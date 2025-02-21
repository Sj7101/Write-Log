function Send-ErrorEmail {
    [CmdletBinding()]
    param()

    # Only send an email if there are errors in the global error buffer.
    if (-not $global:ErrorLogBuffer -or $global:ErrorLogBuffer.Count -eq 0) {
        Write-Log -Type INF -Message "No errors to report. Email will not be sent."
        return
    }

    # Read the email configuration from the JSON file.
    # The JSON file should include properties: smtp, to, cc, bcc, subject, from, and port.
    $configFile = ".\config.json"
    if (-not (Test-Path $configFile)) {
        Write-Log -Type ERR -Message "Configuration file '$configFile' not found."
        return
    }
    $config = Get-Content -Raw -Path $configFile | ConvertFrom-Json

    # Build the email body by listing each error on a new line.
    $body = "The following errors have been logged:`n`n" + ($global:ErrorLogBuffer -join "`n")

    # Create a hashtable of parameters for Send-MailMessage.
    $mailParams = @{
        SmtpServer = $config.smtp
        To         = $config.to
        Subject    = $config.subject
        Body       = $body
        From       = $config.from
        BodyAsHtml = $false
    }
    # Add optional parameters if they are provided.
    if ($config.cc -and $config.cc -ne "") { $mailParams.Cc = $config.cc }
    if ($config.bcc -and $config.bcc -ne "") { $mailParams.Bcc = $config.bcc }
    if ($config.port -and $config.port -ne "") { $mailParams.Port = [int]$config.port }

    try {
        Send-MailMessage @mailParams
        Write-Log -Type INF -Message "Error alert email sent successfully."
    }
    catch {
        Write-Log -Type ERR -Message "Failed to send email: $_"
    }
}
