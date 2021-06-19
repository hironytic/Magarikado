//
// Utility.swift
// Magarikado
//
// Copyright (c) 2021 Hironori Ichimiya <hiron@hironytic.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation

enum Utility {
    /// Parse address string then return as `UInt64`.
    /// - Parameter addrString: Address string
    /// - Returns: Parsed 64-bit unsigned number, or nil when failed to parse.
    static func address(fromString addrString: String) throws -> UInt64 {
        let hexString: String
        if addrString.hasPrefix("0x") {
            hexString = String(addrString[addrString.index(addrString.startIndex, offsetBy: 2)...])
        } else {
            hexString = addrString
        }
        guard let result = UInt64(hexString, radix: 16) else { throw MagarikadoError.invalidAddress(addrString) }
        return result
    }
    
    /// Make fixed-width string
    /// - Parameters:
    ///   - string: string
    ///   - width: width
    /// - Returns: fixed-width string
    static func fixedWidth(_ string: String, width: Int) -> String {
        let length = string.count
        if length >= width {
            return String(string[string.startIndex ..< string.index(string.startIndex, offsetBy: width)])
        } else {
            return string + String(repeating: " ", count: width - length)
        }
    }
    
    /// Run a command line tool.
    /// - Parameters:
    ///   - path: path of the command
    ///   - arguments: array of arguments
    /// - Returns: Result of the command.
    ///            (status: exit status code, stdout: standard output, stderr: standard error)
    static func runCommand(path: String, arguments: [String]) -> (status: Int32, stdout: String, stderr: String) {
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        let outputFileHandle = outputPipe.fileHandleForReading
        defer { outputFileHandle.closeFile() }
        
        let errorFileHandle = errorPipe.fileHandleForReading
        defer { errorFileHandle.closeFile() }
        
        let process = Process()
        process.launchPath = path
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        process.launch()
        process.waitUntilExit()
        
        let stdout = String(data: outputFileHandle.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: errorFileHandle.readDataToEndOfFile(), encoding: .utf8) ?? ""
        
        return (status: process.terminationStatus, stdout: stdout, stderr: stderr)
    }
    
    /// Search specified range using the binary search algorithm.
    /// - Parameters:
    ///   - startIndex: First index of the range (inclusive).
    ///   - endIndex: Last index of the range (exclusive).
    ///   - judge: Closure which takes an index as parameter.
    ///            It compares a value of the index to expected value and returns
    ///            negative number when it is smaller than expected one,
    ///            positive number when it is larger than expected one
    ///            or zero when it is same as expected one.
    /// - Returns: The 0th value (`found`) is whether expected value was found or not.
    ///            The 1st value (`index`) is its index when found, or insertion point when not found.
    static func binarySearch(startIndex: Int, endIndex: Int, judge: (Int) throws -> Int) rethrows -> (found: Bool, index: Int) {
        var low = startIndex
        var high = endIndex - 1

        while low <= high {
            let mid = low + (high - low) / 2
            let compResult = try judge(mid)
            if compResult < 0 {
                low = mid + 1
            } else if compResult > 0 {
                high = mid - 1
            } else {
                return (true, mid)
            }
        }
        
        return (false, low)
    }
}
