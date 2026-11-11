param(
    [Parameter(Mandatory)]
    [ValidateSet('P01','P02','P03','P04','P05')]
    [string]$Participant,
    [ValidateSet('First','Retest')]
    [string]$Round = 'First',
    [ValidateSet('Campaign','Fengxi')]
    [string]$Scenario = 'Campaign',
    [string]$Executable = (Join-Path $PSScriptRoot '../Windows/Fengyun.exe'),
    [string]$ReportDirectory = (Join-Path $PSScriptRoot '../verification/playtest/sessions')
)

$ErrorActionPreference = 'Stop'
$Executable = (Resolve-Path -LiteralPath $Executable).Path
$version = (Get-Item -LiteralPath $Executable).VersionInfo.ProductVersion
$hash = (Get-FileHash -LiteralPath $Executable -Algorithm SHA256).Hash
$directory = (New-Item -ItemType Directory -Force -Path (
    Join-Path $ReportDirectory "$Participant-$Round-$Scenario")).FullName
$manifestPath = Join-Path $directory 'session.json'
$sessionLock = [IO.File]::Open((Join-Path $directory 'session.lock'),
    [IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)

try {
    if (Test-Path -LiteralPath $manifestPath) {
        $session = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        if ($session.SHA256 -ne $hash) {
            throw 'This session is pinned to another build. Use its original EXE to resume, or select the Retest round.'
        }
        if ($session.Profile -cnotmatch '^playtest_[a-z0-9_]+$') {
            throw 'The stored profile is not a playtest profile.'
        }
    }
    else {
        $id = [Guid]::NewGuid().ToString('N').Substring(0,12)
        $session = [pscustomobject]@{
            Participant = $Participant
            Round = $Round
            Scenario = $Scenario
            Profile = "playtest_$($Participant.ToLowerInvariant())_$id"
            ProductVersion = $version
            SHA256 = $hash
        }
        $session | ConvertTo-Json | Set-Content -LiteralPath $manifestPath -Encoding utf8
    }
    $formPath = Join-Path $directory '记录表.md'
    if (-not (Test-Path -LiteralPath $formPath)) {
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot '../verification/playtest/player-form.md') -Destination $formPath
    }

    $started = [DateTime]::UtcNow
    $name = $started.ToString("yyyyMMdd-HHmmss-fff'Z'")
    $log = Join-Path $directory "$name-game.log"
    Write-Host "$Participant | $Round | $Scenario | $version"
    Write-Host "Record: $formPath"
    $game = Start-Process -FilePath $Executable -WorkingDirectory ([IO.Path]::GetTempPath()) -ArgumentList @(
        '--log-file', ('"{0}"' -f $log), '--', "--profile=$($session.Profile)"
    ) -PassThru -Wait
    $ended = [DateTime]::UtcNow
    [pscustomobject]@{
        StartedUtc = $started.ToString('o')
        EndedUtc = $ended.ToString('o')
        ElapsedSeconds = [Math]::Round(($ended - $started).TotalSeconds,1)
        ExitCode = $game.ExitCode
        Log = Split-Path $log -Leaf
    } | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $directory "$name-run.json") -Encoding utf8
    if ($game.ExitCode -ne 0) {
        throw "Game exit code $($game.ExitCode). See $log."
    }
}
finally {
    $sessionLock.Dispose()
}
