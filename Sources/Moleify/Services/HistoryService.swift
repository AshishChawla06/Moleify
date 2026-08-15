import Foundation

public struct HistoryRecordItem: Identifiable, Sendable, Codable, Hashable {
    public let id: String
    public let timestamp: Date
    public let actionType: String // e.g. "Clean", "Uninstall", "Purge", "Optimize"
    public let itemDescription: String
    public let reclaimedBytes: UInt64
    public let isDryRun: Bool
    public let logs: [String]
    
    public init(id: String = UUID().uuidString, timestamp: Date = Date(), actionType: String, itemDescription: String, reclaimedBytes: UInt64, isDryRun: Bool, logs: [String] = []) {
        self.id = id
        self.timestamp = timestamp
        self.actionType = actionType
        self.itemDescription = itemDescription
        self.reclaimedBytes = reclaimedBytes
        self.isDryRun = isDryRun
        self.logs = logs
    }
}

@MainActor
public final class HistoryService: ObservableObject {
    @Published public var historyRecords: [HistoryRecordItem] = []
    
    private let historyFilePath: String
    
    public init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.historyFilePath = docs.appendingPathComponent(".moleify_history.json").path
        loadHistory()
    }
    
    public func addRecord(actionType: String, itemDescription: String, reclaimedBytes: UInt64, isDryRun: Bool, logs: [String] = []) {
        let record = HistoryRecordItem(
            actionType: actionType,
            itemDescription: itemDescription,
            reclaimedBytes: reclaimedBytes,
            isDryRun: isDryRun,
            logs: logs
        )
        historyRecords.insert(record, at: 0)
        saveHistory()
    }
    
    public func clearHistory() {
        historyRecords.removeAll()
        saveHistory()
    }
    
    // MARK: - Export History to JSON (mo history --json)
    public func exportHistoryAsJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        if let data = try? encoder.encode(historyRecords), let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }
        return "[]"
    }
    
    private func saveHistory() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(historyRecords) {
            try? data.write(to: URL(fileURLWithPath: historyFilePath))
        }
    }
    
    private func loadHistory() {
        if let data = try? Data(contentsOf: URL(fileURLWithPath: historyFilePath)) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let decoded = try? decoder.decode([HistoryRecordItem].self, from: data) {
                self.historyRecords = decoded
                return
            }
        }
        
        // Seed initial history record
        self.historyRecords = [
            HistoryRecordItem(
                timestamp: Date().addingTimeInterval(-3600),
                actionType: "Clean (mo clean)",
                itemDescription: "System Cache & Xcode DerivedData Cleanup",
                reclaimedBytes: 12_400_000_000,
                isDryRun: true,
                logs: ["Scanned ~/Library/Caches (8.02 GB)", "Scanned Xcode DerivedData (4.38 GB)"]
            )
        ]
    }
}
