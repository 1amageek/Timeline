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

    public init(
        lanes: [Lane],
        range: Range<Item.Bound>,
        scale: CGFloat = 1,
        axisLabel: @escaping (Double) -> AxisLabel,
        controlPanel: @escaping (Lane) -> ControlPanel,
        content: @escaping (Lane, Item) -> Content
    ) {
        self.model = Model(lanes: lanes, range: range, scale: scale)
        self.axisLabel = axisLabel
        self.controlPanel = controlPanel
        self.content = content
    }

    public init(
        lanes: [Lane],
        range: Range<Item.Bound>,
        scale: CGFloat = 1,
        content: @escaping (Lane, Item) -> Content
    ) where AxisLabel == Never, ControlPanel == Never {
        self.model = Model(lanes: lanes, range: range, scale: scale)
        self.axisLabel = nil
        self.controlPanel = nil
        self.content = content
    }

    public var body: some View {
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
                                Ruler(range: model.range) { grid in
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
                            .background(BackgroundGide(range: model.range))
                        } else {
                            VStack(spacing: 0) {
                                ForEach(model.lanes) { lane in
                                    LaneView(model: model, lane: lane, content: content)
                                }
                            }
                            .background(BackgroundGide(range: model.range))
                        }
                    }
                    .frame(width: proxy.size.width * model.scale, height: proxy.size.height)
                }
                .compositingGroup()
            }
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
                        let (width, position) = model.property(item: item, size: proxy.size)
                        content(lane, item)
                            .frame(width: width)
                            .position(position)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct TimelineModel<Lane: TimelineLaneProtocol> {

    typealias Item = Lane.Item

    typealias Bound = Item.Bound

    var lanes: [Lane]

    var range: Range<Item.Bound>

    var scale: Double

    init(lanes: [Lane] = [], range: Range<Item.Bound>, scale: Double = 1) {
        self.lanes = lanes
        self.range = range
        self.scale = scale
    }
}

extension TimelineModel {

    func magnitude(of range: Range<Bound>) -> Double {
        return Double(range.upperBound - range.lowerBound)
    }

    func property(item: Item, size: CGSize) -> (CGFloat, CGPoint) {
        let timelineMagnitude = magnitude(of: range)
        let itemMagnitude = magnitude(of: item.range)
        let width = size.width * itemMagnitude / timelineMagnitude
        let x = Double(item.range.lowerBound - range.lowerBound) * (size.width / timelineMagnitude) + (width / 2)
        let y = size.height / 2
        let position = CGPoint(x: x, y: y)
        return (width, position)
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
            Timeline(lanes: lanes, range: (0..<10), scale: 1.3, axisLabel: { grid in
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

            Timeline(lanes: lanes, range: (0..<10), scale: 1.3) { lane, item in
                RoundedRectangle(cornerRadius: 8)
                    .fill(.green)
                    .padding(1)
            }
        }
    }
}
