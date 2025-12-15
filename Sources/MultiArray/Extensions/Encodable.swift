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

extension MultiArray: Encodable where Element: Encodable {
    private enum CodingKeys: CodingKey {
        case version
        case count
        case values
    }

    // Current version of the encoding schema.
    // This needs to be bumped whenever the format changes.
    private static var codingVersion: Int { 1 }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.codingVersion, forKey: .version)
        try container.encode(self.count, forKey: .count)

        var values = container.nestedUnkeyedContainer(forKey: .values)
        for value in self {
            try values.encode(value)
        }
    }
}
