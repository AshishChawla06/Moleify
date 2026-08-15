import SwiftUI

public struct UpdaterView: View {
    @EnvironmentObject private var updater: AutoUpdaterService
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto Updater & Component Synchronizer")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("mo update • Automatically keep cleaning definitions, optimizer scripts, hardware profiles, and CLI components up to date")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            Task {
                                await updater.checkForUpdates(autoApplyComponents: false)
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text(updater.isChecking ? "Checking..." : "Check for Updates")
                            }
                            .font(.headline.weight(.bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .disabled(updater.isChecking || updater.isUpdatingAll)
                        
                        Button(action: {
                            Task {
                                await updater.updateAllComponents()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.down.circle.fill")
                                Text(updater.isUpdatingAll ? "Updating..." : "Update All Components")
                            }
                            .font(.headline.weight(.bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.appleBlue)
                        .disabled(updater.isUpdatingAll)
                    }
                }
                
                // Live Updating Progress Banner
                if updater.isUpdatingAll {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "gearshape.arrow.triangle.2.circlepath")
                                    .foregroundStyle(Color.appleBlue)
                                    .font(.title3)
                                Text(updater.currentOperationText)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("\(Int(updater.updateProgress * 100))%")
                                    .font(.headline.weight(.heavy).monospacedDigit())
                                    .foregroundStyle(Color.appleBlue)
                            }
                            
                            ProgressView(value: updater.updateProgress, total: 1.0)
                                .tint(Color.appleBlue)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Automated Preferences Card
                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeaderLabel("Automatic Component Synchronizer Settings")
                        
                        HStack(spacing: 30) {
                            Toggle("Check for updates automatically on app launch", isOn: $updater.autoCheckOnLaunch)
                                .font(.body.weight(.medium))
                            
                            Toggle("Automatically install cleaning rules & component updates", isOn: $updater.autoInstallComponents)
                                .font(.body.weight(.medium))
                        }
                        .toggleStyle(.switch)
                    }
                }
                
                // Status Overview Card
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CURRENT INSTALLED ENGINE VERSION")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            Text("v\(updater.currentVersion) (Moleify Native GUI & tw93/mole)")
                                .font(.title2.weight(.bold).monospacedDigit())
                                .foregroundStyle(Color.appleBlue)
                        }
                        Spacer()
                        
                        if let release = updater.latestRelease {
                            GlassBadge(
                                updater.isUpdateAvailable ? "New Release Available (\(release.tagName))" : "All Components Up to Date (\(release.tagName))",
                                iconName: updater.isUpdateAvailable ? "arrow.up.circle.fill" : "checkmark.circle.fill",
                                color: updater.isUpdateAvailable ? Color.appleOrange : Color.appleGreen
                            )
                        }
                    }
                }
                
                if !updater.errorMessage.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.appleOrange)
                        Text(updater.errorMessage)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(14)
                    .background(Color.appleOrange.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                }
                
                // Subsystem Components Grid
                VStack(alignment: .leading, spacing: 14) {
                    SectionHeaderLabel("Subsystem Components & Cleaning Definitions")
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                        ForEach(updater.components) { comp in
                            GlassCard(padding: 16) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 12) {
                                        Image(systemName: comp.iconName)
                                            .font(.title2)
                                            .foregroundStyle(Color(hex: comp.colorHex))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(comp.name)
                                                .font(.headline.weight(.bold))
                                                .foregroundStyle(.primary)
                                            Text("Version \(comp.currentVersion)")
                                                .font(.caption.weight(.medium).monospacedDigit())
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        
                                        // Component Status Badge
                                        switch comp.status {
                                        case .upToDate:
                                            GlassBadge("Up to Date", iconName: "checkmark", color: Color.appleGreen)
                                        case .updateAvailable:
                                            GlassBadge("Update Ready", iconName: "arrow.up", color: Color.appleOrange)
                                        case .updating:
                                            ProgressView().scaleEffect(0.7)
                                        case .updated:
                                            GlassBadge("Updated", iconName: "sparkles", color: Color.appleBlue)
                                        case .failed:
                                            GlassBadge("Failed", iconName: "xmark", color: Color.appleRed)
                                        }
                                    }
                                    
                                    Text(comp.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                    
                                    Divider().background(Color.white.opacity(0.1))
                                    
                                    HStack {
                                        Text("Latest: \(comp.latestVersion)")
                                            .font(.caption2.weight(.semibold).monospacedDigit())
                                            .foregroundStyle(.tertiary)
                                        Spacer()
                                        
                                        Button("Update Component") {
                                            Task {
                                                await updater.updateSingleComponent(id: comp.id)
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        .font(.caption.weight(.bold))
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Latest Release Notes Card
                if let release = updater.latestRelease {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(release.name.isEmpty ? release.tagName : release.name)
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(.primary)
                                    Text("Published on GitHub: \(release.publishedAt)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                
                                Button(action: {
                                    updater.openReleasePage()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "safari")
                                        Text("Open on GitHub")
                                    }
                                    .font(.headline.weight(.bold))
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.appleGreen)
                            }
                            
                            Divider().background(Color.white.opacity(0.12))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Release Notes & Upstream Changelog:")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.secondary)
                                
                                Text(release.body.isEmpty ? "No changelog provided in this release." : release.body)
                                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                                    .foregroundStyle(.primary)
                                    .padding(12)
                                    .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                
                // Real-Time Update Execution Terminal Log
                if !updater.updateLogs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeaderLabel("Update Execution Log")
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(updater.updateLogs.enumerated()), id: \.offset) { _, log in
                                    Text(log)
                                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                                        .foregroundStyle(Color.appleCyan)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                        }
                        .frame(height: 110)
                        .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                }
            }
            .padding(24)
        }
    }
}
