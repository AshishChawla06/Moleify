import SwiftUI

public enum CatState: String {
    case resting = "Resting"
    case active = "Active"
    case zoomies = "Turbo"
}

public struct CatAnimationView: View {
    public var cpuUsage: Double // 0 to 100
    @State private var frameIndex: Int = 0
    @State private var bounceOffset: CGFloat = 0
    @State private var tailAngle: Double = 0
    
    public init(cpuUsage: Double) {
        self.cpuUsage = cpuUsage
    }
    
    public var catState: CatState {
        if cpuUsage >= 65 {
            return .zoomies
        } else if cpuUsage >= 25 {
            return .active
        } else {
            return .resting
        }
    }
    
    public var speechBubbleText: String {
        switch catState {
        case .resting:
            return "Purring along nicely! System is cool and quiet. 🐾"
        case .active:
            return "Processing tasks smoothly! Keeping an eye on RAM. 🐈"
        case .zoomies:
            return "Zoomies! High CPU activity detected! ⚡😸"
        }
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            // Animated Cat Figure
            TimelineView(.periodic(from: .now, by: catState == .zoomies ? 0.12 : (catState == .active ? 0.25 : 0.5))) { timeline in
                ZStack {
                    // Ambient Glow behind Cat
                    Circle()
                        .fill(catState == .zoomies ? Color.orange.opacity(0.3) : (catState == .active ? Color.blue.opacity(0.2) : Color.green.opacity(0.2)))
                        .frame(width: 54, height: 54)
                        .blur(radius: 8)
                    
                    // Cat Body Shape
                    VStack(spacing: -2) {
                        // Cat Head with Ears
                        HStack(spacing: 14) {
                            // Left Ear
                            TriangleShape()
                                .fill(catState == .zoomies ? Color(hex: "#F97316") : Color(hex: "#38BDF8"))
                                .frame(width: 10, height: 10)
                                .rotationEffect(.degrees(sin(timeline.date.timeIntervalSince1970 * 4) * 8))
                            
                            // Right Ear
                            TriangleShape()
                                .fill(catState == .zoomies ? Color(hex: "#F97316") : Color(hex: "#38BDF8"))
                                .frame(width: 10, height: 10)
                                .rotationEffect(.degrees(-sin(timeline.date.timeIntervalSince1970 * 4) * 8))
                        }
                        .offset(y: 4)
                        
                        // Face & Body Base
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: catState == .zoomies ? [Color(hex: "#F97316"), Color(hex: "#EA580C")] : [Color(hex: "#38BDF8"), Color(hex: "#0284C7")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 38, height: 32)
                            
                            // Eyes & Whiskers
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 6, height: 6)
                                    .overlay(Circle().fill(Color.black).frame(width: 3, height: 3))
                                
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 6, height: 6)
                                    .overlay(Circle().fill(Color.black).frame(width: 3, height: 3))
                            }
                            .offset(y: -2)
                        }
                    }
                    .offset(y: sin(timeline.date.timeIntervalSince1970 * (catState == .zoomies ? 12 : 4)) * (catState == .zoomies ? 4 : 2))
                }
            }
            .frame(width: 60, height: 50)
            
            // Speech Bubble
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Mole Companion")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(catState == .zoomies ? Color(hex: "#F97316") : Color(hex: "#38BDF8"))
                    
                    GlassBadge(catState.rawValue, color: catState == .zoomies ? Color(hex: "#F97316") : Color(hex: "#38BDF8"))
                }
                
                Text(speechBubbleText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.95))
            }
            Spacer()
        }
        .padding(14)
        .background(Color(red: 0.12, green: 0.14, blue: 0.20), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    catState == .zoomies ? Color(hex: "#F97316").opacity(0.4) : Color(hex: "#38BDF8").opacity(0.3),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Helper Triangle Shape for Cat Ears
struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
