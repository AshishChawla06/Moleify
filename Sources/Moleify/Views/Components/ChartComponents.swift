import SwiftUI

// MARK: - Real-Time Rolling Line / Sparkline Graph Component
public struct RealTimeLineGraph: View {
    public var dataPoints: [Double] // Values 0.0 to 100.0 or normalized
    public var gradientColors: [Color]
    public var height: CGFloat
    public var showGridLines: Bool
    
    public init(dataPoints: [Double], gradientColors: [Color] = [.blue.opacity(0.8), .cyan], height: CGFloat = 80, showGridLines: Bool = true) {
        self.dataPoints = dataPoints.isEmpty ? Array(repeating: 10.0, count: 20) : dataPoints
        self.gradientColors = gradientColors
        self.height = height
        self.showGridLines = showGridLines
    }
    
    public var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let points = normalizePoints(width: width, height: height)
            
            ZStack(alignment: .bottom) {
                // Background Grid Lines
                if showGridLines {
                    VStack {
                        Divider().background(Color.white.opacity(0.06))
                        Spacer()
                        Divider().background(Color.white.opacity(0.06))
                        Spacer()
                        Divider().background(Color.white.opacity(0.06))
                    }
                }
                
                // Filled Area under Path
                Path { path in
                    guard !points.isEmpty else { return }
                    path.move(to: CGPoint(x: points[0].x, y: height))
                    path.addLine(to: points[0])
                    
                    for i in 1..<points.count {
                        let p1 = points[i - 1]
                        let p2 = points[i]
                        let midX = (p1.x + p2.x) / 2
                        path.addQuadCurve(to: p2, control: CGPoint(x: midX, y: p1.y))
                    }
                    
                    if let last = points.last {
                        path.addLine(to: CGPoint(x: last.x, y: height))
                    }
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [gradientColors[0].opacity(0.4), gradientColors.last?.opacity(0.05) ?? .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Top Smooth Curve Line
                Path { path in
                    guard !points.isEmpty else { return }
                    path.move(to: points[0])
                    
                    for i in 1..<points.count {
                        let p1 = points[i - 1]
                        let p2 = points[i]
                        let midX = (p1.x + p2.x) / 2
                        path.addQuadCurve(to: p2, control: CGPoint(x: midX, y: p1.y))
                    }
                }
                .stroke(
                    LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                )
                
                // Latest Pulsing Point Indicator
                if let last = points.last {
                    Circle()
                        .fill(gradientColors.first ?? .blue)
                        .frame(width: 7, height: 7)
                        .position(last)
                        .shadow(color: gradientColors.first ?? .blue, radius: 4)
                }
            }
        }
        .frame(height: height)
    }
    
    private func normalizePoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard dataPoints.count > 1 else { return [CGPoint(x: 0, y: height)] }
        
        let maxVal = max(dataPoints.max() ?? 100.0, 1.0)
        let stepX = width / CGFloat(dataPoints.count - 1)
        
        return dataPoints.enumerated().map { index, val in
            let normY = height - (CGFloat(val / maxVal) * (height - 8))
            return CGPoint(x: CGFloat(index) * stepX, y: normY)
        }
    }
}

// MARK: - Interactive Storage Donut Chart Component
public struct StorageDonutChart: View {
    public var categories: [StorageCategoryItem]
    public var totalSizeBytes: UInt64
    
    public init(categories: [StorageCategoryItem], totalSizeBytes: UInt64) {
        self.categories = categories
        self.totalSizeBytes = max(totalSizeBytes, 1)
    }
    
    public var body: some View {
        ZStack {
            let Angles = computeSliceAngles()
            
            ForEach(0..<categories.count, id: \.self) { i in
                let cat = categories[i]
                let (startAngle, endAngle) = Angles[i]
                
                DonutSliceShape(startAngle: startAngle, endAngle: endAngle)
                    .fill(Color(hex: cat.colorHex))
                    .shadow(color: Color(hex: cat.colorHex).opacity(0.3), radius: 4)
            }
            
            // Inner Glass Cutout
            Circle()
                .fill(.ultraThinMaterial)
                .padding(26)
                .overlay(
                    VStack(spacing: 2) {
                        Text("Total Used")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(ByteFormatter.string(from: totalSizeBytes))
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(.primary)
                    }
                )
        }
        .frame(width: 170, height: 170)
    }
    
    private func computeSliceAngles() -> [(Angle, Angle)] {
        let total = Double(categories.reduce(0) { $0 + $1.sizeBytes })
        var current: Double = 0
        var result: [(Angle, Angle)] = []
        
        for cat in categories {
            let fraction = total > 0 ? Double(cat.sizeBytes) / total : 0
            let start = Angle(degrees: current * 360 - 90)
            current += fraction
            let end = Angle(degrees: current * 360 - 90)
            result.append((start, end))
        }
        return result
    }
}

public struct DonutSliceShape: Shape {
    public var startAngle: Angle
    public var endAngle: Angle
    
    public func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius - 24
        
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: endAngle, endAngle: startAngle, clockwise: true)
        path.closeSubpath()
        return path
    }
}
