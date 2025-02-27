function Write-Log {
    [CmdletBinding()]
    param(
        # Log type: SYS, INF, ERR, or WRN
        [Parameter(Mandatory = $true)]
        [ValidateSet("SYS","INF","ERR","WRN")]
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

    # Build the log entry in the format: [MM/DD/YYYY][HH:mm:ss][SYS/INF/ERR/WRN]: MESSAGE
    $LogEntry = "[$Date][$Time][$Type]: $Message"

    # Append the log entry to the log file
    Add-Content -Path $LogFile -Value $LogEntry

    # If the EventLog switch is specified, write the message to the Windows Event Log
    if ($EventLog) {
        # Determine the appropriate event type based on the log type
        $EntryType = if ($Type -eq "ERR") {
            "Error"
        } elseif ($Type -eq "WRN") {
            "Warning"
        } else {
            "Information"
        }
        
        # Use a source name – change "PowerShellScript" if needed.
        $Source = "PowerShellScript"
        if (-not [System.Diagnostics.EventLog]::SourceExists($Source)) {
            [System.Diagnostics.EventLog]::CreateEventSource($Source, "Application")
        }
        
        # Write to the Event Log (this writes the message without the additional log formatting)
        Write-EventLog -LogName Application -Source $Source -EntryType $EntryType -EventId $EventID -Message $Message
    }

    # If the log type is ERR or WRN, capture this entry in a global array for notification purposes
    if ($Type -eq "ERR" -or $Type -eq "WRN") {
        if (-not $global:ErrorLogBuffer) { $global:ErrorLogBuffer = @() }
        $global:ErrorLogBuffer += $LogEntry
    }
}

<#
Example usage:
    Write-Log -Type SYS -EventLog -EventID 1005 -Message "System Message injected here"
    Write-Log -Type ERR -EventLog -EventID 404 -Message "Error injected here"
    Write-Log -Type INF -EventLog -EventID 100 -Message "Success injected here"
    Write-Log -Type WRN -EventLog -EventID 200 -Message "Warning: Check your configuration"
#>
