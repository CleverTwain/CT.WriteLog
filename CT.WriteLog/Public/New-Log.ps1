function New-Log {
    <#
        .SYNOPSIS
            Creates a new log
        .DESCRIPTION
            The New-Log function is used to create a new log file or Windows Event log. A log object is also created
            and either saved in the global PSLOG variable (default) or sent to the pipeline. The latter is useful if
            you need to write to different log files in the same script/function.
        .EXAMPLE
            New-Log '.\myScript.log'
            Create a new log file called 'myScript.log' in the current folder, and save the log object in $PSLOG
        .EXAMPLE
            New-Log '.\myScript.log' -Header 'MyHeader - MyScript' -Append -CMTrace
            Create a new log file called 'myScript.log' if it doesn't exist already, and add a custom header to it.
            The log format used for logging by Write-Log is the CMTrace format.
        .EXAMPLE
            $log1 = New-Log '.\myScript_log1.log'; $log2 = New-Log '.\myScript_log2.log'
            Create two different logs that can be written to depending on your own internal script logic. Remember to pass the correct log object to Write-Log!
        .EXAMPLE
            New-Log -EventLogName 'PowerShell Scripts' -EventLogSource 'MyScript'
            Create a new log called 'PowerShell Scripts' with a source of 'MyScript', for logging to the Windows Event Log.
        .NOTES
            Author: CleverTwain
            Date: 4.8.2018
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium', DefaultParameterSetName = 'PlainText')]
    param (
        # Create or append to a Plain Text log file
        # Log Entry Example:
        # 03-22-2018 12:37:59.168-240 INFORMATION: Generic Log Entry
        [Parameter(
            ParameterSetName = 'PlainText',
            Position = 0
        )]
        [switch]$PlainText,

        # Create or append to a Minimal log file
        # Log Entry Example:
        # Generic Log Entry
        [Parameter(
            ParameterSetName = 'Minimal',
            Position = 0
        )]
        [switch]$Minimal,

        # Create or append to a CMTrace log file
        [Parameter(
            ParameterSetName = 'CMTrace',
            Position = 0
        )]
        [switch]$CMTrace,

        # Create or append to a Windows Event Log
        [Parameter(
            ParameterSetName = 'EventLog',
            Position = 0
        )]
        [switch]$EventLog,

        # Select which type of log to create or append to
        # The format of the log file. Valid choices are 'Minimal', 'PlainText' and 'CMTrace'.
        # The 'Minimal' format will just pass the log entry to the log file, while the 'PlainText' includes meta-data.
        # CMTrace format are viewable using the CMTrace.exe tool.

        # Path to log file.
        [Parameter(
            ParameterSetName = 'PlainText',
            Position = 1)]
        [ValidateNotNullorEmpty()]
        [Parameter(
            ParameterSetName = 'Minimal',
            Position = 1)]
        [ValidateNotNullorEmpty()]
        [Parameter(
            ParameterSetName = 'CMTrace',
            Position = 1)]
        [string] $Path = "$env:TEMP\$(Get-Date -Format FileDateTimeUniversal).log",

        # Optionally define a header to be added when a new empty log file is created.
        #     Headers only apply to files, and do not apply to CMTrace files
        [Parameter(
            ParameterSetName = 'PlainText',
            Mandatory = $false,
            Position = 2)]
        [Parameter(
            ParameterSetName = 'Minimal',
            Mandatory = $false,
            Position = 2)]
        [string]$Header,

        # If log file already exist, append instead of creating a new empty log file.
        [Parameter(
            ParameterSetName = 'PlainText')]
        [Parameter(
            ParameterSetName = 'Minimal')]
        [Parameter(
            ParameterSetName = 'CMTrace')]
        [switch] $Append,

        # Maximum size of log file.
        [Parameter(
            ParameterSetName = 'PlainText'
            )]
        [Parameter(
            ParameterSetName = 'Minimal'
            )]
        [Parameter(
            ParameterSetName = 'CMTrace'
            )]
        [int64] $MaxLogSize = 5242880, # in bytes, default is 5242880 = 5 MB

        # Maximum number of log files to keep. Default is 3. Setting MaxLogFiles to 0 will keep all log files.
        [Parameter(
            ParameterSetName = 'PlainText'
            )]
        [Parameter(
            ParameterSetName = 'Minimal'
            )]
        [Parameter(
            ParameterSetName = 'CMTrace'
            )]
        [ValidateRange(0,99)]
        [int32] $MaxLogFiles = 3,

        # Specifies the name of the event log.
        [Parameter(
            ParameterSetName = 'EventLog',
            Position = 3)]
        [string] $EventLogName = 'CT.WriteLog',

        # Specifies the name of the event log source.
        [Parameter(
            ParameterSetName = 'EventLog')]
        [string] $EventLogSource,

        # Define the default Event ID to use when writing to the Windows Event Log.
        # This Event ID will be used when writing to the Windows log, but can be overrided by the Write-Log function.
        [Parameter(
            ParameterSetName = 'EventLog')]
        [string] $DefaultEventID = '1000',

        # When UseLocalVariable is True, the log object is not saved in the global PSLOG variable,
        # otherwise it's returned to the pipeline.
        [Parameter()]
        [switch] $UseLocalVariable,

        # Messages written via Write-Log are also written back to the host by default. Specifying this option, disables
        # that functionality for the log object.
        [Parameter()]
        [switch] $NoHostWriteBack,

        # When writing to the log, the data stream name (DEBUG, WARNING, VERBOSE, etc.) is not included by default.
        # Specifying this option will include the stream name in all Write-Log messages.
        [Parameter()]
        [switch] $IncludeStreamName
    )

    if ($PSCmdlet.ParameterSetName -eq 'EventLog') {
        $LogType = 'EventLog'
    } else {
        $LogType = 'LogFile'
        $LogFormat = $PSCmdlet.ParameterSetName
    }

    if ($LogType -eq 'EventLog') {

        if (!$EventLogSource) {
            if ( (Get-PSCallStack)[1].FunctionName ) {
                $EventLogSource = (Get-PSCallStack)[1].FunctionName
            } else {
                $EventLogSource = (Get-PSCallStack)[1].Command
            }
            if ($EventLogSource = '<ScriptBlock>') {
                $EventLogSource = 'ScriptBlock'
            }
        }

        if ([System.Diagnostics.EventLog]::SourceExists($EventLogSource)) {
            $AssociatedLog = [System.Diagnostics.EventLog]::LogNameFromSourceName($EventLogSource,".")

            if ($AssociatedLog -ne $EventLogName) {
                Write-Warning "The eventlog source $EventLogSource is already associated with a different eventlog"
                $LogType = $null
                return $null
            }
        }

        try {
            if (-not([System.Diagnostics.EventLog]::SourceExists($EventLogSource))) {

                # In order to create a new event log, or add a new source to an existing eventlog,
                #   the user must be running the command as an administrator.
                # We are checking for that here
                $windowsIdentity=[System.Security.Principal.WindowsIdentity]::GetCurrent()
                $windowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($windowsIdentity)
                $adm=[System.Security.Principal.WindowsBuiltInRole]::Administrator
                if ($windowsPrincipal.IsInRole($adm)) {
                    Remove-Variable -Name Format,MaxLogSize,MaxLogFiles -ErrorAction SilentlyContinue
                    # create new event log if needed
                    New-EventLog -Source $EventLogSource -LogName $EventLogName
                    Write-Verbose "Created new event log (Name: $($EventLogName), Source: $($EventLogSource))"
                }

                else {
                    Write-Warning 'When creating a Windows Event Log you need to run as a user with elevated rights!'
                }
            }
            else {
                Write-Verbose "$($EventLogName) exists, skip create new event log."
            }

            $logType = 'EventLog'
        }
        catch {
            Write-Warning $_.Exception.Message
        }
    }

    else {
        Remove-Variable -Name EventLogName,EventLogSource,DefaultEventID -ErrorAction SilentlyContinue

        $Counter = 0
        $HaveLog = $false
        While (-not $HaveLog) {
            $Mutex = New-Object System.Threading.Mutex($false, "LoggingMutex")
            Write-Debug "Requesting mutex to test access to log"
            [void]$Mutex.WaitOne(1000)
            Write-Debug "Received Mutex to test access to log"
            Try {
                [io.file]::OpenWrite($Path).close()
                $HaveLog = $true
            }
            Catch [System.UnauthorizedAccessException] {
                $FileName = $Path.Split("\") | Select-Object -Last 1
                $Path = "$env:TEMP\$FileName"
                Write-Warning "Current user does not have permission to write to $Path. Redirecting log to $Path"
                $HaveLog = $true
            } Catch {
                $Counter++
                Write-Debug $_
            } Finally {
                Write-Debug "Releasing Mutex to access log"
                [void]$Mutex.ReleaseMutex()
            }
            if ($Counter -gt 99) {
                $HaveLog = $false
                Write-Error "Unable to obtain lock on file"
                $logType = $null
                return $null
            }
        }

        # create new log file if needed ( we need to re-check if the file exists here because the
        #    path may have changed since we last checked)
        if((-not $Append) -or (-not(Test-Path $Path))){
            Write-Verbose "Log does not currently exist, or we are overwriting an existing log"
            try {
                if($Header){
                    Set-Content -Path $Path -Value $Header -Encoding 'UTF8' -Force
                }
                else{
                    Set-Content -Path $Path -Value $null -Encoding 'UTF8' -Force
                }
                Write-Verbose "Created new log file ($($Path))"
            }
            catch{
                Write-Warning $_.Exception.Message
            }
        }
    }

    Write-Verbose "Creating Log Object"
    # create log object
    switch ($LogType) {
        'EventLog' {
            # create log object
            $logObject = [PSCustomObject]@{
                PSTypeName = 'CT.EventLog'
                Type = $logType
                Name = $EventLogName
                Source = $EventLogSource
                DefaultEventID = $DefaultEventID
                IncludeStreamName = $IncludeStreamName
                HostWriteBack = (!$NoHostWriteBack)
                MaxLogSize = $MaxLogSize
                # Limit-EventLog
                # Minimum 64KB Maximum 4GB and must be divisible by 64KB (65536)
                MaxLogRetention = $MaxLogRetention
                # Limit-EventLog
                # RetentionDays
                OverflowAction = $OverflowAction
                # Limit-EventLog
                # OverwriteOlder, OverwriteAsNeeded, DoNotOverwrite
            }
        }
        'LogFile' {
            $logObject = [PSCustomObject]@{
                PSTypeName = 'CT.LogFile'
                Type = $logType
                Path = $Path
                Format = $LogFormat
                Header = $Header
                IncludeStreamName = $IncludeStreamName
                HostWriteBack = (!$NoHostWriteBack)
                MaxLogSize = $MaxLogSize
                MaxLogFiles = $MaxLogFiles
            }
        }
        default {$logObject = $null}
    }

    # Return the log to the pipeline

    if ($UseLocalVariable) {
        Write-Output $logObject
    } else {
        if (Get-Variable PSLog -ErrorAction SilentlyContinue) {
            Remove-Variable -Name PSLOG
        }
        New-Variable -Name PSLOG -Value $logObject -Scope Script
    }
}