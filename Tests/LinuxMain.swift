// Generated using Sourcery 0.10.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import XCTest
@testable import SwiftNetrcTests

extension SwiftNetrcTests {
  static var allTests = [
    ("testRetrievesUsernameAndPassword", testRetrievesUsernameAndPassword),
    ("testNetrcSetsFilePathOnInit", testNetrcSetsFilePathOnInit),
    ("testHandlesTwoMachines", testHandlesTwoMachines),
    ("testHandlesPassphrases", testHandlesPassphrases),
    ("testThrowsNoMachineSpecified", testThrowsNoMachineSpecified),
    ("testThrowsNoValueForToken", testThrowsNoValueForToken),
    ("testThrowsOnUnsafeFile", testThrowsOnUnsafeFile),
    ("testDoesntThrowWithGoodPermissions", testDoesntThrowWithGoodPermissions),
    ("testPerformanceExample", testPerformanceExample),
  ]
}


XCTMain([
  testCase(SwiftNetrcTests.allTests),
])
