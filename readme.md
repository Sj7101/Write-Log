VantageFeedsLog - PowerShell Logging Utility
This repository contains a PowerShell function, Write-Log, which provides robust logging capabilities for your scripts. The function writes log entries to a file and can also write to the Windows Event Log. It features automatic log file archiving when the log file exceeds 10MB and captures error logs for later notification.

Features
Custom Log File:
Logs are stored in VantageFeedsLog.log located in the same directory as your script ($PSScriptRoot).

Automatic Archiving:
When the log file exceeds 10MB, it is automatically moved to an Archived Logs folder with the current date appended (in ddMMyyyy format).

Flexible Log Format:
Each log entry is formatted as:
[MM/DD/YYYY][HH:mm:ss][SYS/INF/ERR]: MESSAGE

Event Log Integration:
Optionally write log entries to the Windows Event Log using the -EventLog switch and specify an event ID with -EventID.

Error Buffering:
Entries logged with type ERR are also captured in a global array ($global:ErrorLogBuffer) for future notifications.

Usage
Importing the Function
Include the function in your PowerShell script or dot-source it into your session:

powershell
Copy
. .\Write-Log.ps1
Example Commands
powershell
Copy
Write-Log -Type SYS -EventLog -EventID 1005 -Message "System Message injected here"
Write-Log -Type ERR -EventLog -EventID 404 -Message "Error injected here"
Write-Log -Type INF -EventLog -EventID 100 -Message "Success injected here"
Function Code
powershell
Copy
function Write-Log {
    [CmdletBinding()]
    param(
        # Log type: SYS, INF, or ERR
        [Parameter(Mandatory = $true)]
        [ValidateSet("SYS","INF","ERR")]
        [string]$Type,
        
        # Message to log
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        # If specified, write the log entry to the Windows Event Log
        [switch]$EventLog,
        
        # The EventID to be used when writing to the Event Log (default is 0)
        [int]$EventID = 0
    )

    # Define the log file path (inside $PSScriptRoot) with the updated name
    $LogFile = Join-Path $PSScriptRoot "VantageFeedsLog.log"
    
    # Check if log file exists; if not, create it
    if (-not (Test-Path $LogFile)) {
        New-Item -Path $LogFile -ItemType File -Force | Out-Null
    }

    # Define maximum log size (10MB in bytes)
    $MaxSize = 10 * 1024 * 1024

    # If the log file is greater than 10MB, archive it
    if ((Get-Item $LogFile).Length -gt $MaxSize) {
        # Define the archive folder path and create it if missing
        $ArchiveFolder = Join-Path $PSScriptRoot "Archived Logs"
        if (-not (Test-Path $ArchiveFolder)) {
            New-Item -Path $ArchiveFolder -ItemType Directory -Force | Out-Null
        }
        # Build the archive file name with date appended (DDMMYYYY)
        $ArchiveFile = Join-Path $ArchiveFolder ("VantageFeedsLog_" + (Get-Date -Format "ddMMyyyy") + ".log")
        Move-Item -Path $LogFile -Destination $ArchiveFile -Force
        # Create a new, empty log file
        New-Item -Path $LogFile -ItemType File -Force | Out-Null
    }

    # Capture the current date and time in the desired formats
    $Date = Get-Date -Format "MM/dd/yyyy"
    $Time = Get-Date -Format "HH:mm:ss"

    # Build the log entry in the format: [MM/DD/YYYY][HH:mm:ss][SYS/INF/ERR]: MESSAGE
    $LogEntry = "[$Date][$Time][$Type]: $Message"

    # Append the log entry to the log file
    Add-Content -Path $LogFile -Value $LogEntry

    # If the EventLog switch is specified, write the message to the Windows Event Log
    if ($EventLog) {
        # Determine the appropriate event type based on the log type
        $EntryType = if ($Type -eq "ERR") { "Error" } else { "Information" }
        
        # Use a source name – change "PowerShellScript" if needed.
        $Source = "PowerShellScript"
        if (-not [System.Diagnostics.EventLog]::SourceExists($Source)) {
            [System.Diagnostics.EventLog]::CreateEventSource($Source, "Application")
        }
        
        # Write to the Event Log (this writes the message without the additional log formatting)
        Write-EventLog -LogName Application -Source $Source -EntryType $EntryType -EventId $EventID -Message $Message
    }

    # If the log type is ERR, capture this entry in a global array for notification purposes
    if ($Type -eq "ERR") {
        if (-not $global:ErrorLogBuffer) { $global:ErrorLogBuffer = @() }
        $global:ErrorLogBuffer += $LogEntry
    }
}

<#
Example usage:
    Write-Log -Type SYS -EventLog -EventID 1005 -Message "System Message injected here"
    Write-Log -Type ERR -EventLog -EventID 404 -Message "Error injected here"
    Write-Log -Type INF -EventLog -EventID 100 -Message "Success injected here"
#>
Prerequisites
PowerShell Version:
This script requires PowerShell 5.1 or later.

Permissions:
Writing to the Windows Event Log may require elevated permissions, especially when creating a new event source.

Script Location:
The script relies on the $PSScriptRoot variable to locate the log file. Ensure that you run the script from a file context (or adjust the path as needed).

Contributing
Feel free to fork this repository and submit pull requests if you have suggestions or improvements.

License
This project is licensed under the MIT License.