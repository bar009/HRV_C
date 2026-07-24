// Track B -- HealthKit data access (Deep Dive D.1). Mac/device-only.
// D-OP4 hybrid: Apple's SDNN is the primary source; beat-series RR is the
// opportunistic secondary (added later, see Track H field test / Q-A).
#if canImport(HealthKit)
import Foundation
import HealthKit
import HRVCore

final class HealthKitService {
    private let store = HKHealthStore()
    private let sdnnType = HKQuantityType(.heartRateVariabilitySDNN)
    private let restingHRType = HKQuantityType(.restingHeartRate)
    private let anchorKey = "hrvSDNN"

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// The single source of truth for what we read. Launch checklist #1 -- request
    /// only what the app actually reads today (App Review rejects unused types).
    /// SDNN drives detection; workouts and sleepAnalysis feed context
    /// stratification (Track H) and, with restingHeartRate, the factual
    /// co-occurring context shown on an event. Every type here is genuinely
    /// queried. Raw `heartRate` stays out: nothing needs per-beat samples.
    private var readTypes: Set<HKObjectType> {
        var read: Set<HKObjectType> = [
            sdnnType,
            restingHRType,
            HKObjectType.workoutType(),
            HKCategoryType(.sleepAnalysis)
        ]
        // Beat series (RRExtractor path) only when the advanced-metrics feature
        // is on (v1.1) -- so v1 never requests an unused type.
        if FeatureFlags.advancedMetricsEnabled {
            read.insert(HKSeriesType.heartbeat())
        }
        return read
    }

    func requestAuthorization() async throws {
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    /// Whether iOS would still present the permission sheet. `.shouldRequest`
    /// means the prompt hasn't been shown yet (requesting will show UI);
    /// `.unnecessary` means it was already asked -- iOS never re-prompts, so any
    /// change must be made in Settings. This is the reliable signal the
    /// diagnostics screen needs, since read-grant status itself is opaque.
    func authorizationRequestStatus() async -> HKAuthorizationRequestStatus {
        await withCheckedContinuation { cont in
            store.getRequestStatusForAuthorization(toShare: [], read: readTypes) { status, _ in
                cont.resume(returning: status)
            }
        }
    }

    /// A one-shot read test over the last `days` days: how many SDNN and resting
    /// HR samples actually come back, and the newest timestamp of each. For read
    /// types Apple never reports grant status, so *actually reading* is the only
    /// honest way to tell the user whether the connection works.
    func probeRecentData(days: Int = 7) async -> HealthProbe {
        async let sdnn = countAndLatest(of: sdnnType, days: days)
        async let hr = countAndLatest(of: restingHRType, days: days)
        let (sdnnCount, latestSDNN) = await sdnn
        let (hrCount, latestHR) = await hr
        return HealthProbe(sdnnCount: sdnnCount, restingHRCount: hrCount,
                           latestSDNN: latestSDNN, latestRestingHR: latestHR)
    }

    private func countAndLatest(of type: HKSampleType, days: Int) async -> (Int, Date?) {
        let start = Date().addingTimeInterval(-Double(days) * 86_400)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        return await withCheckedContinuation { cont in
            store.execute(HKSampleQuery(sampleType: type, predicate: predicate,
                                        limit: HKObjectQueryNoLimit, sortDescriptors: sort) { _, samples, _ in
                let s = samples ?? []
                cont.resume(returning: (s.count, s.first?.endDate))
            })
        }
    }

    /// Latest beat-series metrics (RMSSD/pNN50/SDSD, Deep Dive A.6.1). Reads the
    /// most recent `HKHeartbeatSeriesSample`, extracts its beat-to-beat times,
    /// and runs the pure RRExtractor. Device-only: the simulator produces no
    /// beat series, and passive availability is unproven (Q-A).
    func fetchLatestBeatMetrics(completion: @escaping (BeatSeriesMetrics?) -> Void) {
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        let sampleQuery = HKSampleQuery(sampleType: HKSeriesType.heartbeat(), predicate: nil,
                                        limit: 1, sortDescriptors: sort) { [weak self] _, samples, _ in
            guard let self, let series = samples?.first as? HKHeartbeatSeriesSample else {
                DispatchQueue.main.async { completion(nil) }; return
            }
            var beatTimes: [TimeInterval] = []
            let beatQuery = HKHeartbeatSeriesQuery(heartbeatSeries: series) { _, timeSinceStart, _, done, _ in
                beatTimes.append(timeSinceStart)
                if done {
                    let metrics = RRExtractor.metrics(fromBeatTimes: beatTimes)
                    DispatchQueue.main.async { completion(metrics) }
                }
            }
            self.store.execute(beatQuery)
        }
        store.execute(sampleQuery)
    }

    /// Observe SDNN in the background; delivers new HRVSamples plus a context
    /// classifier (workouts + sleep overlapping the batch) via `onSamples`.
    func startObservingSDNN(anchorProvider: @escaping (String) -> Data?,
                            anchorSink: @escaping (Data, String) -> Void,
                            onSamples: @escaping ([HRVSample], ContextClassifier) -> Void) {
        let observer = HKObserverQuery(sampleType: sdnnType, predicate: nil) { [weak self] _, completion, error in
            guard let self, error == nil else { completion(); return }
            self.fetchNew(anchorProvider: anchorProvider, anchorSink: anchorSink, onSamples: onSamples,
                          done: completion)
        }
        store.execute(observer)
        // iOS batches this regardless of the requested frequency.
        store.enableBackgroundDelivery(for: sdnnType, frequency: .immediate) { _, _ in }
    }

    private func fetchNew(anchorProvider: @escaping (String) -> Data?,
                          anchorSink: @escaping (Data, String) -> Void,
                          onSamples: @escaping ([HRVSample], ContextClassifier) -> Void,
                          done: @escaping () -> Void) {
        var anchor: HKQueryAnchor?
        if let data = anchorProvider(anchorKey) {
            anchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
        }
        let query = HKAnchoredObjectQuery(type: sdnnType, predicate: nil, anchor: anchor,
                                          limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, newAnchor, _ in
            guard let self else { done(); return }
            let hrv = (samples as? [HKQuantitySample] ?? []).map { s in
                HRVSample(timestamp: s.endDate,
                          valueMs: s.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)),
                          metric: .sdnnApple, quality: .high, source: .healthKitDirect)
            }
            if let newAnchor,
               let data = try? NSKeyedArchiver.archivedData(withRootObject: newAnchor, requiringSecureCoding: true) {
                anchorSink(data, self.anchorKey)
            }
            guard !hrv.isEmpty else { done(); return }
            self.fetchContext(for: hrv) { classifier in
                onSamples(hrv, classifier)
                done()
            }
        }
        store.execute(query)
    }

    /// Latest resting heart rate and the personal usual (median over the
    /// window), both in bpm. Apple computes this daily value itself, so this
    /// is one cheap query rather than a stream of per-beat samples.
    func fetchRestingHeartRate(days: Int = 30,
                               completion: @escaping (_ latest: Double?, _ usual: Double?) -> Void) {
        let start = Date().addingTimeInterval(-Double(days) * 86_400)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        store.execute(HKSampleQuery(sampleType: restingHRType, predicate: predicate,
                                    limit: HKObjectQueryNoLimit, sortDescriptors: sort) { _, samples, _ in
            let bpm = (samples as? [HKQuantitySample] ?? []).map {
                $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            }
            let usual = bpm.count >= 2 ? EventContextBuilder.median(bpm) : nil
            DispatchQueue.main.async { completion(bpm.first, usual) }
        })
    }

    /// Build the Track H classifier: workouts + sleepAnalysis intervals that
    /// overlap the sample batch (padded by the recovery buffer on both ends).
    private func fetchContext(for batch: [HRVSample],
                              completion: @escaping (ContextClassifier) -> Void) {
        guard let first = batch.map(\.timestamp).min(),
              let last = batch.map(\.timestamp).max() else {
            completion(ContextClassifier()); return
        }
        let pad = ContextClassifier.postWorkoutRecovery
        let predicate = HKQuery.predicateForSamples(withStart: first.addingTimeInterval(-pad),
                                                    end: last.addingTimeInterval(pad))
        var workouts: [DateInterval] = []
        var sleep: [DateInterval] = []
        let group = DispatchGroup()

        group.enter()
        store.execute(HKSampleQuery(sampleType: .workoutType(), predicate: predicate,
                                    limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            workouts = (samples ?? []).map { DateInterval(start: $0.startDate, end: $0.endDate) }
            group.leave()
        })

        group.enter()
        store.execute(HKSampleQuery(sampleType: HKCategoryType(.sleepAnalysis), predicate: predicate,
                                    limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            let asleepValues = HKCategoryValueSleepAnalysis.allAsleepValues.map(\.rawValue)
            sleep = (samples as? [HKCategorySample] ?? [])
                .filter { asleepValues.contains($0.value) }
                .map { DateInterval(start: $0.startDate, end: $0.endDate) }
            group.leave()
        })

        group.notify(queue: .main) {
            completion(ContextClassifier(workouts: workouts, sleep: sleep))
        }
    }
}
#endif
