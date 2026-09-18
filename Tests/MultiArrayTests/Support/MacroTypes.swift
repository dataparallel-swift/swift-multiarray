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

// Test empty struct (uses Unit)
@Generic
public struct MacroEmpty: Equatable {
    public init() {}
}

// Test struct with single property
@Generic
public struct MacroWrapper: Equatable {
    public let value: Int32

    public init(value: Int32) {
        self.value = value
    }
}

// Test struct with 2 properties
@Generic
public struct MacroPoint: Equatable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

// Test struct with 3 properties including Bool
@Generic
public struct MacroFlaggedPoint: Equatable {
    public let active: Bool
    public let x: Double
    public let y: Double

    public init(active: Bool, x: Double, y: Double) {
        self.active = active
        self.x = x
        self.y = y
    }
}

// Test struct with 4 properties
@Generic
public struct MacroQuad: Equatable {
    public let a: Float
    public let b: Float
    public let c: Float
    public let d: Float

    public init(a: Float, b: Float, c: Float, d: Float) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
    }
}

// Generic structs: the macro emits the complete conformance extension without copying the
// declaration's where clause. Swift resolves the constraints from the struct declaration.
@Generic
public struct MacroVec3<Element>: Equatable where Element: Equatable & Generic {
    public let x: Element
    public let y: Element
    public let z: Element

    public init(x: Element, y: Element, z: Element) {
        self.x = x
        self.y = y
        self.z = z
    }
}

// Test struct with nested Generic types
@Generic
public struct MacroZone: Equatable {
    public let id: Int8
    public let position: MacroVec3<Float>

    public init(id: Int8, position: MacroVec3<Float>) {
        self.id = id
        self.position = position
    }
}

// Test internal access level (default, no keyword)
@Generic
struct MacroInternal: Equatable {
    var x: Double
    var y: Double
}

// Test that a public declaration retains its internal synthesized memberwise initializer.
@Generic
public struct MacroPublicSynthesized: Equatable {
    public var x: Double
    public var y: Double
}

// Public Generic witnesses must remain valid when representation fields are
// intentionally hidden from clients of the module.
@Generic
public struct MacroPublicEncapsulated: Equatable {
    let internalValue: Double
    private let privateValue: Int32

    public init(internalValue: Double, privateValue: Int32) {
        self.internalValue = internalValue
        self.privateValue = privateValue
    }
}

// Test private access level. Protocol witnesses for a private type must be fileprivate.
@Generic
private struct MacroPrivate: Equatable {
    var value: Int32
}

func privateMacroRoundtrips() -> Bool {
    let value = MacroPrivate(value: 42)
    return MacroPrivate(from: value.rawRepresentation) == value
}

private enum MacroNestedContainer {
    @Generic
    fileprivate struct Value: Equatable {
        var value: Int32
    }

    static func roundtrips() -> Bool {
        let value = Value(value: 42)
        return Value(from: value.rawRepresentation) == value
    }
}

func nestedFileprivateMacroRoundtrips() -> Bool {
    MacroNestedContainer.roundtrips()
}

// Test package access level
@Generic
package struct MacroPackage: Equatable {
    package var x: Double
    package var y: Double

    package init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

// Test struct with Box<T> fields wrapping non-Generic types (e.g. String)
@Generic
public struct MacroLabeled: Equatable {
    public let label: Box<String>
    public let value: Float

    public init(label: String, value: Float) {
        self.label = Box(label)
        self.value = value
    }
}

// Test @Box property macro on var: get+set accessor, var backing store.
// For immutable boxed fields, write `let label: Box<String>` explicitly (see MacroLabeled).
// Swift does not allow @attached(accessor) on let declarations.
@Generic
public struct MacroLabeledComputed: Equatable {
    @Box public var label: String
    public let value: Float

    public init(label: String, value: Float) {
        self._label = Box(label)
        self.value = value
    }
}

// Test @Box property macro with default values.
@Generic
public struct MacroLabeledDefaulted: Equatable {
    @Box public var label: String = "guest"
    public var value: Float = 1.0

    public init() {}
}

// Test package access level + default value on @Box property.
@Generic
package struct MacroDefaultedPackage: Equatable {
    @Box package var label: String = "guest"
    package var value: Float = 1.0

    package init() {}
}

// Test that computed properties are excluded; only stored fields are encoded.
// Equivalent to the pattern where a backing _field is stored and a computed
// property provides a typed view of it.
@Generic
public struct MacroWithComputed: Equatable {
    public let x: Float
    public let y: Float
    public var magnitude: Float { (x * x + y * y).squareRoot() }

    public init(x: Float, y: Float) {
        self.x = x
        self.y = y
    }
}

// Test struct with more than 16 properties. The macro should build nested
// Product trees directly rather than relying on fixed-arity tuple helpers.
@Generic
public struct MacroWide17: Equatable {
    public let p00: Int8
    public let p01: Int8
    public let p02: Int8
    public let p03: Int8
    public let p04: Int8
    public let p05: Int8
    public let p06: Int8
    public let p07: Int8
    public let p08: Int8
    public let p09: Int8
    public let p10: Int8
    public let p11: Int8
    public let p12: Int8
    public let p13: Int8
    public let p14: Int8
    public let p15: Int8
    public let p16: Int8

    public init(_ values: [Int8]) {
        precondition(values.count == 17)
        self.p00 = values[0]
        self.p01 = values[1]
        self.p02 = values[2]
        self.p03 = values[3]
        self.p04 = values[4]
        self.p05 = values[5]
        self.p06 = values[6]
        self.p07 = values[7]
        self.p08 = values[8]
        self.p09 = values[9]
        self.p10 = values[10]
        self.p11 = values[11]
        self.p12 = values[12]
        self.p13 = values[13]
        self.p14 = values[14]
        self.p15 = values[15]
        self.p16 = values[16]
    }
}

// Test struct with private backing store + computed accessor (common when
// the logical type isn't Generic but its raw representation is)
@Generic
public struct MacroBackedField: Equatable {
    public var value: Float
    @usableFromInline var _tag: UInt8 // must be @usableFromInline so @inlinable init(from:) can set it
    public var tag: UInt8 { // computed view — should be excluded from encoding
        get { _tag }
        set { _tag = newValue }
    }

    public init(value: Float, tag: UInt8) {
        self.value = value
        self._tag = tag
    }
}
