# Diagnostics and Repair Module

## Overview

The **Diagnostics and Repair** module is a Star Trek-themed network troubleshooting and system diagnostics interface for the SomearnTK application. It features a futuristic UI with vibrant button colors and launches diagnostic tools in external terminal windows.

## Star Trek Theme

The module features a **Star Trek LCARS-inspired** color scheme with:
- Deep space blue-black background (RGB 15, 15, 35)
- Vibrant, futuristic button colors inspired by the Star Trek universe
- Glowing cyan borders and accents
- High-contrast text for readability

### Button Colors
- **Orange**: Ping Diagnostic
- **Blue**: DNS Lookup
- **Purple**: Traceroute
- **Green**: Service Status
- **Yellow**: Disk Space
- **Teal**: CPU & Memory
- **Red**: Uptime Check
- **Purple**: Certificate Check
- **Blue**: Network Config

## Features

### Diagnostic Tools Menu
- **Grid Layout**: Buttons arranged in a flowing grid pattern
- **Star Trek Styling**: Each button has unique colors inspired by the reference image
- **Hover Effects**: Glowing borders on mouse hover
- **One-Click Launch**: Click a button to launch the diagnostic tool

### External Terminal Execution
- **No Inline Output**: Tools run in new PowerShell terminal windows
- **Window Management**: Automatically closes oldest 2 terminal windows before opening a third
- **Formatted Output**: Each terminal displays results with headers and formatting
- **Press Any Key**: Terminals stay open until user presses a key

### Feature Request Box
- **Right Corner Panel**: Dedicated area for user feature requests
- **Submit Button**: Log feature requests for future enhancements
- **Pre-filled Examples**: Helpful suggestions for request ideas

### Least Privilege Approach
- **Access Check First**: Detects if elevated privileges are needed
- **Prompt Only When Needed**: Only requests admin credentials for tools that require it
- **No Unnecessary Elevation**: Most tools run with standard user permissions

### No Loops or Background Noise
- **User-Triggered Only**: Tools run only when buttons are clicked
- **No Auto-Refresh**: No timers or background processes
- **No Polling**: No continuous network traffic
- **Single Execution**: Each button press = one diagnostic run

## Diagnostic Tools

### 1. PING DIAGNOSTIC
- Tests network connectivity with 10 ping requests
- Shows response times and packet loss
- Requires target hostname/IP input

### 2. DNS LOOKUP
- Resolves DNS names to IP addresses
- Shows all DNS record types
- Requires target hostname input

### 3. TRACEROUTE
- Traces network path to destination
- Shows all hops with latency
- Requires target hostname/IP input

### 4. SERVICE STATUS
- Lists Windows services (non-disabled only)
- Shows service status (Running/Stopped)
- Works on local or remote computers

### 5. DISK SPACE
- Shows disk space usage for all drives
- Displays used, free, and total space in GB
- Works on local or remote computers

### 6. CPU & MEMORY
- Displays CPU information (name, cores)
- Shows total and free RAM
- Calculates system uptime
- Works on local or remote computers

### 7. UPTIME CHECK
- Shows system uptime in days/hours/minutes
- Displays last boot time
- Shows OS version
- Works on local or remote computers

### 8. CERTIFICATE CHECK
- Lists SSL certificates in Local Machine store
- Shows expiration dates
- Calculates days until expiry
- Runs on local system only

### 9. NETWORK CONFIG
- Shows network adapter configuration
- Displays IP addresses, DNS servers, gateways
- Shows adapter status and link speed
- Runs on local system only

## Usage

### Launching Tools
1. Click "Diagnostics & Repair" in the main menu
2. Select a diagnostic tool button
3. Enter target hostname/IP if prompted (or use "localhost")
4. View results in the new PowerShell terminal window
5. Press any key to close the terminal when done

### Submitting Feature Requests
1. Type your request in the "Feature Requests" box
2. Click "Submit Request"
3. Confirmation message appears
4. Request is logged for future consideration

### Window Management
- Up to 2 terminal windows can be open simultaneously
- Oldest windows automatically close when a third tool is launched
- This prevents terminal window clutter

## Technical Details

### File Structure
```
AG_DiagnosticsAndRepair.txt - Main module file (520+ lines)
```

### Key Functions
- `Show-DiagnosticsAndRepairView` - Entry point for menu integration
- `Get-AG_DiagnosticsAndRepairPage` - Page generator and UI builder
- `Invoke-DiagnosticTool` - Launches tools in external terminals
- `Manage-TerminalWindows` - Handles window lifecycle
- `New-StarTrekButton` - Creates themed buttons

### Window Management
```powershell
$script:DR_RunningTerminals = [System.Collections.ArrayList]::new()
```
Tracks active terminal processes and enforces 2-window limit.

### External Execution
Tools are launched using:
- `System.Diagnostics.Process.Start()`
- PowerShell with `-EncodedCommand` parameter
- Formatted output with headers and footers
- "Press any key" wait for user review

### Privilege Detection
```powershell
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal(...)
$needsElevation = -not $currentPrincipal.IsInRole([...Administrator])
```
Checks if current user has admin rights before prompting.

## Design Constraints

✅ **Only .txt files** - All code in AG_DiagnosticsAndRepair.txt
✅ **WinForms UI** - Uses System.Windows.Forms
✅ **Star Trek theme** - LCARS-inspired colors and styling
✅ **External execution** - Tools run in new terminal windows
✅ **No inline output** - Output in terminals, not in module UI
✅ **Window management** - Max 2 terminals, auto-close oldest
✅ **No loops** - Single execution per button click
✅ **No background processes** - No timers or jobs
✅ **No network noise** - Only when button clicked
✅ **Least privilege** - Check access before prompting
✅ **Feature requests** - Right corner request box

## Architecture

```
Main Panel
├── Header (Title: "DIAGNOSTICS AND REPAIR")
└── Content (75% / 25% split)
    ├── Left: Button Grid (9 tool buttons)
    └── Right: Feature Request Box
        ├── Title label
        ├── Text input area
        └── Submit button
```

## Color Theme Reference

Based on Star Trek LCARS and the provided reference image:

| Element | Color | RGB |
|---------|-------|-----|
| Background | Deep Space Blue | 15, 15, 35 |
| Panel | Dark Blue | 20, 25, 50 |
| Orange Button | Amber | 255, 145, 40 |
| Blue Button | Cyan | 90, 180, 255 |
| Purple Button | Magenta | 200, 100, 255 |
| Green Button | Emerald | 100, 255, 150 |
| Red Button | Pink | 255, 80, 100 |
| Yellow Button | Gold | 255, 200, 50 |
| Teal Button | Cyan-Green | 80, 220, 220 |
| Text | Light Blue-White | 220, 230, 255 |
| Accent | Cyan | 90, 180, 255 |
| Border | Cyan | 90, 180, 255 |
| Glow | Bright Cyan | 120, 200, 255 |

## Future Enhancements

Potential additions based on feature requests:
- DNS cache flush tool
- Port scanner
- Bandwidth tester
- Remote desktop connection tester
- Event log viewer
- Network packet analyzer
- WHOIS lookup
- IP configuration editor

## Support

### Requirements
- Windows OS with PowerShell 5.1+
- .NET Framework with WinForms support
- Appropriate permissions for diagnostic operations

### Troubleshooting
- **Tool won't launch**: Check if PowerShell is available in PATH
- **Access denied**: Some tools require administrator privileges
- **Remote access fails**: Check WMI/RPC permissions on target
- **Terminal closes immediately**: Syntax error in command (report as bug)

## Integration

### Menu Integration
The module integrates with AG_MenuMain.txt:
- Button: "Diagnostics & Repair"
- Position: 5th button in left navigation
- Command: `Show-DiagnosticsAndRepairView`

### Module Loading
Automatically loaded on first click from:
- `$script:AgScriptsFolder\AG_DiagnosticsAndRepair.txt`
- Launcher directory
- Parent appscripts directory

## Screenshots

_To be added after Windows testing_

## License

Part of the WorkApp repository. See main repository LICENSE.
