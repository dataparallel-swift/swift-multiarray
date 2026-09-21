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

import Foundation

// Products: encode multiple arguments to constructors.
public struct Product<A, B> {
    public let _0: A
    public let _1: B

    @inlinable
    public init(_ lhs: A, _ rhs: B) {
        self._0 = lhs
        self._1 = rhs
    }
}

extension Product: Generic where A: Generic, B: Generic {
    public typealias RawRepresentation = Product<A.RawRepresentation, B.RawRepresentation>

    @inlinable
    public var rawRepresentation: Product<A.RawRepresentation, B.RawRepresentation> {
        .init(self._0.rawRepresentation, self._1.rawRepresentation)
    }

    @inlinable
    public init(from rep: RawRepresentation) {
        self = Product(
            A(from: rep._0),
            B(from: rep._1)
        )
    }
}

extension Product: ArrayData where A: ArrayData, B: ArrayData {
    public typealias Buffer = (A.Buffer, B.Buffer)

    @inlinable
    public static func initialize(_ arrayData: Self.Buffer, at index: Int, to value: Self) {
        A.initialize(arrayData.0, at: index, to: value._0)
        B.initialize(arrayData.1, at: index, to: value._1)
    }

    @inlinable
    public static func initialize(_ arrayData: Self.Buffer, from source: Self.Buffer, count: Int) {
        A.initialize(arrayData.0, from: source.0, count: count)
        B.initialize(arrayData.1, from: source.1, count: count)
    }

    @inlinable
    public static func initialize(_ arrayData: Self.Buffer, repeating value: Self, count: Int) {
        A.initialize(arrayData.0, repeating: value._0, count: count)
        B.initialize(arrayData.1, repeating: value._1, count: count)
    }

    @inlinable
    public static func deinitialize(_ arrayData: Self.Buffer, count: Int) {
        A.deinitialize(arrayData.0, count: count)
        B.deinitialize(arrayData.1, count: count)
    }

    @inlinable
    public static func read(_ arrayData: Self.Buffer, at index: Int) -> Self {
        .init(
            A.read(arrayData.0, at: index),
            B.read(arrayData.1, at: index)
        )
    }

    @inlinable
    public static func write(_ arrayData: Self.Buffer, at index: Int, to value: Self) {
        A.write(arrayData.0, at: index, to: value._0)
        B.write(arrayData.1, at: index, to: value._1)
    }

    @inlinable
    public static func reserve(capacity: Int, from context: inout UnsafeMutableRawPointer) -> Self.Buffer {
        let aR = A.reserve(capacity: capacity, from: &context)
        let bR = B.reserve(capacity: capacity, from: &context)
        return (aR, bR)
    }

    @inlinable
    public static func rawSize(capacity: Int, from offset: Int) -> Int {
        getRawSize(for: B.self, count: capacity, from: getRawSize(for: A.self, count: capacity, from: offset))
    }
}

extension Product: BinaryArrayData where A: BinaryArrayData, B: BinaryArrayData {
    public static var type: Type {
        .product(lhs: A.type, rhs: B.type)
    }

    public static var typeHead: TypeHead {
        .product
    }

    public static func verifyType(in data: Data, at offset: inout Int) throws {
        try verifyByte(expecting: Self.typeHead.rawValue, in: data, at: &offset)
        try A.verifyType(in: data, at: &offset)
        try B.verifyType(in: data, at: &offset)
    }

    public static func appendType(to data: inout Data) {
        data.append(Self.typeHead.rawValue)
        A.appendType(to: &data)
        B.appendType(to: &data)
    }

    public static func firstInvalidElement(in buffer: Buffer, count: Int) -> Int? {
        switch (
            A.firstInvalidElement(in: buffer.0, count: count),
            B.firstInvalidElement(in: buffer.1, count: count)
        ) {
            case let (left?, nil): left
            case let (nil, right?): right
            case let (left?, right?): min(left, right)
            case (nil, nil): nil
        }
    }
}
