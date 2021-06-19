//
// BinaryImageEntryFinder.swift
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

/// This object searches "Binary Images" section and find ``BinaryImageEntry``.
public struct BinaryImageEntryFinder {
    private struct AddressAndIndex {
        var loadAddress: UInt64
        var endAddress: UInt64
        var index: Int
    }
    
    private var binaryImages: [BinaryImageEntry]
    private var addressTable: [AddressAndIndex]
    
    /// Initialize
    /// - Parameter binaryImages: "Binary Images" section of crash report.
    /// - Throws: `MagarikadoError.invalidAddress` if "Binary Images" contains unparsable address.
    public init(binaryImages: [BinaryImageEntry]) throws {
        self.binaryImages = binaryImages
        addressTable = try binaryImages
            .enumerated()
            .map { (index, binaryImage) in
                let loadAddress = try Utility.address(fromString: binaryImage.loadAddress)
                let endAddress = try Utility.address(fromString: binaryImage.endAddress)
                return AddressAndIndex(loadAddress: loadAddress, endAddress: endAddress, index: index)
            }
            .sorted(by: { (lhs, rhs) in lhs.loadAddress < rhs.loadAddress })
    }
    
    /// Find ``BinaryImageEntry`` of binary image loaded at specified address.
    /// - Parameter addressString: Address string
    /// - Returns: Found entry, or `nil` when not found.
    public func find(by addressString: String) -> BinaryImageEntry? {
        guard let addr = try? Utility.address(fromString: addressString) else { return nil }
        
        let (_, index) = Utility.binarySearch(startIndex: addressTable.startIndex, endIndex: addressTable.endIndex) { index in
            let loadAddress = addressTable[index].loadAddress
            if loadAddress < addr {
                return -1
            } else if loadAddress > addr {
                return 1
            } else {
                return 0
            }
        }
        let tableIndex = index - 1
        guard tableIndex >= 0 else { return nil }

        if addressTable[tableIndex].endAddress < addr {
            return nil
        }
        
        let bi = binaryImages[addressTable[tableIndex].index]
        return bi
    }    
}
