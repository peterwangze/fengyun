param(
    [string]$Executable = (Join-Path $PSScriptRoot '../Windows/Fengyun.exe'),
    [string]$ReportDirectory = (Join-Path $PSScriptRoot '../verification'),
    [switch]$LaterChapters,
    [switch]$Expansion,
    [switch]$Tidal
)
$ErrorActionPreference = 'Stop'
$Executable = (Resolve-Path -LiteralPath $Executable).Path
$versionInfo = (Get-Item -LiteralPath $Executable).VersionInfo
if (-not $PSBoundParameters.ContainsKey('Expansion')) { $Expansion = $versionInfo.ProductMajorPart -ge 2 }
$ReportDirectory = (New-Item -ItemType Directory -Path $ReportDirectory -Force).FullName
$profile = 'qa_packaged_' + [Guid]::NewGuid().ToString('N').Substring(0, 10)
$godotSaveDirectory = Join-Path $env:APPDATA 'Godot/app_userdata/风云：山河劫'
$savePath = Join-Path $godotSaveDirectory "jianghu-$profile.json"
$log = Join-Path $ReportDirectory 'windows-run.log'

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class FengyunTestKeyboard {
    [StructLayout(LayoutKind.Sequential)] public struct Rect { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr window, out Rect rect);
    [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr window, out Rect rect);
    [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr window, IntPtr target, uint flags);
    [DllImport("user32.dll")] public static extern uint MapVirtualKey(uint key, uint mode);
    [DllImport("user32.dll", SetLastError = true)] public static extern bool PostMessage(IntPtr window, uint message, UIntPtr key, IntPtr state);
    public static bool GetPhysicalWindowRect(IntPtr window, out Rect rect) {
        var prior = SetThreadDpiAwarenessContext(new IntPtr(-4));
        try { return GetWindowRect(window, out rect); }
        finally { if (prior != IntPtr.Zero) SetThreadDpiAwarenessContext(prior); }
    }
    public static void Tap(IntPtr window, byte key, int duration) {
        int scan = (int) MapVirtualKey(key, 0);
        int extended = key >= 0x25 && key <= 0x28 ? (1 << 24) : 0;
        int flags = 1 | (scan << 16) | extended;
        if (!PostMessage(window, 0x0100, new UIntPtr(key), new IntPtr(flags))) {
            throw new InvalidOperationException("Could not deliver key down.");
        }
        System.Threading.Thread.Sleep(duration);
        if (!PostMessage(window, 0x0101, new UIntPtr(key), new IntPtr(flags | unchecked((int)0xC0000000)))) {
            throw new InvalidOperationException("Could not deliver key up.");
        }
    }
    public static void Click(IntPtr window, int x, int y) {
        Rect rect;
        if (!GetClientRect(window, out rect)) throw new InvalidOperationException("Cannot read client area.");
        int point = (rect.Right * x / 640) | ((rect.Bottom * y / 360) << 16);
        if (!PostMessage(window, 0x0200, UIntPtr.Zero, new IntPtr(point)) ||
            !PostMessage(window, 0x0201, new UIntPtr(1), new IntPtr(point)) ||
            !PostMessage(window, 0x0202, UIntPtr.Zero, new IntPtr(point))) {
            throw new InvalidOperationException("Could not deliver mouse click.");
        }
    }
}
"@

function Open-Game([string]$LogPath) {
    $process = Start-Process -FilePath $Executable -WorkingDirectory ([IO.Path]::GetTempPath()) -ArgumentList @(
        '--log-file', ('"{0}"' -f $LogPath), '--', "--profile=$profile"
    ) -PassThru
    try {
        for ($i = 0; $i -lt 40; $i++) {
            Start-Sleep -Milliseconds 200
            $process.Refresh()
            if ($process.HasExited) { throw "Game exited before opening a window. Exit $($process.ExitCode)." }
            if ($process.MainWindowHandle -ne 0) { break }
        }
        if ($process.MainWindowHandle -eq 0) { throw 'No game window appeared.' }
        for ($i = 0; $i -lt 30; $i++) {
            if ((Test-Path -LiteralPath $LogPath) -and (Get-Item -LiteralPath $LogPath).Length -gt 50) { break }
            Start-Sleep -Milliseconds 250
        }
        Start-Sleep -Milliseconds 650
        $process
    }
    catch {
        Close-Game $process
        throw
    }
}
function Close-Game([Diagnostics.Process]$Process) {
    if ($null -ne $Process -and -not $Process.HasExited) {
        $null = $Process.CloseMainWindow()
        if (-not $Process.WaitForExit(3000)) {
            $Process.Kill()
            $Process.WaitForExit()
        }
    }
}
function Read-Slot {
    Get-Content -Raw -LiteralPath $savePath | ConvertFrom-Json
}
function Set-ChapterFixture([int]$Chapter, [int]$Merit, [array]$Cleared, [switch]$Expanded,
        [string]$Room = '', [switch]$Finished, [hashtable]$Afterstory) {
    $fixture = @{version=1; chapter=$Chapter; tonics=7; merit=$Merit; cleared=@($Cleared);
        chest=$false; finished=[bool]$Finished; intro_seen=$true; easy=$false}
    if ($Expanded) {
        $fixture.chronicle = @{from_chapter=0; room=$Room; marks=@{}; quests=@{}; loadout=@{}}
    }
    if ($null -ne $Afterstory) { $fixture.afterstory = $Afterstory }
    [IO.File]::WriteAllText($savePath, ($fixture | ConvertTo-Json -Compress))
}
function Assert-NoRuntimeErrors([string]$LogPath) {
    if (Select-String -LiteralPath $LogPath -Pattern 'SCRIPT ERROR|Parse Error|^ERROR:' -Quiet) {
        throw "Runtime log contains errors. $LogPath"
    }
}

$game = $null
try {
    $game = Open-Game $log
    function Press-Key([byte]$Key, [int]$Duration = 75) {
        [FengyunTestKeyboard]::Tap($game.MainWindowHandle, $Key, $Duration)
        Start-Sleep -Milliseconds 105
    }

    function Save-Screenshot([string]$Name, [switch]$Direct) {
        $target = Join-Path $ReportDirectory "$Name.png"
        Add-Type -AssemblyName System.Drawing
        $answer = ''
        if (-not $Direct) {
            $desktopTool = 'D:/AI/dev_toolchain/desktop_test_tool_list/desktop-ui.cmd'
            $answer = & $desktopTool screenshot --pid $game.Id --output $target
            if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $target)) {
                $check = [Drawing.Image]::FromFile($target)
                $wideEnough = $check.Width -ge 640
                $check.Dispose()
                if ($wideEnough) { return }
            }
        }
        $window = $game.MainWindowHandle
        $rect = [FengyunTestKeyboard+Rect]::new()
        if (-not [FengyunTestKeyboard]::GetPhysicalWindowRect($window, [ref]$rect)) {
            throw "Could not read the game window bounds. $answer"
        }
        $bitmap = [Drawing.Bitmap]::new($rect.Right - $rect.Left, $rect.Bottom - $rect.Top)
        try {
            $graphics = [Drawing.Graphics]::FromImage($bitmap)
            $hdc = $graphics.GetHdc()
            try {
                if (-not [FengyunTestKeyboard]::PrintWindow($window, $hdc, 2)) {
                    throw "Could not capture the game window. $answer"
                }
            }
            finally {
                $graphics.ReleaseHdc($hdc)
                $graphics.Dispose()
            }
            $bitmap.Save($target, [Drawing.Imaging.ImageFormat]::Png)
        }
        finally { $bitmap.Dispose() }
    }

    Save-Screenshot '07-windows-title'
    if ($Expansion) {
        Press-Key 0x26
        Press-Key 0x0D
        Press-Key 0x0D
        Press-Key 0x0D
        Save-Screenshot '19-windows-fengxi-trial' -Direct
        Press-Key 0x1B
        Press-Key 0x26
        Press-Key 0x0D
        if (Test-Path -LiteralPath $savePath) { throw 'Standalone trial wrote the main slot.' }
    }
    if ($LaterChapters) {
        [FengyunTestKeyboard]::Click($game.MainWindowHandle, 126, 238)
        Start-Sleep -Milliseconds 200
    }
    else { Press-Key 0x0D }
    Press-Key 0x0D
    for ($i = 0; $i -lt 3; $i++) { Press-Key 0x0D }
    $slot = Get-Content -Raw -LiteralPath $savePath | ConvertFrom-Json
    if (-not $slot.intro_seen -or $slot.chapter -ne 0) { throw 'Starting a campaign did not save chapter one.' }

    if ($Expansion) {
        Press-Key 0x44 355
        Press-Key 0x45
        Press-Key 0x0D
        Save-Screenshot '20-windows-spar' -Direct
        for ($i = 0; $i -lt 6; $i++) {
            if ((Read-Slot).chronicle.marks.spar) { break }
            Press-Key 0x32
            Press-Key 0x0D
        }
        if (-not (Read-Slot).chronicle.marks.spar) { throw 'Opening spar did not save.' }
        Press-Key 0x0D
        Press-Key 0x44 1055
    }
    else { Press-Key 0x44 1410 }
    Press-Key 0x57 385
    Press-Key 0x45
    Press-Key 0x0D
    Press-Key 0x0D
    Save-Screenshot '08-windows-battle'
    Press-Key 0x32
    Press-Key 0x0D
    Save-Screenshot '08a-windows-effect' -Direct
    Press-Key 0x32
    Press-Key 0x0D
    Save-Screenshot '08b-windows-break' -Direct
    Press-Key 0x32
    Press-Key 0x0D
    Press-Key 0x33
    Press-Key 0x0D

    $slot = Get-Content -Raw -LiteralPath $savePath | ConvertFrom-Json
    if ($slot.cleared -notcontains 0 -or $slot.merit -ne 2) {
        Save-Screenshot 'windows-battle-failure' -Direct
        throw 'Keyboard battle did not save victory.'
    }

    Press-Key 0x0D
    Press-Key 0x44 2410
    Press-Key 0x57 900
    Press-Key 0x45
    $slot = Get-Content -Raw -LiteralPath $savePath | ConvertFrom-Json
    if ($slot.hall.room -ne 'banquet') { throw 'Could not enter the new wedding hall.' }

    if ($Expansion) {
        Press-Key 0x44 730
        Press-Key 0x45
        for ($i = 0; $i -lt 3; $i++) { Press-Key 0x0D }
        if (-not (Read-Slot).chronicle.marks.kindness) { throw 'Could not meet Kong Ci before the ceremony.' }
        Press-Key 0x44 1180
    }
    else { Press-Key 0x44 1910 }
    Press-Key 0x45
    Save-Screenshot '10-windows-wedding' -Direct
    for ($i = 0; $i -lt 3; $i++) { Press-Key 0x0D }
    Save-Screenshot '10a-windows-wedding-strike' -Direct
    Press-Key 0x0D
    Press-Key 0x0D
    $slot = Get-Content -Raw -LiteralPath $savePath | ConvertFrom-Json
    if (-not $slot.hall.wedding) { throw 'Wedding scene did not complete.' }

    Press-Key 0x53 260
    Press-Key 0x41 1610
    Press-Key 0x45
    if ((Read-Slot).hall.staff -notcontains 'maid') {
        Save-Screenshot 'windows-maid-failure' -Direct
        throw 'The maid was not evacuated.'
    }
    Press-Key 0x44 3240
    Press-Key 0x45
    $slot = Get-Content -Raw -LiteralPath $savePath | ConvertFrom-Json
    if ($slot.hall.staff.Count -ne 2 -or $slot.tonics -ne 4) {
        Save-Screenshot 'windows-servant-failure' -Direct
        throw "Expected two evacuations and four tonics. Evacuated $($slot.hall.staff -join ', '), tonics $($slot.tonics)."
    }

    Press-Key 0x44 750
    Press-Key 0x57 700
    Press-Key 0x45
    $slot = Get-Content -Raw -LiteralPath $savePath | ConvertFrom-Json
    if ($slot.hall.room -ne 'garden') { throw 'Could not enter the rear route.' }
    Save-Screenshot '11-windows-garden' -Direct
    Press-Key 0x1B
    Press-Key 0x26
    Press-Key 0x0D
    Press-Key 0x0D
    Save-Screenshot '09-windows-continue'
    Assert-NoRuntimeErrors $log
    $windowTitle = $game.MainWindowTitle
    $later = @()
    if ($LaterChapters) {
        Close-Game $game
        Set-ChapterFixture 1 4 @() -Expanded:$Expansion
        $ferryLog = Join-Path $ReportDirectory 'windows-ferry.log'
        $game = Open-Game $ferryLog
        Press-Key 0x0D
        Press-Key 0x44 590
        Press-Key 0x57 120
        Press-Key 0x45
        if (-not (Read-Slot).campaign.rope) {
            Save-Screenshot 'windows-mooring-failure' -Direct
            throw 'Could not untie the ferry.'
        }
        Press-Key 0x41 1110
        Press-Key 0x57 155
        Start-Sleep -Milliseconds 650
        Press-Key 0x45
        Start-Sleep -Milliseconds 450
        Save-Screenshot '12-windows-ferry' -Direct
        Press-Key 0x0D
        $ferry = Read-Slot
        if ($ferry.campaign.crossing -ne 'boat' -or $ferry.merit -ne 6) {
            Save-Screenshot 'windows-ferry-failure' -Direct
            throw 'Ferry did not save the west-bank landing reward.'
        }
        Press-Key 0x1B
        Press-Key 0x26
        Press-Key 0x0D
        Press-Key 0x0D
        Save-Screenshot '13-windows-west-checkpoint' -Direct
        Assert-NoRuntimeErrors $ferryLog
        $later += 'Ferry, two merit on landing, west-bank continue'
        if ($Expansion) {
            Press-Key 0x41 1195
            Press-Key 0x57 760
            Press-Key 0x45
            if ((Read-Slot).chronicle.room -ne 'inn') {
                Save-Screenshot 'windows-inn-entry-failure' -Direct
                throw 'Could not enter the west-bank inn.'
            }
            Press-Key 0x57 720
            Press-Key 0x45
            Save-Screenshot '21-windows-inn-evidence' -Direct
            Press-Key 0x0D
            Press-Key 0x0D
            if (-not (Read-Slot).chronicle.marks.ferry_evidence) { throw 'Fengxi investigation did not save.' }
            Press-Key 0x4B
            Press-Key 0x28
            Press-Key 0x28
            Press-Key 0x0D
            Save-Screenshot '22-windows-martial' -Direct
            if ((Read-Slot).chronicle.loadout.wind[0] -ne 2) { throw 'Martial preparation did not save.' }
            $later += 'West-bank inn, corroborate the orders, equip a new martial art'
        }

        Close-Game $game
        Set-ChapterFixture 4 16 @(0)
        $jailLog = Join-Path $ReportDirectory 'windows-jail.log'
        $game = Open-Game $jailLog
        Press-Key 0x0D
        Press-Key 0x57 480
        Press-Key 0x41 2080
        Press-Key 0x57 960
        Press-Key 0x45
        if ((Read-Slot).campaign.palace_room -ne 'jail') {
            Save-Screenshot 'windows-jail-door-failure' -Direct
            throw 'Could not enter the prison.'
        }
        Press-Key 0x44 2410
        Press-Key 0x57 525
        Press-Key 0x45
        Save-Screenshot '14-windows-jail' -Direct
        for ($i = 0; $i -lt 3; $i++) { Press-Key 0x0D }
        if (-not (Read-Slot).campaign.rescued) { throw 'Prison rescue did not save.' }
        Close-Game $game
        $resumeLog = Join-Path $ReportDirectory 'windows-jail-resume.log'
        $game = Open-Game $resumeLog
        Press-Key 0x0D
        Save-Screenshot '15-windows-jail-continue' -Direct
        Press-Key 0x41 155
        Press-Key 0x57 550
        Press-Key 0x45
        $jail = Read-Slot
        if (-not $jail.campaign.rescued -or $jail.campaign.palace_room -ne 'palace') {
            throw 'Rescue did not persist after relaunch and returning to the palace.'
        }
        Assert-NoRuntimeErrors $jailLog
        Assert-NoRuntimeErrors $resumeLog
        $later += 'Enter prison, free prisoner, relaunch, leave via side stair'

        Close-Game $game
        Set-ChapterFixture 5 20 @(0)
        $altarLog = Join-Path $ReportDirectory 'windows-altar.log'
        $game = Open-Game $altarLog
        Press-Key 0x0D
        Press-Key 0x44 905
        Press-Key 0x57 615
        Press-Key 0x45
        Save-Screenshot '16-windows-farewell' -Direct
        for ($i = 0; $i -lt 5; $i++) { Press-Key 0x0D }
        if (-not (Read-Slot).campaign.farewell) { throw 'Farewell did not save.' }
        Press-Key 0x57 685
        Press-Key 0x44 2290
        Press-Key 0x57 495
        Press-Key 0x45
        Save-Screenshot '17-windows-altar' -Direct
        for ($i = 0; $i -lt 3; $i++) { Press-Key 0x0D }
        if (-not (Read-Slot).campaign.altar) { throw 'Altar scene did not save.' }
        Assert-NoRuntimeErrors $altarLog
        $later += 'Play farewell and open the altar confrontation'
        if ($Expansion) {
            Close-Game $game
            Set-ChapterFixture 5 24 @(0,1) -Expanded -Room 'dawn'
            $dawnLog = Join-Path $ReportDirectory 'windows-dawn.log'
            $game = Open-Game $dawnLog
            Press-Key 0x0D
            Press-Key 0x57 425
            Press-Key 0x44 790
            Press-Key 0x45
            Press-Key 0x0D
            Press-Key 0x0D
            Save-Screenshot '23-windows-dawn' -Direct
            if (-not (Read-Slot).chronicle.marks.dawn_lamp) { throw 'Playable epilogue did not save the lit lamp.' }
            Press-Key 0x44 1235
            Press-Key 0x45
            if (-not (Read-Slot).finished) {
                Save-Screenshot 'windows-dawn-exit-failure' -Direct
                throw 'Could not leave the bridge and complete the campaign.'
            }
            Assert-NoRuntimeErrors $dawnLog
            $later += 'Playable dawn, light the lantern and complete the campaign'
        }
    }
    if ($Tidal) {
        Close-Game $game
        Set-ChapterFixture 5 24 @(0,1) -Finished
        $tidalLog = Join-Path $ReportDirectory 'windows-tidal.log'
        $game = Open-Game $tidalLog
        Press-Key 0x26
        Press-Key 0x0D
        if ((Read-Slot).afterstory.room -ne 'tidal_ford') { throw 'Old completed save could not enter Tidegate.' }
        Save-Screenshot '24-windows-tidal-ford' -Direct
        Press-Key 0x57 670
        Press-Key 0x45
        for ($i = 0; $i -lt 3; $i++) { Press-Key 0x0D }
        if (-not (Read-Slot).afterstory.brief) { throw 'Could not finish the Tidegate briefing.' }

        Press-Key 0x41 1840
        Press-Key 0x57 350
        Press-Key 0x45
        Press-Key 0x0D
        if (-not (Read-Slot).afterstory.register) {
            Save-Screenshot 'windows-tidal-register-failure' -Direct
            throw 'Could not inspect the register.'
        }
        Press-Key 0x44 3060
        Press-Key 0x45
        Press-Key 0x0D
        if (-not (Read-Slot).afterstory.seal) {
            Save-Screenshot 'windows-tidal-seal-failure' -Direct
            throw 'Could not inspect the cargo seal.'
        }
        Press-Key 0x44 560
        Press-Key 0x53 420
        Press-Key 0x45
        if (-not (Read-Slot).afterstory.sluice) { throw 'The watergate winch did not save.' }
        Press-Key 0x44 640
        Press-Key 0x57 550
        Press-Key 0x45
        $tidalSlot = Read-Slot
        if ($tidalSlot.afterstory.room -ne 'tidal_fort' -or $tidalSlot.afterstory.route -ne 'sluice') {
            Save-Screenshot 'windows-tidal-route-failure' -Direct
            throw 'Could not enter the granary from the watergate.'
        }
        Press-Key 0x41 1780
        Press-Key 0x57 180
        Press-Key 0x45
        for ($i = 0; $i -lt 3; $i++) { Press-Key 0x0D }
        Save-Screenshot '25-windows-tidal-battle' -Direct
        Press-Key 0x34
        Press-Key 0x34
        Start-Sleep -Milliseconds 740
        Save-Screenshot '26-windows-tidal-ward' -Direct
        Assert-NoRuntimeErrors $tidalLog

        Close-Game $game
        $tidalResumeLog = Join-Path $ReportDirectory 'windows-tidal-resume.log'
        $game = Open-Game $tidalResumeLog
        Press-Key 0x26
        Press-Key 0x0D
        Save-Screenshot '27-windows-tidal-resume' -Direct
        Press-Key 0x1B
        Press-Key 0x26
        Press-Key 0x0D
        if ((Read-Slot).afterstory.room -ne 'tidal_fort') { throw 'Granary checkpoint did not survive reopening.' }
        Assert-NoRuntimeErrors $tidalResumeLog
        $later += 'Old finished save, Tidegate evidence, watergate path, granary battle opening and room continue'

        Close-Game $game
        $settlementFixture = @{room='tidal_ford'; route='sluice'; tonics=2; brief=$true; register=$true;
            seal=$true; sluice=$true; gate=$false; aid=$false; chief=$true; ledger=$true; resolution=''}
        Set-ChapterFixture 5 24 @(0,1) -Finished -Afterstory $settlementFixture
        $settlementLog = Join-Path $ReportDirectory 'windows-tidal-settlement.log'
        $game = Open-Game $settlementLog
        Press-Key 0x26
        Press-Key 0x0D
        Press-Key 0x44 415
        Press-Key 0x57 970
        Press-Key 0x45
        Press-Key 0x28
        Press-Key 0x0D
        Press-Key 0x0D
        Press-Key 0x0D
        $tidalSlot = Read-Slot
        if ($tidalSlot.afterstory.resolution -ne 'witness' -or -not $tidalSlot.finished -or $tidalSlot.merit -ne 24) {
            Save-Screenshot 'windows-tidal-settlement-failure' -Direct
            throw 'Tidegate settlement did not save without changing the campaign.'
        }
        Save-Screenshot '28-windows-tidal-complete' -Direct
        Assert-NoRuntimeErrors $settlementLog
        $later += 'Tidegate settlement with ledger fixture, main campaign unchanged'
    }
    [PSCustomObject]@{
        Result = 'passed'
        Executable = $Executable
        WindowTitle = $windowTitle
        ProductVersion = $versionInfo.ProductVersion
        Tested = 'Launch, Windows keyboard, stagger tutorial, wedding scene, two evacuations, rear route entry, continue'
        Mouse = [bool]$LaterChapters
        ExpandedOpening = [bool]$Expansion
        IsolatedFengxiTrial = [bool]$Expansion
        LaterChapters = $later
        Merit = $slot.merit
        Cleared = $slot.cleared
        Checkpoint = $slot.hall.room
        Evacuated = $slot.hall.staff.Count
        Log = $log
    } | ConvertTo-Json -Depth 3
}
finally {
    Close-Game $game
    foreach ($candidate in @($savePath, "$savePath.bak", "$savePath.tmp")) {
        if (Test-Path -LiteralPath $candidate) { Remove-Item -LiteralPath $candidate }
    }
}

