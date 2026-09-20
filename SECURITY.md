# Security Policy

## Supported Versions
Only the latest release receives active security patches and rule updates.

| Version | Supported          |
| ------- | ------------------ |
| 1.3.x   | :white_check_mark: |
| < 1.3.0 | :x:                |

## Security Invariants
`win-janitor` enforces strict non-destructive safety boundaries:
1. **The Sakshi Shield**: Absolute immutable sanctuary protection for `\Sakshi`, `%USERPROFILE%\Void\Sakshi\`, and all assets matching `*Sakshi*`.
2. **Path Portability**: Absolute machine paths (e.g. `C:\Users\<user>`) are strictly forbidden in tracked code and committed rules.
3. **Runtime State Decoupling**: Registry dumps and PATH backup files are quarantined outside git in `%LOCALAPPDATA%\win-janitor\backups\`.

## Reporting a Vulnerability
**Please do not report security vulnerabilities through public GitHub issues.**

To report a vulnerability, policy bypass, or shield assertion failure:
1. Use GitHub's private vulnerability reporting feature on this repository.
2. Provide a clear description of the vulnerability, execution context, and reproduction steps.

Reports will be acknowledged within 48 hours and resolved promptly.
