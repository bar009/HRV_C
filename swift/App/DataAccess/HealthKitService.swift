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
    private let hrType = HKQuantityType(.heartRate)
    private let anchorKey = "hrvSDNN"

    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async throws {
        let read: Set<HKObjectType> = [sdnnType, hrType, HKSeriesType.heartbeat()]
        try await store.requestAuthorization(toShare: [], read: read)
    }

    /// Observe SDNN in the background; delivers new HRVSamples via `onSamples`.
    func startObservingSDNN(anchorProvider: @escaping (String) -> Data?,
                            anchorSink: @escaping (Data, String) -> Void,
                            onSamples: @escaping ([HRVSample]) -> Void) {
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
                          onSamples: @escaping ([HRVSample]) -> Void,
                          done: @escaping () -> Void) {
        var anchor: HKQueryAnchor?
        if let data = anchorProvider(anchorKey) {
            anchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
        }
        let query = HKAnchoredObjectQuery(type: sdnnType, predicate: nil, anchor: anchor,
                                          limit: HKObjectQueryNoLimit) { _, samples, _, newAnchor, _ in
            let hrv = (samples as? [HKQuantitySample] ?? []).map { s in
                HRVSample(timestamp: s.endDate,
                          valueMs: s.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)),
                          metric: .sdnnApple, quality: .high, source: .healthKitDirect)
            }
            if let newAnchor,
               let data = try? NSKeyedArchiver.archivedData(withRootObject: newAnchor, requiringSecureCoding: true) {
                anchorSink(data, self.anchorKey)
            }
            if !hrv.isEmpty { onSamples(hrv) }
            done()
        }
        store.execute(query)
    }
}
#endif
