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
    private let anchorKey = "hrvSDNN"

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async throws {
        // Launch checklist #1 -- request only what the app actually reads today
        // (App Review rejects requesting unused types). SDNN drives detection;
        // workouts and sleepAnalysis feed context stratification (Track H).
        //
        // heartRate is deliberately NOT requested: nothing queries it. It comes
        // back when it earns its place -- either HR-based restfulness gating
        // (needs a threshold tuned on real watch data, Q-B) or RRExtractor
        // (Q-A), which needs HKHeartbeatSeriesSample rather than this type.
        let read: Set<HKObjectType> = [
            sdnnType,
            HKObjectType.workoutType(),
            HKCategoryType(.sleepAnalysis)
        ]
        try await store.requestAuthorization(toShare: [], read: read)
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
