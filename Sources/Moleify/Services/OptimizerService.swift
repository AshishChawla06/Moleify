import Foundation
import AppKit

@MainActor
public final class OptimizerService: ObservableObject {
    @Published public var tasks: [OptimizationTaskItem] = []
    @Published public var isRunningAny: Bool = false
    
    public init() {
        setupTasks()
    }
    
    private func setupTasks() {
        tasks = [
            OptimizationTaskItem(
                id: "flush_dns",
                title: "Flush DNS Resolver Cache",
                taskDescription: "Clears stale DNS records to resolve website loading issues and speed up domain queries.",
                command: "dscacheutil -flushcache; killall -HUP mDNSResponder",
                iconName: "network"
            ),
            OptimizationTaskItem(
                id: "purge_ram",
                title: "Purge Inactive RAM",
                taskDescription: "Frees up inactive memory pages back to macOS kernel without closing open apps.",
                command: "purge",
                iconName: "memorychip"
            ),
            OptimizationTaskItem(
                id: "rebuild_launchservices",
                title: "Rebuild LaunchServices DB",
                taskDescription: "Fixes 'Open With' duplicate app entries and broken file association icons.",
                command: "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user",
                iconName: "arrow.triangle.2.circlepath"
            ),
            OptimizationTaskItem(
                id: "rebuild_spotlight",
                title: "Reindex Spotlight Search",
                taskDescription: "Forces macOS to re-index all drives to fix missing files in Spotlight search.",
                command: "mdutil -E /",
                iconName: "magnifyingglass",
                requiresSudo: true
            ),
            OptimizationTaskItem(
                id: "clear_font_cache",
                title: "Clear Font Databases",
                taskDescription: "Resets corrupted system and user font cache databases to resolve rendering glitches.",
                command: "atsutil databases -remove",
                iconName: "textformat"
            ),
            OptimizationTaskItem(
                id: "system_maintenance",
                title: "Run System Maintenance Scripts",
                taskDescription: "Executes macOS daily, weekly, and monthly system log rotation and cleanup scripts.",
                command: "periodic daily weekly monthly",
                iconName: "gearshape"
            )
        ]
    }
    
    public func executeTask(_ task: OptimizationTaskItem) async {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        tasks[index].state = .running
        isRunningAny = true
        
        let output = await runShellCommand(task.command)
        
        if output.exitCode == 0 {
            tasks[index].state = .success("Task executed successfully. \(output.stdOut.prefix(100))")
        } else {
            tasks[index].state = .failure("Executed with notification: \(output.stdErr.isEmpty ? output.stdOut : output.stdErr)")
        }
        
        isRunningAny = tasks.contains(where: {
            if case .running = $0.state { return true }
            return false
        })
    }
    
    public func executeAllTasks() async {
        for task in tasks {
            await executeTask(task)
        }
    }
    
    private func runShellCommand(_ command: String) async -> (exitCode: Int32, stdOut: String, stdErr: String) {
        return await Task.detached(priority: .userInitiated) {
            let process = Process()
            let pipeOut = Pipe()
            let pipeErr = Pipe()
            
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-c", command]
            process.standardOutput = pipeOut
            process.standardError = pipeErr
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let dataOut = pipeOut.fileHandleForReading.readDataToEndOfFile()
                let dataErr = pipeErr.fileHandleForReading.readDataToEndOfFile()
                
                let stdOut = String(data: dataOut, encoding: .utf8) ?? ""
                let stdErr = String(data: dataErr, encoding: .utf8) ?? ""
                
                return (process.terminationStatus, stdOut, stdErr)
            } catch {
                return (-1, "", error.localizedDescription)
            }
        }.value
    }
}
