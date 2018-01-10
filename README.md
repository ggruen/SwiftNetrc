# SwiftNetrc

`.netrc` parser for (command-line, cross-platform) Swift.

# Synopsis

let netrc = SwiftNetrc()

let username = netrc['myserver.com'].username
let password = netrc['myserver.com'].password

let (username, password) = netrc.credentials('myserver.com')

# Description

SwiftNetrc parses a .netrc file according to [the rules followed by GNU `ftp`](https://www.gnu.org/software/inetutils/manual/html_node/The-_002enetrc-file.html).

The parser is smart enough to recognize passphrases, with some caveats (see "How the parser works" and "Known Isues" below). Here are some examples:

## These will work

All on one line - whitepsace is ignored

    machine mymachine login joe password mypass

Multi-line is fine too. Even with a passphrase.

    machine mymachine
        login joe
        password This is my Awesome p@ssw0rd!

Passphrase can be on the same line

    machine mymachine login joe password This is my Awesome p@ssw0rd!

Or (see How the Parser works), this is the *same passphrase as above* (because all whitespace is reduced to a single space)

    machine mymachine login joe password This   is
        my
                Awesome
        p@ssw0rd!

A value (machine name, login name, password) that contains more than one word cannot contain a key token (machine, login, password, account, or macdef), or it'll be interpreted as a new token (parser will throw a noValueForToken error).

    machine mymachine login joe password This is my password

This, however, will work, as key tokens are case-sensitive ("Password" is not interpreted as a new token)

    machine mymachine login joe password This is my Password

# How the parser works

The parser strips leading, trailing, and redundant inter-token whitespace, then splits words, by whitespace, into an array of "tokens".
So, for example this:

    machine mymachine login joe password mypass

Would be broken into

    ["machine", "mymachine", "login", "joe", "password", "mypass"]

The parser then steps through looking for the key tokens "machine", "login", "password", "account", and "macdef". When it finds
one of those key tokens, it assigns the next token as the value for that token's property in the SwiftNetrc object.  If the next token
is not a key token, it's appended to the previous key token's value.

# Installation

SPM:

    .package( "https://github.com/ggruen/SwiftNetrc.git", from: "1.0.0" )

# Known Issues

Passphrases can't have "machine", "login", "account", "password" or "macdef" (lower case) in them.

Passphrases can't have leading, trailing, or inter-word redundant whitespace.
