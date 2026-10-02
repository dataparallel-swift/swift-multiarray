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

public extension MultiArray where Element.RawRepresentation: PartialInitializationArrayData {
    /// Creates an array by initializing a prefix of its storage asynchronously.
    ///
    /// The body receives the uninitialized capacity and an `inout` count starting
    /// at zero. On success, initialize each index in `0..<initializedCount`
    /// exactly once, in any order, and no slots outside it. The array publishes
    /// that prefix without moving elements or reducing allocation capacity.
    ///
    /// When both `Element` and its raw representation are `Sendable`, child
    /// tasks may initialize distinct indices concurrently, with one writer per
    /// index. Join all child work before returning or throwing, including after
    /// cancellation or child failure. Update the count only in the parent after
    /// joining; child tasks must not concurrently access it. The view must not
    /// escape or remain in use afterward. Same-index races and escaped use are
    /// undefined behavior.
    ///
    /// The reported count must be between zero and capacity, inclusive;
    /// otherwise, the initializer traps on success or throw. Failure destroys
    /// initialized tracked slots, independently of the reported count, and
    /// rethrows the body's typed error; scattered writes need not form a prefix.
    /// Cancellation takes effect only when the body observes it and throws.
    ///
    /// In debug builds, tracked duplicate writes, missing prefix slots, and
    /// initialized slots outside the reported prefix trigger assertions when
    /// there is no race. Release builds and representations without tracking
    /// rely on the caller to uphold the initialization contract.
    /// See <doc:ConstructingArrays> for examples.
    ///
    /// - Parameters:
    ///   - count: The maximum number of elements that can be initialized.
    ///   - body: A closure that initializes storage and reports the prefix length.
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 9, *)
    init<Failure: Error>(
        unsafeUninitializedCapacity count: Int,
        initializingWith body: sending(UnsafeUninitializedMultiArrayBuffer<Element>, inout Int) async throws(Failure) -> Void
    ) async throws(Failure) {
        let owner = ScatteredInitializationOwner<Element>(capacity: count)
        var initializedCount = 0
        defer { withExtendedLifetime(owner) {} }
        do {
            defer {
                precondition(
                    initializedCount >= 0 && initializedCount <= count,
                    "MultiArray initialized count must be between zero and capacity"
                )
            }
            try await body(owner.buffer, &initializedCount)
        }
        self.arrayData = owner.finish(initializedCount: initializedCount)
    }
}

/// Owns unfinished storage across suspension. Until `finish`, `data.count`
/// stays zero, so only this owner destroys the scattered initialized elements.
private final class ScatteredInitializationOwner<Element>
    where Element: Generic, Element.RawRepresentation: PartialInitializationArrayData
{
    private let capacity: Int
    private var data: MultiArrayData<Element.RawRepresentation>?
    private var flags: UnsafeMutablePointer<UInt8>?

    init(capacity: Int) {
        precondition(capacity >= 0, "MultiArray capacity must be nonnegative")
        self.capacity = capacity
        self.data = MultiArrayData<Element.RawRepresentation>(unsafeUninitializedCapacity: capacity)
        if Element.RawRepresentation.requiresInitializationTracking, capacity > 0 {
            // One byte per index, not packed bits: adjacent element writers
            // must not perform read-modify-write on the same flag byte.
            let flags = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
            flags.initialize(repeating: 0, count: capacity)
            self.flags = flags
        }
    }

    var buffer: UnsafeUninitializedMultiArrayBuffer<Element> {
        guard let data else { preconditionFailure("MultiArray initialization already finished") }
        return UnsafeUninitializedMultiArrayBuffer(data.storage, count: self.capacity, flags: self.flags)
    }

    /// Releases only initialized slots, then relinquishes unfinished storage.
    private func cleanup() {
        guard let data else { return }
        if let flags {
            for index in 0 ..< self.capacity where flags[index] != 0 {
                Element.RawRepresentation.deinitialize(data.storage, at: index)
            }
            flags.deallocate()
            self.flags = nil
        }
        self.data = nil
    }

    func finish(initializedCount: Int) -> MultiArrayData<Element.RawRepresentation> {
        guard let data else { preconditionFailure("MultiArray initialization already finished") }
        if let flags {
            #if DEBUG
            let missingIndices = (0 ..< initializedCount).filter { flags[$0] == 0 }
            assert(missingIndices.isEmpty, "MultiArray initialization left elements \(missingIndices) uninitialized")
            let extraIndices = (initializedCount ..< self.capacity).filter { flags[$0] != 0 }
            assert(extraIndices.isEmpty, "MultiArray initialization initialized elements \(extraIndices) outside the reported prefix")
            #endif
            flags.deallocate()
            self.flags = nil
        }
        data.count = initializedCount
        self.data = nil
        return data
    }

    deinit {
        self.cleanup()
    }
}
