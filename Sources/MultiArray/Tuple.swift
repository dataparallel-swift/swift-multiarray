// Copyright (c) 2025 PassiveLogic, Inc.

// swiftlint:disable identifier_name

public struct T2<A, B> {
    public let _0: A
    public let _1: B
    @inlinable @inline(__always)
    public init(_ _0: A, _ _1: B) {
        self._0 = _0
        self._1 = _1
    }
}

extension T2: Generic where A: Generic, B: Generic {
    public typealias Rep = Product<A, B>.Rep
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep {
        Product(
            A.from(x._0),
            B.from(x._1)
        )
    }

    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self {
        T2(
            A.to(x._0),
            B.to(x._1)
        )
    }
}

public struct T3<A, B, C> {
    public let _0: A
    public let _1: B
    public let _2: C
    @inlinable @inline(__always) public init(_ _0: A, _ _1: B, _ _2: C) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
    }
}

extension T3: Generic where A: Generic, B: Generic, C: Generic {
    public typealias Rep = T2<T2<A, B>, C>.Rep
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep {
        T2.from(T2(T2(x._0, x._1), x._2))
    }

    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self {
        T3(
            A.to(x._0._0),
            B.to(x._0._1),
            C.to(x._1)
        )
    }
}

public struct T4<A, B, C, D> {
    public let _0: A
    public let _1: B
    public let _2: C
    public let _3: D
    @inlinable @inline(__always) public init(_ _0: A, _ _1: B, _ _2: C, _ _3: D) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
        self._3 = _3
    }
}

extension T4: Generic where A: Generic, B: Generic, C: Generic, D: Generic {
    public typealias Rep = T2<T2<A, B>, T2<C, D>>.Rep
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep {
        T2.from(T2(T2(x._0, x._1), T2(x._2, x._3)))
    }

    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self {
        T4(
            A.to(x._0._0),
            B.to(x._0._1),
            C.to(x._1._0),
            D.to(x._1._1)
        )
    }
}

public struct T5<A, B, C, D, E> {
    public let _0: A
    public let _1: B
    public let _2: C
    public let _3: D
    public let _4: E
    @inlinable @inline(__always) public init(_ _0: A, _ _1: B, _ _2: C, _ _3: D, _ _4: E) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
        self._3 = _3
        self._4 = _4
    }
}

extension T5: Generic where A: Generic, B: Generic, C: Generic, D: Generic, E: Generic {
    public typealias Rep = T2<T4<A, B, C, D>, E>.Rep
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep {
        T2.from(T2(T4(x._0, x._1, x._2, x._3), x._4))
    }

    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self {
        T5(
            A.to(x._0._0._0),
            B.to(x._0._0._1),
            C.to(x._0._1._0),
            D.to(x._0._1._1),
            E.to(x._1)
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
    @inlinable @inline(__always) public init(_ _0: A, _ _1: B, _ _2: C, _ _3: D, _ _4: E, _ _5: F) {
        self._0 = _0
        self._1 = _1
        self._2 = _2
        self._3 = _3
        self._4 = _4
        self._5 = _5
    }
}

extension T6: Generic where A: Generic, B: Generic, C: Generic, D: Generic, E: Generic, F: Generic {
    public typealias Rep = T2<T4<A, B, C, D>, T2<E, F>>.Rep
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep {
        T2.from(T2(T4(x._0, x._1, x._2, x._3), T2(x._4, x._5)))
    }

    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self {
        T6(
            A.to(x._0._0._0),
            B.to(x._0._0._1),
            C.to(x._0._1._0),
            D.to(x._0._1._1),
            E.to(x._1._0),
            F.to(x._1._1)
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
    @inlinable @inline(__always) public init(_ _0: A, _ _1: B, _ _2: C, _ _3: D, _ _4: E, _ _5: F, _ _6: G) {
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
    public typealias Rep = T2<T4<A, B, C, D>, T3<E, F, G>>.Rep
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep {
        T2.from(T2(T4(x._0, x._1, x._2, x._3), T3(x._4, x._5, x._6)))
    }

    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self {
        T7(
            A.to(x._0._0._0),
            B.to(x._0._0._1),
            C.to(x._0._1._0),
            D.to(x._0._1._1),
            E.to(x._1._0._0),
            F.to(x._1._0._1),
            G.to(x._1._1)
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
    @inlinable @inline(__always) public init(_ _0: A, _ _1: B, _ _2: C, _ _3: D, _ _4: E, _ _5: F, _ _6: G, _ _7: H) {
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
    public typealias Rep = T2<T4<A, B, C, D>, T4<E, F, G, H>>.Rep
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep {
        T2.from(T2(T4(x._0, x._1, x._2, x._3), T4(x._4, x._5, x._6, x._7)))
    }

    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self {
        T8(
            A.to(x._0._0._0),
            B.to(x._0._0._1),
            C.to(x._0._1._0),
            D.to(x._0._1._1),
            E.to(x._1._0._0),
            F.to(x._1._0._1),
            G.to(x._1._1._0),
            H.to(x._1._1._1)
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
    @inlinable @inline(__always) public init(_ _0: A, _ _1: B, _ _2: C, _ _3: D, _ _4: E, _ _5: F, _ _6: G, _ _7: H, _ _8: I) {
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
    public typealias Rep = T2<T8<A, B, C, D, E, F, G, H>, I>.Rep
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep {
        T2.from(T2(T8(x._0, x._1, x._2, x._3, x._4, x._5, x._6, x._7), x._8))
    }

    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self {
        T9(
            A.to(x._0._0._0._0),
            B.to(x._0._0._0._1),
            C.to(x._0._0._1._0),
            D.to(x._0._0._1._1),
            E.to(x._0._1._0._0),
            F.to(x._0._1._0._1),
            G.to(x._0._1._1._0),
            H.to(x._0._1._1._1),
            I.to(x._1)
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
    @inlinable @inline(__always) public init(_ _0: A, _ _1: B, _ _2: C, _ _3: D, _ _4: E, _ _5: F, _ _6: G, _ _7: H, _ _8: I, _ _9: J) {
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
    public typealias Rep = T2<T8<A, B, C, D, E, F, G, H>, T2<I, J>>.Rep
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep {
        T2.from(T2(T8(x._0, x._1, x._2, x._3, x._4, x._5, x._6, x._7), T2(x._8, x._9)))
    }

    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self {
        T10(
            A.to(x._0._0._0._0),
            B.to(x._0._0._0._1),
            C.to(x._0._0._1._0),
            D.to(x._0._0._1._1),
            E.to(x._0._1._0._0),
            F.to(x._0._1._0._1),
            G.to(x._0._1._1._0),
            H.to(x._0._1._1._1),
            I.to(x._1._0),
            J.to(x._1._1)
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
    @inlinable @inline(__always) public init(
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
    public typealias Rep = T2<T8<A, B, C, D, E, F, G, H>, T3<I, J, K>>.Rep
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep {
        T2.from(T2(T8(x._0, x._1, x._2, x._3, x._4, x._5, x._6, x._7), T3(x._8, x._9, x._10)))
    }

    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self {
        T11(
            A.to(x._0._0._0._0),
            B.to(x._0._0._0._1),
            C.to(x._0._0._1._0),
            D.to(x._0._0._1._1),
            E.to(x._0._1._0._0),
            F.to(x._0._1._0._1),
            G.to(x._0._1._1._0),
            H.to(x._0._1._1._1),
            I.to(x._1._0._0),
            J.to(x._1._0._1),
            K.to(x._1._1)
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
    @inlinable @inline(__always) public init(
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
    public typealias Rep = T2<T8<A, B, C, D, E, F, G, H>, T4<I, J, K, L>>.Rep
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep {
        T2.from(T2(T8(x._0, x._1, x._2, x._3, x._4, x._5, x._6, x._7), T4(x._8, x._9, x._10, x._11)))
    }

    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self {
        T12(
            A.to(x._0._0._0._0),
            B.to(x._0._0._0._1),
            C.to(x._0._0._1._0),
            D.to(x._0._0._1._1),
            E.to(x._0._1._0._0),
            F.to(x._0._1._0._1),
            G.to(x._0._1._1._0),
            H.to(x._0._1._1._1),
            I.to(x._1._0._0),
            J.to(x._1._0._1),
            K.to(x._1._1._0),
            L.to(x._1._1._1)
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
    @inlinable @inline(__always) public init(
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
    public typealias Rep = T2<T8<A, B, C, D, E, F, G, H>, T5<I, J, K, L, M>>.Rep
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep {
        T2.from(T2(T8(x._0, x._1, x._2, x._3, x._4, x._5, x._6, x._7), T5(x._8, x._9, x._10, x._11, x._12)))
    }

    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self {
        T13(
            A.to(x._0._0._0._0),
            B.to(x._0._0._0._1),
            C.to(x._0._0._1._0),
            D.to(x._0._0._1._1),
            E.to(x._0._1._0._0),
            F.to(x._0._1._0._1),
            G.to(x._0._1._1._0),
            H.to(x._0._1._1._1),
            I.to(x._1._0._0._0),
            J.to(x._1._0._0._1),
            K.to(x._1._0._1._0),
            L.to(x._1._0._1._1),
            M.to(x._1._1)
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
    @inlinable @inline(__always) public init(
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
    public typealias Rep = T2<T8<A, B, C, D, E, F, G, H>, T6<I, J, K, L, M, N>>.Rep
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep {
        T2.from(T2(T8(x._0, x._1, x._2, x._3, x._4, x._5, x._6, x._7), T6(x._8, x._9, x._10, x._11, x._12, x._13)))
    }

    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self {
        T14(
            A.to(x._0._0._0._0),
            B.to(x._0._0._0._1),
            C.to(x._0._0._1._0),
            D.to(x._0._0._1._1),
            E.to(x._0._1._0._0),
            F.to(x._0._1._0._1),
            G.to(x._0._1._1._0),
            H.to(x._0._1._1._1),
            I.to(x._1._0._0._0),
            J.to(x._1._0._0._1),
            K.to(x._1._0._1._0),
            L.to(x._1._0._1._1),
            M.to(x._1._1._0),
            N.to(x._1._1._1)
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
    @inlinable @inline(__always) public init(
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
    public typealias Rep = T2<T8<A, B, C, D, E, F, G, H>, T7<I, J, K, L, M, N, O>>.Rep
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep {
        T2.from(T2(T8(x._0, x._1, x._2, x._3, x._4, x._5, x._6, x._7), T7(x._8, x._9, x._10, x._11, x._12, x._13, x._14)))
    }

    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self {
        T15(
            A.to(x._0._0._0._0),
            B.to(x._0._0._0._1),
            C.to(x._0._0._1._0),
            D.to(x._0._0._1._1),
            E.to(x._0._1._0._0),
            F.to(x._0._1._0._1),
            G.to(x._0._1._1._0),
            H.to(x._0._1._1._1),
            I.to(x._1._0._0._0),
            J.to(x._1._0._0._1),
            K.to(x._1._0._1._0),
            L.to(x._1._0._1._1),
            M.to(x._1._1._0._0),
            N.to(x._1._1._0._1),
            O.to(x._1._1._1)
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
    @inlinable @inline(__always) public init(
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
    public typealias Rep = T2<T8<A, B, C, D, E, F, G, H>, T8<I, J, K, L, M, N, O, P>>.Rep
    @inlinable @inline(__always) public static func from(_ x: Self) -> Self.Rep {
        T2.from(T2(T8(x._0, x._1, x._2, x._3, x._4, x._5, x._6, x._7), T8(x._8, x._9, x._10, x._11, x._12, x._13, x._14, x._15)))
    }

    @inlinable @inline(__always) public static func to(_ x: Self.Rep) -> Self {
        T16(
            A.to(x._0._0._0._0),
            B.to(x._0._0._0._1),
            C.to(x._0._0._1._0),
            D.to(x._0._0._1._1),
            E.to(x._0._1._0._0),
            F.to(x._0._1._0._1),
            G.to(x._0._1._1._0),
            H.to(x._0._1._1._1),
            I.to(x._1._0._0._0),
            J.to(x._1._0._0._1),
            K.to(x._1._0._1._0),
            L.to(x._1._0._1._1),
            M.to(x._1._1._0._0),
            N.to(x._1._1._0._1),
            O.to(x._1._1._1._0),
            P.to(x._1._1._1._1)
        )
    }
}
