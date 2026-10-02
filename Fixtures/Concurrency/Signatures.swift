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

private enum FixtureError: Error {
    case childFailed
}

private func exerciseConcurrencySignatures() async throws(FixtureError) {
    _ = try await MultiArray<Int32>(unsafeUninitializedCapacity: 4) { buffer, count async throws(FixtureError) in
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for index in 0 ..< buffer.count {
                    group.addTask {
                        buffer.initializeElement(at: index, to: Int32(index))
                    }
                }
                try await group.waitForAll()
            }
        }
        catch {
            throw .childFailed
        }
        count = buffer.count
    }
}
