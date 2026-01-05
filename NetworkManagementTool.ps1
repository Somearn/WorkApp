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
    $credForm.Size = New-Object System.Drawing.Size(500, 240)
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
    $lblInfo.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
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
    $lblNote.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $credForm.Controls.Add($lblNote)
    
    $btnOK = New-Object System.Windows.Forms.Button
    $btnOK.Text = "✓ OK"
    $btnOK.Location = New-Object System.Drawing.Point(210, 160)
    $btnOK.Size = New-Object System.Drawing.Size(120, 35)
    $btnOK.BackColor = [System.Drawing.Color]::FromArgb(0, 178, 255)
    $btnOK.ForeColor = [System.Drawing.Color]::White
    $btnOK.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnOK.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $credForm.Controls.Add($btnOK)
    
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "✗ Cancel"
    $btnCancel.Location = New-Object System.Drawing.Point(340, 160)
    $btnCancel.Size = New-Object System.Drawing.Size(120, 35)
    $btnCancel.BackColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
    $btnCancel.ForeColor = [System.Drawing.Color]::White
    $btnCancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btnCancel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
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
$form.Size = New-Object System.Drawing.Size(1920, 1080)
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
$generalFont = New-Object System.Drawing.Font("Segoe UI", 10)
$titleFont = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$monoFont = New-Object System.Drawing.Font("Consolas", 9)
$smallFont = New-Object System.Drawing.Font("Segoe UI", 9)

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
$txtGlobalHost.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
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
# TAB CONTROL
# ═══════════════════════════════════════════════════════════════════════════════

$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(20, 55)
$tabControl.Size = New-Object System.Drawing.Size(1860, 980)
$tabControl.Font = $generalFont
$tabControl.BackColor = $darkGray
$tabControl.ForeColor = $textColor
$form.Controls.Add($tabControl)

# ═══════════════════════════════════════════════════════════════════════════════
# TAB 1: NODE SUMMARY - System information and network configuration
# ═══════════════════════════════════════════════════════════════════════════════
$tabNodeSummary = New-Object System.Windows.Forms.TabPage
$tabNodeSummary.Text = "📊 Node Summary"
$tabNodeSummary.BackColor = $nearBlack
$tabControl.Controls.Add($tabNodeSummary)

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
$tabNodeSummary.Controls.Add($btnGetNodeInfo)

$btnClearNodeInfo = New-Object System.Windows.Forms.Button
$btnClearNodeInfo.Text = "🗑 Clear"
$btnClearNodeInfo.Location = New-Object System.Drawing.Point(230, 20)
$btnClearNodeInfo.Size = New-Object System.Drawing.Size(100, 35)
$btnClearNodeInfo.BackColor = $darkGray
$btnClearNodeInfo.ForeColor = $silver
$btnClearNodeInfo.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearNodeInfo.FlatAppearance.BorderColor = $silver
$btnClearNodeInfo.Font = $generalFont
$tabNodeSummary.Controls.Add($btnClearNodeInfo)

$txtNodeInfo = New-Object System.Windows.Forms.TextBox
$txtNodeInfo.Location = New-Object System.Drawing.Point(20, 70)
$txtNodeInfo.Size = New-Object System.Drawing.Size(1800, 870)
$txtNodeInfo.Multiline = $true
$txtNodeInfo.ScrollBars = "Vertical"
$txtNodeInfo.BackColor = $darkGray
$txtNodeInfo.ForeColor = $textColor
$txtNodeInfo.Font = $monoFont
$txtNodeInfo.ReadOnly = $true
$tabNodeSummary.Controls.Add($txtNodeInfo)

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
# TAB 2: NODE HEALTH CHECK - Quick health diagnostics
# ═══════════════════════════════════════════════════════════════════════════════
$tabNodeHealth = New-Object System.Windows.Forms.TabPage
$tabNodeHealth.Text = "❤ Node Health"
$tabNodeHealth.BackColor = $nearBlack
$tabControl.Controls.Add($tabNodeHealth)

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
$tabNodeHealth.Controls.Add($btnCheckHealth)

$btnClearHealth = New-Object System.Windows.Forms.Button
$btnClearHealth.Text = "🗑 Clear"
$btnClearHealth.Location = New-Object System.Drawing.Point(230, 20)
$btnClearHealth.Size = New-Object System.Drawing.Size(100, 35)
$btnClearHealth.BackColor = $darkGray
$btnClearHealth.ForeColor = $silver
$btnClearHealth.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnClearHealth.FlatAppearance.BorderColor = $silver
$btnClearHealth.Font = $generalFont
$tabNodeHealth.Controls.Add($btnClearHealth)

$txtHealthOutput = New-Object System.Windows.Forms.TextBox
$txtHealthOutput.Location = New-Object System.Drawing.Point(20, 70)
$txtHealthOutput.Size = New-Object System.Drawing.Size(1800, 870)
$txtHealthOutput.Multiline = $true
$txtHealthOutput.ScrollBars = "Vertical"
$txtHealthOutput.BackColor = $darkGray
$txtHealthOutput.ForeColor = $textColor
$txtHealthOutput.Font = $monoFont
$txtHealthOutput.ReadOnly = $true
$tabNodeHealth.Controls.Add($txtHealthOutput)

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

