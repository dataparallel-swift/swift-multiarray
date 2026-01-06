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

// swiftlint:disable identifier_name

public struct T2<A, B> {
    public let _0: A
    public let _1: B

    @inlinable
    @_alwaysEmitIntoClient
    public init(_ _0: A, _ _1: B) {
        self._0 = _0
        self._1 = _1
    }
}

extension T2: Generic where A: Generic, B: Generic {
    public typealias RawRepresentation = Product<A, B>.RawRepresentation

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Self.RawRepresentation {
        Product(
            _0.rawRepresentation,
            _1.rawRepresentation
        )
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = T2(
            A(from: rep._0),
            B(from: rep._1)
        )
    }
}

public struct T3<A, B, C> {
    public let _0: A
    public let _1: B
    public let _2: C

    @inlinable
    @_alwaysEmitIntoClient
    public init(_ _0: A, _ _1: B, _ _2: C) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
    }
}

extension T3: Generic where A: Generic, B: Generic, C: Generic {
    public typealias RawRepresentation = T2<T2<A, B>, C>.RawRepresentation

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: T2<T2<A, B>, C>.RawRepresentation {
        T2(T2(_0, _1), _2).rawRepresentation
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = T3(
            A(from: rep._0._0),
            B(from: rep._0._1),
            C(from: rep._1)
        )
    }
}

public struct T4<A, B, C, D> {
    public let _0: A
    public let _1: B
    public let _2: C
    public let _3: D

    @inlinable
    @_alwaysEmitIntoClient
    public init(_ _0: A, _ _1: B, _ _2: C, _ _3: D) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
        self._3 = _3
    }
}

extension T4: Generic where A: Generic, B: Generic, C: Generic, D: Generic {
    public typealias RawRepresentation = T2<T2<A, B>, T2<C, D>>.RawRepresentation

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Self.RawRepresentation {
        T2(T2(_0, _1), T2(_2, _3)).rawRepresentation
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = T4(
            A(from: rep._0._0),
            B(from: rep._0._1),
            C(from: rep._1._0),
            D(from: rep._1._1)
        )
    }
}

public struct T5<A, B, C, D, E> {
    public let _0: A
    public let _1: B
    public let _2: C
    public let _3: D
    public let _4: E

    @inlinable
    @_alwaysEmitIntoClient
    public init(_ _0: A, _ _1: B, _ _2: C, _ _3: D, _ _4: E) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
        self._3 = _3
        self._4 = _4
    }
}

extension T5: Generic where A: Generic, B: Generic, C: Generic, D: Generic, E: Generic {
    public typealias RawRepresentation = T2<T4<A, B, C, D>, E>.RawRepresentation

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Self.RawRepresentation {
        T2(T4(_0, _1, _2, _3), _4).rawRepresentation
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = T5(
            A(from: rep._0._0._0),
            B(from: rep._0._0._1),
            C(from: rep._0._1._0),
            D(from: rep._0._1._1),
            E(from: rep._1)
        )
    }
}

public struct T6<A, B, C, D, E, F> {
    public let _0: A
    public let _1: B
    public let _2: C
    public let _3: D
    public let _4: E
    public let _5: F

    @inlinable
    @_alwaysEmitIntoClient
    public init(_ _0: A, _ _1: B, _ _2: C, _ _3: D, _ _4: E, _ _5: F) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
        self._3 = _3
        self._4 = _4
        self._5 = _5
    }
}

extension T6: Generic where A: Generic, B: Generic, C: Generic, D: Generic, E: Generic, F: Generic {
    public typealias RawRepresentation = T2<T4<A, B, C, D>, T2<E, F>>.RawRepresentation

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Self.RawRepresentation {
        T2(T4(_0, _1, _2, _3), T2(_4, _5)).rawRepresentation
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = T6(
            A(from: rep._0._0._0),
            B(from: rep._0._0._1),
            C(from: rep._0._1._0),
            D(from: rep._0._1._1),
            E(from: rep._1._0),
            F(from: rep._1._1)
        )
    }
}

public struct T7<A, B, C, D, E, F, G> {
    public let _0: A
    public let _1: B
    public let _2: C
    public let _3: D
    public let _4: E
    public let _5: F
    public let _6: G

    @inlinable
    @_alwaysEmitIntoClient
    public init(_ _0: A, _ _1: B, _ _2: C, _ _3: D, _ _4: E, _ _5: F, _ _6: G) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
        self._3 = _3
        self._4 = _4
        self._5 = _5
        self._6 = _6
    }
}

extension T7: Generic where A: Generic, B: Generic, C: Generic, D: Generic, E: Generic, F: Generic, G: Generic {
    public typealias RawRepresentation = T2<T4<A, B, C, D>, T3<E, F, G>>.RawRepresentation

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Self.RawRepresentation {
        T2(T4(_0, _1, _2, _3), T3(_4, _5, _6)).rawRepresentation
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = T7(
            A(from: rep._0._0._0),
            B(from: rep._0._0._1),
            C(from: rep._0._1._0),
            D(from: rep._0._1._1),
            E(from: rep._1._0._0),
            F(from: rep._1._0._1),
            G(from: rep._1._1)
        )
    }
}

public struct T8<A, B, C, D, E, F, G, H> {
    public let _0: A
    public let _1: B
    public let _2: C
    public let _3: D
    public let _4: E
    public let _5: F
    public let _6: G
    public let _7: H

    @inlinable
    @_alwaysEmitIntoClient
    public init(_ _0: A, _ _1: B, _ _2: C, _ _3: D, _ _4: E, _ _5: F, _ _6: G, _ _7: H) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
        self._3 = _3
        self._4 = _4
        self._5 = _5
        self._6 = _6
        self._7 = _7
    }
}

extension T8: Generic where A: Generic, B: Generic, C: Generic, D: Generic, E: Generic, F: Generic, G: Generic, H: Generic {
    public typealias RawRepresentation = T2<T4<A, B, C, D>, T4<E, F, G, H>>.RawRepresentation

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Self.RawRepresentation {
        T2(T4(_0, _1, _2, _3), T4(_4, _5, _6, _7)).rawRepresentation
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = T8(
            A(from: rep._0._0._0),
            B(from: rep._0._0._1),
            C(from: rep._0._1._0),
            D(from: rep._0._1._1),
            E(from: rep._1._0._0),
            F(from: rep._1._0._1),
            G(from: rep._1._1._0),
            H(from: rep._1._1._1)
        )
    }
}

public struct T9<A, B, C, D, E, F, G, H, I> {
    public let _0: A
    public let _1: B
    public let _2: C
    public let _3: D
    public let _4: E
    public let _5: F
    public let _6: G
    public let _7: H
    public let _8: I

    @inlinable
    @_alwaysEmitIntoClient
    public init(_ _0: A, _ _1: B, _ _2: C, _ _3: D, _ _4: E, _ _5: F, _ _6: G, _ _7: H, _ _8: I) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
        self._3 = _3
        self._4 = _4
        self._5 = _5
        self._6 = _6
        self._7 = _7
        self._8 = _8
    }
}

extension T9: Generic where A: Generic, B: Generic, C: Generic, D: Generic, E: Generic, F: Generic, G: Generic, H: Generic, I: Generic {
    public typealias RawRepresentation = T2<T8<A, B, C, D, E, F, G, H>, I>.RawRepresentation

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Self.RawRepresentation {
        T2(T8(_0, _1, _2, _3, _4, _5, _6, _7), _8).rawRepresentation
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = T9(
            A(from: rep._0._0._0._0),
            B(from: rep._0._0._0._1),
            C(from: rep._0._0._1._0),
            D(from: rep._0._0._1._1),
            E(from: rep._0._1._0._0),
            F(from: rep._0._1._0._1),
            G(from: rep._0._1._1._0),
            H(from: rep._0._1._1._1),
            I(from: rep._1)
        )
    }
}

public struct T10<A, B, C, D, E, F, G, H, I, J> {
    public let _0: A
    public let _1: B
    public let _2: C
    public let _3: D
    public let _4: E
    public let _5: F
    public let _6: G
    public let _7: H
    public let _8: I
    public let _9: J

    @inlinable
    @_alwaysEmitIntoClient
    public init(_ _0: A, _ _1: B, _ _2: C, _ _3: D, _ _4: E, _ _5: F, _ _6: G, _ _7: H, _ _8: I, _ _9: J) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
        self._3 = _3
        self._4 = _4
        self._5 = _5
        self._6 = _6
        self._7 = _7
        self._8 = _8
        self._9 = _9
    }
}

extension T10: Generic where A: Generic, B: Generic, C: Generic, D: Generic, E: Generic, F: Generic, G: Generic, H: Generic,
    I: Generic, J: Generic
{
    public typealias RawRepresentation = T2<T8<A, B, C, D, E, F, G, H>, T2<I, J>>.RawRepresentation

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Self.RawRepresentation {
        T2(T8(_0, _1, _2, _3, _4, _5, _6, _7), T2(_8, _9)).rawRepresentation
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = T10(
            A(from: rep._0._0._0._0),
            B(from: rep._0._0._0._1),
            C(from: rep._0._0._1._0),
            D(from: rep._0._0._1._1),
            E(from: rep._0._1._0._0),
            F(from: rep._0._1._0._1),
            G(from: rep._0._1._1._0),
            H(from: rep._0._1._1._1),
            I(from: rep._1._0),
            J(from: rep._1._1)
        )
    }
}

public struct T11<A, B, C, D, E, F, G, H, I, J, K> {
    public let _0: A
    public let _1: B
    public let _2: C
    public let _3: D
    public let _4: E
    public let _5: F
    public let _6: G
    public let _7: H
    public let _8: I
    public let _9: J
    public let _10: K

    @inlinable
    @_alwaysEmitIntoClient
    public init(
        _ _0: A,
        _ _1: B,
        _ _2: C,
        _ _3: D,
        _ _4: E,
        _ _5: F,
        _ _6: G,
        _ _7: H,
        _ _8: I,
        _ _9: J,
        _ _10: K
    ) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
        self._3 = _3
        self._4 = _4
        self._5 = _5
        self._6 = _6
        self._7 = _7
        self._8 = _8
        self._9 = _9
        self._10 = _10
    }
}

extension T11: Generic where A: Generic, B: Generic, C: Generic, D: Generic, E: Generic, F: Generic, G: Generic, H: Generic,
    I: Generic, J: Generic, K: Generic
{
    public typealias RawRepresentation = T2<T8<A, B, C, D, E, F, G, H>, T3<I, J, K>>.RawRepresentation

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Self.RawRepresentation {
        T2(T8(_0, _1, _2, _3, _4, _5, _6, _7), T3(_8, _9, _10)).rawRepresentation
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = T11(
            A(from: rep._0._0._0._0),
            B(from: rep._0._0._0._1),
            C(from: rep._0._0._1._0),
            D(from: rep._0._0._1._1),
            E(from: rep._0._1._0._0),
            F(from: rep._0._1._0._1),
            G(from: rep._0._1._1._0),
            H(from: rep._0._1._1._1),
            I(from: rep._1._0._0),
            J(from: rep._1._0._1),
            K(from: rep._1._1)
        )
    }
}

public struct T12<A, B, C, D, E, F, G, H, I, J, K, L> {
    public let _0: A
    public let _1: B
    public let _2: C
    public let _3: D
    public let _4: E
    public let _5: F
    public let _6: G
    public let _7: H
    public let _8: I
    public let _9: J
    public let _10: K
    public let _11: L

    @inlinable
    @_alwaysEmitIntoClient
    public init(
        _ _0: A,
        _ _1: B,
        _ _2: C,
        _ _3: D,
        _ _4: E,
        _ _5: F,
        _ _6: G,
        _ _7: H,
        _ _8: I,
        _ _9: J,
        _ _10: K,
        _ _11: L
    ) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
        self._3 = _3
        self._4 = _4
        self._5 = _5
        self._6 = _6
        self._7 = _7
        self._8 = _8
        self._9 = _9
        self._10 = _10
        self._11 = _11
    }
}

extension T12: Generic where A: Generic, B: Generic, C: Generic, D: Generic, E: Generic, F: Generic, G: Generic, H: Generic,
    I: Generic, J: Generic, K: Generic, L: Generic
{
    public typealias RawRepresentation = T2<T8<A, B, C, D, E, F, G, H>, T4<I, J, K, L>>.RawRepresentation

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Self.RawRepresentation {
        T2(T8(_0, _1, _2, _3, _4, _5, _6, _7), T4(_8, _9, _10, _11)).rawRepresentation
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = T12(
            A(from: rep._0._0._0._0),
            B(from: rep._0._0._0._1),
            C(from: rep._0._0._1._0),
            D(from: rep._0._0._1._1),
            E(from: rep._0._1._0._0),
            F(from: rep._0._1._0._1),
            G(from: rep._0._1._1._0),
            H(from: rep._0._1._1._1),
            I(from: rep._1._0._0),
            J(from: rep._1._0._1),
            K(from: rep._1._1._0),
            L(from: rep._1._1._1)
        )
    }
}

public struct T13<A, B, C, D, E, F, G, H, I, J, K, L, M> {
    public let _0: A
    public let _1: B
    public let _2: C
    public let _3: D
    public let _4: E
    public let _5: F
    public let _6: G
    public let _7: H
    public let _8: I
    public let _9: J
    public let _10: K
    public let _11: L
    public let _12: M

    @inlinable
    @_alwaysEmitIntoClient
    public init(
        _ _0: A,
        _ _1: B,
        _ _2: C,
        _ _3: D,
        _ _4: E,
        _ _5: F,
        _ _6: G,
        _ _7: H,
        _ _8: I,
        _ _9: J,
        _ _10: K,
        _ _11: L,
        _ _12: M
    ) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
        self._3 = _3
        self._4 = _4
        self._5 = _5
        self._6 = _6
        self._7 = _7
        self._8 = _8
        self._9 = _9
        self._10 = _10
        self._11 = _11
        self._12 = _12
    }
}

extension T13: Generic where A: Generic, B: Generic, C: Generic, D: Generic, E: Generic, F: Generic, G: Generic, H: Generic,
    I: Generic, J: Generic, K: Generic, L: Generic, M: Generic
{
    public typealias RawRepresentation = T2<T8<A, B, C, D, E, F, G, H>, T5<I, J, K, L, M>>.RawRepresentation

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Self.RawRepresentation {
        T2(T8(_0, _1, _2, _3, _4, _5, _6, _7), T5(_8, _9, _10, _11, _12)).rawRepresentation
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = T13(
            A(from: rep._0._0._0._0),
            B(from: rep._0._0._0._1),
            C(from: rep._0._0._1._0),
            D(from: rep._0._0._1._1),
            E(from: rep._0._1._0._0),
            F(from: rep._0._1._0._1),
            G(from: rep._0._1._1._0),
            H(from: rep._0._1._1._1),
            I(from: rep._1._0._0._0),
            J(from: rep._1._0._0._1),
            K(from: rep._1._0._1._0),
            L(from: rep._1._0._1._1),
            M(from: rep._1._1)
        )
    }
}

public struct T14<A, B, C, D, E, F, G, H, I, J, K, L, M, N> {
    public let _0: A
    public let _1: B
    public let _2: C
    public let _3: D
    public let _4: E
    public let _5: F
    public let _6: G
    public let _7: H
    public let _8: I
    public let _9: J
    public let _10: K
    public let _11: L
    public let _12: M
    public let _13: N

    @inlinable
    @_alwaysEmitIntoClient
    public init(
        _ _0: A,
        _ _1: B,
        _ _2: C,
        _ _3: D,
        _ _4: E,
        _ _5: F,
        _ _6: G,
        _ _7: H,
        _ _8: I,
        _ _9: J,
        _ _10: K,
        _ _11: L,
        _ _12: M,
        _ _13: N
    ) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
        self._3 = _3
        self._4 = _4
        self._5 = _5
        self._6 = _6
        self._7 = _7
        self._8 = _8
        self._9 = _9
        self._10 = _10
        self._11 = _11
        self._12 = _12
        self._13 = _13
    }
}

extension T14: Generic where A: Generic, B: Generic, C: Generic, D: Generic, E: Generic, F: Generic, G: Generic, H: Generic,
    I: Generic, J: Generic, K: Generic, L: Generic, M: Generic, N: Generic
{
    public typealias RawRepresentation = T2<T8<A, B, C, D, E, F, G, H>, T6<I, J, K, L, M, N>>.RawRepresentation

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Self.RawRepresentation {
        T2(T8(_0, _1, _2, _3, _4, _5, _6, _7), T6(_8, _9, _10, _11, _12, _13)).rawRepresentation
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = T14(
            A(from: rep._0._0._0._0),
            B(from: rep._0._0._0._1),
            C(from: rep._0._0._1._0),
            D(from: rep._0._0._1._1),
            E(from: rep._0._1._0._0),
            F(from: rep._0._1._0._1),
            G(from: rep._0._1._1._0),
            H(from: rep._0._1._1._1),
            I(from: rep._1._0._0._0),
            J(from: rep._1._0._0._1),
            K(from: rep._1._0._1._0),
            L(from: rep._1._0._1._1),
            M(from: rep._1._1._0),
            N(from: rep._1._1._1)
        )
    }
}

public struct T15<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O> {
    public let _0: A
    public let _1: B
    public let _2: C
    public let _3: D
    public let _4: E
    public let _5: F
    public let _6: G
    public let _7: H
    public let _8: I
    public let _9: J
    public let _10: K
    public let _11: L
    public let _12: M
    public let _13: N
    public let _14: O

    @inlinable
    @_alwaysEmitIntoClient
    public init(
        _ _0: A,
        _ _1: B,
        _ _2: C,
        _ _3: D,
        _ _4: E,
        _ _5: F,
        _ _6: G,
        _ _7: H,
        _ _8: I,
        _ _9: J,
        _ _10: K,
        _ _11: L,
        _ _12: M,
        _ _13: N,
        _ _14: O
    ) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
        self._3 = _3
        self._4 = _4
        self._5 = _5
        self._6 = _6
        self._7 = _7
        self._8 = _8
        self._9 = _9
        self._10 = _10
        self._11 = _11
        self._12 = _12
        self._13 = _13
        self._14 = _14
    }
}

extension T15: Generic where A: Generic, B: Generic, C: Generic, D: Generic, E: Generic, F: Generic, G: Generic, H: Generic,
    I: Generic, J: Generic, K: Generic, L: Generic, M: Generic, N: Generic, O: Generic
{
    public typealias RawRepresentation = T2<T8<A, B, C, D, E, F, G, H>, T7<I, J, K, L, M, N, O>>.RawRepresentation

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Self.RawRepresentation {
        T2(T8(_0, _1, _2, _3, _4, _5, _6, _7), T7(_8, _9, _10, _11, _12, _13, _14)).rawRepresentation
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = T15(
            A(from: rep._0._0._0._0),
            B(from: rep._0._0._0._1),
            C(from: rep._0._0._1._0),
            D(from: rep._0._0._1._1),
            E(from: rep._0._1._0._0),
            F(from: rep._0._1._0._1),
            G(from: rep._0._1._1._0),
            H(from: rep._0._1._1._1),
            I(from: rep._1._0._0._0),
            J(from: rep._1._0._0._1),
            K(from: rep._1._0._1._0),
            L(from: rep._1._0._1._1),
            M(from: rep._1._1._0._0),
            N(from: rep._1._1._0._1),
            O(from: rep._1._1._1)
        )
    }
}

public struct T16<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P> {
    public let _0: A
    public let _1: B
    public let _2: C
    public let _3: D
    public let _4: E
    public let _5: F
    public let _6: G
    public let _7: H
    public let _8: I
    public let _9: J
    public let _10: K
    public let _11: L
    public let _12: M
    public let _13: N
    public let _14: O
    public let _15: P

    @inlinable
    @_alwaysEmitIntoClient
    public init(
        _ _0: A,
        _ _1: B,
        _ _2: C,
        _ _3: D,
        _ _4: E,
        _ _5: F,
        _ _6: G,
        _ _7: H,
        _ _8: I,
        _ _9: J,
        _ _10: K,
        _ _11: L,
        _ _12: M,
        _ _13: N,
        _ _14: O,
        _ _15: P
    ) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
        self._3 = _3
        self._4 = _4
        self._5 = _5
        self._6 = _6
        self._7 = _7
        self._8 = _8
        self._9 = _9
        self._10 = _10
        self._11 = _11
        self._12 = _12
        self._13 = _13
        self._14 = _14
        self._15 = _15
    }
}

extension T16: Generic where A: Generic, B: Generic, C: Generic, D: Generic, E: Generic, F: Generic, G: Generic, H: Generic,
    I: Generic, J: Generic, K: Generic, L: Generic, M: Generic, N: Generic, O: Generic, P: Generic
{
    public typealias RawRepresentation = T2<T8<A, B, C, D, E, F, G, H>, T8<I, J, K, L, M, N, O, P>>.RawRepresentation

    @inlinable
    @_alwaysEmitIntoClient
    public var rawRepresentation: Self.RawRepresentation {
        T2(T8(_0, _1, _2, _3, _4, _5, _6, _7), T8(_8, _9, _10, _11, _12, _13, _14, _15)).rawRepresentation
    }

    @inlinable
    @_alwaysEmitIntoClient
    public init(from rep: RawRepresentation) {
        self = T16(
            A(from: rep._0._0._0._0),
            B(from: rep._0._0._0._1),
            C(from: rep._0._0._1._0),
            D(from: rep._0._0._1._1),
            E(from: rep._0._1._0._0),
            F(from: rep._0._1._0._1),
            G(from: rep._0._1._1._0),
            H(from: rep._0._1._1._1),
            I(from: rep._1._0._0._0),
            J(from: rep._1._0._0._1),
            K(from: rep._1._0._1._0),
            L(from: rep._1._0._1._1),
            M(from: rep._1._1._0._0),
            N(from: rep._1._1._0._1),
            O(from: rep._1._1._1._0),
            P(from: rep._1._1._1._1)
        )
    }
}
