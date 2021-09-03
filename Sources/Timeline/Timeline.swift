//
//  Timeline.swift
//  Timeline
//
//  Created by nori on 2021/08/25.
//

import SwiftUI

public struct Timeline<Lane: TimelineLaneProtocol, AxisLabel: View, ControlPanel: View, Content: View>: View {

    typealias Model = TimelineModel<Lane>

    public typealias Item = Lane.Item

    var model: Model

    var axisLabel: ((Double) -> AxisLabel)?

    var controlPanel: ((Lane) -> ControlPanel)?

    var content: (Lane, Item) -> Content

    let rulerHieght: CGFloat = 32

    let rulerWidth: CGFloat = 32

    public init(
        axis: Axis,
        lanes: [Lane],
        range: Range<Item.Bound>,
        scale: CGFloat = 1,
        axisLabel: @escaping (Double) -> AxisLabel,
        controlPanel: @escaping (Lane) -> ControlPanel,
        content: @escaping (Lane, Item) -> Content
    ) {
        self.model = Model(axis: axis, lanes: lanes, range: range, scale: scale)
        self.axisLabel = axisLabel
        self.controlPanel = controlPanel
        self.content = content
    }

    public init(
        axis: Axis,
        lanes: [Lane],
        range: Range<Item.Bound>,
        scale: CGFloat = 1,
        content: @escaping (Lane, Item) -> Content
    ) where AxisLabel == Never, ControlPanel == Never {
        self.model = Model(axis: axis, lanes: lanes, range: range, scale: scale)
        self.axisLabel = nil
        self.controlPanel = nil
        self.content = content
    }

    var horizontalBody: some View {
        HStack(spacing: 0) {

            if let controlPanel = controlPanel {
                GeometryReader { proxy in
                    VStack(spacing: 0) {
                        ForEach(model.lanes) { lane in
                            controlPanel(lane)
                                .frame(height: proxy.size.height / CGFloat(model.lanes.count))
                        }
                    }
                }
                .padding(.top, rulerHieght)
                .frame(maxWidth: 120)
            }

            GeometryReader { proxy in
                ScrollView([.horizontal]) {
                    Group {
                        if let axisLabel = axisLabel {
                            VStack(spacing: 0) {
                                Ruler(axis: model.axis, range: model.range) { grid in
                                    HStack {
                                        Rectangle()
                                            .fill(Color.gray)
                                            .frame(width: 1)
                                        VStack {
                                            axisLabel(grid)
                                            Spacer()
                                        }
                                        Spacer()
                                    }
                                }.frame(height: rulerHieght)
                                ForEach(model.lanes) { lane in
                                    LaneView(model: model, lane: lane, content: content)
                                }
                            }
                            .background(BackgroundGide(axis: model.axis, range: model.range))
                        } else {
                            VStack(spacing: 0) {
                                ForEach(model.lanes) { lane in
                                    LaneView(model: model, lane: lane, content: content)
                                }
                            }
                            .background(BackgroundGide(axis: model.axis, range: model.range))
                        }
                    }
                    .frame(width: proxy.size.width * model.scale, height: proxy.size.height)
                }
                .compositingGroup()
            }
        }
    }

    var verticalBody: some View {
        VStack(spacing: 0) {

            if let controlPanel = controlPanel {
                GeometryReader { proxy in
                    HStack(spacing: 0) {
                        ForEach(model.lanes) { lane in
                            controlPanel(lane)
                                .frame(width: proxy.size.width / CGFloat(model.lanes.count))
                        }
                    }
                }
                .padding(.top, rulerHieght)
                .frame(maxHeight: 120)
            }

            GeometryReader { proxy in
                ScrollView([.vertical]) {
                    Group {
                        if let axisLabel = axisLabel {
                            HStack(spacing: 0) {
                                Ruler(axis: model.axis, range: model.range) { grid in
                                    VStack {
                                        Rectangle()
                                            .fill(Color.gray)
                                            .frame(height: 1)
                                        HStack {
                                            Spacer()
                                            axisLabel(grid)
                                        }
                                        Spacer()
                                    }
                                }.frame(width: rulerWidth)
                                ForEach(model.lanes) { lane in
                                    LaneView(model: model, lane: lane, content: content)
                                }
                            }
                            .background(BackgroundGide(axis: model.axis, range: model.range))
                        } else {
                            HStack(spacing: 0) {
                                ForEach(model.lanes) { lane in
                                    LaneView(model: model, lane: lane, content: content)
                                }
                            }
                            .background(BackgroundGide(axis: model.axis, range: model.range))
                        }
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height * model.scale)
                }
                .compositingGroup()
            }
        }
    }

    public var body: some View {
        switch model.axis {
            case .vertical: verticalBody
            case .horizontal: horizontalBody
        }
    }
}

extension Timeline {

    struct LaneView: View {

        var model: Model

        var lane: Lane

        var content: (Lane, Item) -> Content

        init(model: Model, lane: Lane, content: @escaping (Lane, Item) -> Content) {
            self.model = model
            self.lane = lane
            self.content = content
        }

        var body: some View {
            GeometryReader { proxy in
                ZStack {
                    ForEach(lane.items) { item in
                        let (size, position) = model.property(item: item, size: proxy.size)
                        content(lane, item)
                            .frame(width: size.width, height: size.height)
                            .position(position)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

public enum Axis {
    case vertical
    case horizontal
}

struct TimelineModel<Lane: TimelineLaneProtocol> {

    typealias Item = Lane.Item

    typealias Bound = Item.Bound

    var axis: Axis

    var lanes: [Lane]

    var range: Range<Item.Bound>

    var scale: Double

    init(axis: Axis, lanes: [Lane] = [], range: Range<Item.Bound>, scale: Double = 1) {
        self.axis = axis
        self.lanes = lanes
        self.range = range
        self.scale = scale
    }
}

extension TimelineModel {

    func magnitude(of range: Range<Bound>) -> Double {
        return Double(range.upperBound - range.lowerBound)
    }

    func property(item: Item, size: CGSize) -> (CGSize, CGPoint) {
        switch axis {
            case .horizontal:
                let timelineMagnitude = magnitude(of: range)
                let itemMagnitude = magnitude(of: item.range)
                let width = size.width * itemMagnitude / timelineMagnitude
                let x = Double(item.range.lowerBound - range.lowerBound) * (size.width / timelineMagnitude) + (width / 2)
                let y = size.height / 2
                let position = CGPoint(x: x, y: y)
                return (CGSize(width: width, height: size.height), position)
            case .vertical:
                let timelineMagnitude = magnitude(of: range)
                let itemMagnitude = magnitude(of: item.range)
                let height = size.height * itemMagnitude / timelineMagnitude
                let y = Double(item.range.lowerBound - range.lowerBound) * (size.height / timelineMagnitude) + (height / 2)
                let x = size.width / 2
                let position = CGPoint(x: x, y: y)
                return (CGSize(width: size.width, height: height), position)
        }
    }
}

public protocol TimelineItemProtocol: Identifiable {

    associatedtype Bound: BinaryFloatingPoint

    var id: ID { get }

    var range: Range<Bound> { get set }
}


public protocol TimelineLaneProtocol: Identifiable {

    associatedtype Item: TimelineItemProtocol

    var id: ID { get }

    var items: [Item] { get set }
}

struct Timeline_Previews: PreviewProvider {

    struct Lane: TimelineLaneProtocol {

        var id: String

        var items: [Item]

        struct Item: TimelineItemProtocol  {

            typealias Bound = Double

            var id: String

            var range: Range<Bound>

            init(id: String, range: Range<Bound>) {
                self.id = id
                self.range = range
            }
        }
    }

    static var lanes: [Lane] = [
        Lane(id: "0", items: [
            Lane.Item(id: "0", range: (1..<2)),
            Lane.Item(id: "1", range: (7..<10)),
        ]),
        Lane(id: "1", items: [
            Lane.Item(id: "0", range: (1..<2)),
            Lane.Item(id: "1", range: (3..<4)),
            Lane.Item(id: "2", range: (5..<6))
        ]),
        Lane(id: "2", items: [
            Lane.Item(id: "0", range: (1..<2)),
            Lane.Item(id: "1", range: (3..<4)),
            Lane.Item(id: "2", range: (8..<10))
        ]),
        Lane(id: "3", items: [
            Lane.Item(id: "0", range: (1..<2)),
            Lane.Item(id: "1", range: (3..<7)),
            Lane.Item(id: "2", range: (8..<9))
        ]),
        Lane(id: "4", items: [
            Lane.Item(id: "0", range: (2..<4)),
            Lane.Item(id: "1", range: (5..<6)),
            Lane.Item(id: "2", range: (8..<10))
        ])
    ]

    static var previews: some View {

        Group {
            // horizontal
            Timeline(axis: .horizontal, lanes: lanes, range: (0..<10), scale: 1.3, axisLabel: { grid in
                Text("\(Int(grid))")
                    .padding(6)
            }, controlPanel: { lane in
                Text(lane.id)
                    .frame(width: 100)
            }) { lane, item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(.green)
                    .padding(1)
            }

            Timeline(axis: .horizontal, lanes: lanes, range: (0..<10), scale: 1.3) { lane, item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(.green)
                    .padding(1)
            }

            // vertical
            Timeline(axis: .vertical, lanes: lanes, range: (0..<10), scale: 1.3, axisLabel: { grid in
                Text("\(Int(grid))")
                    .padding(6)
            }, controlPanel: { lane in
                Text(lane.id)
                    .frame(width: 100)
            }) { lane, item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(.green)
                    .padding(1)
            }

            Timeline(axis: .vertical, lanes: lanes, range: (0..<10), scale: 1.3) { lane, item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(.green)
                    .padding(1)
            }
        }
    }
}
