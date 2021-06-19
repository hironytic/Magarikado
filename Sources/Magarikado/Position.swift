//
// Position.swift
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

/// Range of a text in crash report.
public struct Position: CustomDebugStringConvertible {
    /// Line index at which text starts.
    public var startLine: Int
    
    /// Column index at which text starts on a line indicated with ``startLine``.
    public var startColumn: Int
    
    /// Line index at which text ends.
    public var endLine: Int
    
    /// Column index at which text ends on a line indicated with ``endLine``.
    /// Note that the text doesn't contain a character at this index itself. The text ends before this index.
    public var endColumn: Int
    
    /// Initialize a range.
    /// - Parameters:
    ///   - startLine: Start line.
    ///   - startColumn: Start column on the start line.
    ///   - endLine: End line.
    ///   - endColumn: End column on the end line. (exclusive)
    public init(startLine: Int, startColumn: Int, endLine: Int, endColumn: Int) {
        self.startLine = startLine
        self.startColumn = startColumn
        self.endLine = endLine
        self.endColumn = endColumn
    }
    
    /// Initialize a range which is located in one line.
    /// - Parameters:
    ///   - line: Line.
    ///   - startColumn: Start column on the line.
    ///   - endColumn: End column on the line. (exclusive)
    public init(line: Int, startColumn: Int, endColumn: Int) {
        self.init(startLine: line, startColumn: startColumn, endLine: line, endColumn: endColumn)
    }
    
    /// Initialzie a range which has no length.
    /// - Parameters:
    ///   - line: Line.
    ///   - column: Column on the line.
    public init(line: Int, column: Int) {
        self.init(startLine: line, startColumn: column, endLine: line, endColumn: column)
    }
    
    public var debugDescription: String {
        if startLine == endLine {
            if startColumn == endColumn {
                return "\(startLine):\(startColumn)"
            } else {
                return "\(startLine):\(startColumn)-\(endColumn)"
            }
        } else {
            return "\(startLine):\(startColumn)-\(endLine):\(endColumn)"
        }
    }
}
