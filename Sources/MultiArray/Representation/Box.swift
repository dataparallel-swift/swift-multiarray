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

/// Stores an ordinary Swift value as one field without decomposing it.
///
/// Copying a box copies its payload using the payload's normal value or reference
/// semantics. Boxed fields are not eligible for native binary snapshots.
public struct Box<Element> {
    /// The stored value.
    public let unbox: Element

    /// Wraps a value for field-wise storage.
    @inlinable
    public init(_ value: Element) {
        self.unbox = value
    }
}

extension Box: Sendable where Element: Sendable {}

extension Box: Generic {
    public typealias RawRepresentation = Self
}

extension Box: Equatable where Element: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.unbox == rhs.unbox }
}

// This instance is necessary for any values that are not trivially copyable,
// including values with reference-backed storage that we
// need to keep a strong reference to. In this case initialisation and
// de-initialisation of the raw underlying buffer are important!
extension Box: ArrayData {
    public typealias Buffer = UnsafeMutablePointer<Element>

    @inlinable
    public static func initialize(_ arrayData: Self.Buffer, at index: Int, to value: Self) {
        (arrayData + index).initialize(to: value.unbox)
    }

    @inlinable
    public static func initialize(_ arrayData: Self.Buffer, from source: Self.Buffer, count: Int) {
        arrayData.initialize(from: source, count: count)
    }

    @inlinable
    public static func initialize(_ arrayData: Self.Buffer, repeating value: Self, count: Int) {
        arrayData.initialize(repeating: value.unbox, count: count)
    }

    @inlinable
    public static func deinitialize(_ arrayData: Self.Buffer, count: Int) {
        arrayData.deinitialize(count: count)
    }

    @inlinable
    public static func read(_ arrayData: Self.Buffer, at index: Int) -> Self {
        Box(arrayData[index])
    }

    @inlinable
    public static func write(_ arrayData: Self.Buffer, at index: Int, to value: Self) {
        // Overwriting an already-initialised element will correctly
        // de-initialise any existing element. This is called via the subscript
        // operator and not during initialisation of the multiarray.
        arrayData[index] = value.unbox
    }

    @inlinable
    public static func reserve(capacity: Int, from context: inout UnsafeMutableRawPointer) -> Self.Buffer {
        reserveCapacity(for: Element.self, count: capacity, from: &context)
    }

    @inlinable
    public static func rawSize(capacity: Int, from offset: Int) -> Int? {
        getRawSize(for: Element.self, count: capacity, from: offset)
    }
}

extension Box: PartialInitializationArrayData {
    // Even a seemingly trivial payload is kept conservative: Box accepts any
    // Element, and its storage may own references that need destruction.
    @inlinable
    public static var requiresInitializationTracking: Bool { true }

    @inlinable
    public static func deinitialize(_ arrayData: Buffer, at index: Int) {
        (arrayData + index).deinitialize(count: 1)
    }
}

// Box deliberately has no BinaryArrayData conformance: its payload may include
// pointers or other process-local state.
