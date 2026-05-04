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

struct Point: Generic, Equatable, Randomizable, Codable {
    typealias RawRepresentation = Product<Double, Double>

    var x: Double
    var y: Double

    var rawRepresentation: Product<Double, Double> {
        .init(x, y)
    }

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    init(from rep: RawRepresentation) {
        self = .init(x: rep._0, y: rep._1)
    }

    static func random<R: RandomNumberGenerator>(using generator: inout R) -> Self {
        Self(
            x: Double.random(using: &generator),
            y: Double.random(using: &generator)
        )
    }
}
