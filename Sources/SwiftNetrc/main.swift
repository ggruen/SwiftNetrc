import Darwin // Gets us "exit"
#if SWIFT_PACKAGE
import SwiftNetrcCore
#endif

enum SwiftNetrcCoreError: Error {
    case MacOsSierraRequired
}

do {
    // We need this solely for FileManager.default.homeDirectoryForCurrentUser. See if there's a Swift Standard
    // Library way to get that and/or a Linux version.
    if #available(OSX 10.12, *) {
        let tool = try SwiftNetrc()
        try tool.run()
    } else {
        print("Sorry, SwiftNetrc requires MacOS 10.12 or higher")
        exit(1)
    }
} catch {
    // error happened - exit with non-zero exit status
    print("\(error.localizedDescription)")
    exit(1)
}
