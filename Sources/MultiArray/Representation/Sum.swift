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

// Sums: encode choice between constructors.
//
// TODO: This simple binary sum has no ArrayData conformance. A sum-of-products
// representation, potentially inverted into product-of-sums, could reuse the
// underlying storage for fields shared by individual variants.
public enum Sum<A, B> {
    case lhs(A)
    case rhs(B)
}

extension Sum: Generic where A: Generic, B: Generic {
    public typealias RawRepresentation = Sum<A.RawRepresentation, B.RawRepresentation>

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Sum<A.RawRepresentation, B.RawRepresentation> {
        switch self {
            case let .lhs(left): .lhs(left.rawRepresentation)
            case let .rhs(right): .rhs(right.rawRepresentation)
        }
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = switch rep {
            case let .lhs(left): .lhs(A(from: left))
            case let .rhs(right): .rhs(B(from: right))
        }
    }
}
