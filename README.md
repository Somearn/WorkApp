# WorkApp

A central hub for all my created applications and projects.

## Overview

This repository serves as a collection of various applications, utilities, and projects. Each application is organized in its own directory within the `apps/` folder.

The root directory also contains PowerShell-based modules (stored as `.txt` files) for the SomearnTK application suite.

## Structure

```
WorkApp/
├── apps/                        # All applications and projects
├── docs/                        # Documentation
├── AG_*.txt                     # SomearnTK application modules
├── AG_SecurityHelpers.txt       # Security utilities and logging
├── RunMenu.txt                  # Main launcher
├── SECURITY_REVIEW.md           # Comprehensive security analysis
├── SECURITY_IMPROVEMENTS.md     # Security fixes documentation
└── README.md                    # This file
```

## SomearnTK Modules

The following modules are available in the main menu:

- **Application Manager** - Manage application groups and shortcuts
- **Phone Book** - Contact directory viewer
- **Site Manager** - Site information management
- **Script Launcher** - Execute PowerShell scripts
- **Diagnostics & Repair** - Star Trek-themed network diagnostics and system tools

See [docs/DiagnosticsAndRepair.md](docs/DiagnosticsAndRepair.md) for detailed documentation on the Diagnostics and Repair module.

## Security

This application has been hardened for enterprise environments with EDR and AppLocker/WDAC:

### Security Features
- ✅ **No String-to-Execution Patterns** - Uses direct dot-sourcing instead of `ScriptBlock::Create`
- ✅ **Input Validation** - All user input (hostnames, file paths) is validated
- ✅ **Path Traversal Protection** - All file paths are validated and resolved
- ✅ **Security Logging** - All security events logged to audit trail
- ✅ **File Integrity Framework** - Hash-based validation for modules
- ✅ **UNC Permission Validation** - Checks for excessive write permissions

### Security Documentation
- **[SECURITY_REVIEW.md](SECURITY_REVIEW.md)** - Detailed security analysis with findings table
- **[SECURITY_IMPROVEMENTS.md](SECURITY_IMPROVEMENTS.md)** - Complete list of security fixes implemented

### Security Log Location
Security events are logged to: `%TEMP%\SomearnTK_Security.log`

Review this log for:
- Module loads and validations
- Security violations and blocked attempts
- User actions and script executions

### For Administrators

**UNC Share Permissions:**
- Ensure `\\lsfile03\netdoc$\Somearns_Folder\SomearnTK_app\` is read-only for standard users
- Grant write permissions only to administrators
- Application validates permissions on startup

**Hash Allowlist Maintenance:**
- Update `$script:AG_ModuleHashes` in `AG_SecurityHelpers.txt` when modules change
- Generate hashes with: `Get-FileHash -Algorithm SHA256 -LiteralPath <file>`
- **Important:** Failing to update hashes after legitimate module changes will cause integrity validation failures and prevent module loading

## Getting Started

Browse the `apps/` directory to find available applications. Each app has its own README with specific instructions.

For SomearnTK modules, run `RunMenu.txt` with PowerShell ISE or execute the launcher code.

## System Requirements

- PowerShell 5.1 or higher
- Windows 10/11 or Windows Server 2016+
- Access to UNC path (for corporate deployment)
- .NET Framework 4.5+ (for WinForms)

## Enterprise Deployment

This application is designed for corporate environments:
- Runs from UNC share (no local installation required)
- Compatible with AppLocker and WDAC policies
- EDR-friendly execution patterns
- Comprehensive audit logging
- Fail-closed security model

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding new applications to this hub.

## License

Internal use only. See your organization's policies for usage guidelines.
