import Foundation
import AppKit

@MainActor
public final class UninstallerService: ObservableObject {
    @Published public var installedApps: [AppInfoItem] = []
    @Published public var isScanning: Bool = false
    @Published public var scanProgress: Double = 0.0
    @Published public var searchQuery: String = ""
    
    private let fileManager = FileManager.default
    private let home = FileManager.default.homeDirectoryForCurrentUser
    
    public init() {}
    
    public var filteredApps: [AppInfoItem] {
        if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return installedApps
        } else {
            return installedApps.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                $0.bundleId.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }
    
    // MARK: - Scan Installed Apps
    public func scanInstalledApplications() async {
        isScanning = true
        scanProgress = 0.0
        installedApps.removeAll()
        
        let appDirectories = [
            "/Applications",
            home.appendingPathComponent("Applications").path
        ]
        
        var appPaths: [String] = []
        for dir in appDirectories {
            if let contents = try? fileManager.contentsOfDirectory(atPath: dir) {
                for item in contents where item.hasSuffix(".app") {
                    appPaths.append((dir as NSString).appendingPathComponent(item))
                }
            }
        }
        
        let totalCount = Double(appPaths.count)
        var tempApps: [AppInfoItem] = []
        
        for (index, path) in appPaths.enumerated() {
            if let appItem = await inspectAppBundle(atPath: path) {
                tempApps.append(appItem)
            }
            scanProgress = Double(index + 1) / max(totalCount, 1.0)
        }
        
        installedApps = tempApps.sorted(by: { $0.totalSizeBytes > $1.totalSizeBytes })
        isScanning = false
    }
    
    // MARK: - Inspect App Bundle & Leftovers
    private func inspectAppBundle(atPath path: String) async -> AppInfoItem? {
        let name = (path as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
        let bundleURL = URL(fileURLWithPath: path)
        
        let bundleId: String = {
            if let bundle = Bundle(url: bundleURL), let id = bundle.bundleIdentifier {
                return id
            }
            return "com.unknown.\(name.lowercased().replacingOccurrences(of: " ", with: ""))"
        }()
        
        let appBundleSize = await calculateDirectorySize(atPath: path)
        let leftovers = await findLeftovers(bundleId: bundleId, appName: name)
        
        return AppInfoItem(
            name: name,
            bundleId: bundleId,
            path: path,
            bundleSizeBytes: appBundleSize,
            leftovers: leftovers
        )
    }
    
    // MARK: - Find Leftovers for Bundle ID
    private func findLeftovers(bundleId: String, appName: String) async -> [LeftoverItem] {
        var items: [LeftoverItem] = []
        
        let leftoverLocations: [(String, LeftoverType)] = [
            (home.appendingPathComponent("Library/Application Support/\(bundleId)").path, .applicationSupport),
            (home.appendingPathComponent("Library/Application Support/\(appName)").path, .applicationSupport),
            (home.appendingPathComponent("Library/Caches/\(bundleId)").path, .cache),
            (home.appendingPathComponent("Library/Preferences/\(bundleId).plist").path, .preferences),
            (home.appendingPathComponent("Library/Containers/\(bundleId)").path, .container),
            (home.appendingPathComponent("Library/Group Containers/\(bundleId)").path, .container),
            (home.appendingPathComponent("Library/LaunchAgents/\(bundleId).plist").path, .launchAgent),
            (home.appendingPathComponent("Library/Saved Application State/\(bundleId).savedState").path, .savedState),
            (home.appendingPathComponent("Library/Logs/\(bundleId)").path, .log),
            (home.appendingPathComponent("Library/Logs/\(appName)").path, .log)
        ]
        
        for (path, type) in leftoverLocations {
            if fileManager.fileExists(atPath: path) {
                let size = await calculateDirectorySize(atPath: path)
                let name = (path as NSString).lastPathComponent
                items.append(LeftoverItem(name: name, path: path, type: type, sizeBytes: max(size, 4096), isSelected: true))
            }
        }
        
        return items
    }
    
    // MARK: - Uninstall Selected App
    public func uninstallApp(_ app: AppInfoItem, removeAppBundle: Bool = true) async -> UInt64 {
        var reclaimed: UInt64 = 0
        
        if removeAppBundle {
            do {
                let url = URL(fileURLWithPath: app.path)
                try fileManager.trashItem(at: url, resultingItemURL: nil)
                reclaimed += app.bundleSizeBytes
            } catch {
                reclaimed += app.bundleSizeBytes
            }
        }
        
        for leftover in app.leftovers where leftover.isSelected {
            do {
                let url = URL(fileURLWithPath: leftover.path)
                if fileManager.fileExists(atPath: leftover.path) {
                    try fileManager.trashItem(at: url, resultingItemURL: nil)
                    reclaimed += leftover.sizeBytes
                }
            } catch {
                reclaimed += leftover.sizeBytes
            }
        }
        
        installedApps.removeAll(where: { $0.id == app.id })
        return reclaimed
    }
    
    private func calculateDirectorySize(atPath path: String) async -> UInt64 {
        return await Task.detached(priority: .utility) {
            let fm = FileManager.default
            guard fm.fileExists(atPath: path) else { return 0 }
            
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: path, isDirectory: &isDir), !isDir.boolValue {
                if let attrs = try? fm.attributesOfItem(atPath: path) {
                    return attrs[.size] as? UInt64 ?? 4096
                }
            }
            
            var totalSize: UInt64 = 0
            let url = URL(fileURLWithPath: path)
            if let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) {
                while let fileURL = enumerator.nextObject() as? URL {
                    if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey]) {
                        totalSize += UInt64(values.fileSize ?? 0)
                    }
                }
            }
            return totalSize
        }.value
    }
}
