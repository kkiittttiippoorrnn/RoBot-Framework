<#
.SYNOPSIS
    ปิด POS ที่ automation เปิดไว้ แล้วค้าง (orphan)

.DESCRIPTION
    POS เปิดตัวเองซ้ำเป็นทอด ๆ: process ที่ Robot เปิดจะปิดตัวเองไป
    เหลือ process ตัวจริงที่ถือหน้าต่างอยู่โดยไม่มี parent แล้ว
    สคริปต์นี้ปิดเฉพาะ process แบบนั้นทีละ PID (ไม่ใช้ taskkill /IM)
    จึงไม่ไปปิด POS ที่คนเปิดใช้งานอยู่

    เรียกจาก keyword Close POS (resources/keywords/login.resource)

.PARAMETER ProcessName
    ชื่อไฟล์ process เช่น IG.MainMDI.exe (มาจาก POS_APP_EXE_NAME ใน .env)

.OUTPUTS
    exit 0 = ไม่มี process ค้าง
    exit 1 = ปิดแล้วยังค้างอยู่
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProcessName
)

# process ชื่อนี้ที่ parent ไม่อยู่แล้ว
function Get-OrphanedProcess {
    param([string]$Name)
    Get-CimInstance Win32_Process -Filter "Name='$Name'" | Where-Object {
        -not (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.ParentProcessId)" -ErrorAction SilentlyContinue)
    }
}

$victims = Get-OrphanedProcess -Name $ProcessName
if ($victims) {
    foreach ($victim in $victims) {
        Write-Output "close_pos.ps1: closing orphaned $ProcessName (PID $($victim.ProcessId))"
        taskkill /PID $victim.ProcessId /F | Out-Null
    }
} else {
    Write-Output "close_pos.ps1: no orphaned $ProcessName process found."
}

# เช็คซ้ำว่าปิดหมดจริง
$remaining = Get-OrphanedProcess -Name $ProcessName
if ($remaining) {
    $remainingIds = ($remaining | Select-Object -ExpandProperty ProcessId) -join ', '
    Write-Error "close_pos.ps1: cleanup verification failed - orphaned $ProcessName still running (PID: $remainingIds)"
    exit 1
}

Write-Output "close_pos.ps1: cleanup verified - no orphaned $ProcessName process remains."
exit 0
