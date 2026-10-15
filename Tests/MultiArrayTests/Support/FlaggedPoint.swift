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

struct FlaggedPoint: Generic, Equatable, Randomizable, Codable {
    typealias RawRepresentation = T3<Bool, Double, Double>.RawRepresentation

    let active: Bool
    let x: Double
    let y: Double

    init(active: Bool, x: Double, y: Double) {
        self.active = active
        self.x = x
        self.y = y
    }

    var rawRepresentation: RawRepresentation {
        T3(self.active, self.x, self.y).rawRepresentation
    }

    init(from rep: RawRepresentation) {
        let T3 = T3<Bool, Double, Double>(from: rep)
        self = .init(active: T3._0, x: T3._1, y: T3._2)
    }

    static func random<R: RandomNumberGenerator>(using generator: inout R) -> Self {
        Self(
            active: Bool.random(using: &generator),
            x: Double.random(using: &generator),
            y: Double.random(using: &generator)
        )
    }
}
