//
// CrashReportContent.swift
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

// MARK: - CrashReportContent

/// Content of a crash report.
public struct CrashReportContent {
    /// Header.
    public var header: Header = .init()
    
    /// Exception information.
    public var exceptionInformation: ExceptionInformation = .init()
    
    /// Exception backtrace, if exists.
    public var exceptionBacktrace: ExceptionBacktrace? = nil
    
    /// Backtrace of each thread.
    public var backtraces: [ThreadBacktrace] = []
    
    /// Binary images.
    public var binaryImages: [BinaryImageEntry] = []

    public init(header: Header = .init(), exceptionInformation: ExceptionInformation = .init(), exceptionBacktrace: ExceptionBacktrace? = nil, backtraces: [ThreadBacktrace] = [], binaryImages: [BinaryImageEntry] = []) {
        self.header = header
        self.exceptionInformation = exceptionInformation
        self.exceptionBacktrace = exceptionBacktrace
        self.backtraces = backtraces
        self.binaryImages = binaryImages
    }
}

// MARK: - Header

/// Header part of crash report.
/// It describes the environment the crash occurred in.
public struct Header {
    /// A unique identifier for the report.
    /// Two reports never share the same Incident Identifier.
    public var incidentIdentifier: String? = nil
    
    /// An anonymized per-device identifier. Two reports from the same device contain identical values.
    /// This identifier is reset upon erasing the device.
    public var crashReporterKey: String? = nil
    
    /// A unique identifier for the combination of the device and vendor of the crashed application.
    /// Two reports for apps from the same vendor and from the same device contain identical values.
    /// This field is only present for TestFlight builds of an app, and replaces the CrashReporter Key field.
    public var betaIdentifier: String? = nil
    
    /// The specific device model the app was running on.
    public var hardwareModel: String? = nil
    
    /// The executable name for the process that crashed.
    /// This matches the CFBundleExecutable value in the app's information property list.
    /// The number in brackets is the process ID.
    public var process: String? = nil
    
    /// The location of the executable on disk. macOS replaces user-identifable path components
    /// with placeholder values to protect privacy.
    public var path: String? = nil
    
    /// The CFBundleIdentifier of the process that crashed.
    /// If the binary doesn't have a CFBundleIdentifier,
    /// this field contains either the process name or a placeholder value.
    public var identifier: String? = nil
    
    /// The version of the process that crashed.
    /// The value is a concatenation of the app's CFBundleVersion and CFBundleShortVersionString.
    public var version: String? = nil
    
    /// The version of Xcode used to compile your app's bitcode and to thin your app to device specific variants.
    public var appStoreTools: String? = nil
    
    /// The specific variant of your app produced by app thinning.
    /// This field contains multiple values, described later in this section.
    public var appVariant: String? = nil
    
    /// The CPU architecture of the process that crashed. The value is one of ARM-64, ARM, X86-64, or X86.
    public var codeType: String? = nil
    
    /// The task_role assigned to the process at the time of termination.
    /// This field is generally not helpful when you analyze a crash report.
    public var role: String? = nil
    
    /// The name and process ID (in square brackets) of the process that launched the crashed process.
    public var parentProcess: String? = nil
    
    /// The name of the process coalition containing the app.
    /// Process coalitions track resource usage among groups of related processes,
    /// such as an operating system process supporting a specific API's functionality in an app.
    /// Most processes, including app extensions, form their own coalition.
    public var coalition: String? = nil
    
    /// The date and time of the crash.
    public var dateTime: String? = nil
    
    /// The date and time the app launched.
    public var launchTime: String? = nil
    
    /// The operating system version, including the build number, on which the crash occurred.
    public var osVersion: String? = nil
    
    public init(incidentIdentifier: String? = nil, crashReporterKey: String? = nil, betaIdentifier: String? = nil, hardwareModel: String? = nil, process: String? = nil, path: String? = nil, identifier: String? = nil, version: String? = nil, appStoreTools: String? = nil, appVariant: String? = nil, codeType: String? = nil, role: String? = nil, parentProcess: String? = nil, coalition: String? = nil, dateTime: String? = nil, launchTime: String? = nil, osVersion: String? = nil) {
        self.incidentIdentifier = incidentIdentifier
        self.crashReporterKey = crashReporterKey
        self.betaIdentifier = betaIdentifier
        self.hardwareModel = hardwareModel
        self.process = process
        self.path = path
        self.identifier = identifier
        self.version = version
        self.appStoreTools = appStoreTools
        self.appVariant = appVariant
        self.codeType = codeType
        self.role = role
        self.parentProcess = parentProcess
        self.coalition = coalition
        self.dateTime = dateTime
        self.launchTime = launchTime
        self.osVersion = osVersion
    }
}

// MARK: - ExceptionInformation

/// Exception information part of crash report.
/// This section tells you how the process terminated.
public struct ExceptionInformation {
    /// The name of the Mach exception that terminated the process,
    /// along with the name of the corresponding BSD termination signal in parentheses.
    public var exceptionType: String? = nil
    
    /// Processor specific information about the exception encoded
    /// into one or more 64-bit hexadecimal numbers.
    public var exceptionCodes: String? = nil
    
    /// The human-readable description of the exception codes.
    public var exceptionSubtype: String? = nil
    
    /// Additional information that isn't specific to one exception type.
    public var exceptionNote: String? = nil
    
    /// Exit reason information specified when the operating system terminates a process.
    public var terminationReason: String? = nil
    
    /// The thread on which the exception originated.
    public var triggeredByThread: String? = nil
    
    /// The thread on which the exception originated.
    public var crashedThread: String? = nil
    
    public init(exceptionType: String? = nil, exceptionCodes: String? = nil, exceptionSubtype: String? = nil, exceptionNote: String? = nil, terminationReason: String? = nil, triggeredByThread: String? = nil, crashedThread: String? = nil) {
        self.exceptionType = exceptionType
        self.exceptionCodes = exceptionCodes
        self.exceptionSubtype = exceptionSubtype
        self.exceptionNote = exceptionNote
        self.terminationReason = terminationReason
        self.triggeredByThread = triggeredByThread
        self.crashedThread = crashedThread
    }
}

// MARK: - ExceptionBacktrace

/// Exception backtrace.
public enum ExceptionBacktrace {
    /// Symbolicated exception backtrace.
    case symbolicated([StackFrame])
    
    /// Non-symbolicated exception backtrace. This contains addresses.
    case nonSymbolicated([String])
}

// MARK: - ThreadBacktrace

/// Backtrace of each thread.
public struct ThreadBacktrace {
    /// Thread number.
    public var threadNumber: String
    
    /// Thread name.
    public var threadName: String?
    
    /// Whether the crash occurred on this thread or not.
    public var isCrashed: Bool
    
    /// Stack frame.
    public var stackFrames: [StackFrame]

    public init(threadNumber: String, threadName: String? = nil, isCrashed: Bool, stackFrames: [StackFrame]) {
        self.threadNumber = threadNumber
        self.threadName = threadName
        self.isCrashed = isCrashed
        self.stackFrames = stackFrames
    }
}

// MARK: - StackFrame

/// Stack frame.
public struct StackFrame {
    /// Stack frame number.
    public var number: String
    
    /// Name of the binary.
    public var binaryName: String
    
    /// Address.
    public var address: String
    
    /// Function name.
    public var functionName: String
    
    /// Byte offset from the function's entry point.
    public var offset: String?
    
    /// Source file name, or nil for unavailable.
    public var sourceName: String?
    
    /// Line number for a source file.
    /// `"0"` means the backtrace doesn't map to a specific line of code in the original code.
    public var sourceLine: String?
    
    public init(number: String, binaryName: String, address: String, functionName: String, offset: String?, sourceName: String? = nil, sourceLine: String? = nil) {
        self.number = number
        self.binaryName = binaryName
        self.address = address
        self.functionName = functionName
        self.offset = offset
        self.sourceName = sourceName
        self.sourceLine = sourceLine
    }
}

// MARK: - BinaryImageEntry

/// Each binary image entry.
public struct BinaryImageEntry {
    /// Load address.
    public var loadAddress: String
    
    /// End of loaded addresss.
    public var endAddress: String
    
    /// Binary name.
    public var binaryName: String
    
    /// CPU architecture.
    public var architecture: String
    
    /// Build UUID that uniquely identifies the binary image.
    public var buildUUID: String
    
    /// Path to the binary.
    public var binaryPath: String
    
    public init(loadAddress: String, endAddress: String, binaryName: String, architecture: String, buildUUID: String, binaryPath: String) {
        self.loadAddress = loadAddress
        self.endAddress = endAddress
        self.binaryName = binaryName
        self.architecture = architecture
        self.buildUUID = buildUUID
        self.binaryPath = binaryPath
    }
}
