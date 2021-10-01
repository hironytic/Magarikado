//
// Symbolicator.swift
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

/// Informations about binary image.
public struct BinaryImageInfo: Hashable {
    /// URL of symbol file.
    public var file: URL
    
    /// Load address. This is a hexadecimal string with `"0x"` prefix.
    public var loadAddress: String
    
    /// CPU architecture.
    public var architecture: String
    
    public init(file: URL, loadAddress: String, architecture: String) {
        self.file = file
        self.loadAddress = loadAddress
        self.architecture = architecture
    }    
}

/// Target of symbolication.
public protocol SymbolicateTarget {
    var address: String { get }
}

/// This object provides binary image informations.
public protocol BinaryImageInfoProvider {
    associatedtype Locator
    
    /// Provides a binary image url and its load address for specified address.
    /// - Parameter locator: object that indicates the location of binary image.
    /// - Returns: informations about binary image, or nil if not available.
    func provideBinaryImageInfo(for locator: Locator) throws -> BinaryImageInfo?
}

/// This object symbolicates addresses.
public struct Symbolicator<Target: SymbolicateTarget, BIIProvider: BinaryImageInfoProvider> where Target == BIIProvider.Locator {
    public var binaryInfoProvider: BIIProvider
    
    /// Initialize.
    /// - Parameter binaryInfoProvider: ``BinaryImageInfoProvider`` object which is used in symbolcation.
    public init(binaryInfoProvider: BIIProvider) {
        self.binaryInfoProvider = binaryInfoProvider
    }
    
    /// Symbolicate addresses.
    /// - Parameter addresses: Address strings.
    /// - Returns: An array. It has symbolicated strings for the address, or `nil`s for unsymbolicated address.
    public func symbolicate(targets: [Target]) throws -> [String?] {
        var result: [String?] = .init(repeating: nil, count: targets.count)
        var binaryImageInfoTable = [BinaryImageInfo: [Int]]()
        for (index, target) in targets.enumerated() {
            if let biInfo = try binaryInfoProvider.provideBinaryImageInfo(for: target) {
                binaryImageInfoTable[biInfo, default: []].append(index)
            }
        }
        
        for (biInfo, indices) in binaryImageInfoTable {
            let addrs = indices.map { targets[$0].address }
            let symbolicated = try runAtos(symbolImageFile: biInfo.file,
                                           architecture: biInfo.architecture,
                                           loadAddress: biInfo.loadAddress,
                                           addresses: addrs)
            for (si, sr) in symbolicated.enumerated() {
                if si >= indices.endIndex {
                    break
                }
                result[indices[si]] = sr
            }
        }
        
        return result
    }
    
    private func runAtos(symbolImageFile: URL,
                         architecture: String,
                         loadAddress: String,
                         addresses: [String]) throws -> [String] {
        var arguments = [
            "atos",
            "-o",
            symbolImageFile.path,
            "-arch",
            architecture,
            "-l",
            loadAddress,
        ]
        arguments.append(contentsOf: addresses)
        
        let (status, stdout, stderr) = Utility.runCommand(path: "/usr/bin/xcrun", arguments: arguments)
        guard status == 0 else { throw MagarikadoError.externalCommandFailed("atos", stderr) }

        let re = try! NSRegularExpression(pattern: #"\s*\(in .*?\)"#, options: [])
        return stdout
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map {
                let text = String($0)
                return removeSymbolName(text: text, re: re)
            }
    }

    private func removeSymbolName(text: String, re: NSRegularExpression) -> String {
        if let mr = re.firstMatch(in: text, range: NSRange(text.startIndex ..< text.endIndex, in: text)) {
            if let range = Range(mr.range(at: 0), in: text) {
                var result = text
                result.removeSubrange(range)
                return result
            }
        }
        return text
    }
}
