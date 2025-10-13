//===---*- Greatdori! -*---------------------------------------------------===//
//
// BashTools.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.memz.top/LICENSE.txt for license information
// See https://greatdori.memz.top/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import Foundation

// Copyright Notice: Code below this line (and above the next Copyright Notice) is supplied by Apple.
// License: Apple Sample Code License (https://developer.apple.com/support/downloads/terms/apple-sample-code/Apple-Sample-Code-License.pdf)

@MainActor
func launch(tool: URL, arguments: [String] = [], input: Data = Data(), completionHandler: @escaping CompletionHandler) {
//    dispatchPrecondition(condition: .onQueue(.main))
    
    let group = DispatchGroup()
    let inputPipe = Pipe()
    let outputPipe = Pipe()
    
    var errorQ: Error? = nil
    var output = Data()
    
    let proc = Process()
    proc.executableURL = tool
    proc.arguments = arguments
    proc.standardInput = inputPipe
    proc.standardOutput = outputPipe
    group.enter()
    proc.terminationHandler = { _ in
        DispatchQueue.main.async {
            group.leave()
        }
    }
    
    group.notify(queue: .main) {
        if let error = errorQ {
            completionHandler(.failure(error), output)
        } else {
            completionHandler(.success(proc.terminationStatus), output)
        }
    }
    
    do {
        func posixErr(_ error: Int32) -> Error { NSError(domain: NSPOSIXErrorDomain, code: Int(error), userInfo: nil) }
        
        let fcntlResult = fcntl(inputPipe.fileHandleForWriting.fileDescriptor, F_SETNOSIGPIPE, 1)
        guard fcntlResult >= 0 else { throw posixErr(errno) }
        
        try proc.run()
        
        group.enter()
        let writeIO = DispatchIO(type: .stream, fileDescriptor: inputPipe.fileHandleForWriting.fileDescriptor, queue: .main) { _ in
            try! inputPipe.fileHandleForWriting.close()
        }
        let inputDD = input.withUnsafeBytes { DispatchData(bytes: $0) }
        writeIO.write(offset: 0, data: inputDD, queue: .main) { isDone, _, error in
            if isDone || error != 0 {
                writeIO.close()
                if errorQ == nil && error != 0 { errorQ = posixErr(error) }
                group.leave()
            }
        }
        
        group.enter()
        let readIO = DispatchIO(type: .stream, fileDescriptor: outputPipe.fileHandleForReading.fileDescriptor, queue: .main) { _ in
            try! outputPipe.fileHandleForReading.close()
        }
        readIO.read(offset: 0, length: .max, queue: .main) { isDone, chunkQ, error in
            output.append(contentsOf: chunkQ ?? .empty)
            if isDone || error != 0 {
                readIO.close()
                if errorQ == nil && error != 0 { errorQ = posixErr(error) }
                group.leave()
            }
        }
    } catch {
        errorQ = error
        proc.terminationHandler!(proc)
    }
}

typealias CompletionHandler = (_ result: Result<Int32, Error>, _ output: Data) -> Void

// Copyright Notice: Code below this line is no longer from Apple.

@MainActor
func runTool(tool: URL = URL(fileURLWithPath: "/usr/bin/env"), arguments: [String] = [], input: Data = Data()) async throws -> (status: Int32, output: Data) {
    try await withCheckedThrowingContinuation { continuation in
        launch(tool: tool, arguments: arguments, input: input) { result, output in
            switch result {
            case .success(let status):
                continuation.resume(returning: (status, output))
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}

@MainActor
func runBashScript(_ inputScript: String, commandName: String? = nil, reportBashContent: Bool = true, expectedStatus: Int32? = 0, useEnhancedErrorCatching: Bool = true, viewFailureAsFatalError: Bool) async throws -> (status: Int32, output: Data) {
    
    // DEBUG
//    let something = try await runTool(arguments: ["bash", "-lc", "echo Hello; echo Error >&2"])
//    print(String(data: something.output, encoding: .utf8)!)

    let enhancedErrorCatchingMethod = #"""
set -euo pipefail

echo "Debug 002"

tmp_err=$(mktemp)
exec 2> >(tee "$tmp_err" >&2)
# exec > >(tee "$tmp_out") 2> >(tee "$tmp_err" >&2)

echo "Trees"

trap 'rc=$?;
      err_line=${BASH_LINENO[0]};
      err_file=${BASH_SOURCE[0]};
      err_cmd="$BASH_COMMAND";
      echo -e "\n[!][Bash]\#(commandName != nil ? "[\(commandName!)]" : "") Bash encountered an error."
      echo "LOC: ${err_file}:${err_line}"
      echo "CMD: ${err_cmd}"
      echo "EXC: ${rc}"
      echo -n "MSG:"
      echo
      sed "s/^/     /" "$tmp_err"
     ' ERR
"""#
    
    let script = """
\(useEnhancedErrorCatching ? enhancedErrorCatchingMethod : "")
\(inputScript)
"""
    
    let commandTag = commandName != nil ? "[\(commandName!)]" : ""
    do {
        let bashResult = try await runTool(arguments: ["bash", "-lc", script])
        fflush(stdout)
        if reportBashContent {
            if bashResult.output.isEmpty {
                print("[$][Bash]\(commandTag) Bash returned exit code \(bashResult.status) without any further output.")
            } else if let bashResultString = String(data: bashResult.output, encoding: .utf8) {
                    print("""
[$][Bash]\(commandTag) Bash returned exit code \(bashResult.status) with output as following: \"\"\"
\(bashResultString)
\"\"\"
""")
            } else {
                print("[$][Bash]\(commandTag) Bash returned exit code \(bashResult.status) with an output data of \(bashResult.output). (Unparsebale with UTF-8.)")
            }
            fflush(stdout)
        }
        if let expectedStatus, expectedStatus != bashResult.status {
            fflush(stdout)
            throw BashError(status: bashResult.status, output: bashResult.output)
        }
        fflush(stdout)
        return bashResult
    } catch {
//        if viewFailureAsFatalError {
//            fatalError("[×][Bash]\(commandTag) Encountered an fatal Bash running error. Error: \(error).")
//        }
        throw error
    }
}



struct BashError: Error, CustomStringConvertible {
    var status: Int32
    var output: Data
    
    var description: String {
        let outputString = String(data: output, encoding: .utf8) ?? "<\(output.count) bytes>"
        if outputString.contains("\n") {
            return """
BashError(status: \(status), output: \"\"\"
\(outputString)
\"\"\")
"""
        } else {
            return "BashError(status: \(status), output: \(outputString))"
        }
    }
}
