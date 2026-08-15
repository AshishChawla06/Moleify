import SwiftUI

public struct InstallerView: View {
    @EnvironmentObject private var installer: InstallerService
    @State private var showSuccessBanner: Bool = false
    @State private var reclaimedSpace: UInt64 = 0
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Installer Files Finder")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.98))
                    Text("Locate and remove leftover disk images (.dmg, .pkg, .iso) taking up space in Downloads & Desktop")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                Spacer()
                
                Button(action: {
                    Task {
                        await installer.scanInstallers()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.zipper")
                        Text(installer.isScanning ? "Scanning..." : "Find Installers")
                    }
                    .font(.headline.weight(.bold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#0284C7"))
                .disabled(installer.isScanning || installer.isRemoving)
            }
            .padding(24)
            .background(Color(red: 0.10, green: 0.11, blue: 0.15))
            
            Divider().background(Color.white.opacity(0.12))
            
            if installer.isScanning {
                VStack(spacing: 20) {
                    ProgressView()
                    Text("Scanning Downloads and Desktop folders for installer packages...")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if installer.installers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "internaldrive.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color(hex: "#10B981"))
                    Text("Find & Clean Installer Packages")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.95))
                    Text("Click 'Find Installers' above to search for leftover .dmg and .pkg packages.")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        GlassCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("INSTALLER PACKAGES FOUND")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.white.opacity(0.7))
                                    Text(ByteFormatter.string(from: installer.totalSelectedBytes))
                                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                                        .foregroundStyle(Color(hex: "#10B981"))
                                }
                                Spacer()
                                
                                Button(action: {
                                    Task {
                                        let space = await installer.removeSelectedInstallers()
                                        reclaimedSpace = space
                                        withAnimation { showSuccessBanner = true }
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trash.fill")
                                        Text("Move Selected Installers to Trash")
                                    }
                                    .font(.headline.weight(.bold))
                                    .padding(.horizontal, 22)
                                    .padding(.vertical, 11)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color(hex: "#DC2626"))
                                .disabled(installer.totalSelectedBytes == 0 || installer.isRemoving)
                            }
                        }
                        
                        if showSuccessBanner {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color(hex: "#10B981"))
                                    .font(.title2)
                                Text("Installer packages moved to Trash! Reclaimed \(ByteFormatter.string(from: reclaimedSpace)).")
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
                        
                        GlassCard(padding: 0) {
                            VStack(spacing: 0) {
                                ForEach(installer.installers) { item in
                                    HStack(spacing: 14) {
                                        Toggle("", isOn: Binding(
                                            get: { item.isSelected },
                                            set: { newValue in
                                                if let idx = installer.installers.firstIndex(where: { $0.id == item.id }) {
                                                    installer.installers[idx].isSelected = newValue
                                                }
                                            }
                                        ))
                                        .toggleStyle(.checkbox)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 8) {
                                                Text(item.name)
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundStyle(Color.white.opacity(0.95))
                                                
                                                Text(item.extensionType.uppercased())
                                                    .font(.caption2.weight(.bold))
                                                    .foregroundStyle(Color(hex: "#10B981"))
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color(hex: "#10B981").opacity(0.18), in: Capsule())
                                            }
                                            
                                            Text(item.path)
                                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                                .foregroundStyle(Color.white.opacity(0.75))
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        
                                        Text(ByteFormatter.string(from: item.sizeBytes))
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundStyle(Color(hex: "#10B981"))
                                    }
                                    .padding(14)
                                    .background(Color.white.opacity(0.02))
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
