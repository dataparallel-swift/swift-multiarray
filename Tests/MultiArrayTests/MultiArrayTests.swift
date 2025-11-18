// Copyright (c) 2025 PassiveLogic, Inc.

import MultiArray
import Testing

struct Point: Generic {
    typealias Representation = Product<Double, Double>

    var x: Double
    var y: Double

    static func from(_ value: Point) -> Product<Double, Double> {
        .init(value.x, value.y)
    }

    static func to(_ value: Product<Double, Double>) -> Point {
        .init(x: value._0, y: value._1)
    }
}

@Suite
struct MultiArrayTests {
    @Test
    func test1() {
        let array: [Point] = [.init(x: 1.0, y: 2.0), .init(x: 3.0, y: 4.0)]
        let multiArray = array.toMultiArray()
        let newArray = array.map { $0.x + 1.0 }
        let newMultiArray = multiArray.map { $0.x + 1.0 }
        #expect(newArray == newMultiArray.toArray())
    }
}
