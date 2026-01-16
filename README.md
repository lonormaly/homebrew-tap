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

### Screen UTF-8

GNU Screen with UTF-8 title fix - proper Unicode support in terminal window/tab titles.

```bash
brew install lonormaly/tap/screen-utf8
```

This patched version of GNU Screen fixes a long-standing bug where UTF-8 characters in terminal titles (via OSC escape sequences) are garbled. For example, without this patch, a title like "★ Claude Code" would display as "^E Claude Code".

**The fix includes:**
- Re-encode Unicode code points back to UTF-8 in `StringChar()`
- Bypass UTF-8 re-encoding in `SetXtermOSC()` and `ShowHStatus()` for already-encoded strings
- Add `AddRawStr()` and `AddRawStrn()` functions for raw string output
- Set `WT_FLAG` to "0" for both tab and window titles

**Colors in Screen 5.0.1:** Note that the old letter-based color codes (`krgybmcw`) have been removed. Use numeric syntax instead:
- Basic: `%{= 1;4}` (red on blue)
- 256-color: `%{= 196;21}`
- Truecolor: `%{= #FF0000;#000000}` (requires `truecolor on` in screenrc)

See `brew info screen-utf8` for full color reference.

This is automatically installed as a dependency of ImmorTerm.
