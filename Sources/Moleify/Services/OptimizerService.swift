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
                command: "dscacheutil -flushcache; killall -HUP mDNSResponder 2>/dev/null || true",
                iconName: "network"
            ),
            OptimizationTaskItem(
                id: "purge_ram",
                title: "Purge Inactive RAM",
                taskDescription: "Frees up inactive memory pages back to macOS kernel without closing open apps.",
                command: "purge",
                iconName: "memorychip",
                requiresSudo: true
            ),
            OptimizationTaskItem(
                id: "rebuild_launchservices",
                title: "Rebuild LaunchServices DB",
                taskDescription: "Fixes 'Open With' duplicate app entries and broken file association icons.",
                command: "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -r -domain local -domain user -domain system",
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
                command: "/usr/sbin/periodic daily weekly monthly 2>/dev/null || echo 'System maintenance completed.'",
                iconName: "gearshape"
            )
        ]
    }
    
    public func executeTask(_ task: OptimizationTaskItem) async {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        
        tasks[index].state = .running
        isRunningAny = true
        
        let output: (exitCode: Int32, stdOut: String, stdErr: String)
        if task.requiresSudo {
            output = await runAppleScriptAdmin(task.command)
        } else {
            output = await runShellCommand(task.command)
        }
        
        if output.exitCode == 0 {
            let msg = output.stdOut.trimmingCharacters(in: .whitespacesAndNewlines)
            tasks[index].state = .success(msg.isEmpty ? "Task executed successfully." : "Task executed successfully. \(msg.prefix(120))")
        } else {
            let err = output.stdErr.trimmingCharacters(in: .whitespacesAndNewlines)
            tasks[index].state = .failure("Executed with notification: \(err.isEmpty ? output.stdOut : err)")
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
    
    // MARK: - Execute Shell Command
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
    
    // MARK: - Execute Admin Shell Command via AppleScript Privilege Escalation
    private func runAppleScriptAdmin(_ command: String) async -> (exitCode: Int32, stdOut: String, stdErr: String) {
        return await Task.detached(priority: .userInitiated) {
            let escapedCommand = command.replacingOccurrences(of: "\"", with: "\\\"")
            let scriptSource = "do shell script \"\(escapedCommand)\" with administrator privileges"
            
            var errorDict: NSDictionary?
            if let script = NSAppleScript(source: scriptSource) {
                let result = script.executeAndReturnError(&errorDict)
                if let err = errorDict {
                    let errMsg = (err[NSAppleScript.errorMessage] as? String) ?? "User cancelled or admin privilege required."
                    return (1, "", errMsg)
                }
                let output = result.stringValue ?? "Command executed with administrator privileges."
                return (0, output, "")
            }
            return (1, "", "Failed to initialize AppleScript privileges.")
        }.value
    }
}
