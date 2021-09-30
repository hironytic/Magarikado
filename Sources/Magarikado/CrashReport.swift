//
// CrashReport.swift
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

/// An object which manages a crash report.
public struct CrashReport {
    private var lines: [String]
    public private(set) var positions: CrashReportPositions
    public private(set) var content: CrashReportContent
    
    /// Initialize object from text lines.
    /// - Parameter lines: lines of crash report.
    /// - Throws: When lines are invalid.
    public init(lines: [String]) throws {
        self.lines = lines
        var parser = Parser()
        (content, positions) = try parser.parse(lines: lines)
    }
    
    /// Initialize object from text.
    /// - Parameter text: crash report text
    /// - Throws: When the text is invalid
    public init(text: String) throws {
        let lines = text
            .replacingOccurrences(of: "\r", with: "")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0) }
        try self.init(lines: lines)
    }
    
    /// Initialize object from binary data.
    /// - Parameter data: binary data which content is crash report
    /// - Throws: When the data is invalid
    public init(data: Data) throws {
        guard let text = String(data: data, encoding: .utf8) else {
            throw MagarikadoError.formatError
        }
        try self.init(text: text)
    }
    
    /// Initialize object from file.
    /// - Parameter file: file URL of crash report.
    /// - Throws: When failed to read the file, or its content is invalid.
    public init(file: URL) throws {
        let data: Data
        do {
            data = try Data(contentsOf: file)
        } catch let error {
            throw MagarikadoError.fileLoadError(url: file, error: error)
        }
        try self.init(data: data)
    }
    
    /// Symbolicate the report and return each lines.
    /// - Parameter fileProvider: `BinaryImageFileProvider` object which is used in symbolicating.
    /// - Returns: The result lines.
    public func symbolicateAsLines(fileProvider: BinaryImageFileProvider) throws -> [String] {
        struct BIIProvider: BinaryImageInfoProvider {
            private var finder: BinaryImageEntryFinder
            private var fileProvider: BinaryImageFileProvider
            
            init(searcher: BinaryImageEntryFinder, fileProvider: BinaryImageFileProvider) {
                self.finder = searcher
                self.fileProvider = fileProvider
            }
            
            func provideBinaryImageInfo(for locator: AddressTarget) throws -> BinaryImageInfo? {
                guard let binaryImage = finder.find(by: locator.address) else { return nil }
                guard let file = try fileProvider.provideBinaryImageFile(for: binaryImage) else { return nil }
                return BinaryImageInfo(file: file,
                                       loadAddress: binaryImage.loadAddress,
                                       architecture: binaryImage.architecture)
            }
        }
        
        let searcher = try BinaryImageEntryFinder(binaryImages: content.binaryImages)
        let provider = BIIProvider(searcher: searcher, fileProvider: fileProvider)
        let symbolicator = Symbolicator(binaryInfoProvider: provider)
        var textRewriter = TextRewriter(lines: lines)
     
        var addresses = [String]()
        var rewritePositions = [Position]()
        
        // exception backtrace
        if case .nonSymbolicated(let addrs) = content.exceptionBacktrace {
            let symbolicated = try symbolicator.symbolicate(targets: addrs.map { AddressTarget(address: $0) })
            let lines: [String] = symbolicated.enumerated().map { (index, result) in
                let address = addrs[index]
                let binaryImage = searcher.find(by: address)
                let funcName: String
                if let result = result {
                    funcName = result
                } else {
                    if let loadAddress = binaryImage?.loadAddress,
                       let numLoadAddress = try? Utility.address(fromString: loadAddress),
                       let numAddress = try? Utility.address(fromString: address) {
                        funcName = "\(loadAddress) + \(numAddress - numLoadAddress)"
                    } else {
                        funcName = "0x00000000 + 0"
                    }                    
                }

                let indexString = Utility.fixedWidth(String(index), width: 3)
                let binaryName = Utility.fixedWidth(binaryImage?.binaryName ?? "", width: 30)
                return "\(indexString) \(binaryName)\t\(address) \(funcName)"
            }
            try textRewriter.addMark(at: positions.exceptionBacktrace!, newTextLines: lines)
        }
        
        // backtrace
        for btIndex in content.backtraces.indices {
            for sfIndex in content.backtraces[btIndex].stackFrames.indices {
                let address = content.backtraces[btIndex].stackFrames[sfIndex].address
                addresses.append(address)
                
                let funcPosition = positions.backtraces[btIndex].stackFrames[sfIndex].functionName
                let lastPosition = positions.backtraces[btIndex].stackFrames[sfIndex].sourceLine
                let position = Position(startLine: funcPosition.startLine, startColumn: funcPosition.startColumn,
                                        endLine: lastPosition.endLine, endColumn: lastPosition.endColumn)
                rewritePositions.append(position)
            }
        }
        let symbolicated = try symbolicator.symbolicate(targets: addresses.map { AddressTarget(address: $0) })
        for (index, newText) in symbolicated.enumerated() {
            if let newText = newText {
                try textRewriter.addMark(at: rewritePositions[index], newText: newText)
            }
        }
        
        return textRewriter.rewrite()
    }
    
    /// Symbolicate the report and return whole text as a string.
    /// - Parameter fileProvider: `BinaryImageFileProvider` object which is used in symbolicating.
    /// - Returns: The result text.
    public func symbolicateAsText(fileProvider: BinaryImageFileProvider) throws -> String {
        let lines = try symbolicateAsLines(fileProvider: fileProvider)
        return lines.joined(separator: "\n")
    }
    
    /// Symbolicate the report and return whole text as a binary data.
    /// - Parameter fileProvider: `BinaryImageFileProvider` object which is used in symbolicating.
    /// - Returns: The result data.
    public func symbolicateAsData(fileProvider: BinaryImageFileProvider) throws -> Data {
        let text = try symbolicateAsText(fileProvider: fileProvider)
        return Data(text.utf8)
    }
    
    /// Symbolicate the report and save it to a file.
    /// - Parameters:
    ///   - fileProvider: `BinaryImageFileProvider` object which is used in symbolicating.
    ///   - outFile: URL of the file to which the symbolicated report will be saved.
    public func symbolicateAsFile(fileProvider: BinaryImageFileProvider, outFile: URL) throws {
        let data = try symbolicateAsData(fileProvider: fileProvider)
        try data.write(to: outFile)
    }
}

// Symbolicate target which has only address
public struct AddressTarget: SymbolicateTarget {
    public var address: String
    
    public init(address: String) {
        self.address = address
    }
}
