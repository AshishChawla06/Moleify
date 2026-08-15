import SwiftUI

public struct DashboardView: View {
    @EnvironmentObject private var monitor: SystemMonitorService
    @EnvironmentObject private var optimizer: OptimizerService
    @State private var processSearchQuery: String = ""
    @State private var showPurgeToast: Bool = false
    
    public init() {}
    
    public var filteredProcesses: [ProcessInfoItem] {
        if processSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return monitor.topProcesses
        } else {
            return monitor.topProcesses.filter {
                $0.name.localizedCaseInsensitiveContains(processSearchQuery) ||
                "\($0.id)".contains(processSearchQuery)
            }
        }
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Banner
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("System Dashboard")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("Real-time macOS telemetry updated every 1.5s via Metal 3 GPU shaders & Darwin Kernel statistics")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    
                    GlassBadge("System Status: Optimal", iconName: "checkmark.shield.fill", color: Color.appleGreen)
                }
                
                // Reactive Cat Companion Animation Header
                CatAnimationView(cpuUsage: monitor.stats.cpuUsage)
                
                if showPurgeToast {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.appleGreen)
                        Text("RAM purge executed! Inactive memory freed back to kernel.")
                            .font(.body.weight(.bold))
                            .foregroundStyle(.primary)
                        Spacer()
                        Button("Dismiss") { showPurgeToast = false }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .background(Color.appleGreen.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appleGreen.opacity(0.4), lineWidth: 1))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Top Metrics Grid with Metal Gauges & Live Real-Time Graphs
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                    // CPU Gauge & Live Graph Card
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "cpu")
                                        .font(.title3)
                                        .foregroundStyle(Color.appleBlue)
                                    Text("CPU Load")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.primary)
                                }
                                Spacer()
                                Text("\(Int(monitor.stats.cpuUsage))%")
                                    .font(.title2.weight(.heavy).monospacedDigit())
                                    .foregroundStyle(Color.appleBlue)
                            }
                            
                            HStack {
                                Spacer()
                                ZStack {
                                    MetalParticleGaugeView(
                                        usageValue: monitor.stats.cpuUsage / 100.0,
                                        themeColor: SIMD3<Float>(0.0, 0.48, 1.0)
                                    )
                                    .frame(width: 120, height: 120)
                                    
                                    VStack(spacing: 2) {
                                        Text("\(monitor.stats.cpuCores.count) Cores")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.primary)
                                        Text("Apple Silicon")
                                            .font(.caption2.weight(.medium))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            
                            // Real-Time CPU History Line Graph
                            VStack(alignment: .leading, spacing: 6) {
                                SectionHeaderLabel("30s Load Trend")
                                
                                RealTimeLineGraph(
                                    dataPoints: monitor.cpuHistory,
                                    gradientColors: [Color.appleBlue, Color.appleCyan],
                                    height: 50
                                )
                            }
                        }
                    }
                    
                    // RAM Memory Card
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "memorychip")
                                        .font(.title3)
                                        .foregroundStyle(Color.applePurple)
                                    Text("RAM Memory")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.primary)
                                }
                                Spacer()
                                Button(action: {
                                    Task {
                                        if let task = optimizer.tasks.first(where: { $0.id == "purge_ram" }) {
                                             await optimizer.executeTask(task)
                                            withAnimation { showPurgeToast = true }
                                        }
                                    }
                                }) {
                                    Label("Purge", systemImage: "bolt.fill")
                                        .font(.caption.weight(.bold))
                                }
                                .buttonStyle(.bordered)
                                .tint(Color.applePurple)
                            }
                            
                            HStack {
                                Spacer()
                                ZStack {
                                    MetalParticleGaugeView(
                                        usageValue: monitor.stats.totalMemory > 0 ? Double(monitor.stats.usedMemory) / Double(monitor.stats.totalMemory) : 0.4,
                                        themeColor: SIMD3<Float>(0.68, 0.32, 0.87)
                                    )
                                    .frame(width: 120, height: 120)
                                    
                                    VStack(spacing: 2) {
                                        Text(ByteFormatter.string(from: monitor.stats.usedMemory))
                                            .font(.subheadline.weight(.heavy).monospacedDigit())
                                            .foregroundStyle(Color.applePurple)
                                        Text("of \(ByteFormatter.string(from: monitor.stats.totalMemory))")
                                            .font(.caption2.weight(.medium))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            
                            // Memory Composition Breakdown Bar
                            VStack(alignment: .leading, spacing: 6) {
                                GeometryReader { geo in
                                    HStack(spacing: 1) {
                                        let total = max(Double(monitor.stats.totalMemory), 1.0)
                                        Rectangle().fill(Color.applePurple).frame(width: geo.size.width * CGFloat(Double(monitor.stats.appMemory) / total))
                                        Rectangle().fill(Color.appleIndigo).frame(width: geo.size.width * CGFloat(Double(monitor.stats.wiredMemory) / total))
                                        Rectangle().fill(Color.appleOrange).frame(width: geo.size.width * CGFloat(Double(monitor.stats.compressedMemory) / total))
                                        Rectangle().fill(Color.white.opacity(0.15)).frame(width: geo.size.width * CGFloat(Double(monitor.stats.freeMemory) / total))
                                    }
                                    .clipShape(Capsule())
                                }
                                .frame(height: 8)
                                
                                HStack(spacing: 8) {
                                    Label("App: \(ByteFormatter.string(from: monitor.stats.appMemory))", systemImage: "circle.fill")
                                        .foregroundStyle(Color.applePurple)
                                    Spacer()
                                    Label("Wired: \(ByteFormatter.string(from: monitor.stats.wiredMemory))", systemImage: "circle.fill")
                                        .foregroundStyle(Color.appleIndigo)
                                }
                                .font(.caption.weight(.semibold))
                            }
                        }
                    }
                    
                    // Disk Space & Throughput
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                HStack(spacing: 8) {
                                    Image(systemName: "internaldrive")
                                        .font(.title3)
                                        .foregroundStyle(Color.appleTeal)
                                    Text("Macintosh HD")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(.primary)
                                }
                                Spacer()
                                Text("\(Int((Double(monitor.stats.usedDiskSpace) / max(Double(monitor.stats.totalDiskSpace), 1.0)) * 100))%")
                                    .font(.title2.weight(.heavy).monospacedDigit())
                                    .foregroundStyle(Color.appleTeal)
                            }
                            
                            HStack {
                                Spacer()
                                ZStack {
                                    MetalParticleGaugeView(
                                        usageValue: Double(monitor.stats.usedDiskSpace) / max(Double(monitor.stats.totalDiskSpace), 1.0),
                                        themeColor: SIMD3<Float>(0.19, 0.69, 0.78)
                                    )
                                    .frame(width: 120, height: 120)
                                    
                                    VStack(spacing: 2) {
                                        Text("Free \(ByteFormatter.string(from: monitor.stats.freeDiskSpace))")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(.primary)
                                        Text("Capacity \(ByteFormatter.string(from: monitor.stats.totalDiskSpace))")
                                            .font(.caption2.weight(.medium))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            
                            VStack(spacing: 6) {
                                HStack {
                                    Label("Read Speed", systemImage: "arrow.down.circle")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(String(format: "%.1f", monitor.stats.diskReadSpeedMBps)) MB/s")
                                        .font(.caption.weight(.bold).monospacedDigit())
                                        .foregroundStyle(.primary)
                                }
                                HStack {
                                    Label("Write Speed", systemImage: "arrow.up.circle")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(String(format: "%.1f", monitor.stats.diskWriteSpeedMBps)) MB/s")
                                        .font(.caption.weight(.bold).monospacedDigit())
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                    }
                }
                
                // Network Live Dual Graph Card
                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "network")
                                .font(.title2)
                                .foregroundStyle(Color.appleCyan)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Real-Time Network Telemetry")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.primary)
                                Text("Live upload and download throughput history")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            
                            HStack(spacing: 20) {
                                Label("↓ \(ByteFormatter.string(from: UInt64(monitor.stats.downloadSpeedBytesPerSec)))/s", systemImage: "arrow.down")
                                    .font(.subheadline.weight(.bold).monospacedDigit())
                                    .foregroundStyle(Color.appleCyan)
                                Label("↑ \(ByteFormatter.string(from: UInt64(monitor.stats.uploadSpeedBytesPerSec)))/s", systemImage: "arrow.up")
                                    .font(.subheadline.weight(.bold).monospacedDigit())
                                    .foregroundStyle(Color.appleBlue)
                            }
                        }
                        
                        RealTimeLineGraph(
                            dataPoints: monitor.downloadHistory,
                            gradientColors: [Color.appleCyan, Color.appleBlue],
                            height: 70
                        )
                    }
                }
                
                // Top Active Processes Section
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Top Active Processes")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.primary)
                            Text("Inspect live processes sorted by CPU load and memory consumption")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        
                        // Process Search Filter
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Filter process...", text: $processSearchQuery)
                                .textFieldStyle(.plain)
                                .foregroundStyle(.primary)
                                .frame(width: 160)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                    
                    GlassCard(padding: 0) {
                        VStack(spacing: 0) {
                            HStack {
                                Text("Process Name").frame(width: 220, alignment: .leading)
                                Text("PID").frame(width: 80, alignment: .leading)
                                Text("User").frame(width: 100, alignment: .leading)
                                Text("CPU %").frame(width: 100, alignment: .trailing)
                                Text("Memory").frame(width: 120, alignment: .trailing)
                                Spacer()
                            }
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.04))
                            
                            Divider().background(Color.white.opacity(0.12))
                            
                            ForEach(filteredProcesses) { proc in
                                HStack {
                                    HStack(spacing: 10) {
                                        Image(systemName: "gearshape.fill")
                                            .font(.caption)
                                            .foregroundStyle(Color.appleBlue)
                                        Text(proc.name)
                                            .font(.body.weight(.bold))
                                            .foregroundStyle(.primary)
                                    }
                                    .frame(width: 220, alignment: .leading)
                                    
                                    Text("\(proc.id)").font(.caption.weight(.medium).monospacedDigit()).foregroundStyle(.secondary).frame(width: 80, alignment: .leading)
                                    Text(proc.user).font(.caption.weight(.medium)).foregroundStyle(.secondary).frame(width: 100, alignment: .leading)
                                    Text("\(String(format: "%.1f", proc.cpuUsagePercentage))%").font(.body.weight(.heavy).monospacedDigit()).foregroundStyle(Color.appleBlue).frame(width: 100, alignment: .trailing)
                                    Text("\(Int(proc.memoryUsageMB)) MB").font(.body.weight(.bold).monospacedDigit()).foregroundStyle(.primary).frame(width: 120, alignment: .trailing)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.01))
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}
