import SwiftUI

public struct CleanerView: View {
    @EnvironmentObject private var cleaner: CleanerService
    @State private var showSuccessBanner: Bool = false
    @State private var cleanedBytes: UInt64 = 0
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Smart System Cleaner")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.98))
                    Text("Reclaim gigabytes by scanning system caches, logs, browser leftovers, and Xcode junk")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                Spacer()
                
                // Mode Toggle Pill
                HStack(spacing: 14) {
                    Toggle(isOn: $cleaner.dryRunMode) {
                        HStack(spacing: 6) {
                            Image(systemName: cleaner.dryRunMode ? "eye.fill" : "flame.fill")
                                .foregroundStyle(cleaner.dryRunMode ? Color(hex: "#38BDF8") : Color(hex: "#F97316"))
                            Text(cleaner.dryRunMode ? "Dry Run (Safe Preview)" : "Live Safe Delete")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.white.opacity(0.95))
                        }
                    }
                    .toggleStyle(.switch)
                    
                    Button(action: {
                        Task {
                            await cleaner.startScan()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                            Text(cleaner.isScanning ? "Scanning..." : "Scan System")
                        }
                        .font(.headline.weight(.bold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#0284C7"))
                    .disabled(cleaner.isScanning || cleaner.isCleaning)
                }
            }
            .padding(24)
            .background(Color(red: 0.10, green: 0.11, blue: 0.15))
            
            Divider().background(Color.white.opacity(0.12))
            
            if cleaner.isScanning {
                VStack(spacing: 20) {
                    ProgressView(value: cleaner.scanProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 340)
                    Text("Analyzing application caches, logs, and developer temporary build directories...")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if cleaner.items.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 56))
                        .foregroundStyle(Color(hex: "#38BDF8"))
                    Text("Ready to Clean")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.95))
                    Text("Click 'Scan System' above to compute exact cleanable storage footprint.")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        // Summary Banner Card
                        GlassCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("SELECTED SPACE READY FOR CLEANUP")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.white.opacity(0.7))
                                    Text(ByteFormatter.string(from: cleaner.totalSelectedSizeBytes))
                                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                                        .foregroundStyle(Color(hex: "#38BDF8"))
                                    Text("Total scanned across all categories: \(ByteFormatter.string(from: cleaner.totalScannedSizeBytes))")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(Color.white.opacity(0.65))
                                }
                                Spacer()
                                
                                HStack(spacing: 12) {
                                    Button("Select All") {
                                        for i in 0..<cleaner.items.count {
                                            cleaner.items[i].isSelected = true
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .foregroundStyle(Color.white.opacity(0.9))
                                    
                                    Button("Deselect All") {
                                        for i in 0..<cleaner.items.count {
                                            cleaner.items[i].isSelected = false
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .foregroundStyle(Color.white.opacity(0.9))
                                    
                                    Button(action: {
                                        Task {
                                            let result = await cleaner.performClean()
                                            cleanedBytes = result.reclaimedBytes
                                            withAnimation { showSuccessBanner = true }
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: cleaner.dryRunMode ? "eye.circle" : "trash.fill")
                                            Text(cleaner.dryRunMode ? "Simulate Clean (Dry Run)" : "Clean Selected Items")
                                        }
                                        .font(.headline.weight(.bold))
                                        .padding(.horizontal, 22)
                                        .padding(.vertical, 11)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(cleaner.dryRunMode ? Color(hex: "#0284C7") : Color(hex: "#DC2626"))
                                    .disabled(cleaner.totalSelectedSizeBytes == 0 || cleaner.isCleaning)
                                }
                            }
                        }
                        
                        if showSuccessBanner {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color(hex: "#10B981"))
                                    .font(.title2)
                                Text(cleaner.dryRunMode ? "Dry Run simulation finished! Space to reclaim: \(ByteFormatter.string(from: cleanedBytes))" : "Cleaning complete! Reclaimed \(ByteFormatter.string(from: cleanedBytes)) of disk space.")
                                    .font(.body.weight(.bold))
                                    .foregroundStyle(Color.white.opacity(0.95))
                                Spacer()
                                Button("Dismiss") { withAnimation { showSuccessBanner = false } }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(Color.white.opacity(0.8))
                            }
                            .padding(16)
                            .background(Color(hex: "#065F46").opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#10B981"), lineWidth: 1))
                        }
                        
                        // Category Items Breakdown
                        ForEach(CleanCategory.allCases) { category in
                            let categoryItems = cleaner.items.filter { $0.category == category }
                            if !categoryItems.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: category.iconName)
                                            .foregroundStyle(Color(hex: "#38BDF8"))
                                            .font(.title3)
                                        Text(category.rawValue)
                                            .font(.title3.weight(.bold))
                                            .foregroundStyle(Color.white.opacity(0.95))
                                        Spacer()
                                        Text(ByteFormatter.string(from: categoryItems.reduce(0) { $0 + $1.sizeBytes }))
                                            .font(.subheadline.weight(.bold).monospacedDigit())
                                            .foregroundStyle(Color(hex: "#38BDF8"))
                                    }
                                    
                                    GlassCard(padding: 0) {
                                        VStack(spacing: 0) {
                                            ForEach(categoryItems) { item in
                                                HStack(spacing: 14) {
                                                    Toggle("", isOn: Binding(
                                                        get: { item.isSelected },
                                                        set: { newValue in
                                                            if let idx = cleaner.items.firstIndex(where: { $0.id == item.id }) {
                                                                cleaner.items[idx].isSelected = newValue
                                                            }
                                                        }
                                                    ))
                                                    .toggleStyle(.checkbox)
                                                    
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(item.name)
                                                            .font(.system(size: 15, weight: .bold))
                                                            .foregroundStyle(Color.white.opacity(0.95))
                                                        
                                                        // High-Contrast Path Readability Fix
                                                        Text(item.path)
                                                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                                                            .foregroundStyle(Color.white.opacity(0.75))
                                                            .lineLimit(1)
                                                    }
                                                    Spacer()
                                                    
                                                    Text(ByteFormatter.string(from: item.sizeBytes))
                                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                                        .foregroundStyle(Color.white.opacity(0.9))
                                                }
                                                .padding(14)
                                                .background(Color.white.opacity(0.02))
                                            }
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
    }
}
