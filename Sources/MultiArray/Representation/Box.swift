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

// Constant: Encode boxed/constant data (i.e. don't do anything with it; will
// not be encoded into a struct-of-array representation).
public struct Box<Element> {
    public let unbox: Element

    @inlinable
    @_alwaysEmitIntoClient
    public init(_ value: Element) {
        self.unbox = value
    }
}

extension Box: Generic {
    public typealias RawRepresentation = Self
}

extension Box: Equatable where Element: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.unbox == rhs.unbox }
}

// This instance is necessary for any values that are not trivially copyable,
// i.e. class-based types (e.g. String) that are owned by somebody else, but we
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
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func read(_ arrayData: Self.Buffer, at index: Int) -> Self {
        Box(arrayData[index])
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func write(_ arrayData: Self.Buffer, at index: Int, to value: Self) {
        // Overwriting an already-initialised element will correctly
        // de-initialise any existing element. This is called via the subscript
        // operator and not during initialisation of the multiarray.
        arrayData[index] = value.unbox
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func reserve(capacity: Int, from context: inout UnsafeMutableRawPointer) -> Self.Buffer {
        reserveCapacity(for: Element.self, count: capacity, from: &context)
    }

    @inlinable
    // @inline(__always)
    // @_alwaysEmitIntoClient
    public static func rawSize(capacity: Int, from offset: Int) -> Int {
        getRawSize(for: Element.self, count: capacity, from: offset)
    }
}

// Box deliberately has no BinaryArrayData conformance: its payload may include
// pointers or other process-local state.
