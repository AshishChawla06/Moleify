import Foundation
import SwiftUI

// MARK: - System Statistics Models

public struct CPUCoreInfo: Identifiable, Sendable, Hashable {
    public let id: Int
    public let usagePercentage: Double
}

public struct SystemStats: Sendable {
    public var cpuUsage: Double = 0.0
    public var cpuCores: [CPUCoreInfo] = []
    
    // RAM in Bytes
    public var totalMemory: UInt64 = 0
    public var usedMemory: UInt64 = 0
    public var freeMemory: UInt64 = 0
    public var wiredMemory: UInt64 = 0
    public var compressedMemory: UInt64 = 0
    public var appMemory: UInt64 = 0
    public var cachedMemory: UInt64 = 0
    
    // Disk in Bytes
    public var totalDiskSpace: UInt64 = 0
    public var freeDiskSpace: UInt64 = 0
    public var usedDiskSpace: UInt64 = 0
    public var diskReadSpeedMBps: Double = 0.0
    public var diskWriteSpeedMBps: Double = 0.0
    
    // Network in Bytes/sec
    public var downloadSpeedBytesPerSec: Double = 0.0
    public var uploadSpeedBytesPerSec: Double = 0.0
    
    // Battery
    public var batteryLevel: Double = 1.0 // 0.0 to 1.0
    public var isCharging: Bool = true
    public var batteryHealth: String = "Normal"
    
    public init() {}
}

public struct ProcessInfoItem: Identifiable, Sendable, Hashable {
    public let id: Int32 // PID
    public let name: String
    public let cpuUsagePercentage: Double
    public let memoryUsageMB: Double
    public let user: String
}

// MARK: - System Cleaner Models

public enum CleanCategory: String, CaseIterable, Identifiable, Sendable, Hashable {
    case systemCache = "System Cache"
    case appCache = "User App Caches"
    case logs = "System & App Logs"
    case xcode = "Xcode DerivedData & Junk"
    case developer = "Developer Caches (SwiftPM/CocoaPods)"
    case packageManagers = "Package Managers (Brew/npm/yarn)"
    case browser = "Browser Caches & Junk"
    case trash = "Trash Bin"
    case temp = "Temporary Files"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .systemCache: return "cpu"
        case .appCache: return "square.stack.3d.up"
        case .logs: return "doc.text"
        case .xcode: return "hammer"
        case .developer: return "terminal"
        case .packageManagers: return "shippingbox"
        case .browser: return "globe"
        case .trash: return "trash"
        case .temp: return "clock.arrow.circlepath"
        }
    }
    
    public var categoryDescription: String {
        switch self {
        case .systemCache: return "OS cache files generated for temporary performance index."
        case .appCache: return "Cached data created by installed third-party applications."
        case .logs: return "Diagnostic logs and crash reports accumulating over time."
        case .xcode: return "Intermediate build artifacts, iOS DeviceSupport, and module caches."
        case .developer: return "Local index and package caches for SwiftPM, CocoaPods, and Android."
        case .packageManagers: return "Downloaded formula archives from Homebrew, npm, pnpm, and cargo."
        case .browser: return "Cache, web data, and temporary offline assets from Safari, Chrome, Arc."
        case .trash: return "Deleted files residing in user Trash."
        case .temp: return "System temporary folders created in /tmp and /var/folders."
        }
    }
}

public struct CleanableItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let path: String
    public let category: CleanCategory
    public var sizeBytes: UInt64
    public var isSelected: Bool
    public let itemDescription: String
    
    public init(id: String = UUID().uuidString, name: String, path: String, category: CleanCategory, sizeBytes: UInt64, isSelected: Bool = true, itemDescription: String = "") {
        self.id = id
        self.name = name
        self.path = path
        self.category = category
        self.sizeBytes = sizeBytes
        self.isSelected = isSelected
        self.itemDescription = itemDescription
    }
}

// MARK: - App Uninstaller Models

public enum LeftoverType: String, CaseIterable, Sendable, Hashable {
    case applicationSupport = "Application Support"
    case cache = "Caches"
    case preferences = "Preferences (.plist)"
    case container = "Containers"
    case launchAgent = "Launch Agents / Daemons"
    case savedState = "Saved Application State"
    case log = "Logs"
    case unknown = "Other Dependencies"
    
    public var iconName: String {
        switch self {
        case .applicationSupport: return "folder"
        case .cache: return "externaldrive"
        case .preferences: return "slider.horizontal.3"
        case .container: return "shippingbox"
        case .launchAgent: return "gearshape.2"
        case .savedState: return "clock"
        case .log: return "doc.text"
        case .unknown: return "doc"
        }
    }
}

public struct LeftoverItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let path: String
    public let type: LeftoverType
    public let sizeBytes: UInt64
    public var isSelected: Bool
    
    public init(id: String = UUID().uuidString, name: String, path: String, type: LeftoverType, sizeBytes: UInt64, isSelected: Bool = true) {
        self.id = id
        self.name = name
        self.path = path
        self.type = type
        self.sizeBytes = sizeBytes
        self.isSelected = isSelected
    }
}

public struct AppInfoItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let bundleId: String
    public let path: String
    public let bundleSizeBytes: UInt64
    public var leftovers: [LeftoverItem]
    
    public var totalSizeBytes: UInt64 {
        bundleSizeBytes + leftovers.reduce(0) { $0 + ($1.isSelected ? $1.sizeBytes : 0) }
    }
    
    public init(id: String = UUID().uuidString, name: String, bundleId: String, path: String, bundleSizeBytes: UInt64, leftovers: [LeftoverItem] = []) {
        self.id = id
        self.name = name
        self.bundleId = bundleId
        self.path = path
        self.bundleSizeBytes = bundleSizeBytes
        self.leftovers = leftovers
    }
}

// MARK: - Disk Storage Analyzer Models

public struct StorageCategoryItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let sizeBytes: UInt64
    public let colorHex: String
    public let iconName: String
    
    public init(name: String, sizeBytes: UInt64, colorHex: String, iconName: String) {
        self.id = name
        self.name = name
        self.sizeBytes = sizeBytes
        self.colorHex = colorHex
        self.iconName = iconName
    }
}

public struct LargeFileItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let path: String
    public let sizeBytes: UInt64
    public let lastModified: Date
    
    public init(id: String = UUID().uuidString, name: String, path: String, sizeBytes: UInt64, lastModified: Date) {
        self.id = id
        self.name = name
        self.path = path
        self.sizeBytes = sizeBytes
        self.lastModified = lastModified
    }
}

// MARK: - System Optimizer Models

public enum TaskExecutionState: Sendable, Hashable {
    case idle
    case running
    case success(String)
    case failure(String)
}

public struct OptimizationTaskItem: Identifiable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let taskDescription: String
    public let command: String
    public let iconName: String
    public var state: TaskExecutionState
    public var requiresSudo: Bool
    
    public init(id: String, title: String, taskDescription: String, command: String, iconName: String, state: TaskExecutionState = .idle, requiresSudo: Bool = false) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.command = command
        self.iconName = iconName
        self.state = state
        self.requiresSudo = requiresSudo
    }
}

// MARK: - Formatting Helpers

public enum ByteFormatter {
    public static func string(from bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
