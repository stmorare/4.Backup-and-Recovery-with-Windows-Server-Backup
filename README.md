# Backup and Recovery with Windows Server Backup Project

## Overview
This project implements a backup and recovery solution using Windows Server Backup on DC-00 to protect `SalesFolder` on FS-01, testing recovery with a manual overwrite due to restore location issues.

## Objectives
- Configured backup for `C:\SalesFolder` on DC-00.
- Simulated data loss by renaming to `SalesFolder_Old` on FS-01.
- Restored to DC-00, then manually copied to FS-01.
- Automated monitoring with PowerShell.
- Verified on the Windows 11 client.

## Steps
- Set up `SalesFolder` and `BackupShare` on FS-01.
- Backed up `C:\SalesFolder` on DC-00 to `\\FS-01\BackupShare`.
- Renamed `SalesFolder` to `SalesFolder_Old` on FS-01.
- Restored to `C:\SalesFolder` on DC-00, then copied to `SalesFolder_Old` on FS-01.
- Mapped `Z:` and verified.
