<#
.SYNOPSIS
    รัน Robot Framework ด้วย venv และค่าตั้งของโปรเจกต์

.EXAMPLE
    .\run.ps1                                  # รันทุก test ใน tests/
    .\run.ps1 -Include smoke                   # เฉพาะ tag smoke
    .\run.ps1 -Exclude pending-first-run       # ข้าม test ที่ยังไม่เคยรันจริง
    .\run.ps1 -Tests tests/sales -DryRun       # เช็ค keyword/argument โดยไม่เปิด POS
    .\run.ps1 -Tests tests/receipt -Variable RECALL_SALE_NUM:RC6812230014   # ส่งตัวแปรให้ test

.NOTES
    test คุม POS บนหน้าจอจริง ห้ามแตะเมาส์/คีย์บอร์ดระหว่างรัน
    ผลรันอยู่ที่ evidence/<วันเวลา>/
#>
[CmdletBinding()]
param(
    [string[]]$Tests = @('tests'),
    [string[]]$Include = @(),
    [string[]]$Exclude = @(),
    [string[]]$Variable = @(),
    [switch]$DryRun
)

$root = $PSScriptRoot
$robot = Join-Path $root '.venv\Scripts\robot.exe'
if (-not (Test-Path $robot)) {
    Write-Error "Robot Framework not found at $robot - see README.md, Setup."
    exit 2
}

# บาง shell ตั้ง PYTHONIOENCODING=utf-8:surrogateescape ซึ่ง Robot รับไม่ได้
$env:PYTHONIOENCODING = 'utf-8'
$env:PYTHONUTF8 = '1'

$outDir = Join-Path $root ("evidence\" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$robotArgs = @('--outputdir', $outDir)
foreach ($tag in $Include) { $robotArgs += @('--include', $tag) }
foreach ($tag in $Exclude) { $robotArgs += @('--exclude', $tag) }
foreach ($var in $Variable) { $robotArgs += @('--variable', $var) }
if ($DryRun) { $robotArgs += '--dryrun' }
$robotArgs += $Tests

Push-Location $root
try {
    & $robot @robotArgs
    $rc = $LASTEXITCODE
} finally {
    Pop-Location
}
exit $rc
