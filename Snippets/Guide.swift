// Copyright (c) 2026 The swift-multiarray authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import MultiArray

// snippet.point
@Generic
struct Point {
    var x: Double
    var y: Double
}

func makePoints() -> MultiArray<Point> {
    [
        Point(x: 1, y: 2),
        Point(x: 3, y: 4),
    ]
}

// snippet.end

// snippet.generic
@Generic
struct Vec3<Element> where Element: Generic {
    let x, y, z: Element
}

@Generic
struct Zone {
    let id: Int8
    let position: Vec3<Float>
}

// snippet.end

// snippet.box
@Generic
struct Labeled {
    let label: Box<String>
    let value: Float
}

@Generic
struct LabeledWithMacro {
    @Box var label: String
    let value: Float

    init(label: String, value: Float) {
        self._label = Box(label)
        self.value = value
    }
}

// snippet.end

// snippet.computed
@Generic
struct Vec2 {
    var x: Float
    var y: Float
    var magnitude: Float { (self.x * self.x + self.y * self.y).squareRoot() }
}

// snippet.end

// snippet.status
@Generic
enum Status: UInt8 {
    case off = 0
    case on = 1
}

// snippet.end

func guideExamples() {
    let points = makePoints()
    precondition(points.count == 2)
    precondition(points[1].x == 3)

    let zones: MultiArray<Zone> = [Zone(id: 1, position: Vec3(x: 2, y: 3, z: 4))]
    precondition(zones[0].position.z == 4)

    let labels: MultiArray<LabeledWithMacro> = [LabeledWithMacro(label: "temperature", value: 21)]
    precondition(labels[0].label == "temperature")

    let statuses: MultiArray<Status> = [.off, .on]
    precondition(statuses[1] == .on)
}

guideExamples()
