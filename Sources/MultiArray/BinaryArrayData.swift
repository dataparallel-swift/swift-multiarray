// Copyright (c) 2025 The swift-multiarray authors. All rights reserved.
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

// The subset of ArrayData types that are safe to serialise as raw bytes. By
// "safe" we mean:
//  - no heap pointers / references embedded in the representation (i.e. no Box)
//  - the representation's byte layout is fully determined by the type
//  - data written is deterministic (padding bytes included)
public protocol BinaryArrayData: ArrayData {}

// Primal types. MemoryLayout<T>.size == MemoryLayout<T>.stride
extension Int: BinaryArrayData {}
extension Int8: BinaryArrayData {}
extension Int16: BinaryArrayData {}
extension Int32: BinaryArrayData {}
extension Int64: BinaryArrayData {}
@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
extension Int128: BinaryArrayData {}
extension UInt: BinaryArrayData {}
extension UInt8: BinaryArrayData {}
extension UInt16: BinaryArrayData {}
extension UInt32: BinaryArrayData {}
extension UInt64: BinaryArrayData {}
@available(macOS 15.0, iOS 18.0, tvOS 18.0, watchOS 11.0, *)
extension UInt128: BinaryArrayData {}
#if arch(arm64)
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension Float16: BinaryArrayData {}
#endif
extension Float32: BinaryArrayData {}
extension Float64: BinaryArrayData {}

extension SIMD2: BinaryArrayData {}
extension SIMD3: BinaryArrayData {}
extension SIMD4: BinaryArrayData {}
extension SIMD8: BinaryArrayData {}
extension SIMD16: BinaryArrayData {}
extension SIMD32: BinaryArrayData {}
extension SIMD64: BinaryArrayData {}

// Datatype-generic markers
extension Unit: BinaryArrayData {}
// extension Box -- not allowed; may include pointers, etc.
extension Product: BinaryArrayData where A: BinaryArrayData, B: BinaryArrayData {}
