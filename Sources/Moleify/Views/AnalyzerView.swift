import SwiftUI

public struct AnalyzerView: View {
    @EnvironmentObject private var analyzer: DiskAnalyzerService
    @State private var customPathInput: String = "/"
    @State private var showDuplicatesToast: Bool = false
    @State private var reclaimedDupSpace: UInt64 = 0
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Disk Storage Analyzer & Duplicates")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("mo analyze • Visual storage distribution, category breakdown, duplicate finder, and large files inspector")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            Task {
                                await analyzer.scanDuplicateFiles()
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc.fill")
                                Text(analyzer.isScanningDuplicates ? "Scanning..." : "Find Duplicates")
                            }
                            .font(.headline.weight(.bold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.applePurple)
                        
                        Button(action: {
                            Task {
                                await analyzer.analyzeStorage(path: customPathInput)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text(analyzer.isAnalyzing ? "Analyzing..." : "Analyze Disk")
                            }
                            .font(.headline.weight(.bold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.appleBlue)
                        .disabled(analyzer.isAnalyzing)
                    }
                }
                
                if showDuplicatesToast {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.appleGreen)
                        Text("Duplicate files moved to Trash! Reclaimed \(ByteFormatter.string(from: reclaimedDupSpace)).")
                            .font(.body.weight(.bold))
                            .foregroundStyle(.primary)
                        Spacer()
                        Button("Dismiss") { showDuplicatesToast = false }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color.appleGreen.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appleGreen.opacity(0.4), lineWidth: 1))
                }
                
                // Target Path Preset Quick Buttons
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeaderLabel("Target Disk or Directory Presets")
                        
                        HStack(spacing: 12) {
                            Button("Macintosh HD ( / )") {
                                customPathInput = "/"
                                Task { await analyzer.analyzeStorage(path: "/") }
                            }
                            .buttonStyle(.bordered)
                            .tint(customPathInput == "/" ? Color.appleBlue : Color.gray)
                            
                            Button("External Drives ( /Volumes )") {
                                customPathInput = "/Volumes"
                                Task { await analyzer.analyzeStorage(path: "/Volumes") }
                            }
                            .buttonStyle(.bordered)
                            .tint(customPathInput == "/Volumes" ? Color.appleBlue : Color.gray)
                            
                            Button("Temp Files ( /private/tmp )") {
                                customPathInput = "/private/tmp"
                                Task { await analyzer.analyzeStorage(path: "/private/tmp") }
                            }
                            .buttonStyle(.bordered)
                            .tint(customPathInput == "/private/tmp" ? Color.appleBlue : Color.gray)
                            
                            Spacer()
                            
                            HStack {
                                Image(systemName: "folder")
                                    .foregroundStyle(.secondary)
                                TextField("Target Path", text: $customPathInput)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                    .foregroundStyle(.primary)
                                    .frame(width: 180)
                            }
                            .padding(8)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                
                // Category Allocation Breakdown & Interactive Donut Chart Card
                GlassCard {
                    HStack(spacing: 24) {
                        // Interactive Storage Donut Chart
                        StorageDonutChart(
                            categories: analyzer.categories,
                            totalSizeBytes: analyzer.categories.reduce(0) { $0 + $1.sizeBytes }
                        )
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Storage Allocation by Category")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if analyzer.selectedCategoryFilter != nil {
                                    Button("Clear Filter") {
                                        analyzer.selectedCategoryFilter = nil
                                    }
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.appleBlue)
                                }
                            }
                            
                            GeometryReader { geo in
                                HStack(spacing: 2) {
                                    let total = Double(analyzer.categories.reduce(0) { $0 + $1.sizeBytes })
                                    ForEach(analyzer.categories) { cat in
                                        let width = total > 0 ? (Double(cat.sizeBytes) / total) * geo.size.width : 0
                                        Rectangle()
                                            .fill(Color(hex: cat.colorHex))
                                            .frame(width: max(width, 4))
                                    }
                                }
                                .clipShape(Capsule())
                            }
                            .frame(height: 14)
                            
                            // Interactive Legend Grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(analyzer.categories) { cat in
                                    Button(action: {
                                        if analyzer.selectedCategoryFilter == cat.name {
                                            analyzer.selectedCategoryFilter = nil
                                        } else {
                                            analyzer.selectedCategoryFilter = cat.name
                                        }
                                    }) {
                                        HStack(spacing: 10) {
                                            Circle()
                                                .fill(Color(hex: cat.colorHex))
                                                .frame(width: 10, height: 10)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(cat.name)
                                                    .font(.caption.weight(.bold))
                                                    .foregroundStyle(.primary)
                                                Text(ByteFormatter.string(from: cat.sizeBytes))
                                                    .font(.caption2.weight(.medium))
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            if analyzer.selectedCategoryFilter == cat.name {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(Color(hex: cat.colorHex))
                                            }
                                        }
                                        .padding(10)
                                        .background(analyzer.selectedCategoryFilter == cat.name ? Color(hex: cat.colorHex).opacity(0.18) : Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                
                // Duplicate File Finder Section (mo duplicates)
                if !analyzer.duplicateGroups.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Duplicate Files Found (mo duplicates)")
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(Color.applePurple)
                                Text("Review duplicate file copies and reclaim wasted space with one click")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    let reclaimed = await analyzer.removeSelectedDuplicates()
                                    reclaimedDupSpace = reclaimed
                                    withAnimation { showDuplicatesToast = true }
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash.fill")
                                    Text("Purge Duplicates")
                                }
                                .font(.headline.weight(.bold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color.appleRed)
                        }
                        
                        GlassCard(padding: 0) {
                            VStack(spacing: 0) {
                                ForEach(analyzer.duplicateGroups) { group in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "doc.on.doc")
                                                .foregroundStyle(Color.applePurple)
                                            Text(group.fileName)
                                                .font(.body.weight(.bold))
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            Text("\(group.paths.count) copies • \(ByteFormatter.string(from: group.fileSize)) each")
                                                .font(.caption.weight(.bold).monospacedDigit())
                                                .foregroundStyle(Color.applePurple)
                                        }
                                        
                                        ForEach(group.paths, id: \.self) { path in
                                            HStack {
                                                Image(systemName: path == group.paths.first ? "star.fill" : "doc")
                                                    .foregroundStyle(path == group.paths.first ? Color.appleYellow : Color.secondary)
                                                    .font(.caption)
                                                
                                                Text(path)
                                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                                    .foregroundStyle(.secondary)
                                                    .lineLimit(1)
                                                Spacer()
                                                
                                                if path != group.paths.first {
                                                    Text("Duplicate Copy")
                                                        .font(.caption2.weight(.bold))
                                                        .foregroundStyle(Color.appleRed)
                                                } else {
                                                    Text("Original Keep")
                                                        .font(.caption2.weight(.bold))
                                                        .foregroundStyle(Color.appleGreen)
                                                }
                                            }
                                            .padding(.leading, 12)
                                        }
                                    }
                                    .padding(14)
                                    .background(Color.white.opacity(0.01))
                                }
                            }
                        }
                    }
                }
                
                // Top Largest Files Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Top Largest Files in Target Path (\(analyzer.targetPath))")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                            Text("Filter by file extension type or category")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        
                        // File Type Filter Buttons
                        HStack(spacing: 8) {
                            ForEach(["All", "Media", "Archives", "Developer", "Documents"], id: \.self) { filterType in
                                Button(filterType) {
                                    analyzer.fileTypeFilter = filterType
                                }
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(analyzer.fileTypeFilter == filterType ? Color.appleBlue : Color.white.opacity(0.06), in: Capsule())
                                .foregroundStyle(analyzer.fileTypeFilter == filterType ? Color.white : Color.secondary)
                            }
                        }
                    }
                    
                    if analyzer.isAnalyzing {
                        ProgressView("Scanning directory trees for large files in \(analyzer.targetPath)...")
                            .padding(.vertical, 30)
                    } else if analyzer.filteredLargestFiles.isEmpty {
                        GlassCard {
                            Text("No large files found matching current filter.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        GlassCard(padding: 0) {
                            VStack(spacing: 0) {
                                ForEach(analyzer.filteredLargestFiles) { file in
                                    HStack(spacing: 14) {
                                        Image(systemName: "doc.fill")
                                            .foregroundStyle(Color.appleBlue)
                                            .font(.title3)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(file.name)
                                                .font(.body.weight(.bold))
                                                .foregroundStyle(.primary)
                                            Text(file.path)
                                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        
                                        Text(ByteFormatter.string(from: file.sizeBytes))
                                            .font(.body.weight(.bold).monospacedDigit())
                                            .foregroundStyle(.primary)
                                        
                                        Button(action: {
                                            analyzer.revealInFinder(path: file.path)
                                        }) {
                                            HStack(spacing: 4) {
                                                Image(systemName: "folder")
                                                Text("Finder")
                                            }
                                            .font(.caption.weight(.bold))
                                        }
                                        .buttonStyle(.bordered)
                                        .foregroundStyle(.primary)
                                        
                                        Button(action: {
                                            analyzer.trashFile(path: file.path)
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.caption.weight(.bold))
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(Color.appleRed)
                                    }
                                    .padding(14)
                                    .background(Color.white.opacity(0.01))
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}
