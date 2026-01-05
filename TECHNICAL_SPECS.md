# Network Management Tool - Technical Specifications

## System Requirements

### Minimum Requirements
- **OS**: Windows 10 (1809+) or Windows Server 2016+
- **PowerShell**: Version 5.1 or later
- **.NET Framework**: 4.7.2 or later (included in Windows)
- **RAM**: 512 MB available
- **Disk Space**: 50 MB for tool operation
- **Screen Resolution**: 1920x1080 (optimized), minimum 1600x900

### Recommended Requirements
- **OS**: Windows 10 21H2+ or Windows Server 2019+
- **PowerShell**: Version 7+ (for enhanced performance)
- **RAM**: 1 GB available
- **Administrator Rights**: For full functionality
- **Network**: Active connection for remote operations

### Required Modules
All required assemblies are standard Windows components:
- `System.Windows.Forms` - UI framework
- `System.Drawing` - Graphics and theming
- `System.Security` - Credential management

### Optional Components
- **PuTTY**: For SSH functionality (auto-detected)
- **IIS**: For IIS certificate checking
- **SQL Server**: For SQL certificate checking
- **ThreatLocker**: For security monitoring features

## Architecture

### Design Pattern
- **Single-File Application**: Self-contained PowerShell script
- **Event-Driven UI**: Windows Forms with button-triggered operations
- **Tab-Based Navigation**: 14 functional tabs
- **Global State Management**: Shared target host and credentials

### Code Structure
```
NetworkManagementTool.ps1 (2,414 lines)
├── Header & Assembly Loading (10 lines)
├── Global Variables (5 lines)
├── Helper Functions (150 lines)
│   └── Get-T2Credentials() - Credential dialog
│   └── Write-OutputSafe() - Safe output writing
├── Main Form Setup (50 lines)
├── Global Controls (60 lines)
│   ├── Target Host Field
│   ├── Credentials Management
│   └── Tab Control
└── Tab Implementations (2,100 lines)
    ├── Tab 1: Node Summary (200 lines)
    ├── Tab 2: Node Health Check (215 lines)
    ├── Tab 3: Ping Test (140 lines)
    ├── Tab 4: NSLookup (110 lines)
    ├── Tab 5: Traceroute (105 lines)
    ├── Tab 6: Domain Users (145 lines)
    ├── Tab 7: IPConfig (155 lines)
    ├── Tab 8: NetStat (130 lines)
    ├── Tab 9: RDP (165 lines)
    ├── Tab 10: PuTTY (180 lines)
    ├── Tab 11: Server Reboot (205 lines)
    ├── Tab 12: Certificates (190 lines)
    ├── Tab 13: ThreatLocker (175 lines)
    └── Tab 14: Services (185 lines)
```

## Theme Implementation

### Color Palette
```
Primary Colors:
  Near-Black:     #0F0F0F (RGB: 15, 15, 15)      - Background
  Dark Gray:      #212121 (RGB: 33, 33, 33)      - Panels/Controls
  
Accent Colors:
  Teal:           #00B2FF (RGB: 0, 178, 255)     - Actions/Success
  Red:            #FF5733 (RGB: 255, 87, 51)     - Warnings/Critical
  Silver:         #C0C0C0 (RGB: 192, 192, 192)   - Neutral/Cancel
  Yellow:         #FFC107 (RGB: 255, 193, 7)     - Caution
  Green:          #4CAF50 (RGB: 76, 175, 80)     - Confirmed/Healthy
  
Text Colors:
  Text Primary:   #F0F0F0 (RGB: 240, 240, 240)   - Main text
  Text Secondary: #C0C0C0 (RGB: 192, 192, 192)   - Helper text
```

### Typography
```
Fonts:
  Title Font:     Segoe UI, 14pt, Bold
  General Font:   Segoe UI, 10pt, Regular
  Monospace Font: Consolas, 9pt, Regular
  Small Font:     Segoe UI, 9pt, Regular
  Button Font:    Segoe UI, 10pt, Regular/Bold
```

### UI Components
```
Form:
  Size: 1920 x 1080 pixels
  Border: Sizable
  Start Position: CenterScreen
  
TabControl:
  Location: 20, 55
  Size: 1860 x 980
  
Standard Button:
  Height: 35 pixels
  Border: 2px solid (themed)
  Style: Flat
  
TextBox (Output):
  Size: 1800 x 820-870 pixels
  Multiline: Yes
  ScrollBars: Vertical
  ReadOnly: Yes
  Font: Consolas, 9pt
```

## Security Features

### Credential Management
- **Storage**: In-memory only (SecureString)
- **Scope**: Session-only (cleared on exit)
- **Encryption**: Windows DPAPI via SecureString
- **Transmission**: Never logged or saved to disk
- **Cleanup**: Explicit garbage collection on close

### T2 (Restricted Admin) Mode
- **RDP Feature**: `/restrictedAdmin` parameter
- **Security Benefit**: Credentials not sent to remote PC
- **Authentication**: Kerberos ticket-based
- **Use Case**: Prevent credential theft on remote systems
- **Requirement**: Target must support restricted admin

### Best Practices Enforced
- No plaintext credential storage
- No automatic credential caching
- Explicit clear credential button
- User confirmation for destructive operations
- Secure dialog for credential input

## Network Requirements

### Protocols Used
- **ICMP**: Ping testing (echo request/reply)
- **DNS**: Name resolution (UDP/TCP port 53)
- **RDP**: Remote desktop (TCP port 3389)
- **SSH**: PuTTY connections (TCP port 22, configurable)
- **WinRM**: Remote PowerShell (HTTP: 5985, HTTPS: 5986)
- **SMB**: File and service access (TCP port 445)

### Firewall Rules Required

**For Local Computer:**
```powershell
# Allow outbound connections (usually default)
New-NetFirewallRule -DisplayName "Network Management Tool - Outbound" `
  -Direction Outbound -Action Allow
```

**For Remote Targets:**
```powershell
# Enable WinRM
Enable-PSRemoting -Force

# Allow WinRM through firewall
Enable-NetFirewallRule -DisplayGroup "Windows Remote Management"

# For RDP
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```

### Required Permissions

**Local Operations:**
- Standard User: Read-only operations
- Administrator: Full functionality

**Remote Operations:**
- Domain User: Basic connectivity tests
- Domain Admin: Full remote management
- Local Admin on Target: Remote admin tasks

## Performance Characteristics

### Resource Usage
```
Idle State:
  CPU: <1%
  Memory: ~80 MB
  Disk I/O: Minimal
  
Active Operations:
  CPU: 5-15% (during operations)
  Memory: ~120 MB
  Network: Varies by operation
  
Heavy Operations (Reboot Monitor):
  CPU: 10-20%
  Memory: ~150 MB
  Network: Continuous ping traffic
```

### Operation Timeouts
```
Ping Test:         1 second per ping
DNS Lookup:        5 seconds
Traceroute:        30 seconds per hop (max 30 hops)
Remote Connection: 30 seconds
Service Query:     15 seconds
Certificate Check: 10 seconds
Health Check:      20 seconds
```

### Optimization Features
- **No Background Loops**: All operations on-demand
- **Efficient Event Handling**: Event-driven architecture
- **Resource Cleanup**: Explicit disposal of connections
- **Lazy Loading**: Operations execute only when requested
- **Tab Isolation**: Each tab independent (no cross-interference)

## Error Handling

### Exception Management
```powershell
Try-Catch Structure:
  Try {
    # Operation code
  }
  Catch {
    # User-friendly error message
    # Troubleshooting tips included
    # Logging to output textbox
  }
```

### User Feedback
- **Success**: Green checkmarks (✓), teal text
- **Warning**: Orange/yellow warnings (⚠), yellow text
- **Error**: Red X marks (✗), red text
- **Info**: Neutral messages, silver text

### Recovery Mechanisms
- **Connection Failures**: Retry prompts
- **Credential Errors**: Re-prompt for credentials
- **Timeout Handling**: Clear timeout messages
- **Partial Failures**: Continue with available data

## Compatibility

### Windows Versions
| Version | Status | Notes |
|---------|--------|-------|
| Windows 10 (1809+) | ✓ Fully Supported | Recommended |
| Windows 10 (older) | ⚠ Limited | May work, not tested |
| Windows 11 | ✓ Fully Supported | Optimal |
| Server 2016+ | ✓ Fully Supported | Ideal for hospital IT |
| Server 2012 R2 | ⚠ Limited | Basic functionality |

### PowerShell Versions
| Version | Status | Notes |
|---------|--------|-------|
| 5.1 | ✓ Fully Supported | Minimum required |
| 7.0+ | ✓ Fully Supported | Enhanced performance |
| 5.0 | ⚠ May Work | Not recommended |
| 4.0 or older | ✗ Not Supported | Will not work |

### Remote Target OS
- Windows 10/11 (all editions)
- Windows Server 2012 R2 through 2022
- Domain-joined or workgroup computers
- Requires WinRM enabled

## Deployment

### Installation
```powershell
# No installation required - single file deployment

# 1. Copy file to desired location
Copy-Item NetworkManagementTool.ps1 C:\IT-Tools\

# 2. (Optional) Create desktop shortcut
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Network Tool.lnk")
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File C:\IT-Tools\NetworkManagementTool.ps1"
$Shortcut.IconLocation = "imageres.dll,93"
$Shortcut.Save()

# 3. Set execution policy if needed
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Distribution
- **Single File**: Just distribute NetworkManagementTool.ps1
- **Network Share**: Place on accessible file share
- **GPO Deployment**: Can be deployed via Group Policy
- **No Dependencies**: Works without additional installations

### Updates
- Replace single file with new version
- No configuration migration needed
- No database or settings files
- Clean slate each run

## Maintenance

### Logging
- **Current**: On-screen only (textboxes)
- **Future**: Could add file logging
- **Security**: No credential logging

### Backups
- **Config**: None (stateless application)
- **Credentials**: Not stored (session-only)
- **History**: Not maintained

### Updates
- Manual replacement of .ps1 file
- Check version in script header
- Review README for changes

## Known Limitations

1. **GUI Only**: No command-line interface
2. **Windows Only**: Requires Windows OS
3. **Single-Threaded**: One operation at a time per tab
4. **No Scheduling**: Cannot schedule automated runs
5. **No Logging**: Output not automatically saved
6. **Session-Only Creds**: Must re-enter each session

## Future Enhancement Possibilities

### Potential Features
- [ ] Export results to file
- [ ] Logging to file option
- [ ] Scheduled health checks
- [ ] Multi-tab simultaneous operations
- [ ] Custom color themes
- [ ] Persistent credential store (encrypted)
- [ ] Dashboard summary view
- [ ] Alert thresholds configuration

### Community Feedback
This tool is designed for internal use. Customize as needed for your environment.

---

**Version**: 1.0  
**Build Date**: 2026  
**Target**: Healthcare IT Operations  
**Classification**: Internal Tool

