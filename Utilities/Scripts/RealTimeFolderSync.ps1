# Script Name: RealTimeFolderSync.ps1
# Description: Captures the current directory structure for Dev_NovaAI, excluding unnecessary metadata, and monitors changes.
# Version: 1.3.1
# Author: Seanje Lenox-Wise
# Updated: 2024-12-01

# Define the root directory
$RootDirectory = "C:\Users\seanj\OneDrive\Desktop\Dev_NovaAI"

# Define excluded directories and file patterns
$ExcludedPatterns = @(
    ".git",        # Git metadata
    "*.tmp",       # Temporary files
    "*.lnk",       # Shortcut files
    "*.cloud",     # Cloud-only files
    "*.cloudf",    # Files waiting for download
    "desktop.ini"  # System configuration
)

# Function to capture directory structure in tree format and export to a file
Function Capture-DirectoryStructure {
    param (
        [string]$DirectoryPath,
        [string]$OutputFile = "$DirectoryPath\DirectoryStructure.txt"
    )

    Write-Host "Capturing directory structure for: $DirectoryPath" -ForegroundColor Green

    # Check if the directory exists
    if (-Not (Test-Path $DirectoryPath)) {
        Write-Host "Error: The specified directory does not exist." -ForegroundColor Red
        return
    }

    # Recursive function to generate a tree structure
    Function Generate-Tree {
        param (
            [string]$Path,
            [int]$Depth = 0
        )
        $Prefix = " " * ($Depth * 4) + "|-- "
        Get-ChildItem -Path $Path -Force |
            Where-Object {
                # Exclude paths based on patterns
                $ExcludeMatch = $false
                foreach ($Pattern in $ExcludedPatterns) {
                    if ($_.FullName -like "*$Pattern*") {
                        $ExcludeMatch = $true
                        break
                    }
                }
                -Not $ExcludeMatch -and $_.Name -ne ".git"
            } | ForEach-Object {
                $Output = "$Prefix$($_.Name)"
                Out-String -InputObject $Output
                if ($_.PSIsContainer) {
                    Generate-Tree -Path $_.FullName -Depth ($Depth + 1)
                }
            }
    }

    # Generate tree and save to file
    try {
        $TreeOutput = Generate-Tree -Path $DirectoryPath
        $TreeOutput | Out-File -FilePath $OutputFile -Force
        Write-Host "Directory structure captured successfully! Output saved to: $OutputFile" -ForegroundColor Cyan
    } catch {
        Write-Host "An error occurred: $_" -ForegroundColor Red
    }
}

# Function to monitor directory changes and log them to a file
Function Monitor-DirectoryChanges {
    param (
        [string]$DirectoryPath,
        [string]$LogFile = "$DirectoryPath\DirectoryChanges.log"
    )

    # Ensure the log file exists
    if (-Not (Test-Path $LogFile)) {
        New-Item -Path $LogFile -ItemType File -Force | Out-Null
        Write-Host "Log file created: $LogFile" -ForegroundColor Green
    }

    Write-Host "Monitoring changes in directory: $DirectoryPath" -ForegroundColor Yellow

    # Monitor directory changes
    $Watcher = New-Object System.IO.FileSystemWatcher
    $Watcher.Path = $DirectoryPath
    $Watcher.IncludeSubdirectories = $true
    $Watcher.EnableRaisingEvents = $true

    # Log changes to a file
    Register-ObjectEvent -InputObject $Watcher -EventName Changed -Action {
        if (-Not ($Event.SourceEventArgs.FullPath -like "*$ExcludedPatterns*")) {
            $Change = "File changed: $($Event.SourceEventArgs.FullPath) at $(Get-Date)"
            Add-Content -Path $LogFile -Value $Change
            Write-Host $Change -ForegroundColor Green
        }
    }
    Register-ObjectEvent -InputObject $Watcher -EventName Created -Action {
        if (-Not ($Event.SourceEventArgs.FullPath -like "*$ExcludedPatterns*")) {
            $Create = "File created: $($Event.SourceEventArgs.FullPath) at $(Get-Date)"
            Add-Content -Path $LogFile -Value $Create
            Write-Host $Create -ForegroundColor Blue
        }
    }
    Register-ObjectEvent -InputObject $Watcher -EventName Deleted -Action {
        if (-Not ($Event.SourceEventArgs.FullPath -like "*$ExcludedPatterns*")) {
            $Delete = "File deleted: $($Event.SourceEventArgs.FullPath) at $(Get-Date)"
            Add-Content -Path $LogFile -Value $Delete
            Write-Host $Delete -ForegroundColor Red
        }
    }
    Register-ObjectEvent -InputObject $Watcher -EventName Renamed -Action {
        if (-Not ($Event.SourceEventArgs.FullPath -like "*$ExcludedPatterns*")) {
            $Rename = "File renamed: $($Event.SourceEventArgs.OldFullPath) to $($Event.SourceEventArgs.FullPath) at $(Get-Date)"
            Add-Content -Path $LogFile -Value $Rename
            Write-Host $Rename -ForegroundColor Magenta
        }
    }

    Write-Host "Press any key to stop monitoring..." -ForegroundColor Yellow
    while ($Watcher.EnableRaisingEvents) {
        Start-Sleep -Milliseconds 500
    }
    Unregister-Event -SourceIdentifier *
    Write-Host "Monitoring stopped. Changes logged to: $LogFile" -ForegroundColor Cyan
}

# Main execution
Write-Host "RealTimeFolderSync - NovaAI Directory Management Script" -ForegroundColor White
Write-Host "======================================================="

# Prompt the user to capture the directory structure or monitor changes
Write-Host "Select an option:" -ForegroundColor White
Write-Host "1. Capture directory structure" -ForegroundColor White
Write-Host "2. Monitor directory changes (real-time)" -ForegroundColor White
Write-Host "3. Exit" -ForegroundColor White

$Option = Read-Host "Enter your choice (1/2/3)"

switch ($Option) {
    "1" {
        Capture-DirectoryStructure -DirectoryPath $RootDirectory
    }
    "2" {
        Monitor-DirectoryChanges -DirectoryPath $RootDirectory
    }
    "3" {
        Write-Host "Exiting script. Goodbye!" -ForegroundColor Cyan
        exit
    }
    default {
        Write-Host "Invalid option. Please run the script again." -ForegroundColor Red
    }
}
