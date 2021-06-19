//
// TextRewriterTests.swift
// MagarikadoTests
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
import XCTest
@testable import Magarikado

final class TextRewriterTests: XCTestCase {
    func testReplaceNullRangeWithZeroLine() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst"])
        try rewriter.addMark(at: Position(line: 0, column: 3), newTextLines: [])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcdefghij", "klmnopqrst"])
    }

    func testReplaceNullRangeWithOneEmptyLine() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst"])
        try rewriter.addMark(at: Position(line: 0, column: 3), newTextLines: [""])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcdefghij", "klmnopqrst"])
    }

    func testReplaceNullRangeWithOneLine() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst"])
        try rewriter.addMark(at: Position(line: 0, column: 3), newTextLines: ["LINE1"])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcLINE1defghij", "klmnopqrst"])
    }
    
    func testReplaceNullRangeWithTwoLines() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst"])
        try rewriter.addMark(at: Position(line: 0, column: 3), newTextLines: ["LINE1", "LINE2"])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcLINE1", "LINE2defghij", "klmnopqrst"])
    }

    func testReplaceNullEmptyRangeWithZeroLine() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", ""])
        try rewriter.addMark(at: Position(line: 1, column: 0), newTextLines: [])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcdefghij", ""])
    }

    func testReplaceNullEmptyRangeWithOneEmptyLine() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", ""])
        try rewriter.addMark(at: Position(line: 1, column: 0), newTextLines: [""])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcdefghij", ""])
    }

    func testReplaceNullEmptyRangeWithTwoEmptyLines() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", ""])
        try rewriter.addMark(at: Position(line: 1, column: 0), newTextLines: ["", ""])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcdefghij", "", ""])
    }

    func testReplaceRangeOnOneLineWithZeroLine() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst"])
        try rewriter.addMark(at: Position(line: 0, startColumn: 3, endColumn: 6), newTextLines: [])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcghij", "klmnopqrst"])
    }

    func testReplaceRangeOnOneLineWithOneEmptyLine() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst"])
        try rewriter.addMark(at: Position(line: 0, startColumn: 3, endColumn: 6), newTextLines: [""])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcghij", "klmnopqrst"])
    }

    func testReplaceRangeOnOneLineWithOneLine() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst"])
        try rewriter.addMark(at: Position(line: 0, startColumn: 3, endColumn: 6), newTextLines: ["LINE1"])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcLINE1ghij", "klmnopqrst"])
    }

    func testReplaceRangeOnOneLineWithTwoLines() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst"])
        try rewriter.addMark(at: Position(line: 0, startColumn: 3, endColumn: 6), newTextLines: ["LINE1", "LINE2"])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcLINE1", "LINE2ghij", "klmnopqrst"])
    }

    func testReplaceRangeOnTwoLinesWithZeroLine() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst"])
        try rewriter.addMark(at: Position(startLine: 0, startColumn: 3, endLine: 1, endColumn: 6), newTextLines: [])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcqrst"])
    }

    func testReplaceRangeOnTwoLinesWithOneEmptyLine() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst"])
        try rewriter.addMark(at: Position(startLine: 0, startColumn: 3, endLine: 1, endColumn: 6), newTextLines: [""])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abc", "qrst"])
    }
    
    func testReplaceRangeOnTwoLinesWithOneLine() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst"])
        try rewriter.addMark(at: Position(startLine: 0, startColumn: 3, endLine: 1, endColumn: 6), newTextLines: ["LINE1"])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcLINE1", "qrst"])
    }
    
    func testReplaceRangeOnTwoLinesWithTwoLines() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst"])
        try rewriter.addMark(at: Position(startLine: 0, startColumn: 3, endLine: 1, endColumn: 6), newTextLines: ["LINE1", "LINE2"])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcLINE1", "LINE2qrst"])
    }

    func testReplaceRangeOnTwoLinesWithThreeLines() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst"])
        try rewriter.addMark(at: Position(startLine: 0, startColumn: 3, endLine: 1, endColumn: 6), newTextLines: ["LINE1", "LINE2", "LINE3"])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcLINE1", "LINE2", "LINE3qrst"])
    }
    
    func testReplaceRangeOnThreeLinesWithZeroLine() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst", "uvwxyz"])
        try rewriter.addMark(at: Position(startLine: 0, startColumn: 3, endLine: 2, endColumn: 2), newTextLines: [])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcwxyz"])
    }
    
    func testReplaceRangeOnThreeLinesWithOneEmptyLine() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst", "uvwxyz"])
        try rewriter.addMark(at: Position(startLine: 0, startColumn: 3, endLine: 2, endColumn: 2), newTextLines: [""])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abc", "wxyz"])
    }

    func testReplaceRangeOnThreeLinesWithOneLine() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst", "uvwxyz"])
        try rewriter.addMark(at: Position(startLine: 0, startColumn: 3, endLine: 2, endColumn: 2), newTextLines: ["LINE1"])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcLINE1", "wxyz"])
    }

    func testReplaceRangeOnThreeLinesWithTwoLines() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst", "uvwxyz"])
        try rewriter.addMark(at: Position(startLine: 0, startColumn: 3, endLine: 2, endColumn: 2), newTextLines: ["LINE1", "LINE2"])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcLINE1", "LINE2wxyz"])
    }

    func testReplaceRangeOnThreeLinesWithThreeLines() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst", "uvwxyz"])
        try rewriter.addMark(at: Position(startLine: 0, startColumn: 3, endLine: 2, endColumn: 2), newTextLines: ["LINE1", "LINE2", "LINE3"])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcLINE1", "LINE2", "LINE3wxyz"])
    }

    func testReplaceRangeOnThreeLinesWithFourLines() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst", "uvwxyz"])
        try rewriter.addMark(at: Position(startLine: 0, startColumn: 3, endLine: 2, endColumn: 2), newTextLines: ["LINE1", "LINE2", "LINE3", "LINE4"])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abcLINE1", "LINE2", "LINE3", "LINE4wxyz"])
    }
    
    func testAddMultipleMarkOnOneLine() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst"])
        try rewriter.addMark(at: Position(line: 0, startColumn: 2, endColumn: 5), newTextLines: ["REP1"])
        try rewriter.addMark(at: Position(line: 0, startColumn: 5, endColumn: 7), newTextLines: ["REP2"])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abREP1REP2hij", "klmnopqrst"])
    }
    
    func testAddMultipleMark() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst"])
        try rewriter.addMark(at: Position(line: 0, startColumn: 2, endColumn: 5), newTextLines: ["REP1"])
        try rewriter.addMark(at: Position(line: 1, startColumn: 5, endColumn: 7), newTextLines: ["REP2"])
        let result = rewriter.rewrite()
        XCTAssertEqual(result, ["abREP1fghij", "klmnoREP2rst"])
    }
    
    func testErrorOnOverlappedPosition1() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst"])
        try rewriter.addMark(at: Position(line: 0, startColumn: 2, endColumn: 5), newTextLines: ["REP1"])
        XCTAssertThrowsError(try rewriter.addMark(at: Position(line: 0, startColumn: 4, endColumn: 7), newTextLines: ["REP2"]))
    }

    func testErrorOnOverlappedPosition2() throws {
        var rewriter = TextRewriter(lines: ["abcdefghij", "klmnopqrst"])
        try rewriter.addMark(at: Position(line: 0, startColumn: 4, endColumn: 7), newTextLines: ["REP2"])
        XCTAssertThrowsError(try rewriter.addMark(at: Position(line: 0, startColumn: 2, endColumn: 5), newTextLines: ["REP1"]))
    }
}
