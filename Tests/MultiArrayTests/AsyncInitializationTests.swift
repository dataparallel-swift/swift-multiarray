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
@testable import MultiArray
import Testing

private enum ConstructionError: Error, Equatable {
    case expected
}

private final class LifetimeCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0

    func increment() {
        self.lock.lock()
        self.value += 1
        self.lock.unlock()
    }

    func decrement() {
        self.lock.lock()
        self.value -= 1
        self.lock.unlock()
    }

    var liveCount: Int {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.value
    }
}

private final class Tracked: @unchecked Sendable {
    let counter: LifetimeCounter

    init(_ counter: LifetimeCounter) {
        self.counter = counter
        counter.increment()
    }

    deinit { self.counter.decrement() }
}

@Suite
struct AsyncInitializationTests {
    @Test
    func arbitraryOrdersAndZeroCapacity() async {
        let forward = await MultiArray<Int32>(unsafeUninitializedCapacity: 4) { buffer, count async in
            #expect(buffer.flags == nil)
            for index in 0 ..< buffer.count {
                buffer.initializeElement(at: index, to: Int32(index))
            }
            count = buffer.count
        }
        #expect(Array(forward) == [0, 1, 2, 3])

        let reverse = await MultiArray<Int32>(unsafeUninitializedCapacity: 4) { buffer, count async in
            for index in (0 ..< buffer.count).reversed() {
                buffer.initializeElement(at: index, to: Int32(index))
            }
            count = buffer.count
        }
        #expect(Array(reverse) == [0, 1, 2, 3])

        let shuffled = await MultiArray<Int32>(unsafeUninitializedCapacity: 4) { buffer, count async in
            for index in [2, 0, 3, 1] {
                buffer.initializeElement(at: index, to: Int32(index))
            }
            count = buffer.count
        }
        #expect(Array(shuffled) == [0, 1, 2, 3])

        let empty = await MultiArray<Box<String>>(unsafeUninitializedCapacity: 0) { buffer, count async in
            #expect(buffer.count == 0)
            #expect(count == 0)
        }
        #expect(empty.isEmpty)
    }

    @Test
    func partialPrefixRetainsCapacityAndCanonicalSnapshot() async {
        let result = await MultiArray<Product<UInt8, UInt64>>(unsafeUninitializedCapacity: 16) { buffer, count async in
            #expect(count == 0)
            for index in [2, 0, 1] {
                buffer.initializeElement(at: index, to: Product(UInt8(index), UInt64(index)))
            }
            count = 3
        }
        #expect(result.count == 3)
        #expect(result.arrayData.capacity == 16)
        let exact = MultiArray((0 ..< 3).map { Product(UInt8($0), UInt64($0)) })
        for index in 0 ..< result.count {
            #expect(result[index]._0 == UInt8(index))
            #expect(result[index]._1 == UInt64(index))
        }
        #expect(result.encode() == exact.encode())
    }

    @Test
    func trackedPartialAndEmptyPrefixesReleaseOnlyPublishedElements() async {
        let counter = LifetimeCounter()
        do {
            let result = await MultiArray<Box<Tracked>>(unsafeUninitializedCapacity: 6) { buffer, count async in
                for index in [1, 0] {
                    buffer.initializeElement(at: index, to: Box(Tracked(counter)))
                }
                count = 2
            }
            #expect(result.count == 2)
            #expect(result.arrayData.capacity == 6)
            #expect(counter.liveCount == 2)
        }
        #expect(counter.liveCount == 0)
        let empty = await MultiArray<Box<Tracked>>(unsafeUninitializedCapacity: 6) { _, count async in
            #expect(count == 0)
        }
        #expect(empty.isEmpty)
        #expect(empty.arrayData.capacity == 6)
    }

    @Test(arguments: [0, 17, 64])
    func concurrentDisjointIndices(publishedCount: Int) async {
        let result = await MultiArray<Product<Int32, Box<String>>>(unsafeUninitializedCapacity: 64) { buffer, count async in
            #expect(buffer.flags != nil)
            await withTaskGroup(of: Void.self) { group in
                for index in 0 ..< publishedCount {
                    group.addTask {
                        buffer.initializeElement(at: index, to: Product(Int32(index), Box(String(index))))
                    }
                }
            }
            count = publishedCount
        }
        #expect(result.count == publishedCount)
        #expect(result.arrayData.capacity == 64)
        for index in 0 ..< result.count {
            #expect(result[index]._0 == Int32(index))
            #expect(result[index]._1.unbox == String(index))
        }
    }

    @Test
    func scatteredFailureReleasesOnlyInitializedProducts() async {
        let counter = LifetimeCounter()
        do {
            _ = try await MultiArray<Product<
                Int32,
                Box<Tracked>
            >>(unsafeUninitializedCapacity: 6) { buffer, count async throws(ConstructionError) in
                #expect(buffer.flags != nil)
                #expect((0 ..< buffer.count).allSatisfy { buffer.flags?[$0] == 0 })
                buffer.initializeElement(at: 4, to: Product(4, Box(Tracked(counter))))
                buffer.initializeElement(at: 1, to: Product(1, Box(Tracked(counter))))
                #expect(counter.liveCount == 2)
                count = 1 // Cleanup must use the scattered flags, not this count.
                throw .expected
            }
            Issue.record("expected construction to throw")
        }
        catch {
            #expect(error == .expected)
        }
        #expect(counter.liveCount == 0)
    }

    @Test
    func childFailureIsJoinedBeforeCleanup() async {
        let counter = LifetimeCounter()
        do {
            _ = try await MultiArray<Box<Tracked>>(unsafeUninitializedCapacity: 4) { buffer, _ async throws(ConstructionError) in
                do {
                    try await withThrowingTaskGroup(of: Void.self) { group in
                        for index in 0 ..< buffer.count {
                            group.addTask {
                                if index == 3 { throw ConstructionError.expected }
                                buffer.initializeElement(at: index, to: Box(Tracked(counter)))
                            }
                        }
                        try await group.waitForAll()
                    }
                }
                catch {
                    throw .expected
                }
            }
            Issue.record("expected child construction to throw")
        }
        catch {
            #expect(error == .expected)
        }
        #expect(counter.liveCount == 0)
    }

    @Test
    func completedTrackedStorageTransfersWithoutReinitializing() async {
        let counter = LifetimeCounter()
        do {
            let result = await MultiArray<Box<Tracked>>(unsafeUninitializedCapacity: 3) { buffer, count async in
                #expect(buffer.flags != nil)
                for index in [2, 0, 1] {
                    buffer.initializeElement(at: index, to: Box(Tracked(counter)))
                }
                count = buffer.count
            }
            #expect(counter.liveCount == 3)
            #expect(result.count == 3)
        }
        #expect(counter.liveCount == 0)
    }

    #if compiler(>=6.2)
    @Test
    func negativeReportedCountTraps() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            _ = try await MultiArray<Int32>(unsafeUninitializedCapacity: 1) { _, reportedCount async throws(ConstructionError) in
                reportedCount = -1
            }
        }
        #if DEBUG
        let output = String(bytes: result?.standardErrorContent ?? [], encoding: .utf8) ?? ""
        #expect(output.contains("MultiArray initialized count must be between zero and capacity"))
        #else
        // Optimized preconditions may trap without emitting their message.
        _ = result
        #endif
    }

    @Test
    func excessiveReportedCountTraps() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            _ = await MultiArray<Int32>(unsafeUninitializedCapacity: 1) { _, reportedCount async in
                reportedCount = 2
            }
        }
        #if DEBUG
        let output = String(bytes: result?.standardErrorContent ?? [], encoding: .utf8) ?? ""
        #expect(output.contains("MultiArray initialized count must be between zero and capacity"))
        #else
        // Optimized preconditions may trap without emitting their message.
        _ = result
        #endif
    }

    @Test
    func negativeReportedCountTrapsOnThrow() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            _ = try await MultiArray<Int32>(unsafeUninitializedCapacity: 1) { _, reportedCount async throws(ConstructionError) in
                reportedCount = -1
                throw .expected
            }
        }
        #if DEBUG
        let output = String(bytes: result?.standardErrorContent ?? [], encoding: .utf8) ?? ""
        #expect(output.contains("MultiArray initialized count must be between zero and capacity"))
        #else
        // Optimized preconditions may trap without emitting their message.
        _ = result
        #endif
    }

    @Test
    func excessiveReportedCountTrapsOnThrow() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            _ = try await MultiArray<Int32>(unsafeUninitializedCapacity: 1) { _, reportedCount async throws(ConstructionError) in
                reportedCount = 2
                throw .expected
            }
        }
        #if DEBUG
        let output = String(bytes: result?.standardErrorContent ?? [], encoding: .utf8) ?? ""
        #expect(output.contains("MultiArray initialized count must be between zero and capacity"))
        #else
        // Optimized preconditions may trap without emitting their message.
        _ = result
        #endif
    }

    #if DEBUG
    @Test
    func initializedSlotOutsidePrefixAssertsInDebug() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            _ = await MultiArray<Box<String>>(unsafeUninitializedCapacity: 5) { buffer, count async in
                buffer.initializeElement(at: 0, to: Box("first"))
                buffer.initializeElement(at: 2, to: Box("third"))
                buffer.initializeElement(at: 4, to: Box("fifth"))
                count = 1
            }
        }
        let output = String(bytes: result?.standardErrorContent ?? [], encoding: .utf8) ?? ""
        #expect(output.contains("MultiArray initialization initialized elements [2, 4] outside the reported prefix"))
    }

    @Test
    func missingTrackedSlotAssertsInDebug() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            _ = await MultiArray<Box<String>>(unsafeUninitializedCapacity: 5) { buffer, count async in
                buffer.initializeElement(at: 0, to: Box("first"))
                buffer.initializeElement(at: 2, to: Box("third"))
                count = buffer.count
            }
        }

        let output = String(bytes: result?.standardErrorContent ?? [], encoding: .utf8) ?? ""
        #expect(output.contains("MultiArray initialization left elements [1, 3, 4] uninitialized"))
    }

    @Test
    func duplicateTrackedSlotAssertsInDebug() async {
        let result = await #expect(processExitsWith: .failure, observing: [\.standardErrorContent]) {
            _ = await MultiArray<Box<String>>(unsafeUninitializedCapacity: 1) { buffer, _ async in
                buffer.initializeElement(at: 0, to: Box("first"))
                buffer.initializeElement(at: 0, to: Box("second"))
            }
        }

        let output = String(bytes: result?.standardErrorContent ?? [], encoding: .utf8) ?? ""
        #expect(output.contains("MultiArray element initialized more than once"))
    }
    #endif
    #endif
}
