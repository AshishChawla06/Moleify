import Foundation
import AppKit

public struct InstallerFileItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let path: String
    public let extensionType: String
    public let sizeBytes: UInt64
    public let createdDate: Date
    public var isSelected: Bool
    
    public init(id: String = UUID().uuidString, name: String, path: String, extensionType: String, sizeBytes: UInt64, createdDate: Date, isSelected: Bool = true) {
        self.id = id
        self.name = name
        self.path = path
        self.extensionType = extensionType
        self.sizeBytes = sizeBytes
        self.createdDate = createdDate
        self.isSelected = isSelected
    }
}

@MainActor
public final class InstallerService: ObservableObject {
    @Published public var installers: [InstallerFileItem] = []
    @Published public var isScanning: Bool = false
    @Published public var isRemoving: Bool = false
    @Published public var lastReclaimedBytes: UInt64 = 0
    
    private let fileManager = FileManager.default
    private let home = FileManager.default.homeDirectoryForCurrentUser
    
    public init() {}
    
    public var totalSelectedBytes: UInt64 {
        installers.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeBytes }
    }
    
    // MARK: - Scan Installer Files (mo installer)
    public func scanInstallers() async {
        isScanning = true
        installers.removeAll()
        
        let targetFolders = [
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Documents")
        ]
        
        let installerExtensions: Set<String> = ["dmg", "pkg", "iso", "xip"]
        var foundItems: [InstallerFileItem] = []
        
        for folder in targetFolders {
            guard fileManager.fileExists(atPath: folder.path) else { continue }
            
            if let contents = try? fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey], options: [.skipsHiddenFiles]) {
                for fileURL in contents {
                    let ext = fileURL.pathExtension.lowercased()
                    if installerExtensions.contains(ext) {
                        if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .creationDateKey]),
                           let size = values.fileSize {
                            
                            let item = InstallerFileItem(
                                name: fileURL.lastPathComponent,
                                path: fileURL.path,
                                extensionType: ext,
                                sizeBytes: UInt64(size),
                                createdDate: values.creationDate ?? Date(),
                                isSelected: true
                            )
                            foundItems.append(item)
                        }
                    }
                }
            }
        }
        
        installers = foundItems.sorted(by: { $0.sizeBytes > $1.sizeBytes })
        isScanning = false
    }
    
    // MARK: - Remove Selected Installers
    public func removeSelectedInstallers() async -> UInt64 {
        isRemoving = true
        var reclaimed: UInt64 = 0
        
        let targets = installers.filter { $0.isSelected }
        for item in targets {
            let url = URL(fileURLWithPath: item.path)
            do {
                if fileManager.fileExists(atPath: item.path) {
                    try fileManager.trashItem(at: url, resultingItemURL: nil)
                    reclaimed += item.sizeBytes
                }
            } catch {
                reclaimed += item.sizeBytes
            }
        }
        
        lastReclaimedBytes = reclaimed
        installers.removeAll(where: { $0.isSelected })
        isRemoving = false
        return reclaimed
    }
}
