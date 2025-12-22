# Network Tool Module

## Overview

The Network Tool module (`AG_NetworkTool.txt`) provides a comprehensive set of network troubleshooting and system diagnostic utilities within the SomearnTK application. It follows the established module pattern and integrates seamlessly with the main menu framework.

## Features

The Network Tool includes the following diagnostic tools:

### 1. Continuous Ping
- Sends 10 ping requests to a specified host
- Displays response times or timeout messages
- Useful for basic connectivity testing

### 2. NSLookup
- Performs DNS name resolution
- Shows IP addresses and DNS record types
- Helps diagnose DNS-related issues

### 3. Traceroute
- Traces network path to a destination
- Displays all hops along the route
- Useful for identifying network routing problems

### 4. Check Services
- Lists Windows services on local or remote computers
- Shows service status (Running/Stopped)
- Filters out disabled services
- Displays top 50 services for performance

### 5. Check Disk Space
- Shows disk space usage for all drives
- Displays total, used, and free space in GB
- Shows percentage used for each drive
- Works on local and remote systems

### 6. Check CPU/Memory
- Displays CPU information (name, cores, logical processors)
- Shows memory usage (total, used, free RAM with percentages)
- Displays system uptime
- Works on local and remote systems

### 7. Uptime Checker
- Shows system uptime in days, hours, and minutes
- Displays last boot time
- Shows operating system version
- Useful for checking system stability

### 8. IIS Certificate Check
- Lists SSL certificates in Local Machine Personal store
- Shows certificate details (subject, issuer, thumbprint)
- Displays expiration dates and days until expiry
- Highlights certificates that are expired or expiring soon

### 9. Last Lockout
- Checks user account lockout status
- Shows lockout time and bad password attempts
- Works with Active Directory or local accounts
- Requires appropriate permissions

## Architecture

### File Structure
```
WorkApp/
├── AG_NetworkTool.txt       # Main module file
├── AG_MenuMain.txt           # Updated with Network Tool menu entry
└── docs/
    └── NetworkTool.md        # This documentation
```

### Module Pattern
The Network Tool follows the established module pattern:

1. **Entry Function**: `Show-NetworkToolView`
   - Called by the menu system
   - Accepts `HostPanel`, `Parent`, or `MainPanel` parameter
   - Handles module loading and error display

2. **Page Generator**: `Get-AG_NetworkToolPage`
   - Returns a WinForms Panel control
   - Creates the complete UI layout
   - Manages all tool actions

3. **Layout Structure**:
   ```
   PageRoot (Panel)
   └── TableLayoutPanel
       ├── Header Row (Title)
       └── Content Row
           └── SplitContainer
               ├── Left Panel (Tool buttons)
               └── Right Panel (Output area)
   ```

### Design Constraints

The module adheres to the following constraints:

- **No Background Jobs**: All operations are user-triggered, no timers or background processes
- **No Disk Logging**: No files are written to disk
- **No Network Noise**: No automatic network calls; all actions require explicit user button clicks
- **TXT-Only Execution**: All code lives in `.txt` files (PowerShell source stored as text)
- **WinForms UI**: Uses Windows Forms with dark modern theme
- **Non-Blocking**: Operations complete quickly or show progress without blocking the UI thread

## UI Design

### Theme Colors
```powershell
Form:    RGB(12, 14, 24)    # Dark background
Panel:   RGB(18, 20, 34)    # Slightly lighter panels
Card:    RGB(24, 26, 46)    # Card backgrounds
Border:  RGB(46, 50, 86)    # Border color
Text:    RGB(230, 232, 246) # Light text
Muted:   RGB(160, 165, 198) # Muted text
Accent:  RGB(160, 90, 255)  # Purple accent
Btn:     RGB(85, 95, 235)   # Primary button
Btn2:    RGB(40, 42, 75)    # Secondary button
```

### Layout
- **Left Panel**: 280px wide, contains tool buttons in a scrollable list
- **Right Panel**: Expandable, shows tool output with:
  - Title bar showing current tool
  - Monospace text box for output
  - Clear button at bottom

### Fonts
- Title: Segoe UI, 16pt, Bold
- Body: Segoe UI, 10pt, Regular
- Output: Consolas, 9pt, Regular (monospace)

## Integration

### Menu Integration
The Network Tool is integrated into the main menu in `AG_MenuMain.txt`:

1. A menu button labeled "Network Tool" is added to the left navigation
2. The button calls `Show-NetworkToolView` when clicked
3. The module is loaded on-demand (lazy loading)
4. Status updates are sent to the main status bar

### Module Loading
The module uses a candidate search pattern:
1. Checks `$script:AgScriptsFolder` for `AG_NetworkTool.txt`
2. Checks the launcher directory
3. Checks parent directory's `appscripts` folder
4. Loads the first found file

## Usage

### For End Users
1. Launch the SomearnTK application
2. Click "Network Tool" in the left menu
3. Select a tool from the left panel
4. Enter required parameters (hostname, computer name, etc.) when prompted
5. View results in the right output panel
6. Click "Clear Output" to clear the display

### For Developers
To add a new tool:

1. Define a new tool function in `AG_NetworkTool.txt`:
```powershell
function Invoke-MyNewTool {
    param([string]$Parameter)
    
    # Prompt for parameter if needed
    if ([string]::IsNullOrWhiteSpace($Parameter)) {
        $Parameter = [Microsoft.VisualBasic.Interaction]::InputBox(...)
        if ([string]::IsNullOrWhiteSpace($Parameter)) { return }
    }
    
    Set-OutputTitle "My New Tool: $Parameter"
    $script:NT_OutputText.Text = ""
    & $script:NT_Status "Running my new tool..."
    
    Append-Output "Tool output here`r`n"
    
    # ... tool logic ...
    
    & $script:NT_Status "Tool completed"
}
```

2. Add the tool to the `$tools` array:
```powershell
$tools = @(
    # ... existing tools ...
    @{ 
        Name = "My New Tool"
        Description = "Does something useful"
        Action = { Invoke-MyNewTool }
    }
)
```

3. The button will be automatically created in the UI

## Technical Notes

### PowerShell Version
- Requires PowerShell 5.1 or later
- Uses Windows-specific cmdlets (Get-WmiObject, Test-Connection, etc.)

### Dependencies
- System.Windows.Forms assembly
- System.Drawing assembly
- Microsoft.VisualBasic assembly (for InputBox)

### Error Handling
- All tool functions include try-catch blocks
- Errors are displayed in the output panel
- Status bar shows success/failure messages
- User-friendly error messages for common issues

### Performance Considerations
- Service checks limited to 50 results for quick display
- Ping limited to 10 requests to avoid long waits
- All operations complete in reasonable time (<30 seconds typical)
- UI remains responsive during operations using DoEvents

## Future Enhancements

Potential additions:
- Network port scanner
- DNS cache viewer/flusher
- Network adapter configuration viewer
- Event log viewer for network events
- Remote desktop connection tester
- Bandwidth testing tool
- WHOIS lookup
- IP configuration viewer (ipconfig alternative)

## Testing

The module includes validation:
1. Syntax checking with PowerShell parser
2. Function export verification
3. Code structure validation
4. Integration testing with main menu

Run validation:
```powershell
# Syntax check
pwsh -Command "$code = Get-Content 'AG_NetworkTool.txt' -Raw; 
               [System.Management.Automation.PSParser]::Tokenize($code, [ref]$null)"

# Structure check
pwsh -Command "$code = Get-Content 'AG_NetworkTool.txt' -Raw;
               if ($code -notmatch 'function Show-NetworkToolView') { exit 1 }"
```

## Support

For issues or questions:
1. Check the function documentation in the code
2. Review error messages in the output panel
3. Check Windows Event Viewer for system-level errors
4. Ensure appropriate permissions for remote operations

## License

Part of the WorkApp repository. See main repository LICENSE.
