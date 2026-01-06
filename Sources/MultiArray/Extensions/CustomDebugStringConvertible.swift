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

// XXX: Maybe we want to have this representation print the values in their
// encoded representation, rather than in the surface representation, since
// that's what the regular CustomStringConvertible does already.
extension MultiArray: CustomDebugStringConvertible {
    public var debugDescription: String {
        """
        MultiArray<\(Element.self)> {
            count: \(self.count)
            encoding: \(Element.RawRepresentation.self)
            storage: \(self.arrayData.storage)
            values: [\(map { String(describing: $0) }.joined(separator: ", "))]
        }
        """
    }
}
