//import Darwin // Gets us "exit"
import Foundation  // Needed for error.localizedDescription (or we get an error from ld)
#if SWIFT_PACKAGE
import SwiftNetrcCore
#endif

enum SwiftNetrcCoreError: Error {
    case MacOsSierraRequired
}

do {
    let tool = try SwiftNetrc()
    try tool.run()
} catch {
    // error happened - exit with non-zero exit status
    print(error.localizedDescription)
    exit(1)
}
