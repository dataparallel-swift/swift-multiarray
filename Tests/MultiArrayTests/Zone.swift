// Copyright (c) 2025 The swift-multiarray authors. All rights reserved.
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

struct Zone: Generic, Equatable, Randomizable, Codable {
    typealias RawRepresentation = T2<Int, Vec3<Float>>.RawRepresentation

    let id: Int
    let position: Vec3<Float>

    init(id: Int, position: Vec3<Float>) {
        self.id = id
        self.position = position
    }

    func move(dx: Float = 0, dy: Float = 0, dz: Float = 0) -> Zone {
        Zone(id: self.id, position: Vec3(x: self.position.x + dx, y: self.position.y + dy, z: self.position.z + dz))
    }

    var rawRepresentation: RawRepresentation {
        T2(self.id, self.position).rawRepresentation
    }

    init(from rep: RawRepresentation) {
        self = Zone(id: rep._0, position: .init(from: rep._1))
    }

    static func random<T: RandomNumberGenerator>(using generator: inout T) -> Self {
        Zone(
            id: Int.random(using: &generator),
            position: Vec3<Float>.random(using: &generator)
        )
    }
}
