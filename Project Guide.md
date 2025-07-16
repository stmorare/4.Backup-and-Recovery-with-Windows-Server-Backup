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


    

