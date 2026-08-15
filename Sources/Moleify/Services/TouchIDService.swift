import Foundation
import AppKit

@MainActor
public final class TouchIDService: ObservableObject {
    @Published public var isTouchIDEnabled: Bool = false
    @Published public var isAliasInstalled: Bool = false
    @Published public var statusMessage: String = ""
    @Published public var appVersion: String = "1.0.0 (Moleify Native)"
    
    private let pamSudoPath = "/etc/pam.d/sudo"
    
    public init() {
        checkTouchIDStatus()
        checkAliasStatus()
    }
    
    // MARK: - Check TouchID for Sudo status (mo touchid)
    public func checkTouchIDStatus() {
        if let contents = try? String(contentsOfFile: pamSudoPath, encoding: .utf8) {
            isTouchIDEnabled = contents.contains("pam_tid.so")
        } else {
            isTouchIDEnabled = false
        }
    }
    
    // MARK: - Configure TouchID for Sudo
    public func toggleTouchID() async {
        let command: String
        if isTouchIDEnabled {
            // Disable
            command = "sudo sed -i '' '/pam_tid.so/d' /etc/pam.d/sudo"
        } else {
            // Enable Touch ID for sudo
            command = "sudo sh -c 'echo \"auth       sufficient     pam_tid.so\" >> /etc/pam.d/sudo'"
        }
        
        let output = await runShellCommand(command)
        if output.exitCode == 0 {
            checkTouchIDStatus()
            statusMessage = isTouchIDEnabled ? "Touch ID successfully enabled for sudo terminal actions!" : "Touch ID disabled for sudo."
        } else {
            statusMessage = "Executed setup command: \(output.stdOut.isEmpty ? output.stdErr : output.stdOut)"
        }
    }
    
    // MARK: - Check Shell Completion & Alias status (mo completion)
    public func checkAliasStatus() {
        let zshrcPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".zshrc").path
        if let contents = try? String(contentsOfFile: zshrcPath, encoding: .utf8) {
            isAliasInstalled = contents.contains("alias mo=") || contents.contains("alias mole=")
        }
    }
    
    // MARK: - Setup Shell Tab Completion & Alias
    public func installShellAlias() async {
        let zshrcPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".zshrc").path
        let aliasLine = "\n# Moleify CLI Shortcut\nalias mo=\"\(FileManager.default.currentDirectoryPath)/.build/debug/Moleify\"\nalias mole=\"\(FileManager.default.currentDirectoryPath)/.build/debug/Moleify\"\n"
        
        do {
            var current = (try? String(contentsOfFile: zshrcPath, encoding: .utf8)) ?? ""
            if !current.contains("alias mo=") {
                current += aliasLine
                try current.write(toFile: zshrcPath, atomically: true, encoding: .utf8)
                isAliasInstalled = true
                statusMessage = "Shell alias 'mo' and 'mole' added to ~/.zshrc! Type 'mo' in terminal to launch."
            }
        } catch {
            statusMessage = "Could not update ~/.zshrc: \(error.localizedDescription)"
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
