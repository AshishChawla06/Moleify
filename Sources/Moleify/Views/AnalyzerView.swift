import SwiftUI

public struct AnalyzerView: View {
    @EnvironmentObject private var analyzer: DiskAnalyzerService
    @State private var customPathInput: String = "/"
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Disk Storage Analyzer")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.98))
                        Text("mo analyze • Analyze disk space allocation across categories and target specific drives or directories")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.75))
                    }
                    Spacer()
                    
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
                    .tint(Color(hex: "#0284C7"))
                    .disabled(analyzer.isAnalyzing)
                }
                
                // Target Path Preset Quick Buttons (mo analyze /Volumes, mo analyze /private/tmp)
                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TARGET DISK OR DIRECTORY PRESETS")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.white.opacity(0.7))
                        
                        HStack(spacing: 12) {
                            Button("Macintosh HD ( / )") {
                                customPathInput = "/"
                                Task { await analyzer.analyzeStorage(path: "/") }
                            }
                            .buttonStyle(.bordered)
                            .tint(customPathInput == "/" ? Color(hex: "#38BDF8") : Color.gray)
                            
                            Button("External Drives ( /Volumes )") {
                                customPathInput = "/Volumes"
                                Task { await analyzer.analyzeStorage(path: "/Volumes") }
                            }
                            .buttonStyle(.bordered)
                            .tint(customPathInput == "/Volumes" ? Color(hex: "#38BDF8") : Color.gray)
                            
                            Button("Temp Files ( /private/tmp )") {
                                customPathInput = "/private/tmp"
                                Task { await analyzer.analyzeStorage(path: "/private/tmp") }
                            }
                            .buttonStyle(.bordered)
                            .tint(customPathInput == "/private/tmp" ? Color(hex: "#38BDF8") : Color.gray)
                            
                            Spacer()
                            
                            HStack {
                                TextField("Target Path", text: $customPathInput)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                    .foregroundStyle(Color.white)
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
                            Text("Storage Allocation by Category")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Color.white.opacity(0.95))
                            
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
                            
                            // Legend Grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(analyzer.categories) { cat in
                                    HStack(spacing: 10) {
                                        Circle()
                                            .fill(Color(hex: cat.colorHex))
                                            .frame(width: 10, height: 10)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(cat.name)
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(Color.white.opacity(0.95))
                                            Text(ByteFormatter.string(from: cat.sizeBytes))
                                                .font(.caption2.weight(.medium))
                                                .foregroundStyle(Color.white.opacity(0.75))
                                        }
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(Color.white.opacity(0.02), in: RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                }
                
                // Top Largest Files Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Top Largest Files in Target Path (\(analyzer.targetPath))")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.95))
                    
                    if analyzer.isAnalyzing {
                        ProgressView("Scanning directory trees for large files in \(analyzer.targetPath)...")
                            .padding(.vertical, 30)
                    } else if analyzer.largestFiles.isEmpty {
                        GlassCard {
                            Text("Click 'Analyze Disk' above to scan and list top largest files on your Mac.")
                                .font(.subheadline)
                                .foregroundStyle(Color.white.opacity(0.75))
                        }
                    } else {
                        GlassCard(padding: 0) {
                            VStack(spacing: 0) {
                                ForEach(analyzer.largestFiles) { file in
                                    HStack(spacing: 14) {
                                        Image(systemName: "doc.fill")
                                            .foregroundStyle(Color(hex: "#38BDF8"))
                                            .font(.title3)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(file.name)
                                                .font(.body.weight(.bold))
                                                .foregroundStyle(Color.white.opacity(0.95))
                                            Text(file.path)
                                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                                .foregroundStyle(Color.white.opacity(0.75))
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        
                                        Text(ByteFormatter.string(from: file.sizeBytes))
                                            .font(.body.weight(.bold).monospacedDigit())
                                            .foregroundStyle(Color.white.opacity(0.95))
                                        
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
                                        .foregroundStyle(Color.white.opacity(0.9))
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
