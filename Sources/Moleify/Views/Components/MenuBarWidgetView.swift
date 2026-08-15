import SwiftUI

public struct MenuBarWidgetView: View {
    @EnvironmentObject private var monitor: SystemMonitorService
    @EnvironmentObject private var optimizer: OptimizerService
    @EnvironmentObject private var cleaner: CleanerService
    @Environment(\.openWindow) private var openWindow
    
    @State private var showPurgeToast: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 14) {
            // Widget Header with Mini Cat Companion
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(monitor.stats.cpuUsage >= 65 ? Color(hex: "#F97316").opacity(0.3) : Color(hex: "#38BDF8").opacity(0.3))
                        .frame(width: 36, height: 36)
                        .blur(radius: 4)
                    
                    Image(systemName: "cat.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(monitor.stats.cpuUsage >= 65 ? Color(hex: "#F97316") : Color(hex: "#38BDF8"))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Moleify Live Status")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.98))
                    Text(monitor.stats.cpuUsage >= 65 ? "High Load • Zoomies! ⚡" : "System Running Cool 🐾")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                Spacer()
                
                GlassBadge("\(Int(monitor.stats.cpuUsage))% CPU", color: Color(hex: "#38BDF8"))
            }
            .padding(12)
            .background(Color(red: 0.12, green: 0.14, blue: 0.20), in: RoundedRectangle(cornerRadius: 12))
            
            if showPurgeToast {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(hex: "#10B981"))
                    Text("RAM Purged!")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.95))
                    Spacer()
                }
                .padding(8)
                .background(Color(hex: "#065F46").opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
            }
            
            // Metrics Compact Cards
            VStack(spacing: 10) {
                // CPU Metric Row
                HStack {
                    Label("CPU Load", systemImage: "cpu")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.9))
                    Spacer()
                    CustomProgressBar(value: monitor.stats.cpuUsage / 100.0, color: Color(hex: "#38BDF8"), height: 6)
                        .frame(width: 90)
                    Text("\(Int(monitor.stats.cpuUsage))%")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color(hex: "#38BDF8"))
                        .frame(width: 45, alignment: .trailing)
                }
                
                // RAM Metric Row
                HStack {
                    Label("RAM Used", systemImage: "memorychip")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.9))
                    Spacer()
                    let ramFraction = monitor.stats.totalMemory > 0 ? Double(monitor.stats.usedMemory) / Double(monitor.stats.totalMemory) : 0.4
                    CustomProgressBar(value: ramFraction, color: Color(hex: "#A855F7"), height: 6)
                        .frame(width: 90)
                    Text(ByteFormatter.string(from: monitor.stats.usedMemory))
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color(hex: "#C084FC"))
                        .frame(width: 75, alignment: .trailing)
                }
                
                // Disk Free Row
                HStack {
                    Label("Macintosh HD", systemImage: "internaldrive")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.9))
                    Spacer()
                    Text("Free \(ByteFormatter.string(from: monitor.stats.freeDiskSpace))")
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color(hex: "#2DD4BF"))
                }
                
                // Network Speed Row
                HStack {
                    Label("Network", systemImage: "network")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.9))
                    Spacer()
                    Text("↓ \(ByteFormatter.string(from: UInt64(monitor.stats.downloadSpeedBytesPerSec)))/s")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color(hex: "#38BDF8"))
                    Text("↑ \(ByteFormatter.string(from: UInt64(monitor.stats.uploadSpeedBytesPerSec)))/s")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(Color(hex: "#60A5FA"))
                }
            }
            .padding(12)
            .background(Color(red: 0.12, green: 0.14, blue: 0.18), in: RoundedRectangle(cornerRadius: 12))
            
            // Quick Widget Actions Footer
            HStack(spacing: 10) {
                Button(action: {
                    Task {
                        if let task = optimizer.tasks.first(where: { $0.id == "purge_ram" }) {
                            await optimizer.executeTask(task)
                            withAnimation { showPurgeToast = true }
                        }
                    }
                }) {
                    Label("Purge RAM", systemImage: "bolt.fill")
                        .font(.caption.weight(.bold))
                }
                .buttonStyle(.bordered)
                .tint(Color(hex: "#A855F7"))
                
                Button(action: {
                    Task {
                        await cleaner.startScan()
                    }
                }) {
                    Label("Scan Caches", systemImage: "sparkles")
                        .font(.caption.weight(.bold))
                }
                .buttonStyle(.bordered)
                .tint(Color(hex: "#38BDF8"))
                
                Spacer()
                
                Button("Quit Widget") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.6))
            }
        }
        .padding(16)
        .frame(width: 330)
        .background(Color(red: 0.08, green: 0.09, blue: 0.12))
        .preferredColorScheme(.dark)
    }
}
