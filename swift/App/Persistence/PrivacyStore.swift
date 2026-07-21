// Launch checklist #6 -- build the SwiftData store as strictly on-device:
// no CloudKit sync, excluded from iCloud/iTunes backup, and file-protected.
// Health-derived data must never leave the device (AGENTS.md: local-first).
// Mac-only; compiled under Xcode.
#if canImport(SwiftData)
import Foundation
import SwiftData

enum PrivacyStore {
    static let models: [any PersistentModel.Type] = [
        StoredSample.self, StoredBaseline.self, StoredAlert.self, StoredAnchor.self,
        EventRecord.self, GuidedResponse.self, CoherenceSession.self
    ]

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema(models)
        let url = storeURL()
        // cloudKitDatabase: .none => never syncs to iCloud.
        let config = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        let container = try ModelContainer(for: schema, configurations: config)
        protect(url)
        return container
    }

    private static func storeURL() -> URL {
        let dir = URL.applicationSupportDirectory.appending(path: "HRVC", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "HRVC.store")
    }

    /// Exclude the store (and its -wal/-shm sidecars) from backup and set file
    /// protection so the data is unreadable while the device is locked.
    private static func protect(_ storeURL: URL) {
        let fm = FileManager.default
        for suffix in ["", "-wal", "-shm"] {
            let path = storeURL.path + suffix
            guard fm.fileExists(atPath: path) else { continue }
            var url = URL(fileURLWithPath: path)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try? url.setResourceValues(values)
            #if os(iOS) || os(watchOS)
            try? fm.setAttributes([.protectionKey: FileProtectionType.completeUnlessOpen],
                                  ofItemAtPath: path)
            #endif
        }
    }
}
#endif
