import Foundation
import AppKit

public struct GitHubReleaseInfo: Codable, Sendable {
    public let tagName: String
    public let name: String
    public let body: String
    public let htmlUrl: String
    public let publishedAt: String
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case body
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
    }
}

@MainActor
public final class AutoUpdaterService: ObservableObject {
    @Published public var isChecking: Bool = false
    @Published public var latestRelease: GitHubReleaseInfo?
    @Published public var isUpdateAvailable: Bool = false
    @Published public var errorMessage: String = ""
    @Published public var currentVersion: String = "1.0.0"
    
    private let repoReleaseURL = URL(string: "https://api.github.com/repos/tw93/mole/releases/latest")!
    
    public init() {}
    
    // MARK: - Check GitHub Release (https://github.com/tw93/mole)
    public func checkForUpdates() async {
        isChecking = true
        errorMessage = ""
        
        do {
            var request = URLRequest(url: repoReleaseURL)
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            request.setValue("Moleify-macOS-Updater", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "GitHub API response: \((response as? HTTPURLResponse)?.statusCode ?? -1)"
                isChecking = false
                return
            }
            
            let decoder = JSONDecoder()
            let release = try decoder.decode(GitHubReleaseInfo.self, from: data)
            
            self.latestRelease = release
            
            let cleanedTag = release.tagName.replacingOccurrences(of: "v", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            if cleanedTag != currentVersion {
                isUpdateAvailable = true
            } else {
                isUpdateAvailable = false
            }
        } catch {
            errorMessage = "Failed to fetch updates from tw93/mole: \(error.localizedDescription)"
        }
        
        isChecking = false
    }
    
    public func openReleasePage() {
        if let release = latestRelease, let url = URL(string: release.htmlUrl) {
            NSWorkspace.shared.open(url)
        } else if let fallback = URL(string: "https://github.com/tw93/mole/releases") {
            NSWorkspace.shared.open(fallback)
        }
    }
}
