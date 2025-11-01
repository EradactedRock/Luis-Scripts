#This script lists all printers installed on the local machine. It can optionally save the output to a specified file.

param (
    [string]$OutputFile
)

$ComputerName = $env:COMPUTERNAME
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Get all printer ports to extract IP addresses
$ports = Get-PrinterPort

# Get all printers and enrich with IP info
$printers = Get-Printer | ForEach-Object {
    $port = $ports | Where-Object { $_.Name -eq $_.PortName }
    [PSCustomObject]@{
        ComputerName = $ComputerName
        Name         = $_.Name
        DriverName   = $_.DriverName
        PortName     = $_.PortName
        PrinterHost  = if ($port) { $port.HostAddress } else { "N/A" }
        Shared       = $_.Shared
        Published    = $_.Published
    }
}

if ($OutputFile -and $OutputFile.Trim() -ne "") {
    $folder = Split-Path $OutputFile
    if (-not (Test-Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force
    }

    Add-Content -Path $OutputFile -Value "[$Timestamp] Printer list from $ComputerName"
    $printers | Out-File -FilePath $OutputFile -Append -Encoding UTF8
    Write-Output "Printer list saved to $OutputFile"
} else {
    $printers | Format-Table -AutoSize
}