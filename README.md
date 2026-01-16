# Homebrew Tap for lonormaly

Custom Homebrew formulae by [lonormaly](https://github.com/lonormaly).

## Installation

```bash
brew tap lonormaly/tap
```

## Available Formulae

### ImmorTerm

Persistent terminal sessions for VS Code - terminals that survive crashes.

```bash
brew install lonormaly/tap/immorterm
```

[Repository](https://github.com/lonormaly/ImmorTerm) | [Documentation](https://github.com/lonormaly/ImmorTerm#readme)

### Screen for ImmorTerm

GNU Screen patched for ImmorTerm - with UTF-8 title fix and color support.

```bash
brew install lonormaly/tap/screen-immorterm
```

This is required by the [ImmorTerm VS Code extension](https://github.com/lonormaly/ImmorTerm) for persistent terminal sessions.

**Patches included:**
- UTF-8 characters in terminal titles (★, ✳, emoji work correctly)
- Proper hardstatus Unicode support
- OSC escape sequence fixes

**Colors in Screen 5.0.1:** The old letter-based color codes (`krgybmcw`) have been removed. Use numeric syntax:
- Basic: `%{= 1;4}` (red on blue)
- 256-color: `%{= 196;21}`
- Truecolor: `%{= #FF0000;#000000}` (requires `truecolor on`)

See `brew info screen-immorterm` for full color reference.
