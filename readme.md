PowerShell Logging Utility
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

. .\Write-Log.ps1

Example usage:

    Write-Log -Type SYS -EventLog -EventID 1005 -Message "System Message injected here"
    Write-Log -Type ERR -EventLog -EventID 404 -Message "Error injected here"
    Write-Log -Type INF -EventLog -EventID 100 -Message "Success injected here"

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