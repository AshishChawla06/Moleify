import Foundation
import IOKit.ps

public struct BatteryStats: Sendable {
    public var isBatteryPresent: Bool = false
    public var isCharging: Bool = false
    public var currentCapacity: Int = 100
    public var isACPowered: Bool = true
    public var healthPercentage: Int = 100
    public var cycleCount: Int = 0
    public var thermalState: String = "Nominal (Cool)"
}

@MainActor
public final class BatteryService: ObservableObject {
    @Published public var stats = BatteryStats()
    
    public init() {
        updateBatteryStats()
    }
    
    public func updateBatteryStats() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as [CFTypeRef]
        
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                let isCharging = (description[kIOPSIsChargingKey] as? Bool) ?? false
                let capacity = (description[kIOPSCurrentCapacityKey] as? Int) ?? 100
                let powerSource = (description[kIOPSPowerSourceStateKey] as? String) ?? ""
                
                stats.isBatteryPresent = true
                stats.isCharging = isCharging
                stats.currentCapacity = capacity
                stats.isACPowered = powerSource == kIOPSACPowerValue
            }
        }
        
        let processInfo = ProcessInfo.processInfo
        switch processInfo.thermalState {
        case .nominal:
            stats.thermalState = "Nominal (Cool & Optimal)"
        case .fair:
            stats.thermalState = "Fair (Slightly Warm)"
        case .serious:
            stats.thermalState = "Serious (Throttling Active)"
        case .critical:
            stats.thermalState = "Critical (Heavy Thermal Throttling)"
        @unknown default:
            stats.thermalState = "Nominal"
        }
    }
}
