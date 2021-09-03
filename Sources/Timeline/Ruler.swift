//
//  Ruler.swift
//  Ruler
//
//  Created by nori on 2021/08/25.
//

import SwiftUI

public struct Ruler<Bound: BinaryFloatingPoint, Content: View>: View {

    var axisScale: AxisScale<Bound>

    var content: (Double) -> Content

    public init(axis: Axis, range: Range<Bound>, scale: Double = 1, content: @escaping (Double) -> Content) {
        self.axisScale = AxisScale(axis: axis, range: range, scale: scale)
        self.content = content
    }

    public init(axisScale: AxisScale<Bound>, content: @escaping (Double) -> Content) {
        self.axisScale = axisScale
        self.content = content
    }

    var verticalBody: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<axisScale.numberOfGrids) { grid in
                    let (size, position) = axisScale.property(grid: grid, size: proxy.size)
                    content(axisScale.gridLabel(grid: grid))
                        .frame(height: size.height)
                        .position(position)
                }
            }
        }
    }

    var horizontalBody: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<axisScale.numberOfGrids) { grid in
                    let (size, position) = axisScale.property(grid: grid, size: proxy.size)
                    content(axisScale.gridLabel(grid: grid))
                        .frame(width: size.width)
                        .position(position)
                }
            }
        }
    }

    public var body: some View {
        switch axisScale.axis {
            case .vertical: verticalBody
            case .horizontal: horizontalBody
        }
    }
}

public struct BackgroundGide<Bound: BinaryFloatingPoint>: View {

    var axisScale: AxisScale<Bound>

    var color: Color

    #if os(macOS)
    public init(axis: Axis, range: Range<Bound>, scale: Double = 1, color: Color = Color(.separatorColor)) {
        self.axisScale = AxisScale(axis: axis, range: range, scale: scale)
        self.color = color
    }

    public init(axisScale: AxisScale<Bound>, color: Color = Color(.separatorColor)) {
        self.axisScale = axisScale
        self.color = color
    }
    #endif

    #if os(iOS)
    public init(axis: Axis, range: Range<Bound>, scale: Double = 1, color: Color = Color(.separator)) {
        self.axisScale = AxisScale(axis: axis, range: range, scale: scale)
        self.color = color
    }

    public init(axisScale: AxisScale<Bound>, color: Color = Color(.separator)) {
        self.axisScale = axisScale
        self.color = color
    }
    #endif

    var verticalBody: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<axisScale.numberOfGrids) { grid in
                    let (size, position) = axisScale.property(grid: grid, size: proxy.size)
                    VStack {
                        Rectangle()
                            .fill(Color.gray)
                            .frame(height: 1)
                        Spacer()
                    }
                    .frame(width: size.width, height: size.height)
                    .position(position)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height * axisScale.scale)
        }
    }

    var horizontalBody: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<axisScale.numberOfGrids) { grid in
                    let (size, position) = axisScale.property(grid: grid, size: proxy.size)
                    HStack {
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 1)
                        Spacer()
                    }
                    .frame(width: size.width, height: size.height)
                    .position(position)
                }
            }
            .frame(width: proxy.size.width * axisScale.scale, height: proxy.size.height)
        }
    }

    public var body: some View {
        switch axisScale.axis {
            case .vertical: verticalBody
            case .horizontal: horizontalBody
        }
    }
}


public struct AxisScale<Bound: BinaryFloatingPoint> {

    var axis: Axis

    var range: Range<Bound>

    var scale: Double

    var interval: Double

    var numberOfGrids: Int

    public init(axis: Axis, range: Range<Bound>, scale: Double = 1) {
        self.axis = axis
        self.range = range
        self.scale = scale
        let magnitude = Double(range.upperBound - range.lowerBound)
        let disitCount = String(Int(magnitude)).count
        let interval: Double = pow(Double(10), Double(disitCount - 2))
        let numberOfGrids = ceil(magnitude / interval)
        self.interval = interval
        self.numberOfGrids = Int(numberOfGrids)
    }

    func gridLabel(grid: Int) -> Double {
        return Double(range.lowerBound) + (Double(grid) * interval)
    }

    func magnitude(of range: Range<Bound>) -> Double {
        return Double(range.upperBound - range.lowerBound)
    }

    func property(grid: Int, size: CGSize) -> (CGSize, CGPoint) {
        let magnitude = Double(range.upperBound - range.lowerBound)
        switch axis {
            case .vertical:
                let height = interval / magnitude * size.height * scale
                let y = Double(grid) * interval / magnitude * size.height * scale + height / 2
                let x = size.width / 2
                let position = CGPoint(x: x, y: y)
                return (CGSize(width: size.width, height: height), position)
            case .horizontal:
                let width = interval / magnitude * size.width * scale
                let x = Double(grid) * interval / magnitude * size.width * scale + width / 2
                let y = size.height / 2
                let position = CGPoint(x: x, y: y)
                return (CGSize(width: width, height: size.height), position)
        }
    }
}

struct Ruler_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Ruler(axis: .vertical, range: (0..<10)) { scale in
                VStack {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(height: 1)
                    HStack {
                        Spacer()
                        Text("\(Int(scale))")
                    }
                    Spacer()
                }
            }
//            BackgroundGide(axis: .vertical, range: (0..<100))

            Ruler(axis: .horizontal, range: (0..<10)) { scale in
                HStack {
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 1)
                    VStack {
                        Text("\(Int(scale))")
                        Spacer()
                    }
                    Spacer()
                }
            }
//            BackgroundGide(axis: .horizontal, range: (0..<100))
        }
    }
}
