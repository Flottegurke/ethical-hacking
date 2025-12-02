param(
    [string]$at = "Unknown Attack"
)

Add-Type -AssemblyName PresentationCore, PresentationFramework

# Ensure STA mode
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    powershell -sta -File $PSCommandPath
    exit
}


# =========================
# Window Setup
# =========================

$window = New-Object System.Windows.Window

$window.Title = "Security Alert"
$window.WindowStyle = 'None'
$window.WindowState = 'Maximized'
$window.SizeToContent = 'Manual'
$window.Width  = [System.Windows.SystemParameters]::PrimaryScreenWidth
$window.Height = [System.Windows.SystemParameters]::PrimaryScreenHeight
$window.Background = 'Black'
$window.Topmost = $true
$window.Focusable = $true
$window.ShowInTaskbar = $false
$window.Cursor = [System.Windows.Input.Cursors]::None
$window.ResizeMode = 'NoResize'
$window.IsHitTestVisible = $true
$window.AllowsTransparency = $false
$window.InputBindings.Clear()
$window.ContextMenu = $null

# Force focus
New-DispatcherTimer -Interval ([TimeSpan]::FromMilliseconds(125)) -Action {
    if ($window.IsVisible) {
        $window.Topmost = $true
        $window.Activate()
        $window.Focus()
    }
}
$window.Add_Deactivated({
    $window.Topmost = $true
    $window.Activate()
    $window.Focus()
})

$grid = New-Object System.Windows.Controls.Grid
$window.Content = $grid

# Dark translucent panel
$panel = New-Object System.Windows.Controls.Border
$panel.ContextMenu = $null
$panel.Background = "#70000000"
$panel.Padding = 60
$panel.HorizontalAlignment = "Center"
$panel.VerticalAlignment = "Center"
$panel.CornerRadius = 20
$panel.BorderBrush = "DarkRed"
$panel.BorderThickness = 4
$grid.Children.Add($panel)

# StackPanel inside panel
$stack = New-Object System.Windows.Controls.StackPanel
$stack.ContextMenu = $null
$stack.HorizontalAlignment = "Center"
$stack.VerticalAlignment = "Center"
$panel.Child = $stack


# =========================
# UI Elements
# =========================

function New-TextBlock {
    param(
        [string]$Text,
        [string]$Foreground = "White",
        [int]$FontSize = 22,
        [string]$FontWeight = "Normal",
        [string]$FontFamily = "OCR A Extended",
        [string]$Margin = "0",
        [string]$TextAlignment = "Left"
    )
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $Text
    $tb.Foreground = $Foreground
    $tb.FontSize = $FontSize
    $tb.FontWeight = $FontWeight
    $tb.FontFamily = $FontFamily
    $tb.Margin = $Margin
    $tb.TextAlignment = $TextAlignment
    $tb.TextWrapping = "Wrap"
    return $tb
}

# Header
$header = New-TextBlock -Text "SYSTEM COMPROMISED" -Foreground "Red" -FontFamily "Consolas" -FontSize 72 -FontWeight "Bold" -Margin "0,0,0,20" -TextAlignment "Center"
$header.Effect = New-Object System.Windows.Media.Effects.DropShadowEffect
$header.Effect.Color = "Red"
$header.Effect.BlurRadius = 60
$header.Effect.Opacity = 0.8
$stack.Children.Add($header)

# Description
$descriptionText = @"
Whoops - you could have been hacked just now.

This is a demonstration to raise awareness
on how easily your system could get compromised.
This script does NOT damage your computer or access your data in anny way.

=== Attack Type ===
$AttackType
"@
$description = New-TextBlock -Text "" -Margin "0,0,0,20"
$stack.Children.Add($description)

# Footer /countdown
$global:countdown = 45
$footer = New-TextBlock -Text "Wait $global:countdown seconds to regain control" -Foreground "Orange" -FontSize 24 -Margin "0,20,0,0"
$stack.Children.Add($footer)


# =========================
# Animations
# =========================

function New-DispatcherTimer {
    param(
        [TimeSpan]$Interval,
        [ScriptBlock]$Action
    )
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = $Interval
    $timer.Add_Tick($Action)
    $timer.Start()
    return $timer
}

# Typewriter
$global:typeIndex = 0
$global:typeDone = $false
$typedText = $descriptionText.ToCharArray()

$typeTimer = New-Object System.Windows.Threading.DispatcherTimer
$typeTimer.Interval = [TimeSpan]::FromMilliseconds(2)
$typeTimer.Add_Tick({
    if ($global:typeIndex -lt $typedText.Length) {
        $description.Text += $typedText[$global:typeIndex]
        $global:typeIndex++
    }
    else {
        $global:typeDone = $true
        $typeTimer.Stop()
        $glitchTimer.Start()
    }
})

# Cursed text
$cursedChars = @('@', '%', '?', '#', '*', '/', '~', '}', '[', '!', '{')
$glitchTimer = New-DispatcherTimer -Interval ([TimeSpan]::FromMilliseconds(120)) -Action {
    if (-not $typeDone) { return }

    $chars = $typedText.Clone()
    for ($i = 0; $i -lt $chars.Length; $i++) {
        if ((Get-Random -Minimum 0.0 -Maximum 1.0) -lt 0.01) {
            $chars[$i] = $cursedChars | Get-Random
        }
    }
    $description.Text = -join $chars
}

# Countdown
$cdTimer = New-DispatcherTimer -Interval ([TimeSpan]::FromSeconds(1)) -Action {
    if ($global:countdown -gt 0) {
        $global:countdown--
        $footer.Text = "Wait $global:countdown seconds to regain control"
    } else {
        $footer.Text = "Press 'R' to regain controll"
        $cdTimer.Stop()
    }
}

# Header flicker
New-DispatcherTimer -Interval ([TimeSpan]::FromMilliseconds(60)) -Action {
    $header.Opacity = Get-Random -Minimum 0.6 -Maximum 1.0
}

# Background flicker
New-DispatcherTimer -Interval ([TimeSpan]::FromMilliseconds(240)) -Action {
    $level = Get-Random -Minimum 0 -Maximum 50
    $window.Background = "#FF$([Convert]::ToString(20+$level,16).PadLeft(2,'0'))0000"
}


# =========================
# Keyboard Handling
# =========================

$window.Add_KeyDown({
    param($sender, $event)

    if ($event.Key -eq [System.Windows.Input.Key]::R) {
        $window.Close()
    }

    $event.Handled = $true
})

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Taskbar {
    [DllImport("user32.dll")]
    public static extern int FindWindow(string className, string windowText);

    [DllImport("user32.dll")]
    public static extern int ShowWindow(int hwnd, int command);
}
"@


# =========================
# Sound
# =========================

# Volume controll
$audio = New-Object -ComObject WScript.Shell
function Set-VolumeMax {
    for ($i=0; $i -lt 50; $i++) {
        $audio.SendKeys([char]175)
    }
}

# Decode and play sound
$base64Audio = @"
"@
$audioBytes = [Convert]::FromBase64String($base64Audio)
$ms = New-Object System.IO.MemoryStream
$ms.Write($audioBytes, 0, $audioBytes.Length)
$ms.Position = 0
$sound = New-Object System.Media.SoundPlayer $ms


# =========================
# Start UI
# =========================

# Prevent closing until timer ends
$window.Add_Closing({
    param($s,$e)
    if ($global:countdown -gt 0) { $e.Cancel = $true }
})

#Max volume
Set-VolumeMax

# Hide taskbar
$hwnd = [Taskbar]::FindWindow("Shell_TrayWnd", "")
[Taskbar]::ShowWindow($hwnd, 0)  # SW_HIDE

# Play sound
$sound.Play()

# Delay timer
$delayTimer = New-Object System.Windows.Threading.DispatcherTimer
$delayTimer.Interval = [TimeSpan]::FromSeconds(6)
$delayTimer.Add_Tick({
    $delayTimer.Stop()
    $typeTimer.Start()
})
$delayTimer.Start()

# Restore default state after closing
$window.Add_Closed({
    [Taskbar]::ShowWindow($hwnd, 5)

    $glitchTimer.Stop()
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.InvokeShutdown()
})
# Show window
$window.Opacity = 0
$window.Show()
$window.Activate()
$window.Focus()
# Fade in
New-DispatcherTimer -Interval ([TimeSpan]::FromMilliseconds(16)) -Action {
    if ($window.Opacity -lt 1) {
        $window.Opacity += 0.05
    }
}
[System.Windows.Threading.Dispatcher]::Run()
