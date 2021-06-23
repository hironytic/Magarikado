//
// BinaryImageFileProvider.swift
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

/// A protocol to which object that provides binary image file conforms.
public protocol BinaryImageFileProvider {
    /// Provide a url of binary image file which matches to specified entry.
    /// - Parameter entry: Which binary image to provide.
    func provideBinaryImageFile(for entry: BinaryImageEntry) throws -> URL?
}

private let reUUID = try! NSRegularExpression(pattern: #"uuid ([^\s]+)\s"#, options: [])

/// Return build UUID for specified binary image file.
/// - Parameters:
///   - file: Binary iamge file.
///   - architecture: Architecture, such as `"arm64"`.
/// - Throws: `MagarikadoError.externalCommandFailed` when failed to run otool.
/// - Returns: Build UUID, or `nil` if not found.
public func buildUUID(for file: URL, architecture: String) throws -> String? {
    let arguments = [
        "otool",
        "-arch",
        architecture,
        "-l",
        file.path,
    ]

    let (status, stdout, _ /*stderr*/) = Utility.runCommand(path: "/usr/bin/xcrun", arguments: arguments)
    guard status == 0 else { return nil }

    guard let match = reUUID.firstMatch(in: stdout, range: NSRange(stdout.startIndex ..< stdout.endIndex, in: stdout)) else { return nil }
    return String(stdout[Range(match.range(at: 1), in: stdout)!])
        .replacingOccurrences(of: "-", with: "")
        .lowercased()
}

// This object provides system binary image file.
public struct SystemBinaryImageFileProvider: BinaryImageFileProvider {
    private var folders: [URL]
    private class Cache {
        var uuidToURL: [String: URL?] = [:]
    }
    private var cache = Cache()
    
    /// Initialize with Xcode's "iOS DeviceSupport" folders.
    public init() {
        let fm = FileManager.default
        let deviceSupportDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Developer/Xcode/iOS DeviceSupport")
        
        folders = ((try? fm.contentsOfDirectory(at: deviceSupportDir, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? [])
            .map { $0.appendingPathComponent("Symbols")}
    }
    
    /// Initialize with specified folders.
    /// - Parameter folders: Folders to search for system binary image file.
    public init(folders: [URL]) {
        self.folders = folders
    }

    public func provideBinaryImageFile(for entry: BinaryImageEntry) throws -> URL? {
        let cacheKey = entry.buildUUID + ":" + entry.architecture
        if let url = cache.uuidToURL[cacheKey] {
            return url
        }

        let fm = FileManager.default
        let binaryPath: String
        if entry.binaryPath.starts(with: "/") {
            binaryPath = String(entry.binaryPath[entry.binaryPath.index(after: entry.binaryPath.startIndex)...])
        } else {
            binaryPath = entry.binaryPath
        }
        
        for folder in folders {
            let file = folder.appendingPathComponent(binaryPath)
            guard fm.fileExists(atPath: file.path) else { continue }
            
            guard let buildUUID = try buildUUID(for: file, architecture: entry.architecture) else { continue }
            if entry.buildUUID == buildUUID {
                cache.uuidToURL[cacheKey] = .some(.some(file))
                return file
            }
        }
        
        cache.uuidToURL[cacheKey] = .some(.none)
        return nil
    }
}

/// This object provides binary image file in dSYM file.
public struct DSYMBinaryImageFileProvider: BinaryImageFileProvider {
    private var binaryImageFiles: [URL]
    private class Cache {
        var uuidToURL: [String: URL?] = [:]
    }
    private var cache = Cache()
    
    /// Initialize with dSYM file.
    /// - Parameter dSYM: URL of dSYM file.
    public init(dSYM: URL) {
        let fm = FileManager.default
        let dwarfFolder = dSYM.appendingPathComponent("Contents/Resources/DWARF")
        binaryImageFiles = ((try? fm.contentsOfDirectory(at: dwarfFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)) ?? [])
    }
    
    public func provideBinaryImageFile(for entry: BinaryImageEntry) throws -> URL? {
        let cacheKey = entry.buildUUID + ":" + entry.architecture
        if let url = cache.uuidToURL[cacheKey] {
            return url
        }
        
        for file in binaryImageFiles {
            guard let buildUUID = try buildUUID(for: file, architecture: entry.architecture) else { continue }
            if entry.buildUUID == buildUUID {
                cache.uuidToURL[cacheKey] = .some(.some(file))
                return file
            }
        }
        
        cache.uuidToURL[cacheKey] = .some(.none)
        return nil
    }
}

/// This object chains multiple `BinaryImageFileProvider`s.
public struct BinaryImageFileProviderChain: BinaryImageFileProvider {
    private var providers: [BinaryImageFileProvider]
    
    /// Initialize.
    /// - Parameter providers: Providers.
    public init(providers: [BinaryImageFileProvider]) {
        self.providers = providers
    }
    
    public func provideBinaryImageFile(for entry: BinaryImageEntry) throws -> URL? {
        for provider in providers {
            if let url = try provider.provideBinaryImageFile(for: entry) {
                return url
            }
        }
        return nil
    }
}
