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
import Testing

// This conformance is deliberately written in a separate client module using
// only ArrayData. Adding the refinement must not add a protocol requirement to
// existing clients or grant them scattered-initialization capability.
private struct ExternalArrayData: ArrayData {
    typealias Buffer = UnsafeMutablePointer<Self>
}

private func supportsScatteredCleanup<T: ArrayData>(_: T.Type) -> Bool { false }
private func supportsScatteredCleanup<T: PartialInitializationArrayData>(_: T.Type) -> Bool { true }

private enum Code: Int32, Generic {
    case value = 1

    typealias RawRepresentation = RawValueRepresentation<Self>
}

private final class Token {}

@Suite
struct PartialInitializationArrayDataTests {
    @Test
    func trackingTraitComposes() {
        #expect(!Int32.requiresInitializationTracking)
        #expect(!SIMD4<Float>.requiresInitializationTracking)
        #expect(!Unit.requiresInitializationTracking)
        #expect(!Product<Int32, Unit>.requiresInitializationTracking)
        #expect(!RawValueRepresentation<Code>.requiresInitializationTracking)
        #expect(Box<Int32>.requiresInitializationTracking)
        #expect(Product<Int32, Box<String>>.requiresInitializationTracking)
        #expect(Product<Box<String>, Product<Unit, Int32>>.requiresInitializationTracking)
    }

    @Test
    func externalArrayDataDoesNotAcquireScatteredCleanup() {
        #expect(!supportsScatteredCleanup(ExternalArrayData.self))
        #expect(supportsScatteredCleanup(Product<Int32, Box<String>>.self))
    }

    @Test
    func trivialPerIndexCleanupIsNoOp() {
        let pointer = UnsafeMutablePointer<Int32>.allocate(capacity: 4)
        defer { pointer.deallocate() }
        Int32.initialize(pointer, at: 2, to: 42)
        Int32.deinitialize(pointer, at: 2)
        Unit.deinitialize((), at: 2)

        let raw = Code.value.rawRepresentation
        RawValueRepresentation<Code>.initialize(pointer, at: 1, to: raw)
        RawValueRepresentation<Code>.deinitialize(pointer, at: 1)
    }

    @Test
    func scatteredProductCleanupReleasesOnlySelectedIndex() {
        typealias Representation = Product<Int32, Product<Box<Token>, Box<Token>>>
        let numbers = UnsafeMutablePointer<Int32>.allocate(capacity: 5)
        let first = UnsafeMutablePointer<Token>.allocate(capacity: 5)
        let second = UnsafeMutablePointer<Token>.allocate(capacity: 5)
        defer {
            numbers.deallocate()
            first.deallocate()
            second.deallocate()
        }
        let buffer: Representation.Buffer = (numbers, (first, second))

        weak var firstAtOne: Token?
        weak var secondAtOne: Token?
        weak var firstAtFour: Token?
        weak var secondAtFour: Token?
        do {
            let a = Token()
            let b = Token()
            firstAtOne = a
            secondAtOne = b
            Representation.initialize(buffer, at: 1, to: Product(1, Product(Box(a), Box(b))))
        }
        do {
            let a = Token()
            let b = Token()
            firstAtFour = a
            secondAtFour = b
            Representation.initialize(buffer, at: 4, to: Product(4, Product(Box(a), Box(b))))
        }

        #expect(firstAtOne != nil)
        #expect(secondAtOne != nil)
        #expect(firstAtFour != nil)
        #expect(secondAtFour != nil)

        Representation.deinitialize(buffer, at: 4)
        #expect(firstAtFour == nil)
        #expect(secondAtFour == nil)
        #expect(firstAtOne != nil)
        #expect(secondAtOne != nil)

        Representation.deinitialize(buffer, at: 1)
        #expect(firstAtOne == nil)
        #expect(secondAtOne == nil)
    }
}
