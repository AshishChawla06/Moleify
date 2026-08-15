import SwiftUI

public struct UtilitiesView: View {
    @EnvironmentObject private var touchID: TouchIDService
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Touch ID & CLI Utilities")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.98))
                    Text("Configure Apple Touch ID authentication for sudo commands, set up shell aliases, and view CLI shortcuts")
                        .font(.subheadline)
                        .foregroundStyle(Color.white.opacity(0.75))
                }
                
                if !touchID.statusMessage.isEmpty {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Color(hex: "#38BDF8"))
                        Text(touchID.statusMessage)
                            .font(.body.weight(.bold))
                            .foregroundStyle(Color.white.opacity(0.95))
                        Spacer()
                        Button("Dismiss") { touchID.statusMessage = "" }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.white.opacity(0.8))
                    }
                    .padding(14)
                    .background(Color(hex: "#0284C7").opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#38BDF8"), lineWidth: 1))
                }
                
                // Utility Cards Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                    // Touch ID Card (mo touchid)
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "touchid")
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: "#38BDF8"))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Touch ID for Sudo")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(Color.white.opacity(0.95))
                                    Text("mo touchid")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(Color.white.opacity(0.6))
                                }
                                Spacer()
                            }
                            
                            Text("Allows authenticating sudo terminal actions using Apple Silicon Touch ID instead of typing password.")
                                .font(.subheadline)
                                .foregroundStyle(Color.white.opacity(0.75))
                            
                            HStack {
                                GlassBadge(touchID.isTouchIDEnabled ? "Touch ID Active" : "Touch ID Disabled", color: touchID.isTouchIDEnabled ? Color(hex: "#10B981") : Color(hex: "#F59E0B"))
                                Spacer()
                                Button(action: {
                                    Task { await touchID.toggleTouchID() }
                                }) {
                                    Text(touchID.isTouchIDEnabled ? "Disable" : "Configure Touch ID")
                                        .font(.caption.weight(.bold))
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(touchID.isTouchIDEnabled ? Color.gray : Color(hex: "#0284C7"))
                            }
                        }
                    }
                    
                    // Shell Tab Completion & Alias Card (mo completion)
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                Image(systemName: "terminal.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: "#A855F7"))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Shell Alias & Completion")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(Color.white.opacity(0.95))
                                    Text("mo completion")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(Color.white.opacity(0.6))
                                }
                                Spacer()
                            }
                            
                            Text("Installs 'mo' and 'mole' command-line shortcuts into ~/.zshrc for instant terminal access.")
                                .font(.subheadline)
                                .foregroundStyle(Color.white.opacity(0.75))
                            
                            HStack {
                                GlassBadge(touchID.isAliasInstalled ? "Alias Installed" : "Not Configured", color: touchID.isAliasInstalled ? Color(hex: "#10B981") : Color(hex: "#F59E0B"))
                                Spacer()
                                Button(action: {
                                    Task { await touchID.installShellAlias() }
                                }) {
                                    Text("Install 'mo' Shortcut")
                                        .font(.caption.weight(.bold))
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color(hex: "#A855F7"))
                                .disabled(touchID.isAliasInstalled)
                            }
                        }
                    }
                }
                
                // CLI Commands Cheat Sheet Section (mo --help, mo --version)
                VStack(alignment: .leading, spacing: 14) {
                    Text("Mole CLI Commands & Shortcuts Reference (mo --help)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.white.opacity(0.95))
                    
                    GlassCard(padding: 0) {
                        VStack(spacing: 0) {
                            let commandsList: [(String, String, String)] = [
                                ("mo", "Launch interactive GUI/CLI dashboard", "Dashboard"),
                                ("mo clean", "Deep cleanup + leftover scanning", "Cleaner"),
                                ("mo uninstall", "Remove installed apps & dependencies", "Uninstaller"),
                                ("mo purge", "Clean build artifacts (node_modules, target, .build)", "Project Purge"),
                                ("mo installer", "Find & delete leftover .dmg/.pkg installer files", "Installers"),
                                ("mo optimize", "Refresh system caches & services", "Optimizer"),
                                ("mo analyze", "Visual disk storage explorer", "Disk Analyzer"),
                                ("mo status", "Live system health telemetry dashboard", "Dashboard"),
                                ("mo touchid", "Configure Touch ID for sudo", "Utilities"),
                                ("mo completion", "Set up shell tab completion & alias", "Utilities"),
                                ("mo update", "Update Mole / Moleify engine", "System"),
                                ("mo remove", "Remove Mole / Moleify from system", "System")
                            ]
                            
                            ForEach(commandsList, id: \.0) { item in
                                HStack {
                                    Text(item.0)
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color(hex: "#38BDF8"))
                                        .frame(width: 140, alignment: .leading)
                                    
                                    Text(item.1)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.white.opacity(0.85))
                                    Spacer()
                                    
                                    Text(item.2)
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(Color.white.opacity(0.6))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.white.opacity(0.06), in: Capsule())
                                }
                                .padding(14)
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
