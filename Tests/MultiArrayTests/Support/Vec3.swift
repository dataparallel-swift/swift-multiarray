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

struct Vec3<Element>: Equatable, Codable where Element: Equatable & Codable {
    let x, y, z: Element

    init(x: Element, y: Element, z: Element) {
        self.x = x
        self.y = y
        self.z = z
    }
}

extension Vec3: Generic where Element: Generic {
    typealias RawRepresentation = T3<Element, Element, Element>.RawRepresentation

    var rawRepresentation: RawRepresentation {
        T3(self.x, self.y, self.z).rawRepresentation
    }

    init(from rep: RawRepresentation) {
        let T3 = T3<Element, Element, Element>(from: rep)
        self = Vec3(x: T3._0, y: T3._1, z: T3._2)
    }
}

extension Vec3: Randomizable where Element: Randomizable {
    static func random<T: RandomNumberGenerator>(using generator: inout T) -> Self {
        Vec3(
            x: Element.random(using: &generator),
            y: Element.random(using: &generator),
            z: Element.random(using: &generator)
        )
    }
}
