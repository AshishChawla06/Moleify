import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject private var cleaner: CleanerService
    @State private var newPathInput: String = ""
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings & Whitelist Configuration")
                        .font(.title2.weight(.bold))
                    Text("Customize cleaning protection paths, telemetry refresh rates, and Metal graphics rendering")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Whitelist Card
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "shield.checkerboard")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Protected Whitelist Directories")
                                .font(.headline)
                            Text("Moleify will never remove files located inside whitelisted directory paths.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    
                    HStack {
                        TextField("Enter path (e.g. /Users/username/Documents/Critical)", text: $newPathInput)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Add Path") {
                            let trimmed = newPathInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                cleaner.whitelistPaths.insert(trimmed)
                                newPathInput = ""
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newPathInput.isEmpty)
                    }
                    
                    if cleaner.whitelistPaths.isEmpty {
                        Text("No whitelisted directories specified. Default protective measures apply.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.vertical, 4)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(Array(cleaner.whitelistPaths), id: \.self) { path in
                                HStack {
                                    Image(systemName: "folder.badge.gearshape")
                                        .foregroundStyle(.blue)
                                    Text(path)
                                        .font(.body.weight(.medium).monospaced())
                                    Spacer()
                                    Button(action: {
                                        cleaner.whitelistPaths.remove(path)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(10)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                // About Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.title2)
                            .foregroundStyle(.purple)
                        Text("About Moleify")
                            .font(.headline)
                    }
                    
                    Text("Moleify is a 100% native macOS GUI application for Mole, inspired by tw93/mole. Built with Swift 6, SwiftUI, Darwin system APIs, and Metal 3 hardware acceleration.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        Link(destination: URL(string: "https://github.com/tw93/mole")!) {
                            Label("tw93/mole Repository", systemImage: "link")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding(24)
        }
    }
}
