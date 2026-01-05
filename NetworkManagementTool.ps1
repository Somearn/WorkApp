# ═══════════════════════════════════════════════════════════════════════════════
# NETWORK MANAGEMENT TOOL - STARSHIP COCKPIT THEME
# Healthcare IT Network Operations Console
# Version 1.0 - Hospital Environment Edition
# ═══════════════════════════════════════════════════════════════════════════════

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ═══════════════════════════════════════════════════════════════════════════════
# GLOBAL VARIABLES - Session-scoped, cleared on exit
# ═══════════════════════════════════════════════════════════════════════════════
$script:storedCredentials = $null
$script:globalTargetHost = "localhost"

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

function Get-T2Credentials {
    param([string]$Purpose = "remote operations")
    
    $credForm = New-Object System.Windows.Forms.Form
    $credForm.Text = "Enter T2 Credentials"
    $credForm.ClientSize = New-Object System.Drawing.Size(500, 240)
    $credForm.StartPosition = "CenterParent"
    $credForm.BackColor = [System.Drawing.Color]::FromArgb(33, 33, 33)
    $credForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $credForm.MaximizeBox = $false
    $credForm.MinimizeBox = $false
    
    $lblInfo = New-Object System.Windows.Forms.Label
    $lblInfo.Text = "Enter credentials for $Purpose"
    $lblInfo.Location = New-Object System.Drawing.Point(20, 10)
    $lblInfo.Size = New-Object System.Drawing.Size(450, 20)
    $lblInfo.ForeColor = [System.Drawing.Color]::FromArgb(0, 178, 255)
    $lblInfo.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $credForm.Controls.Add($lblInfo)
    
    $lblUser = New-Object System.Windows.Forms.Label
    $lblUser.Text = "Username:"
    $lblUser.Location = New-Object System.Drawing.Point(20, 45)
    $lblUser.Size = New-Object System.Drawing.Size(110, 20)
    $lblUser.ForeColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $credForm.Controls.Add($lblUser)
    
    $txtUser = New-Object System.Windows.Forms.TextBox
    $txtUser.Location = New-Object System.Drawing.Point(140, 43)
    $txtUser.Size = New-Object System.Drawing.Size(320, 20)
    $txtUser.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $txtUser.ForeColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $credForm.Controls.Add($txtUser)
    
    $lblPass = New-Object System.Windows.Forms.Label
    $lblPass.Text = "Password:"
    $lblPass.Location = New-Object System.Drawing.Point(20, 85)
    $lblPass.Size = New-Object System.Drawing.Size(110, 20)
    $lblPass.ForeColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $credForm.Controls.Add($lblPass)
    
    $txtPass = New-Object System.Windows.Forms.TextBox
    $txtPass.Location = New-Object System.Drawing.Point(140, 83)
    $txtPass.Size = New-Object System.Drawing.Size(320, 20)
    $txtPass.PasswordChar = "●"
    $txtPass.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $txtPass.ForeColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $credForm.Controls.Add($txtPass)
    
    $lblNote = New-Object System.Windows.Forms.Label
    $lblNote.Text = "⚠ Credentials stored securely in memory for this session only"
    $lblNote.Location = New-Object System.Drawing.Point(20, 115)
    $lblNote.Size = New-Object System.Drawing.Size(450, 30)
    $lblNote.ForeColor = [System.Drawing.Color]::FromArgb(192, 192, 192)
    $lblNote.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $credForm.Controls.Add($lblNote)
    
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "✓ OK"
    $btnOK.Location = New-Object System.Drawing.Point(210, 160)
    $btnOK.Size = New-Object System.Drawing.Size(120, 35)
    $btnOK.BackColor = [System.Drawing.Color]::FromArgb(0, 178, 255)
    $btnOK.ForeColor = [System.Drawing.Color]::White
    $btnOK.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnOK.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $credForm.Controls.Add($btnOK)
    
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "✗ Cancel"
    $btnCancel.Location = New-Object System.Drawing.Point(340, 160)
    $btnCancel.Size = New-Object System.Drawing.Size(120, 35)
    $btnCancel.BackColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
    $btnCancel.ForeColor = [System.Drawing.Color]::White
    $btnCancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnCancel.Font = New-Object System.Drawing.Font("Segoe UI", 12)
    $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $credForm.Controls.Add($btnCancel)
    
    $credForm.AcceptButton = $btnOK
    $credForm.CancelButton = $btnCancel
    
    $result = $credForm.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK -and -not [string]::IsNullOrWhiteSpace($txtUser.Text)) {
        try {
            $secPass = ConvertTo-SecureString $txtPass.Text -AsPlainText -Force
            return New-Object System.Management.Automation.PSCredential($txtUser.Text, $secPass)
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error creating credentials: $($_.Exception.Message)", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    return $null
}

function Write-OutputSafe {
    param(
        [System.Windows.Forms.TextBox]$TextBox,
        [string]$Text
    )
    try {
        if ($TextBox -and $TextBox.IsHandleCreated) {
            $TextBox.AppendText($Text)
        }
    } catch {
        # Silently handle disposed controls
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN FORM SETUP
# ═══════════════════════════════════════════════════════════════════════════════

$form = New-Object System.Windows.Forms.Form
$form.Text = "Network Management Tool - Healthcare IT Operations Console"
$form.ClientSize = New-Object System.Drawing.Size(1920, 1080)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(15, 15, 15)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
$form.MaximizeBox = $true
$form.MinimizeBox = $true

# Theme Colors
$nearBlack = [System.Drawing.Color]::FromArgb(15, 15, 15)
$darkGray = [System.Drawing.Color]::FromArgb(33, 33, 33)
$teal = [System.Drawing.Color]::FromArgb(0, 178, 255)
$red = [System.Drawing.Color]::FromArgb(255, 87, 51)
$silver = [System.Drawing.Color]::FromArgb(192, 192, 192)
$textColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$yellow = [System.Drawing.Color]::FromArgb(255, 193, 7)
$green = [System.Drawing.Color]::FromArgb(76, 175, 80)

# Fonts
$generalFont = New-Object System.Drawing.Font("Segoe UI", 12)
$titleFont = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$monoFont = New-Object System.Drawing.Font("Consolas", 12)
$smallFont = New-Object System.Drawing.Font("Segoe UI", 11)

# ═══════════════════════════════════════════════════════════════════════════════
# HEADER - GLOBAL TARGET HOST & CREDENTIALS
# ═══════════════════════════════════════════════════════════════════════════════

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "⬢ NETWORK MANAGEMENT TOOL ⬢"
$titleLabel.Font = $titleFont
$titleLabel.ForeColor = $teal
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$titleLabel.AutoSize = $false
$titleLabel.Size = New-Object System.Drawing.Size(600, 35)
$titleLabel.Location = New-Object System.Drawing.Point(20, 10)
$titleLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$form.Controls.Add($titleLabel)

$lblGlobalHost = New-Object System.Windows.Forms.Label
$lblGlobalHost.Text = "Target Host:"
$lblGlobalHost.Location = New-Object System.Drawing.Point(650, 15)
$lblGlobalHost.Size = New-Object System.Drawing.Size(100, 25)
$lblGlobalHost.ForeColor = $textColor
$lblGlobalHost.Font = $generalFont
$form.Controls.Add($lblGlobalHost)

$txtGlobalHost = New-Object System.Windows.Forms.TextBox
$txtGlobalHost.Location = New-Object System.Drawing.Point(760, 13)
$txtGlobalHost.Size = New-Object System.Drawing.Size(350, 25)
$txtGlobalHost.BackColor = $darkGray
$txtGlobalHost.ForeColor = $teal
$txtGlobalHost.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$txtGlobalHost.Text = "localhost"
$txtGlobalHost.Add_TextChanged({
    $script:globalTargetHost = $txtGlobalHost.Text
})
$form.Controls.Add($txtGlobalHost)

$btnSetCredentials = New-Object System.Windows.Forms.Button
$btnSetCredentials.Text = "🔐 Set T2 Creds"
$btnSetCredentials.Location = New-Object System.Drawing.Point(1130, 10)
$btnSetCredentials.Size = New-Object System.Drawing.Size(150, 30)
$btnSetCredentials.BackColor = $darkGray
$btnSetCredentials.ForeColor = $teal
$btnSetCredentials.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnSetCredentials.FlatAppearance.BorderColor = $teal
$btnSetCredentials.FlatAppearance.BorderSize = 2
$btnSetCredentials.Font = $generalFont
$form.Controls.Add($btnSetCredentials)

$lblCredStatus = New-Object System.Windows.Forms.Label
$lblCredStatus.Text = "No credentials"
$lblCredStatus.Location = New-Object System.Drawing.Point(1290, 15)
$lblCredStatus.Size = New-Object System.Drawing.Size(300, 25)
$lblCredStatus.ForeColor = $silver
$lblCredStatus.Font = $smallFont
$form.Controls.Add($lblCredStatus)

$btnSetCredentials.Add_Click({
    $cred = Get-T2Credentials
    if ($cred) {
        $script:storedCredentials = $cred
        $lblCredStatus.Text = "✓ Loaded: $($cred.UserName)"
        $lblCredStatus.ForeColor = $green
    }
})

$btnClearCred = New-Object System.Windows.Forms.Button
$btnClearCred.Text = "Clear"
$btnClearCred.Location = New-Object System.Drawing.Point(1600, 10)
$btnClearCred.Size = New-Object System.Drawing.Size(80, 30)
$btnClearCred.BackColor = $darkGray
$btnClearCred.ForeColor = $red
$btnClearCred.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearCred.FlatAppearance.BorderColor = $red
$btnClearCred.Font = $generalFont
$form.Controls.Add($btnClearCred)

$btnClearCred.Add_Click({
    $script:storedCredentials = $null
    $lblCredStatus.Text = "No credentials"
    $lblCredStatus.ForeColor = $silver
    [System.Windows.Forms.MessageBox]::Show("Credentials cleared from memory.", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})

# ═══════════════════════════════════════════════════════════════════════════════
# LEFT NAVIGATION PANEL
# ═══════════════════════════════════════════════════════════════════════════════

$navPanel = New-Object System.Windows.Forms.Panel
$navPanel.Location = New-Object System.Drawing.Point(20, 55)
$navPanel.Size = New-Object System.Drawing.Size(250, 980)
$navPanel.BackColor = $darkGray
$navPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($navPanel)

$navLabel = New-Object System.Windows.Forms.Label
$navLabel.Text = "TOOLS"
$navLabel.Location = New-Object System.Drawing.Point(10, 10)
$navLabel.Size = New-Object System.Drawing.Size(230, 30)
$navLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$navLabel.ForeColor = $teal
$navLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$navPanel.Controls.Add($navLabel)

$navListBox = New-Object System.Windows.Forms.ListBox
$navListBox.Location = New-Object System.Drawing.Point(10, 50)
$navListBox.Size = New-Object System.Drawing.Size(230, 920)
$navListBox.BackColor = $nearBlack
$navListBox.ForeColor = $textColor
$navListBox.Font = $generalFont
$navListBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$navListBox.Items.AddRange(@(
    "📊 Node Summary",
    "❤ Node Health",
    "📡 Ping Test",
    "🔍 NSLookup",
    "🗺 Traceroute",
    "👥 Domain Users",
    "🌐 IPConfig",
    "📈 NetStat",
    "🖥 RDP",
    "🔧 PuTTY SSH",
    "🔄 Server Reboot",
    "🔒 Certificates",
    "🛡 ThreatLocker",
    "⚙ Services"
))
$navListBox.SelectedIndex = 0
$navPanel.Controls.Add($navListBox)

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN CONTENT PANEL
# ═══════════════════════════════════════════════════════════════════════════════

$contentPanel = New-Object System.Windows.Forms.Panel
$contentPanel.Location = New-Object System.Drawing.Point(280, 55)
$contentPanel.Size = New-Object System.Drawing.Size(1610, 980)
$contentPanel.BackColor = $nearBlack
$contentPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($contentPanel)

# ═══════════════════════════════════════════════════════════════════════════════
# PANEL 1: NODE SUMMARY - System information and network configuration
# ═══════════════════════════════════════════════════════════════════════════════
$panelNodeSummary = New-Object System.Windows.Forms.Panel
$panelNodeSummary.Location = New-Object System.Drawing.Point(0, 0)
$panelNodeSummary.Size = New-Object System.Drawing.Size(1610, 980)
$panelNodeSummary.BackColor = $nearBlack
$panelNodeSummary.Visible = $true
$contentPanel.Controls.Add($panelNodeSummary)

$btnGetNodeInfo = New-Object System.Windows.Forms.Button
$btnGetNodeInfo.Text = "🔍 Get Node Summary"
$btnGetNodeInfo.Location = New-Object System.Drawing.Point(20, 20)
$btnGetNodeInfo.Size = New-Object System.Drawing.Size(200, 35)
$btnGetNodeInfo.BackColor = $darkGray
$btnGetNodeInfo.ForeColor = $teal
$btnGetNodeInfo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnGetNodeInfo.FlatAppearance.BorderColor = $teal
$btnGetNodeInfo.FlatAppearance.BorderSize = 2
$btnGetNodeInfo.Font = $generalFont
$panelNodeSummary.Controls.Add($btnGetNodeInfo)

$btnClearNodeInfo = New-Object System.Windows.Forms.Button
$btnClearNodeInfo.Text = "🗑 Clear"
$btnClearNodeInfo.Location = New-Object System.Drawing.Point(230, 20)
$btnClearNodeInfo.Size = New-Object System.Drawing.Size(100, 35)
$btnClearNodeInfo.BackColor = $darkGray
$btnClearNodeInfo.ForeColor = $silver
$btnClearNodeInfo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearNodeInfo.FlatAppearance.BorderColor = $silver
$btnClearNodeInfo.Font = $generalFont
$panelNodeSummary.Controls.Add($btnClearNodeInfo)

$txtNodeInfo = New-Object System.Windows.Forms.TextBox
$txtNodeInfo.Location = New-Object System.Drawing.Point(20, 70)
$txtNodeInfo.Size = New-Object System.Drawing.Size(1550, 870)
$txtNodeInfo.Multiline = $true
$txtNodeInfo.ScrollBars = "Vertical"
$txtNodeInfo.BackColor = $darkGray
$txtNodeInfo.ForeColor = $textColor
$txtNodeInfo.Font = $monoFont
$txtNodeInfo.ReadOnly = $true
$panelNodeSummary.Controls.Add($txtNodeInfo)

$btnGetNodeInfo.Add_Click({
    $targetHost = $script:globalTargetHost
    if ([string]::IsNullOrWhiteSpace($targetHost)) { $targetHost = "localhost" }
    
    $txtNodeInfo.Text = "═══════════════════════════════════════════════════════════════`r`n"
    $txtNodeInfo.AppendText("  NODE SUMMARY - $targetHost`r`n")
    $txtNodeInfo.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
    
    try {
        $isLocal = ($targetHost -eq "localhost" -or $targetHost -eq "." -or $targetHost -eq $env:COMPUTERNAME)
        
        if ($isLocal) {
            # Local computer information
            $txtNodeInfo.AppendText("► SYSTEM INFORMATION:`r`n")
            $txtNodeInfo.AppendText("  Computer Name: $env:COMPUTERNAME`r`n")
            $txtNodeInfo.AppendText("  User: $env:USERNAME`r`n")
            $txtNodeInfo.AppendText("  Domain: $env:USERDOMAIN`r`n`r`n")
            
            # Uptime
            $os = Get-CimInstance Win32_OperatingSystem
            $lastBoot = $os.LastBootUpTime
            $uptime = (Get-Date) - $lastBoot
            $txtNodeInfo.AppendText("► UPTIME & BOOT TIME:`r`n")
            $txtNodeInfo.AppendText("  Last Boot: $lastBoot`r`n")
            $txtNodeInfo.AppendText("  Uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m`r`n`r`n")
            
            # OS Information
            $txtNodeInfo.AppendText("► OPERATING SYSTEM:`r`n")
            $txtNodeInfo.AppendText("  OS: $($os.Caption)`r`n")
            $txtNodeInfo.AppendText("  Version: $($os.Version)`r`n")
            $txtNodeInfo.AppendText("  Build: $($os.BuildNumber)`r`n`r`n")
            
            # Network Adapters
            $txtNodeInfo.AppendText("► NETWORK ADAPTERS:`r`n")
            $adapters = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" }
            foreach ($adapter in $adapters) {
                $txtNodeInfo.AppendText("  Interface: $($adapter.InterfaceAlias)`r`n")
                $txtNodeInfo.AppendText("  IP Address: $($adapter.IPAddress)`r`n")
                $txtNodeInfo.AppendText("  Subnet: /$($adapter.PrefixLength)`r`n")
                $txtNodeInfo.AppendText("  ─────────────────────────────────────────────────────`r`n")
            }
            
            # Default Gateway
            $txtNodeInfo.AppendText("`r`n► DEFAULT GATEWAY:`r`n")
            $gateways = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty NextHop -Unique
            foreach ($gw in $gateways) {
                if ($gw -ne "0.0.0.0" -and $gw -ne "::") {
                    $txtNodeInfo.AppendText("  $gw`r`n")
                }
            }
            
            # DNS Servers
            $txtNodeInfo.AppendText("`r`n► DNS SERVERS:`r`n")
            $dnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.ServerAddresses.Count -gt 0 }
            foreach ($dns in $dnsServers) {
                if ($dns.ServerAddresses.Count -gt 0) {
                    $txtNodeInfo.AppendText("  Interface: $($dns.InterfaceAlias)`r`n")
                    foreach ($server in $dns.ServerAddresses) {
                        $txtNodeInfo.AppendText("    DNS: $server`r`n")
                    }
                }
            }
            
            # MAC Addresses
            $txtNodeInfo.AppendText("`r`n► MAC ADDRESSES:`r`n")
            $macs = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
            foreach ($mac in $macs) {
                $txtNodeInfo.AppendText("  $($mac.Name): $($mac.MacAddress)`r`n")
            }
            
        } else {
            # Remote computer - requires credentials
            $txtNodeInfo.AppendText("Connecting to remote computer: $targetHost`r`n`r`n")
            
            $cred = $script:storedCredentials
            if (-not $cred) {
                $result = [System.Windows.Forms.MessageBox]::Show("No credentials loaded. Load credentials now?", "Credentials Required", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
                if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                    $cred = Get-T2Credentials -Purpose "accessing $targetHost"
                    if ($cred) {
                        $script:storedCredentials = $cred
                        $lblCredStatus.Text = "✓ Loaded: $($cred.UserName)"
                        $lblCredStatus.ForeColor = $green
                    }
                }
            }
            
            if ($cred) {
                $session = New-PSSession -ComputerName $targetHost -Credential $cred -ErrorAction Stop
                $remoteData = Invoke-Command -Session $session -ScriptBlock {
                    $data = @{}
                    $data.ComputerName = $env:COMPUTERNAME
                    $data.Username = $env:USERNAME
                    $data.Domain = $env:USERDOMAIN
                    $os = Get-CimInstance Win32_OperatingSystem
                    $data.LastBoot = $os.LastBootUpTime
                    $data.Uptime = (Get-Date) - $os.LastBootUpTime
                    $data.OSCaption = $os.Caption
                    $data.OSVersion = $os.Version
                    $data.OSBuild = $os.BuildNumber
                    $data.IPAddresses = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" }
                    $data.Gateways = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty NextHop -Unique | Where-Object { $_ -ne "0.0.0.0" }
                    $data.DNS = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.ServerAddresses.Count -gt 0 }
                    $data.MACs = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
                    return $data
                }
                Remove-PSSession -Session $session
                
                $txtNodeInfo.AppendText("► SYSTEM INFORMATION:`r`n")
                $txtNodeInfo.AppendText("  Computer Name: $($remoteData.ComputerName)`r`n")
                $txtNodeInfo.AppendText("  User: $($remoteData.Username)`r`n")
                $txtNodeInfo.AppendText("  Domain: $($remoteData.Domain)`r`n`r`n")
                
                $txtNodeInfo.AppendText("► UPTIME:`r`n")
                $txtNodeInfo.AppendText("  Last Boot: $($remoteData.LastBoot)`r`n")
                $txtNodeInfo.AppendText("  Uptime: $($remoteData.Uptime.Days)d $($remoteData.Uptime.Hours)h $($remoteData.Uptime.Minutes)m`r`n`r`n")
                
                $txtNodeInfo.AppendText("► OPERATING SYSTEM:`r`n")
                $txtNodeInfo.AppendText("  OS: $($remoteData.OSCaption)`r`n")
                $txtNodeInfo.AppendText("  Version: $($remoteData.OSVersion)`r`n")
                $txtNodeInfo.AppendText("  Build: $($remoteData.OSBuild)`r`n`r`n")
                
                $txtNodeInfo.AppendText("► NETWORK ADAPTERS:`r`n")
                foreach ($adapter in $remoteData.IPAddresses) {
                    $txtNodeInfo.AppendText("  $($adapter.InterfaceAlias): $($adapter.IPAddress)/$($adapter.PrefixLength)`r`n")
                }
                
                $txtNodeInfo.AppendText("`r`n► GATEWAYS:`r`n")
                foreach ($gw in $remoteData.Gateways) {
                    $txtNodeInfo.AppendText("  $gw`r`n")
                }
            } else {
                $txtNodeInfo.AppendText("✗ Operation cancelled - no credentials provided`r`n")
            }
        }
        
        $txtNodeInfo.AppendText("`r`n═══════════════════════════════════════════════════════════════`r`n")
        $txtNodeInfo.AppendText("  SUMMARY COMPLETE`r`n")
        $txtNodeInfo.AppendText("═══════════════════════════════════════════════════════════════`r`n")
        
    } catch {
        $txtNodeInfo.AppendText("`r`n✗ ERROR: $($_.Exception.Message)`r`n")
        $txtNodeInfo.AppendText("`r`nTroubleshooting:`r`n")
        $txtNodeInfo.AppendText("• Verify the target host is reachable`r`n")
        $txtNodeInfo.AppendText("• Check credentials if connecting remotely`r`n")
        $txtNodeInfo.AppendText("• Ensure WinRM is enabled on remote computer`r`n")
    }
})

$btnClearNodeInfo.Add_Click({
    $txtNodeInfo.Clear()
})



# ═══════════════════════════════════════════════════════════════════════════════
# PANEL 2: NODE HEALTH CHECK - Quick health diagnostics
# ═══════════════════════════════════════════════════════════════════════════════
$panelNodeHealth = New-Object System.Windows.Forms.Panel
$panelNodeHealth.Location = New-Object System.Drawing.Point(0, 0)
$panelNodeHealth.Size = New-Object System.Drawing.Size(1610, 980)
$panelNodeHealth.BackColor = $nearBlack
$panelNodeHealth.Visible = $false
$contentPanel.Controls.Add($panelNodeHealth)

$btnCheckHealth = New-Object System.Windows.Forms.Button
$btnCheckHealth.Text = "🏥 Check Node Health"
$btnCheckHealth.Location = New-Object System.Drawing.Point(20, 20)
$btnCheckHealth.Size = New-Object System.Drawing.Size(200, 35)
$btnCheckHealth.BackColor = $darkGray
$btnCheckHealth.ForeColor = $teal
$btnCheckHealth.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCheckHealth.FlatAppearance.BorderColor = $teal
$btnCheckHealth.FlatAppearance.BorderSize = 2
$btnCheckHealth.Font = $generalFont
$panelNodeHealth.Controls.Add($btnCheckHealth)

$btnClearHealth = New-Object System.Windows.Forms.Button
$btnClearHealth.Text = "🗑 Clear"
$btnClearHealth.Location = New-Object System.Drawing.Point(230, 20)
$btnClearHealth.Size = New-Object System.Drawing.Size(100, 35)
$btnClearHealth.BackColor = $darkGray
$btnClearHealth.ForeColor = $silver
$btnClearHealth.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearHealth.FlatAppearance.BorderColor = $silver
$btnClearHealth.Font = $generalFont
$panelNodeHealth.Controls.Add($btnClearHealth)

$txtHealthOutput = New-Object System.Windows.Forms.TextBox
$txtHealthOutput.Location = New-Object System.Drawing.Point(20, 70)
$txtHealthOutput.Size = New-Object System.Drawing.Size(1550, 870)
$txtHealthOutput.Multiline = $true
$txtHealthOutput.ScrollBars = "Vertical"
$txtHealthOutput.BackColor = $darkGray
$txtHealthOutput.ForeColor = $textColor
$txtHealthOutput.Font = $monoFont
$txtHealthOutput.ReadOnly = $true
$panelNodeHealth.Controls.Add($txtHealthOutput)

$btnCheckHealth.Add_Click({
    $targetHost = $script:globalTargetHost
    if ([string]::IsNullOrWhiteSpace($targetHost)) { $targetHost = "localhost" }
    
    $txtHealthOutput.Text = "═══════════════════════════════════════════════════════════════`r`n"
    $txtHealthOutput.AppendText("  NODE HEALTH CHECK - $targetHost`r`n")
    $txtHealthOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
    
    try {
        $isLocal = ($targetHost -eq "localhost" -or $targetHost -eq "." -or $targetHost -eq $env:COMPUTERNAME)
        
        if ($isLocal) {
            # CPU Usage
            $txtHealthOutput.AppendText("► CPU USAGE:`r`n")
            $cpu = Get-CimInstance Win32_Processor
            $cpuUsage = $cpu.LoadPercentage
            if ($cpuUsage -gt 80) {
                $txtHealthOutput.AppendText("  ⚠ WARNING: CPU at $cpuUsage% (HIGH)`r`n")
            } elseif ($cpuUsage -gt 60) {
                $txtHealthOutput.AppendText("  ⚡ CPU at $cpuUsage% (Moderate)`r`n")
            } else {
                $txtHealthOutput.AppendText("  ✓ CPU at $cpuUsage% (Normal)`r`n")
            }
            $txtHealthOutput.AppendText("  Processor: $($cpu.Name)`r`n")
            $txtHealthOutput.AppendText("  Cores: $($cpu.NumberOfCores) | Logical: $($cpu.NumberOfLogicalProcessors)`r`n`r`n")
            
            # Memory Usage
            $txtHealthOutput.AppendText("► MEMORY USAGE:`r`n")
            $os = Get-CimInstance Win32_OperatingSystem
            $totalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
            $freeMem = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
            $usedMem = $totalMem - $freeMem
            $memPercent = [math]::Round(($usedMem / $totalMem) * 100, 1)
            
            if ($memPercent -gt 90) {
                $txtHealthOutput.AppendText("  ⚠ CRITICAL: Memory at $memPercent% used`r`n")
            } elseif ($memPercent -gt 75) {
                $txtHealthOutput.AppendText("  ⚡ WARNING: Memory at $memPercent% used`r`n")
            } else {
                $txtHealthOutput.AppendText("  ✓ Memory at $memPercent% used (Normal)`r`n")
            }
            $txtHealthOutput.AppendText("  Total: $totalMem GB | Used: $usedMem GB | Free: $freeMem GB`r`n`r`n")
            
            # Disk Space
            $txtHealthOutput.AppendText("► DISK SPACE:`r`n")
            $disks = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
            foreach ($disk in $disks) {
                $totalSpace = [math]::Round($disk.Size / 1GB, 2)
                $freeSpace = [math]::Round($disk.FreeSpace / 1GB, 2)
                $usedSpace = $totalSpace - $freeSpace
                $diskPercent = [math]::Round(($usedSpace / $totalSpace) * 100, 1)
                
                if ($diskPercent -gt 90) {
                    $txtHealthOutput.AppendText("  ⚠ CRITICAL: Drive $($disk.DeviceID) at $diskPercent% full`r`n")
                } elseif ($diskPercent -gt 75) {
                    $txtHealthOutput.AppendText("  ⚡ WARNING: Drive $($disk.DeviceID) at $diskPercent% full`r`n")
                } else {
                    $txtHealthOutput.AppendText("  ✓ Drive $($disk.DeviceID) at $diskPercent% used (Normal)`r`n")
                }
                $txtHealthOutput.AppendText("    Total: $totalSpace GB | Free: $freeSpace GB`r`n")
            }
            
            # Running Services (Critical Windows Services)
            $txtHealthOutput.AppendText("`r`n► CRITICAL SERVICES STATUS:`r`n")
            $criticalServices = @("wuauserv", "Winmgmt", "Dnscache", "LanmanServer", "LanmanWorkstation", "W32Time")
            foreach ($svcName in $criticalServices) {
                $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
                if ($svc) {
                    if ($svc.Status -eq "Running") {
                        $txtHealthOutput.AppendText("  ✓ $($svc.DisplayName): Running`r`n")
                    } else {
                        $txtHealthOutput.AppendText("  ⚠ $($svc.DisplayName): $($svc.Status)`r`n")
                    }
                }
            }
            
            # Network Connectivity
            $txtHealthOutput.AppendText("`r`n► NETWORK CONNECTIVITY:`r`n")
            $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
            if ($adapters.Count -gt 0) {
                $txtHealthOutput.AppendText("  ✓ Active Network Adapters: $($adapters.Count)`r`n")
                foreach ($adapter in $adapters) {
                    $txtHealthOutput.AppendText("    • $($adapter.Name) ($($adapter.LinkSpeed))`r`n")
                }
            } else {
                $txtHealthOutput.AppendText("  ⚠ No active network adapters found`r`n")
            }
            
            # Ping Test to Gateway
            $txtHealthOutput.AppendText("`r`n► GATEWAY CONNECTIVITY:`r`n")
            $gateway = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty NextHop
            if ($gateway -and $gateway -ne "0.0.0.0") {
                $pingResult = Test-Connection -ComputerName $gateway -Count 2 -Quiet -ErrorAction SilentlyContinue
                if ($pingResult) {
                    $txtHealthOutput.AppendText("  ✓ Gateway $gateway is reachable`r`n")
                } else {
                    $txtHealthOutput.AppendText("  ⚠ Gateway $gateway is NOT reachable`r`n")
                }
            }
            
            # Event Log Errors (Last 24 hours)
            $txtHealthOutput.AppendText("`r`n► RECENT EVENT LOG ERRORS (Last 24h):`r`n")
            $errors = Get-EventLog -LogName System -EntryType Error -After (Get-Date).AddHours(-24) -ErrorAction SilentlyContinue | Select-Object -First 5
            if ($errors) {
                foreach ($error in $errors) {
                    $txtHealthOutput.AppendText("  • [$($error.TimeGenerated.ToString('MM/dd HH:mm'))] $($error.Source): $($error.Message.Substring(0, [Math]::Min(80, $error.Message.Length)))`r`n")
                }
            } else {
                $txtHealthOutput.AppendText("  ✓ No critical errors in last 24 hours`r`n")
            }
            
        } else {
            # Remote health check
            $cred = $script:storedCredentials
            if (-not $cred) {
                $result = [System.Windows.Forms.MessageBox]::Show("No credentials loaded. Load credentials now?", "Credentials Required", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
                if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                    $cred = Get-T2Credentials -Purpose "accessing $targetHost"
                    if ($cred) {
                        $script:storedCredentials = $cred
                        $lblCredStatus.Text = "✓ Loaded: $($cred.UserName)"
                        $lblCredStatus.ForeColor = $green
                    }
                }
            }
            
            if ($cred) {
                $session = New-PSSession -ComputerName $targetHost -Credential $cred -ErrorAction Stop
                $healthData = Invoke-Command -Session $session -ScriptBlock {
                    $health = @{}
                    $cpu = Get-CimInstance Win32_Processor
                    $health.CPUUsage = $cpu.LoadPercentage
                    $health.CPUName = $cpu.Name
                    $health.CPUCores = $cpu.NumberOfCores
                    
                    $os = Get-CimInstance Win32_OperatingSystem
                    $health.TotalMem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
                    $health.FreeMem = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
                    
                    $health.Disks = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 }
                    $health.Adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
                    
                    return $health
                }
                Remove-PSSession -Session $session
                
                $txtHealthOutput.AppendText("► CPU: $($healthData.CPUUsage)%`r`n")
                $txtHealthOutput.AppendText("► Memory: Used $($healthData.TotalMem - $healthData.FreeMem) GB / $($healthData.TotalMem) GB`r`n")
                $txtHealthOutput.AppendText("► Disks:`r`n")
                foreach ($disk in $healthData.Disks) {
                    $pct = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)
                    $txtHealthOutput.AppendText("  $($disk.DeviceID): $pct% used`r`n")
                }
            } else {
                $txtHealthOutput.AppendText("✗ Operation cancelled`r`n")
            }
        }
        
        $txtHealthOutput.AppendText("`r`n═══════════════════════════════════════════════════════════════`r`n")
        $txtHealthOutput.AppendText("  HEALTH CHECK COMPLETE`r`n")
        $txtHealthOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n")
        
    } catch {
        $txtHealthOutput.AppendText("`r`n✗ ERROR: $($_.Exception.Message)`r`n")
    }
})

$btnClearHealth.Add_Click({
    $txtHealthOutput.Clear()
})

# ═══════════════════════════════════════════════════════════════════════════════
# PANEL 3: PING TEST - Network reachability testing (on-demand only)
# ═══════════════════════════════════════════════════════════════════════════════
$panelPing = New-Object System.Windows.Forms.Panel
$panelPing.Location = New-Object System.Drawing.Point(0, 0)
$panelPing.Size = New-Object System.Drawing.Size(1610, 980)
$panelPing.BackColor = $nearBlack
$panelPing.Visible = $false
$contentPanel.Controls.Add($panelPing)

$lblPingTarget = New-Object System.Windows.Forms.Label
$lblPingTarget.Text = "Target (uses global host if empty):"
$lblPingTarget.Location = New-Object System.Drawing.Point(20, 25)
$lblPingTarget.Size = New-Object System.Drawing.Size(250, 25)
$lblPingTarget.ForeColor = $textColor
$lblPingTarget.Font = $generalFont
$panelPing.Controls.Add($lblPingTarget)

$txtPingTarget = New-Object System.Windows.Forms.TextBox
$txtPingTarget.Location = New-Object System.Drawing.Point(280, 22)
$txtPingTarget.Size = New-Object System.Drawing.Size(300, 25)
$txtPingTarget.BackColor = $darkGray
$txtPingTarget.ForeColor = $textColor
$txtPingTarget.Font = $generalFont
$panelPing.Controls.Add($txtPingTarget)

$lblPingCount = New-Object System.Windows.Forms.Label
$lblPingCount.Text = "Count:"
$lblPingCount.Location = New-Object System.Drawing.Point(600, 25)
$lblPingCount.Size = New-Object System.Drawing.Size(60, 25)
$lblPingCount.ForeColor = $textColor
$lblPingCount.Font = $generalFont
$panelPing.Controls.Add($lblPingCount)

$txtPingCount = New-Object System.Windows.Forms.TextBox
$txtPingCount.Location = New-Object System.Drawing.Point(670, 22)
$txtPingCount.Size = New-Object System.Drawing.Size(60, 25)
$txtPingCount.BackColor = $darkGray
$txtPingCount.ForeColor = $textColor
$txtPingCount.Font = $generalFont
$txtPingCount.Text = "4"
$panelPing.Controls.Add($txtPingCount)

$btnPing = New-Object System.Windows.Forms.Button
$btnPing.Text = "▶ Ping"
$btnPing.Location = New-Object System.Drawing.Point(750, 20)
$btnPing.Size = New-Object System.Drawing.Size(120, 30)
$btnPing.BackColor = $darkGray
$btnPing.ForeColor = $teal
$btnPing.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnPing.FlatAppearance.BorderColor = $teal
$btnPing.FlatAppearance.BorderSize = 2
$btnPing.Font = $generalFont
$panelPing.Controls.Add($btnPing)

$btnClearPing = New-Object System.Windows.Forms.Button
$btnClearPing.Text = "🗑 Clear"
$btnClearPing.Location = New-Object System.Drawing.Point(880, 20)
$btnClearPing.Size = New-Object System.Drawing.Size(100, 30)
$btnClearPing.BackColor = $darkGray
$btnClearPing.ForeColor = $silver
$btnClearPing.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearPing.FlatAppearance.BorderColor = $silver
$btnClearPing.Font = $generalFont
$panelPing.Controls.Add($btnClearPing)

$txtPingOutput = New-Object System.Windows.Forms.TextBox
$txtPingOutput.Location = New-Object System.Drawing.Point(20, 70)
$txtPingOutput.Size = New-Object System.Drawing.Size(1550, 870)
$txtPingOutput.Multiline = $true
$txtPingOutput.ScrollBars = "Vertical"
$txtPingOutput.BackColor = $darkGray
$txtPingOutput.ForeColor = $textColor
$txtPingOutput.Font = $monoFont
$txtPingOutput.ReadOnly = $true
$panelPing.Controls.Add($txtPingOutput)

$btnPing.Add_Click({
    $target = if ([string]::IsNullOrWhiteSpace($txtPingTarget.Text)) { $script:globalTargetHost } else { $txtPingTarget.Text }
    $count = 4
    
    try {
        $count = [int]$txtPingCount.Text
        if ($count -lt 1) { $count = 4 }
        if ($count -gt 100) { $count = 100 }
    } catch {
        $count = 4
    }
    
    if ([string]::IsNullOrWhiteSpace($target)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a target host or set the global target host.", "Input Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    $txtPingOutput.Text = "═══════════════════════════════════════════════════════════════`r`n"
    $txtPingOutput.AppendText("  PING TEST - $target ($count packets)`r`n")
    $txtPingOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
    
    $btnPing.Enabled = $false
    $btnPing.Text = "⏳ Pinging..."
    
    try {
        for ($i = 1; $i -le $count; $i++) {
            $txtPingOutput.AppendText("Ping $i of ${count}...`r`n")
            $result = Test-Connection -ComputerName $target -Count 1 -ErrorAction Stop
            $timestamp = Get-Date -Format "HH:mm:ss"
            $txtPingOutput.AppendText("  [$timestamp] Reply from $($result.IPV4Address): bytes=$($result.ReplySize) time=$($result.ResponseTime)ms TTL=$($result.TimeToLive)`r`n")
            
            if ($i -lt $count) {
                Start-Sleep -Seconds 1
            }
        }
        
        # Statistics
        $allResults = Test-Connection -ComputerName $target -Count $count -ErrorAction Stop
        $avgTime = ($allResults | Measure-Object -Property ResponseTime -Average).Average
        $minTime = ($allResults | Measure-Object -Property ResponseTime -Minimum).Minimum
        $maxTime = ($allResults | Measure-Object -Property ResponseTime -Maximum).Maximum
        
        $txtPingOutput.AppendText("`r`n► STATISTICS:`r`n")
        $txtPingOutput.AppendText("  Packets: Sent = $count, Received = $($allResults.Count), Lost = $($count - $allResults.Count)`r`n")
        $txtPingOutput.AppendText("  Round Trip Times:`r`n")
        $txtPingOutput.AppendText("    Minimum = ${minTime}ms, Maximum = ${maxTime}ms, Average = $([math]::Round($avgTime, 2))ms`r`n")
        
    } catch {
        $txtPingOutput.AppendText("`r`n✗ ERROR: $($_.Exception.Message)`r`n")
        $txtPingOutput.AppendText("`r`nPossible reasons:`r`n")
        $txtPingOutput.AppendText("• Host is unreachable or offline`r`n")
        $txtPingOutput.AppendText("• Firewall blocking ICMP`r`n")
        $txtPingOutput.AppendText("• Invalid hostname/IP`r`n")
    }
    
    $txtPingOutput.AppendText("`r`n═══════════════════════════════════════════════════════════════`r`n")
    $txtPingOutput.AppendText("  PING TEST COMPLETE`r`n")
    $txtPingOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n")
    
    $btnPing.Enabled = $true
    $btnPing.Text = "▶ Ping"
})

$btnClearPing.Add_Click({
    $txtPingOutput.Clear()
})

# ═══════════════════════════════════════════════════════════════════════════════
# PANEL 4: NSLOOKUP - DNS resolution tool
# ═══════════════════════════════════════════════════════════════════════════════
$panelNSLookup = New-Object System.Windows.Forms.Panel
$panelNSLookup.Location = New-Object System.Drawing.Point(0, 0)
$panelNSLookup.Size = New-Object System.Drawing.Size(1610, 980)
$panelNSLookup.BackColor = $nearBlack
$panelNSLookup.Visible = $false
$contentPanel.Controls.Add($panelNSLookup)

$lblNSTarget = New-Object System.Windows.Forms.Label
$lblNSTarget.Text = "Domain/IP:"
$lblNSTarget.Location = New-Object System.Drawing.Point(20, 25)
$lblNSTarget.Size = New-Object System.Drawing.Size(100, 25)
$lblNSTarget.ForeColor = $textColor
$lblNSTarget.Font = $generalFont
$panelNSLookup.Controls.Add($lblNSTarget)

$txtNSTarget = New-Object System.Windows.Forms.TextBox
$txtNSTarget.Location = New-Object System.Drawing.Point(130, 22)
$txtNSTarget.Size = New-Object System.Drawing.Size(400, 25)
$txtNSTarget.BackColor = $darkGray
$txtNSTarget.ForeColor = $textColor
$txtNSTarget.Font = $generalFont
$panelNSLookup.Controls.Add($txtNSTarget)

$btnNSLookup = New-Object System.Windows.Forms.Button
$btnNSLookup.Text = "▶ Lookup"
$btnNSLookup.Location = New-Object System.Drawing.Point(550, 20)
$btnNSLookup.Size = New-Object System.Drawing.Size(120, 30)
$btnNSLookup.BackColor = $darkGray
$btnNSLookup.ForeColor = $teal
$btnNSLookup.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnNSLookup.FlatAppearance.BorderColor = $teal
$btnNSLookup.FlatAppearance.BorderSize = 2
$btnNSLookup.Font = $generalFont
$panelNSLookup.Controls.Add($btnNSLookup)

$btnClearNS = New-Object System.Windows.Forms.Button
$btnClearNS.Text = "🗑 Clear"
$btnClearNS.Location = New-Object System.Drawing.Point(680, 20)
$btnClearNS.Size = New-Object System.Drawing.Size(100, 30)
$btnClearNS.BackColor = $darkGray
$btnClearNS.ForeColor = $silver
$btnClearNS.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearNS.FlatAppearance.BorderColor = $silver
$btnClearNS.Font = $generalFont
$panelNSLookup.Controls.Add($btnClearNS)

$txtNSOutput = New-Object System.Windows.Forms.TextBox
$txtNSOutput.Location = New-Object System.Drawing.Point(20, 70)
$txtNSOutput.Size = New-Object System.Drawing.Size(1550, 870)
$txtNSOutput.Multiline = $true
$txtNSOutput.ScrollBars = "Vertical"
$txtNSOutput.BackColor = $darkGray
$txtNSOutput.ForeColor = $textColor
$txtNSOutput.Font = $monoFont
$txtNSOutput.ReadOnly = $true
$panelNSLookup.Controls.Add($txtNSOutput)

$btnNSLookup.Add_Click({
    $target = $txtNSTarget.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($target)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a domain or IP address.", "Input Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    $txtNSOutput.Text = "═══════════════════════════════════════════════════════════════`r`n"
    $txtNSOutput.AppendText("  NSLOOKUP - $target`r`n")
    $txtNSOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
    
    try {
        # Using Resolve-DnsName
        $txtNSOutput.AppendText("► DNS RESOLUTION (PowerShell):`r`n")
        $dnsResults = Resolve-DnsName -Name $target -ErrorAction Stop
        foreach ($record in $dnsResults) {
            $txtNSOutput.AppendText("  Type: $($record.Type)`r`n")
            $txtNSOutput.AppendText("  Name: $($record.Name)`r`n")
            if ($record.IPAddress) {
                $txtNSOutput.AppendText("  IP Address: $($record.IPAddress)`r`n")
            }
            if ($record.NameHost) {
                $txtNSOutput.AppendText("  Name Host: $($record.NameHost)`r`n")
            }
            $txtNSOutput.AppendText("  ─────────────────────────────────────────────────────────`r`n")
        }
        
        # Using nslookup command
        $txtNSOutput.AppendText("`r`n► NSLOOKUP (Command):`r`n")
        $nsResult = nslookup $target 2>&1
        foreach ($line in $nsResult) {
            $txtNSOutput.AppendText("  $line`r`n")
        }
        
    } catch {
        $txtNSOutput.AppendText("`r`n✗ ERROR: $($_.Exception.Message)`r`n")
    }
    
    $txtNSOutput.AppendText("`r`n═══════════════════════════════════════════════════════════════`r`n")
})

$btnClearNS.Add_Click({
    $txtNSOutput.Clear()
})

# ═══════════════════════════════════════════════════════════════════════════════
# PANEL 5: TRACEROUTE - Network path tracing
# ═══════════════════════════════════════════════════════════════════════════════
$panelTraceroute = New-Object System.Windows.Forms.Panel
$panelTraceroute.Location = New-Object System.Drawing.Point(0, 0)
$panelTraceroute.Size = New-Object System.Drawing.Size(1610, 980)
$panelTraceroute.BackColor = $nearBlack
$panelTraceroute.Visible = $false
$contentPanel.Controls.Add($panelTraceroute)

$lblTraceTarget = New-Object System.Windows.Forms.Label
$lblTraceTarget.Text = "Target:"
$lblTraceTarget.Location = New-Object System.Drawing.Point(20, 25)
$lblTraceTarget.Size = New-Object System.Drawing.Size(100, 25)
$lblTraceTarget.ForeColor = $textColor
$lblTraceTarget.Font = $generalFont
$panelTraceroute.Controls.Add($lblTraceTarget)

$txtTraceTarget = New-Object System.Windows.Forms.TextBox
$txtTraceTarget.Location = New-Object System.Drawing.Point(130, 22)
$txtTraceTarget.Size = New-Object System.Drawing.Size(400, 25)
$txtTraceTarget.BackColor = $darkGray
$txtTraceTarget.ForeColor = $textColor
$txtTraceTarget.Font = $generalFont
$panelTraceroute.Controls.Add($txtTraceTarget)

$btnTrace = New-Object System.Windows.Forms.Button
$btnTrace.Text = "▶ Traceroute"
$btnTrace.Location = New-Object System.Drawing.Point(550, 20)
$btnTrace.Size = New-Object System.Drawing.Size(140, 30)
$btnTrace.BackColor = $darkGray
$btnTrace.ForeColor = $teal
$btnTrace.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnTrace.FlatAppearance.BorderColor = $teal
$btnTrace.FlatAppearance.BorderSize = 2
$btnTrace.Font = $generalFont
$panelTraceroute.Controls.Add($btnTrace)

$btnClearTrace = New-Object System.Windows.Forms.Button
$btnClearTrace.Text = "🗑 Clear"
$btnClearTrace.Location = New-Object System.Drawing.Point(700, 20)
$btnClearTrace.Size = New-Object System.Drawing.Size(100, 30)
$btnClearTrace.BackColor = $darkGray
$btnClearTrace.ForeColor = $silver
$btnClearTrace.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearTrace.FlatAppearance.BorderColor = $silver
$btnClearTrace.Font = $generalFont
$panelTraceroute.Controls.Add($btnClearTrace)

$txtTraceOutput = New-Object System.Windows.Forms.TextBox
$txtTraceOutput.Location = New-Object System.Drawing.Point(20, 70)
$txtTraceOutput.Size = New-Object System.Drawing.Size(1550, 870)
$txtTraceOutput.Multiline = $true
$txtTraceOutput.ScrollBars = "Vertical"
$txtTraceOutput.BackColor = $darkGray
$txtTraceOutput.ForeColor = $textColor
$txtTraceOutput.Font = $monoFont
$txtTraceOutput.ReadOnly = $true
$panelTraceroute.Controls.Add($txtTraceOutput)

$btnTrace.Add_Click({
    $target = if ([string]::IsNullOrWhiteSpace($txtTraceTarget.Text)) { $script:globalTargetHost } else { $txtTraceTarget.Text.Trim() }
    
    if ([string]::IsNullOrWhiteSpace($target)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a target host.", "Input Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    $txtTraceOutput.Text = "═══════════════════════════════════════════════════════════════`r`n"
    $txtTraceOutput.AppendText("  TRACEROUTE - $target`r`n")
    $txtTraceOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
    $txtTraceOutput.AppendText("Starting traceroute... This may take several seconds.`r`n`r`n")
    
    $btnTrace.Enabled = $false
    $btnTrace.Text = "⏳ Tracing..."
    
    try {
        $traceResult = tracert $target 2>&1
        foreach ($line in $traceResult) {
            $txtTraceOutput.AppendText("$line`r`n")
        }
    } catch {
        $txtTraceOutput.AppendText("`r`n✗ ERROR: $($_.Exception.Message)`r`n")
    }
    
    $txtTraceOutput.AppendText("`r`n═══════════════════════════════════════════════════════════════`r`n")
    $txtTraceOutput.AppendText("  TRACEROUTE COMPLETE`r`n")
    $txtTraceOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n")
    
    $btnTrace.Enabled = $true
    $btnTrace.Text = "▶ Traceroute"
})

$btnClearTrace.Add_Click({
    $txtTraceOutput.Clear()
})

# ═══════════════════════════════════════════════════════════════════════════════
# PANEL 6: DOMAIN USERS - List domain or local users
# ═══════════════════════════════════════════════════════════════════════════════
$panelDomainUsers = New-Object System.Windows.Forms.Panel
$panelDomainUsers.Location = New-Object System.Drawing.Point(0, 0)
$panelDomainUsers.Size = New-Object System.Drawing.Size(1610, 980)
$panelDomainUsers.BackColor = $nearBlack
$panelDomainUsers.Visible = $false
$contentPanel.Controls.Add($panelDomainUsers)

$btnGetUsers = New-Object System.Windows.Forms.Button
$btnGetUsers.Text = "👥 Get Domain Users"
$btnGetUsers.Location = New-Object System.Drawing.Point(20, 20)
$btnGetUsers.Size = New-Object System.Drawing.Size(180, 35)
$btnGetUsers.BackColor = $darkGray
$btnGetUsers.ForeColor = $teal
$btnGetUsers.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnGetUsers.FlatAppearance.BorderColor = $teal
$btnGetUsers.FlatAppearance.BorderSize = 2
$btnGetUsers.Font = $generalFont
$panelDomainUsers.Controls.Add($btnGetUsers)

$btnGetLocalUsers = New-Object System.Windows.Forms.Button
$btnGetLocalUsers.Text = "💻 Get Local Users"
$btnGetLocalUsers.Location = New-Object System.Drawing.Point(210, 20)
$btnGetLocalUsers.Size = New-Object System.Drawing.Size(180, 35)
$btnGetLocalUsers.BackColor = $darkGray
$btnGetLocalUsers.ForeColor = $teal
$btnGetLocalUsers.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnGetLocalUsers.FlatAppearance.BorderColor = $teal
$btnGetLocalUsers.FlatAppearance.BorderSize = 2
$btnGetLocalUsers.Font = $generalFont
$panelDomainUsers.Controls.Add($btnGetLocalUsers)

$btnClearUsers = New-Object System.Windows.Forms.Button
$btnClearUsers.Text = "🗑 Clear"
$btnClearUsers.Location = New-Object System.Drawing.Point(400, 20)
$btnClearUsers.Size = New-Object System.Drawing.Size(100, 35)
$btnClearUsers.BackColor = $darkGray
$btnClearUsers.ForeColor = $silver
$btnClearUsers.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearUsers.FlatAppearance.BorderColor = $silver
$btnClearUsers.Font = $generalFont
$panelDomainUsers.Controls.Add($btnClearUsers)

$txtUsersOutput = New-Object System.Windows.Forms.TextBox
$txtUsersOutput.Location = New-Object System.Drawing.Point(20, 70)
$txtUsersOutput.Size = New-Object System.Drawing.Size(1550, 870)
$txtUsersOutput.Multiline = $true
$txtUsersOutput.ScrollBars = "Vertical"
$txtUsersOutput.BackColor = $darkGray
$txtUsersOutput.ForeColor = $textColor
$txtUsersOutput.Font = $monoFont
$txtUsersOutput.ReadOnly = $true
$panelDomainUsers.Controls.Add($txtUsersOutput)

$btnGetUsers.Add_Click({
    $txtUsersOutput.Text = "═══════════════════════════════════════════════════════════════`r`n"
    $txtUsersOutput.AppendText("  DOMAIN USERS`r`n")
    $txtUsersOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
    
    try {
        $result = net user /domain 2>&1
        
        if ($result -match "not a member of a domain|could not find") {
            $txtUsersOutput.AppendText("⚠ This computer is not a member of a domain.`r`n")
            $txtUsersOutput.AppendText("Use 'Get Local Users' button instead.`r`n")
        } else {
            foreach ($line in $result) {
                $txtUsersOutput.AppendText("$line`r`n")
            }
        }
    } catch {
        $txtUsersOutput.AppendText("✗ ERROR: $($_.Exception.Message)`r`n")
    }
    
    $txtUsersOutput.AppendText("`r`n═══════════════════════════════════════════════════════════════`r`n")
})

$btnGetLocalUsers.Add_Click({
    $targetHost = $script:globalTargetHost
    if ([string]::IsNullOrWhiteSpace($targetHost)) { $targetHost = "localhost" }
    
    $txtUsersOutput.Text = "═══════════════════════════════════════════════════════════════`r`n"
    $txtUsersOutput.AppendText("  LOCAL USERS - $targetHost`r`n")
    $txtUsersOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
    
    try {
        $isLocal = ($targetHost -eq "localhost" -or $targetHost -eq "." -or $targetHost -eq $env:COMPUTERNAME)
        
        if ($isLocal) {
            $users = Get-LocalUser
            foreach ($user in $users) {
                $txtUsersOutput.AppendText("User: $($user.Name)`r`n")
                $txtUsersOutput.AppendText("  Enabled: $($user.Enabled)`r`n")
                $txtUsersOutput.AppendText("  Description: $($user.Description)`r`n")
                $txtUsersOutput.AppendText("  Last Logon: $($user.LastLogon)`r`n")
                $txtUsersOutput.AppendText("  ─────────────────────────────────────────────────────────`r`n")
            }
        } else {
            # Remote query
            $cred = $script:storedCredentials
            if (-not $cred) {
                $result = [System.Windows.Forms.MessageBox]::Show("No credentials loaded. Load now?", "Credentials Required", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
                if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                    $cred = Get-T2Credentials -Purpose "accessing $targetHost"
                    if ($cred) {
                        $script:storedCredentials = $cred
                    }
                }
            }
            
            if ($cred) {
                $session = New-PSSession -ComputerName $targetHost -Credential $cred -ErrorAction Stop
                $remoteUsers = Invoke-Command -Session $session -ScriptBlock {
                    Get-LocalUser
                }
                Remove-PSSession -Session $session
                
                foreach ($user in $remoteUsers) {
                    $txtUsersOutput.AppendText("User: $($user.Name)`r`n")
                    $txtUsersOutput.AppendText("  Enabled: $($user.Enabled)`r`n")
                    $txtUsersOutput.AppendText("  Description: $($user.Description)`r`n")
                    $txtUsersOutput.AppendText("  ─────────────────────────────────────────────────────────`r`n")
                }
            }
        }
    } catch {
        $txtUsersOutput.AppendText("✗ ERROR: $($_.Exception.Message)`r`n")
    }
    
    $txtUsersOutput.AppendText("`r`n═══════════════════════════════════════════════════════════════`r`n")
})

$btnClearUsers.Add_Click({
    $txtUsersOutput.Clear()
})

# ═══════════════════════════════════════════════════════════════════════════════
# PANEL 7: IPCONFIG - IP configuration and management
# ═══════════════════════════════════════════════════════════════════════════════
$panelIPConfig = New-Object System.Windows.Forms.Panel
$panelIPConfig.Location = New-Object System.Drawing.Point(0, 0)
$panelIPConfig.Size = New-Object System.Drawing.Size(1610, 980)
$panelIPConfig.BackColor = $nearBlack
$panelIPConfig.Visible = $false
$contentPanel.Controls.Add($panelIPConfig)

$btnIPConfigAll = New-Object System.Windows.Forms.Button
$btnIPConfigAll.Text = "📋 IPConfig /all"
$btnIPConfigAll.Location = New-Object System.Drawing.Point(20, 20)
$btnIPConfigAll.Size = New-Object System.Drawing.Size(150, 35)
$btnIPConfigAll.BackColor = $darkGray
$btnIPConfigAll.ForeColor = $teal
$btnIPConfigAll.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnIPConfigAll.FlatAppearance.BorderColor = $teal
$btnIPConfigAll.FlatAppearance.BorderSize = 2
$btnIPConfigAll.Font = $generalFont
$panelIPConfig.Controls.Add($btnIPConfigAll)

$btnFlushDNS = New-Object System.Windows.Forms.Button
$btnFlushDNS.Text = "🔄 Flush DNS"
$btnFlushDNS.Location = New-Object System.Drawing.Point(180, 20)
$btnFlushDNS.Size = New-Object System.Drawing.Size(150, 35)
$btnFlushDNS.BackColor = $darkGray
$btnFlushDNS.ForeColor = $teal
$btnFlushDNS.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnFlushDNS.FlatAppearance.BorderColor = $teal
$btnFlushDNS.FlatAppearance.BorderSize = 2
$btnFlushDNS.Font = $generalFont
$panelIPConfig.Controls.Add($btnFlushDNS)

$btnRenewDHCP = New-Object System.Windows.Forms.Button
$btnRenewDHCP.Text = "♻ Renew DHCP"
$btnRenewDHCP.Location = New-Object System.Drawing.Point(340, 20)
$btnRenewDHCP.Size = New-Object System.Drawing.Size(150, 35)
$btnRenewDHCP.BackColor = $darkGray
$btnRenewDHCP.ForeColor = $yellow
$btnRenewDHCP.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnRenewDHCP.FlatAppearance.BorderColor = $yellow
$btnRenewDHCP.FlatAppearance.BorderSize = 2
$btnRenewDHCP.Font = $generalFont
$panelIPConfig.Controls.Add($btnRenewDHCP)

$btnClearIPConfig = New-Object System.Windows.Forms.Button
$btnClearIPConfig.Text = "🗑 Clear"
$btnClearIPConfig.Location = New-Object System.Drawing.Point(500, 20)
$btnClearIPConfig.Size = New-Object System.Drawing.Size(100, 35)
$btnClearIPConfig.BackColor = $darkGray
$btnClearIPConfig.ForeColor = $silver
$btnClearIPConfig.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearIPConfig.FlatAppearance.BorderColor = $silver
$btnClearIPConfig.Font = $generalFont
$panelIPConfig.Controls.Add($btnClearIPConfig)

$txtIPConfigOutput = New-Object System.Windows.Forms.TextBox
$txtIPConfigOutput.Location = New-Object System.Drawing.Point(20, 70)
$txtIPConfigOutput.Size = New-Object System.Drawing.Size(1550, 870)
$txtIPConfigOutput.Multiline = $true
$txtIPConfigOutput.ScrollBars = "Vertical"
$txtIPConfigOutput.BackColor = $darkGray
$txtIPConfigOutput.ForeColor = $textColor
$txtIPConfigOutput.Font = $monoFont
$txtIPConfigOutput.ReadOnly = $true
$panelIPConfig.Controls.Add($txtIPConfigOutput)

$btnIPConfigAll.Add_Click({
    $txtIPConfigOutput.Text = "═══════════════════════════════════════════════════════════════`r`n"
    $txtIPConfigOutput.AppendText("  IP CONFIGURATION (DETAILED)`r`n")
    $txtIPConfigOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
    
    try {
        $result = ipconfig /all
        foreach ($line in $result) {
            $txtIPConfigOutput.AppendText("$line`r`n")
        }
    } catch {
        $txtIPConfigOutput.AppendText("✗ ERROR: $($_.Exception.Message)`r`n")
    }
    
    $txtIPConfigOutput.AppendText("`r`n═══════════════════════════════════════════════════════════════`r`n")
})

$btnFlushDNS.Add_Click({
    $txtIPConfigOutput.Text = "Flushing DNS cache...`r`n`r`n"
    
    try {
        $result = ipconfig /flushdns
        foreach ($line in $result) {
            $txtIPConfigOutput.AppendText("$line`r`n")
        }
        $txtIPConfigOutput.AppendText("`r`n✓ DNS cache flushed successfully!`r`n")
    } catch {
        $txtIPConfigOutput.AppendText("✗ ERROR: $($_.Exception.Message)`r`n")
    }
})

$btnRenewDHCP.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show("This will release and renew your IP address. Network connectivity will be briefly interrupted. Continue?", "Confirm DHCP Renewal", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $txtIPConfigOutput.Text = "Renewing DHCP lease...`r`n`r`n"
        
        try {
            $txtIPConfigOutput.AppendText("Releasing current IP address...`r`n")
            $result1 = ipconfig /release
            foreach ($line in $result1) {
                $txtIPConfigOutput.AppendText("$line`r`n")
            }
            
            $txtIPConfigOutput.AppendText("`r`nRenewing IP address...`r`n")
            $result2 = ipconfig /renew
            foreach ($line in $result2) {
                $txtIPConfigOutput.AppendText("$line`r`n")
            }
            
            $txtIPConfigOutput.AppendText("`r`n✓ DHCP lease renewed successfully!`r`n")
        } catch {
            $txtIPConfigOutput.AppendText("✗ ERROR: $($_.Exception.Message)`r`n")
        }
    }
})

$btnClearIPConfig.Add_Click({
    $txtIPConfigOutput.Clear()
})

# ═══════════════════════════════════════════════════════════════════════════════
# PANEL 8: NETSTAT - Network statistics and connections
# ═══════════════════════════════════════════════════════════════════════════════
$panelNetStat = New-Object System.Windows.Forms.Panel
$panelNetStat.Location = New-Object System.Drawing.Point(0, 0)
$panelNetStat.Size = New-Object System.Drawing.Size(1610, 980)
$panelNetStat.BackColor = $nearBlack
$panelNetStat.Visible = $false
$contentPanel.Controls.Add($panelNetStat)

$btnNetStatAll = New-Object System.Windows.Forms.Button
$btnNetStatAll.Text = "📡 Active Connections"
$btnNetStatAll.Location = New-Object System.Drawing.Point(20, 20)
$btnNetStatAll.Size = New-Object System.Drawing.Size(180, 35)
$btnNetStatAll.BackColor = $darkGray
$btnNetStatAll.ForeColor = $teal
$btnNetStatAll.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnNetStatAll.FlatAppearance.BorderColor = $teal
$btnNetStatAll.FlatAppearance.BorderSize = 2
$btnNetStatAll.Font = $generalFont
$panelNetStat.Controls.Add($btnNetStatAll)

$btnNetStatListening = New-Object System.Windows.Forms.Button
$btnNetStatListening.Text = "👂 Listening Ports"
$btnNetStatListening.Location = New-Object System.Drawing.Point(210, 20)
$btnNetStatListening.Size = New-Object System.Drawing.Size(180, 35)
$btnNetStatListening.BackColor = $darkGray
$btnNetStatListening.ForeColor = $teal
$btnNetStatListening.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnNetStatListening.FlatAppearance.BorderColor = $teal
$btnNetStatListening.FlatAppearance.BorderSize = 2
$btnNetStatListening.Font = $generalFont
$panelNetStat.Controls.Add($btnNetStatListening)

$btnClearNetStat = New-Object System.Windows.Forms.Button
$btnClearNetStat.Text = "🗑 Clear"
$btnClearNetStat.Location = New-Object System.Drawing.Point(400, 20)
$btnClearNetStat.Size = New-Object System.Drawing.Size(100, 35)
$btnClearNetStat.BackColor = $darkGray
$btnClearNetStat.ForeColor = $silver
$btnClearNetStat.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearNetStat.FlatAppearance.BorderColor = $silver
$btnClearNetStat.Font = $generalFont
$panelNetStat.Controls.Add($btnClearNetStat)

$txtNetStatOutput = New-Object System.Windows.Forms.TextBox
$txtNetStatOutput.Location = New-Object System.Drawing.Point(20, 70)
$txtNetStatOutput.Size = New-Object System.Drawing.Size(1550, 870)
$txtNetStatOutput.Multiline = $true
$txtNetStatOutput.ScrollBars = "Vertical"
$txtNetStatOutput.BackColor = $darkGray
$txtNetStatOutput.ForeColor = $textColor
$txtNetStatOutput.Font = $monoFont
$txtNetStatOutput.ReadOnly = $true
$panelNetStat.Controls.Add($txtNetStatOutput)

$btnNetStatAll.Add_Click({
    $txtNetStatOutput.Text = "═══════════════════════════════════════════════════════════════`r`n"
    $txtNetStatOutput.AppendText("  ACTIVE NETWORK CONNECTIONS`r`n")
    $txtNetStatOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
    
    try {
        $result = netstat -ano
        foreach ($line in $result) {
            $txtNetStatOutput.AppendText("$line`r`n")
        }
    } catch {
        $txtNetStatOutput.AppendText("✗ ERROR: $($_.Exception.Message)`r`n")
    }
    
    $txtNetStatOutput.AppendText("`r`n═══════════════════════════════════════════════════════════════`r`n")
})

$btnNetStatListening.Add_Click({
    $txtNetStatOutput.Text = "═══════════════════════════════════════════════════════════════`r`n"
    $txtNetStatOutput.AppendText("  LISTENING PORTS`r`n")
    $txtNetStatOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
    
    try {
        $result = netstat -ano | Select-String "LISTENING"
        foreach ($line in $result) {
            $txtNetStatOutput.AppendText("$line`r`n")
        }
    } catch {
        $txtNetStatOutput.AppendText("✗ ERROR: $($_.Exception.Message)`r`n")
    }
    
    $txtNetStatOutput.AppendText("`r`n═══════════════════════════════════════════════════════════════`r`n")
})

$btnClearNetStat.Add_Click({
    $txtNetStatOutput.Clear()
})

# ═══════════════════════════════════════════════════════════════════════════════
# PANEL 9: RDP CONNECTION - Remote Desktop with T2 (restrictedAdmin) support
# ═══════════════════════════════════════════════════════════════════════════════
$panelRDP = New-Object System.Windows.Forms.Panel
$panelRDP.Location = New-Object System.Drawing.Point(0, 0)
$panelRDP.Size = New-Object System.Drawing.Size(1610, 980)
$panelRDP.BackColor = $nearBlack
$panelRDP.Visible = $false
$contentPanel.Controls.Add($panelRDP)

$lblRDPHost = New-Object System.Windows.Forms.Label
$lblRDPHost.Text = "Target Host (uses global if empty):"
$lblRDPHost.Location = New-Object System.Drawing.Point(20, 25)
$lblRDPHost.Size = New-Object System.Drawing.Size(250, 25)
$lblRDPHost.ForeColor = $textColor
$lblRDPHost.Font = $generalFont
$panelRDP.Controls.Add($lblRDPHost)

$txtRDPHost = New-Object System.Windows.Forms.TextBox
$txtRDPHost.Location = New-Object System.Drawing.Point(280, 22)
$txtRDPHost.Size = New-Object System.Drawing.Size(400, 25)
$txtRDPHost.BackColor = $darkGray
$txtRDPHost.ForeColor = $textColor
$txtRDPHost.Font = $generalFont
$panelRDP.Controls.Add($txtRDPHost)

$chkRDPMultimon = New-Object System.Windows.Forms.CheckBox
$chkRDPMultimon.Text = "🖥 Multi-Monitor (/multimon)"
$chkRDPMultimon.Location = New-Object System.Drawing.Point(20, 65)
$chkRDPMultimon.Size = New-Object System.Drawing.Size(280, 25)
$chkRDPMultimon.ForeColor = $textColor
$chkRDPMultimon.Font = $generalFont
$panelRDP.Controls.Add($chkRDPMultimon)

$chkRDPAdmin = New-Object System.Windows.Forms.CheckBox
$chkRDPAdmin.Text = "👑 Admin Mode (/admin)"
$chkRDPAdmin.Location = New-Object System.Drawing.Point(20, 100)
$chkRDPAdmin.Size = New-Object System.Drawing.Size(280, 25)
$chkRDPAdmin.ForeColor = $textColor
$chkRDPAdmin.Font = $generalFont
$panelRDP.Controls.Add($chkRDPAdmin)

$chkRDPT2 = New-Object System.Windows.Forms.CheckBox
$chkRDPT2.Text = "🔐 T2 Feature (/restrictedAdmin)"
$chkRDPT2.Location = New-Object System.Drawing.Point(20, 135)
$chkRDPT2.Size = New-Object System.Drawing.Size(400, 25)
$chkRDPT2.ForeColor = $teal
$chkRDPT2.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$chkRDPT2.Checked = $true
$panelRDP.Controls.Add($chkRDPT2)

$lblRDPT2Note = New-Object System.Windows.Forms.Label
$lblRDPT2Note.Text = "Note: T2/restrictedAdmin mode prevents credentials from being sent to the remote PC"
$lblRDPT2Note.Location = New-Object System.Drawing.Point(40, 163)
$lblRDPT2Note.Size = New-Object System.Drawing.Size(700, 25)
$lblRDPT2Note.ForeColor = $silver
$lblRDPT2Note.Font = $smallFont
$panelRDP.Controls.Add($lblRDPT2Note)

$btnConnectRDP = New-Object System.Windows.Forms.Button
$btnConnectRDP.Text = "▶ Connect RDP"
$btnConnectRDP.Location = New-Object System.Drawing.Point(20, 200)
$btnConnectRDP.Size = New-Object System.Drawing.Size(200, 40)
$btnConnectRDP.BackColor = $darkGray
$btnConnectRDP.ForeColor = $teal
$btnConnectRDP.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnConnectRDP.FlatAppearance.BorderColor = $teal
$btnConnectRDP.FlatAppearance.BorderSize = 2
$btnConnectRDP.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$panelRDP.Controls.Add($btnConnectRDP)

$btnClearRDP = New-Object System.Windows.Forms.Button
$btnClearRDP.Text = "🗑 Clear"
$btnClearRDP.Location = New-Object System.Drawing.Point(230, 200)
$btnClearRDP.Size = New-Object System.Drawing.Size(100, 40)
$btnClearRDP.BackColor = $darkGray
$btnClearRDP.ForeColor = $silver
$btnClearRDP.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearRDP.FlatAppearance.BorderColor = $silver
$btnClearRDP.Font = $generalFont
$panelRDP.Controls.Add($btnClearRDP)

$txtRDPOutput = New-Object System.Windows.Forms.TextBox
$txtRDPOutput.Location = New-Object System.Drawing.Point(20, 260)
$txtRDPOutput.Size = New-Object System.Drawing.Size(1550, 680)
$txtRDPOutput.Multiline = $true
$txtRDPOutput.ScrollBars = "Vertical"
$txtRDPOutput.BackColor = $darkGray
$txtRDPOutput.ForeColor = $textColor
$txtRDPOutput.Font = $monoFont
$txtRDPOutput.ReadOnly = $true
$panelRDP.Controls.Add($txtRDPOutput)

$btnConnectRDP.Add_Click({
    $target = if ([string]::IsNullOrWhiteSpace($txtRDPHost.Text)) { $script:globalTargetHost } else { $txtRDPHost.Text.Trim() }
    
    if ([string]::IsNullOrWhiteSpace($target)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a target host.", "Input Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    $txtRDPOutput.Text = "═══════════════════════════════════════════════════════════════`r`n"
    $txtRDPOutput.AppendText("  RDP CONNECTION - $target`r`n")
    $txtRDPOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
    
    try {
        $arguments = "/v:$target"
        
        if ($chkRDPMultimon.Checked) {
            $arguments += " /multimon"
            $txtRDPOutput.AppendText("✓ Multi-monitor support enabled`r`n")
        }
        
        if ($chkRDPAdmin.Checked) {
            $arguments += " /admin"
            $txtRDPOutput.AppendText("✓ Administrator mode enabled`r`n")
        }
        
        if ($chkRDPT2.Checked) {
            $arguments += " /restrictedAdmin"
            $txtRDPOutput.AppendText("✓ T2 Feature (Restricted Admin) enabled`r`n")
            $txtRDPOutput.AppendText("  → Credentials will NOT be sent to remote PC`r`n")
            $txtRDPOutput.AppendText("  → Uses Kerberos authentication`r`n")
            $txtRDPOutput.AppendText("  → Requires T2 credentials if not using stored creds`r`n")
        }
        
        $txtRDPOutput.AppendText("`r`n═══════════════════════════════════════════════════════════════`r`n")
        $txtRDPOutput.AppendText("  LAUNCHING RDP CLIENT`r`n")
        $txtRDPOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n")
        $txtRDPOutput.AppendText("`r`nCommand: mstsc $arguments`r`n")
        $txtRDPOutput.AppendText("`r`nRDP window launching...`r`n")
        
        Start-Process "mstsc" -ArgumentList $arguments
        
        $txtRDPOutput.AppendText("`r`n✓ RDP client launched successfully!`r`n")
        $txtRDPOutput.AppendText("`r`nThe RDP window should open separately.`r`n")
        
        if ($chkRDPT2.Checked) {
            $txtRDPOutput.AppendText("`r`n⚠ NOTE: With /restrictedAdmin, you may be automatically logged in`r`n")
            $txtRDPOutput.AppendText("using your current domain credentials (Kerberos).`r`n")
        }
        
    } catch {
        $txtRDPOutput.AppendText("`r`n✗ ERROR: $($_.Exception.Message)`r`n")
    }
})

$btnClearRDP.Add_Click({
    $txtRDPOutput.Clear()
})

# ═══════════════════════════════════════════════════════════════════════════════
# PANEL 10: PUTTY SSH - SSH client launcher
# ═══════════════════════════════════════════════════════════════════════════════
$panelPuTTY = New-Object System.Windows.Forms.Panel
$panelPuTTY.Location = New-Object System.Drawing.Point(0, 0)
$panelPuTTY.Size = New-Object System.Drawing.Size(1610, 980)
$panelPuTTY.BackColor = $nearBlack
$panelPuTTY.Visible = $false
$contentPanel.Controls.Add($panelPuTTY)

$lblPuTTYHost = New-Object System.Windows.Forms.Label
$lblPuTTYHost.Text = "SSH Host:"
$lblPuTTYHost.Location = New-Object System.Drawing.Point(20, 25)
$lblPuTTYHost.Size = New-Object System.Drawing.Size(100, 25)
$lblPuTTYHost.ForeColor = $textColor
$lblPuTTYHost.Font = $generalFont
$panelPuTTY.Controls.Add($lblPuTTYHost)

$txtPuTTYHost = New-Object System.Windows.Forms.TextBox
$txtPuTTYHost.Location = New-Object System.Drawing.Point(130, 22)
$txtPuTTYHost.Size = New-Object System.Drawing.Size(400, 25)
$txtPuTTYHost.BackColor = $darkGray
$txtPuTTYHost.ForeColor = $textColor
$txtPuTTYHost.Font = $generalFont
$panelPuTTY.Controls.Add($txtPuTTYHost)

$lblPuTTYPort = New-Object System.Windows.Forms.Label
$lblPuTTYPort.Text = "Port:"
$lblPuTTYPort.Location = New-Object System.Drawing.Point(550, 25)
$lblPuTTYPort.Size = New-Object System.Drawing.Size(50, 25)
$lblPuTTYPort.ForeColor = $textColor
$lblPuTTYPort.Font = $generalFont
$panelPuTTY.Controls.Add($lblPuTTYPort)

$txtPuTTYPort = New-Object System.Windows.Forms.TextBox
$txtPuTTYPort.Location = New-Object System.Drawing.Point(610, 22)
$txtPuTTYPort.Size = New-Object System.Drawing.Size(80, 25)
$txtPuTTYPort.BackColor = $darkGray
$txtPuTTYPort.ForeColor = $textColor
$txtPuTTYPort.Font = $generalFont
$txtPuTTYPort.Text = "22"
$panelPuTTY.Controls.Add($txtPuTTYPort)

$lblPuTTYUser = New-Object System.Windows.Forms.Label
$lblPuTTYUser.Text = "Username:"
$lblPuTTYUser.Location = New-Object System.Drawing.Point(20, 65)
$lblPuTTYUser.Size = New-Object System.Drawing.Size(100, 25)
$lblPuTTYUser.ForeColor = $textColor
$lblPuTTYUser.Font = $generalFont
$panelPuTTY.Controls.Add($lblPuTTYUser)

$txtPuTTYUser = New-Object System.Windows.Forms.TextBox
$txtPuTTYUser.Location = New-Object System.Drawing.Point(130, 62)
$txtPuTTYUser.Size = New-Object System.Drawing.Size(400, 25)
$txtPuTTYUser.BackColor = $darkGray
$txtPuTTYUser.ForeColor = $textColor
$txtPuTTYUser.Font = $generalFont
$panelPuTTY.Controls.Add($txtPuTTYUser)

$btnLaunchPuTTY = New-Object System.Windows.Forms.Button
$btnLaunchPuTTY.Text = "▶ Launch PuTTY"
$btnLaunchPuTTY.Location = New-Object System.Drawing.Point(20, 110)
$btnLaunchPuTTY.Size = New-Object System.Drawing.Size(180, 35)
$btnLaunchPuTTY.BackColor = $darkGray
$btnLaunchPuTTY.ForeColor = $teal
$btnLaunchPuTTY.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnLaunchPuTTY.FlatAppearance.BorderColor = $teal
$btnLaunchPuTTY.FlatAppearance.BorderSize = 2
$btnLaunchPuTTY.Font = $generalFont
$panelPuTTY.Controls.Add($btnLaunchPuTTY)

$btnDownloadPuTTY = New-Object System.Windows.Forms.Button
$btnDownloadPuTTY.Text = "⬇ Download PuTTY"
$btnDownloadPuTTY.Location = New-Object System.Drawing.Point(210, 110)
$btnDownloadPuTTY.Size = New-Object System.Drawing.Size(180, 35)
$btnDownloadPuTTY.BackColor = $darkGray
$btnDownloadPuTTY.ForeColor = $silver
$btnDownloadPuTTY.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnDownloadPuTTY.FlatAppearance.BorderColor = $silver
$btnDownloadPuTTY.Font = $generalFont
$panelPuTTY.Controls.Add($btnDownloadPuTTY)

$btnClearPuTTY = New-Object System.Windows.Forms.Button
$btnClearPuTTY.Text = "🗑 Clear"
$btnClearPuTTY.Location = New-Object System.Drawing.Point(400, 110)
$btnClearPuTTY.Size = New-Object System.Drawing.Size(100, 35)
$btnClearPuTTY.BackColor = $darkGray
$btnClearPuTTY.ForeColor = $silver
$btnClearPuTTY.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearPuTTY.FlatAppearance.BorderColor = $silver
$btnClearPuTTY.Font = $generalFont
$panelPuTTY.Controls.Add($btnClearPuTTY)

$txtPuTTYOutput = New-Object System.Windows.Forms.TextBox
$txtPuTTYOutput.Location = New-Object System.Drawing.Point(20, 165)
$txtPuTTYOutput.Size = New-Object System.Drawing.Size(1550, 775)
$txtPuTTYOutput.Multiline = $true
$txtPuTTYOutput.ScrollBars = "Vertical"
$txtPuTTYOutput.BackColor = $darkGray
$txtPuTTYOutput.ForeColor = $textColor
$txtPuTTYOutput.Font = $monoFont
$txtPuTTYOutput.ReadOnly = $true
$txtPuTTYOutput.Text = "═══════════════════════════════════════════════════════════════`r`n" +
                        "  PuTTY SSH CLIENT LAUNCHER`r`n" +
                        "═══════════════════════════════════════════════════════════════`r`n`r`n" +
                        "This tool launches PuTTY SSH client with your specified parameters.`r`n`r`n" +
                        "Common PuTTY locations:`r`n" +
                        "  • C:\Program Files\PuTTY\putty.exe`r`n" +
                        "  • C:\Program Files (x86)\PuTTY\putty.exe`r`n" +
                        "  • In system PATH`r`n"
$panelPuTTY.Controls.Add($txtPuTTYOutput)

$btnLaunchPuTTY.Add_Click({
    $host = if ([string]::IsNullOrWhiteSpace($txtPuTTYHost.Text)) { $script:globalTargetHost } else { $txtPuTTYHost.Text.Trim() }
    $port = $txtPuTTYPort.Text
    $username = $txtPuTTYUser.Text
    
    if ([string]::IsNullOrWhiteSpace($host)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a target host.", "Input Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    $txtPuTTYOutput.Text = "═══════════════════════════════════════════════════════════════`r`n"
    $txtPuTTYOutput.AppendText("  LAUNCHING PuTTY SSH - $host`r`n")
    $txtPuTTYOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
    
    try {
        # Find PuTTY
        $puttyPaths = @(
            "putty.exe",
            "C:\Program Files\PuTTY\putty.exe",
            "C:\Program Files (x86)\PuTTY\putty.exe",
            "$env:LOCALAPPDATA\Programs\PuTTY\putty.exe"
        )
        
        $puttyFound = $false
        $puttyPath = ""
        
        foreach ($path in $puttyPaths) {
            if (Get-Command $path -ErrorAction SilentlyContinue) {
                $puttyPath = $path
                $puttyFound = $true
                break
            } elseif (Test-Path $path) {
                $puttyPath = $path
                $puttyFound = $true
                break
            }
        }
        
        if (-not $puttyFound) {
            $txtPuTTYOutput.AppendText("✗ PuTTY not found in common locations or PATH.`r`n")
            $txtPuTTYOutput.AppendText("`r`nPlease install PuTTY using the 'Download PuTTY' button.`r`n")
            return
        }
        
        $arguments = "-ssh $host -P $port"
        
        if (-not [string]::IsNullOrWhiteSpace($username)) {
            $arguments += " -l $username"
            $txtPuTTYOutput.AppendText("✓ Username: $username`r`n")
        }
        
        $txtPuTTYOutput.AppendText("✓ Host: $host`r`n")
        $txtPuTTYOutput.AppendText("✓ Port: $port`r`n")
        $txtPuTTYOutput.AppendText("✓ PuTTY path: $puttyPath`r`n")
        $txtPuTTYOutput.AppendText("`r`nCommand: $puttyPath $arguments`r`n")
        
        Start-Process $puttyPath -ArgumentList $arguments
        
        $txtPuTTYOutput.AppendText("`r`n✓ PuTTY launched successfully!`r`n")
        $txtPuTTYOutput.AppendText("`r`nThe PuTTY window should open separately.`r`n")
        $txtPuTTYOutput.AppendText("You will be prompted for a password in the terminal.`r`n")
        
    } catch {
        $txtPuTTYOutput.AppendText("`r`n✗ ERROR: $($_.Exception.Message)`r`n")
    }
})

$btnDownloadPuTTY.Add_Click({
    $txtPuTTYOutput.AppendText("`r`nOpening PuTTY download page...`r`n")
    Start-Process "https://www.putty.org/"
    $txtPuTTYOutput.AppendText("✓ Browser launched with PuTTY website`r`n")
})

$btnClearPuTTY.Add_Click({
    $txtPuTTYOutput.Clear()
})

# ═══════════════════════════════════════════════════════════════════════════════
# PANEL 11: SERVER REBOOT MONITOR - Reboot server with visual ping monitoring
# ═══════════════════════════════════════════════════════════════════════════════
$panelReboot = New-Object System.Windows.Forms.Panel
$panelReboot.Location = New-Object System.Drawing.Point(0, 0)
$panelReboot.Size = New-Object System.Drawing.Size(1610, 980)
$panelReboot.BackColor = $nearBlack
$panelReboot.Visible = $false
$contentPanel.Controls.Add($panelReboot)

$lblRebootTarget = New-Object System.Windows.Forms.Label
$lblRebootTarget.Text = "Target Server (uses global if empty):"
$lblRebootTarget.Location = New-Object System.Drawing.Point(20, 25)
$lblRebootTarget.Size = New-Object System.Drawing.Size(250, 25)
$lblRebootTarget.ForeColor = $textColor
$lblRebootTarget.Font = $generalFont
$panelReboot.Controls.Add($lblRebootTarget)

$txtRebootTarget = New-Object System.Windows.Forms.TextBox
$txtRebootTarget.Location = New-Object System.Drawing.Point(280, 22)
$txtRebootTarget.Size = New-Object System.Drawing.Size(400, 25)
$txtRebootTarget.BackColor = $darkGray
$txtRebootTarget.ForeColor = $textColor
$txtRebootTarget.Font = $generalFont
$panelReboot.Controls.Add($txtRebootTarget)

$lblRebootDelay = New-Object System.Windows.Forms.Label
$lblRebootDelay.Text = "Delay (seconds):"
$lblRebootDelay.Location = New-Object System.Drawing.Point(700, 25)
$lblRebootDelay.Size = New-Object System.Drawing.Size(120, 25)
$lblRebootDelay.ForeColor = $textColor
$lblRebootDelay.Font = $generalFont
$panelReboot.Controls.Add($lblRebootDelay)

$txtRebootDelay = New-Object System.Windows.Forms.TextBox
$txtRebootDelay.Location = New-Object System.Drawing.Point(830, 22)
$txtRebootDelay.Size = New-Object System.Drawing.Size(80, 25)
$txtRebootDelay.BackColor = $darkGray
$txtRebootDelay.ForeColor = $textColor
$txtRebootDelay.Font = $generalFont
$txtRebootDelay.Text = "30"
$panelReboot.Controls.Add($txtRebootDelay)

$btnReboot = New-Object System.Windows.Forms.Button
$btnReboot.Text = "🔄 Reboot Server"
$btnReboot.Location = New-Object System.Drawing.Point(20, 65)
$btnReboot.Size = New-Object System.Drawing.Size(180, 35)
$btnReboot.BackColor = $darkGray
$btnReboot.ForeColor = $red
$btnReboot.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnReboot.FlatAppearance.BorderColor = $red
$btnReboot.FlatAppearance.BorderSize = 2
$btnReboot.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$panelReboot.Controls.Add($btnReboot)

$btnPingMonitor = New-Object System.Windows.Forms.Button
$btnPingMonitor.Text = "📡 Ping Monitor Only"
$btnPingMonitor.Location = New-Object System.Drawing.Point(210, 65)
$btnPingMonitor.Size = New-Object System.Drawing.Size(180, 35)
$btnPingMonitor.BackColor = $darkGray
$btnPingMonitor.ForeColor = $teal
$btnPingMonitor.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnPingMonitor.FlatAppearance.BorderColor = $teal
$btnPingMonitor.FlatAppearance.BorderSize = 2
$btnPingMonitor.Font = $generalFont
$panelReboot.Controls.Add($btnPingMonitor)

$btnClearReboot = New-Object System.Windows.Forms.Button
$btnClearReboot.Text = "🗑 Clear"
$btnClearReboot.Location = New-Object System.Drawing.Point(400, 65)
$btnClearReboot.Size = New-Object System.Drawing.Size(100, 35)
$btnClearReboot.BackColor = $darkGray
$btnClearReboot.ForeColor = $silver
$btnClearReboot.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearReboot.FlatAppearance.BorderColor = $silver
$btnClearReboot.Font = $generalFont
$panelReboot.Controls.Add($btnClearReboot)

$txtRebootOutput = New-Object System.Windows.Forms.TextBox
$txtRebootOutput.Location = New-Object System.Drawing.Point(20, 120)
$txtRebootOutput.Size = New-Object System.Drawing.Size(1550, 820)
$txtRebootOutput.Multiline = $true
$txtRebootOutput.ScrollBars = "Vertical"
$txtRebootOutput.BackColor = $darkGray
$txtRebootOutput.ForeColor = $textColor
$txtRebootOutput.Font = $monoFont
$txtRebootOutput.ReadOnly = $true
$panelReboot.Controls.Add($txtRebootOutput)

$btnReboot.Add_Click({
    $target = if ([string]::IsNullOrWhiteSpace($txtRebootTarget.Text)) { $script:globalTargetHost } else { $txtRebootTarget.Text.Trim() }
    $delay = 30
    
    try {
        $delay = [int]$txtRebootDelay.Text
        if ($delay -lt 0) { $delay = 30 }
    } catch {
        $delay = 30
    }
    
    if ([string]::IsNullOrWhiteSpace($target) -or $target -eq "localhost") {
        [System.Windows.Forms.MessageBox]::Show("Cannot reboot localhost from this tool. Please specify a remote server.", "Invalid Target", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    $result = [System.Windows.Forms.MessageBox]::Show("⚠ WARNING: This will REBOOT the server $target in $delay seconds!`r`n`r`nAre you sure you want to continue?", "Confirm Reboot", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $txtRebootOutput.Text = "═══════════════════════════════════════════════════════════════`r`n"
        $txtRebootOutput.AppendText("  SERVER REBOOT WITH MONITORING - $target`r`n")
        $txtRebootOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
        
        try {
            $cred = $script:storedCredentials
            if (-not $cred) {
                $credResult = [System.Windows.Forms.MessageBox]::Show("No credentials loaded. Load credentials now?", "Credentials Required", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
                if ($credResult -eq [System.Windows.Forms.DialogResult]::Yes) {
                    $cred = Get-T2Credentials -Purpose "rebooting $target"
                    if ($cred) {
                        $script:storedCredentials = $cred
                        $lblCredStatus.Text = "✓ Loaded: $($cred.UserName)"
                        $lblCredStatus.ForeColor = $green
                    }
                }
            }
            
            if ($cred) {
                $txtRebootOutput.AppendText("Initiating reboot command...`r`n")
                $txtRebootOutput.AppendText("Target: $target`r`n")
                $txtRebootOutput.AppendText("Delay: $delay seconds`r`n`r`n")
                
                Restart-Computer -ComputerName $target -Credential $cred -Force -Delay $delay -ErrorAction Stop
                
                $txtRebootOutput.AppendText("✓ Reboot command sent successfully!`r`n")
                $txtRebootOutput.AppendText("`r`nStarting ping monitoring...`r`n")
                $txtRebootOutput.AppendText("─────────────────────────────────────────────────────────`r`n")
                
                # Monitor with pings
                for ($i = 1; $i -le 60; $i++) {
                    $timestamp = Get-Date -Format "HH:mm:ss"
                    try {
                        $pingResult = Test-Connection -ComputerName $target -Count 1 -Quiet -ErrorAction SilentlyContinue
                        if ($pingResult) {
                            $txtRebootOutput.AppendText("[$timestamp] ✓ Server is online`r`n")
                        } else {
                            $txtRebootOutput.AppendText("[$timestamp] ⚠ Server is offline (rebooting)`r`n")
                        }
                    } catch {
                        $txtRebootOutput.AppendText("[$timestamp] ⚠ Server unreachable`r`n")
                    }
                    
                    Start-Sleep -Seconds 5
                    
                    if ($i -ge 20) { break }
                }
                
                $txtRebootOutput.AppendText("`r`n═══════════════════════════════════════════════════════════════`r`n")
                $txtRebootOutput.AppendText("  MONITORING COMPLETE`r`n")
                $txtRebootOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n")
            } else {
                $txtRebootOutput.AppendText("✗ Operation cancelled - no credentials provided`r`n")
            }
            
        } catch {
            $txtRebootOutput.AppendText("`r`n✗ ERROR: $($_.Exception.Message)`r`n")
        }
    }
})

$btnPingMonitor.Add_Click({
    $target = if ([string]::IsNullOrWhiteSpace($txtRebootTarget.Text)) { $script:globalTargetHost } else { $txtRebootTarget.Text.Trim() }
    
    if ([string]::IsNullOrWhiteSpace($target)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a target host.", "Input Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    $txtRebootOutput.Text = "═══════════════════════════════════════════════════════════════`r`n"
    $txtRebootOutput.AppendText("  PING MONITORING - $target`r`n")
    $txtRebootOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
    
    for ($i = 1; $i -le 20; $i++) {
        $timestamp = Get-Date -Format "HH:mm:ss"
        try {
            $result = Test-Connection -ComputerName $target -Count 1 -ErrorAction Stop
            $txtRebootOutput.AppendText("[$timestamp] ✓ Reply from $($result.IPV4Address): time=$($result.ResponseTime)ms`r`n")
        } catch {
            $txtRebootOutput.AppendText("[$timestamp] ✗ No response from $target`r`n")
        }
        
        Start-Sleep -Seconds 3
    }
    
    $txtRebootOutput.AppendText("`r`n═══════════════════════════════════════════════════════════════`r`n")
})

$btnClearReboot.Add_Click({
    $txtRebootOutput.Clear()
})

# ═══════════════════════════════════════════════════════════════════════════════
# PANEL 12: CERTIFICATE CHECK - IIS and SQL Server certificates via registry
# ═══════════════════════════════════════════════════════════════════════════════
$panelCertCheck = New-Object System.Windows.Forms.Panel
$panelCertCheck.Location = New-Object System.Drawing.Point(0, 0)
$panelCertCheck.Size = New-Object System.Drawing.Size(1610, 980)
$panelCertCheck.BackColor = $nearBlack
$panelCertCheck.Visible = $false
$contentPanel.Controls.Add($panelCertCheck)

$btnCheckCerts = New-Object System.Windows.Forms.Button
$btnCheckCerts.Text = "🔍 Check All Certificates"
$btnCheckCerts.Location = New-Object System.Drawing.Point(20, 20)
$btnCheckCerts.Size = New-Object System.Drawing.Size(200, 35)
$btnCheckCerts.BackColor = $darkGray
$btnCheckCerts.ForeColor = $teal
$btnCheckCerts.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCheckCerts.FlatAppearance.BorderColor = $teal
$btnCheckCerts.FlatAppearance.BorderSize = 2
$btnCheckCerts.Font = $generalFont
$panelCertCheck.Controls.Add($btnCheckCerts)

$btnCheckIIS = New-Object System.Windows.Forms.Button
$btnCheckIIS.Text = "🌐 IIS Certs Only"
$btnCheckIIS.Location = New-Object System.Drawing.Point(230, 20)
$btnCheckIIS.Size = New-Object System.Drawing.Size(150, 35)
$btnCheckIIS.BackColor = $darkGray
$btnCheckIIS.ForeColor = $teal
$btnCheckIIS.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCheckIIS.FlatAppearance.BorderColor = $teal
$btnCheckIIS.FlatAppearance.BorderSize = 2
$btnCheckIIS.Font = $generalFont
$panelCertCheck.Controls.Add($btnCheckIIS)

$btnCheckSQL = New-Object System.Windows.Forms.Button
$btnCheckSQL.Text = "🗄 SQL Certs Only"
$btnCheckSQL.Location = New-Object System.Drawing.Point(390, 20)
$btnCheckSQL.Size = New-Object System.Drawing.Size(150, 35)
$btnCheckSQL.BackColor = $darkGray
$btnCheckSQL.ForeColor = $teal
$btnCheckSQL.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCheckSQL.FlatAppearance.BorderColor = $teal
$btnCheckSQL.FlatAppearance.BorderSize = 2
$btnCheckSQL.Font = $generalFont
$panelCertCheck.Controls.Add($btnCheckSQL)

$btnClearCerts = New-Object System.Windows.Forms.Button
$btnClearCerts.Text = "🗑 Clear"
$btnClearCerts.Location = New-Object System.Drawing.Point(550, 20)
$btnClearCerts.Size = New-Object System.Drawing.Size(100, 35)
$btnClearCerts.BackColor = $darkGray
$btnClearCerts.ForeColor = $silver
$btnClearCerts.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearCerts.FlatAppearance.BorderColor = $silver
$btnClearCerts.Font = $generalFont
$panelCertCheck.Controls.Add($btnClearCerts)

$txtCertOutput = New-Object System.Windows.Forms.TextBox
$txtCertOutput.Location = New-Object System.Drawing.Point(20, 70)
$txtCertOutput.Size = New-Object System.Drawing.Size(1550, 870)
$txtCertOutput.Multiline = $true
$txtCertOutput.ScrollBars = "Vertical"
$txtCertOutput.BackColor = $darkGray
$txtCertOutput.ForeColor = $textColor
$txtCertOutput.Font = $monoFont
$txtCertOutput.ReadOnly = $true
$panelCertCheck.Controls.Add($txtCertOutput)

$btnCheckCerts.Add_Click({
    $targetHost = $script:globalTargetHost
    if ([string]::IsNullOrWhiteSpace($targetHost)) { $targetHost = "localhost" }
    
    $txtCertOutput.Text = "═══════════════════════════════════════════════════════════════`r`n"
    $txtCertOutput.AppendText("  CERTIFICATE CHECK - $targetHost`r`n")
    $txtCertOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
    
    try {
        # Check Local Computer certificates
        $txtCertOutput.AppendText("► LOCAL COMPUTER CERTIFICATES:`r`n`r`n")
        
        $certs = Get-ChildItem -Path Cert:\LocalMachine\My -ErrorAction SilentlyContinue
        if ($certs) {
            foreach ($cert in $certs) {
                $daysUntilExpiry = ($cert.NotAfter - (Get-Date)).Days
                $status = if ($daysUntilExpiry -lt 0) { "⚠ EXPIRED" } elseif ($daysUntilExpiry -lt 30) { "⚡ EXPIRING SOON" } else { "✓ Valid" }
                
                $txtCertOutput.AppendText("$status Certificate`r`n")
                $txtCertOutput.AppendText("  Subject: $($cert.Subject)`r`n")
                $txtCertOutput.AppendText("  Issuer: $($cert.Issuer)`r`n")
                $txtCertOutput.AppendText("  Thumbprint: $($cert.Thumbprint)`r`n")
                $txtCertOutput.AppendText("  Valid From: $($cert.NotBefore)`r`n")
                $txtCertOutput.AppendText("  Valid To: $($cert.NotAfter)`r`n")
                $txtCertOutput.AppendText("  Days Until Expiry: $daysUntilExpiry`r`n")
                $txtCertOutput.AppendText("  ─────────────────────────────────────────────────────────`r`n")
            }
        } else {
            $txtCertOutput.AppendText("  No certificates found in LocalMachine\My store`r`n")
        }
        
        # Check Web Hosting certificates
        $txtCertOutput.AppendText("`r`n► WEB HOSTING CERTIFICATES:`r`n`r`n")
        $webCerts = Get-ChildItem -Path Cert:\LocalMachine\WebHosting -ErrorAction SilentlyContinue
        if ($webCerts) {
            foreach ($cert in $webCerts) {
                $daysUntilExpiry = ($cert.NotAfter - (Get-Date)).Days
                $txtCertOutput.AppendText("  Subject: $($cert.Subject) | Expires: $($cert.NotAfter) ($daysUntilExpiry days)`r`n")
            }
        } else {
            $txtCertOutput.AppendText("  No web hosting certificates found`r`n")
        }
        
        # Check for SQL Server certificates via registry
        $txtCertOutput.AppendText("`r`n► SQL SERVER CERTIFICATE CHECK:`r`n`r`n")
        $sqlRegPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server"
        if (Test-Path $sqlRegPath) {
            $txtCertOutput.AppendText("  SQL Server installation detected`r`n")
            
            # Try to find SQL Server instances
            $instances = Get-ChildItem -Path "$sqlRegPath\Instance Names\SQL" -ErrorAction SilentlyContinue
            if ($instances) {
                foreach ($instance in $instances.Property) {
                    $txtCertOutput.AppendText("  Instance: $instance`r`n")
                }
            }
        } else {
            $txtCertOutput.AppendText("  No SQL Server installation detected`r`n")
        }
        
        # Check IIS if installed
        $txtCertOutput.AppendText("`r`n► IIS CERTIFICATE BINDINGS:`r`n`r`n")
        try {
            Import-Module WebAdministration -ErrorAction Stop
            $bindings = Get-WebBinding | Where-Object { $_.protocol -eq "https" }
            if ($bindings) {
                foreach ($binding in $bindings) {
                    $txtCertOutput.AppendText("  Site: $($binding.ItemXPath)`r`n")
                    $txtCertOutput.AppendText("  Binding: $($binding.bindingInformation)`r`n")
                    if ($binding.certificateHash) {
                        $txtCertOutput.AppendText("  Cert Hash: $($binding.certificateHash)`r`n")
                    }
                    $txtCertOutput.AppendText("  ─────────────────────────────────────────────────────────`r`n")
                }
            } else {
                $txtCertOutput.AppendText("  No HTTPS bindings found`r`n")
            }
        } catch {
            $txtCertOutput.AppendText("  IIS not installed or WebAdministration module not available`r`n")
        }
        
    } catch {
        $txtCertOutput.AppendText("`r`n✗ ERROR: $($_.Exception.Message)`r`n")
    }
    
    $txtCertOutput.AppendText("`r`n═══════════════════════════════════════════════════════════════`r`n")
    $txtCertOutput.AppendText("  CERTIFICATE CHECK COMPLETE`r`n")
    $txtCertOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n")
})

$btnCheckIIS.Add_Click({
    $txtCertOutput.Text = "Checking IIS certificates...`r`n`r`n"
    
    try {
        Import-Module WebAdministration -ErrorAction Stop
        $bindings = Get-WebBinding | Where-Object { $_.protocol -eq "https" }
        
        foreach ($binding in $bindings) {
            $txtCertOutput.AppendText("Site: $($binding.ItemXPath)`r`n")
            $txtCertOutput.AppendText("Binding: $($binding.bindingInformation)`r`n")
            if ($binding.certificateHash) {
                $certHash = $binding.certificateHash
                $cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $certHash }
                if ($cert) {
                    $daysUntilExpiry = ($cert.NotAfter - (Get-Date)).Days
                    $txtCertOutput.AppendText("Subject: $($cert.Subject)`r`n")
                    $txtCertOutput.AppendText("Expires: $($cert.NotAfter) ($daysUntilExpiry days)`r`n")
                }
            }
            $txtCertOutput.AppendText("─────────────────────────────────────────────────────────`r`n")
        }
    } catch {
        $txtCertOutput.AppendText("✗ ERROR: $($_.Exception.Message)`r`n")
    }
})

$btnCheckSQL.Add_Click({
    $txtCertOutput.Text = "Checking SQL Server certificates...`r`n`r`n"
    
    try {
        $sqlRegPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server"
        if (Test-Path $sqlRegPath) {
            $txtCertOutput.AppendText("SQL Server detected. Checking instances...`r`n`r`n")
            
            $instances = Get-ChildItem -Path "$sqlRegPath\Instance Names\SQL" -ErrorAction SilentlyContinue
            foreach ($prop in $instances.Property) {
                $txtCertOutput.AppendText("Instance: $prop`r`n")
                $instanceValue = Get-ItemProperty -Path "$sqlRegPath\Instance Names\SQL" -Name $prop
                $txtCertOutput.AppendText("Path: $($instanceValue.$prop)`r`n")
                $txtCertOutput.AppendText("─────────────────────────────────────────────────────────`r`n")
            }
        } else {
            $txtCertOutput.AppendText("No SQL Server installation found`r`n")
        }
    } catch {
        $txtCertOutput.AppendText("✗ ERROR: $($_.Exception.Message)`r`n")
    }
})

$btnClearCerts.Add_Click({
    $txtCertOutput.Clear()
})

# ═══════════════════════════════════════════════════════════════════════════════
# PANEL 13: THREATLOCKER CHECK - Check for ThreatLocker blocking events
# ═══════════════════════════════════════════════════════════════════════════════
$panelThreatLocker = New-Object System.Windows.Forms.Panel
$panelThreatLocker.Location = New-Object System.Drawing.Point(0, 0)
$panelThreatLocker.Size = New-Object System.Drawing.Size(1610, 980)
$panelThreatLocker.BackColor = $nearBlack
$panelThreatLocker.Visible = $false
$contentPanel.Controls.Add($panelThreatLocker)

$lblTLTarget = New-Object System.Windows.Forms.Label
$lblTLTarget.Text = "Target Host (uses global if empty):"
$lblTLTarget.Location = New-Object System.Drawing.Point(20, 25)
$lblTLTarget.Size = New-Object System.Drawing.Size(250, 25)
$lblTLTarget.ForeColor = $textColor
$lblTLTarget.Font = $generalFont
$panelThreatLocker.Controls.Add($lblTLTarget)

$txtTLTarget = New-Object System.Windows.Forms.TextBox
$txtTLTarget.Location = New-Object System.Drawing.Point(280, 22)
$txtTLTarget.Size = New-Object System.Drawing.Size(400, 25)
$txtTLTarget.BackColor = $darkGray
$txtTLTarget.ForeColor = $textColor
$txtTLTarget.Font = $generalFont
$panelThreatLocker.Controls.Add($txtTLTarget)

$btnCheckTL = New-Object System.Windows.Forms.Button
$btnCheckTL.Text = "🔍 Check ThreatLocker"
$btnCheckTL.Location = New-Object System.Drawing.Point(20, 65)
$btnCheckTL.Size = New-Object System.Drawing.Size(200, 35)
$btnCheckTL.BackColor = $darkGray
$btnCheckTL.ForeColor = $teal
$btnCheckTL.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCheckTL.FlatAppearance.BorderColor = $teal
$btnCheckTL.FlatAppearance.BorderSize = 2
$btnCheckTL.Font = $generalFont
$panelThreatLocker.Controls.Add($btnCheckTL)

$btnCheckTLService = New-Object System.Windows.Forms.Button
$btnCheckTLService.Text = "⚙ Check Service Status"
$btnCheckTLService.Location = New-Object System.Drawing.Point(230, 65)
$btnCheckTLService.Size = New-Object System.Drawing.Size(200, 35)
$btnCheckTLService.BackColor = $darkGray
$btnCheckTLService.ForeColor = $teal
$btnCheckTLService.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCheckTLService.FlatAppearance.BorderColor = $teal
$btnCheckTLService.FlatAppearance.BorderSize = 2
$btnCheckTLService.Font = $generalFont
$panelThreatLocker.Controls.Add($btnCheckTLService)

$btnClearTL = New-Object System.Windows.Forms.Button
$btnClearTL.Text = "🗑 Clear"
$btnClearTL.Location = New-Object System.Drawing.Point(440, 65)
$btnClearTL.Size = New-Object System.Drawing.Size(100, 35)
$btnClearTL.BackColor = $darkGray
$btnClearTL.ForeColor = $silver
$btnClearTL.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearTL.FlatAppearance.BorderColor = $silver
$btnClearTL.Font = $generalFont
$panelThreatLocker.Controls.Add($btnClearTL)

$txtTLOutput = New-Object System.Windows.Forms.TextBox
$txtTLOutput.Location = New-Object System.Drawing.Point(20, 120)
$txtTLOutput.Size = New-Object System.Drawing.Size(1550, 820)
$txtTLOutput.Multiline = $true
$txtTLOutput.ScrollBars = "Vertical"
$txtTLOutput.BackColor = $darkGray
$txtTLOutput.ForeColor = $textColor
$txtTLOutput.Font = $monoFont
$txtTLOutput.ReadOnly = $true
$panelThreatLocker.Controls.Add($txtTLOutput)

$btnCheckTL.Add_Click({
    $targetHost = if ([string]::IsNullOrWhiteSpace($txtTLTarget.Text)) { $script:globalTargetHost } else { $txtTLTarget.Text.Trim() }
    if ([string]::IsNullOrWhiteSpace($targetHost)) { $targetHost = "localhost" }
    
    $txtTLOutput.Text = "═══════════════════════════════════════════════════════════════`r`n"
    $txtTLOutput.AppendText("  THREATLOCKER CHECK - $targetHost`r`n")
    $txtTLOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
    
    try {
        $txtTLOutput.AppendText("Checking for ThreatLocker blocking events...`r`n`r`n")
        
        # Check Event Logs for ThreatLocker
        $txtTLOutput.AppendText("► EVENT LOG CHECK:`r`n")
        try {
            $tlEvents = Get-WinEvent -FilterHashtable @{LogName='Application','System'; ProviderName='*ThreatLocker*'} -MaxEvents 50 -ErrorAction SilentlyContinue
            
            if ($tlEvents) {
                $txtTLOutput.AppendText("  Found $($tlEvents.Count) ThreatLocker events:`r`n`r`n")
                foreach ($event in $tlEvents | Select-Object -First 20) {
                    $txtTLOutput.AppendText("  [$($event.TimeCreated.ToString('MM/dd HH:mm'))] $($event.LevelDisplayName)`r`n")
                    $txtTLOutput.AppendText("    $($event.Message.Substring(0, [Math]::Min(150, $event.Message.Length)))...`r`n")
                    $txtTLOutput.AppendText("    ─────────────────────────────────────────────────────────`r`n")
                }
            } else {
                $txtTLOutput.AppendText("  No ThreatLocker events found in recent logs`r`n")
            }
        } catch {
            $txtTLOutput.AppendText("  Unable to query ThreatLocker events: $($_.Exception.Message)`r`n")
        }
        
        # Check for ThreatLocker installation
        $txtTLOutput.AppendText("`r`n► INSTALLATION CHECK:`r`n")
        $tlPath = "C:\Program Files\ThreatLocker"
        if (Test-Path $tlPath) {
            $txtTLOutput.AppendText("  ✓ ThreatLocker installation found at: $tlPath`r`n")
        } else {
            $txtTLOutput.AppendText("  ⚠ ThreatLocker installation not found in default location`r`n")
        }
        
        # Check registry for ThreatLocker
        $txtTLOutput.AppendText("`r`n► REGISTRY CHECK:`r`n")
        $tlRegPaths = @(
            "HKLM:\SOFTWARE\ThreatLocker",
            "HKLM:\SYSTEM\CurrentControlSet\Services\ThreatLocker"
        )
        
        foreach ($regPath in $tlRegPaths) {
            if (Test-Path $regPath) {
                $txtTLOutput.AppendText("  ✓ Found: $regPath`r`n")
            }
        }
        
    } catch {
        $txtTLOutput.AppendText("`r`n✗ ERROR: $($_.Exception.Message)`r`n")
    }
    
    $txtTLOutput.AppendText("`r`n═══════════════════════════════════════════════════════════════`r`n")
    $txtTLOutput.AppendText("  THREATLOCKER CHECK COMPLETE`r`n")
    $txtTLOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n")
})

$btnCheckTLService.Add_Click({
    $targetHost = if ([string]::IsNullOrWhiteSpace($txtTLTarget.Text)) { $script:globalTargetHost } else { $txtTLTarget.Text.Trim() }
    if ([string]::IsNullOrWhiteSpace($targetHost)) { $targetHost = "localhost" }
    
    $txtTLOutput.Text = "Checking ThreatLocker service status on $targetHost...`r`n`r`n"
    
    try {
        $services = Get-Service -Name "*ThreatLocker*" -ErrorAction SilentlyContinue
        
        if ($services) {
            foreach ($svc in $services) {
                $status = if ($svc.Status -eq "Running") { "✓" } else { "⚠" }
                $txtTLOutput.AppendText("$status $($svc.DisplayName)`r`n")
                $txtTLOutput.AppendText("  Name: $($svc.Name)`r`n")
                $txtTLOutput.AppendText("  Status: $($svc.Status)`r`n")
                $txtTLOutput.AppendText("  Start Type: $($svc.StartType)`r`n")
                $txtTLOutput.AppendText("  ─────────────────────────────────────────────────────────`r`n")
            }
        } else {
            $txtTLOutput.AppendText("⚠ No ThreatLocker services found`r`n")
        }
    } catch {
        $txtTLOutput.AppendText("✗ ERROR: $($_.Exception.Message)`r`n")
    }
})

$btnClearTL.Add_Click({
    $txtTLOutput.Clear()
})

# ═══════════════════════════════════════════════════════════════════════════════
# PANEL 14: SERVICES MANAGER - Windows Services management
# ═══════════════════════════════════════════════════════════════════════════════
$panelServices = New-Object System.Windows.Forms.Panel
$panelServices.Location = New-Object System.Drawing.Point(0, 0)
$panelServices.Size = New-Object System.Drawing.Size(1610, 980)
$panelServices.BackColor = $nearBlack
$panelServices.Visible = $false
$contentPanel.Controls.Add($panelServices)

$lblServicesTarget = New-Object System.Windows.Forms.Label
$lblServicesTarget.Text = "Target Host (uses global if empty):"
$lblServicesTarget.Location = New-Object System.Drawing.Point(20, 25)
$lblServicesTarget.Size = New-Object System.Drawing.Size(250, 25)
$lblServicesTarget.ForeColor = $textColor
$lblServicesTarget.Font = $generalFont
$panelServices.Controls.Add($lblServicesTarget)

$txtServicesTarget = New-Object System.Windows.Forms.TextBox
$txtServicesTarget.Location = New-Object System.Drawing.Point(280, 22)
$txtServicesTarget.Size = New-Object System.Drawing.Size(400, 25)
$txtServicesTarget.BackColor = $darkGray
$txtServicesTarget.ForeColor = $textColor
$txtServicesTarget.Font = $generalFont
$panelServices.Controls.Add($txtServicesTarget)

$btnOpenServices = New-Object System.Windows.Forms.Button
$btnOpenServices.Text = "🖥 Open services.msc"
$btnOpenServices.Location = New-Object System.Drawing.Point(20, 65)
$btnOpenServices.Size = New-Object System.Drawing.Size(200, 35)
$btnOpenServices.BackColor = $darkGray
$btnOpenServices.ForeColor = $teal
$btnOpenServices.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnOpenServices.FlatAppearance.BorderColor = $teal
$btnOpenServices.FlatAppearance.BorderSize = 2
$btnOpenServices.Font = $generalFont
$panelServices.Controls.Add($btnOpenServices)

$btnListServices = New-Object System.Windows.Forms.Button
$btnListServices.Text = "📋 List All Services"
$btnListServices.Location = New-Object System.Drawing.Point(230, 65)
$btnListServices.Size = New-Object System.Drawing.Size(200, 35)
$btnListServices.BackColor = $darkGray
$btnListServices.ForeColor = $teal
$btnListServices.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnListServices.FlatAppearance.BorderColor = $teal
$btnListServices.FlatAppearance.BorderSize = 2
$btnListServices.Font = $generalFont
$panelServices.Controls.Add($btnListServices)

$btnClearServices = New-Object System.Windows.Forms.Button
$btnClearServices.Text = "🗑 Clear"
$btnClearServices.Location = New-Object System.Drawing.Point(440, 65)
$btnClearServices.Size = New-Object System.Drawing.Size(100, 35)
$btnClearServices.BackColor = $darkGray
$btnClearServices.ForeColor = $silver
$btnClearServices.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearServices.FlatAppearance.BorderColor = $silver
$btnClearServices.Font = $generalFont
$panelServices.Controls.Add($btnClearServices)

$txtServicesOutput = New-Object System.Windows.Forms.TextBox
$txtServicesOutput.Location = New-Object System.Drawing.Point(20, 120)
$txtServicesOutput.Size = New-Object System.Drawing.Size(1550, 820)
$txtServicesOutput.Multiline = $true
$txtServicesOutput.ScrollBars = "Vertical"
$txtServicesOutput.BackColor = $darkGray
$txtServicesOutput.ForeColor = $textColor
$txtServicesOutput.Font = $monoFont
$txtServicesOutput.ReadOnly = $true
$txtServicesOutput.Text = "═══════════════════════════════════════════════════════════════`r`n" +
                          "  SERVICES MANAGER`r`n" +
                          "═══════════════════════════════════════════════════════════════`r`n`r`n" +
                          "Use 'Open services.msc' to launch the native Windows Services`r`n" +
                          "management console for the target computer.`r`n`r`n" +
                          "For remote computers, it will attempt to connect using stored`r`n" +
                          "T2 credentials if available.`r`n"
$panelServices.Controls.Add($txtServicesOutput)

$btnOpenServices.Add_Click({
    $targetHost = if ([string]::IsNullOrWhiteSpace($txtServicesTarget.Text)) { $script:globalTargetHost } else { $txtServicesTarget.Text.Trim() }
    if ([string]::IsNullOrWhiteSpace($targetHost) -or $targetHost -eq "localhost") { $targetHost = $env:COMPUTERNAME }
    
    $txtServicesOutput.Text = "═══════════════════════════════════════════════════════════════`r`n"
    $txtServicesOutput.AppendText("  OPENING SERVICES MANAGER - $targetHost`r`n")
    $txtServicesOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
    
    try {
        if ($targetHost -eq $env:COMPUTERNAME) {
            $txtServicesOutput.AppendText("Opening local services.msc...`r`n")
            Start-Process "services.msc"
            $txtServicesOutput.AppendText("✓ Services console launched`r`n")
        } else {
            $txtServicesOutput.AppendText("Opening remote services for: $targetHost`r`n")
            Start-Process "mmc" -ArgumentList "services.msc /computer=$targetHost"
            $txtServicesOutput.AppendText("✓ Remote services console launched`r`n")
            $txtServicesOutput.AppendText("`r`nNote: You may be prompted for credentials if not using`r`n")
            $txtServicesOutput.AppendText("      current domain authentication.`r`n")
        }
    } catch {
        $txtServicesOutput.AppendText("`r`n✗ ERROR: $($_.Exception.Message)`r`n")
    }
})

$btnListServices.Add_Click({
    $targetHost = if ([string]::IsNullOrWhiteSpace($txtServicesTarget.Text)) { $script:globalTargetHost } else { $txtServicesTarget.Text.Trim() }
    if ([string]::IsNullOrWhiteSpace($targetHost)) { $targetHost = "localhost" }
    
    $txtServicesOutput.Text = "═══════════════════════════════════════════════════════════════`r`n"
    $txtServicesOutput.AppendText("  SERVICES LIST - $targetHost`r`n")
    $txtServicesOutput.AppendText("═══════════════════════════════════════════════════════════════`r`n`r`n")
    
    try {
        $services = Get-Service | Sort-Object DisplayName
        
        $runningCount = ($services | Where-Object { $_.Status -eq "Running" }).Count
        $stoppedCount = ($services | Where-Object { $_.Status -eq "Stopped" }).Count
        
        $txtServicesOutput.AppendText("Total Services: $($services.Count)`r`n")
        $txtServicesOutput.AppendText("Running: $runningCount | Stopped: $stoppedCount`r`n")
        $txtServicesOutput.AppendText("`r`n─────────────────────────────────────────────────────────`r`n`r`n")
        
        foreach ($svc in $services) {
            $status = if ($svc.Status -eq "Running") { "✓" } else { "○" }
            $txtServicesOutput.AppendText("$status $($svc.DisplayName)`r`n")
            $txtServicesOutput.AppendText("  Name: $($svc.Name) | Status: $($svc.Status) | StartType: $($svc.StartType)`r`n")
        }
        
    } catch {
        $txtServicesOutput.AppendText("`r`n✗ ERROR: $($_.Exception.Message)`r`n")
    }
    
    $txtServicesOutput.AppendText("`r`n═══════════════════════════════════════════════════════════════`r`n")
})

$btnClearServices.Add_Click({
    $txtServicesOutput.Clear()
})

# ═══════════════════════════════════════════════════════════════════════════════
# NAVIGATION LOGIC - Show/Hide Panels Based on Selection
# ═══════════════════════════════════════════════════════════════════════════════

$navListBox.Add_SelectedIndexChanged({
    # Hide all panels
    $panelNodeSummary.Visible = $false
    $panelNodeHealth.Visible = $false
    $panelPing.Visible = $false
    $panelNSLookup.Visible = $false
    $panelTraceroute.Visible = $false
    $panelDomainUsers.Visible = $false
    $panelIPConfig.Visible = $false
    $panelNetStat.Visible = $false
    $panelRDP.Visible = $false
    $panelPuTTY.Visible = $false
    $panelReboot.Visible = $false
    $panelCertCheck.Visible = $false
    $panelThreatLocker.Visible = $false
    $panelServices.Visible = $false
    
    # Show selected panel
    switch ($navListBox.SelectedIndex) {
        0 { $panelNodeSummary.Visible = $true }
        1 { $panelNodeHealth.Visible = $true }
        2 { $panelPing.Visible = $true }
        3 { $panelNSLookup.Visible = $true }
        4 { $panelTraceroute.Visible = $true }
        5 { $panelDomainUsers.Visible = $true }
        6 { $panelIPConfig.Visible = $true }
        7 { $panelNetStat.Visible = $true }
        8 { $panelRDP.Visible = $true }
        9 { $panelPuTTY.Visible = $true }
        10 { $panelReboot.Visible = $true }
        11 { $panelCertCheck.Visible = $true }
        12 { $panelThreatLocker.Visible = $true }
        13 { $panelServices.Visible = $true }
    }
})

# ═══════════════════════════════════════════════════════════════════════════════
# FORM CLEANUP AND SHOW
# ═══════════════════════════════════════════════════════════════════════════════

# Form closing event - cleanup
$form.Add_FormClosing({
    # Clear credentials from memory
    $script:storedCredentials = $null
    
    # Any other cleanup
    [System.GC]::Collect()
})

# Show the form
[void]$form.ShowDialog()

# Script end
