//
// CrashReport+Parser.swift
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

extension CrashReport {
    struct Parser {
        private enum Section {
            case header
            case exceptionInformation
            case exceptionBacktrace
            case backtrace
            case crashedThreadState
            case binaryImages
        }
        private var section: Section = .header
        private var lines: [String] = []
        private var lineIndex: Int = 0
        private var line: String = ""
        private var content: CrashReportContent = .init()
        private var positions: CrashReportPositions = .init()
        private var currentStackFrames: [StackFrame] = []
        private var currentThreadBacktrace: ThreadBacktrace? = nil
        private var currentThreadBacktracePositions: ThreadBacktracePositions? = nil
        private var currentThreadName: String? = nil
        
        private enum HeaderKeys {
            public static let incidentIdentifier = "Incident Identifier"
            public static let crashReporterKey = "CrashReporter Key"
            public static let betaIdentifier = "Beta Identifier"
            public static let hardwareModel = "Hardware Model"
            public static let process = "Process"
            public static let path = "Path"
            public static let identifier = "Identifier"
            public static let version = "Version"
            public static let appStoreTools = "AppStoreTools"
            public static let appVariant = "AppVariant"
            public static let codeType = "Code Type"
            public static let role = "Role"
            public static let parentProcess = "Parent Process"
            public static let coalition = "Coalition"
            public static let dateTime = "Date/Time"
            public static let launchTime = "Launch Time"
            public static let osVersion = "OS Version"
        }

        private enum ExceptionInformationKeys {
            public static let exceptionType = "Exception Type"
            public static let exceptionCodes = "Exception Codes"
            public static let exceptionSubtype = "Exception Subtype"
            public static let exceptionNote = "Exception Note"
            public static let terminationReason = "Termination Reason"
            public static let triggeredByThread = "Triggered by Thread"
            public static let crashedThread = "Crashed Thread"
            
            public static let allKeys = [
                exceptionType, exceptionCodes, exceptionSubtype,
                exceptionNote, terminationReason, triggeredByThread, crashedThread,
            ]
        }
        
        private enum ExceptionBacktraceKeys {
            public static let lastExceptionBacktrace = "Last Exception Backtrace"
        }
        
        private enum BinaryImagesKeys {
            public static let binaryImages = "Binary Images"
        }
        
        mutating func parse(lines: [String]) throws -> (content: CrashReportContent, positions: CrashReportPositions) {
            self.lines = lines
            self.section = .header
            for (lineIndex, line) in lines.enumerated() {
                self.lineIndex = lineIndex
                self.line = line
                switch section {
                case .header:
                    parseHeader()
                case .exceptionInformation:
                    parseExceptionInformation()
                case .exceptionBacktrace:
                    parseExceptionBacktrace()
                case .backtrace:
                    parseBacktrace()
                case .crashedThreadState:
                    parseCrashedThreadState()
                case .binaryImages:
                    parseBinaryImages()
                }
            }
            return (content: content, positions: positions)
        }
        
        // MARK: Header
        
        private mutating func parseHeader() {
            guard let (key, value, _) = parseKeyValueLine() else { return }

            switch key {
            case HeaderKeys.incidentIdentifier:
                content.header.incidentIdentifier = value
            case HeaderKeys.crashReporterKey:
                content.header.crashReporterKey = value
            case HeaderKeys.betaIdentifier:
                content.header.betaIdentifier = value
            case HeaderKeys.hardwareModel:
                content.header.hardwareModel = value
            case HeaderKeys.process:
                content.header.process = value
            case HeaderKeys.path:
                content.header.path = value
            case HeaderKeys.identifier:
                content.header.identifier = value
            case HeaderKeys.version:
                content.header.version = value
            case HeaderKeys.appStoreTools:
                content.header.appStoreTools = value
            case HeaderKeys.appVariant:
                content.header.appVariant = value
            case HeaderKeys.codeType:
                content.header.codeType = value
            case HeaderKeys.role:
                content.header.role = value
            case HeaderKeys.parentProcess:
                content.header.parentProcess = value
            case HeaderKeys.coalition:
                content.header.coalition = value
            case HeaderKeys.dateTime:
                content.header.dateTime = value
            case HeaderKeys.launchTime:
                content.header.launchTime = value
            case HeaderKeys.osVersion:
                content.header.osVersion = value
            default:
                if ExceptionInformationKeys.allKeys.contains(key) {
                    moveToExceptionInformationSection()
                } else if ExceptionBacktraceKeys.lastExceptionBacktrace == key {
                    moveToExceptionBacktrace()
                } else if isThreadBacktrace() {
                    moveToBacktrace()
                }
            }
        }
        
        // MARK: Exception Information
        
        private mutating func moveToExceptionInformationSection() {
            section = .exceptionInformation
            parseExceptionInformation()
        }
        
        private mutating func parseExceptionInformation() {
            guard let (key, value, _) = parseKeyValueLine() else { return }

            switch key {
            case ExceptionInformationKeys.exceptionType:
                content.exceptionInformation.exceptionType = value
            case ExceptionInformationKeys.exceptionCodes:
                content.exceptionInformation.exceptionCodes = value
            case ExceptionInformationKeys.exceptionSubtype:
                content.exceptionInformation.exceptionSubtype = value
            case ExceptionInformationKeys.exceptionNote:
                content.exceptionInformation.exceptionNote = value
            case ExceptionInformationKeys.terminationReason:
                content.exceptionInformation.terminationReason = value
            case ExceptionInformationKeys.triggeredByThread:
                content.exceptionInformation.triggeredByThread = value
            case ExceptionInformationKeys.crashedThread:
                content.exceptionInformation.crashedThread = value
            default:
                if ExceptionBacktraceKeys.lastExceptionBacktrace == key {
                    moveToExceptionBacktrace()
                } else if isThreadBacktrace() {
                    moveToBacktrace()
                }
            }
        }
        
        // MARK: Exception Backtrace
        
        private let reNonSynbolicatedLastExceptionBacktrace = try! NSRegularExpression(pattern: #"\((.*)\)"#, options: [])
        
        private mutating func moveToExceptionBacktrace() {
            section = .exceptionBacktrace
            currentStackFrames = []
            
            parseExceptionBacktrace()
        }
        
        private mutating func parseExceptionBacktrace() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if let match = reNonSynbolicatedLastExceptionBacktrace.firstMatch(in: trimmedLine) {
                if let (addressesStr, _, _) = trimmedLine.textAndPosition(nsRange: match.range(at: 1)) {
                    let addresses = addressesStr.split(separator: " ").map { String($0) }
                    content.exceptionBacktrace = .nonSymbolicated(addresses)
                    positions.exceptionBacktrace = Position(line: lineIndex, startColumn: 0, endColumn: line.count)
                }
            } else if let (stackFrame, _) = parseStackFrameLine() {
                currentStackFrames.append(stackFrame)
                if positions.exceptionBacktrace == nil {
                    positions.exceptionBacktrace = Position(line: lineIndex, startColumn: 0, endColumn: line.count)
                } else {
                    positions.exceptionBacktrace!.endLine = lineIndex
                    positions.exceptionBacktrace!.endColumn = line.count
                }
            } else if isThreadBacktrace() {
                if !currentStackFrames.isEmpty {
                    content.exceptionBacktrace = .symbolicated(currentStackFrames)
                }
                moveToBacktrace()
            }
        }
        
        // MARK: Backtrace
        
        private let reThreadBacktrace = try! NSRegularExpression(pattern: #"^Thread [0-9]+ .*"#, options: [])
        private let reThreadBacktrace1 = try! NSRegularExpression(pattern: #"^Thread [0-9]+ name:\s*(.*)"#, options: [])
        private let reThreadBacktrace2 = try! NSRegularExpression(pattern: #"^Thread ([0-9]+)(\s+Crashed)?:"#, options: [])
        
        private func isThreadBacktrace() -> Bool {
            return reThreadBacktrace.firstMatch(in: line) != nil
        }
        
        private let reBacktrace = try! NSRegularExpression(pattern: #"([0-9]+)\s+(.+\S)\s*\t(0x[0-9a-f]+)\s+(.*)"#, options: [])
        private let reBacktrace2 = try! NSRegularExpression(pattern: #"(.+) \+ ([0-9]+)(?:\s+\((.+):([0-9]+)\))?"#, options: [])
        
        private func parseStackFrameLine() -> (StackFrame, StackFramePositions)? {
            guard let matchFour = reBacktrace.firstMatch(in: line) else { return nil }
            guard let number = line.textAndPosition(nsRange: matchFour.range(at: 1)) else { return nil }
            guard let binaryName = line.textAndPosition(nsRange: matchFour.range(at: 2)) else { return nil }
            guard let address = line.textAndPosition(nsRange: matchFour.range(at: 3)) else { return nil }
            guard let others = line.textAndPosition(nsRange: matchFour.range(at: 4)) else { return nil }

            guard let matchTwoOrFour = reBacktrace2.firstMatch(in: others.text) else { return nil }
            guard let functionName = others.text.textAndPosition(nsRange: matchTwoOrFour.range(at: 1)) else { return nil }
            guard let offset = others.text.textAndPosition(nsRange: matchTwoOrFour.range(at: 2)) else { return nil }
            let sourceName = others.text.textAndPosition(nsRange: matchTwoOrFour.range(at: 3))
            let sourceLine = others.text.textAndPosition(nsRange: matchTwoOrFour.range(at: 4))

            let stackFrame = StackFrame(number: number.text,
                                        binaryName: binaryName.text,
                                        address: address.text,
                                        functionName: functionName.text,
                                        offset: offset.text,
                                        sourceName: sourceName?.text,
                                        sourceLine: sourceLine?.text)
            let stackFramePositions = StackFramePositions(number: Position(line: lineIndex, startColumn: number.start, endColumn: number.end),
                                                          binaryName: Position(line: lineIndex, startColumn: binaryName.start, endColumn: binaryName.end),
                                                          address: Position(line: lineIndex, startColumn: address.start, endColumn: address.end),
                                                          functionName: Position(line: lineIndex, startColumn: functionName.start + others.start, endColumn: functionName.end + others.start),
                                                          offset: Position(line: lineIndex, startColumn: offset.start + others.start, endColumn: offset.end + others.start),
                                                          sourceName: sourceName.map { Position(line: lineIndex, startColumn: $0.start + others.start, endColumn: $0.end + others.start) } ?? Position(line: lineIndex, column: line.count),
                                                          sourceLine: sourceLine.map { Position(line: lineIndex, startColumn: $0.start + others.start, endColumn: $0.end + others.start) } ?? Position(line: lineIndex, column: line.count))
            return (stackFrame, stackFramePositions)
        }
        
        private mutating func moveToBacktrace() {
            section = .backtrace
            currentThreadBacktrace = nil
            currentThreadBacktracePositions = nil
            currentThreadName = nil
            parseBacktrace()
        }
        
        private mutating func parseBacktrace() {
            if let threadNameMatch = reThreadBacktrace1.firstMatch(in: line) { // thread name
                if let threadName = line.textAndPosition(nsRange: threadNameMatch.range(at: 1)) {
                    pushBacktrace()
                    currentThreadName = threadName.text
                }
            } else if let threadMatch = reThreadBacktrace2.firstMatch(in: line) { // thread number (with "Crashed" optinally)
                if let threadNumber = line.textAndPosition(nsRange: threadMatch.range(at: 1)) {
                    let isCrashed = threadMatch.range(at: 2).location != NSNotFound
                    let threadName = currentThreadName
                    currentThreadName = nil
                    pushBacktrace()
                    currentThreadBacktrace = ThreadBacktrace(threadNumber: threadNumber.text,
                                                             threadName: threadName,
                                                             isCrashed: isCrashed,
                                                             stackFrames: [])
                    currentThreadBacktracePositions = ThreadBacktracePositions()
                }
            } else if let (stackFrame, stackFramePosition) = parseStackFrameLine() {
                currentThreadBacktrace?.stackFrames.append(stackFrame)
                currentThreadBacktracePositions?.stackFrames.append(stackFramePosition)
            } else if isCrashedThreadState() {
                pushBacktrace()
                moveToCrashedThreadState()
            } else if line.starts(with: BinaryImagesKeys.binaryImages) {
                pushBacktrace()
                moveToBinaryImages()
            }
        }
        
        private mutating func pushBacktrace() {
            if let currentThreadBacktrace = currentThreadBacktrace {
                content.backtraces.append(currentThreadBacktrace)
            }
            currentThreadBacktrace = nil
            if let currentThreadBacktracePositions = currentThreadBacktracePositions {
                positions.backtraces.append(currentThreadBacktracePositions)
            }
            currentThreadBacktracePositions = nil
        }
        
        // MARK: Crashed Thread State
        
        private let reCrashedThreadState = try! NSRegularExpression(pattern: #"^Thread [0-9]+ crashed with .*Thread State.*"#, options: [])
        
        private func isCrashedThreadState() -> Bool {
            return reCrashedThreadState.firstMatch(in: line) != nil
        }
        
        private mutating func moveToCrashedThreadState() {
            section = .crashedThreadState
            parseCrashedThreadState()
        }
        
        private mutating func parseCrashedThreadState() {
            if line.starts(with: BinaryImagesKeys.binaryImages) {
                moveToBinaryImages()
            }
        }
        
        // MARK: Binary Images
        
        let reBinaryImage = try! NSRegularExpression(pattern: #"(0x[0-9a-f]+)\s+-\s+(0x[0-9a-f]+)\s+(\S.*)\s+(\S+)\s+<([0-9a-f]+)>\s+(\S.*)"#, options: [])

        private mutating func moveToBinaryImages() {
            section = .binaryImages
            parseBinaryImages()
        }
        
        private mutating func parseBinaryImages() {
            guard let match = reBinaryImage.firstMatch(in: line) else { return }

            guard let loadAddress = line.textAndPosition(nsRange: match.range(at: 1)) else { return }
            guard let endAddress = line.textAndPosition(nsRange: match.range(at: 2)) else { return }
            guard let binaryName = line.textAndPosition(nsRange: match.range(at: 3)) else { return }
            guard let architecture = line.textAndPosition(nsRange: match.range(at: 4)) else { return }
            guard let buildUUID = line.textAndPosition(nsRange: match.range(at: 5)) else { return }
            guard let binaryPath = line.textAndPosition(nsRange: match.range(at: 6)) else { return }

            let binaryImage = BinaryImageEntry(loadAddress: loadAddress.text,
                                               endAddress: endAddress.text,
                                               binaryName: binaryName.text,
                                               architecture: architecture.text,
                                               buildUUID: buildUUID.text,
                                               binaryPath: binaryPath.text)
            content.binaryImages.append(binaryImage)
        }
        
        // MARK: Commonly used functions
        
        private func parseKeyValueLine() -> (key: String, value: String, valuePosition: Position)? {
            guard let delimiterIndex = line.firstIndex(of: ":") else { return nil }
            let key = line[line.startIndex ..< delimiterIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            let secondPart = line[line.index(after: delimiterIndex)...]
            if let valueStartIndex = secondPart.firstIndex(where: { !$0.isWhitespace }) {
                let valueEndIndex = secondPart.lastIndex(where: { !$0.isWhitespace })!
                let value = String(line[valueStartIndex ... valueEndIndex])
                let startColumn = line.distance(from: line.startIndex, to: valueStartIndex)
                let endColumn = line.distance(from: line.startIndex, to: valueEndIndex) + 1
                return (key: key, value: value, valuePosition: Position(line: lineIndex, startColumn: startColumn, endColumn: endColumn))
            } else {
                return (key: key, value: "", valuePosition: Position(line: lineIndex, column: line.count))
            }
        }
    }
}

private extension String {
    var wholeNSRange: NSRange {
        return NSRange(self.startIndex ..< self.endIndex, in: self)
    }
    
    func textAndPosition(nsRange: NSRange) -> (text: String, start: Int, end: Int)? {
        guard let range = Range(nsRange, in: self) else { return nil }
        let text = String(self[range])
        let start = distance(from: startIndex, to: range.lowerBound)
        let end = distance(from: startIndex, to: range.upperBound)
        return (text: text, start: start, end: end)
    }
}

private extension NSRegularExpression {
    func firstMatch(in str: String) -> NSTextCheckingResult? {
        return self.firstMatch(in: str, range: str.wholeNSRange)
    }
}
