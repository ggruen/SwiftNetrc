//
//  SwiftNetrcTests.swift
//  SwiftNetrc
//

import Foundation
import XCTest
@testable import SwiftNetrcCore

class SwiftNetrcTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of
        // each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation
        // of each test method in the class.
        super.tearDown()
    }

    /**
     * TDD Tests - e.g.:
     * - given: A .netrc file with "machine mytest login joe password mypass"
     * - when:
     *      let netrc = SwiftNetrc("/path/to/test/netrc")
     *      let login = netrc['mytest].login
     *      let password = netrc['mytest'].password
     * - then:
     *     - login is "joe"
     *     - password is "mypass"
     */
    func testRetrievesUsernameAndPassword() throws {
        // Given
        let testEntry = "machine mytest login joe password mypass"
        try testEntry.write(toFile: "/tmp/testnetrc", atomically: false, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: "/tmp/testnetrc") }

        // When
        let netrc = try SwiftNetrc(["/tmp/testnetrc"])
        let login = netrc["mytest"]?.login
        let password = netrc["mytest"]?.password

        // Then
        XCTAssertEqual(login, "joe", "Username is joe")
        XCTAssertEqual(password, "mypass", "Password is mypass")
    }

    // Given: A .netrc file at /tmp/netrc
    // When: let netrc = SwiftNetrc("/tmp/netrc")
    // Then: netrc.netrcFile == "/tmp/netrc"
    func testNetrcSetsFilePathOnInit() throws {
        // Given
        let testEntry = "machine mytest login joe password mypass"
        try testEntry.write(toFile: "/tmp/testnetrc", atomically: false, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: "/tmp/testnetrc") }

        // When
        let netrc = try SwiftNetrc(["/tmp/testnetrc"])

        // Then
        XCTAssertEqual(netrc.netrcFile.path, "/tmp/testnetrc")
    }

    // Given: A .netrc file with a lot of whitespace and machine "testmachine" and machine "testmachine2"
    // When: let netrc = SwiftNetrc("/tmp/netrc")
    // Then:
    //  - Correct username is returned for testmachine
    //  - Correct username is returned for testmachine2
    //  - Correct password is returned for testmachine
    //  - Correct password is returned for testmachine2
    func testHandlesTwoMachines() throws {
        // Given
        let testEntry = """
            machine mytest
                login joe
                password mypass
            machine myothertest
                login frank
                password frank'spassword
            """
        try testEntry.write(toFile: "/tmp/testnetrc", atomically: false, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: "/tmp/testnetrc") }

        // When
        let netrc = try SwiftNetrc("/tmp/testnetrc")

        // Then
        XCTAssertEqual(netrc["mytest"]?.login, "joe")
        XCTAssertEqual(netrc["mytest"]?.password, "mypass")
        XCTAssertEqual(netrc["myothertest"]?.login, "frank")
        XCTAssertEqual(netrc["myothertest"]?.password, "frank'spassword")
    }

    // Given: A .netrc file with a passphrase containing spaces and special characters
    // When: Parse the file
    // Then: netrc["mymachine"]?.password equals the passphrase
    func testHandlesPassphrases() throws {
        // Given
        let testEntry = """
            machine mytest
                login joe
                password mypass
            machine myothertest
                login frank
                password I am Frank and I use passphr@ze$!!
            """
        try testEntry.write(toFile: "/tmp/testnetrc", atomically: false, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: "/tmp/testnetrc") }

        // When
        let netrc = try SwiftNetrc("/tmp/testnetrc")

        // Then
        XCTAssertEqual(netrc["myothertest"]?.password, "I am Frank and I use passphr@ze$!!")
    }

    // Given: .netrc file with machine name out of order
    // When: Parse file
    // Then: Throws a "noMachineSpecified" error
    func testThrowsNoMachineSpecified() throws {
        // Given
        let testEntry = """
            login joe machine something password oops
            """
        try testEntry.write(toFile: "/tmp/testnetrc", atomically: false, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: "/tmp/testnetrc") }

        // When / then
        do {
            let _ = try SwiftNetrc("/tmp/testnetrc")
            XCTFail("Parser didn't throw an error parsing a bad file")
        } catch SwiftNetrc.SwiftNetrcError.noMachineSpecified {
            XCTAssert(true, "Parser threw noMachineSpecified error")
        } catch {
            XCTFail("Parser threw a \(error.localizedDescription) error instead of noMachineSpecified")
        }
    }

    /// If a token is followed by another token or is at the end of the line, parser should throw an error
    func testThrowsValueForToken() throws {
        // Given
        let testEntry = """
            machine something login joe password
            """
        try testEntry.write(toFile: "/tmp/testnetrc", atomically: false, encoding: .utf8)
        defer { try? FileManager.default.removeItem(atPath: "/tmp/testnetrc") }

        // When / then
        do {
            let netrc = try SwiftNetrc("/tmp/testnetrc")
            print( netrc )
            XCTFail("Parser didn't throw an error parsing a bad file")
        } catch SwiftNetrc.SwiftNetrcError.noValueForToken(let token) {
            XCTAssert(true, "Parser threw noMachineSpecified error for token \(token)")
        } catch {
            XCTFail("Parser threw a \(error.localizedDescription) error instead of noMachineSpecified")
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}
