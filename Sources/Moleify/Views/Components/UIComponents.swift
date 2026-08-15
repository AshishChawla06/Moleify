import SwiftUI
import AppKit

// MARK: - Apple HIG Premium Translucent Surface Card
public struct GlassCard<Content: View>: View {
    public var cornerRadius: CGFloat
    public var padding: CGFloat
    public var content: Content
    
    public init(cornerRadius: CGFloat = 14, padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.75))
                    .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
    }
}

// MARK: - Apple System Badge Pill
public struct GlassBadge: View {
    public var text: String
    public var iconName: String?
    public var color: Color
    
    public init(_ text: String, iconName: String? = nil, color: Color = .blue) {
        self.text = text
        self.iconName = iconName
        self.color = color
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            if let iconName = iconName {
                Image(systemName: iconName)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(color)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
            }
            
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.15), in: Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: - Apple Style Progress Meter
public struct CustomProgressBar: View {
    public var value: Double // 0.0 to 1.0
    public var color: Color
    public var height: CGFloat
    
    public init(value: Double, color: Color = .blue, height: CGFloat = 6) {
        self.value = min(max(value, 0.0), 1.0)
        self.color = color
        self.height = height
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.10))
                    .frame(height: height)
                
                Capsule()
                    .fill(color)
                    .frame(width: max(geo.size.width * CGFloat(value), 4), height: height)
                    .animation(.easeInOut(duration: 0.3), value: value)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Apple HIG Section Header Text
public struct SectionHeaderLabel: View {
    public var text: String
    
    public init(_ text: String) {
        self.text = text
    }
    
    public var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(Color.secondary)
            .tracking(0.8)
    }
}

// MARK: - Color Hex Extension
extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 255, (int >> 8) & 255, int & 255)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Apple System HIG Preset Colors
    public static let appleBlue = Color(hex: "#007AFF")
    public static let appleCyan = Color(hex: "#32ADE6")
    public static let applePurple = Color(hex: "#AF52DE")
    public static let appleIndigo = Color(hex: "#5856D6")
    public static let applePink = Color(hex: "#FF2D55")
    public static let appleRed = Color(hex: "#FF3B30")
    public static let appleOrange = Color(hex: "#FF9500")
    public static let appleYellow = Color(hex: "#FFCC00")
    public static let appleGreen = Color(hex: "#34C759")
    public static let appleTeal = Color(hex: "#30B0C7")
}
