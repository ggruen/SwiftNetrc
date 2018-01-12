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
        let ( removeCallback, path ) = try self.writeNetrc(with: testEntry)
        defer { removeCallback() }

        // When
        let netrc = try SwiftNetrc([path])
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
        let ( removeCallback, path ) = try self.writeNetrc(with: testEntry)
        defer { removeCallback() }

        // When
        let netrc = try SwiftNetrc([path])

        // Then
        XCTAssertEqual(netrc.netrcFile.path, path)
    }

    /// Given: A .netrc file with a lot of whitespace and machine "testmachine" and machine "testmachine2"
    /// When: let netrc = SwiftNetrc("/tmp/netrc")
    /// Then:
    ///  - Correct username is returned for testmachine
    ///  - Correct username is returned for testmachine2
    ///  - Correct password is returned for testmachine
    ///  - Correct password is returned for testmachine2
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
        let ( removeCallback, path ) = try self.writeNetrc(with: testEntry)
        defer { removeCallback() }

        // When
        let netrc = try SwiftNetrc(path)

        // Then
        XCTAssertEqual(netrc["mytest"]?.login, "joe")
        XCTAssertEqual(netrc["mytest"]?.password, "mypass")
        XCTAssertEqual(netrc["myothertest"]?.login, "frank")
        XCTAssertEqual(netrc["myothertest"]?.password, "frank'spassword")
    }

    /// Given: A .netrc file with a passphrase containing spaces and special characters
    /// When: Parse the file
    /// Then: netrc["mymachine"]?.password equals the passphrase
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
        let ( removeCallback, path ) = try self.writeNetrc(with: testEntry)
        defer { removeCallback() }

        // When
        let netrc = try SwiftNetrc(path)

        // Then
        XCTAssertEqual(netrc["myothertest"]?.password, "I am Frank and I use passphr@ze$!!")
    }

    /// Given: .netrc file with machine name out of order
    /// When: Parse file
    /// Then: Throws a "noMachineSpecified" error
    func testThrowsNoMachineSpecified() throws {
        // Given
        let testEntry = """
            login joe machine something password oops
            """
        let ( removeCallback, path ) = try self.writeNetrc(with: testEntry)
        defer { removeCallback() }

        // When / then
        do {
            let _ = try SwiftNetrc(path)
            XCTFail("Parser didn't throw an error parsing a bad file")
        } catch SwiftNetrc.SwiftNetrcError.noMachineSpecified {
            XCTAssert(true, "Parser threw noMachineSpecified error")
        } catch {
            XCTFail("Parser threw a \(error.localizedDescription) error instead of noMachineSpecified")
        }
    }

    /// If a token is followed by another token or is at the end of the line, parser should throw an error
    func testThrowsNoValueForToken() throws {
        // Given
        let testEntry = """
            machine something login joe password
            """
        let ( removeCallback, path ) = try self.writeNetrc(with: testEntry)
        defer { removeCallback() }

        // When / then
        do {
            let _ = try SwiftNetrc(path)
            XCTFail("Parser didn't throw an error parsing a bad file")
        } catch SwiftNetrc.SwiftNetrcError.noValueForToken(let token) {
            XCTAssert(true, "Parser threw noMachineSpecified error for token \(token)")
        } catch {
            XCTFail("Parser threw a \(error.localizedDescription) error instead of noMachineSpecified")
        }
    }

    /// Given: .netrc with bad permissions
    /// When: let netrc = SwiftNetrc()
    /// Then: throws error
    func testThrowsOnUnsafeFile() throws {
        // Given
        let testEntry = """
        machine something login joe password mypass
        """
        let ( removeCallback, path ) = try self.writeNetrc(with: testEntry, withPermissions: 0o640)
        defer { removeCallback() }

        // When
        do {
            let _ = try SwiftNetrc(path)
            XCTFail("SwiftNetrc didn't error with bad .netrc permissions")
        } catch SwiftNetrc.SwiftNetrcError.fileGroupOrWorldWritableOrExecutable {
            XCTAssert(true, "SwiftNetrc threw fileGroupOrWorldWritableOrExecutable error for bad permissions")
        } catch {
            XCTFail("SwiftNetrc threw incorrect error: \(error.localizedDescription)")
        }
    }

    /// Given: .netrc with 600 (good) permissions
    /// When: let netrc = SwiftNetrc()
    /// Then: doesn't throw error
    func testDoesntThrowWithGoodPermissions() throws {
        // Given
        let testEntry = """
        machine something login joe password mypass
        """
        let (removeCallback, path) = try self.writeNetrc(with: testEntry, withPermissions: 0o600)
        defer { removeCallback() }

        // When
        do {
            let _ = try SwiftNetrc(path)
            XCTAssert(true, "SwiftNetrc didn't error with good .netrc permissions")
        } catch SwiftNetrc.SwiftNetrcError.fileGroupOrWorldWritableOrExecutable {
            XCTFail("SwiftNetrc threw fileGroupOrWorldWritableOrExecutable error for good permissions")
        } catch {
            XCTFail("SwiftNetrc threw unexpected error: \(error.localizedDescription)")
        }
    }

    /// Utility function to write test data to a test .netrc file
    ///
    /// Example:
    ///     let testEntry = """
    ///         machine something login joe password mypass
    ///         """
    ///     let (removeCallback, path) = try self.writeNetrc(with: testEntry)
    ///     defer { removeCallback() }
    ///
    /// - Parameters:
    ///   - content: String containing the content to write to the .netrc file.
    ///   - path: Path to .netrc test file - defaults to "/tmp/testnetrc". The file will be overwritten.
    ///   - perms: Permissions to set for the test file, defaults to 0o600
    /// - Returns: `( callback, pathToFile )`, a tuple in which `callback` is a function to call that will remove
    ///     the test file and `pathToFile` is the path to the created file
    /// - Throws: Errors from `String` or `FileManager`
    func writeNetrc(with content: String, to path: String = "/tmp/testnetrc", withPermissions perms: NSNumber = 0o600) throws -> (() -> (), String) {
        try content.write(toFile: path, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: perms], ofItemAtPath: path)
        return ( { try? FileManager.default.removeItem(atPath: path)}, path )
    }

    func testPerformanceExample() throws {
        // Given
        let testEntry = """
            machine mytest
                login joe
                password mypass
            machine myothertest
                login frank
                password I am Frank and I use passphr@ze$!!
            """
        let ( removeCallback, path ) = try self.writeNetrc(with: testEntry)
        defer { removeCallback() }

        self.measure {
            // Put the code you want to measure the time of here.
            let _ = try? SwiftNetrc(path)
        }
    }
}
