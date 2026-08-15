import SwiftUI

public struct PurgeView: View {
    @EnvironmentObject private var purge: PurgeService
    @State private var showSuccessBanner: Bool = false
    @State private var reclaimedSpace: UInt64 = 0
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Project Build Artifacts Purge")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.98))
                    Text("Reclaim massive disk space by purging node_modules, .build, target/, and venv project dependencies")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                Spacer()
                
                Button(action: {
                    Task {
                        await purge.scanProjectArtifacts()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "folder.badge.gearshape")
                        Text(purge.isScanning ? "Scanning..." : "Scan Projects")
                    }
                    .font(.headline.weight(.bold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#0284C7"))
                .disabled(purge.isScanning || purge.isPurging)
            }
            .padding(24)
            .background(Color(red: 0.10, green: 0.11, blue: 0.15))
            
            Divider().background(Color.white.opacity(0.12))
            
            if purge.isScanning {
                VStack(spacing: 20) {
                    ProgressView(value: purge.scanProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 340)
                    Text("Scanning Developer and Project directories for build artifacts...")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if purge.artifacts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "hammer.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color(hex: "#F59E0B"))
                    Text("Purge Project Build Artifacts")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.95))
                    Text("Click 'Scan Projects' above to locate heavy build outputs (node_modules, target/, .build).")
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
                                    Text("PROJECT BUILD ARTIFACTS TO PURGE")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(Color.white.opacity(0.7))
                                    Text(ByteFormatter.string(from: purge.totalSelectedBytes))
                                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                                        .foregroundStyle(Color(hex: "#F59E0B"))
                                }
                                Spacer()
                                
                                Button(action: {
                                    Task {
                                        let space = await purge.purgeSelected()
                                        reclaimedSpace = space
                                        withAnimation { showSuccessBanner = true }
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "trash.fill")
                                        Text("Purge Selected Artifacts")
                                    }
                                    .font(.headline.weight(.bold))
                                    .padding(.horizontal, 22)
                                    .padding(.vertical, 11)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color(hex: "#DC2626"))
                                .disabled(purge.totalSelectedBytes == 0 || purge.isPurging)
                            }
                        }
                        
                        if showSuccessBanner {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color(hex: "#10B981"))
                                    .font(.title2)
                                Text("Project artifacts purged! Reclaimed \(ByteFormatter.string(from: reclaimedSpace)) of disk space.")
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
                        
                        // Artifact List
                        GlassCard(padding: 0) {
                            VStack(spacing: 0) {
                                ForEach(purge.artifacts) { item in
                                    HStack(spacing: 14) {
                                        Toggle("", isOn: Binding(
                                            get: { item.isSelected },
                                            set: { newValue in
                                                if let idx = purge.artifacts.firstIndex(where: { $0.id == item.id }) {
                                                    purge.artifacts[idx].isSelected = newValue
                                                }
                                            }
                                        ))
                                        .toggleStyle(.checkbox)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            HStack(spacing: 8) {
                                                Text(item.projectName)
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundStyle(Color.white.opacity(0.95))
                                                
                                                Text(item.artifactType)
                                                    .font(.caption.weight(.bold))
                                                    .foregroundStyle(Color(hex: "#F59E0B"))
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 3)
                                                    .background(Color(hex: "#F59E0B").opacity(0.18), in: Capsule())
                                            }
                                            
                                            Text(item.path)
                                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                                .foregroundStyle(Color.white.opacity(0.75))
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        
                                        Text(ByteFormatter.string(from: item.sizeBytes))
                                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                                            .foregroundStyle(Color(hex: "#F59E0B"))
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
