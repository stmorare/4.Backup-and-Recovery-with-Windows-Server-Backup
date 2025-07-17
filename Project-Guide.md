# Backup and Recovery with Windows Server Backup 

## Objectives
- Install and configure the Windows Server Backup role on DC-00.
- Set up and verify a backup job for the replicated `C:\SalesFolder` on DC-00.
- Simulate data loss by renaming `SalesFolder` to `SalesFolder_Old` on FS-01.
- Restore data to an alternate location on DC-00 and manually copy to FS-01.
- Automate backup status checks with a PowerShell script.
- Verify the restore process on the Windows 11 client via a mapped network drive.
- Document the setup for a portfolio on GitHub.

## Tools Used
- **Windows Server 2025**: DC-00 (192.168.10.116) as backup server, FS-01 (192.168.10.117) as data source.
- **Windows 11**: Client (192.168.10.118) for restore verification.
- **PowerShell**: For automation and monitoring.
- **VMware Workstation Player**: For the existing VM environment.
- **Git Bash**: For uploading to GitHub.

## Step-by-Step Procedure

### Step 1: Prepare the Environment
1. **Verify Current Setup**:
   - Ensure DC-00, FS-01, and the client are running and joined to `mydomain.local`.
   - Confirm `C:\SalesFolder` exists on FS-01 with sample data (e.g., create `test.txt` using Notepad).
2. **Add Backup Storage**:
   - On FS-01, create `C:\BackupShare` with at least 20-30 GB free space:
     - Right-click `C:\` > **New** > **Folder** > Name it `BackupShare`.
     - Right-click `BackupShare` > **Properties** > **Sharing** > **Share** > Add `Everyone` with **Read/Write** > **Share**.
   - Map `\\FS-01\BackupShare` on DC-00:
     - **File Explorer** > **Map network drive** > **Drive**: `Z:` > **Folder**: `\\FS-01\BackupShare` > **Finish** > Use `mydomain\administrator` credentials.

### Step 2: Install Windows Server Backup on DC-00
1. **Install the Feature**:
   - Open **Server Manager** > **Manage** > **Add Roles and Features**.
   - **Role-based or feature-based installation** > **Next**.
   - Select DC-00 > Expand **Features** > Check **Windows Server Backup** > **Next** > **Install**.
   - Confirm completion.

### Step 3: Configure a Backup Job
1. **Set Up Backup Schedule**:
   - Open **Windows Server Backup** > **Local Backup** > **Backup Schedule**.
   - **Getting Started**: **Next**.
   - **Select Backup Configuration**: **Custom** > **Next**.
   - **Select Items to Backup**: Only `C:\SalesFolder` (DC-00’s replicated copy) is visible > Check it > **Next**.
     - Note: `\\FS-01\SalesFolder` was not addable due to UI limitation.
   - **Specify Destination**: Select `\\FS-01\BackupShare` > **Next**.
   - **Specify Schedule**: **Once a day at 02:00 AM** > **Next**.
   - **Select Backup Type**: Confirm `C:\SalesFolder` > **Next** > **Finish**.
2. **Run Initial Backup**:
   - Click **Backup Once** > Use latest schedule > **Next** > **Backup** > Wait 5-15 minutes.
3. **Verify Backup**:
   - Run `Monitor-Backup.ps1`:
     ```powershell
     cd C:\Scripts
     .\Monitor-Backup.ps1
     ```
   - Check `C:\Scripts\Backup_Log.txt` for “Completed” status.

### Step 4: Automate Backup Status Checks
1. **Create PowerShell Script on DC-00**:
   - Save as `C:\Scripts\Monitor-Backup.ps1` (see Monitor-Backup.ps1)

2. **Schedule the Script**:
   - Open **Task Scheduler** > **Create Task**.
   - **Name**: `Backup Monitor`.
   - **Run with highest privileges**, **Run whether user is logged on or not**.
   - **User**: `mydomain\administrator`.
   - **Triggers**: **New** > **Daily at 03:00 AM** > **OK**.
   - **Actions**: **New** > **Start a program** > Program: `powershell.exe` > Arguments: `-ExecutionPolicy Bypass -File "C:              \Scripts\Monitor-Backup.ps1"` > **OK**.
   - Enter `mydomain\administrator` password > **OK**.
   - Test by right-clicking **Run**.

### Step 5: Simulate Data Loss
1. **Rename `SalesFolder` on FS-01**:
   - On FS-01, navigate to `C:\`.
   - Right-click `SalesFolder` > **Rename** > `SalesFolder_Old` > Enter.
   - If locked, stop **DFS Replication** (**Services** > **DFS Replication** > **Stop**) and retry.

### Step 6: Restore to Original Location
1. **Open Recovery Wizard on DC-00**:
   - Click **Recover** > **This server** > **Next**.
   - **Select Backup Location**: `\\FS-01\BackupShare` > **Next**.
   - **Select Backup Date**: Latest > **Next**.
   - **Select Recovery Type**: **Files and folders** > **Next**.
   - **Select Items to Recover**: Select `C:\SalesFolder` > **Next**.
   - **Specify Recovery Options**: **Original location** > Check **Overwrite existing files** > **Next** > **Recover** > Wait 5-10 minutes.
     - Note: "Original location" worked after multiple attempts but restored to DC-00, not FS-01.
2. **Handle DFSR**:
   - Start **DFS Replication** on FS-01 (**Start**) after restore (though restore occurred on DC-00).

### Step 7: Verify and Manually Correct Restore
1. **Check DC-00**:
   - Navigate to `C:\SalesFolder` or `C:\RestoredSalesFolder` (created earlier) on DC-00.
   - Confirm restored files (e.g., `test.txt`) are present.
2. **Manually Restore to FS-01**:
   - Copy files from `C:\SalesFolder` or `C:\RestoredSalesFolder` on DC-00.
   - Navigate to `\\FS-01\C$\SalesFolder_Old` via **File Explorer**.
   - Paste files, overwriting if prompted.
   - Rename `SalesFolder_Old` to `SalesFolder` (right-click > **Rename**).
   - Stop **DFS Replication** on FS-01 (**Services** > **Stop**) before copying, then **Start** after.
3. **Map Drive on Client**:
   - On the Windows 11 client, **Map network drive** > **Drive**: `Z:` > **Folder**: `\\FS-01\SalesFolder` > **Finish** > Use `mydomain\administrator` credentials > **OK**.
   - Open `Z:\` and create `verify.txt` to test write access.

### Step 8: Document and Upload
1. **Screenshots**:
   - Backup console on DC-00.
   - `C:\SalesFolder` on FS-01 with restored files.
   - Mapped `Z:` drive on the client.
   - `C:\Scripts\Backup_Log.txt` output.
2. **GitHub Upload**:
   - **Git Bash**:
     ```bash
     cd /c/SystemAdminProjects/Backup-and-Recovery-Project
     git init
     git add .
     git commit -m "Completed Backup and Recovery Project"
     git remote add origin https://github.com/your-username/Backup-and-Recovery-Project.git
     git push -u origin main
     ```

## Screenshots
- ![Backup Once](screenshots/Backup%20Once-Successful!.png) 
- ![Sales-Folder](screenshots/SalesFolder%Mapped.png)
- ![Task-Schedule](screenshots/Schedule-the-Script-Configured.png)
- ![Script-Results](screenshots/TheScriptIsWorkingFine.png)
- ![Backup-Console](screenshots/Windows-Server-Backup-Configuration.png)
- [Permissions-Test](screenshots/verify%text%file%created%to%test%WRITE%permissions.png)


    

=======
# Step-by-Step Guide: Backup and Recovery with Windows Server Backup (Windows Server 2025)

## 1. Environment Preparation

### 1.1. Validate the Lab Setup
- Ensure **DC-00** (192.168.10.116), **FS-01** (192.168.10.117), and the **Windows 11 client** (192.168.10.118) are all running and joined to the domain `mydomain.local`.
- Confirm `C:\SalesFolder` exists on **FS-01**, and it contains test files (create a `test.txt` using Notepad if needed).

### 1.2. Add Backup Storage Target
- On **FS-01**:
  - Create a new folder: `C:\BackupShare`
  - Right-click > **Properties** > **Sharing** > **Advanced Sharing**
  - Share as `BackupShare` and give **Everyone** **Read/Write** permissions.
- On **DC-00**:
  - Map network drive:  
    - Open **File Explorer**
    - Right-click **This PC** > **Map network drive**
    - **Drive**: `Z:`
    - **Folder**: `\\FS-01\BackupShare`
    - When prompted, use domain credentials (`mydomain\administrator`).

## 2. Install Windows Server Backup on DC-00

1. Open **Server Manager** > **Manage** > **Add Roles and Features**.
2. Choose **Role-based or feature-based installation** > select your DC-00 server.
3. Under **Features**, check **Windows Server Backup** and click **Next** > **Install**.
4. Wait for the installation to complete.

## 3. Configure a Backup Job

### 3.1. Create a Backup Schedule

- On **DC-00**:
  1. Open **Windows Server Backup** (search in Start).
  2. Click **Local Backup** > **Backup Schedule** (right pane).
  3. **Getting Started**: click **Next**.
  4. **Select Backup Configuration**: choose **Custom** > **Next**.
  5. **Select Items to Backup**: add only `C:\SalesFolder`.
  6. **Specify Destination Type**: select **Remote Shared Folder** > type `\\FS-01\BackupShare`.
  7. **Specify Schedule**: set for **Once daily at 02:00 AM** (or as desired).
  8. Confirm settings and finish the wizard.

### 3.2. Run an Initial Backup Immediately

- Use **Backup Once...** from the right pane, select options from schedule, and start. Wait for backup completion.

### 3.3. Verify Backup Completion

- Open **Windows Server Backup** > select the latest backup > confirm **Status: Completed** (alternatively, check logs or use the script below).

## 4. Automate Backup Status Monitoring

### 4.1. Create Monitoring Script (`Monitor-Backup.ps1`)

Create **C:\Scripts\Monitor-Backup.ps1** with:
```powershell
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
```

### 4.2. Schedule with Task Scheduler

- Open **Task Scheduler** > **Create Task**:
  - **General**: Name = `Backup Monitor`; Run with highest privileges; set to run as `mydomain\administrator`.
  - **Triggers**: Daily at 03:00 AM.
  - **Actions**:  
    - Program/Script: `powershell.exe`
    - Add Arguments: `-ExecutionPolicy Bypass -File "C:\Scripts\Monitor-Backup.ps1"`
  - **Settings**: Check `Run task as soon as possible after a scheduled start is missed`
- Manually **Run** the task to verify it works (check `C:\Scripts\Backup_Log.txt`).

## 5. Simulate Data Loss on FS-01

1. On **FS-01**:
   - In **File Explorer**, go to `C:\`
   - Right-click `SalesFolder` > **Rename** > `SalesFolder_Old`
   - If Windows errors that the folder is in use, temporarily stop the **DFS Replication** service (`services.msc` > **DFS Replication** > **Stop Service**).
   - Try rename again; restart **DFS Replication** service once complete.

## 6. Restore Data from Backup

### 6.1. Use Windows Server Backup Recovery Wizard

- On **DC-00**:
  1. Open **Windows Server Backup** > **Local Backup** > **Recover...**
  2. **Where is the backup stored?**: Select **Another location** > set to `\\FS-01\BackupShare`
  3. **Select Backup Date**: Choose the most recent backup.
  4. **Select Recovery Type**: **Files and Folders**.
  5. **Select Items to Recover**: Drill down to select `C:\SalesFolder`.
  6. **Select Recovery Options**:
     - **Recover to Original Location** *(if available and you want to overwrite DC-00's own copy)*  
       **OR**
     - **Recover to Another Location** (e.g., `C:\RestoredSalesFolder` on DC-00).
  7. **Recover**: Start the process and wait until it’s finished.

## 7. Restore to FS-01 and Resume DFSR

1. **Manually Copy Restored Data to FS-01**:
   - On **FS-01**, stop **DFS Replication** service again.
   - Copy files from `C:\RestoredSalesFolder` (or `C:\SalesFolder`) on **DC-00** back to `C:\SalesFolder_Old` on **FS-01** (using `\\FS-01\C$\SalesFolder_Old`)
   - Rename `SalesFolder_Old` back to `SalesFolder`.
   - Make sure NTFS permissions are set as before.
   - Restart **DFS Replication** on **FS-01**.

2. **DFS will detect changes** and resync as needed.

## 8. Verify Restore on Client

- On your **Windows 11 client**:
  1. Map the network drive:
     - In File Explorer, **Map Network Drive**
     - **Drive**: Z:
     - **Folder**: `\\FS-01\SalesFolder` (or the DFS Namespace path if applicable)
     - Use domain credentials if prompted.
  2. Open `Z:\` and check for restored files (e.g., `test.txt`).
  3. Create a new file `verify.txt` to confirm write permissions.
  4. Confirm file syncs to both servers after a few minutes.

## 9. Troubleshooting Tips

| Issue | Possible Cause | Solution |
|-------|---------------|----------|
| Can't back up to share | Firewall, permissions | Ensure `BackupShare` is shared & accessible; check NTFS permissions and firewall exceptions. |
| DFSR/DFS lock on folder | Replication running | Stop DFS Replication service before renaming or overwriting SalesFolder. |
| Client can't access restored files | NTFS or share permissions | Double-check all folder permissions and user memberships. |
| Scheduled tasks/scripts don't run | Permission or path issues | Always set "Run whether user is logged on or not," check script paths, verify `C:\Scripts` exists, check logs. |

## Summary

By completing this project, you will have:
- Installed and configured reliable server-level backup on Windows Server 2025.
- Recovered mission-critical data after simulated loss.
- Automated backup status monitoring with PowerShell.
- Proven business continuity with an end-to-end restoration test.
- Documented everything with screenshots and GitHub version control—ideal for your SysAdmin portfolio!
