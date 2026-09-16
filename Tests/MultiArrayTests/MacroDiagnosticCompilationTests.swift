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

@Generic
struct MacroConditionalComputed {
    var value: Int32 = 7
    let fixed: Int32
    #if os(Linux)
    var doubled: Int32 { value * 2 }
    static let defaultValue: Int32 = 7
    struct Nested { let ignored: Int32 = 3 }
    #else
    func doubled() -> Int32 { value * 2 }
    #endif
}

@Suite
struct MacroStoredPropertyCompilationTests {
    @Test
    func conditionalComputedAndDefaultedMutableMembersRemainSupported() {
        var original = MacroConditionalComputed(fixed: 19)
        original.value = 42
        let restored = MultiArray([original])[0]
        #expect(restored.value == 42)
        #expect(restored.fixed == 19)
    }
}

#if os(Linux)
@Suite
struct MacroDiagnosticCompilationTests {
    @Test(arguments: [
        ("#if os(Linux)\nvar active: Int32 = 3\n#endif", "conditionally compiled stored property 'active'"),
        ("#if os(macOS)\nvar inactive: Int32\n#endif", "conditionally compiled stored property 'inactive'"),
        ("#if os(Linux)\n#if DEBUG\nvar nested: Int32 = 3\n#endif\n#endif", "conditionally compiled stored property 'nested'"),
        ("let value: Int32 = 7", "declaration-initialized let property 'value'"),
    ])
    func unsupportedPropertiesFailCompilation(member: String, diagnostic: String) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("Probe.swift")
        try "import MultiArray\n@Generic struct Probe {\n\(member)\n}\n".write(to: source, atomically: true, encoding: .utf8)
        let binaryDirectory = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
        // SwiftPM's legacy build uses Modules/ and a -tool executable; Swift Build
        // places both modules and the unsuffixed plugin in the products directory.
        let legacyModules = binaryDirectory.appendingPathComponent("Modules")
        let isLegacyBuild = FileManager.default.fileExists(atPath: legacyModules.appendingPathComponent("MultiArray.swiftmodule").path)
        let moduleDirectory = isLegacyBuild ? legacyModules : binaryDirectory
        let plugin = binaryDirectory.appendingPathComponent(isLegacyBuild ? "MultiArrayMacros-tool" : "MultiArrayMacros")
        #expect(FileManager.default.fileExists(atPath: moduleDirectory.appendingPathComponent("MultiArray.swiftmodule").path))
        #expect(FileManager.default.isExecutableFile(atPath: plugin.path))
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [
            "swiftc", "-c", source.path, "-o", directory.appendingPathComponent("Probe.o").path,
            "-I", moduleDirectory.path,
            "-load-plugin-executable", plugin.path + "#MultiArrayMacros",
        ]
        let errors = Pipe()
        process.standardError = errors
        try process.run()
        let output = try #require(String(data: errors.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8))
        process.waitUntilExit()
        #expect(process.terminationStatus != 0)
        #expect(output.contains(diagnostic), "\(output)")
    }
}
#endif
