import Foundation
import AppKit

public struct ProjectArtifactItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let projectName: String
    public let artifactType: String // e.g. "node_modules", ".build", "target", "venv"
    public let path: String
    public let sizeBytes: UInt64
    public var isSelected: Bool
    
    public init(id: String = UUID().uuidString, projectName: String, artifactType: String, path: String, sizeBytes: UInt64, isSelected: Bool = true) {
        self.id = id
        self.projectName = projectName
        self.artifactType = artifactType
        self.path = path
        self.sizeBytes = sizeBytes
        self.isSelected = isSelected
    }
}

@MainActor
public final class PurgeService: ObservableObject {
    @Published public var artifacts: [ProjectArtifactItem] = []
    @Published public var isScanning: Bool = false
    @Published public var scanProgress: Double = 0.0
    @Published public var isPurging: Bool = false
    @Published public var lastPurgedBytes: UInt64 = 0
    
    private let fileManager = FileManager.default
    private let home = FileManager.default.homeDirectoryForCurrentUser
    
    public init() {}
    
    public var totalSelectedBytes: UInt64 {
        artifacts.filter { $0.isSelected }.reduce(0) { $0 + $1.sizeBytes }
    }
    
    // MARK: - Scan Project Build Artifacts (mo purge)
    public func scanProjectArtifacts() async {
        isScanning = true
        scanProgress = 0.0
        artifacts.removeAll()
        
        let searchDirectories = [
            home.path,
            home.appendingPathComponent("Documents").path,
            home.appendingPathComponent("Desktop").path,
            home.appendingPathComponent("Developer").path,
            home.appendingPathComponent("Projects").path
        ]
        
        let targetArtifactNames: Set<String> = [
            "node_modules", ".build", "target", "venv", ".venv",
            "DerivedData", ".gradle", ".next", "dist", "build", "Podfile.lock"
        ]
        
        var foundItems: [ProjectArtifactItem] = []
        let totalDirs = Double(searchDirectories.count)
        
        for (index, searchDir) in searchDirectories.enumerated() {
            guard fileManager.fileExists(atPath: searchDir) else { continue }
            
            let url = URL(fileURLWithPath: searchDir)
            if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                
                var count = 0
                while let fileURL = enumerator.nextObject() as? URL {
                    count += 1
                    if count > 800 { break } // Limit depth per top directory to keep scan fast
                    
                    let name = fileURL.lastPathComponent
                    if targetArtifactNames.contains(name) {
                        let path = fileURL.path
                        let projectName = (path as NSString).deletingLastPathComponent.components(separatedBy: "/").last ?? "Project"
                        let size = await calculateDirectorySize(atPath: path)
                        
                        if size > 1_000_000 { // Items > 1MB
                            let item = ProjectArtifactItem(
                                projectName: projectName,
                                artifactType: name,
                                path: path,
                                sizeBytes: size,
                                isSelected: true
                            )
                            foundItems.append(item)
                        }
                    }
                }
            }
            scanProgress = Double(index + 1) / totalDirs
        }
        
        artifacts = foundItems.sorted(by: { $0.sizeBytes > $1.sizeBytes })
        isScanning = false
    }
    
    // MARK: - Purge Selected Artifacts
    public func purgeSelected() async -> UInt64 {
        isPurging = true
        var reclaimed: UInt64 = 0
        
        let targets = artifacts.filter { $0.isSelected }
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
        
        lastPurgedBytes = reclaimed
        artifacts.removeAll(where: { $0.isSelected })
        isPurging = false
        return reclaimed
    }
    
    private func calculateDirectorySize(atPath path: String) async -> UInt64 {
        return await Task.detached(priority: .utility) {
            let fm = FileManager.default
            guard fm.fileExists(atPath: path) else { return 0 }
            
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
