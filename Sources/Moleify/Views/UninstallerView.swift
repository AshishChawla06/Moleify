import SwiftUI

public struct UninstallerView: View {
    @EnvironmentObject private var uninstaller: UninstallerService
    @State private var selectedApp: AppInfoItem?
    @State private var reclaimedSpace: UInt64 = 0
    @State private var showSuccessBanner: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Deep Application Uninstaller")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.98))
                    Text("Thoroughly remove macOS applications along with associated hidden preferences, caches, and containers")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                Spacer()
                
                Button(action: {
                    Task {
                        await uninstaller.scanInstalledApplications()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text(uninstaller.isScanning ? "Scanning..." : "Scan Apps")
                    }
                    .font(.headline.weight(.bold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#0284C7"))
                .disabled(uninstaller.isScanning)
            }
            .padding(24)
            .background(Color(red: 0.10, green: 0.11, blue: 0.15))
            
            Divider().background(Color.white.opacity(0.12))
            
            if uninstaller.isScanning {
                VStack(spacing: 20) {
                    ProgressView(value: uninstaller.scanProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 340)
                    Text("Scanning /Applications directory and analyzing associated leftover dependencies...")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if uninstaller.installedApps.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "square.grid.3x3.topleft.filled")
                        .font(.system(size: 56))
                        .foregroundStyle(Color(hex: "#818CF8"))
                    Text("Scan Installed Applications")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.95))
                    Text("Click 'Scan Apps' above to detect installed macOS applications and compute their hidden leftover files.")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 0) {
                    // Left App List Pane
                    VStack(spacing: 12) {
                        // Search Field
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.white.opacity(0.6))
                            TextField("Search installed apps...", text: $uninstaller.searchQuery)
                                .textFieldStyle(.plain)
                                .foregroundStyle(Color.white)
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                        
                        List(selection: $selectedApp) {
                            ForEach(uninstaller.filteredApps) { app in
                                HStack(spacing: 12) {
                                    Image(systemName: "app.fill")
                                        .font(.title2)
                                        .foregroundStyle(Color(hex: "#818CF8"))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(app.name)
                                            .font(.body.weight(.bold))
                                            .foregroundStyle(Color.white.opacity(0.95))
                                        Text(app.bundleId)
                                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                                            .foregroundStyle(Color.white.opacity(0.7))
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    
                                    Text(ByteFormatter.string(from: app.totalSizeBytes))
                                        .font(.caption.weight(.heavy).monospacedDigit())
                                        .foregroundStyle(Color(hex: "#38BDF8"))
                                }
                                .padding(.vertical, 4)
                                .tag(app)
                            }
                        }
                        .listStyle(.sidebar)
                    }
                    .frame(width: 350)
                    .padding(16)
                    
                    Divider().background(Color.white.opacity(0.12))
                    
                    // Right App Inspector Pane
                    if let app = selectedApp {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                GlassCard {
                                    HStack(spacing: 18) {
                                        Image(systemName: "app.dashed")
                                            .font(.system(size: 52))
                                            .foregroundStyle(Color(hex: "#818CF8"))
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(app.name)
                                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                                .foregroundStyle(Color.white.opacity(0.98))
                                            Text(app.path)
                                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                                .foregroundStyle(Color.white.opacity(0.75))
                                        }
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("TOTAL FOOTPRINT")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(Color.white.opacity(0.7))
                                            Text(ByteFormatter.string(from: app.totalSizeBytes))
                                                .font(.title2.weight(.heavy))
                                                .foregroundStyle(Color(hex: "#38BDF8"))
                                        }
                                    }
                                }
                                
                                if showSuccessBanner {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color(hex: "#10B981"))
                                            .font(.title3)
                                        Text("Successfully uninstalled \(app.name)! Reclaimed \(ByteFormatter.string(from: reclaimedSpace)).")
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
                                
                                VStack(alignment: .leading, spacing: 14) {
                                    Text("App Bundle & Hidden Leftovers")
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(Color.white.opacity(0.95))
                                    
                                    // Main Bundle Card
                                    GlassCard {
                                        HStack {
                                            Image(systemName: "shippingbox.fill")
                                                .font(.title3)
                                                .foregroundStyle(Color(hex: "#38BDF8"))
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Main Executable App Bundle")
                                                    .font(.body.weight(.bold))
                                                    .foregroundStyle(Color.white.opacity(0.95))
                                                Text(app.path)
                                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                                    .foregroundStyle(Color.white.opacity(0.75))
                                            }
                                            Spacer()
                                            Text(ByteFormatter.string(from: app.bundleSizeBytes))
                                                .font(.body.weight(.heavy).monospacedDigit())
                                                .foregroundStyle(Color.white.opacity(0.95))
                                        }
                                    }
                                    
                                    // Leftovers List Card
                                    if app.leftovers.isEmpty {
                                        GlassCard {
                                            Text("No leftover preference or container files detected for this application.")
                                                .font(.subheadline)
                                                .foregroundStyle(Color.white.opacity(0.75))
                                        }
                                    } else {
                                        ForEach(app.leftovers) { leftover in
                                            GlassCard {
                                                HStack {
                                                    Image(systemName: leftover.type.iconName)
                                                        .font(.title3)
                                                        .foregroundStyle(Color(hex: "#F97316"))
                                                    
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text("\(leftover.type.rawValue): \(leftover.name)")
                                                            .font(.body.weight(.bold))
                                                            .foregroundStyle(Color.white.opacity(0.95))
                                                        Text(leftover.path)
                                                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                                                            .foregroundStyle(Color.white.opacity(0.75))
                                                            .lineLimit(1)
                                                    }
                                                    Spacer()
                                                    
                                                    Text(ByteFormatter.string(from: leftover.sizeBytes))
                                                        .font(.body.weight(.bold).monospacedDigit())
                                                        .foregroundStyle(Color.white.opacity(0.9))
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        Task {
                                            let space = await uninstaller.uninstallApp(app)
                                            reclaimedSpace = space
                                            withAnimation { showSuccessBanner = true }
                                            selectedApp = nil
                                        }
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "trash.fill")
                                            Text("Uninstall \(app.name) Completely")
                                        }
                                        .font(.headline.weight(.bold))
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(Color(hex: "#DC2626"))
                                }
                            }
                            .padding(24)
                        }
                    } else {
                        VStack(spacing: 14) {
                            Image(systemName: "cursorarrow.click")
                                .font(.system(size: 44))
                                .foregroundStyle(Color.white.opacity(0.5))
                            Text("Select an application from the sidebar to inspect bundle and leftover items.")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.white.opacity(0.75))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
    }
}
