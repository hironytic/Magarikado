//
// TextRewriter.swift
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

// Utility for rewriting text lines.
public struct TextRewriter {
    private var lines: [String]
    private var marks: [Mark] = [] // marks are sorted in ascending order by position
 
    private struct Mark {
        var position: Position
        var newTextLines: [String]
    }
        
    /// Initialize object with text lines to rewrite.
    /// - Parameter lines: Text lines to rewrite.
    public init(lines: [String]) {
        self.lines = lines
    }
    
    /// Add a rewriting mark.
    /// - Parameters:
    ///   - position: position
    ///   - newText: new text
    /// - Throws: Throws ``TextRewriterError.positionOverlapped`` when the position is overlapped to existing one.
    public mutating func addMark(at position: Position, newText: String) throws {
        let newTextLines = newText
            .replacingOccurrences(of: "\r", with: "")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0) }
        try addMark(at: position, newTextLines: newTextLines)
    }
    
    /// Add a rewriting mark.
    /// - Parameters:
    ///   - position: position
    ///   - newText: lines of new text
    /// - Throws: Throws ``TextRewriterError.positionOverlapped`` when the position is overlapped to existing one.
    public mutating func addMark(at position: Position, newTextLines: [String]) throws {
        let (_, index) = Utility.binarySearch(startIndex: marks.startIndex, endIndex: marks.endIndex) { index in
            let mark = marks[index]
            let lineComp = mark.position.startLine - position.startLine
            if lineComp == 0 {
                return mark.position.startColumn - position.startColumn
            } else {
                return lineComp
            }
        }
        
        // check if overlapping with previous range
        if index - 1 >= marks.startIndex {
            if marks[index - 1].position.endLine > position.startLine
                || (marks[index - 1].position.endLine == position.startLine && marks[index - 1].position.endColumn > position.startColumn) {
                throw MagarikadoError.markedPositionOverlapped
            }
        }
        
        // check if overlapping with next range
        if index < marks.endIndex {
            if marks[index].position.startLine < position.endLine
                || (marks[index].position.startLine == position.endLine && marks[index].position.startColumn < position.endColumn) {
                throw MagarikadoError.markedPositionOverlapped
            }
        }
    
        marks.insert(Mark(position: position, newTextLines: newTextLines), at: index)
    }
    
    /// Rewrite text lines.
    /// - Returns: Rewriiten lines.
    public func rewrite() -> [String] {
        var lines = self.lines
        for mark in marks.reversed() {
            let newTextLinesCount = mark.newTextLines.count
            if mark.position.startLine == mark.position.endLine {
                switch newTextLinesCount {
                case 0:
                    var targetLine = lines[mark.position.startLine]
                    targetLine.removeSubrange(targetLine.index(targetLine.startIndex, offsetBy: mark.position.startColumn) ..< targetLine.index(targetLine.startIndex, offsetBy: mark.position.endColumn))
                    lines[mark.position.startLine] = targetLine
                    break
                case 1:
                    var targetLine = lines[mark.position.startLine]
                    targetLine.replaceSubrange(targetLine.index(targetLine.startIndex, offsetBy: mark.position.startColumn) ..< targetLine.index(targetLine.startIndex, offsetBy: mark.position.endColumn),
                                               with: mark.newTextLines[0])
                    lines[mark.position.startLine] = targetLine
                default:
                    var startLine = lines[mark.position.startLine]
                    var endLine = startLine
                    
                    startLine.replaceSubrange(startLine.index(startLine.startIndex, offsetBy: mark.position.startColumn) ..< startLine.endIndex,
                                              with: mark.newTextLines[0])
                    endLine.replaceSubrange(endLine.startIndex ..< endLine.index(endLine.startIndex, offsetBy: mark.position.endColumn),
                                            with: mark.newTextLines[mark.newTextLines.count - 1])
                    lines[mark.position.startLine] = startLine
                    if newTextLinesCount > 2 {
                        lines.insert(contentsOf: mark.newTextLines[1 ..< newTextLinesCount - 1], at: mark.position.startLine + 1)
                    }
                    lines.insert(endLine, at: mark.position.startLine + newTextLinesCount - 1)
                }
            } else {
                switch newTextLinesCount {
                case 0:
                    let startLine = lines[mark.position.startLine]
                    let endLine = lines[mark.position.endLine]
                    let rewrittenLine = String(startLine[startLine.startIndex ..< startLine.index(startLine.startIndex, offsetBy: mark.position.startColumn)])
                        + String(endLine[endLine.index(endLine.startIndex, offsetBy: mark.position.endColumn)...])
                    lines[mark.position.startLine] = rewrittenLine
                    if mark.position.startLine + 1 <= mark.position.endLine {
                        lines.removeSubrange(mark.position.startLine + 1 ... mark.position.endLine)
                    }
                case 1:
                    let startLine = lines[mark.position.startLine]
                    let endLine = lines[mark.position.endLine]
                    let rewrittenStartLine = String(startLine[startLine.startIndex ..< startLine.index(startLine.startIndex, offsetBy: mark.position.startColumn)])
                        + mark.newTextLines[0]
                    lines[mark.position.startLine] = rewrittenStartLine
                    let rewrittenEndLine = String(endLine[endLine.index(endLine.startIndex, offsetBy: mark.position.endColumn)...])
                    if mark.position.endColumn != 0 && rewrittenEndLine.isEmpty {
                        lines.remove(at: mark.position.endLine)
                    } else {
                        lines[mark.position.endLine] = rewrittenEndLine
                    }
                    if mark.position.startLine + 1 < mark.position.endLine {
                        lines.removeSubrange(mark.position.startLine + 1 ..< mark.position.endLine)
                    }
                default:
                    let startLine = lines[mark.position.startLine]
                    let endLine = lines[mark.position.endLine]
                    let rewrittenStartLine = String(startLine[startLine.startIndex ..< startLine.index(startLine.startIndex, offsetBy: mark.position.startColumn)])
                        + mark.newTextLines[0]
                    lines[mark.position.startLine] = rewrittenStartLine
                    let rewrittenEndLine = mark.newTextLines[mark.newTextLines.count - 1] + String(endLine[endLine.index(endLine.startIndex, offsetBy: mark.position.endColumn)...])
                    lines[mark.position.endLine] = rewrittenEndLine
                    if mark.position.startLine + 1 < mark.position.endLine {
                        lines.removeSubrange(mark.position.startLine + 1 ..< mark.position.endLine)
                    }
                    lines.insert(contentsOf: mark.newTextLines[1 ..< mark.newTextLines.count - 1], at: mark.position.startLine + 1)
                }
            }
        }
        return lines
    }
}
