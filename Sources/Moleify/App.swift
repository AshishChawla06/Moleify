import SwiftUI
import AppKit

@main
struct MoleifyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var systemMonitor = SystemMonitorService()
    @StateObject private var cleaner = CleanerService()
    @StateObject private var uninstaller = UninstallerService()
    @StateObject private var purge = PurgeService()
    @StateObject private var installer = InstallerService()
    @StateObject private var diskAnalyzer = DiskAnalyzerService()
    @StateObject private var optimizer = OptimizerService()
    @StateObject private var history = HistoryService()
    @StateObject private var updater = AutoUpdaterService()
    @StateObject private var touchID = TouchIDService()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(systemMonitor)
                .environmentObject(cleaner)
                .environmentObject(uninstaller)
                .environmentObject(purge)
                .environmentObject(installer)
                .environmentObject(diskAnalyzer)
                .environmentObject(optimizer)
                .environmentObject(history)
                .environmentObject(updater)
                .environmentObject(touchID)
                .frame(minWidth: 1080, minHeight: 720)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        
        MenuBarExtra("Moleify Live Status", systemImage: "gauge.with.needle.fill") {
            MenuBarWidgetView()
                .environmentObject(systemMonitor)
                .environmentObject(cleaner)
                .environmentObject(optimizer)
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .darkAqua)
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.backgroundColor = NSColor(red: 0.07, green: 0.08, blue: 0.11, alpha: 1.0)
        }
    }
}
