$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) { Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Definition)`"" -Verb RunAs -WorkingDirectory (Split-Path -Parent $MyInvocation.MyCommand.Definition); exit }

$timestamp = Get-Date -Format "HHmmss_ddMMyy"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$out = Join-Path $scriptDir "Especificaciones_$timestamp.txt"
$sep = "======================================================================="

if (Test-Path $out) { Remove-Item $out -Force }

function Escribir { param([string]$texto); $texto | Out-File $out -Encoding UTF8 -Append }
function Progreso { param([int]$step, [string]$activity); $percent = [math]::Round(($step / 10) * 100); Write-Progress -Activity "Recopilando informacion del sistema..." -Status $activity -PercentComplete $percent }

$paso = 0

Escribir "==================================="
Escribir "     ESPECIFICACIONES COMPLETAS     "
Escribir "Archivo: $out"
Escribir "==================================="

$paso++; Progreso $paso "Motherboard"
Escribir ""
Escribir $sep
Escribir "[ MOTHERBOARD ]"
Get-WmiObject Win32_BaseBoard | Format-List Manufacturer,Product,SerialNumber | Out-String | ForEach-Object {$_.TrimEnd()} | Out-File $out -Encoding UTF8 -Append

$paso++; Progreso $paso "CPU / Procesador"
Escribir $sep
Escribir ""
Escribir $sep
Escribir "[ CPU / PROCESADOR ]"
Get-WmiObject Win32_Processor | Format-List Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed | Out-String | ForEach-Object {$_.TrimEnd()} | Out-File $out -Encoding UTF8 -Append

$paso++; Progreso $paso "Memoria RAM"
Escribir $sep
Escribir ""
Escribir $sep
Escribir "[ RAM TOTAL ]"
$ram = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory
Escribir ("Total RAM = " + [math]::Round($ram/1GB,2) + " GB")
$slots = (Get-WmiObject Win32_PhysicalMemoryArray).MemoryDevices
$modules = @(Get-WmiObject Win32_PhysicalMemory).Length
if ($modules -eq $null) { $modules = 1 }
Escribir ("Slots = " + $slots)
Escribir ("Usados = " + $modules)

Escribir ""
Escribir "[ MODULOS DE RAM ]"
Get-WmiObject Win32_PhysicalMemory | Format-List Manufacturer,Capacity,Speed,MemoryType,FormFactor,PartNumber | Out-String | ForEach-Object {$_.TrimEnd()} | Out-File $out -Encoding UTF8 -Append

$paso++; Progreso $paso "Tarjetas Gráficas"
Escribir $sep
Escribir ""
Escribir $sep
Escribir "[ TARJETAS GRAFICAS ]"
Get-WmiObject Win32_VideoController | Format-List Name,DriverVersion,AdapterRAM | Out-String | ForEach-Object {$_.TrimEnd()} | Out-File $out -Encoding UTF8 -Append

$paso++; Progreso $paso "Discos / Unidades"
Escribir $sep
Escribir ""
Escribir $sep
Escribir "[ DISCOS / UNIDADES ]"
$disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3"
foreach ($disk in $disks) {
    $used = [math]::Round(($disk.Size - $disk.FreeSpace)/1GB, 2)
    $total = [math]::Round($disk.Size/1GB, 2)
    $free = [math]::Round(($disk.FreeSpace/($disk.Size))*100, 1)
    Escribir ("Unidad: " + $disk.Name)
    Escribir ("Capacidad: " + $used + "GB / " + $total + "GB (Libre: " + $free + "%)")
    Escribir ""
}

$paso++; Progreso $paso "BIOS / UEFI"
Escribir $sep
Escribir ""
Escribir $sep
Escribir "[ BIOS / UEFI ]"
Get-WmiObject Win32_BIOS | Format-List Manufacturer,Name,Version,ReleaseDate | Out-String | ForEach-Object {$_.TrimEnd()} | Out-File $out -Encoding UTF8 -Append

$paso++; Progreso $paso "SecureBoot / TPM"
Escribir ""
Escribir "[ SECURE BOOT / TPM ]"
try { 
    $sb = Confirm-SecureBootUEFI
    Escribir ("SecureBoot: " + $sb) 
} catch { 
    Escribir "SecureBoot: No disponible/No UEFI"
}
$tpmReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\TPM" -ErrorAction SilentlyContinue
if ($tpmReg) { 
    Escribir "TPM 2.0: Detectado"
} else { 
    Escribir "TPM 2.0: No detectado"
}

$paso++; Progreso $paso "Windows / Sistema Operativo"
Escribir $sep
Escribir ""
Escribir $sep
Escribir "[ WINDOWS / SISTEMA OPERATIVO ]"
Get-WmiObject Win32_OperatingSystem | Format-List Caption,Version,BuildNumber,OSArchitecture | Out-String | ForEach-Object {$_.TrimEnd()} | Out-File $out -Encoding UTF8 -Append

$paso++; Progreso $paso "Información de Licencia"
Escribir $sep
Escribir ""
Escribir $sep
Escribir "[ DETALLES DE LICENCIA - SLMGR ]"
(cscript //Nologo "C:\Windows\System32\slmgr.vbs" /dlv) | Out-String | ForEach-Object {$_.TrimEnd()} | Out-File $out -Encoding UTF8 -Append

$paso++; Progreso $paso "Finalizando..."
Escribir $sep
Escribir ""
Escribir "==================================="
Escribir "Script by @mikenagarian"
Escribir "==================================="

Write-Progress -Activity "Recopilando informacion del sistema..." -Completed
Write-Host "`n========== PROCESO COMPLETADO SCRIPT BY MIKE NAGARIAN ==========" -ForegroundColor Green
Write-Host "Archivo guardado en: $out" -ForegroundColor Cyan
Write-Host "Presione cualquier tecla para cerrar..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
