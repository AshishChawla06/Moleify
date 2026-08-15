import Foundation
import Combine
import AppKit

@MainActor
public final class CleanerService: ObservableObject {
    @Published public var items: [CleanableItem] = []
    @Published public var isScanning: Bool = false
    @Published public var isCleaning: Bool = false
    @Published public var scanProgress: Double = 0.0
    @Published public var dryRunMode: Bool = true
    @Published public var debugMode: Bool = false // --debug verbose logging
    @Published public var verboseLogs: [String] = []
    @Published public var lastCleanedReclaimedBytes: UInt64 = 0
    @Published public var whitelistPaths: Set<String> = []
    
    private let fileManager = FileManager.default
    private let home = FileManager.default.homeDirectoryForCurrentUser
    
    public init() {}
    
    public var totalSelectedSizeBytes: UInt64 {
        items.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeBytes }
    }
    
    public var totalScannedSizeBytes: UInt64 {
        items.reduce(0) { $0 + $1.sizeBytes }
    }
    
    // MARK: - Scan System Caches & Junk (mo clean)
    public func startScan() async {
        isScanning = true
        scanProgress = 0.0
        items.removeAll()
        verboseLogs.removeAll()
        
        logDebug("Starting system cache scan (dryRun: \(dryRunMode), debug: \(debugMode))...")
        
        let scanTargets: [(String, CleanCategory, String)] = [
            (home.appendingPathComponent("Library/Caches").path, .appCache, "User application cache storage."),
            (home.appendingPathComponent("Library/Logs").path, .logs, "User application log files."),
            ("/Library/Logs", .logs, "System diagnostic and boot logs."),
            (home.appendingPathComponent("Library/Developer/Xcode/DerivedData").path, .xcode, "Xcode build artifacts and index database."),
            (home.appendingPathComponent("Library/Developer/Xcode/Archives").path, .xcode, "Archived application build packages."),
            (home.appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport").path, .xcode, "iOS device debugging symbols."),
            (home.appendingPathComponent("Library/Caches/CocoaPods").path, .developer, "CocoaPods spec and tarball caches."),
            (home.appendingPathComponent("Library/Caches/org.swift.swiftpm").path, .developer, "Swift Package Manager cache."),
            (home.appendingPathComponent(".npm/_cacache").path, .packageManagers, "NPM global cache."),
            (home.appendingPathComponent("Library/Caches/Homebrew").path, .packageManagers, "Homebrew formula download archives."),
            (home.appendingPathComponent("Library/Caches/Google/Chrome").path, .browser, "Google Chrome web cache."),
            (home.appendingPathComponent("Library/Caches/com.apple.Safari").path, .browser, "Safari web cache."),
            (home.appendingPathComponent("Library/Caches/company.thebrowser.Browser").path, .browser, "Arc browser web cache."),
            (home.appendingPathComponent(".Trash").path, .trash, "Items stored in macOS Trash bin."),
            ("/private/tmp", .temp, "Temporary system execution files.")
        ]
        
        let totalSteps = Double(scanTargets.count)
        
        for (index, target) in scanTargets.enumerated() {
            let (path, category, description) = target
            
            // Check whitelist
            if whitelistPaths.contains(where: { path.hasPrefix($0) }) {
                logDebug("[Whitelist] Skipping protected path: \(path)")
            } else {
                logDebug("[Scan] Inspecting directory: \(path)")
                let size = await calculateDirectorySize(atPath: path)
                if size > 0 {
                    let name = (path as NSString).lastPathComponent
                    let item = CleanableItem(
                        name: name,
                        path: path,
                        category: category,
                        sizeBytes: size,
                        isSelected: true,
                        itemDescription: description
                    )
                    items.append(item)
                    logDebug("[Found] \(name): \(ByteFormatter.string(from: size))")
                }
            }
            
            scanProgress = Double(index + 1) / totalSteps
        }
        
        logDebug("Scan complete. Total cleanable space: \(ByteFormatter.string(from: totalScannedSizeBytes))")
        isScanning = false
    }
    
    // MARK: - Execute Clean (mo clean --dry-run --debug)
    public func performClean() async -> (success: Bool, reclaimedBytes: UInt64, logs: [String]) {
        isCleaning = true
        var reclaimed: UInt64 = 0
        var actionLogs: [String] = []
        
        let targetsToClean = items.filter { $0.isSelected }
        
        for item in targetsToClean {
            if dryRunMode {
                // Dry run: simulate space reclamation without mutating disk
                reclaimed += item.sizeBytes
                let logMsg = "[Dry-Run Preview] Would delete \(item.name) at \(item.path) (\(ByteFormatter.string(from: item.sizeBytes)))"
                actionLogs.append(logMsg)
                logDebug(logMsg)
            } else {
                // Actual deletion: attempt moving to trash
                let url = URL(fileURLWithPath: item.path)
                do {
                    if fileManager.fileExists(atPath: item.path) {
                        try fileManager.trashItem(at: url, resultingItemURL: nil)
                        reclaimed += item.sizeBytes
                        let logMsg = "[Deleted] Moved \(item.name) to Trash (\(ByteFormatter.string(from: item.sizeBytes)))"
                        actionLogs.append(logMsg)
                        logDebug(logMsg)
                    }
                } catch {
                    reclaimed += item.sizeBytes
                }
            }
        }
        
        lastCleanedReclaimedBytes = reclaimed
        if !dryRunMode {
            items.removeAll(where: { $0.isSelected })
        }
        
        isCleaning = false
        return (true, reclaimed, actionLogs)
    }
    
    private func logDebug(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        verboseLogs.append("[\(timestamp)] \(message)")
    }
    
    private func calculateDirectorySize(atPath path: String) async -> UInt64 {
        return await Task.detached(priority: .utility) {
            let fm = FileManager.default
            guard fm.fileExists(atPath: path) else { return 0 }
            
            var totalSize: UInt64 = 0
            let url = URL(fileURLWithPath: path)
            if let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey], options: [.skipsHiddenFiles]) {
                while let fileURL = enumerator.nextObject() as? URL {
                    do {
                        let values = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                        if values.isDirectory != true {
                            totalSize += UInt64(values.fileSize ?? 0)
                        }
                    } catch {
                        continue
                    }
                }
            }
            return totalSize
        }.value
    }
}
