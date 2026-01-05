# Network Management Tool - Quick Start Guide

## 🚀 Getting Started in 3 Steps

### Step 1: Launch the Tool
```powershell
# Right-click PowerShell and select "Run as Administrator"
cd C:\Path\To\Tool
.\NetworkManagementTool.ps1
```

### Step 2: Set Up Credentials (if needed for remote operations)
1. Click **"🔐 Set T2 Creds"** button at the top
2. Enter your admin username and password
3. Credentials are stored securely in memory only

### Step 3: Enter Target Host
1. Type hostname or IP in the **"Target Host"** field
2. All tabs will automatically use this target
3. Default is "localhost" for local operations

## 📋 Common Tasks

### Quick Health Check
1. Navigate to **"❤ Node Health"** tab
2. Click **"🏥 Check Node Health"**
3. Review CPU, memory, disk, and service status

### Ping a Server
1. Navigate to **"📡 Ping Test"** tab
2. Target auto-fills from global field
3. Click **"▶ Ping"**
4. View response times and statistics

### Remote Desktop Connection (with T2)
1. Navigate to **"🖥 RDP"** tab
2. Ensure **"🔐 T2 Feature"** is checked
3. Click **"▶ Connect RDP"**
4. RDP window opens automatically

### Reboot Server with Monitoring
1. Navigate to **"🔄 Server Reboot"** tab
2. Enter target server name
3. Set delay (default 30 seconds)
4. Click **"🔄 Reboot Server"**
5. Watch real-time ping monitoring

### Check Certificates
1. Navigate to **"🔒 Certificates"** tab
2. Click **"🔍 Check All Certificates"**
3. Review expiration dates
4. Look for warnings (⚠)

### Check ThreatLocker Status
1. Navigate to **"🛡 ThreatLocker"** tab
2. Click **"🔍 Check ThreatLocker"**
3. Review recent blocking events
4. Check service status

## 🎯 Hospital IT Scenarios

### Morning Server Check
```
1. Set target to main server
2. Node Health Check → verify all systems normal
3. Certificate Check → ensure no expiring certs
4. ThreatLocker Check → review overnight blocks
```

### Troubleshooting Connectivity
```
1. Ping Test → verify basic connectivity
2. Traceroute → identify network path issues
3. NSLookup → verify DNS resolution
4. NetStat → check active connections
```

### Server Maintenance
```
1. Services → review running services
2. Node Summary → document current config
3. Server Reboot → reboot with monitoring
4. Node Health → verify post-reboot status
```

### Certificate Management
```
1. Certificates → check all cert expiration
2. IIS Certs Only → review web certificates
3. SQL Certs Only → check database certs
4. Document renewals needed
```

## 💡 Pro Tips

### Keyboard Shortcuts
- **Tab** - Switch between fields
- **Enter** - Execute focused button
- **Esc** - Close credential dialogs

### Best Practices
1. ✓ Always use T2 mode for RDP when possible
2. ✓ Clear credentials when done (**"Clear"** button)
3. ✓ Use during maintenance windows for reboots
4. ✓ Save outputs before clearing screens
5. ✓ Test on non-critical systems first

### Time-Saving Features
- Set global target once, use everywhere
- Stored credentials work across all tabs
- Clear button on every tab for quick resets
- All operations are on-demand (no waiting)

## ⚠ Important Notes

### Security
- Credentials stored in memory only (cleared on exit)
- T2 mode prevents credential exposure to remote PC
- Always clear credentials after sensitive operations

### Remote Access
- Requires WinRM enabled on target computers
- Firewall must allow remote management
- Use domain accounts for best results

### Hospital Environment
- Coordinate reboots with clinical staff
- Monitor critical medical device servers carefully
- Keep ThreatLocker running at all times
- Review certificates monthly

## 🛠 Troubleshooting

### "Access Denied" Error
→ Load T2 credentials at the top
→ Verify account has admin rights
→ Check WinRM is enabled

### "Cannot Connect" Error
→ Ping the target first
→ Verify hostname/IP is correct
→ Check firewall settings

### RDP T2 Not Working
→ Uncheck T2 feature as fallback
→ Verify target supports restrictedAdmin
→ Check Group Policy settings

## 📞 Getting Help

### Built-in Help
- Every tab has clear button labels
- Error messages include troubleshooting tips
- Hover over buttons for tooltips (where available)

### Common Questions

**Q: Can I use this on multiple computers at once?**  
A: Yes! Run multiple instances of the tool.

**Q: Do credentials persist after closing?**  
A: No, they're cleared from memory on exit.

**Q: Can I save the output?**  
A: Copy/paste from text boxes. Logs aren't auto-saved.

**Q: What if target host is offline?**  
A: Operations will timeout with error messages.

## 🎨 Interface Guide

### Color Coding
- **Teal (#00B2FF)** - Action buttons, success messages
- **Red (#FF5733)** - Warnings, errors, critical actions
- **Silver (#C0C0C0)** - Clear/cancel operations
- **Green** - Confirmed credentials, healthy status
- **Yellow** - Caution, requires attention

### Status Indicators
- **✓** - Success, running, healthy
- **⚠** - Warning, attention needed
- **✗** - Error, failed, stopped
- **○** - Neutral, stopped service
- **⚡** - Moderate warning level

## 🔄 Workflow Examples

### Daily Operations Check
```powershell
Morning Routine:
1. Launch tool as admin
2. Set T2 credentials once
3. Target: main-server-01
   - Health Check
   - Certificate Check
   - ThreatLocker Check
4. Target: backup-server-02
   - Repeat checks
5. Clear credentials
6. Close tool
```

### Emergency Troubleshooting
```powershell
When Server Goes Down:
1. Quick launch tool
2. Ping Test → is it reachable?
3. If yes: Health Check → what's wrong?
4. If no: Traceroute → where's the break?
5. Services → check critical services
6. Event logs in Health Check
7. Document findings
```

---

**Need More Help?**  
See full README.md for detailed documentation.

**Ready to Deploy!**  
This tool is production-ready for hospital IT environments.
