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
import MultiArray
import Testing

@Suite
struct GenericMacroTests {
    // MARK: - Raw-value enum

    @Test
    func macroRawValueEnumRoundtrip() throws {
        let original: MultiArray<MacroStatus> = [.off, .on, .off]
        let encoded = original.encode()
        let decoded = try MultiArray<MacroStatus>(data: encoded)
        #expect(decoded == original)
    }

    @Test
    func macroRawValueEnumRejectsInvalidValue() throws {
        let encoded = MultiArray<UInt8>([2]).encode()

        #expect(throws: BinaryMultiArrayError.invalidRawRepresentation(index: 0)) {
            _ = try MultiArray<MacroStatus>(data: encoded)
        }
    }

    // MARK: - Empty struct (Unit)

    @Test
    func macroEmptyRoundtrip() {
        let array: [MacroEmpty] = [.init(), .init(), .init()]
        let ma = MultiArray(array)
        let roundtrip = Array(ma)
        #expect(roundtrip == array)
    }

    @Test
    func macroEmptyRawRepresentation() {
        let empty = MacroEmpty()
        let rep = empty.rawRepresentation
        let restored = MacroEmpty(from: rep)
        #expect(restored == empty)
    }

    // MARK: - Single property (N=1)

    @Test
    func macroWrapperRoundtrip() {
        let array: [MacroWrapper] = [
            .init(value: 100),
            .init(value: 200),
            .init(value: -300),
        ]
        let ma = MultiArray(array)
        let roundtrip = Array(ma)
        #expect(roundtrip == array)
    }

    // MARK: - 2-property struct

    @Test
    func macroPointRoundtrip() {
        let array: [MacroPoint] = [
            .init(x: 1.0, y: 2.0),
            .init(x: 3.0, y: 4.0),
            .init(x: -5.0, y: 6.0),
        ]
        let ma = MultiArray(array)
        let roundtrip = Array(ma)
        #expect(roundtrip == array)
    }

    @Test
    func macroPointRawRepresentation() {
        let point = MacroPoint(x: 1.0, y: 2.0)
        let rep = point.rawRepresentation
        let restored = MacroPoint(from: rep)
        #expect(restored == point)
    }

    // MARK: - 3-property generic struct

    @Test
    func macroVec3FloatRoundtrip() {
        let array: [MacroVec3<Float>] = [
            .init(x: 1, y: 2, z: 3),
            .init(x: 4, y: 5, z: 6),
        ]
        let ma = MultiArray(array)
        let roundtrip = Array(ma)
        #expect(roundtrip == array)
    }

    @Test
    func macroVec3IntRoundtrip() {
        let array: [MacroVec3<Int32>] = [
            .init(x: 10, y: 20, z: 30),
            .init(x: 40, y: 50, z: 60),
        ]
        let ma = MultiArray(array)
        let roundtrip = Array(ma)
        #expect(roundtrip == array)
    }

    // MARK: - Nested Generic types

    @Test
    func macroZoneRoundtrip() {
        let array: [MacroZone] = [
            .init(id: 0, position: .init(x: -1, y: 12, z: 0)),
            .init(id: 1, position: .init(x: 3.5, y: 4.5, z: 5.5)),
        ]
        let ma = MultiArray(array)
        let roundtrip = Array(ma)
        #expect(roundtrip == array)
    }

    // MARK: - Bool field

    @Test
    func macroFlaggedPointRoundtrip() {
        let array: [MacroFlaggedPoint] = [
            .init(active: true, x: 1.0, y: 2.0),
            .init(active: false, x: 3.0, y: 4.0),
        ]
        let ma = MultiArray(array)
        let roundtrip = Array(ma)
        #expect(roundtrip == array)
    }

    // MARK: - 4-property struct (T4)

    @Test
    func macroQuadRoundtrip() {
        let array: [MacroQuad] = [
            .init(a: 1, b: 2, c: 3, d: 4),
            .init(a: 5, b: 6, c: 7, d: 8),
        ]
        let ma = MultiArray(array)
        let roundtrip = Array(ma)
        #expect(roundtrip == array)
    }

    // MARK: - Binary roundtrip

    @Test
    func macroEmptyBinaryRoundtrip() throws {
        let original: MultiArray<MacroEmpty> = [.init(), .init()]
        let encoded = original.encode()
        let decoded = try MultiArray<MacroEmpty>(data: encoded)
        #expect(decoded == original)
    }

    @Test
    func macroPointBinaryRoundtrip() throws {
        let original: MultiArray<MacroPoint> = [
            .init(x: 1.0, y: 2.0),
            .init(x: 3.0, y: 4.0),
        ]
        let encoded = original.encode()
        let decoded = try MultiArray<MacroPoint>(data: encoded)
        #expect(decoded == original)
    }

    @Test
    func macroZoneBinaryRoundtrip() throws {
        let original: MultiArray<MacroZone> = [
            .init(id: 42, position: .init(x: 1, y: 2, z: 3)),
        ]
        let encoded = original.encode()
        let decoded = try MultiArray<MacroZone>(data: encoded)
        #expect(decoded == original)
    }

    // MARK: - Empty array

    @Test
    func macroEmptyArray() {
        let ma = MultiArray<MacroPoint>()
        #expect(ma.count == 0)
        #expect(Array(ma).isEmpty)
    }

    // MARK: - Mutation

    @Test
    func macroPointMutation() {
        var ma: MultiArray<MacroPoint> = [
            .init(x: 1.0, y: 2.0),
            .init(x: 3.0, y: 4.0),
        ]
        ma[0] = .init(x: 99.0, y: 88.0)
        #expect(ma[0].x == 99.0)
        #expect(ma[0].y == 88.0)
        #expect(ma[1].x == 3.0)
    }

    // MARK: - Internal access level

    @Test
    func macroInternalRoundtrip() {
        let array: [MacroInternal] = [
            .init(x: 1.0, y: 2.0),
            .init(x: 3.0, y: 4.0),
        ]
        let ma = MultiArray(array)
        let roundtrip = Array(ma)
        #expect(roundtrip == array)
    }

    @Test
    func macroPublicSynthesizedMemberwiseInitializer() {
        let value = MacroPublicSynthesized(x: 1.0, y: 2.0)
        #expect(MacroPublicSynthesized(from: value.rawRepresentation) == value)
    }

    @Test
    func macroPublicEncapsulatedRoundtrip() {
        let value = MacroPublicEncapsulated(internalValue: 1.5, privateValue: 42)
        #expect(MacroPublicEncapsulated(from: value.rawRepresentation) == value)
    }

    @Test
    func macroPrivateRoundtrip() {
        #expect(privateMacroRoundtrips())
    }

    @Test
    func macroNestedFileprivateRoundtrip() {
        #expect(nestedFileprivateMacroRoundtrips())
    }

    // MARK: - Package access level

    @Test
    func macroPackageRoundtrip() {
        let array: [MacroPackage] = [
            .init(x: 1.0, y: 2.0),
            .init(x: 3.0, y: 4.0),
        ]
        let ma = MultiArray(array)
        let roundtrip = Array(ma)
        #expect(roundtrip == array)
    }

    @Test
    func macroPackageRawRepresentation() {
        let v = MacroPackage(x: 1.0, y: 2.0)
        let rep = v.rawRepresentation
        let restored = MacroPackage(from: rep)
        #expect(restored == v)
    }

    // MARK: - Box<T> fields for non-Generic types

    @Test
    func macroLabeledRoundtrip() {
        let array: [MacroLabeled] = [
            .init(label: "hello", value: 1.0),
            .init(label: "world", value: 2.0),
        ]
        let ma = MultiArray(array)
        let roundtrip = Array(ma)
        #expect(roundtrip == array)
    }

    @Test
    func macroLabeledRawRepresentation() {
        let v = MacroLabeled(label: "test", value: 42.0)
        let restored = MacroLabeled(from: v.rawRepresentation)
        #expect(restored == v)
    }

    // MARK: - @Box property macro

    @Test
    func macroLabeledComputedRoundtrip() {
        let array: [MacroLabeledComputed] = [
            .init(label: "hello", value: 1.0),
            .init(label: "world", value: 2.0),
        ]
        let ma = MultiArray(array)
        let roundtrip = Array(ma)
        #expect(roundtrip == array)
    }

    @Test
    func macroLabeledComputedAccessor() {
        var v = MacroLabeledComputed(label: "original", value: 1.0)
        #expect(v.label == "original")
        v.label = "updated"
        #expect(v.label == "updated")
    }

    @Test
    func macroLabeledComputedRawRepresentation() {
        let v = MacroLabeledComputed(label: "test", value: 42.0)
        let restored = MacroLabeledComputed(from: v.rawRepresentation)
        #expect(restored == v)
    }

    @Test
    func macroLabeledDefaultedAccessor() {
        var value = MacroLabeledDefaulted()
        #expect(value.label == "guest")
        #expect(value.value == 1.0)
        value.label = "updated"
        #expect(value.label == "updated")
    }

    @Test
    func macroLabeledDefaultedRoundtrip() {
        var second = MacroLabeledDefaulted()
        second.label = "custom"
        second.value = 2.0

        let array: [MacroLabeledDefaulted] = [
            .init(),
            second,
        ]
        let ma = MultiArray(array)
        let roundtrip = Array(ma)
        #expect(roundtrip == array)
    }

    @Test
    func macroDefaultedPackageAccessor() {
        var value = MacroDefaultedPackage()
        #expect(value.label == "guest")
        #expect(value.value == 1.0)
        value.label = "updated"
        #expect(value.label == "updated")
    }

    // MARK: - Computed properties excluded from encoding

    @Test
    func macroWithComputedRoundtrip() {
        let array: [MacroWithComputed] = [
            .init(x: 3.0, y: 4.0),
            .init(x: 1.0, y: 0.0),
        ]
        let ma = MultiArray(array)
        let roundtrip = Array(ma)
        #expect(roundtrip == array)
        #expect(roundtrip[0].magnitude == array[0].magnitude)
    }

    // MARK: - More than 16 stored properties

    @Test
    func macroWide17Roundtrip() {
        let array: [MacroWide17] = [
            .init(Array(0 ..< 17).map(Int8.init)),
            .init(Array(17 ..< 34).map(Int8.init)),
        ]
        let ma = MultiArray(array)
        let roundtrip = Array(ma)
        #expect(roundtrip == array)
    }

    @Test
    func macroWide17RawRepresentation() {
        let value = MacroWide17(Array(0 ..< 17).map(Int8.init))
        let restored = MacroWide17(from: value.rawRepresentation)
        #expect(restored == value)
    }

    // MARK: - Private backing store + computed accessor

    @Test
    func macroBackedFieldRoundtrip() {
        let array: [MacroBackedField] = [
            .init(value: 1.5, tag: 10),
            .init(value: 2.5, tag: 20),
        ]
        let ma = MultiArray(array)
        let roundtrip = Array(ma)
        #expect(roundtrip == array)
        #expect(roundtrip[0].tag == 10)
        #expect(roundtrip[1].tag == 20)
    }
}
