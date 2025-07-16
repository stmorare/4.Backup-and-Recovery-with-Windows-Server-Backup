# Check if Windows Server Backup module is available and import it
if (Get-Module -ListAvailable -Name WindowsServerBackup) {
    try {
        # Remove existing module if loaded to avoid conflicts
        if (Get-Module WindowsServerBackup) {
            Remove-Module WindowsServerBackup -Force
        }
        Import-Module WindowsServerBackup -Force -ErrorAction Stop
        Write-Host "WindowsServerBackup module loaded successfully"
        
        # Verify key cmdlets are available
        $availableCmdlets = @('Get-WBJob', 'Get-WBBackupSet', 'Get-WBSummary', 'Get-WBPolicy')
        $missingCmdlets = @()
        
        foreach ($cmdlet in $availableCmdlets) {
            if (!(Get-Command $cmdlet -ErrorAction SilentlyContinue)) {
                $missingCmdlets += $cmdlet
            }
        }
        
        if ($missingCmdlets.Count -gt 0) {
            Write-Host "Warning: Missing cmdlets: $($missingCmdlets -join ', ')" -ForegroundColor Yellow
        }
        
        # Note: Get-WBBackupStatus is not available in this version, using alternatives
        Write-Host "Note: Using Get-WBSummary and Get-WBBackupSet for backup status" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Error loading WindowsServerBackup module: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Host "Windows Server Backup module not available. Please install Windows Server Backup feature."
    exit 1
}

# Set log file and ensure directory exists
$logPath = "C:\Scripts\Backup_Log.txt"
$logDir = Split-Path $logPath -Parent
if (!(Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Function to write logs
function Write-Log {
    param([string]$Message)
    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$time - $Message" | Out-File -FilePath $logPath -Append
}

try {
    # Get backup status
    Write-Log "Checking backup status..."
    Write-Host "Checking backup status..."
    
    # Check for active backup jobs
    $backupJobs = Get-WBJob -ErrorAction SilentlyContinue
    if ($backupJobs) {
        Write-Log "Found $($backupJobs.Count) active backup job(s):"
        Write-Host "Found $($backupJobs.Count) active backup job(s):"
        
        foreach ($job in $backupJobs) {
            $jobInfo = "Job ID: $($job.JobId), State: $($job.JobState), Start: $($job.StartTime)"
            Write-Log $jobInfo
            Write-Host $jobInfo
            
            if ($job.JobState -eq "Running") {
                Write-Log "Info: Backup job is currently running"
                Write-Host "Info: Backup job is currently running"
            } elseif ($job.JobState -eq "Failed") {
                Write-Log "Warning: Backup job failed! State: $($job.JobState)"
                Write-Host "Warning: Backup job failed! State: $($job.JobState)" -ForegroundColor Red
            } elseif ($job.JobState -eq "Stopped") {
                Write-Log "Warning: Backup job was stopped! State: $($job.JobState)"
                Write-Host "Warning: Backup job was stopped! State: $($job.JobState)" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Log "No active backup jobs found."
        Write-Host "No active backup jobs found."
    }
    
    # Check last backup status using available cmdlets
    Write-Log "Checking last backup status..."
    Write-Host "Checking last backup status..."
    
    $lastBackup = $null
    $backupSummary = $null
    
    # Method 1: Try Get-WBSummary (primary method for this system)
    if (Get-Command Get-WBSummary -ErrorAction SilentlyContinue) {
        try {
            $backupSummary = Get-WBSummary -ErrorAction SilentlyContinue
            if ($backupSummary) {
                $summaryInfo = "Backup Summary - Last Backup: $($backupSummary.LastBackupTime), Result: $($backupSummary.LastBackupResultHR)"
                Write-Log $summaryInfo
                Write-Host $summaryInfo
                
                if ($backupSummary.LastBackupResultHR -eq "Success") {
                    Write-Log "Success: Last backup completed successfully"
                    Write-Host "Success: Last backup completed successfully" -ForegroundColor Green
                } elseif ($backupSummary.LastBackupResultHR) {
                    Write-Log "Warning: Last backup result: $($backupSummary.LastBackupResultHR)"
                    Write-Host "Warning: Last backup result: $($backupSummary.LastBackupResultHR)" -ForegroundColor Red
                }
                
                if ($backupSummary.NextBackupTime) {
                    $nextBackupInfo = "Next scheduled backup: $($backupSummary.NextBackupTime)"
                    Write-Log $nextBackupInfo
                    Write-Host $nextBackupInfo
                }
                
                if ($backupSummary.LastSuccessfulBackupTime) {
                    $lastSuccessInfo = "Last successful backup: $($backupSummary.LastSuccessfulBackupTime)"
                    Write-Log $lastSuccessInfo
                    Write-Host $lastSuccessInfo
                }
            }
        }
        catch {
            Write-Log "Get-WBSummary failed: $($_.Exception.Message)"
        }
    }
    
    # Method 2: Try Get-WBBackupSet for detailed backup history
    if (Get-Command Get-WBBackupSet -ErrorAction SilentlyContinue) {
        try {
            $backupSets = Get-WBBackupSet -ErrorAction SilentlyContinue
            if ($backupSets) {
                $latestBackupSet = $backupSets | Sort-Object BackupTime -Descending | Select-Object -First 1
                $backupSetInfo = "Latest backup set: $($latestBackupSet.BackupTime), Version: $($latestBackupSet.VersionId)"
                Write-Log $backupSetInfo
                Write-Host $backupSetInfo
                
                # Show recent backup history
                $recentBackups = $backupSets | Sort-Object BackupTime -Descending | Select-Object -First 5
                Write-Log "Recent backup history (last 5):"
                Write-Host "Recent backup history (last 5):" -ForegroundColor Cyan
                
                foreach ($backup in $recentBackups) {
                    $backupInfo = "  - $($backup.BackupTime) (Version: $($backup.VersionId))"
                    Write-Log $backupInfo
                    Write-Host $backupInfo
                }
            } else {
                Write-Log "No backup sets found"
                Write-Host "No backup sets found" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Log "Get-WBBackupSet failed: $($_.Exception.Message)"
        }
    }
    
    # Method 3: Check Windows Event Log as additional information
    if (!$backupSummary -and !$backupSets) {
        Write-Log "Attempting to check Windows Event Log for backup information..."
        try {
            $backupEvents = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Backup'; ID=4,8,517} -MaxEvents 10 -ErrorAction SilentlyContinue
            if ($backupEvents) {
                $latestEvent = $backupEvents | Sort-Object TimeCreated -Descending | Select-Object -First 1
                $eventInfo = "Latest backup event: $($latestEvent.TimeCreated) - $($latestEvent.LevelDisplayName) - $($latestEvent.Message)"
                Write-Log $eventInfo
                Write-Host $eventInfo
            } else {
                Write-Log "No backup events found in Windows Event Log"
                Write-Host "No backup events found in Windows Event Log"
            }
        }
        catch {
            Write-Log "Could not access Windows Event Log: $($_.Exception.Message)"
        }
    }
    
    if (!$backupSummary -and !$backupSets) {
        Write-Log "No backup status information available - backup may not be configured or no backups have been performed"
        Write-Host "No backup status information available - backup may not be configured or no backups have been performed" -ForegroundColor Yellow
    }
    
    # Check backup policy/schedule
    Write-Log "Checking backup policy..."
    Write-Host "Checking backup policy..."
    
    $backupPolicy = Get-WBPolicy -ErrorAction SilentlyContinue
    if ($backupPolicy) {
        Write-Log "Backup policy is configured"
        Write-Host "Backup policy is configured"
        
        if ($backupPolicy.Schedule) {
            $scheduleInfo = "Backup schedule: $($backupPolicy.Schedule -join ', ')"
            Write-Log $scheduleInfo
            Write-Host $scheduleInfo
        }
    } else {
        Write-Log "No backup policy configured"
        Write-Host "No backup policy configured" -ForegroundColor Yellow
    }
}
catch {
    $errorMsg = "Error: $($_.Exception.Message)"
    Write-Log $errorMsg
    Write-Host $errorMsg -ForegroundColor Red
}

Write-Log "Backup monitoring completed!"
Write-Host "Backup monitoring completed! Check $logPath for details." -ForegroundColor Cyan