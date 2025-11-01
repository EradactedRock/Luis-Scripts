# This script removes printers whose PortName contains specific IPs.
# Supports dry-run mode to preview actions without making changes.
# To enable dry-run mode, run the script with: -DryRun
# Example: .\RemovePrinters_Port.ps1 -DryRun
#The Err0r Codes are as follows:
# 0 - Success: Printers removed without errors
# 1 - Failure: At least one error occurred during removal
# 2 - No Action Needed: No printers matched the criteria for removal

param (
    [switch]$DryRun
)

# Define target IPs (used to match inside PortName)
$targetIPs = @("x.x.x.x", "x.x.x.x")

# Define log file path
$logPath = Join-Path $env:ProgramData "PrinterRemovalLogs\printer_cleanup.log"
$logFolder = Split-Path $logPath

# Ensure log folder exists
if (-not (Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force
}

# Get all printers
$printers = Get-Printer

$removedCount = 0
$skippedCount = 0
$errorCount = 0
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Add-Content -Path $logPath -Value "[$timestamp] Starting printer cleanup. DryRun: $DryRun"

foreach ($printer in $printers) {
    $portName = $printer.PortName
    $match = $targetIPs | Where-Object { $portName -like "*$_*" }

    if ($match) {
        $msg = "[$timestamp] Match found: $($printer.Name) (Port: $portName)"
        if ($DryRun) {
            $msg += " - Dry run, not removed"
        } else {
            try {
                Remove-Printer -Name $printer.Name -ErrorAction Stop
                $msg += " - Removed"
                $removedCount++
            } catch {
                $msg += " - Error: $($_.Exception.Message)"
                $errorCount++
            }
        }
    } else {
        $msg = "[$timestamp] Skipped: $($printer.Name) (Port: $portName)"
        $skippedCount++
    }

    Add-Content -Path $logPath -Value $msg
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$summary = "[$timestamp] Cleanup complete. Removed: $removedCount, Skipped: $skippedCount, DryRun: $DryRun"
Add-Content -Path $logPath -Value $summary

# Determine exit code
if ($removedCount -gt 0 -and $errorCount -eq 0) {
    $exitCode = 0  # Success: printers removed without errors
} elseif ($errorCount -gt 0) {
    $exitCode = 1  # Failure: at least one error occurred
} else {
    $exitCode = 2  # No printers removed (no action needed)
}

$exitMsg = "[$timestamp] Exit code: $exitCode"
Add-Content -Path $logPath -Value $exitMsg
exit $exitCode