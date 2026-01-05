# Network Management Tool

## Healthcare IT Network Operations Console - Starship Cockpit Theme

A comprehensive PowerShell-based network diagnostics and management tool designed for hospital IT operations with a futuristic starship cockpit theme.

### Features

#### 🎨 Themed Interface
- Deep-space background (#0F0F0F)
- Teal accent colors (#00B2FF) for actions
- Red accent colors (#FF5733) for warnings
- Rounded, translucent panels
- Clean, modern sans-serif fonts (Segoe UI, Consolas)
- Optimized for 1920x1080 (1080p) displays

#### 🌐 Global Target Host
- Set target hostname/IP once at the top
- All functions automatically use the global target
- Individual tabs can override if needed
- Smooth integration across all tools

#### 🔐 T2 Credentials Management
- Secure credential storage for the session
- Support for restrictedAdmin (/T2) RDP connections
- Credentials stored safely in memory only
- Automatic cleanup on exit

### Tool Tabs

#### 📊 Node Summary
- System information (hostname, domain, uptime)
- Network adapter details (IP, subnet, gateway)
- DNS server configuration
- MAC addresses
- Supports both local and remote computers

#### ❤ Node Health Check
- CPU usage monitoring with thresholds
- Memory usage and availability
- Disk space analysis with warnings
- Critical Windows services status
- Network connectivity verification
- Gateway reachability testing
- Recent event log errors (last 24 hours)
- Perfect for quick health assessments

#### 📡 Ping Test
- On-demand ping testing (no continuous loops)
- Configurable packet count
- Detailed statistics (min/max/avg response times)
- Packet loss calculation
- Uses global target host by default

#### 🔍 NSLookup
- DNS resolution using PowerShell and nslookup
- Forward and reverse lookups
- Detailed DNS record information
- Multiple record type support

#### 🗺 Traceroute
- Network path tracing using tracert
- Hop-by-hop analysis
- Latency measurement per hop
- Timeout and unreachable detection

#### 👥 Domain Users
- List domain users (net user /domain)
- List local users on target computer
- User status (enabled/disabled)
- Last logon information
- Supports remote computers with credentials

#### 🌐 IPConfig
- Full IP configuration (ipconfig /all)
- DNS cache flushing
- DHCP lease renewal
- Network adapter details
- DNS and WINS server information

#### 📊 NetStat
- Active network connections
- Listening ports with PID
- Protocol and state information
- Connection filtering options

#### 🖥 RDP Connection
- Remote Desktop Protocol launcher
- **T2 Feature Support** (/restrictedAdmin)
- Multi-monitor support (/multimon)
- Administrator mode (/admin)
- Credential protection with T2 mode
- Kerberos authentication

#### 🔧 PuTTY SSH
- SSH client launcher
- Auto-detection of PuTTY installation
- Custom port and username support
- Download link for PuTTY
- Supports standard SSH parameters

#### 🔄 Server Reboot Monitor
- Remote server reboot with credentials
- Configurable delay before reboot
- **Visual ping monitoring** during reboot
- Real-time status updates
- Automatic connectivity tracking
- Ping-only monitoring mode

#### 🔒 Certificate Check
- Local computer certificates
- Web hosting certificates
- IIS HTTPS binding certificates
- SQL Server certificate detection
- Expiration date tracking
- Warning for expiring certificates

#### 🛡 ThreatLocker Check
- ThreatLocker event log analysis
- Service status verification
- Installation detection
- Registry check
- Recent blocking events
- Perfect for healthcare security compliance

#### ⚙ Services Manager
- Launch native services.msc
- Remote services management
- Complete service listing
- Status and start type information
- Running/stopped service counts

### Usage

#### Prerequisites
- Windows PowerShell 5.1 or later
- Windows 10/11 or Windows Server 2016+
- Appropriate permissions for remote operations
- WinRM enabled for remote computer access

#### Running the Tool

1. **Download the script:**
   ```powershell
   # Save NetworkManagementTool.ps1 to your computer
   ```

2. **Run as Administrator (recommended):**
   ```powershell
   # Right-click PowerShell and select "Run as Administrator"
   cd C:\Path\To\Script
   .\NetworkManagementTool.ps1
   ```

3. **Set Execution Policy (if needed):**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

#### Using T2 Credentials

For remote operations requiring authentication:

1. Click "Set T2 Credentials" button at the top
2. Enter username and password
3. Credentials are stored securely in memory for the session
4. Click "Clear" to remove credentials when done

#### Setting Global Target Host

1. Enter hostname or IP in the "Target Host" field at the top
2. All tabs will use this target automatically
3. Individual tabs can override by entering a different target locally
4. Default is "localhost" for local operations

### Healthcare IT Use Cases

#### Patient Care Systems
- Monitor medical device servers
- Check connectivity to PACS/EMR systems
- Verify network paths to imaging equipment
- Certificate management for HTTPS services

#### Security & Compliance
- ThreatLocker monitoring
- Certificate expiration tracking
- Service status verification
- Event log analysis

#### Server Management
- Remote server reboots with visual monitoring
- Service management across multiple servers
- Health checks before maintenance windows
- Network diagnostics for troubleshooting

#### Network Operations
- Quick connectivity tests
- DNS troubleshooting
- Port and connection monitoring
- Remote desktop access with T2 security

### Best Practices

#### Security
1. Always use T2 (restrictedAdmin) mode for RDP when possible
2. Clear stored credentials when finished
3. Run from secure workstation
4. Use least-privilege accounts when possible

#### Remote Operations
1. Enable WinRM on target computers
2. Configure firewall rules appropriately
3. Use domain accounts for remote access
4. Test connectivity with ping before other operations

#### Hospital Environment
1. Coordinate reboots during maintenance windows
2. Monitor critical services continuously
3. Check certificates monthly
4. Review ThreatLocker blocks regularly

### Troubleshooting

#### Cannot Connect to Remote Computer
- Verify WinRM is enabled: `winrm quickconfig`
- Check firewall settings
- Confirm credentials have appropriate permissions
- Test basic connectivity with ping

#### RDP with T2 Not Working
- Ensure target supports Restricted Admin mode
- Verify Kerberos authentication is working
- Check Group Policy settings
- Use regular RDP mode as fallback

#### ThreatLocker Events Not Found
- Verify ThreatLocker is installed
- Check event log permissions
- Run as Administrator
- Confirm ThreatLocker service is running

### Technical Details

#### Architecture
- Pure PowerShell with Windows Forms
- No external dependencies
- Self-contained single-file application
- Memory-safe credential handling

#### Performance
- All operations are on-demand (no background loops)
- Efficient event-driven UI
- Minimal resource footprint
- Fast tab switching

#### Theme Implementation
- Follows starship cockpit design guidelines
- Near-black deep-space background (#0F0F0F)
- Teal glow accents (#00B2FF)
- Red warnings (#FF5733)
- Optimal contrast ratios for readability

### Version History

#### Version 1.0 - Initial Release
- 14 comprehensive tool tabs
- Global target host functionality
- T2 credential management
- Healthcare IT-specific features
- Starship cockpit theme
- Complete documentation

### License

This tool is provided as-is for internal use. Modify as needed for your environment.

### Support

For issues or feature requests, contact your IT department.

---

**Designed for Healthcare IT Professionals**  
*Streamline your network operations with a powerful, themed management console*
