import SwiftUI

public enum NavigationTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case cleaner = "Cleaner"
    case uninstaller = "Uninstaller"
    case purge = "Project Purge"
    case installer = "Installers"
    case analyzer = "Disk Analyzer"
    case optimizer = "Optimizer"
    case history = "History"
    case updater = "Updater (mo update)"
    case utilities = "Touch ID & CLI"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .dashboard: return "gauge.with.needle.fill"
        case .cleaner: return "sparkles"
        case .uninstaller: return "trash.fill"
        case .purge: return "folder.fill.badge.gearshape"
        case .installer: return "doc.zipper"
        case .analyzer: return "chart.pie.fill"
        case .optimizer: return "bolt.fill"
        case .history: return "clock.arrow.circlepath"
        case .updater: return "arrow.triangle.2.circlepath"
        case .utilities: return "touchid"
        case .settings: return "gearshape.fill"
        }
    }
    
    public var accentColor: Color {
        switch self {
        case .dashboard: return Color.appleBlue
        case .cleaner: return Color.applePurple
        case .uninstaller: return Color.appleIndigo
        case .purge: return Color.appleOrange
        case .installer: return Color.appleGreen
        case .analyzer: return Color.appleTeal
        case .optimizer: return Color.appleYellow
        case .history: return Color.appleCyan
        case .updater: return Color.appleBlue
        case .utilities: return Color.appleBlue
        case .settings: return .gray
        }
    }
}

public struct MainView: View {
    @State private var selectedTab: NavigationTab? = .dashboard
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Deep Dark Metallic Canvas Background
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            
            // Metal Liquid Glass Background Layer
            MetalBackgroundView()
                .ignoresSafeArea()
            
            NavigationSplitView {
                VStack(alignment: .leading, spacing: 0) {
                    // Apple Style Sidebar Header Title
                    HStack(spacing: 8) {
                        Image(systemName: "circle.grid.2x2.fill")
                            .font(.title3)
                            .foregroundStyle(Color.appleBlue)
                        Text("Moleify")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    List(NavigationTab.allCases, selection: $selectedTab) { tab in
                        NavigationLink(value: tab) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(tab.accentColor.opacity(0.18))
                                        .frame(width: 26, height: 26)
                                    Image(systemName: tab.iconName)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(tab.accentColor)
                                }
                                
                                Text(tab.rawValue)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(.primary)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                    .listStyle(.sidebar)
                }
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
            } detail: {
                ZStack {
                    Color(nsColor: .windowBackgroundColor)
                        .ignoresSafeArea()
                    
                    Group {
                        switch selectedTab {
                        case .dashboard, .none:
                            DashboardView()
                        case .cleaner:
                            CleanerView()
                        case .uninstaller:
                            UninstallerView()
                        case .purge:
                            PurgeView()
                        case .installer:
                            InstallerView()
                        case .analyzer:
                            AnalyzerView()
                        case .optimizer:
                            OptimizerView()
                        case .history:
                            HistoryView()
                        case .updater:
                            UpdaterView()
                        case .utilities:
                            UtilitiesView()
                        case .settings:
                            SettingsView()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .preferredColorScheme(.dark)
    }
}
