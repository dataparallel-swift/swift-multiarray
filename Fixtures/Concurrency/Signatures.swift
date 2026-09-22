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

protocol FixtureGeneric {
    associatedtype RawRepresentation
}

struct FixtureUnsafeUninitializedBuffer<Element> where Element: FixtureGeneric {}

extension FixtureUnsafeUninitializedBuffer: @unchecked Sendable
    where Element: Sendable, Element.RawRepresentation: Sendable {}

struct FixtureMultiArray<Element> where Element: FixtureGeneric {
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 9, *)
    init<Failure: Error>(
        unsafeUninitializedCapacity _: Int,
        initializingWith body: sending(
            FixtureUnsafeUninitializedBuffer<Element>
        ) async throws(Failure) -> Void
    ) async throws(Failure) {
        try await body(FixtureUnsafeUninitializedBuffer())
    }
}

enum FixtureError: Error {
    case childFailed
}

struct FixtureElement: FixtureGeneric, Sendable {
    typealias RawRepresentation = Int
}

@available(macOS 10.15, iOS 13, tvOS 13, watchOS 9, *)
func exerciseConcurrencySignatures() async throws(FixtureError) {
    _ = try await FixtureMultiArray<FixtureElement>(unsafeUninitializedCapacity: 4) { buffer throws(FixtureError) in
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for _ in 0 ..< 4 {
                    group.addTask {
                        _ = buffer
                    }
                }
                try await group.waitForAll()
            }
        }
        catch {
            throw .childFailed
        }
    }
}
