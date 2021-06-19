//
// MagarikadoError.swift
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

/// Error thrown in Magarikado.
public enum MagarikadoError: Error {
    /// Failed to load file.
    /// The 0th associated value is a url of the file.
    /// The 1th associated value is an error which occured on loading.
    case fileLoadError(url: URL, error: Error)
    
    /// Invalid carsh report format.
    case formatError
    
    /// Failed to execute external command, or it resulted an error.
    /// The 0th associated value is name of the command.
    /// The 1st associated value is error message.
    case externalCommandFailed(String, String)
    
    /// Failed to parse address string.
    /// The associated value is the address string.
    case invalidAddress(String)
    
    /// There are overlapped marked positions in ``TextReqriter``.
    case markedPositionOverlapped
}

extension MagarikadoError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .fileLoadError(url: let url, error: _):
            return "Failed to load file: \(url)"
        case .formatError:
            return "Invalid crash report:"
        case .externalCommandFailed(let command, let message):
            return "Error in executing \(command): \(message)"
        case .invalidAddress(let addr):
            return "Invalid address found: \(addr)"
        case .markedPositionOverlapped:
            return "There are overlapped marked positions"
        }
    }
}
