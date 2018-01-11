# SwiftNetrc

[![Build Status](https://travis-ci.org/ggruen/SwiftNetrc.svg?branch=master)](https://travis-ci.org/ggruen/SwiftNetrc)

`.netrc` parser for (command-line / server-side) Swift.

# Synopsis

    let netrc = SwiftNetrc()

    let username = netrc['myserver.com'].username
    let password = netrc['myserver.com'].password

    let (username, password) = netrc.credentials('myserver.com')

# Description

SwiftNetrc parses a .netrc file according to [the rules followed by GNU `ftp`](https://www.gnu.org/software/inetutils/manual/html_node/The-_002enetrc-file.html).

The parser is smart enough to recognize passphrases, with some caveats (see "How the parser works" and "Known Isues" below).

If the input file is readable by anyone but the user, throws a SwiftNetrc.SwiftNetrcError.fileGroupOrWorldWritableOrExecutable error.

## Parsing examples

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

A value (machine name, login name, password) that contains more than one word cannot contain a key token (machine, login, password, account, or macdef) other than itself, or it'll be interpreted as a new token (parser will throw a noValueForToken error). e.g. This will fail with a noValueForToken error because of the last "machine"

    machine mymachine login joe password This is my machine

But this will work, because the parser is smart enough to recognize that it's already parsing "password".

    machine mymachine login joe password This is my password

This, however, will work, as key tokens are case-sensitive ("Machine" is not interpreted as a new token)

    machine mymachine login joe password This is my Machine

As will this, because tokens are split at whitespace, so the "." is part of the token.

    machine mymachine login joe password This is my machine.

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

## Passphrases have some limitations

Passphrases can't have "machine", "login", "account", or "macdef" (lower case) in them.

Passphrases can't have leading, trailing, or inter-word redundant whitespace.

## .netrc can't contain comments

.netrc file can't contain comments (this is a feature, to prevent confusion with #'s in tokens, e.g. in passwords)

## Command-line utility exists but, is mostly useless

There's a command-line utility that'll get built when you build, but it currently just runs the parser and prints ".netrc file parsed
without error" if there are no errors, and prints and error and exits 1 otherwise. I guess you could use it to test your .netrc file like this:

    swift build
    ./.build/x86_64-apple-macosx10.10/debug/SwiftNetrc && ftp ftp.myserver.com

If you really want to you can "install" it:

    cp ./.build/x86_64-apple-macosx10.10/debug/SwiftNetrc /usr/local/bin/swiftnetrc

Then you could just run "swiftnetrc" to have it parse and report on your .netrc file. Exciting, I know.
