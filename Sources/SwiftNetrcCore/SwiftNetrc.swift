import Foundation

@available(OSX 10.12, *)
/// Parses `~/.netrc`
///
///     let netrc = SwiftNetrc()
///     print netrc["mymachine"].login
///     print netrc["mymachine"].password
///
public final class SwiftNetrc {
    enum SwiftNetrcError: Error {
        /// There was no "machine" token found, or it wasn't found before another token was found
        case noMachineSpecified

        /// A token was expected, but a different word was provided
        case invalidToken(String)

        /// A token, e.g. "password" wasn't followed by a value
        case noValueForToken(String)

        /// .netrc file isn't read-only
        case fileGroupOrWorldWritableOrExecutable
    }

    /// The URL to the .netrc file. Defaults to ~/.netrc
    open var netrcFile: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".netrc")
    var machines: [String: NetrcMachine] = [:]

    /// Allows this library to be used as a shell command
    ///
    /// Example:
    ///
    /// *Load a test .netrc in /tmp/.netrc*
    ///
    ///     let netrc = SwiftNetrc([ "/tmp/.netrc" ])
    ///
    /// - Parameter arguments: Command-line arguments, one "word" per array item.
    public init(_ arguments: [String] = CommandLine.arguments) throws {
        if arguments.count > 0 {
            netrcFile = URL(fileURLWithPath: arguments[0])
        }
        try load()
    }

    /// Leaves the default ~/.netrc
    public init() throws {
        try load()
    }

    /// Initializes a SwiftNetrc object with just the path to the .netrc file
    ///
    /// - Parameter fileName: /path/to/.netrc
    public convenience init(_ fileName: String) throws {
        try self.init([fileName])
    }

    /// Reads the contents of .netrc into `machines`
    open func load() throws {
        let attributes = try FileManager.default.attributesOfItem(atPath: netrcFile.path)
        // .netrc must be read and/or write for user only, so 600 or 400 are ok, nothing else.
        let okPermissions: Int16 = 0o600
        guard (attributes[.posixPermissions] as! Int16 | okPermissions) == okPermissions else {
            throw SwiftNetrcError.fileGroupOrWorldWritableOrExecutable
        }
        let netrc = try String(contentsOf: netrcFile, encoding: .utf8)

        try parse(netrc)
    }

    /// Parses a string that contains the contents of a .netrc file
    ///
    /// - Parameter content: Contents of a .netrc file
    /// - Throws: SwiftNetrcError.noMachineSpecified if the .netrc file has a parameter specified before a "machine" is specified
    private func parse(_ content: String) throws {
        // Remove comments
        // Removed: can break passwords with # in them, and isn't in the spec
//        let lines = content.split(separator: "\n")
//        var tokenContent = ""
//        for line in lines {
//            var deCommentedLine = String(line)
//            if let i = line.index(of: "#") {
//                deCommentedLine = String(line[..<i])
//            }
//            tokenContent.append(deCommentedLine + "\n")
//        }
        let tokenContent = content

        var tokens = tokenContent.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)

        var currentMachineName = ""
        var currentToken: NetrcToken?
        var i: Int = 0
        while i < tokens.count {

            let tokenString = tokens[i]

            // Skip empty tokens, which we really shouldn't have, just in case.
            if tokenString.isEmpty {
                i += 1
                continue
            }

            var tokenIsValue = false
            if let token = NetrcToken(rawValue: tokenString) {
                currentToken = token
            } else {
                tokenIsValue = true
            }

            // A valid token (really, "machine") must be the first token in the file. If not, this'll happen.
            guard currentToken != nil else {
                throw SwiftNetrcError.invalidToken(tokenString)
            }
            switch currentToken! {
                case .machine:
                    if !tokenIsValue {
                        guard i+1 < tokens.count else {
                            throw SwiftNetrcError.noValueForToken( (currentToken?.rawValue)! )
                        }
                        currentMachineName = tokens[i + 1]
                        i += 1
                        machines[currentMachineName] = NetrcMachine()
                        machines[currentMachineName]?.name = currentMachineName // Redundant?
                    }
                case .login:
                    guard currentMachineName != "" else { throw SwiftNetrcError.noMachineSpecified }
                    if let login = machines[currentMachineName]?.login {
                        machines[currentMachineName]!.login = "\(login) \(tokens[i])"
                    } else {
                        guard i+1 < tokens.count else {
                            throw SwiftNetrcError.noValueForToken( (currentToken?.rawValue)! )
                        }
                        machines[currentMachineName]!.login = tokens[i + 1]
                        i += 1
                    }
                case .password:
                    guard currentMachineName != "" else { throw SwiftNetrcError.noMachineSpecified }
                    if let password = machines[currentMachineName]?.password {
                        machines[currentMachineName]!.password = "\(password) \(tokens[i])"
                    } else {
                        guard i+1 < tokens.count else {
                            throw SwiftNetrcError.noValueForToken( (currentToken?.rawValue)! )
                        }
                        machines[currentMachineName]!.password = tokens[i + 1]
                        i += 1
                    }
                case .account:
                    guard currentMachineName != "" else { throw SwiftNetrcError.noMachineSpecified }
                    if let account = machines[currentMachineName]?.account {
                        machines[currentMachineName]!.account = "\(account) \(tokens[i])"
                    } else {
                        guard i+1 < tokens.count else {
                            throw SwiftNetrcError.noValueForToken( (currentToken?.rawValue)! )
                        }
                        machines[currentMachineName]!.account = tokens[i + 1]
                        i += 1
                    }
                case .macdef:
                    guard currentMachineName != "" else { throw SwiftNetrcError.noMachineSpecified }
                    if let macdef = machines[currentMachineName]?.macdef {
                        machines[currentMachineName]!.macdef = "\(macdef) \(tokens[i])"
                    } else {
                        guard i+1 < tokens.count else {
                            throw SwiftNetrcError.noValueForToken( (currentToken?.rawValue)! )
                        }
                        machines[currentMachineName]!.macdef = tokens[i + 1]
                        i += 1
                    }
            }

            // Next token
            i += 1
        }

    }

    subscript(_ machine: String) -> NetrcMachine? {
        return machines[machine]
    }

    /// Called by main.swift. Not too useful right now - just kinda validates the file (makes sure it can parse it)
    public func run() throws {
        try self.load()
        print( ".netrc file parsed without error" )
    }
}

/// Represents a machine whose information is stored in .netrc
public struct NetrcMachine {
    var name = ""
    private var properties: [String: String] = [:]
    var login: String?
    var password: String?
    /// Alias for "name"
    var machine: String { return name }

    /// Account
    var account: String?

    /// Macdef: Macro definition. Stored but not used, unless you want to execute an FTP macro
    var macdef: String?

    subscript(_ name: String) -> String? {
        get {
            return properties[name]
        }
        set(newValue) {
            properties[name] = newValue
        }
    }
}

enum NetrcToken: String {
    typealias RawValue = String

    case machine
    case login
    case password
    case account
    case macdef

}
