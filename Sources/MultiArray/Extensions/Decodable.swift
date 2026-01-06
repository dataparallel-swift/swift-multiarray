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

extension MultiArray: Decodable where Element: Decodable {
    private enum CodingKeys: CodingKey {
        case version
        case count
        case values
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // If the version tag is absent, decode as v1. Only the 2.0.0 release
        // did not include a version tag, but was added since 2.1.0. This format
        // is a fairly (human) readable encoding of just {count, values}.
        let version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1

        switch version {
            case 1:
                let count = try container.decode(Int.self, forKey: .count)
                var values = try container.nestedUnkeyedContainer(forKey: .values)
                self = try .init(count: count) { _ in
                    try values.decode(Element.self)
                }

                if !values.isAtEnd {
                    throw DecodingError.dataCorrupted(
                        .init(
                            codingPath: values.codingPath,
                            debugDescription: "More values than expected for count: \(count)"
                        )
                    )
                }

            default:
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: container.codingPath,
                        debugDescription: "Unsupported MultiArray coding version: \(version)"
                    )
                )
        }
    }
}
