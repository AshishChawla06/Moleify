import SwiftUI

public struct OptimizerView: View {
    @EnvironmentObject private var optimizer: OptimizerService
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("System Optimizer & Maintenance")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                        Text("Execute one-click system maintenance scripts, flush DNS, purge RAM, and rebuild indices")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await optimizer.executeAllTasks()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                            Text(optimizer.isRunningAny ? "Running All..." : "Run All Tasks")
                        }
                        .font(.headline)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .disabled(optimizer.isRunningAny)
                }
                
                // Tasks Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                    ForEach(optimizer.tasks) { task in
                        GlassCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 12) {
                                    Image(systemName: task.iconName)
                                        .font(.title2)
                                        .foregroundStyle(.orange)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(task.title)
                                            .font(.headline)
                                        if task.requiresSudo {
                                            Text("Requires Sudo / Admin")
                                                .font(.caption2.weight(.semibold))
                                                .foregroundStyle(.orange)
                                        }
                                    }
                                    Spacer()
                                    
                                    switch task.state {
                                    case .idle:
                                        Button("Run") {
                                            Task { await optimizer.executeTask(task) }
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.orange)
                                    case .running:
                                        ProgressView()
                                            .controlSize(.small)
                                    case .success:
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.title3)
                                    case .failure:
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.yellow)
                                            .font(.title3)
                                    }
                                }
                                
                                Text(task.taskDescription)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                // Console command preview
                                HStack {
                                    Text("$ \(task.command)")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.tertiary)
                                        .lineLimit(1)
                                    Spacer()
                                }
                                .padding(8)
                                .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 6))
                                
                                if case let .success(message) = task.state {
                                    Text(message)
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                        .lineLimit(2)
                                } else if case let .failure(errorMsg) = task.state {
                                    Text(errorMsg)
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                        .lineLimit(2)
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
