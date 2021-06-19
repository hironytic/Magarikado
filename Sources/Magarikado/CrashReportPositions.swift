//
// CrashReportPositions.swift
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

/// Positions of each crash report content.
public struct CrashReportPositions {
    /// Positions of exception backtrace, if exists.
    public var exceptionBacktrace: Position? = nil
    
    /// Positions of backtrace of each thread.
    public var backtraces: [ThreadBacktracePositions] = []
}

/// Positions of a backtrace of each thread.
public struct ThreadBacktracePositions {
    /// Positons of stack frames.
    public var stackFrames: [StackFramePositions] = []
}

/// Positions of a stack frame.
public struct StackFramePositions {
    /// Position of stack frame number.
    public var number: Position
    
    /// Position of name of the binary.
    public var binaryName: Position
    
    /// Position of address.
    public var address: Position
    
    /// Position of function name.
    public var functionName: Position
    
    /// Position of byte offset from the function's entry point.
    public var offset: Position
    
    /// Position of source file name, or nil for unavailable.
    public var sourceName: Position
    
    /// Position of line number for a source file.
    public var sourceLine: Position
}
