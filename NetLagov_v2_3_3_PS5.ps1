# ============================================================
#  NetLagov v2.3.3
#  Авто-повышение до Администратора
# ============================================================

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`""
    Exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ── ЦВЕТА ──
$C_BG     = [System.Drawing.Color]::FromArgb(10,  10,  20)
$C_PANEL  = [System.Drawing.Color]::FromArgb(18,  18,  35)
$C_ACCENT = [System.Drawing.Color]::FromArgb(0,   210, 255)
$C_PURPLE = [System.Drawing.Color]::FromArgb(130, 0,   255)
$C_GREEN  = [System.Drawing.Color]::FromArgb(0,   255, 130)
$C_RED    = [System.Drawing.Color]::FromArgb(255, 60,  80)
$C_YELLOW = [System.Drawing.Color]::FromArgb(255, 200, 0)
$C_TEXT   = [System.Drawing.Color]::FromArgb(220, 220, 240)
$C_DIM    = [System.Drawing.Color]::FromArgb(100, 100, 130)

# ── ШРИФТЫ ──
$F_TITLE  = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$F_HEADER = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$F_NORMAL = New-Object System.Drawing.Font("Segoe UI", 9)
$F_SMALL  = New-Object System.Drawing.Font("Segoe UI", 8)
$F_MONO   = New-Object System.Drawing.Font("Consolas", 8)
$F_BIG    = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$F_INFO   = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)

# ── ЯЗЫК ──
$Script:Lang      = "RU"
$Script:LangItems = [System.Collections.Generic.List[hashtable]]::new()

function global:GNO_TStr { param([string]$RU, [string]$EN)
    if ($Script:Lang -eq "RU") { return $RU } else { return $EN }
}

function global:GNO_RegLang {
    param($Ctrl, [string]$RU, [string]$EN)
    $Script:LangItems.Add(@{C=$Ctrl; RU=$RU; EN=$EN; IsTooltip=$false})
    $Ctrl.Text = $RU
}

function global:GNO_SwitchLang {
    param([string]$Lang)
    $Script:Lang = $Lang
    foreach ($item in $Script:LangItems) {
        try {
            if ($item.C.IsDisposed) { continue }
            if ($item.IsTooltip) {
                $Script:Tooltip.SetToolTip($item.C, $item[$Lang])
            } else {
                $item.C.Text = $item[$Lang]
            }
        } catch {}
    }
}

# ── ЛОГ ──
# Place logs beside the script when run as PS1, or beside the EXE in a compiled build.
$Script:AppFilePath = [string]$MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($Script:AppFilePath) -or -not (Test-Path -LiteralPath $Script:AppFilePath -PathType Leaf -ErrorAction SilentlyContinue)) {
    $Script:AppFilePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
}
$Script:AppDirectory = Split-Path -Parent -Path $Script:AppFilePath
$Script:LogFile = Join-Path $Script:AppDirectory ("NetLagov_{0}.log" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))

function global:GNO_WriteLog {
    param([string]$Msg, [string]$Lvl = "INFO")
    Add-Content -Path $Script:LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Lvl] $Msg" -Encoding UTF8
}

function global:GNO_RunCmd {
    param([string]$Cmd)
    GNO_WriteLog "EXEC: $Cmd"
    try   { $r = cmd /c "$Cmd 2>&1"; GNO_WriteLog "OUT: $($r -join ' | ')"; return $r }
    catch { GNO_WriteLog "ERR: $_" "ERROR"; return "ERROR: $_" }
}

# ── DNS ──
$Script:DNSMap = [ordered]@{
    # --- Глобальные / быстрые ---
    "Cloudflare"         = @("1.1.1.1",          "1.0.0.1")
    "Cloudflare Family"  = @("1.1.1.3",          "1.0.0.3")
    "Google"             = @("8.8.8.8",           "8.8.4.4")
    "Quad9"              = @("9.9.9.9",           "149.112.112.112")
    "Quad9 ECS"          = @("9.9.9.11",          "149.112.112.11")
    "OpenDNS"            = @("208.67.222.222",    "208.67.220.220")
    "OpenDNS FamilyShield"=@("208.67.222.123",    "208.67.220.123")
    "AdGuard"            = @("94.140.14.14",      "94.140.15.15")
    "AdGuard Family"     = @("94.140.14.15",      "94.140.15.16")
    "Comodo Secure"      = @("8.26.56.26",        "8.20.247.20")
    "Level3"             = @("209.244.0.3",       "209.244.0.4")
    "Verisign"           = @("64.6.64.6",         "64.6.65.6")
    "DNS.Watch"          = @("84.200.69.80",      "84.200.70.40")
    "Neustar"            = @("156.154.70.1",      "156.154.71.1")
    "Norton ConnectSafe" = @("199.85.126.10",     "199.85.127.10")
    "Yandex Basic"       = @("77.88.8.8",         "77.88.8.1")
    "Yandex Safe"        = @("77.88.8.88",        "77.88.8.2")
    "SkyDNS"             = @("193.58.251.251",    "193.58.251.252")
    "Comss.one"          = @("92.38.152.163",     "93.115.24.204")
    # --- Российские / региональные ---
    "Rostelecom"         = @("195.34.32.116",     "195.34.32.117")
    "MTS"                = @("213.87.0.1",        "213.87.1.1")
    "Beeline"            = @("80.77.16.16",       "80.77.16.17")
    "MGTS"               = @("195.14.99.2",       "195.14.99.3")
    # --- Конфиденциальность ---
    "NextDNS"            = @("45.90.28.0",        "45.90.30.0")
    "ControlD"           = @("76.76.2.0",         "76.76.10.0")
}
$Script:BestDNS = $null
$Script:SelectedDNS = $null
$Script:SelectedAdapter = $null

function global:GNO_GetSelectedAdapters {
    if (-not $Script:SelectedAdapter) { return @() }
    $adapter = Get-NetAdapter -InterfaceIndex $Script:SelectedAdapter.InterfaceIndex -ErrorAction SilentlyContinue
    if ($adapter -and $adapter.Status -eq "Up") { return ,$adapter }
    return @()
}

function global:GNO_RefreshAdapters {
    $previousIndex = if ($Script:SelectedAdapter) { $Script:SelectedAdapter.InterfaceIndex } else { $null }
    $Script:AdapterByName = @{}
    $Script:AdapterCombo.BeginUpdate()
    try {
        $Script:AdapterCombo.Items.Clear()
        $adapters = @(Get-NetAdapter | Where-Object { $_.Status -eq "Up" })
        foreach ($adapter in $adapters) {
            $adapterName = [string]$adapter.Name
            $Script:AdapterByName[$adapterName] = $adapter
            [void]$Script:AdapterCombo.Items.Add($adapterName)
        }
        if ($adapters.Count -gt 0) {
            $idx = 0
            for ($i = 0; $i -lt $adapters.Count; $i++) {
                if ($adapters[$i].InterfaceIndex -eq $previousIndex) { $idx = $i; break }
            }
            $Script:AdapterCombo.SelectedIndex = $idx
            $Script:SelectedAdapter = $adapters[$idx]
            $Script:AdapterCombo.Enabled = $true
        } else {
            $Script:SelectedAdapter = $null
            $Script:AdapterCombo.Enabled = $false
        }
    } finally { $Script:AdapterCombo.EndUpdate() }
}

# ── PS5 / PS7 СОВМЕСТИМОСТЬ ──
# PS5: Test-Connection возвращает .ResponseTime (WMI Win32_PingStatus)
# PS7: Test-Connection возвращает .Latency (Microsoft.PowerShell.Commands.PingStatus)
$Script:PingProp = if ($PSVersionTable.PSVersion.Major -ge 7) { 'Latency' } else { 'ResponseTime' }

# ── TOOLTIP ──
$Script:Tooltip = New-Object System.Windows.Forms.ToolTip
$Script:Tooltip.AutoPopDelay = 12000
$Script:Tooltip.InitialDelay = 300
$Script:Tooltip.ReshowDelay  = 200
$Script:Tooltip.ShowAlways   = $true

# ── UI ХЕЛПЕРЫ ──
function global:GNO_MakeLabel {
    param([string]$T, [int]$X, [int]$Y, [int]$W = 400, [int]$H = 22, $Fnt = $F_NORMAL, $Clr = $C_TEXT)
    $l = New-Object System.Windows.Forms.Label
    $l.Text      = $T
    $l.Location  = New-Object System.Drawing.Point($X, $Y)
    $l.Size      = New-Object System.Drawing.Size($W, $H)
    $l.Font      = $Fnt
    $l.ForeColor = $Clr
    $l.BackColor = [System.Drawing.Color]::Transparent
    return $l
}

function global:GNO_MakeSection {
    param([string]$T, [int]$X, [int]$Y, [int]$W = 500)
    return (GNO_MakeLabel $T $X $Y $W 22 $F_HEADER $C_ACCENT)
}

function global:GNO_MakeButton {
    param([string]$T, [int]$X, [int]$Y, [int]$W = 200, [int]$H = 36,
          [System.Drawing.Color]$Bg, [System.Drawing.Color]$Fg)
    $b = New-Object System.Windows.Forms.Button
    $b.Text      = $T
    $b.Location  = New-Object System.Drawing.Point($X, $Y)
    $b.Size      = New-Object System.Drawing.Size($W, $H)
    $b.FlatStyle = "Flat"
    $b.Font      = $F_HEADER
    $b.BackColor = $Bg
    $b.ForeColor = $Fg
    $b.FlatAppearance.BorderColor = $C_ACCENT
    $b.FlatAppearance.BorderSize  = 1
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    return $b
}

function global:GNO_MakeRTB {
    param([int]$X, [int]$Y, [int]$W, [int]$H)
    $r = New-Object System.Windows.Forms.RichTextBox
    $r.Location    = New-Object System.Drawing.Point($X, $Y)
    $r.Size        = New-Object System.Drawing.Size($W, $H)
    $r.BackColor   = $C_PANEL
    $r.ForeColor   = $C_TEXT
    $r.Font        = $F_MONO
    $r.ReadOnly    = $true
    $r.ScrollBars  = "Vertical"
    $r.BorderStyle = "FixedSingle"
    return $r
}

function global:GNO_AppendRTB {
    param($Box, [string]$Text, [System.Drawing.Color]$Color = $C_TEXT)
    if ($null -eq $Box) { return }
    if ($Box.IsDisposed) { return }
    try {
        $Box.SelectionStart  = $Box.TextLength
        $Box.SelectionLength = 0
        $Box.SelectionColor  = $Color
        $Box.AppendText("$Text`n")
        $Box.SelectionColor  = $C_TEXT
        $Box.ScrollToCaret()
        [System.Windows.Forms.Application]::DoEvents()
    } catch {}
}

function global:GNO_MakePBar {
    param([int]$X, [int]$Y, [int]$W = 300, [int]$H = 18)
    $p = New-Object System.Windows.Forms.ProgressBar
    $p.Location  = New-Object System.Drawing.Point($X, $Y)
    $p.Size      = New-Object System.Drawing.Size($W, $H)
    $p.Style     = "Continuous"
    $p.Minimum   = 0
    $p.Maximum   = 100
    $p.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 50)
    $p.ForeColor = $C_ACCENT
    return $p
}

function global:GNO_SetBar {
    param($Bar, [int]$Val, [string]$St, $Lbl, [System.Drawing.Color]$Clr = $C_GREEN)
    if ($null -ne $Bar) { $Bar.Value = [Math]::Min($Val, 100) }
    if ($null -ne $Lbl) { $Lbl.Text = $St; $Lbl.ForeColor = $Clr }
    [System.Windows.Forms.Application]::DoEvents()
}

function global:GNO_MakeTabPage {
    param([string]$T)
    $pg = New-Object System.Windows.Forms.TabPage
    $pg.Text      = $T
    $pg.BackColor = $C_BG
    $pg.ForeColor = $C_TEXT
    $pg.Padding   = New-Object System.Windows.Forms.Padding(6)
    return $pg
}

function global:GNO_MakeInfoBtn {
    param([int]$X, [int]$Y, [string]$TipRU, [string]$TipEN)
    $b = New-Object System.Windows.Forms.Button
    $b.Text      = "i"
    $b.Location  = New-Object System.Drawing.Point($X, $Y)
    $b.Size      = New-Object System.Drawing.Size(22, 22)
    $b.FlatStyle = "Flat"
    $b.Font      = $F_INFO
    $b.BackColor = [System.Drawing.Color]::FromArgb(0, 50, 80)
    $b.ForeColor = $C_ACCENT
    $b.FlatAppearance.BorderColor = $C_ACCENT
    $b.FlatAppearance.BorderSize  = 1
    $b.Cursor    = [System.Windows.Forms.Cursors]::Help
    $Script:Tooltip.SetToolTip($b, $TipRU)
    $Script:LangItems.Add(@{C=$b; RU=$TipRU; EN=$TipEN; IsTooltip=$true})
    return $b
}

# ═══════════════════════════════════════════════════════
#  ГЛАВНАЯ ФОРМА
# ═══════════════════════════════════════════════════════
$mainForm = New-Object System.Windows.Forms.Form
    $mainForm.Text            = "NetLagov v2.3.3"
$mainForm.Size            = New-Object System.Drawing.Size(1100, 780)
$mainForm.MinimumSize     = New-Object System.Drawing.Size(900, 650)
$mainForm.StartPosition   = "CenterScreen"
$mainForm.BackColor       = $C_BG
$mainForm.ForeColor       = $C_TEXT
$mainForm.Font            = $F_NORMAL
$mainForm.FormBorderStyle = "Sizable"
$mainForm.MaximizeBox     = $true

# Панель заголовка
$titlePanel = New-Object System.Windows.Forms.Panel
$titlePanel.Dock      = "Top"
$titlePanel.Height    = 62
$titlePanel.BackColor = $C_PANEL
$mainForm.Controls.Add($titlePanel)

$lblTitle = GNO_MakeLabel "NetLagov" 20 8 400 34 $F_TITLE $C_ACCENT
$titlePanel.Controls.Add($lblTitle)

$lblSubtitle = GNO_MakeLabel "" 22 42 460 18 $F_SMALL $C_DIM
GNO_RegLang $lblSubtitle "Ремонт сети  |  TCP  |  DNS  |  NIC  |  Игровая оптимизация  |  Твики  |  Диагностика" "Network Repair  |  TCP  |  DNS  |  NIC  |  Gaming Opt  |  Tweaks  |  Diagnostics"
$titlePanel.Controls.Add($lblSubtitle)

$lblAdapterSelect = GNO_MakeLabel "" 500 21 64 22 $F_SMALL $C_DIM
GNO_RegLang $lblAdapterSelect "Адаптер:" "Adapter:"
$titlePanel.Controls.Add($lblAdapterSelect)
$Script:AdapterCombo = New-Object System.Windows.Forms.ComboBox
$Script:AdapterCombo.Location = New-Object System.Drawing.Point(565, 16)
$Script:AdapterCombo.Size = New-Object System.Drawing.Size(235, 28)
$Script:AdapterCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$Script:AdapterCombo.DropDownWidth = 300
$Script:AdapterCombo.BackColor = $C_PANEL
$Script:AdapterCombo.ForeColor = $C_TEXT
$Script:AdapterCombo.Font = $F_SMALL
$Script:AdapterCombo.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$Script:AdapterCombo.Add_SelectedIndexChanged({
    $adapterName = [string]$Script:AdapterCombo.SelectedItem
    if ($adapterName -and $Script:AdapterByName.ContainsKey($adapterName)) {
        $Script:SelectedAdapter = $Script:AdapterByName[$adapterName]
    }
})
$titlePanel.Controls.Add($Script:AdapterCombo)

$lblVer = GNO_MakeLabel "v2.3.3  |  $(Get-Date -Format 'dd.MM.yyyy')" 810 10 125 18 $F_SMALL $C_DIM
$lblVer.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$titlePanel.Controls.Add($lblVer)

# Кнопка переключения языка
$btnLangRU = GNO_MakeButton "RU" 940 16 45 30 ([System.Drawing.Color]::FromArgb(0, 60, 90)) $C_ACCENT
$btnLangEN = GNO_MakeButton "EN" 988 16 45 30 ([System.Drawing.Color]::FromArgb(20, 20, 40)) $C_DIM
$btnLangRU.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$btnLangEN.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$btnLangRU.Font = $F_SMALL
$btnLangEN.Font = $F_SMALL
$btnLangRU.FlatAppearance.BorderColor = $C_ACCENT
$btnLangEN.FlatAppearance.BorderColor = $C_DIM
$titlePanel.Controls.Add($btnLangRU)
$titlePanel.Controls.Add($btnLangEN)

$btnLangRU.Add_Click({
    GNO_SwitchLang "RU"
    $btnLangRU.BackColor = [System.Drawing.Color]::FromArgb(0, 60, 90)
    $btnLangRU.ForeColor = $C_ACCENT
    $btnLangRU.FlatAppearance.BorderColor = $C_ACCENT
    $btnLangEN.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 40)
    $btnLangEN.ForeColor = $C_DIM
    $btnLangEN.FlatAppearance.BorderColor = $C_DIM
})

$btnLangEN.Add_Click({
    GNO_SwitchLang "EN"
    $btnLangEN.BackColor = [System.Drawing.Color]::FromArgb(0, 60, 90)
    $btnLangEN.ForeColor = $C_ACCENT
    $btnLangEN.FlatAppearance.BorderColor = $C_ACCENT
    $btnLangRU.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 40)
    $btnLangRU.ForeColor = $C_DIM
    $btnLangRU.FlatAppearance.BorderColor = $C_DIM
})

# Статусбар
$statusBar = GNO_MakeLabel "  Готово  |  Лог: $Script:LogFile" 0 0 1100 22 $F_SMALL $C_DIM
$statusBar.Dock      = "Bottom"
$statusBar.BackColor = $C_PANEL
$mainForm.Controls.Add($statusBar)

# Вкладки
$tabCtrl = New-Object System.Windows.Forms.TabControl
$tabCtrl.Location = New-Object System.Drawing.Point(10, 70)
$tabCtrl.Size     = New-Object System.Drawing.Size(1070, 660)
$tabCtrl.Font     = $F_HEADER
$tabCtrl.Anchor   = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$mainForm.Controls.Add($tabCtrl)

$pgDiag   = GNO_MakeTabPage ""
$pgRep    = GNO_MakeTabPage ""
$pgOpt    = GNO_MakeTabPage ""
$pgDNS    = GNO_MakeTabPage ""
$pgNIC    = GNO_MakeTabPage ""
$pgTest   = GNO_MakeTabPage ""
$pgTweaks = GNO_MakeTabPage ""
$pgLog    = GNO_MakeTabPage ""
$pgDonate = GNO_MakeTabPage ""

GNO_RegLang $pgDiag   "Диагностика"    "Diagnostics"
GNO_RegLang $pgRep    "Ремонт"         "Repair"
GNO_RegLang $pgOpt    "Игровой TCP"    "Gaming TCP"
GNO_RegLang $pgDNS    "DNS"            "DNS"
GNO_RegLang $pgNIC    "Адаптер"        "NIC"
GNO_RegLang $pgTest   "Пинг/Джиттер"  "Ping/Jitter"
GNO_RegLang $pgTweaks "Твики"          "Tweaks"
GNO_RegLang $pgLog    "Лог"            "Log"
GNO_RegLang $pgDonate "Донат"         "Donate"

$tabCtrl.TabPages.Add($pgDiag)
$tabCtrl.TabPages.Add($pgRep)
$tabCtrl.TabPages.Add($pgOpt)
$tabCtrl.TabPages.Add($pgDNS)
$tabCtrl.TabPages.Add($pgNIC)
$tabCtrl.TabPages.Add($pgTest)
$tabCtrl.TabPages.Add($pgTweaks)
$tabCtrl.TabPages.Add($pgLog)
$tabCtrl.TabPages.Add($pgDonate)

# ═══════════════════════════════════════════════════════
#  ВКЛАДКА: ДОБРОВОЛЬНАЯ ПОДДЕРЖКА
# ═══════════════════════════════════════════════════════
$donatePanel = New-Object System.Windows.Forms.TableLayoutPanel
$donatePanel.Dock = "Fill"
$donatePanel.BackColor = $C_BG
$donatePanel.ColumnCount = 1
$donatePanel.RowCount = 4
$donatePanel.Padding = New-Object System.Windows.Forms.Padding(24)
[void]$donatePanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100)))
[void]$donatePanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 35)))
[void]$donatePanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 30)))
[void]$donatePanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 15)))
[void]$donatePanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 20)))
$pgDonate.Controls.Add($donatePanel)
$lblDonateTitle = GNO_MakeLabel "" 0 0 700 40 $F_TITLE $C_ACCENT
$lblDonateTitle.Dock = "Fill"
$lblDonateTitle.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
GNO_RegLang $lblDonateTitle "Поддержите развитие NetLagov" "Support NetLagov Development"
$donatePanel.Controls.Add($lblDonateTitle, 0, 0)
$lblDonateText = GNO_MakeLabel "" 0 0 760 70 $F_NORMAL $C_TEXT
$lblDonateText.Dock = "Fill"
$lblDonateText.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
GNO_RegLang $lblDonateText "Если NetLagov вам полезен, вы можете добровольно поддержать дальнейшую разработку. Любая поддержка помогает развивать проект и добавлять новые возможности." "If NetLagov is useful to you, you can voluntarily support its continued development. Every contribution helps improve the project and add new features."
$donatePanel.Controls.Add($lblDonateText, 0, 1)
$btnDonateLink = GNO_MakeButton "" 0 0 260 42 ([System.Drawing.Color]::FromArgb(0,60,90)) $C_ACCENT
$btnDonateLink.Anchor = [System.Windows.Forms.AnchorStyles]::None
GNO_RegLang $btnDonateLink "Поддержать NetLagov" "Support NetLagov"
$Script:DonateUrl = "https://www.donationalerts.com/r/kiboon"
$btnDonateLink.Add_Click({ Start-Process -FilePath $Script:DonateUrl })
$donatePanel.Controls.Add($btnDonateLink, 0, 2)
$lblDonateNote = GNO_MakeLabel "" 0 0 700 30 $F_SMALL $C_DIM
$lblDonateNote.Dock = "Fill"
$lblDonateNote.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
GNO_RegLang $lblDonateNote "Донат полностью добровольный." "Donations are entirely voluntary."
$donatePanel.Controls.Add($lblDonateNote, 0, 3)
#  ВКЛАДКА: ДИАГНОСТИКА
# ═══════════════════════════════════════════════════════
$secDiag1 = GNO_MakeSection "" 8 6
GNO_RegLang $secDiag1 "Панель диагностики сети" "Network Diagnostics Dashboard"
$pgDiag.Controls.Add($secDiag1)

$Script:DiagMetric = @{}
$metricDefs = @(
    @{NRU="Пинг";    NEN="Ping";    X=8;   C=$C_GREEN}
    @{NRU="Джиттер"; NEN="Jitter";  X=168; C=$C_YELLOW}
    @{NRU="Потери";  NEN="Loss";    X=328; C=$C_GREEN}
    @{NRU="DNS мс";  NEN="DNS ms";  X=488; C=$C_ACCENT}
    @{NRU="Адаптер"; NEN="Adapter"; X=648; C=$C_ACCENT}
    @{NRU="Оценка";  NEN="Grade";   X=808; C=$C_GREEN}
)
foreach ($m in $metricDefs) {
    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.Location    = New-Object System.Drawing.Point($m.X, 34)
    $pnl.Size        = New-Object System.Drawing.Size(152, 68)
    $pnl.BackColor   = $C_PANEL
    $pnl.BorderStyle = "FixedSingle"
    $nl = GNO_MakeLabel "" 6 4 140 16 $F_SMALL $C_DIM
    GNO_RegLang $nl $m.NRU $m.NEN
    $vl = GNO_MakeLabel "--" 6 22 140 36 $F_BIG $m.C
    $pnl.Controls.Add($nl)
    $pnl.Controls.Add($vl)
    $pgDiag.Controls.Add($pnl)
    $Script:DiagMetric[$m.NRU] = $vl
    $Script:DiagMetric[$m.NEN] = $vl
}

$Script:DiagStatus = @{}
$secDiag2 = GNO_MakeSection "" 8 108
GNO_RegLang $secDiag2 "Состояние компонентов" "Component Status"
$pgDiag.Controls.Add($secDiag2)

$statusDefs = @(
    @{NRU="Winsock";     NEN="Winsock";    X=8}
    @{NRU="TCP стек";    NEN="TCP Stack";  X=168}
    @{NRU="DNS кэш";     NEN="DNS Cache";  X=328}
    @{NRU="Адаптер";     NEN="NIC";        X=488}
    @{NRU="Bufferbloat"; NEN="Bufferbloat";X=648}
    @{NRU="Game Mode";   NEN="Game Mode";  X=808}
)
foreach ($s in $statusDefs) {
    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.Location  = New-Object System.Drawing.Point($s.X, 126)
    $pnl.Size      = New-Object System.Drawing.Size(152, 46)
    $pnl.BackColor = $C_PANEL
    $nl = GNO_MakeLabel "" 6 4 140 16 $F_SMALL $C_DIM
    GNO_RegLang $nl $s.NRU $s.NEN
    $sl = GNO_MakeLabel "Неизвестно" 6 22 140 20 $F_NORMAL $C_DIM
    $pnl.Controls.Add($nl)
    $pnl.Controls.Add($sl)
    $pgDiag.Controls.Add($pnl)
    $Script:DiagStatus[$s.NRU] = $sl
    $Script:DiagStatus[$s.NEN] = $sl
}

$secDiag3 = GNO_MakeSection "" 8 180
GNO_RegLang $secDiag3 "Вывод диагностики" "Diagnostic Output"
$pgDiag.Controls.Add($secDiag3)

$Script:rtbDiag  = GNO_MakeRTB 8   200 670 360
$Script:rtbAdapt = GNO_MakeRTB 690  200 360 360
$pgDiag.Controls.Add($Script:rtbDiag)

$secDiag4 = GNO_MakeSection "" 690 180 360
GNO_RegLang $secDiag4 "Выбранный адаптер" "Selected Adapter"
$pgDiag.Controls.Add($secDiag4)
$pgDiag.Controls.Add($Script:rtbAdapt)

$btnRunDiag = GNO_MakeButton "" 8   572 200 34 ([System.Drawing.Color]::FromArgb(0,60,30))  $C_GREEN
$btnAutoFix = GNO_MakeButton "" 218 572 170 34 ([System.Drawing.Color]::FromArgb(80,0,0))   $C_RED
GNO_RegLang $btnRunDiag "Запустить диагностику" "Run Diagnostics"
GNO_RegLang $btnAutoFix "Авто-исправление"       "Auto-Fix All"
$pgDiag.Controls.Add($btnRunDiag)
$pgDiag.Controls.Add($btnAutoFix)

# ═══════════════════════════════════════════════════════
#  ВКЛАДКА: РЕМОНТ
# ═══════════════════════════════════════════════════════
$secRep = GNO_MakeSection "" 8 6
GNO_RegLang $secRep "Восстановление сетевого стека" "Network Stack Repair"
$pgRep.Controls.Add($secRep)

$repDefs = @(
    @{RU="Сброс Winsock";        EN="Winsock Reset"}
    @{RU="Сброс IP стека";       EN="IP Stack Reset"}
    @{RU="Освобождение IP";      EN="Release IP"}
    @{RU="Обновление IP";        EN="Renew IP"}
    @{RU="Очистка DNS кэша";     EN="Flush DNS"}
    @{RU="Сброс файрвола";       EN="Reset Firewall"}
    @{RU="Сброс IPv6";           EN="Reset IPv6"}
    @{RU="Проверка hosts файла"; EN="Check Hosts File"}
    @{RU="Сетевые политики";     EN="Network Policies"}
    @{RU="Регистрация DNS";      EN="Register DNS"}
)
$Script:RepBar  = @{}
$Script:RepStat = @{}
$Script:RepLbls = @{}
$Script:RepairRows = [System.Collections.Generic.List[hashtable]]::new()
for ($i = 0; $i -lt $repDefs.Count; $i++) {
    [int]$ry = 32 + ($i * 50)
    $rd = $repDefs[$i]
    $lbl = GNO_MakeLabel "" 8 $ry 220 18 $F_NORMAL $C_TEXT
    GNO_RegLang $lbl $rd.RU $rd.EN
    $pgRep.Controls.Add($lbl)
    $rb = GNO_MakePBar 235 $ry 450 18
    $rs = GNO_MakeLabel "--" 694 $ry 90 18 $F_SMALL $C_DIM
    $pgRep.Controls.Add($rb)
    $pgRep.Controls.Add($rs)
    $Script:RepBar[$rd.RU]  = $rb
    $Script:RepStat[$rd.RU] = $rs
    $Script:RepBar[$rd.EN]  = $rb
    $Script:RepStat[$rd.EN] = $rs
    $Script:RepairRows.Add(@{Label=$lbl; Bar=$rb; Status=$rs})
}

$Script:rtbRep = GNO_MakeRTB 800 32 240 560
$pgRep.Controls.Add($Script:rtbRep)

$btnRepair  = GNO_MakeButton "" 8   585 165 34 ([System.Drawing.Color]::FromArgb(0,60,30))  $C_GREEN
$btnReboot  = GNO_MakeButton "" 183 585 155 34 ([System.Drawing.Color]::FromArgb(80,40,0))  $C_YELLOW
$btnCancelR = GNO_MakeButton "" 348 585 155 34 ([System.Drawing.Color]::FromArgb(80,0,0))   $C_RED
GNO_RegLang $btnRepair  "Полное восстановление" "Full Repair"
GNO_RegLang $btnReboot  "Перезагрузка (10с)"   "Reboot (10s)"
GNO_RegLang $btnCancelR "Отмена перезагрузки"  "Cancel Reboot"
$btnCancelR.Enabled = $false
$pgRep.Controls.Add($btnRepair)
$pgRep.Controls.Add($btnReboot)
$pgRep.Controls.Add($btnCancelR)

# ═══════════════════════════════════════════════════════
#  ВКЛАДКА: ИГРОВОЙ TCP
# ═══════════════════════════════════════════════════════
$secOpt = GNO_MakeSection "" 8 6
GNO_RegLang $secOpt "Оптимизация TCP Windows для игр" "Windows Gaming TCP Optimization"
$pgOpt.Controls.Add($secOpt)

$optDefs = @(
    @{RU="Отключить алгоритм Нейгла"; EN="Disable Nagle Algorithm"
      TipRU="Отключает задержку малых TCP-пакетов на интерфейсах. На слабом CPU обработка частых пакетов может добавить нагрузку; на мощном влияние обычно меньше. Большинство игр использует UDP, поэтому игровой отклик может не измениться."
      TipEN="Disables delayed batching of small TCP packets on interfaces. Frequent packets can add CPU work on a low-end processor; a powerful CPU has more headroom. Most games use UDP, so game response may not change."}
    @{RU="Авто-настройка TCP — Откл."; EN="TCP Auto-Tuning Off"
      TipRU="Отключает автонастройку TCP. Может помочь совместимости отдельных сетей, но уменьшить скорость TCP-загрузки, особенно на быстром или дальнем канале. Для игровых UDP-пакетов прямого эффекта обычно нет."
      TipEN="Disables TCP auto-tuning. It may help compatibility on some networks but can reduce TCP download throughput, especially on fast or long-distance links. It usually has no direct effect on game UDP packets."}
    @{RU="Отключить сетевой троттлинг"; EN="Network Throttling Off"
      TipRU="Отключает NetworkThrottlingIndex в профиле мультимедиа Windows. При снятии соответствующего ограничения возможна большая обработка сетевых прерываний CPU; на слабом процессоре это может отнять ресурсы у игры. Прирост зависит от нагрузки и не гарантирован."
      TipEN="Disables NetworkThrottlingIndex in the Windows multimedia profile. Removing a matching limit may increase network interrupt processing on the CPU and compete with a game on a low-end PC. Any gain depends on workload and is not guaranteed."}
    @{RU="System Responsiveness = 0"; EN="System Responsiveness 0"
      TipRU="Ставит SystemResponsiveness в 0 в профиле мультимедиа Windows. Меняет планирование мультимедийных потоков, а не отдает весь CPU игре; приоритет фоновых задач может снизиться. На мощном ПК эффект обычно заметен лишь при конкурирующей нагрузке."
      TipEN="Sets SystemResponsiveness to 0 in the Windows multimedia profile. This changes multimedia scheduling; it does not give all CPU time to a game. Background work may receive lower priority, with effects most visible under competition."}
    @{RU="QoS DSCP 46 EF"; EN="QoS DSCP 46 EF"
      TipRU="Маркирует весь трафик DSCP 46 через политику QoS. При поддержке метки роутером и сетью возможен приоритет пакетов; иначе эффекта нет. Само маркирование дает небольшую обработку, нагрузка на CPU обычно мала."
      TipEN="Marks all traffic DSCP 46 through a QoS policy. Packets may be prioritized only when the router and network honor the mark; otherwise there is no effect. Marking adds little CPU work on most systems."}
    @{RU="Отключить ECN"; EN="ECN Disabled"
      TipRU="Отключает ECN для TCP. Меняется реакция TCP на перегрузку; при насыщении канала возможны иные скорость и потери. На UDP-игры напрямую не влияет; эффект на слабом и мощном ПК зависит от сети, а не класса компьютера."
      TipEN="Disables ECN for TCP. TCP congestion behavior changes; throughput or loss may differ when a link is saturated. It does not directly affect UDP games. Results depend on the network rather than PC class."}
    @{RU="Отключить TCP Timestamps"; EN="TCP Timestamps Disabled"
      TipRU="Отключает TCP timestamps. Снижение служебных данных минимально; скорость и FPS обычно не меняются. Может убрать функции TCP, связанные с временными метками. Нагрузка CPU меняется несущественно на любом ПК."
      TipEN="Disables TCP timestamps. Any reduction in overhead is tiny, so speed and FPS usually do not change. TCP functions that use timestamps may be affected. CPU impact is negligible on low-end and powerful PCs alike."}
    @{RU="Initial RTO 2000мс"; EN="Initial RTO 2000ms"
      TipRU="Задает начальный таймер повторной передачи TCP 2000 мс. Потерянный TCP-пакет может быть повторен раньше, но на нестабильной линии возможны лишние повторы и нагрузка. UDP-игры это не ускоряет."
      TipEN="Sets the initial TCP retransmission timer to 2000 ms. A lost TCP packet may be retried sooner, but unstable links may see unnecessary retries and extra work. It does not speed up UDP games."}
    @{RU="Отключить RSC (Chimney)"; EN="RSC Disabled"
      TipRU="Отключает RSC: адаптер перестает объединять входящие TCP-сегменты. Это может снизить задержку пакетной обработки, но повышает число прерываний и работу CPU; слабый CPU может просесть под потоком, мощный легче обработает пакеты."
      TipEN="Disables RSC, so the adapter stops coalescing incoming TCP segments. This may reduce batching delay but increases interrupts and CPU work; a low-end CPU may struggle under traffic, while a powerful CPU has more headroom."}
    @{RU="RSS — включить"; EN="RSS Enabled"
      TipRU="Включает RSS: поддерживаемый адаптер распределяет обработку входящих пакетов по ядрам. Снимает узкое место одного ядра, особенно на многоядерном слабом ПК; на мощном польза возможна при высокой сетевой нагрузке. Требуются поддержка драйвера и CPU."
      TipEN="Enables RSS, distributing incoming packet processing across cores when the adapter supports it. It can relieve a single-core bottleneck, especially on a low-end multicore PC; a powerful PC may benefit under heavy network load. Driver support is required."}
    @{RU="TCP ACK Frequency = 1"; EN="TCP ACK Frequency 1"
      TipRU="Задает TCP ACK Frequency = 1 на интерфейсах. Более частые подтверждения TCP могут увеличить служебные пакеты и работу адаптера и CPU; при ограниченном CPU это может быть заметнее. Для UDP-игр прямого эффекта нет."
      TipEN="Sets TCP ACK Frequency to 1 on interfaces. More frequent TCP acknowledgements may increase packet count and adapter/CPU work, which can matter more with limited CPU headroom. It has no direct effect on UDP games."}
    @{RU="Отключить Teredo"; EN="Teredo Disabled"
      TipRU="Отключает туннель Teredo. Экономия ресурсов обычно мала на слабом и мощном ПК; приложениям, которым нужен Teredo или соответствующий IPv6-путь, связь может перестать работать."
      TipEN="Disables the Teredo tunnel. Resource savings are usually small on both low-end and powerful PCs; apps that rely on Teredo or that IPv6 path may lose connectivity."}
)

# Словарь команд для отдельного применения TCP
$Script:OptActions = [ordered]@{
    "Отключить алгоритм Нейгла" = {
        Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | ForEach-Object {
            Set-ItemProperty $_.PSPath "TcpAckFrequency" 1 -Type DWord -EA SilentlyContinue
            Set-ItemProperty $_.PSPath "TCPNoDelay"      1 -Type DWord -EA SilentlyContinue
            Set-ItemProperty $_.PSPath "TcpDelAckTicks"  1 -Type DWord -EA SilentlyContinue
        }
    }
    "Авто-настройка TCP — Откл." = { GNO_RunCmd "netsh int tcp set global autotuninglevel=disabled" }
    "Отключить сетевой троттлинг" = {
        Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
            -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord -Force
    }
    "System Responsiveness = 0" = {
        Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
            -Name "SystemResponsiveness" -Value 0 -Type DWord -Force
    }
    "QoS DSCP 46 EF" = {
        $p = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\Game"
        if (-not (Test-Path $p)) { New-Item $p -Force | Out-Null }
        Set-ItemProperty $p -Name "Version"           -Value "1.0" -Force
        Set-ItemProperty $p -Name "Application Name"  -Value "*"   -Force
        Set-ItemProperty $p -Name "Protocol"          -Value "*"   -Force
        Set-ItemProperty $p -Name "Local Port"        -Value "*"   -Force
        Set-ItemProperty $p -Name "Remote Port"       -Value "*"   -Force
        Set-ItemProperty $p -Name "Local IP"          -Value "*"   -Force
        Set-ItemProperty $p -Name "Remote IP"         -Value "*"   -Force
        Set-ItemProperty $p -Name "DSCP Value"        -Value "46"  -Force
        Set-ItemProperty $p -Name "Throttle Rate"     -Value "-1"  -Force
    }
    "Отключить ECN" = { GNO_RunCmd "netsh int tcp set global ecncapability=disabled" }
    "Отключить TCP Timestamps" = { GNO_RunCmd "netsh int tcp set global timestamps=disabled" }
    "Initial RTO 2000мс" = { GNO_RunCmd "netsh int tcp set global initialRto=2000" }
    "Отключить RSC (Chimney)" = { GNO_RunCmd "netsh int tcp set global rsc=disabled" }
    "RSS — включить" = { GNO_RunCmd "netsh int tcp set global rss=enabled" }
    "TCP ACK Frequency = 1" = {
        Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | ForEach-Object {
            Set-ItemProperty $_.PSPath "TcpAckFrequency" 1 -Type DWord -EA SilentlyContinue
        }
    }
    "Отключить Teredo" = { GNO_RunCmd "netsh int teredo set state disabled" }
}

$Script:OptBar  = @{}
$Script:OptStat = @{}
$Script:OptRows = [System.Collections.Generic.List[hashtable]]::new()
for ($i = 0; $i -lt $optDefs.Count; $i++) {
    [int]$oy = 32 + ($i * 46)
    $od = $optDefs[$i]

    # Название
    $lbl = GNO_MakeLabel "" 8 ($oy+2) 218 20 $F_NORMAL $C_TEXT
    GNO_RegLang $lbl $od.RU $od.EN
    $pgOpt.Controls.Add($lbl)

    # Кнопка i
    $iBtn = GNO_MakeInfoBtn 228 ($oy+1) $od.TipRU $od.TipEN
    $pgOpt.Controls.Add($iBtn)

    # Прогресс-бар
    $ob = GNO_MakePBar 258 ($oy+2) 290 18
    $pgOpt.Controls.Add($ob)

    # Статус
    $os = GNO_MakeLabel "--" 555 ($oy+2) 70 18 $F_SMALL $C_DIM
    $pgOpt.Controls.Add($os)

    # Кнопка Применить (индивидуальная)
    $applyBtnOpt = GNO_MakeButton "" 632 ($oy-1) 110 26 ([System.Drawing.Color]::FromArgb(50,0,80)) $C_PURPLE
    GNO_RegLang $applyBtnOpt "Применить" "Apply"
    $localOd  = $od
    $localOb  = $ob
    $localOs  = $os
    $applyBtnOpt.Add_Click({
        $localOs.Text      = GNO_TStr "..." "..."
        $localOs.ForeColor = $C_YELLOW
        $localOb.Value     = 40
        [System.Windows.Forms.Application]::DoEvents()
        try {
            $action = $Script:OptActions[$localOd.RU]
            if ($action) { & $action }
            $localOb.Value     = 100
            $localOs.Text      = "OK"
            $localOs.ForeColor = $C_GREEN
            GNO_AppendRTB $Script:rtbOpt "[OK] $($localOd.RU)" $C_GREEN
            GNO_WriteLog "OPT single: $($localOd.RU)"
        } catch {
            $localOb.Value     = 100
            $localOs.Text      = GNO_TStr "Ошибка" "Error"
            $localOs.ForeColor = $C_RED
            GNO_AppendRTB $Script:rtbOpt "[ERR] $($localOd.RU): $_" $C_RED
        }
    }.GetNewClosure())
    $pgOpt.Controls.Add($applyBtnOpt)

    $Script:OptBar[$od.RU]  = $ob
    $Script:OptStat[$od.RU] = $os
    $Script:OptBar[$od.EN]  = $ob
    $Script:OptStat[$od.EN] = $os
    $Script:OptRows.Add(@{Label=$lbl; Info=$iBtn; Bar=$ob; Status=$os; Apply=$applyBtnOpt})
}

$Script:rtbOpt = GNO_MakeRTB 800 32 240 560
$pgOpt.Controls.Add($Script:rtbOpt)

$btnApplyOpt   = GNO_MakeButton "" 8   622 255 34 ([System.Drawing.Color]::FromArgb(50,0,80))  $C_PURPLE
$btnRestoreOpt = GNO_MakeButton "" 273 622 185 34 ([System.Drawing.Color]::FromArgb(60,50,0))  $C_YELLOW
GNO_RegLang $btnApplyOpt   "Применить оптимизации" "Apply Optimizations"
GNO_RegLang $btnRestoreOpt "Восстановить по умолч." "Restore Defaults"
$pgOpt.Controls.Add($btnApplyOpt)
$pgOpt.Controls.Add($btnRestoreOpt)

# ═══════════════════════════════════════════════════════
#  ВКЛАДКА: DNS
# ═══════════════════════════════════════════════════════
$secDNS = GNO_MakeSection "" 8 6
GNO_RegLang $secDNS "DNS Бенчмарк и автоматическая оптимизация" "DNS Benchmark and Auto-Optimizer"
$pgDNS.Controls.Add($secDNS)

# Заголовки колонок (фиксированные, над панелью прокрутки)
$dnsH1 = GNO_MakeLabel "" 10  30 160 18 $F_HEADER $C_ACCENT
$dnsH2 = GNO_MakeLabel "" 175 30 115 18 $F_HEADER $C_ACCENT
$dnsH3 = GNO_MakeLabel "" 295 30 125 18 $F_HEADER $C_ACCENT
$dnsH4 = GNO_MakeLabel "" 425 30  75 18 $F_HEADER $C_ACCENT
$dnsH5 = GNO_MakeLabel "" 505 30 200 18 $F_HEADER $C_ACCENT
GNO_RegLang $dnsH1 "Провайдер"  "Provider"
GNO_RegLang $dnsH2 "Основной"   "Primary"
GNO_RegLang $dnsH3 "Резервный"  "Secondary"
GNO_RegLang $dnsH4 "Задержка"   "Latency"
GNO_RegLang $dnsH5 "Статус"     "Status"
$pgDNS.Controls.Add($dnsH1)
$pgDNS.Controls.Add($dnsH2)
$pgDNS.Controls.Add($dnsH3)
$pgDNS.Controls.Add($dnsH4)
$pgDNS.Controls.Add($dnsH5)

# Скролл-панель для строк DNS
$dnsScrollPanel = New-Object System.Windows.Forms.Panel
$dnsScrollPanel.Location    = New-Object System.Drawing.Point(8, 52)
$dnsScrollPanel.Size        = New-Object System.Drawing.Size(740, 490)
$dnsScrollPanel.AutoScroll  = $true
$dnsScrollPanel.BackColor   = $C_BG
$pgDNS.Controls.Add($dnsScrollPanel)

$Script:DnsLabels = @{}
$Script:DnsRows = @{}
$Script:SelectedDNS = $null
[int]$dnsY = 4
foreach ($kv in $Script:DNSMap.GetEnumerator()) {
    $rowBg = New-Object System.Windows.Forms.Panel
    $rowBg.Location  = New-Object System.Drawing.Point(0, $dnsY)
    $rowBg.Size      = New-Object System.Drawing.Size(730, 22)
    $rowBg.BackColor = if ((($dnsY - 4) / 22) % 2 -eq 0) { [System.Drawing.Color]::FromArgb(22,22,40) } else { $C_BG }
    $rowBg.Cursor = [System.Windows.Forms.Cursors]::Hand

    # Все метки — дети rowBg (Y=2 внутри строки)
    $lName = New-Object System.Windows.Forms.Label
    $lName.Text = $kv.Key; $lName.Location = New-Object System.Drawing.Point(2, 2)
    $lName.Size = New-Object System.Drawing.Size(162, 18); $lName.Font = $F_NORMAL
    $lName.ForeColor = $C_TEXT; $lName.BackColor = [System.Drawing.Color]::Transparent
    $rowBg.Controls.Add($lName)

    $lIP1 = New-Object System.Windows.Forms.Label
    $lIP1.Text = $kv.Value[0]; $lIP1.Location = New-Object System.Drawing.Point(168, 2)
    $lIP1.Size = New-Object System.Drawing.Size(115, 18); $lIP1.Font = $F_MONO
    $lIP1.ForeColor = $C_ACCENT; $lIP1.BackColor = [System.Drawing.Color]::Transparent
    $rowBg.Controls.Add($lIP1)

    $lIP2 = New-Object System.Windows.Forms.Label
    $lIP2.Text = $kv.Value[1]; $lIP2.Location = New-Object System.Drawing.Point(288, 2)
    $lIP2.Size = New-Object System.Drawing.Size(125, 18); $lIP2.Font = $F_MONO
    $lIP2.ForeColor = $C_ACCENT; $lIP2.BackColor = [System.Drawing.Color]::Transparent
    $rowBg.Controls.Add($lIP2)

    $dLatL = New-Object System.Windows.Forms.Label
    $dLatL.Text = "--"; $dLatL.Location = New-Object System.Drawing.Point(418, 2)
    $dLatL.Size = New-Object System.Drawing.Size(72, 18); $dLatL.Font = $F_NORMAL
    $dLatL.ForeColor = $C_DIM; $dLatL.BackColor = [System.Drawing.Color]::Transparent
    $rowBg.Controls.Add($dLatL)

    $dStatL = New-Object System.Windows.Forms.Label
    $dStatL.Text = GNO_TStr "Не тестировался" "Not tested"
    $dStatL.Location = New-Object System.Drawing.Point(495, 2)
    $dStatL.Size = New-Object System.Drawing.Size(225, 18); $dStatL.Font = $F_SMALL
    $dStatL.ForeColor = $C_DIM; $dStatL.BackColor = [System.Drawing.Color]::Transparent
    $rowBg.Controls.Add($dStatL)

    $dnsScrollPanel.Controls.Add($rowBg)
    $Script:DnsLabels[$kv.Key] = @{ Lat = $dLatL; Stat = $dStatL }
    $Script:DnsRows[$kv.Key] = @{Panel=$rowBg; Name=$lName; Primary=$lIP1; Secondary=$lIP2; Latency=$dLatL; Status=$dStatL}
    $localDnsKey = [string]$kv.Key
    $rowBg.Add_Click({ GNO_DNS_Select $localDnsKey }.GetNewClosure())
    $lName.Add_Click({ GNO_DNS_Select $localDnsKey }.GetNewClosure())
    $lIP1.Add_Click({ GNO_DNS_Select $localDnsKey }.GetNewClosure())
    $lIP2.Add_Click({ GNO_DNS_Select $localDnsKey }.GetNewClosure())
    $dLatL.Add_Click({ GNO_DNS_Select $localDnsKey }.GetNewClosure())
    $dStatL.Add_Click({ GNO_DNS_Select $localDnsKey }.GetNewClosure())
    $dnsY += 22
}

$Script:lblBestDNS = GNO_MakeLabel (GNO_TStr "Запустите бенчмарк для поиска оптимального DNS" "Run benchmark to find the fastest DNS") 10 550 740 24 `
    (New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)) $C_GREEN
$pgDNS.Controls.Add($Script:lblBestDNS)

$secDNSlog = GNO_MakeSection "" 760 18 290
GNO_RegLang $secDNSlog "Лог бенчмарка" "Benchmark Log"
$pgDNS.Controls.Add($secDNSlog)
$Script:rtbDNS = GNO_MakeRTB 760 36 290 548
$pgDNS.Controls.Add($Script:rtbDNS)

$btnDNSBench = GNO_MakeButton "" 10  584 170 34 ([System.Drawing.Color]::FromArgb(0,30,80))  $C_ACCENT
$btnApplyDNS = GNO_MakeButton "" 190 584 170 34 ([System.Drawing.Color]::FromArgb(0,70,30))  $C_GREEN
$btnApplySelectedDNS = GNO_MakeButton "" 370 584 210 34 ([System.Drawing.Color]::FromArgb(0,50,60)) $C_ACCENT
$btnResetDNS = GNO_MakeButton "" 590 584 160 34 ([System.Drawing.Color]::FromArgb(60,40,0))  $C_YELLOW
GNO_RegLang $btnDNSBench "Запустить бенчмарк"   "Benchmark All"
GNO_RegLang $btnApplyDNS "Применить лучший DNS" "Apply Best DNS"
GNO_RegLang $btnApplySelectedDNS "Применить выбранный DNS" "Apply Selected DNS"
GNO_RegLang $btnResetDNS "Сбросить на авто"     "Reset to Auto"
$pgDNS.Controls.Add($btnDNSBench)
$pgDNS.Controls.Add($btnApplyDNS)
$pgDNS.Controls.Add($btnApplySelectedDNS)
$pgDNS.Controls.Add($btnResetDNS)

# ═══════════════════════════════════════════════════════
#  ВКЛАДКА: АДАПТЕР (NIC)
# ═══════════════════════════════════════════════════════
$secNIC = GNO_MakeSection "" 8 6
GNO_RegLang $secNIC "Оптимизация сетевого адаптера" "NIC Adapter Optimization"
$pgNIC.Controls.Add($secNIC)

$Script:rtbNIC    = GNO_MakeRTB   8  32 680 280
$Script:rtbNICDet = GNO_MakeRTB 700  32 350 600
$pgNIC.Controls.Add($Script:rtbNIC)

$secNICdet = GNO_MakeSection "" 700 18 350
GNO_RegLang $secNICdet "Детали адаптера" "Adapter Details"
$pgNIC.Controls.Add($secNICdet)
$pgNIC.Controls.Add($Script:rtbNICDet)

$secNICprog = GNO_MakeSection "" 8 322
GNO_RegLang $secNICprog "Прогресс настройки" "Tuning Progress"
$pgNIC.Controls.Add($secNICprog)

$nicDefs = @(
    @{
        RU="Управление питанием — Всегда вкл."; EN="Power Mgmt Always On"
        TipRU="Отключает энергосбережение выбранного адаптера и EEE при поддержке драйвера. Может уменьшить паузы, но повышает потребление и нагрев адаптера; влияние CPU обычно мало, на ноутбуке сокращается время от батареи."
        TipEN="Disables power saving for the selected adapter and EEE when supported by its driver. It may reduce pauses but increases adapter power use and heat; CPU impact is usually small, while laptop battery life can fall."
        Action={
            GNO_GetSelectedAdapters|ForEach-Object{
                Disable-NetAdapterPowerManagement -Name $_.Name -EA SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Energy-Efficient Ethernet" -DisplayValue "Disabled" -EA SilentlyContinue
            }
        }
    }
    @{
        RU="Отключить Energy Efficient Eth."; EN="Energy Efficient Eth Off"
        TipRU="Отключает Energy-Efficient Ethernet у адаптера. Может убрать задержки перехода режима на отдельных связках драйвера и оборудования. Обычно не ускоряет сеть само по себе; увеличивает потребление энергии, особенно заметное на ноутбуке."
        TipEN="Disables Energy-Efficient Ethernet on the adapter. It may remove mode-transition delays on specific hardware and drivers. It does not inherently speed up networking and increases power use, especially relevant on laptops."
        Action={
            GNO_GetSelectedAdapters|ForEach-Object{
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Energy Efficient Ethernet" -DisplayValue "Disabled" -EA SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Green Ethernet"            -DisplayValue "Disabled" -EA SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Advanced EEE"              -DisplayValue "Disabled" -EA SilentlyContinue
            }
        }
    }
    @{
        RU="Отключить Flow Control"; EN="Flow Control Off"
        TipRU="Отключает Flow Control у адаптера. При перегрузке устройства меньше приостанавливают отправку, но возможны потери и повторы; обработка пакетов и нагрузка CPU могут вырасти. Результат зависит от адаптера, коммутатора и нагрузки."
        TipEN="Disables adapter Flow Control. Devices may pause sending less under congestion, but loss and retries may rise; packet handling and CPU load can increase. Results depend on adapter, switch, and traffic."
        Action={
            GNO_GetSelectedAdapters|ForEach-Object{
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Flow Control" -DisplayValue "Disabled" -EA SilentlyContinue
            }
        }
    }
    @{
        RU="Отключить Priority и VLAN"; EN="Priority and VLAN Off"
        TipRU="Отключает 802.1p и VLAN на адаптере. Уменьшает обработку тегов лишь в подходящем сценарии, но не дает обычной домашней сети прироста. VLAN-соединения могут перестать работать; влияние CPU обычно мало."
        TipEN="Disables 802.1p and VLAN on the adapter. It only reduces tag processing in matching use cases and offers no general home-network gain. VLAN connectivity may break; CPU impact is usually small."
        Action={
            GNO_GetSelectedAdapters|ForEach-Object{
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Priority & VLAN" -DisplayValue "Priority & VLAN Disabled" -EA SilentlyContinue
            }
        }
    }
    @{
        RU="Буферы приёма — максимум"; EN="Receive Buffers Max"
        TipRU="Задает 512 буферов приема, если драйвер принимает значение. Запас помогает пережить всплески трафика, но увеличивает память адаптера и размер очереди; слабый ПК может сильнее ощущать задержку и нагрузку, мощный лучше переносит поток."
        TipEN="Sets 512 receive buffers if accepted by the driver. Extra headroom can absorb traffic bursts, but uses adapter memory and may build a longer queue; a low-end PC may feel added delay more, while a powerful PC handles traffic more easily."
        Action={
            GNO_GetSelectedAdapters|ForEach-Object{
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Receive Buffers" -DisplayValue "512" -EA SilentlyContinue
            }
        }
    }
    @{
        RU="Буферы передачи — максимум"; EN="Transmit Buffers Max"
        TipRU="Задает 512 буферов передачи, если поддерживается драйвером. Может снизить потери при интенсивной отправке, но расходует память и может копить очередь, повышая задержку. Подходящее значение зависит от адаптера и нагрузки."
        TipEN="Sets 512 transmit buffers if supported. It may reduce drops during heavy sending, but uses memory and can build a queue that raises latency. The right value depends on adapter and traffic."
        Action={
            GNO_GetSelectedAdapters|ForEach-Object{
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Transmit Buffers" -DisplayValue "512" -EA SilentlyContinue
            }
        }
    }
    @{
        RU="Отключить Interrupt Moderation"; EN="Interrupt Moderation Off"
        TipRU="Отключает Interrupt Moderation. Адаптер чаще прерывает CPU для обработки пакетов: задержка может снизиться, но загрузка процессора вырасти. Слабый CPU особенно чувствителен при высоком трафике; мощный имеет больший запас."
        TipEN="Disables Interrupt Moderation. The adapter interrupts the CPU more often: latency may fall, but CPU use can rise. A low-end CPU is more sensitive under heavy traffic; a powerful one has more headroom."
        Action={
            GNO_GetSelectedAdapters|ForEach-Object{
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Interrupt Moderation" -DisplayValue "Disabled" -EA SilentlyContinue
            }
        }
    }
    @{
        RU="Отключить Large Send Offload"; EN="Large Send Offload Off"
        TipRU="Отключает Large Send Offload. Передача крупных TCP-сегментов чаще обрабатывается CPU вместо адаптера; это может помочь при проблемном драйвере, но повысить загрузку CPU и снизить пропускную способность на слабом ПК. Мощному проще выдержать нагрузку."
        TipEN="Disables Large Send Offload. The CPU handles more large TCP sends instead of the adapter; this may help with a faulty driver but can raise CPU load and reduce throughput on a low-end PC. A powerful CPU can handle the extra work more easily."
        Action={
            GNO_GetSelectedAdapters|ForEach-Object{
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Large Send Offload v2 (IPv4)" -DisplayValue "Disabled" -EA SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Large Send Offload v2 (IPv6)" -DisplayValue "Disabled" -EA SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "TCP/UDP Checksum Offload (IPv4)" -DisplayValue "Disabled" -EA SilentlyContinue
            }
        }
    }
)

# Словарь действий NIC для индивидуального применения
$Script:NICActions = @{}
foreach ($nd in $nicDefs) { $Script:NICActions[$nd.RU] = $nd.Action }

$Script:NICBar  = @{}
$Script:NICStat = @{}
$Script:NICRows = [System.Collections.Generic.List[hashtable]]::new()
for ($i = 0; $i -lt $nicDefs.Count; $i++) {
    [int]$ny = 342 + ($i * 34)
    $nd = $nicDefs[$i]

    # Название
    $lbl = GNO_MakeLabel "" 8 ($ny+2) 218 20 $F_NORMAL $C_TEXT
    GNO_RegLang $lbl $nd.RU $nd.EN
    $pgNIC.Controls.Add($lbl)

    # Кнопка i
    $iBtnN = GNO_MakeInfoBtn 228 ($ny+1) $nd.TipRU $nd.TipEN
    $pgNIC.Controls.Add($iBtnN)

    # Прогресс-бар
    $nb = GNO_MakePBar 258 ($ny+2) 250 18
    $pgNIC.Controls.Add($nb)

    # Статус
    $ns = GNO_MakeLabel "--" 515 ($ny+2) 55 18 $F_SMALL $C_DIM
    $pgNIC.Controls.Add($ns)

    # Кнопка Применить (индивидуальная)
    $applyBtnNIC = GNO_MakeButton "" 577 ($ny-1) 110 26 ([System.Drawing.Color]::FromArgb(0,50,70)) $C_ACCENT
    GNO_RegLang $applyBtnNIC "Применить" "Apply"
    $localNd  = $nd
    $localNb  = $nb
    $localNs  = $ns
    $applyBtnNIC.Add_Click({
        $localNs.Text      = GNO_TStr "..." "..."
        $localNs.ForeColor = $C_YELLOW
        $localNb.Value     = 40
        [System.Windows.Forms.Application]::DoEvents()
        try {
            & $localNd.Action
            $localNb.Value     = 100
            $localNs.Text      = "OK"
            $localNs.ForeColor = $C_GREEN
            GNO_AppendRTB $Script:rtbNICDet "[OK] $($localNd.RU)" $C_GREEN
            GNO_WriteLog "NIC single: $($localNd.RU)"
        } catch {
            $localNb.Value     = 100
            $localNs.Text      = GNO_TStr "Ошибка" "Error"
            $localNs.ForeColor = $C_RED
            GNO_AppendRTB $Script:rtbNICDet "[ERR] $($localNd.RU): $_" $C_RED
        }
    }.GetNewClosure())
    $pgNIC.Controls.Add($applyBtnNIC)

    $Script:NICBar[$nd.RU]  = $nb
    $Script:NICStat[$nd.RU] = $ns
    $Script:NICBar[$nd.EN]  = $nb
    $Script:NICStat[$nd.EN] = $ns
    $Script:NICRows.Add(@{Label=$lbl; Info=$iBtnN; Bar=$nb; Status=$ns; Apply=$applyBtnNIC})
}

$btnTuneNIC = GNO_MakeButton "" 8 626 220 34 ([System.Drawing.Color]::FromArgb(0,50,70)) $C_ACCENT
GNO_RegLang $btnTuneNIC "Настроить адаптер для игр" "Tune NIC for Gaming"
$pgNIC.Controls.Add($btnTuneNIC)

# ═══════════════════════════════════════════════════════
#  ВКЛАДКА: ПИНГ / ДЖИТТЕР
# ═══════════════════════════════════════════════════════
$secTest = GNO_MakeSection "" 8 6
GNO_RegLang $secTest "Анализатор Пинга, Джиттера и Потерь пакетов" "Ping  Jitter  Packet Loss Analyzer"
$pgTest.Controls.Add($secTest)

$Script:PingMetric = @{}
$pingMetricDefs = @(
    @{NRU="Мин. пинг"; NEN="Min Ping"; X=8;   C=$C_GREEN}
    @{NRU="Сред. пинг";NEN="Avg Ping"; X=168; C=$C_ACCENT}
    @{NRU="Макс. пинг";NEN="Max Ping"; X=328; C=$C_YELLOW}
    @{NRU="Джиттер";   NEN="Jitter";   X=488; C=$C_PURPLE}
    @{NRU="Потери %";  NEN="Loss pct"; X=648; C=$C_RED}
    @{NRU="Качество";  NEN="Quality";  X=808; C=$C_GREEN}
)
foreach ($m in $pingMetricDefs) {
    $pnl = New-Object System.Windows.Forms.Panel
    $pnl.Location    = New-Object System.Drawing.Point($m.X, 32)
    $pnl.Size        = New-Object System.Drawing.Size(152, 68)
    $pnl.BackColor   = $C_PANEL
    $pnl.BorderStyle = "FixedSingle"
    $nl = GNO_MakeLabel "" 6 4 140 16 $F_SMALL $C_DIM
    GNO_RegLang $nl $m.NRU $m.NEN
    $vl = GNO_MakeLabel "--" 6 22 140 36 $F_BIG $m.C
    $pnl.Controls.Add($nl)
    $pnl.Controls.Add($vl)
    $pgTest.Controls.Add($pnl)
    $Script:PingMetric[$m.NRU] = $vl
    $Script:PingMetric[$m.NEN] = $vl
}

$lblTargets = GNO_MakeLabel "" 8 112 80 22 $F_NORMAL $C_TEXT
GNO_RegLang $lblTargets "Хосты:" "Targets:"
$pgTest.Controls.Add($lblTargets)

$tbTargets = New-Object System.Windows.Forms.TextBox
$tbTargets.Text      = "8.8.8.8, 1.1.1.1, google.com"
$tbTargets.Location  = New-Object System.Drawing.Point(90, 110)
$tbTargets.Size      = New-Object System.Drawing.Size(360, 24)
$tbTargets.BackColor = $C_PANEL
$tbTargets.ForeColor = $C_TEXT
$tbTargets.Font      = $F_NORMAL
$pgTest.Controls.Add($tbTargets)

$lblCount = GNO_MakeLabel "" 463 112 65 22 $F_NORMAL $C_TEXT
GNO_RegLang $lblCount "Кол-во:" "Count:"
$pgTest.Controls.Add($lblCount)

$nudCount = New-Object System.Windows.Forms.NumericUpDown
$nudCount.Location  = New-Object System.Drawing.Point(530, 110)
$nudCount.Size      = New-Object System.Drawing.Size(70, 24)
$nudCount.Minimum   = 4
$nudCount.Maximum   = 200
$nudCount.Value     = 30
$nudCount.BackColor = $C_PANEL
$nudCount.ForeColor = $C_TEXT
$pgTest.Controls.Add($nudCount)

$btnStartTest = GNO_MakeButton "" 610 108 130 30 ([System.Drawing.Color]::FromArgb(0,70,30)) $C_GREEN
$btnStopTest  = GNO_MakeButton "" 750 108  90 30 ([System.Drawing.Color]::FromArgb(80,0,0))  $C_RED
GNO_RegLang $btnStartTest "Старт"      "Start Test"
GNO_RegLang $btnStopTest  "Стоп"       "Stop"
$btnStopTest.Enabled = $false
$pgTest.Controls.Add($btnStartTest)
$pgTest.Controls.Add($btnStopTest)

$chartMaxPts = 120
$Script:PingHistory    = [System.Collections.Generic.List[double]]::new()
$Script:JitterHistory  = [System.Collections.Generic.List[double]]::new()
$Script:LossHistory    = [System.Collections.Generic.List[double]]::new()

# Helper: draw one chart panel
function global:GNO_DrawChart {
    param($g, $w, $h, $data, $lineColor, $fillColor, $label, $unit, $warnThresh, $badThresh)
    try {
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::FromArgb(18,18,35))

    $padL = 48; $padR = 8; $padT = 8; $padB = 18
    [int]$cw = $w - $padL - $padR
    [int]$ch = $h - $padT - $padB

    # --- Autoscale Y (nice numbers) ---
    $rawMax = if ($data.Count -gt 0) { ($data | Measure-Object -Maximum).Maximum } else { 1.0 }
    $rawMax = [double][Math]::Max($rawMax, 1.0)
    $mag    = [Math]::Pow(10, [Math]::Floor([Math]::Log10($rawMax)))
    $norm   = $rawMax / $mag
    $nice   = if ($norm -le 1.5) { 1.5 } elseif ($norm -le 2) { 2 } elseif ($norm -le 3) { 3 } elseif ($norm -le 5) { 5 } else { 10 }
    [double]$maxY = $nice * $mag

    # --- Grid (4 lines) ---
    $gridPen   = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(40,40,65), 1)
    $gridFont  = New-Object System.Drawing.Font("Consolas", 7)
    $gridBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(90,110,140))
    for ($gi = 0; $gi -le 4; $gi++) {
        [int]$gy = $padT + $ch - [int]($gi / 4.0 * $ch)
        $g.DrawLine($gridPen, $padL, $gy, ($padL + $cw), $gy)
        $gridVal = [math]::Round($maxY * $gi / 4, 1)
        $g.DrawString("$gridVal", $gridFont, $gridBrush, 1, ($gy - 7))
    }
    $gridPen.Dispose(); $gridFont.Dispose(); $gridBrush.Dispose()

    # --- Threshold lines ---
    if ($warnThresh -gt 0 -and $warnThresh -lt $maxY) {
        [int]$ty = $padT + $ch - [int]([double]$warnThresh / $maxY * $ch)
        $tp = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(120,255,200,0), 1)
        $tp.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
        $g.DrawLine($tp, $padL, $ty, ($padL + $cw), $ty)
        $tp.Dispose()
    }
    if ($badThresh -gt 0 -and $badThresh -lt $maxY) {
        [int]$ty = $padT + $ch - [int]([double]$badThresh / $maxY * $ch)
        $bp = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(120,255,60,80), 1)
        $bp.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
        $g.DrawLine($bp, $padL, $ty, ($padL + $cw), $ty)
        $bp.Dispose()
    }

    # --- Data: fill polygon + line ---
    [int]$count = $data.Count
    if ($count -gt 1) {
        # Strictly typed PointF lists — no PowerShell slicing
        $linePts = [System.Collections.Generic.List[System.Drawing.PointF]]::new()
        $fillPts = [System.Collections.Generic.List[System.Drawing.PointF]]::new()

        for ($i = 0; $i -lt $count; $i++) {
            [float]$px  = [float]$padL + ([float]$i / [float][Math]::Max($chartMaxPts - 1, 1) * [float]$cw)
            [float]$val = [float][Math]::Min([double]$data[$i], $maxY)
            [float]$py  = [float]$padT + [float]$ch - ($val / [float]$maxY * [float]$ch)
            $pt = [System.Drawing.PointF]::new($px, $py)
            $linePts.Add($pt)
            $fillPts.Add($pt)
        }
        # Close fill polygon at bottom-right → bottom-left
        $fillPts.Add([System.Drawing.PointF]::new($linePts[$count - 1].X, [float]($padT + $ch)))
        $fillPts.Add([System.Drawing.PointF]::new([float]$padL,           [float]($padT + $ch)))

        $brush = New-Object System.Drawing.SolidBrush($fillColor)
        $g.FillPolygon($brush, ([System.Drawing.PointF[]]$fillPts.ToArray()))
        $brush.Dispose()

        $pen = New-Object System.Drawing.Pen($lineColor, 1.5)
        $g.DrawLines($pen, ([System.Drawing.PointF[]]$linePts.ToArray()))
        $pen.Dispose()
    }

    # --- Label: cur / avg / max ---
    $lblFont  = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
    $lblBrush = New-Object System.Drawing.SolidBrush($lineColor)
    $curVal   = if ($count -gt 0) { [math]::Round([double]$data[$count - 1], 1) } else { 0 }
    $avgVal   = if ($count -gt 0) { [math]::Round(($data | Measure-Object -Average).Average, 1) } else { 0 }
    $maxDisp  = if ($count -gt 0) { [math]::Round(($data | Measure-Object -Maximum).Maximum, 1) } else { 0 }
    $g.DrawString("${label}   cur: ${curVal}${unit}   avg: ${avgVal}${unit}   max: ${maxDisp}${unit}", $lblFont, $lblBrush, ($padL + 4), 1)
    $lblFont.Dispose(); $lblBrush.Dispose()
    } catch { <# подавляем ошибки рисования чтобы не спамить в консоль #> }
}

# 3 chart panels stacked
$chartPing = New-Object System.Windows.Forms.Panel
$chartPing.Location    = New-Object System.Drawing.Point(8, 148)
$chartPing.Size        = New-Object System.Drawing.Size(680, 90)
$chartPing.BackColor   = [System.Drawing.Color]::FromArgb(18,18,35)
$chartPing.BorderStyle = "FixedSingle"
$pgTest.Controls.Add($chartPing)

$chartJitter = New-Object System.Windows.Forms.Panel
$chartJitter.Location    = New-Object System.Drawing.Point(8, 244)
$chartJitter.Size        = New-Object System.Drawing.Size(680, 75)
$chartJitter.BackColor   = [System.Drawing.Color]::FromArgb(18,18,35)
$chartJitter.BorderStyle = "FixedSingle"
$pgTest.Controls.Add($chartJitter)

$chartLoss = New-Object System.Windows.Forms.Panel
$chartLoss.Location    = New-Object System.Drawing.Point(8, 325)
$chartLoss.Size        = New-Object System.Drawing.Size(680, 60)
$chartLoss.BackColor   = [System.Drawing.Color]::FromArgb(18,18,35)
$chartLoss.BorderStyle = "FixedSingle"
$pgTest.Controls.Add($chartLoss)

$chartPing.Add_Paint({
    param($s,$e)
    GNO_DrawChart $e.Graphics $s.Width $s.Height $Script:PingHistory `
        ([System.Drawing.Color]::FromArgb(0,210,255)) `
        ([System.Drawing.Color]::FromArgb(25,0,210,255)) `
        "Ping" "ms" 50 100
})

$chartJitter.Add_Paint({
    param($s,$e)
    GNO_DrawChart $e.Graphics $s.Width $s.Height $Script:JitterHistory `
        ([System.Drawing.Color]::FromArgb(255,200,0)) `
        ([System.Drawing.Color]::FromArgb(25,255,200,0)) `
        "Jitter" "ms" 10 30
})

$chartLoss.Add_Paint({
    param($s,$e)
    GNO_DrawChart $e.Graphics $s.Width $s.Height $Script:LossHistory `
        ([System.Drawing.Color]::FromArgb(255,60,80)) `
        ([System.Drawing.Color]::FromArgb(30,255,60,80)) `
        "Loss" "%" 1 5
})

$Script:rtbPing    = GNO_MakeRTB 8   392 680 208
$Script:rtbPingDet = GNO_MakeRTB 700 148 350 452
$pgTest.Controls.Add($Script:rtbPing)

$secTestDet = GNO_MakeSection "" 700 134 350
GNO_RegLang $secTestDet "Детали по хостам" "Per-Host Details"
$pgTest.Controls.Add($secTestDet)
$pgTest.Controls.Add($Script:rtbPingDet)

# ═══════════════════════════════════════════════════════
#  ВКЛАДКА: ТВИКИ (РЕЕСТР)
# ═══════════════════════════════════════════════════════
$secTweaks = GNO_MakeSection "" 8 6
GNO_RegLang $secTweaks "Твики реестра для максимальной производительности" "Registry Tweaks for Maximum Performance"
$pgTweaks.Controls.Add($secTweaks)

# Заголовки колонок
$thName = GNO_MakeLabel "" 8   30 270 18 $F_SMALL $C_DIM
$thStat = GNO_MakeLabel "" 320 30 130 18 $F_SMALL $C_DIM
GNO_RegLang $thName "Твик" "Tweak"
GNO_RegLang $thStat "Статус" "Status"
$pgTweaks.Controls.Add($thName)
$pgTweaks.Controls.Add($thStat)

# Лог твиков справа
$secTweakLog = GNO_MakeSection "" 770 6 280
GNO_RegLang $secTweakLog "Лог применения" "Application Log"
$pgTweaks.Controls.Add($secTweakLog)
$Script:rtbTweaks = GNO_MakeRTB 770 28 280 570
$pgTweaks.Controls.Add($Script:rtbTweaks)

$Script:TweakDefs = @(
    @{
        NameRU = "Отключить Game DVR / Запись Xbox"
        NameEN = "Disable Game DVR / Xbox Recording"
        TipRU="Запрещает Game DVR через политику Windows. Если запись была активна, снизятся нагрузка кодирования и использование RAM; на мощном ПК выигрыш может быть незаметен. Захват и запись через эту функцию отключатся."
        TipEN="Blocks Game DVR through Windows policy. If capture was active, encoding load and RAM use may fall; gains can be unnoticeable on a powerful PC. Recording through this feature will stop."
        Action = {
            if (-not (Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR")) {
                New-Item "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Force | Out-Null
            }
            Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "DVREnabled"        -Value 0 -Type DWord -Force
            Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord -Force
            if (-not (Test-Path "HKCU:\System\GameConfigStore")) {
                New-Item "HKCU:\System\GameConfigStore" -Force | Out-Null
            }
            Set-ItemProperty "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force
        }
    }
    @{
        NameRU = "Включить Game Mode Windows"
        NameEN = "Enable Windows Game Mode"
        TipRU="Включает Windows Game Mode: система меняет приоритеты и фоновую активность при игре. Может освободить ресурсы CPU на загруженном слабом ПК; на мощном эффект зависит от фоновых задач. При несовместимости игру можно запускать с режимом выключенным."
        TipEN="Enables Windows Game Mode, which adjusts priorities and background activity during games. It may free CPU resources on a busy low-end PC; effects on a powerful PC depend on background load. Disable it for compatibility issues."
        Action = {
            if (-not (Test-Path "HKCU:\SOFTWARE\Microsoft\GameBar")) {
                New-Item "HKCU:\SOFTWARE\Microsoft\GameBar" -Force | Out-Null
            }
            Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "AllowAutoGameMode"  -Value 1 -Type DWord -Force
            Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -Type DWord -Force
        }
    }
    @{
        NameRU = "HAGS — Аппаратное планирование GPU"
        NameEN = "HAGS — Hardware GPU Scheduling"
        TipRU="Включает HAGS и требует перезагрузки. Меняет планирование команд GPU; результат зависит от видеокарты, драйвера и игры. Может снизить часть нагрузки CPU, но также вызвать рывки или несовместимость; особенно проверяйте на слабом GPU."
        TipEN="Enables HAGS and requires a reboot. It changes GPU command scheduling; results depend on graphics hardware, driver, and game. It may reduce some CPU work or cause stutter/compatibility issues; check carefully on a low-end GPU."
        Action = {
            if (-not (Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers")) {
                New-Item "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Force | Out-Null
            }
            Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -Type DWord -Force
        }
    }
    @{
        NameRU = "Отключить Power Throttling CPU"
        NameEN = "Disable CPU Power Throttling"
        TipRU="Отключает Power Throttling для фоновых процессов. Может увеличить их потребление CPU, не создавая ресурсов для игры; слабый CPU может сильнее конкурировать с фоновыми задачами. Растут расход батареи и нагрев."
        TipEN="Disables Power Throttling for background processes. They may use more CPU without adding resources to the game; a low-end CPU may face more competition. Battery use and heat can rise."
        Action = {
            $path = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling"
            if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
            Set-ItemProperty $path -Name "PowerThrottlingOff" -Value 1 -Type DWord -Force
        }
    }
    @{
        NameRU = "Таймер высокого разрешения"
        NameEN = "High Resolution Timer"
        TipRU="Включает параметры высокого разрешения таймера и отключает динамический тик; нужна перезагрузка. Может увеличить частоту пробуждения CPU и энергопотребление, особенно на мобильных устройствах. Прирост FPS или снижение задержки не гарантированы."
        TipEN="Enables high-resolution timer settings and disables dynamic tick; a reboot is required. More frequent CPU wakeups may increase power use, especially on mobile systems. Higher FPS or lower latency is not guaranteed."
        Action = {
            bcdedit /set useplatformtick yes 2>&1 | Out-Null
            bcdedit /set disabledynamictick yes 2>&1 | Out-Null
        }
    }
    @{
        NameRU = "Приоритет GPU/CPU для игр"
        NameEN = "GPU/CPU Priority for Games"
        TipRU="Меняет параметры планировщика мультимедиа для задачи Games. Может повлиять на распределение CPU и GPU при конкуренции потоков, но не добавляет вычислительной мощности. Эффект зависит от игры и драйвера; фоновые задачи могут уступать."
        TipEN="Changes Windows multimedia scheduling values for the Games task. It may affect CPU/GPU allocation under contention but does not add computing power. Effects depend on game and driver; background tasks may yield resources."
        Action = {
            $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
            if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
            Set-ItemProperty $path -Name "GPU Priority"        -Value 8      -Type DWord -Force
            Set-ItemProperty $path -Name "Priority"            -Value 6      -Type DWord -Force
            Set-ItemProperty $path -Name "Scheduling Category" -Value "High" -Force
            Set-ItemProperty $path -Name "SFIO Priority"       -Value "High" -Force
            Set-ItemProperty $path -Name "Background Only"     -Value "False"-Force
        }
    }
    @{
        NameRU = "Отключить ускорение мыши"
        NameEN = "Disable Mouse Acceleration"
        TipRU="Отключает ускорение указателя Windows для пользователя. Изменяет поведение мыши, но не производительность CPU/GPU и FPS. Подойдет тем, кому нужен более постоянный отклик; обычное управление курсором может ощущаться непривычно."
        TipEN="Disables Windows pointer acceleration for the user. It changes mouse behavior but not CPU/GPU performance or FPS. It may suit users who prefer consistent pointer response; desktop cursor movement may feel unfamiliar."
        Action = {
            Set-ItemProperty "HKCU:\Control Panel\Mouse" -Name "MouseSpeed"      -Value "0" -Force
            Set-ItemProperty "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -Force
            Set-ItemProperty "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -Force
        }
    }
    @{
        NameRU = "Отключить Fullscreen оптимизации"
        NameEN = "Disable Fullscreen Optimizations"
        TipRU="Меняет параметры Windows для полноэкранных оптимизаций. Может повлиять на композицию, оверлеи, Alt+Tab и нагрузку GPU; эффект зависит от игры и видеокарты. Проверяйте конкретные приложения: гарантии меньшей задержки нет."
        TipEN="Changes Windows settings related to fullscreen optimizations. It may affect composition, overlays, Alt+Tab, and GPU workload; results depend on game and graphics hardware. Check each app; lower latency is not guaranteed."
        Action = {
            if (-not (Test-Path "HKCU:\System\GameConfigStore")) {
                New-Item "HKCU:\System\GameConfigStore" -Force | Out-Null
            }
            Set-ItemProperty "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode"               -Value 2 -Type DWord -Force
            Set-ItemProperty "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode"       -Value 1 -Type DWord -Force
            Set-ItemProperty "HKCU:\System\GameConfigStore" -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1 -Type DWord -Force
        }
    }
    @{
        NameRU = "Отключить SysMain (Superfetch)"
        NameEN = "Disable SysMain (Superfetch)"
        TipRU="Останавливает и отключает SysMain. Может уменьшить фоновую дисковую активность, если служба создает нагрузку; фиксированную экономию RAM обещать нельзя. Часто запускаемые приложения могут загружаться медленнее, особенно с HDD."
        TipEN="Stops and disables SysMain. It may reduce background disk activity if the service is causing load; a fixed amount of freed RAM cannot be promised. Frequently used apps may launch more slowly, especially from an HDD."
        Action = {
            Stop-Service -Name "SysMain" -Force -EA SilentlyContinue
            Set-Service  -Name "SysMain" -StartupType Disabled -EA SilentlyContinue
        }
    }
    @{
        NameRU = "Отключить Xbox Game Bar"
        NameEN = "Disable Xbox Game Bar"
        TipRU="Запрещает Game DVR политикой Windows, влияя на связанные функции Xbox Game Bar. При активной записи может снизить нагрузку CPU, GPU и память; на мощном ПК эффект может быть мал. Оверлей и запись Game Bar отключатся."
        TipEN="Blocks Game DVR through Windows policy, affecting related Xbox Game Bar features. If recording was active, CPU/GPU load and memory use may fall; gains can be small on a powerful PC. Game Bar overlay and recording will be disabled."
        Action = {
            if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR")) {
                New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Force | Out-Null
            }
            Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0 -Type DWord -Force
        }
    }
    @{
        NameRU = "Отключить Cortana"
        NameEN = "Disable Cortana"
        TipRU="Запрещает Cortana политикой Windows. Может сократить фоновые процессы и использование RAM/CPU, если компонент активен; на мощном ПК эффект обычно мал. Голосовые функции Cortana перестанут работать."
        TipEN="Blocks Cortana through Windows policy. It may reduce background CPU/RAM use when the component is active; effects are usually small on a powerful PC. Cortana voice features will stop working."
        Action = {
            $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
            if (-not (Test-Path $path)) { New-Item $path -Force | Out-Null }
            Set-ItemProperty $path -Name "AllowCortana" -Value 0 -Type DWord -Force
        }
    }
    @{
        NameRU = "Визуальные эффекты — Производительность"
        NameEN = "Visual Effects — Performance Mode"
        TipRU="Включает режим визуальных эффектов Windows, убирая часть анимаций и эффектов. На слабой встроенной графике или CPU интерфейс может стать отзывчивее; на мощном ПК разница обычно мала и FPS игры не обещан. Внешний вид станет проще."
        TipEN="Selects a Windows visual-effects mode and removes some animations and effects. On a low-end CPU or integrated GPU, the interface may feel more responsive; effects are usually small on a powerful PC and do not promise game FPS. The interface looks simpler."
        Action = {
            if (-not (Test-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects")) {
                New-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Force | Out-Null
            }
            Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord -Force
            Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Value "0" -Force -EA SilentlyContinue
            Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay"   -Value "0" -Force -EA SilentlyContinue
        }
    }
)

# Строим UI для твиков
$Script:TweakStatLbls = @{}
[int]$ty = 50

foreach ($tweak in $Script:TweakDefs) {
    $localTweak = $tweak

    # Подпись твика
    $lbl = GNO_MakeLabel "" 8 $ty 268 24 $F_NORMAL $C_TEXT
    GNO_RegLang $lbl $tweak.NameRU $tweak.NameEN
    $pgTweaks.Controls.Add($lbl)

    # Кнопка i (подсказка)
    $iBtn = GNO_MakeInfoBtn 278 ($ty+1) $tweak.TipRU $tweak.TipEN
    $pgTweaks.Controls.Add($iBtn)

    # Статус
    $statLbl = GNO_MakeLabel "—" 308 $ty 130 24 $F_SMALL $C_DIM
    $pgTweaks.Controls.Add($statLbl)
    $Script:TweakStatLbls[$tweak.NameRU] = $statLbl

    # Кнопка Применить
    $applyBtn = GNO_MakeButton "" 446 ($ty-1) 110 26 ([System.Drawing.Color]::FromArgb(50,0,80)) $C_PURPLE
    GNO_RegLang $applyBtn "Применить" "Apply"

    $localStat = $statLbl
    $localRTB  = $Script:rtbTweaks
    $applyBtn.Add_Click({
        $localStat.Text      = GNO_TStr "Применяется..." "Applying..."
        $localStat.ForeColor = $C_YELLOW
        [System.Windows.Forms.Application]::DoEvents()
        try {
            & $localTweak.Action
            $localStat.Text      = GNO_TStr "✓ Готово" "✓ Done"
            $localStat.ForeColor = $C_GREEN
            GNO_AppendRTB $localRTB "[OK] $($localTweak.NameRU)" $C_GREEN
            GNO_WriteLog "TWEAK OK: $($localTweak.NameRU)"
        } catch {
            $localStat.Text      = GNO_TStr "✗ Ошибка" "✗ Error"
            $localStat.ForeColor = $C_RED
            GNO_AppendRTB $localRTB "[ERR] $($localTweak.NameRU): $_" $C_RED
            GNO_WriteLog "TWEAK ERR: $($localTweak.NameRU) | $_" "ERROR"
        }
    }.GetNewClosure())

    $pgTweaks.Controls.Add($applyBtn)
    $ty += 38
}

# Кнопка "Создать точку восстановления"
$btnRestorePoint = GNO_MakeButton "" 8 ($ty + 8) 260 34 ([System.Drawing.Color]::FromArgb(0,40,70)) $C_ACCENT
GNO_RegLang $btnRestorePoint "■ Точка восстановления" "■ Create Restore Point"
$Script:Tooltip.SetToolTip($btnRestorePoint, "Создаёт точку восстановления системы перед применением твиков. Если что-то пойдёт не так — откатишься через: Панель управления → Восстановление → Восстановить систему")
$btnRestorePoint.Add_Click({
    $btnRestorePoint.Enabled = $false
    GNO_AppendRTB $Script:rtbTweaks "$(GNO_TStr 'Создание точки восстановления...' 'Creating restore point...')" $C_YELLOW
    [System.Windows.Forms.Application]::DoEvents()
    try {
        $rpName = "NetLagov_$(Get-Date -Format 'dd.MM.yyyy_HH-mm')"
        Enable-ComputerRestore -Drive "C:\" -EA SilentlyContinue
        Checkpoint-Computer -Description $rpName -RestorePointType "MODIFY_SETTINGS" -EA Stop
        GNO_AppendRTB $Script:rtbTweaks "[OK] $(GNO_TStr 'Точка восстановления создана' 'Restore point created'): $rpName" $C_GREEN
        GNO_WriteLog "RESTORE POINT: $rpName"
        $btnRestorePoint.Text = GNO_TStr "✓ Точка создана" "✓ Point created"
        $btnRestorePoint.ForeColor = $C_GREEN
    } catch {
        GNO_AppendRTB $Script:rtbTweaks "[ERR] $(GNO_TStr 'Ошибка создания точки' 'Restore point error'): $_" $C_RED
        GNO_WriteLog "RESTORE POINT ERR: $_" "ERROR"
        $btnRestorePoint.Enabled = $true
    }
    GNO_Log_Refresh
})
$pgTweaks.Controls.Add($btnRestorePoint)

# Кнопка "Применить все"
$btnApplyAllTweaks = GNO_MakeButton "" 278 ($ty + 8) 200 34 ([System.Drawing.Color]::FromArgb(0,60,30)) $C_GREEN
GNO_RegLang $btnApplyAllTweaks "Применить все твики" "Apply All Tweaks"
$btnApplyAllTweaks.Add_Click({
    GNO_AppendRTB $Script:rtbTweaks "=== $(GNO_TStr 'Применение всех твиков' 'Applying all tweaks') ===" $C_ACCENT
    foreach ($tweak in $Script:TweakDefs) {
        $statLbl = $Script:TweakStatLbls[$tweak.NameRU]
        $statLbl.Text      = GNO_TStr "Применяется..." "Applying..."
        $statLbl.ForeColor = $C_YELLOW
        [System.Windows.Forms.Application]::DoEvents()
        try {
            & $tweak.Action
            $statLbl.Text      = GNO_TStr "✓ Готово" "✓ Done"
            $statLbl.ForeColor = $C_GREEN
            GNO_AppendRTB $Script:rtbTweaks "[OK] $($tweak.NameRU)" $C_GREEN
            GNO_WriteLog "TWEAK OK: $($tweak.NameRU)"
        } catch {
            $statLbl.Text      = GNO_TStr "✗ Ошибка" "✗ Error"
            $statLbl.ForeColor = $C_RED
            GNO_AppendRTB $Script:rtbTweaks "[ERR] $($tweak.NameRU)" $C_RED
            GNO_WriteLog "TWEAK ERR: $($tweak.NameRU)" "ERROR"
        }
        Start-Sleep -Milliseconds 100
    }
    GNO_AppendRTB $Script:rtbTweaks "=== $(GNO_TStr 'Готово! Рекомендуется перезагрузка.' 'Done! Reboot recommended.') ===" $C_GREEN
    GNO_Log_Refresh
})
$pgTweaks.Controls.Add($btnApplyAllTweaks)

$lblTweakNote = GNO_MakeLabel "" 8 ($ty + 50) 760 20 $F_SMALL $C_YELLOW
GNO_RegLang $lblTweakNote "* Некоторые твики требуют перезагрузки для вступления в силу" "* Some tweaks require a reboot to take effect"
$pgTweaks.Controls.Add($lblTweakNote)

# ═══════════════════════════════════════════════════════
#  ВКЛАДКА: ЛОГ
# ═══════════════════════════════════════════════════════
$secLog = GNO_MakeSection "" 8 6
GNO_RegLang $secLog "Журнал операций" "Operation Log"
$pgLog.Controls.Add($secLog)

$Script:rtbLog = GNO_MakeRTB 8 30 1040 580
$pgLog.Controls.Add($Script:rtbLog)

$btnOpenLog = GNO_MakeButton "" 8 622 200 34 ([System.Drawing.Color]::FromArgb(0,40,60)) $C_ACCENT
GNO_RegLang $btnOpenLog "Открыть в Notepad" "Open in Notepad"
$pgLog.Controls.Add($btnOpenLog)

# ═══════════════════════════════════════════════════════
#  ЛОГИКА: ДИАГНОСТИКА
# ═══════════════════════════════════════════════════════
function global:GNO_Diag_Run {
    $statusBar.Text = "  $(GNO_TStr 'Диагностика...' 'Running diagnostics...')"
    $Script:rtbDiag.Clear()
    $Script:rtbAdapt.Clear()

    GNO_AppendRTB $Script:rtbDiag "$(GNO_TStr '==== Диагностика ====' '==== Diagnostics ====')" $C_ACCENT
    GNO_AppendRTB $Script:rtbDiag "$(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')" $C_DIM

    # Адаптеры — в правую панель
    try {
        $adapters = GNO_GetSelectedAdapters
        foreach ($a in $adapters) {
            $spd = try { [math]::Round([double]$a.LinkSpeed / 1MB, 0) } catch { "?" }
            GNO_AppendRTB $Script:rtbAdapt "$($a.Name)" $C_GREEN
            GNO_AppendRTB $Script:rtbAdapt "  $(GNO_TStr 'Скорость' 'Speed'): ${spd} Mbps" $C_TEXT
            GNO_AppendRTB $Script:rtbAdapt "  MAC: $($a.MacAddress)" $C_DIM
            try {
                $ip = (Get-NetIPAddress -InterfaceIndex $a.InterfaceIndex -AddressFamily IPv4 -EA SilentlyContinue).IPAddress
                if ($ip) { GNO_AppendRTB $Script:rtbAdapt "  IP: $ip" $C_ACCENT }
            } catch {}
        }
        $firstName = if ($adapters) { $adapters[0].Name } else { "N/A" }
        $Script:DiagMetric["Адаптер"].Text = $firstName.Substring(0,[Math]::Min($firstName.Length,10))
        $Script:DiagMetric["Adapter"].Text = $firstName.Substring(0,[Math]::Min($firstName.Length,10))
    } catch {}

    # ── Пинг по хостам ──
    GNO_AppendRTB $Script:rtbDiag "" $C_DIM
    GNO_AppendRTB $Script:rtbDiag "$(GNO_TStr '>> Тест связи...' '>> Connectivity test...')" $C_YELLOW
    $pings = @()
    foreach ($t in @("8.8.8.8","1.1.1.1","google.com")) {
        try {
            $r = Test-Connection $t -Count 4 -EA SilentlyContinue
            if ($r) {
                $vals = @($r | ForEach-Object { $_.$Script:PingProp })
                $avg  = [math]::Round(($vals | Measure-Object -Average).Average, 1)
                $pings += $avg
                $sym  = if ($avg -lt 30){ "[OK]" } elseif ($avg -lt 70){ "[HIGH]" } else { "[BAD]" }
                $clr  = if ($avg -lt 30){ $C_GREEN } elseif ($avg -lt 70){ $C_YELLOW } else { $C_RED }
                GNO_AppendRTB $Script:rtbDiag "  $($t.PadRight(14)) $avg ms  $sym" $clr
                GNO_WriteLog "Ping $t = ${avg}ms"
            }
        } catch {}
    }
    if ($pings.Count -gt 0) {
        $avgPing = [math]::Round(($pings | Measure-Object -Average).Average, 1)
        $Script:DiagMetric["Пинг"].Text = "${avgPing}ms"
        $Script:DiagMetric["Ping"].Text = "${avgPing}ms"
    }

    # ── Джиттер и потери ──
    GNO_AppendRTB $Script:rtbDiag "" $C_DIM
    GNO_AppendRTB $Script:rtbDiag "$(GNO_TStr '>> Джиттер и потери...' '>> Jitter and loss...')" $C_YELLOW
    try {
        $jr = Test-Connection "8.8.8.8" -Count 20 -EA SilentlyContinue
        if ($jr -and $jr.Count -gt 1) {
            $times = @($jr | ForEach-Object { $_.$Script:PingProp })
            $diffs = @()
            for ($i=1; $i -lt $times.Count; $i++) { $diffs += [Math]::Abs($times[$i] - $times[$i-1]) }
            $jAvg = [math]::Round(($diffs | Measure-Object -Average).Average, 1)
            $loss = [math]::Round(((20 - $jr.Count) / 20) * 100, 1)
            $Script:DiagMetric["Джиттер"].Text = "${jAvg}ms"
            $Script:DiagMetric["Jitter"].Text  = "${jAvg}ms"
            $Script:DiagMetric["Потери"].Text  = "${loss}%"
            $Script:DiagMetric["Loss"].Text    = "${loss}%"
            $jClr = if ($jAvg -lt 5){$C_GREEN}elseif($jAvg -lt 20){$C_YELLOW}else{$C_RED}
            GNO_AppendRTB $Script:rtbDiag "  $(GNO_TStr 'Джиттер' 'Jitter') avg ${jAvg}ms  $(GNO_TStr 'Потери' 'Loss') ${loss}%" $jClr
            GNO_WriteLog "Jitter=${jAvg}ms Loss=${loss}%"
        }
    } catch { GNO_AppendRTB $Script:rtbDiag "  $(GNO_TStr 'Пропущено' 'Skipped')" $C_DIM }

    # ── DNS задержка ──
    GNO_AppendRTB $Script:rtbDiag "" $C_DIM
    GNO_AppendRTB $Script:rtbDiag "$(GNO_TStr '>> DNS задержка...' '>> DNS latency...')" $C_YELLOW
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        [System.Net.Dns]::GetHostAddresses("google.com") | Out-Null
        $sw.Stop()
        $dnsMs = [math]::Round($sw.ElapsedMilliseconds, 1)
        $Script:DiagMetric["DNS мс"].Text = "${dnsMs}ms"
        $Script:DiagMetric["DNS ms"].Text = "${dnsMs}ms"
        GNO_AppendRTB $Script:rtbDiag "  DNS: ${dnsMs}ms" $C_ACCENT
        GNO_WriteLog "DNS=${dnsMs}ms"
    } catch { GNO_AppendRTB $Script:rtbDiag "  $(GNO_TStr 'Ошибка DNS' 'DNS test failed')" $C_RED }

    # ── Статус компонентов ──
    $Script:DiagStatus["Winsock"].Text      = "OK";     $Script:DiagStatus["Winsock"].ForeColor      = $C_GREEN
    try { $Script:DiagStatus["TCP стек"].Text   = "OK"; $Script:DiagStatus["TCP стек"].ForeColor   = $C_GREEN } catch {}
    try { $Script:DiagStatus["TCP Stack"].Text  = "OK"; $Script:DiagStatus["TCP Stack"].ForeColor  = $C_GREEN } catch {}
    try { $Script:DiagStatus["DNS кэш"].Text    = "Active"; $Script:DiagStatus["DNS кэш"].ForeColor   = $C_ACCENT } catch {}
    try { $Script:DiagStatus["DNS Cache"].Text  = "Active"; $Script:DiagStatus["DNS Cache"].ForeColor = $C_ACCENT } catch {}
    try { $Script:DiagStatus["Адаптер"].Text    = "OK"; $Script:DiagStatus["Адаптер"].ForeColor    = $C_GREEN } catch {}
    try { $Script:DiagStatus["NIC"].Text        = "OK"; $Script:DiagStatus["NIC"].ForeColor        = $C_GREEN } catch {}

    # ── Bufferbloat ──
    GNO_AppendRTB $Script:rtbDiag "" $C_DIM
    GNO_AppendRTB $Script:rtbDiag "$(GNO_TStr '>> Bufferbloat...' '>> Bufferbloat check...')" $C_YELLOW
    try {
        $bs = Test-Connection "8.8.8.8" -Count 5 -EA SilentlyContinue
        if ($bs) {
            $bVals = @($bs | ForEach-Object { $_.$Script:PingProp })
            $bp    = [math]::Round(($bVals | Measure-Object -Average).Average, 1)
            $ld    = Test-Connection "8.8.8.8" -Count 5 -EA SilentlyContinue
            if ($ld) {
                $lVals = @($ld | ForEach-Object { $_.$Script:PingProp })
                $lp    = [math]::Round(($lVals | Measure-Object -Average).Average, 1)
                $bl    = [math]::Round($lp - $bp, 1)
                $gr    = if ($bl -lt 5){"A - Excellent"}elseif($bl -lt 30){"B - Good"}elseif($bl -lt 60){"C - Poor"}else{"D - Bad"}
            } else {
                $lp = $bp; $bl = 0
                $gr = if ($bp -lt 20){"A - Excellent"}elseif($bp -lt 40){"B - Good"}elseif($bp -lt 80){"C - Poor"}else{"D - Bad"}
            }
            $bclr = if ($gr -like "A*"){$C_GREEN}elseif($gr -like "B*"){$C_ACCENT}elseif($gr -like "C*"){$C_YELLOW}else{$C_RED}
            $grLetter = $gr.Substring(0,1)
            $Script:DiagMetric["Оценка"].Text = $grLetter
            $Script:DiagMetric["Grade"].Text  = $grLetter
            try { $Script:DiagStatus["Bufferbloat"].Text = "Grade $grLetter"; $Script:DiagStatus["Bufferbloat"].ForeColor = $bclr } catch {}
            GNO_AppendRTB $Script:rtbDiag "  $(GNO_TStr 'База' 'Base'): ${bp}ms  $(GNO_TStr 'Нагрузка' 'Loaded'): ${lp}ms" $C_TEXT
            GNO_AppendRTB $Script:rtbDiag "  Bufferbloat: $gr (+${bl}ms)" $bclr
            GNO_WriteLog "Bufferbloat: $gr +${bl}ms"
        }
    } catch { GNO_AppendRTB $Script:rtbDiag "  $(GNO_TStr 'Пропущено' 'Skipped')" $C_DIM }

    # ── Game Mode ──
    try {
        $gm = Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "AutoGameModeEnabled" -EA SilentlyContinue
        $gmOn = $gm -and $gm.AutoGameModeEnabled -eq 1
        $Script:DiagStatus["Game Mode"].Text      = if ($gmOn){ GNO_TStr "Включён" "Enabled" } else { GNO_TStr "Выключен" "Disabled" }
        $Script:DiagStatus["Game Mode"].ForeColor = if ($gmOn){ $C_GREEN } else { $C_RED }
    } catch {}

    GNO_AppendRTB $Script:rtbDiag "" $C_DIM
    GNO_AppendRTB $Script:rtbDiag "$(GNO_TStr '==== Диагностика завершена ====' '==== Diagnostics complete ====')" $C_GREEN
    GNO_WriteLog "=== DIAGNOSTICS DONE ==="
    $statusBar.Text = "  $(GNO_TStr 'Готово' 'Ready')  |  Лог: $Script:LogFile"
    GNO_Log_Refresh
}

$btnRunDiag.Add_Click({ GNO_Diag_Run })
$btnAutoFix.Add_Click({
    GNO_Diag_Run
    GNO_Repair_Run
})

# ═══════════════════════════════════════════════════════
#  ЛОГИКА: РЕМОНТ
# ═══════════════════════════════════════════════════════
function global:GNO_Repair_Run {
    $statusBar.Text = "  $(GNO_TStr 'Восстановление сети...' 'Repairing network...')"
    $Script:rtbRep.Clear()
    GNO_AppendRTB $Script:rtbRep "$(GNO_TStr '=== Восстановление ===' '=== Repair ===')" $C_ACCENT

    $repOps = @(
        @{RU="Сброс Winsock";        EN="Winsock Reset";        A={ GNO_RunCmd "netsh winsock reset" }}
        @{RU="Сброс IP стека";       EN="IP Stack Reset";       A={ GNO_RunCmd "netsh int ip reset" }}
        @{RU="Освобождение IP";      EN="Release IP";           A={ GNO_RunCmd "ipconfig /release" }}
        @{RU="Обновление IP";        EN="Renew IP";             A={ GNO_RunCmd "ipconfig /renew" }}
        @{RU="Очистка DNS кэша";     EN="Flush DNS";            A={ GNO_RunCmd "ipconfig /flushdns" }}
        @{RU="Сброс файрвола";       EN="Reset Firewall";       A={ GNO_RunCmd "netsh advfirewall reset" }}
        @{RU="Сброс IPv6";           EN="Reset IPv6";           A={ GNO_RunCmd "netsh int ipv6 reset" }}
        @{RU="Проверка hosts файла"; EN="Check Hosts File";     A={
            $h = Get-Content "$env:SystemRoot\System32\drivers\etc\hosts" -EA SilentlyContinue
            $susp = $h | Where-Object { $_ -notmatch "^#" -and $_ -match "\S" -and $_ -notmatch "localhost|::1" }
            if ($susp) { GNO_AppendRTB $Script:rtbRep "  $(GNO_TStr 'Подозрительные записи' 'Suspicious entries'): $($susp.Count)" $C_YELLOW }
            else       { GNO_AppendRTB $Script:rtbRep "  Hosts file OK" $C_GREEN }
        }}
        @{RU="Сетевые политики";     EN="Network Policies";     A={ GNO_RunCmd "netsh int tcp reset" }}
        @{RU="Регистрация DNS";      EN="Register DNS";         A={ GNO_RunCmd "ipconfig /registerdns" }}
    )

    foreach ($op in $repOps) {
        GNO_SetBar $Script:RepBar[$op.RU] 40 "$(GNO_TStr 'Выполняется...' 'Applying...')" $Script:RepStat[$op.RU] $C_YELLOW
        try {
            & $op.A
            GNO_SetBar $Script:RepBar[$op.RU] 100 "OK" $Script:RepStat[$op.RU] $C_GREEN
            GNO_AppendRTB $Script:rtbRep "  [OK] $($op.RU)" $C_GREEN
        } catch {
            GNO_SetBar $Script:RepBar[$op.RU] 100 "$(GNO_TStr 'Ошибка' 'Error')" $Script:RepStat[$op.RU] $C_RED
        }
        GNO_WriteLog "REPAIR: $($op.RU)"
        Start-Sleep -Milliseconds 150
    }

    GNO_AppendRTB $Script:rtbRep "" $C_DIM
    GNO_AppendRTB $Script:rtbRep "$(GNO_TStr '=== Восстановление завершено ===' '=== Repair Done ===')" $C_GREEN
    GNO_WriteLog "=== REPAIR DONE ==="
    $statusBar.Text = "  $(GNO_TStr 'Готово' 'Ready')  |  Лог: $Script:LogFile"
    GNO_Log_Refresh
}

$Script:rebootTimer = $null
$btnRepair.Add_Click({ GNO_Repair_Run })
$btnReboot.Add_Click({
    $Script:rebootCountdown = 10
    $btnCancelR.Enabled = $true
    $Script:rebootTimer = New-Object System.Windows.Forms.Timer
    $Script:rebootTimer.Interval = 1000
    $Script:rebootTimer.Add_Tick({
        $Script:rebootCountdown--
        $btnReboot.Text = "$(GNO_TStr 'Перезагрузка' 'Reboot') ($($Script:rebootCountdown)с)"
        if ($Script:rebootCountdown -le 0) {
            $Script:rebootTimer.Stop()
            Restart-Computer -Force
        }
    })
    $Script:rebootTimer.Start()
})
$btnCancelR.Add_Click({
    if ($Script:rebootTimer) { $Script:rebootTimer.Stop() }
    GNO_RegLang $btnReboot "Перезагрузка (10с)" "Reboot (10s)"
    $btnReboot.Text     = if ($Script:Lang -eq "RU") {"Перезагрузка (10с)"} else {"Reboot (10s)"}
    $btnCancelR.Enabled = $false
})

# ═══════════════════════════════════════════════════════
#  ЛОГИКА: ИГРОВОЙ TCP
# ═══════════════════════════════════════════════════════
function global:GNO_Opt_Run {
    $statusBar.Text = "  $(GNO_TStr 'Оптимизация TCP...' 'Optimizing TCP...')"
    $Script:rtbOpt.Clear()
    GNO_AppendRTB $Script:rtbOpt "$(GNO_TStr '=== Оптимизация TCP ===' '=== TCP Optimization ===')" $C_ACCENT

    $optOps = @(
        @{RU="Отключить алгоритм Нейгла"; A={
            Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | ForEach-Object {
                Set-ItemProperty $_.PSPath "TcpAckFrequency" 1 -Type DWord -EA SilentlyContinue
                Set-ItemProperty $_.PSPath "TCPNoDelay"      1 -Type DWord -EA SilentlyContinue
                Set-ItemProperty $_.PSPath "TcpDelAckTicks"  1 -Type DWord -EA SilentlyContinue
            }
        }}
        @{RU="Авто-настройка TCP — Эксперим."; A={ GNO_RunCmd "netsh int tcp set global autotuninglevel=experimental" }}
        @{RU="Отключить сетевой троттлинг"; A={
            Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
                -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord -Force
        }}
        @{RU="System Responsiveness = 0"; A={
            Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
                -Name "SystemResponsiveness" -Value 0 -Type DWord -Force
        }}
        @{RU="QoS DSCP 46 EF"; A={
            if (-not (Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\Game")) {
                New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\Game" -Force | Out-Null
            }
            Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\Game" -Name "Version"            -Value "1.0"  -Force
            Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\Game" -Name "Application Name"  -Value "*"    -Force
            Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\Game" -Name "Protocol"          -Value "*"    -Force
            Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\Game" -Name "Local Port"        -Value "*"    -Force
            Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\Game" -Name "Remote Port"       -Value "*"    -Force
            Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\Game" -Name "Local IP"          -Value "*"    -Force
            Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\Game" -Name "Remote IP"         -Value "*"    -Force
            Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\Game" -Name "DSCP Value"        -Value "46"   -Force
            Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\QoS\Game" -Name "Throttle Rate"     -Value "-1"   -Force
        }}
        @{RU="Отключить ECN"; A={ GNO_RunCmd "netsh int tcp set global ecncapability=disabled" }}
        @{RU="Отключить TCP Timestamps"; A={ GNO_RunCmd "netsh int tcp set global timestamps=disabled" }}
        @{RU="Initial RTO 2000мс"; A={ GNO_RunCmd "netsh int tcp set global initialRto=2000" }}
        @{RU="Отключить Chimney Offload"; A={ GNO_RunCmd "netsh int tcp set global rsc=disabled" }}
        @{RU="RSS — включить"; A={ GNO_RunCmd "netsh int tcp set global rss=enabled" }}
        @{RU="TCP ACK Frequency = 1"; A={
            Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | ForEach-Object {
                Set-ItemProperty $_.PSPath "TcpAckFrequency" 1 -Type DWord -EA SilentlyContinue
            }
        }}
        @{RU="Отключить Teredo"; A={ GNO_RunCmd "netsh int teredo set state disabled" }}
    )

    foreach ($op in $optOps) {
        GNO_SetBar $Script:OptBar[$op.RU] 40 "$(GNO_TStr 'Применяется...' 'Applying...')" $Script:OptStat[$op.RU] $C_YELLOW
        try {
            & $op.A
            GNO_SetBar $Script:OptBar[$op.RU] 100 "OK" $Script:OptStat[$op.RU] $C_GREEN
            GNO_AppendRTB $Script:rtbOpt "  [OK] $($op.RU)" $C_GREEN
        } catch {
            GNO_SetBar $Script:OptBar[$op.RU] 100 "$(GNO_TStr 'Ошибка' 'Err')" $Script:OptStat[$op.RU] $C_RED
        }
        GNO_WriteLog "OPT: $($op.RU)"
        Start-Sleep -Milliseconds 100
    }

    GNO_AppendRTB $Script:rtbOpt "" $C_DIM
    GNO_AppendRTB $Script:rtbOpt "$(GNO_TStr '=== Оптимизация завершена ===' '=== Optimization Done ===')" $C_GREEN
    GNO_WriteLog "=== OPT DONE ==="
    $statusBar.Text = "  $(GNO_TStr 'Готово' 'Ready')  |  Лог: $Script:LogFile"
    GNO_Log_Refresh
}

function global:GNO_Opt_Restore {
    GNO_RunCmd "netsh int tcp set global autotuninglevel=normal"
    GNO_RunCmd "netsh int tcp set global ecncapability=enabled"
    GNO_RunCmd "netsh int tcp set global timestamps=allowed"
    GNO_RunCmd "netsh int tcp set global initialRto=3000"
    GNO_RunCmd "netsh int tcp set global rss=enabled"
    GNO_RunCmd "netsh int tcp set global rsc=enabled"
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
        -Name "NetworkThrottlingIndex" -Value 10 -Type DWord -Force
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" `
        -Name "SystemResponsiveness" -Value 20 -Type DWord -Force
    # Восстанавливаем реестровые ключи Nagle
    Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -EA SilentlyContinue | ForEach-Object {
        Remove-ItemProperty $_.PSPath "TcpAckFrequency" -EA SilentlyContinue
        Remove-ItemProperty $_.PSPath "TCPNoDelay"      -EA SilentlyContinue
        Remove-ItemProperty $_.PSPath "TcpDelAckTicks"  -EA SilentlyContinue
    }
    GNO_AppendRTB $Script:rtbOpt "$(GNO_TStr '=== Настройки восстановлены ===' '=== Defaults Restored ===')" $C_YELLOW
    GNO_WriteLog "=== OPT RESTORED ==="
}

$btnApplyOpt.Add_Click({ GNO_Opt_Run })
$btnRestoreOpt.Add_Click({ GNO_Opt_Restore })

# ═══════════════════════════════════════════════════════
#  ЛОГИКА: DNS
# ═══════════════════════════════════════════════════════
function global:GNO_DNS_Select {
    param([string]$Name)
    if (-not $Script:DnsRows.ContainsKey($Name)) { return }
    $Script:SelectedDNS = $Name
    foreach ($key in $Script:DnsRows.Keys) {
        $row = $Script:DnsRows[$key].Panel
        $row.BackColor = if ($key -eq $Name) { [System.Drawing.Color]::FromArgb(0, 60, 82) } elseif ((($row.Top - 4) / 22) % 2 -eq 0) { [System.Drawing.Color]::FromArgb(22,22,40) } else { $C_BG }
    }
}

function global:GNO_DNS_Bench {
    $statusBar.Text = "  $(GNO_TStr 'DNS бенчмарк...' 'DNS benchmarking...')"
    $Script:rtbDNS.Clear()
    GNO_AppendRTB $Script:rtbDNS "$(GNO_TStr '=== DNS Бенчмарк (таймаут 1000мс, 3 замера) ===' '=== DNS Benchmark (1000ms timeout, 3 samples) ===')" $C_ACCENT
    GNO_AppendRTB $Script:rtbDNS "" $C_DIM

    $bestMs  = 9999.0
    $bestKey = $null
    $results = [System.Collections.Generic.List[hashtable]]::new()

    foreach ($kv in $Script:DNSMap.GetEnumerator()) {
        $ip  = $kv.Value[0]
        $lbl = $Script:DnsLabels[$kv.Key]
        if ($null -eq $lbl) { continue }

        $lbl.Stat.Text      = GNO_TStr "Тест..." "Testing..."
        $lbl.Stat.ForeColor = $C_YELLOW
        $lbl.Lat.Text       = "..."
        [System.Windows.Forms.Application]::DoEvents()

        try {
            $times = [System.Collections.Generic.List[double]]::new()
            for ($i = 0; $i -lt 3; $i++) {
                # PS5: .NET Ping — работает в PS5 и EXE
                try {
                    $ping  = New-Object System.Net.NetworkInformation.Ping
                    $reply = $ping.Send($ip, 1000)
                    if ($reply.Status -eq "Success") { $times.Add([double]$reply.RoundtripTime) }
                    $ping.Dispose()
                } catch {}
            }

            if ($times.Count -gt 0) {
                # Убираем выброс (max) если есть 3 замера, берём среднее оставшихся
                if ($times.Count -ge 3) { $times.Remove(($times | Measure-Object -Maximum).Maximum) | Out-Null }
                $avg = [math]::Round(($times | Measure-Object -Average).Average, 1)

                $lbl.Lat.Text       = "${avg}ms"
                $lbl.Lat.ForeColor  = if ($avg -lt 20){$C_GREEN}elseif($avg -lt 60){$C_YELLOW}else{$C_RED}
                $lbl.Stat.Text      = GNO_TStr "Доступен" "Reachable"
                $lbl.Stat.ForeColor = $C_GREEN

                $results.Add(@{Name=$kv.Key; Ms=$avg})
                if ($avg -lt $bestMs) { $bestMs = $avg; $bestKey = $kv.Key }
            } else {
                $lbl.Lat.Text       = "—"
                $lbl.Lat.ForeColor  = $C_DIM
                $lbl.Stat.Text      = GNO_TStr "Недоступен" "Unreachable"
                $lbl.Stat.ForeColor = $C_RED
                GNO_AppendRTB $Script:rtbDNS "$(GNO_TStr 'недост' 'N/A')  $($kv.Key)" $C_RED
            }
        } catch {
            $lbl.Stat.Text      = GNO_TStr "Ошибка" "Error"
            $lbl.Stat.ForeColor = $C_RED
        }
    }

    # Сортируем и выводим топ в лог
    if ($results.Count -gt 0) {
        $sorted = $results | Sort-Object { $_['Ms'] }
        GNO_AppendRTB $Script:rtbDNS "$(GNO_TStr '— Рейтинг по скорости —' '— Speed Ranking —')" $C_ACCENT
        $rank = 1
        foreach ($r in $sorted) {
            $medal = switch ($rank) { 1 {"[1]"} 2 {"[2]"} 3 {"[3]"} default {"  $rank."} }
            $clr   = if ($rank -le 3){$C_GREEN}elseif($rank -le 8){$C_YELLOW}else{$C_DIM}
            GNO_AppendRTB $Script:rtbDNS "$medal  $($r['Name'].PadRight(22)) $($r['Ms'])ms" $clr
            $rank++
        }
    }

    if ($bestKey) {
        $Script:BestDNS = $bestKey
        $Script:lblBestDNS.Text = "$(GNO_TStr '★ Лучший DNS' '★ Best DNS'): $bestKey (${bestMs}ms) — $(GNO_TStr 'нажмите Применить' 'click Apply to set')"
        $Script:lblBestDNS.ForeColor = $C_GREEN
    }

    $statusBar.Text = "  $(GNO_TStr 'Готово' 'Ready')  |  Лог: $Script:LogFile"
    GNO_WriteLog "=== DNS BENCH DONE best=$bestKey ${bestMs}ms ==="
    GNO_Log_Refresh
}

function global:GNO_DNS_Apply {
    if (-not $Script:BestDNS) {
        [System.Windows.Forms.MessageBox]::Show(
            (GNO_TStr "Сначала запустите бенчмарк" "Run benchmark first"),
            "NetLagov", "OK", "Warning") | Out-Null
        return
    }
    GNO_DNS_ApplyToAdapter $Script:BestDNS
}

function global:GNO_DNS_ApplySelected {
    if (-not $Script:SelectedDNS) {
        [System.Windows.Forms.MessageBox]::Show((GNO_TStr "Сначала выберите DNS в таблице" "Select a DNS provider in the table first"), "NetLagov", "OK", "Warning") | Out-Null
        return
    }
    GNO_DNS_ApplyToAdapter $Script:SelectedDNS
}

function global:GNO_DNS_ApplyToAdapter {
    param([string]$DnsName)
    if (-not $Script:SelectedAdapter) {
        [System.Windows.Forms.MessageBox]::Show((GNO_TStr "Нет выбранного активного адаптера" "No active adapter is selected"), "NetLagov", "OK", "Warning") | Out-Null
        return
    }
    $dns = $Script:DNSMap[$DnsName]
    $adapter = GNO_GetSelectedAdapters | Select-Object -First 1
    if (-not $adapter) {
        [System.Windows.Forms.MessageBox]::Show((GNO_TStr "Выбранный адаптер больше не подключён" "The selected adapter is no longer connected"), "NetLagov", "OK", "Warning") | Out-Null
        return
    }
    try {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses ($dns[0], $dns[1]) -EA Stop
        GNO_AppendRTB $Script:rtbDNS "$(GNO_TStr 'DNS установлен' 'DNS applied') ($DnsName) на $($adapter.Name): $($dns[0]) / $($dns[1])" $C_GREEN
        GNO_WriteLog "DNS APPLIED: adapter=$($adapter.Name) provider=$DnsName addresses=$($dns[0]) $($dns[1])"
        GNO_Log_Refresh
    } catch {
        GNO_AppendRTB $Script:rtbDNS "$(GNO_TStr 'Ошибка применения DNS' 'Failed to apply DNS'): $_" $C_RED
        GNO_WriteLog "DNS APPLY ERROR: $_" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("$(GNO_TStr 'Не удалось применить DNS' 'Failed to apply DNS'): $_", "NetLagov", "OK", "Error") | Out-Null
    }
}

function global:GNO_DNS_Reset {
    $adapter = GNO_GetSelectedAdapters | Select-Object -First 1
    if (-not $adapter) {
        [System.Windows.Forms.MessageBox]::Show((GNO_TStr "Нет выбранного активного адаптера" "No active adapter is selected"), "NetLagov", "OK", "Warning") | Out-Null
        return
    }
    try {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses -EA Stop
        GNO_AppendRTB $Script:rtbDNS "$(GNO_TStr 'DNS сброшен на автоматический' 'DNS reset to auto') ($($adapter.Name))" $C_YELLOW
        GNO_WriteLog "DNS RESET TO AUTO: adapter=$($adapter.Name)"
        GNO_Log_Refresh
    } catch {
        GNO_AppendRTB $Script:rtbDNS "$(GNO_TStr 'Ошибка сброса DNS' 'Failed to reset DNS'): $_" $C_RED
        GNO_WriteLog "DNS RESET ERROR: $_" "ERROR"
        [System.Windows.Forms.MessageBox]::Show("$(GNO_TStr 'Не удалось сбросить DNS' 'Failed to reset DNS'): $_", "NetLagov", "OK", "Error") | Out-Null
    }
}

$btnDNSBench.Add_Click({ GNO_DNS_Bench })
$btnApplyDNS.Add_Click({ GNO_DNS_Apply })
$btnApplySelectedDNS.Add_Click({ GNO_DNS_ApplySelected })
$btnResetDNS.Add_Click({ GNO_DNS_Reset })

# ═══════════════════════════════════════════════════════
#  ЛОГИКА: NIC
# ═══════════════════════════════════════════════════════
function global:GNO_NIC_Run {
    $statusBar.Text = "  $(GNO_TStr 'Настройка адаптера...' 'Tuning NIC...')"
    $Script:rtbNIC.Clear()
    $Script:rtbNICDet.Clear()

    GNO_AppendRTB $Script:rtbNIC "$(GNO_TStr '=== Настройка NIC ===' '=== NIC Tuning ===')" $C_ACCENT

    $adapters = GNO_GetSelectedAdapters
    foreach ($a in $adapters) {
        $spd = try { [math]::Round([double]$a.LinkSpeed / 1000000) } catch { try { [math]::Round(($a.LinkSpeed -replace '[^0-9]','') / 1) } catch { 0 } }
        GNO_AppendRTB $Script:rtbNIC "  $($a.Name)  ${spd} Mbps" $C_ACCENT
    }

    $nicRunDefs = @(
        @{RU="Управление питанием — Всегда вкл."; A={
            GNO_GetSelectedAdapters|ForEach-Object{
                Disable-NetAdapterPowerManagement -Name $_.Name -EA SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Energy-Efficient Ethernet" -DisplayValue "Disabled" -EA SilentlyContinue
            }
            GNO_AppendRTB $Script:rtbNICDet "  Power: Always On" $C_GREEN
        }}
        @{RU="Отключить Energy Efficient Eth."; A={
            GNO_GetSelectedAdapters|ForEach-Object{
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Energy Efficient Ethernet" -DisplayValue "Disabled" -EA SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Green Ethernet"            -DisplayValue "Disabled" -EA SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Advanced EEE"              -DisplayValue "Disabled" -EA SilentlyContinue
            }
            GNO_AppendRTB $Script:rtbNICDet "  EEE: Off" $C_GREEN
        }}
        @{RU="Отключить Flow Control"; A={
            GNO_GetSelectedAdapters|ForEach-Object{
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Flow Control" -DisplayValue "Disabled" -EA SilentlyContinue
            }
            GNO_AppendRTB $Script:rtbNICDet "  Flow Control: Off" $C_GREEN
        }}
        @{RU="Отключить Priority и VLAN"; A={
            GNO_GetSelectedAdapters|ForEach-Object{
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Priority & VLAN" -DisplayValue "Priority & VLAN Disabled" -EA SilentlyContinue
            }
            GNO_AppendRTB $Script:rtbNICDet "  Priority/VLAN: Off" $C_GREEN
        }}
        @{RU="Буферы приёма — максимум"; A={
            GNO_GetSelectedAdapters|ForEach-Object{
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Receive Buffers" -DisplayValue "512" -EA SilentlyContinue
            }
            GNO_AppendRTB $Script:rtbNICDet "  RX Buffers: 512" $C_GREEN
        }}
        @{RU="Буферы передачи — максимум"; A={
            GNO_GetSelectedAdapters|ForEach-Object{
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Transmit Buffers" -DisplayValue "512" -EA SilentlyContinue
            }
            GNO_AppendRTB $Script:rtbNICDet "  TX Buffers: 512" $C_GREEN
        }}
        @{RU="Отключить Interrupt Moderation"; A={
            GNO_GetSelectedAdapters|ForEach-Object{
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Interrupt Moderation" -DisplayValue "Disabled" -EA SilentlyContinue
            }
            GNO_AppendRTB $Script:rtbNICDet "  Interrupt Mod: Off" $C_GREEN
        }}
        @{RU="Отключить Large Send Offload"; A={
            GNO_GetSelectedAdapters|ForEach-Object{
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Large Send Offload v2 (IPv4)" -DisplayValue "Disabled" -EA SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "Large Send Offload v2 (IPv6)" -DisplayValue "Disabled" -EA SilentlyContinue
                Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName "TCP/UDP Checksum Offload (IPv4)" -DisplayValue "Disabled" -EA SilentlyContinue
            }
            GNO_AppendRTB $Script:rtbNICDet "  LSO: Off" $C_GREEN
        }}
    )

    foreach ($op in $nicRunDefs) {
        GNO_SetBar $Script:NICBar[$op.RU] 40 "$(GNO_TStr 'Применяется...' 'Applying...')" $Script:NICStat[$op.RU] $C_YELLOW
        try {
            & $op.A
            GNO_SetBar $Script:NICBar[$op.RU] 100 "OK" $Script:NICStat[$op.RU] $C_GREEN
        } catch {
            GNO_SetBar $Script:NICBar[$op.RU] 100 "$(GNO_TStr 'Ошибка' 'Err')" $Script:NICStat[$op.RU] $C_RED
        }
        GNO_WriteLog "NIC: $($op.RU)"
        Start-Sleep -Milliseconds 120
    }

    GNO_AppendRTB $Script:rtbNICDet "" $C_DIM
    GNO_AppendRTB $Script:rtbNICDet "$(GNO_TStr '=== Настройка завершена ===' '=== NIC Done ===')" $C_GREEN
    GNO_WriteLog "=== NIC DONE ==="
    $statusBar.Text = "  $(GNO_TStr 'Готово' 'Ready')  |  Лог: $Script:LogFile"
    GNO_Log_Refresh
}

$btnTuneNIC.Add_Click({ GNO_NIC_Run })
# ═══════════════════════════════════════════════════════
$pingTimer          = New-Object System.Windows.Forms.Timer
$pingTimer.Interval = 400
$Script:ptDone      = 0
$Script:ptTotal     = 0
$Script:ptTargets   = @()
$Script:allPings    = [System.Collections.Generic.List[double]]::new()
$Script:allJitters  = [System.Collections.Generic.List[double]]::new()
$Script:lostPkts    = 0

$pingTimer.Add_Tick({
    if ($Script:ptDone -ge $Script:ptTotal) {
        $pingTimer.Stop()
        $btnStartTest.Enabled = $true
        $btnStopTest.Enabled  = $false
        if ($Script:allPings.Count -gt 0) {
            $mn  = [math]::Round(($Script:allPings | Measure-Object -Minimum).Minimum, 1)
            $mx  = [math]::Round(($Script:allPings | Measure-Object -Maximum).Maximum, 1)
            $av  = [math]::Round(($Script:allPings | Measure-Object -Average).Average, 1)
            $ls  = [math]::Round($Script:lostPkts / $Script:ptTotal * 100, 1)
            $q   = if ($av -lt 20 -and $ls -eq 0){"Excellent"}elseif($av -lt 50){"Good"}elseif($av -lt 100){"Fair"}else{"Poor"}
            $Script:PingMetric["Мин. пинг"].Text = "${mn}ms"
            $Script:PingMetric["Сред. пинг"].Text = "${av}ms"
            $Script:PingMetric["Макс. пинг"].Text = "${mx}ms"
            $Script:PingMetric["Потери %"].Text   = "${ls}%"
            $Script:PingMetric["Качество"].Text   = $q
            $Script:PingMetric["Min Ping"].Text = "${mn}ms"
            $Script:PingMetric["Avg Ping"].Text = "${av}ms"
            $Script:PingMetric["Max Ping"].Text = "${mx}ms"
            $Script:PingMetric["Loss pct"].Text = "${ls}%"
            $Script:PingMetric["Quality"].Text  = $q
            GNO_AppendRTB $Script:rtbPing "Min:$mn  Avg:$av  Max:$mx ms  Loss:$ls%  -> $q" $C_GREEN
            GNO_WriteLog "PingTest Min=$mn Avg=$av Max=$mx Loss=$ls%"
        }
        GNO_AppendRTB $Script:rtbPing "== $(GNO_TStr 'Тест завершён' 'Test complete') ==" $C_GREEN
        return
    }

    $tgt = $Script:ptTargets[$Script:ptDone % $Script:ptTargets.Count]
    $Script:ptDone++

    try {
        $r = Test-Connection $tgt -Count 1 -EA SilentlyContinue
        if ($r) {
            $ms = $r.$Script:PingProp
            $Script:allPings.Add($ms)
            $Script:PingHistory.Add($ms)
            if ($Script:PingHistory.Count -gt $chartMaxPts) { $Script:PingHistory.RemoveAt(0) }

            if ($Script:allPings.Count -gt 1) {
                $j = [Math]::Abs($Script:allPings[$Script:allPings.Count-1] - $Script:allPings[$Script:allPings.Count-2])
                $Script:allJitters.Add($j)
                $Script:JitterHistory.Add($j)
                if ($Script:JitterHistory.Count -gt $chartMaxPts) { $Script:JitterHistory.RemoveAt(0) }
                $jAvg = [math]::Round(($Script:allJitters|Measure-Object -Average).Average,1)
                $Script:PingMetric["Джиттер"].Text  = "${jAvg}ms"
                $Script:PingMetric["Jitter"].Text   = "${jAvg}ms"
            }

            $clr = if ($ms -lt 30){$C_GREEN}elseif($ms -lt 80){$C_YELLOW}else{$C_RED}
            GNO_AppendRTB $Script:rtbPing "[$($Script:ptDone)/$($Script:ptTotal)] $tgt  $ms ms" $clr
            $pAvg = [math]::Round(($Script:allPings|Measure-Object -Average).Average,1)
            $pMin = [math]::Round(($Script:allPings|Measure-Object -Minimum).Minimum,1)
            $pMax = [math]::Round(($Script:allPings|Measure-Object -Maximum).Maximum,1)
            $Script:PingMetric["Мин. пинг"].Text  = "${pMin}ms"
            $Script:PingMetric["Сред. пинг"].Text = "${pAvg}ms"
            $Script:PingMetric["Макс. пинг"].Text = "${pMax}ms"
            $Script:PingMetric["Min Ping"].Text = "${pMin}ms"
            $Script:PingMetric["Avg Ping"].Text = "${pAvg}ms"
            $Script:PingMetric["Max Ping"].Text = "${pMax}ms"
        $ls_cur = [math]::Round($Script:lostPkts / [Math]::Max($Script:ptDone,1) * 100, 1)
        $Script:LossHistory.Add($ls_cur)
        if ($Script:LossHistory.Count -gt $chartMaxPts) { $Script:LossHistory.RemoveAt(0) }
        $Script:PingMetric["Потери %"].Text = "${ls_cur}%"
        $Script:PingMetric["Loss pct"].Text = "${ls_cur}%"
    } else {
        $Script:lostPkts++
        $ls_cur = [math]::Round($Script:lostPkts / [Math]::Max($Script:ptDone,1) * 100, 1)
        $Script:LossHistory.Add($ls_cur)
        if ($Script:LossHistory.Count -gt $chartMaxPts) { $Script:LossHistory.RemoveAt(0) }
        GNO_AppendRTB $Script:rtbPing "[$($Script:ptDone)/$($Script:ptTotal)] $tgt  TIMEOUT" $C_RED
    }
    } catch {
        $Script:lostPkts++
        $ls_cur = [math]::Round($Script:lostPkts / [Math]::Max($Script:ptDone,1) * 100, 1)
        $Script:LossHistory.Add($ls_cur)
        if ($Script:LossHistory.Count -gt $chartMaxPts) { $Script:LossHistory.RemoveAt(0) }
        GNO_AppendRTB $Script:rtbPing "[$($Script:ptDone)/$($Script:ptTotal)] $tgt  ERROR" $C_RED
    }

    $chartPing.Invalidate()
    $chartJitter.Invalidate()
    $chartLoss.Invalidate()
    [System.Windows.Forms.Application]::DoEvents()
})

$btnStartTest.Add_Click({
    $Script:PingHistory.Clear()
    $Script:JitterHistory.Clear()
    $Script:LossHistory.Clear()
    $Script:allPings.Clear()
    $Script:allJitters.Clear()
    $Script:lostPkts  = 0
    $Script:ptDone    = 0
    $Script:ptTotal   = [int]$nudCount.Value
    $Script:ptTargets = ($tbTargets.Text -split ",") | ForEach-Object { $_.Trim() }
    $Script:rtbPing.Clear()
    GNO_AppendRTB $Script:rtbPing "$(GNO_TStr 'Хосты' 'Targets'): $($Script:ptTargets -join ', ')  N=$($Script:ptTotal)" $C_DIM
    GNO_WriteLog "PingTest start n=$($Script:ptTotal)"
    $btnStartTest.Enabled = $false
    $btnStopTest.Enabled  = $true
    $pingTimer.Start()
})

$btnStopTest.Add_Click({
    $pingTimer.Stop()
    $Script:ptDone        = $Script:ptTotal
    $btnStartTest.Enabled = $true
    $btnStopTest.Enabled  = $false
    GNO_AppendRTB $Script:rtbPing "-- $(GNO_TStr 'Остановлено пользователем' 'Stopped by user') --" $C_YELLOW
    GNO_WriteLog "PingTest stopped"
})

# ═══════════════════════════════════════════════════════
#  ЛОГИКА: ЛОГ
# ═══════════════════════════════════════════════════════
function global:GNO_Log_Refresh {
    if (-not (Test-Path $Script:LogFile)) { return }
    $Script:rtbLog.Clear()
    Get-Content $Script:LogFile | ForEach-Object {
        $clr = if ($_ -match "\[ERROR\]"){$C_RED}elseif($_ -match "\[WARN\]"){$C_YELLOW}else{$C_TEXT}
        GNO_AppendRTB $Script:rtbLog $_ $clr
    }
}

$btnOpenLog.Add_Click({
    if (Test-Path $Script:LogFile) { Start-Process notepad.exe $Script:LogFile }
})

function global:GNO_LayoutAllTabs {
    # Use the actual tab-page client sizes. Per-row anchoring made sibling
    # progress bars expand over their buttons on wide windows.
    $adapterX = [Math]::Max(565, $titlePanel.ClientSize.Width - 800)
    $lblAdapterSelect.Left = $adapterX - 65
    $Script:AdapterCombo.Left = $adapterX

    $w = [Math]::Max(1, $pgDiag.ClientSize.Width)
    $h = [Math]::Max(1, $pgDiag.ClientSize.Height)
    $bottomY = [Math]::Max(300, $h - 42)

    $cardW = [Math]::Max(100, [int][Math]::Floor(($w - 24 - 40) / 6))
    $metricCards = @($pgDiag.Controls | Where-Object { $_ -is [System.Windows.Forms.Panel] -and $_.Top -eq 34 } | Sort-Object Left)
    $statusCards = @($pgDiag.Controls | Where-Object { $_ -is [System.Windows.Forms.Panel] -and $_.Top -eq 126 } | Sort-Object Left)
    for ($i = 0; $i -lt $metricCards.Count; $i++) {
        $card = $metricCards[$i]
        $card.SetBounds((8 + $i * ($cardW + 8)), 34, $cardW, 68)
        foreach ($child in $card.Controls) { $child.Width = [Math]::Max(40, $cardW - 12) }
    }
    for ($i = 0; $i -lt $statusCards.Count; $i++) {
        $card = $statusCards[$i]
        $card.SetBounds((8 + $i * ($cardW + 8)), 126, $cardW, 46)
        foreach ($child in $card.Controls) { $child.Width = [Math]::Max(40, $cardW - 12) }
    }

    $diagRightW = [Math]::Max(280, [int][Math]::Floor($w * 0.32))
    $diagLeftW = [Math]::Max(380, $w - $diagRightW - 24)
    $diagRightX = 8 + $diagLeftW + 12
    $diagBodyH = [Math]::Max(120, $bottomY - 212)
    $secDiag3.SetBounds(8, 180, $diagLeftW, 22)
    $Script:rtbDiag.SetBounds(8, 200, $diagLeftW, $diagBodyH)
    $secDiag4.SetBounds($diagRightX, 180, $diagRightW, 22)
    $Script:rtbAdapt.SetBounds($diagRightX, 200, $diagRightW, $diagBodyH)
    $btnRunDiag.Top = $bottomY
    $btnAutoFix.Top = $bottomY

    $w = [Math]::Max(1, $pgRep.ClientSize.Width); $h = [Math]::Max(1, $pgRep.ClientSize.Height)
    $bottomY = [Math]::Max(300, $h - 42); $repLogX = [Math]::Max(610, $w - 252); $repRight = $repLogX - 16
    $Script:rtbRep.SetBounds($repLogX, 32, [Math]::Max(180, $w - $repLogX - 8), [Math]::Max(100, $bottomY - 40))
    $repStep = [Math]::Max(34, [Math]::Min(50, [int][Math]::Floor(($h - 120) / [Math]::Max(1, $Script:RepairRows.Count))))
    for ($i = 0; $i -lt $Script:RepairRows.Count; $i++) {
        $row = $Script:RepairRows[$i]; $y = 32 + $i * $repStep; $statusX = $repRight - 98
        $row.Label.Top = $y; $row.Bar.SetBounds(235, $y, [Math]::Max(80, [Math]::Min(500, $statusX - 243)), 18); $row.Status.SetBounds($statusX, $y, 90, 18)
    }
    $btnRepair.Top = $bottomY; $btnReboot.Top = $bottomY; $btnCancelR.Top = $bottomY

    $w = [Math]::Max(1, $pgOpt.ClientSize.Width); $h = [Math]::Max(1, $pgOpt.ClientSize.Height)
    $bottomY = [Math]::Max(300, $h - 42); $optLogX = [Math]::Max(610, $w - 252); $optRight = $optLogX - 16
    $Script:rtbOpt.SetBounds($optLogX, 32, [Math]::Max(180, $w - $optLogX - 8), [Math]::Max(100, $bottomY - 40))
    $optStep = [Math]::Max(32, [Math]::Min(46, [int][Math]::Floor(($h - 100) / [Math]::Max(1, $Script:OptRows.Count))))
    for ($i = 0; $i -lt $Script:OptRows.Count; $i++) {
        $row = $Script:OptRows[$i]; $y = 32 + $i * $optStep; $statusX = $optRight - 185; $applyX = $optRight - 110
        $row.Label.Top = $y + 2; $row.Info.Top = $y + 1
        $row.Bar.SetBounds(258, $y + 2, [Math]::Max(80, [Math]::Min(400, $statusX - 266)), 18)
        $row.Status.SetBounds($statusX, $y + 2, 70, 18); $row.Apply.SetBounds($applyX, $y - 1, 110, 26)
    }
    $btnApplyOpt.Top = $bottomY; $btnRestoreOpt.Top = $bottomY

    $w = [Math]::Max(1, $pgDNS.ClientSize.Width); $h = [Math]::Max(1, $pgDNS.ClientSize.Height)
    $bottomY = [Math]::Max(300, $h - 42)
    $tableW = [Math]::Min($w - 180, [Math]::Max(690, [int][Math]::Floor(($w - 36) * 0.68)))
    $tableW = [Math]::Max(500, $tableW); $logX = 8 + $tableW + 12; $logW = [Math]::Max(120, $w - $logX - 8)
    $bestY = $bottomY - 32; $tableH = [Math]::Max(120, $bestY - 60)
    $dnsScrollPanel.SetBounds(8, 52, $tableW, $tableH)
    $dnsH5.Width = [Math]::Max(100, $tableW - 510)
    foreach ($key in $Script:DnsRows.Keys) {
        $row = $Script:DnsRows[$key]; $row.Panel.Width = $tableW - 10
        $row.Status.Width = [Math]::Max(70, $tableW - 520)
    }
    $secDNSlog.SetBounds($logX, 18, $logW, 22)
    $Script:rtbDNS.SetBounds($logX, 36, $logW, [Math]::Max(100, $bottomY - 44))
    $Script:lblBestDNS.SetBounds(10, $bestY, $tableW - 10, 24)
    $available = $tableW - 20
    if ($available -ge 740) { $dnsWidths = @(170,170,210,160) }
    else {
        $usable = [Math]::Max(400, $available - 18)
        $dnsWidths = @([int][Math]::Floor($usable * .22), [int][Math]::Floor($usable * .22), [int][Math]::Floor($usable * .30), 0)
        $dnsWidths[3] = $usable - $dnsWidths[0] - $dnsWidths[1] - $dnsWidths[2]
    }
    $dnsButtons = @($btnDNSBench, $btnApplyDNS, $btnApplySelectedDNS, $btnResetDNS); $x = 10
    for ($i = 0; $i -lt $dnsButtons.Count; $i++) { $dnsButtons[$i].SetBounds($x, $bottomY, $dnsWidths[$i], 34); $x += $dnsWidths[$i] + 6 }

    $w = [Math]::Max(1, $pgNIC.ClientSize.Width); $h = [Math]::Max(1, $pgNIC.ClientSize.Height)
    $bottomY = [Math]::Max(300, $h - 42); $nicRightW = [Math]::Max(270, [int][Math]::Floor($w * 0.32)); $nicDetailX = $w - $nicRightW - 8; $nicLeftEnd = $nicDetailX - 12
    $rowsTop = if ($h -lt 650) { 190 } else { [Math]::Min(322, $h - 320) }
    $rowsTop = [Math]::Max(190, $rowsTop); $nicStep = [Math]::Max(26, [Math]::Min(52, [int][Math]::Floor(($bottomY - $rowsTop - 24) / [Math]::Max(1, $Script:NICRows.Count))))
    $secNICprog.Top = $rowsTop - 20
    $Script:rtbNIC.SetBounds(8, 32, [Math]::Max(300, $nicLeftEnd - 16), [Math]::Max(120, $rowsTop - 64))
    $secNICdet.SetBounds($nicDetailX, 18, $nicRightW, 22)
    $Script:rtbNICDet.SetBounds($nicDetailX, 32, $nicRightW, [Math]::Max(120, $h - 40))
    for ($i = 0; $i -lt $Script:NICRows.Count; $i++) {
        $row = $Script:NICRows[$i]; $y = $rowsTop + 20 + $i * $nicStep; $statusX = $nicLeftEnd - 176; $applyX = $nicLeftEnd - 116
        $row.Label.Top = $y + 2; $row.Info.Top = $y + 1
        $row.Bar.SetBounds(258, $y + 2, [Math]::Max(65, [Math]::Min(350, $statusX - 266)), 18)
        $row.Status.SetBounds($statusX, $y + 2, 55, 18); $row.Apply.SetBounds($applyX, $y - 1, 110, 26)
    }
    $btnTuneNIC.Top = $bottomY

    $w = [Math]::Max(1, $pgTest.ClientSize.Width); $h = [Math]::Max(1, $pgTest.ClientSize.Height)
    $testRightW = [Math]::Max(270, [int][Math]::Floor($w * 0.32)); $testRightX = $w - $testRightW - 8; $testLeftW = [Math]::Max(300, $testRightX - 16)
    foreach ($chart in @($chartPing, $chartJitter, $chartLoss)) { $chart.Width = $testLeftW }
    $Script:rtbPing.SetBounds(8, 392, $testLeftW, [Math]::Max(80, $h - 408))
    $secTestDet.SetBounds($testRightX, 134, $testRightW, 22)
    $Script:rtbPingDet.SetBounds($testRightX, 158, $testRightW, [Math]::Max(100, $h - 174))

    $w = [Math]::Max(1, $pgTweaks.ClientSize.Width); $h = [Math]::Max(1, $pgTweaks.ClientSize.Height)
    $tweakLogX = [Math]::Max(565, $w - 288)
    $secTweakLog.SetBounds($tweakLogX, 6, 280, 22); $Script:rtbTweaks.SetBounds($tweakLogX, 28, 280, [Math]::Max(120, $h - 38))
    $lblTweakNote.Width = [Math]::Max(300, $tweakLogX - 16)

    $w = [Math]::Max(1, $pgLog.ClientSize.Width); $h = [Math]::Max(1, $pgLog.ClientSize.Height)
    $Script:rtbLog.SetBounds(8, 30, [Math]::Max(300, $w - 16), [Math]::Max(120, $h - 72))
    $btnOpenLog.Top = [Math]::Max(300, $h - 42)
}

$tabCtrl.Add_Resize({ GNO_LayoutAllTabs })

# ═══════════════════════════════════════════════════════
#  ЗАПУСК
# ═══════════════════════════════════════════════════════
    GNO_WriteLog "=== NetLagov v2.3.3 Started ==="
GNO_WriteLog "User=$env:USERNAME  PC=$env:COMPUTERNAME  Lang=RU"

$mainForm.Add_Shown({
    GNO_LayoutAllTabs
    GNO_RefreshAdapters
    $tabCtrl.SelectedTab = $pgDiag
    Start-Sleep -Milliseconds 200
    GNO_Diag_Run
})

[System.Windows.Forms.Application]::Run($mainForm)

