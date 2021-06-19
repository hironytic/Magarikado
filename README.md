# Magarikado

A library for handling iOS crash report file.

<h3 align="center">
<img src="crash_at_magarikado.png" width="500">
</h3>

With Magarikado, you can:

- parse iOS crash report to access specific value
- symbolicate iOS crash report to read stack traces

## Installation

### Swift Package Manager

Magarikado is available through [Swift Package Manager](https://swift.org/package-manager/).
To install it, add dependency to your `Package.swift` file like following:

```swift
import PackageDescription

let package = Package(
    name: "Hello",
    dependencies: [
        .package(url: "https://github.com/hironytic/Magarikado.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "Hello",
            dependencies: ["Magarikado"]
        ),
    ]
    ...
)
```

## Usage

Suppose you have an iOS crash report `DramaticCrash-2018-08-09-195533.ips` like this:

```
{"app_name":"DramaticCrash","timestamp":"2018-08-09 19:55:33.64 +0900","app_version":"1.0","slice_uuid":"fcbd7e2d-0452-3c2a-8356-98b0bf29e71f","adam_id":0,"build_version":"1","bundleID":"com.hironytic.DramaticCrash","share_with_app_devs":true,"is_first_party":false,"bug_type":"109","os_version":"iPhone OS 11.4.1 (15G77)","incident_id":"FF62C474-CB63-4EE3-B40F-A66BDC5E6DDB","name":"DramaticCrash"}
Incident Identifier: FF62C474-CB63-4EE3-B40F-A66BDC5E6DDB
CrashReporter Key:   ed6a9d055387ef07eabb7022c33839b0c1eeab9f
Hardware Model:      iPod7,1
Process:             DramaticCrash [290]
Path:                /private/var/containers/Bundle/Application/7F9CA838-47AB-4DB1-AECB-CF2EC9E21AC0/DramaticCrash.app/DramaticCrash
Identifier:          com.hironytic.DramaticCrash
Version:             1 (1.0)

...snip...

Thread 0 name:  Dispatch queue: com.apple.main-thread
Thread 0 Crashed:
0   DramaticCrash                 	0x0000000100c8d708 0x100c88000 + 22280
1   DramaticCrash                 	0x0000000100c8d668 0x100c88000 + 22120
2   DramaticCrash                 	0x0000000100c8c2bc 0x100c88000 + 17084
3   UIKit                         	0x000000018ddb30cc 0x18dc9f000 + 1130700
4   UIKit                         	0x000000018ddb2d84 0x18dc9f000 + 1129860
5   UIKit                         	0x000000018ddb1aa0 0x18dc9f000 + 1125024
6   UIKit                         	0x000000018ddad5ec 0x18dc9f000 + 1107436
7   UIKit                         	0x000000018dcea6f4 0x18dc9f000 + 308980

...snip...
```

### Parsing iOS crash report

You can parse it and access to its values in your code.

```swift
import Magarikado

let file = URL(fileURLWithPath: "/path/to/DramaticCrash-2018-08-09-195533.ips")
let crashReport = try CrashReport(file: file)

let content = crashReport.content
print(content.header.identifier!) // com.hironytic.DramaticCrash
print(content.backtraces[0].isCrashed) // true
print(content.backtraces[0].stackFrames[0].address) // 0x0000000100c8d708
```

### Symbolicating iOS crash report

On macOS with Xcode Command Line Tools installed, you can symbolicate it.

```swift
import Magarikado

let file = URL(fileURLWithPath: "/path/to/DramaticCrash-2018-08-09-195533.ips")
let crashReport = try CrashReport(file: file)

let fileProvider = BinaryImageFileProviderChain(providers: [
    DSYMBinaryImageFileProvider(dSYM: URL(fileURLWithPath: "/path/to/DramaticCrash.app.dSYM")),
    SystemBinaryImageFileProvider(),
])
let outFile = URL(fileURLWithPath: "/path/to/output.txt")
try crashReport.symbolicateAsFile(fileProvider: fileProvider, outFile: outFile)
```

The content of `output.txt` may be like this:

```
...snip...

Thread 0 name:  Dispatch queue: com.apple.main-thread
Thread 0 Crashed:
0   DramaticCrash                 	0x0000000100c8d708 specialized ViewController.tableView(_:cellForRowAt:) (ViewController.swift:63)
1   DramaticCrash                 	0x0000000100c8d668 specialized ViewController.tableView(_:cellForRowAt:) (ViewController.swift:63)
2   DramaticCrash                 	0x0000000100c8c2bc @objc ViewController.tableView(_:cellForRowAt:) (ViewController.swift:61)
3   UIKit                         	0x000000018ddb30cc -[UITableView _createPreparedCellForGlobalRow:withIndexPath:willDisplay:] + 668
4   UIKit                         	0x000000018ddb2d84 -[UITableView _createPreparedCellForGlobalRow:willDisplay:] + 80
5   UIKit                         	0x000000018ddb1aa0 -[UITableView _updateVisibleCellsNow:isRecursive:] + 2280
6   UIKit                         	0x000000018ddad5ec -[UITableView layoutSubviews] + 140
7   UIKit                         	0x000000018dcea6f4 -[UIView(CALayerDelegate) layoutSublayersOfLayer:] + 1420

...snip...
```

## Magarikado??

"Magarikado" is a Japanese word which means "corner" or "crossroad".
Sometimes at there, a school girl with toast in her mouth crashes into a boy.

## Author

Hironori Ichimiya, hiron@hironytic.com

## License

Magarikado is available under the MIT license. See the LICENSE file for more info.

