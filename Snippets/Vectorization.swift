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

// snippet.model
@Generic
public struct Vector3 {
    public let x, y, z: Float
}

@Generic
public struct Particle {
    public let id: Int64
    public let position: Vector3

    public func moved(dx: Float = 0, dy: Float = 0, dz: Float = 0) -> Particle {
        Particle(
            id: self.id,
            position: Vector3(
                x: self.position.x + dx,
                y: self.position.y + dy,
                z: self.position.z + dz
            )
        )
    }
}

// snippet.end

// snippet.move
public func move(_ input: MultiArray<Particle>) -> MultiArray<Particle> {
    input.map { $0.moved(dx: 1) }
}

// snippet.end
