import Foundation
import AppKit

@MainActor
public final class DiskAnalyzerService: ObservableObject {
    @Published public var categories: [StorageCategoryItem] = []
    @Published public var largestFiles: [LargeFileItem] = []
    @Published public var isAnalyzing: Bool = false
    @Published public var scanProgress: Double = 0.0
    @Published public var targetPath: String = "/" // Target path e.g. "/", "/Volumes", "/private/tmp"
    
    private let home = FileManager.default.homeDirectoryForCurrentUser
    
    public init() {}
    
    public func analyzeStorage(path: String? = nil) async {
        if let customPath = path {
            self.targetPath = customPath
        }
        
        isAnalyzing = true
        scanProgress = 0.0
        
        let sampleCategories: [StorageCategoryItem] = [
            StorageCategoryItem(name: "Applications", sizeBytes: 42_500_000_000, colorHex: "#3B82F6", iconName: "app.dashed"),
            StorageCategoryItem(name: "Developer & Xcode", sizeBytes: 28_400_000_000, colorHex: "#8B5CF6", iconName: "hammer"),
            StorageCategoryItem(name: "Documents & Files", sizeBytes: 65_200_000_000, colorHex: "#10B981", iconName: "doc.text"),
            StorageCategoryItem(name: "System Caches & Logs", sizeBytes: 14_800_000_000, colorHex: "#F59E0B", iconName: "externaldrive"),
            StorageCategoryItem(name: "Media & Downloads", sizeBytes: 38_100_000_000, colorHex: "#EC4899", iconName: "film"),
            StorageCategoryItem(name: "Trash", sizeBytes: 4_200_000_000, colorHex: "#EF4444", iconName: "trash")
        ]
        
        categories = sampleCategories
        
        // Scan top largest files in target directory
        let topFiles = await findTopLargestFiles(inPath: targetPath)
        largestFiles = topFiles
        
        isAnalyzing = false
    }
    
    public func revealInFinder(path: String) {
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    private func findTopLargestFiles(inPath scanPath: String) async -> [LargeFileItem] {
        return await Task.detached(priority: .utility) {
            let fm = FileManager.default
            let targetFolder = URL(fileURLWithPath: scanPath)
            var files: [LargeFileItem] = []
            
            if let enumerator = fm.enumerator(at: targetFolder, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey], options: [.skipsHiddenFiles]) {
                var count = 0
                while let fileURL = enumerator.nextObject() as? URL {
                    count += 1
                    if count > 1500 { break } // Limit speed
                    
                    if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey]),
                       values.isDirectory == false,
                       let size = values.fileSize,
                       size > 20_000_000 { // Files larger than 20MB
                        
                        let item = LargeFileItem(
                            name: fileURL.lastPathComponent,
                            path: fileURL.path,
                            sizeBytes: UInt64(size),
                            lastModified: values.contentModificationDate ?? Date()
                        )
                        files.append(item)
                    }
                }
            }
            
            return Array(files.sorted(by: { $0.sizeBytes > $1.sizeBytes }).prefix(40))
        }.value
    }
}
