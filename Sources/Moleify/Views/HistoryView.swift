import SwiftUI

public struct HistoryView: View {
    @EnvironmentObject private var history: HistoryService
    @State private var showJSONModal: Bool = false
    @State private var jsonOutput: String = ""
    @State private var isCopied: Bool = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cleaning & Action History")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.98))
                        Text("mo history • Review detailed audit log of past cleanup, uninstallation, and optimization tasks")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.75))
                    }
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            jsonOutput = history.exportHistoryAsJSON()
                            showJSONModal = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "curlybraces")
                                Text("Export JSON (mo history --json)")
                            }
                            .font(.headline.weight(.bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "#0284C7"))
                        
                        Button("Clear History") {
                            history.clearHistory()
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(Color.white.opacity(0.8))
                    }
                }
                
                if history.historyRecords.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 56))
                            .foregroundStyle(Color(hex: "#38BDF8"))
                        Text("No Action History Yet")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(Color.white.opacity(0.95))
                        Text("Completed cleanup, uninstallation, and optimization actions will be logged here.")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.75))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 40)
                } else {
                    GlassCard(padding: 0) {
                        VStack(spacing: 0) {
                            HStack {
                                Text("Timestamp").frame(width: 170, alignment: .leading)
                                Text("Action Type").frame(width: 180, alignment: .leading)
                                Text("Description").frame(minWidth: 200, alignment: .leading)
                                Text("Mode").frame(width: 100, alignment: .leading)
                                Text("Reclaimed").frame(width: 110, alignment: .trailing)
                            }
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.06))
                            
                            Divider().background(Color.white.opacity(0.12))
                            
                            ForEach(history.historyRecords) { record in
                                HStack {
                                    Text(DateFormatter.localizedString(from: record.timestamp, dateStyle: .short, timeStyle: .medium))
                                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                                        .foregroundStyle(Color.white.opacity(0.75))
                                        .frame(width: 170, alignment: .leading)
                                    
                                    Text(record.actionType)
                                        .font(.body.weight(.bold))
                                        .foregroundStyle(Color(hex: "#38BDF8"))
                                        .frame(width: 180, alignment: .leading)
                                    
                                    Text(record.itemDescription)
                                        .font(.subheadline)
                                        .foregroundStyle(Color.white.opacity(0.9))
                                        .lineLimit(1)
                                        .frame(minWidth: 200, alignment: .leading)
                                    
                                    GlassBadge(record.isDryRun ? "Dry Run" : "Live Delete", color: record.isDryRun ? Color(hex: "#0284C7") : Color(hex: "#10B981"))
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Text(ByteFormatter.string(from: record.reclaimedBytes))
                                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                                        .foregroundStyle(Color(hex: "#10B981"))
                                        .frame(width: 110, alignment: .trailing)
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
        .sheet(isPresented: $showJSONModal) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("History Export (mo history --json)")
                        .font(.title2.weight(.bold))
                    Spacer()
                    Button("Close") { showJSONModal = false }
                }
                
                ScrollView {
                    Text(jsonOutput)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color.green)
                        .padding(12)
                        .background(Color.black)
                        .cornerRadius(8)
                }
                .frame(height: 350)
                
                HStack {
                    Spacer()
                    Button(isCopied ? "Copied to Clipboard!" : "Copy JSON") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(jsonOutput, forType: .string)
                        isCopied = true
                        Task {
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            isCopied = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
            .frame(width: 600, height: 480)
        }
    }
}
