# Network Tool UI Layout

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ Network Troubleshooting Tools                                                │
├──────────────────┬──────────────────────────────────────────────────────────┤
│                  │                                                            │
│ Tool Buttons     │ Output Area                                                │
│                  │                                                            │
│ ┌──────────────┐ │ ┌────────────────────────────────────────────────────┐   │
│ │ Continuous   │ │ │ Select a tool to begin                             │   │
│ │ Ping         │ │ ├────────────────────────────────────────────────────┤   │
│ └──────────────┘ │ │                                                     │   │
│ ┌──────────────┐ │ │                                                     │   │
│ │ NSLookup     │ │ │  [Monospace Output Text Box]                        │   │
│ └──────────────┘ │ │  Shows results from selected tool                   │   │
│ ┌──────────────┐ │ │                                                     │   │
│ │ Traceroute   │ │ │                                                     │   │
│ └──────────────┘ │ │                                                     │   │
│ ┌──────────────┐ │ │                                                     │   │
│ │ Check        │ │ │                                                     │   │
│ │ Services     │ │ │                                                     │   │
│ └──────────────┘ │ │                                                     │   │
│ ┌──────────────┐ │ │                                                     │   │
│ │ Check Disk   │ │ ├────────────────────────────────────────────────────┤   │
│ │ Space        │ │ │ [ Clear Output ]                                   │   │
│ └──────────────┘ │ └────────────────────────────────────────────────────┘   │
│ ┌──────────────┐ │                                                            │
│ │ Check CPU/   │ │                                                            │
│ │ Memory       │ │                                                            │
│ └──────────────┘ │                                                            │
│ ┌──────────────┐ │                                                            │
│ │ Uptime       │ │                                                            │
│ │ Checker      │ │                                                            │
│ └──────────────┘ │                                                            │
│ ┌──────────────┐ │                                                            │
│ │ IIS Cert     │ │                                                            │
│ │ Check        │ │                                                            │
│ └──────────────┘ │                                                            │
│ ┌──────────────┐ │                                                            │
│ │ Last Lockout │ │                                                            │
│ └──────────────┘ │                                                            │
│                  │                                                            │
└──────────────────┴──────────────────────────────────────────────────────────┘

Color Scheme:
- Background: Dark blue-black (RGB 12, 14, 24)
- Panels: Slightly lighter blue-grey (RGB 18, 20, 34)
- Cards: Medium blue-grey (RGB 24, 26, 46)
- Text: Light grey-white (RGB 230, 232, 246)
- Accent: Purple (RGB 160, 90, 255)
- Buttons: Blue-purple (RGB 85, 95, 235) or dark grey-blue (RGB 40, 42, 75)

Interaction Flow:
1. User clicks a tool button on the left
2. Tool prompts for required input (hostname, computer name, etc.)
3. Tool executes and displays output in the right panel
4. Status bar at bottom shows current operation
5. User can clear output or run another tool
```

## Key Features

### Left Panel (280px wide)
- Scrollable list of tool buttons
- Each button is 220px wide × 50px high
- Hover effects for interactivity
- Tooltips show tool descriptions

### Right Panel (Expandable)
- Title bar shows current tool name
- Large monospace text box for output
- Scrollable (vertical and horizontal)
- Read-only to prevent accidental edits
- Clear button at bottom

### Split Container
- Resizable divider between panels
- Default split at 280px
- Allows users to adjust panel sizes

## Tool Categories

### Network Diagnostics
- Continuous Ping
- NSLookup
- Traceroute

### System Monitoring
- Check Services
- Check Disk Space
- Check CPU/Memory
- Uptime Checker

### Security & Compliance
- IIS Certificate Check
- Last Lockout

## Usage Pattern

Each tool follows this pattern:
1. **Input**: Prompt user for parameters (via InputBox)
2. **Execution**: Run PowerShell cmdlets to gather data
3. **Output**: Display formatted results in monospace text
4. **Status**: Update status bar with progress/completion

All operations are:
- ✓ User-triggered (no automatic execution)
- ✓ Quick to complete (<30 seconds typical)
- ✓ Error-handled with friendly messages
- ✓ Status-reported to the main status bar
