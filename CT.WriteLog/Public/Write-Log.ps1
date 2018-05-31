Function Write-Log
{
    <#
        .SYNOPSIS
            Write to the log and back to the host by default.
        .DESCRIPTION
            The Write-Log function is used to write to the log and by default, also write back to the host.
            It is using the log object created by New-AHGLog to determine if it's going to write to a log file
            or to a Windows Event log. Log files can be created in multiple formats
        .EXAMPLE
            Write-AHGLog 'Finished running WMI query'
            Get the log object from $PSLOG and write to the log.
        .EXAMPLE
            $myLog | Write-AHGLog 'Finished running WMI query'
            Use the log object saved in $myLog and write to the log.
        .EXAMPLE
            Write-AHGLog 'WMI query failed - Access denied!' -LogType Error -PassThru | Write-Warning
            Will write an error to the event log, and then pass the log entry to the Write-Warning cmdlet.
        .NOTES
            Author: CleverTwain
            Date: 4.8.2018
            Dependencies: Invoke-AHGLogRotation
    #>

    [cmdletbinding()]
    param (
        # The text you want to write to the log.
        # Not limiting this to a string, as this function can catch exceptions as well
        [Parameter(Position = 0)]
        [Alias('Message')]
        $LogEntry,

        # The type of log entry. Valid choices are 'Error', 'FailureAudit','Information','SuccessAudit' and 'Warning'.
        # Note that the CMTrace format only supports 3 log types (1-3), so 'Error' and 'FailureAudit' are translated to CMTrace log type 3, 'Information' and 'SuccessAudit'
        # are translated to 1, while 'Warning' is translated to 2. 'FailureAudit' and 'SuccessAudit' are only really included since they are valid log types when
        # writing to the Windows Event Log.
        [Parameter()]
        [ValidateSet('Error', 'FailureAudit', 'Information', 'SuccessAudit', 'Warning', 'Verbose', 'Debug')]
        [Alias('Type')]
        [string] $LogType = 'Information',

        # Include the stream name in the log entry when writing CMTrace logs
        [Parameter()]
        [switch]$IncludeStreamName,

        # Do not write the message back to the host via the specified stream
        #     By default, log entries are written back to the host via the specified data stream.
        [Parameter()]
        [switch]$NoHostWriteBack,

        # Event ID. Only applicable when writing to the Windows Event Log.
        [Parameter()]
        [string] $EventID,

        # The log object created using the New-Log function. Defaults to reading the PSLOG variable.
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullorEmpty()]
        [Alias('LogFile')]
        [object] $Log = $Global:PSLOG,

        # PassThru passes the log entry to the pipeline for further processing.
        [Parameter()]
        [switch] $PassThru
    )
    Begin
    {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"

        if ( (!$Log.HostWriteBack) -or ($NoHostWriteBack))
        {
            $NoHostWriteBack = $true
        }

        if ( ($Log.IncludeStreamName) -or ($IncludeStreamName))
        {
            $IncludeStreamName = $true
        }

        # An attribute of the Log object will be flagged if we do not have appropriate permissions.
        # If that attribute is flagged, we should still write to the screen if appropriate


    } #begin
    Process
    {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] $LogEntry  "

        try
        {

            # get information from log object
            $logObject = $Log

            Write-Verbose "Received the log object of type $($logObject.Type)"

            if ($logObject.Format)
            {
                Write-Debug "LogFormat: $($LogObject.Format)"
            }

            # translate event types to CMTrace types, and gather information for error
            if ($logObject.Format -eq 'CMTrace' -or $logObject.Type -eq 'EventLog')
            {
                switch ($LogType)
                {
                    'Error'
                    {
                        $cmType = '3'

                        #Get the info about the calling script, function etc
                        $CallingInfo = (Get-PSCallStack)[1]

                        if (!$LogEntry.Exception.Message)
                        {
                            [System.Exception]$Exception = $LogEntry
                            [String]$ErrorID = 'Custom Error'
                            [System.Management.Automation.ErrorCategory]$ErrorCategory = [Management.Automation.ErrorCategory]::WriteError
                            $ErrorRecord = New-Object Management.automation.errorrecord ($Exception, $ErrorID, $ErrorCategory, $LogEntry)
                            $LogEntry = $ErrorRecord

                            $LogEntry =
                            "$([String]$LogEntry.Exception.Message)`r`r`n" +
                            "`nFunction: $($Callinginfo.FunctionName)" +
                            "`nScriptName: $($Callinginfo.Scriptname)" +
                            "`nLine Number: $($Callinginfo.ScriptLineNumber)" +
                            "`nColumn Number: $($Callinginfo.Position.StartColumnNumber)" +
                            "`nLine: $($Callinginfo.Position.StartScriptPosition.Line)"
                        }
                        else
                        {
                            $LogEntry =
                            "$([String]$LogEntry.Exception.Message)`r`r`n" +
                            "`nCommand: $($LogEntry.InvocationInfo.MyCommand)" +
                            "`nScriptName: $($LogEntry.InvocationInfo.Scriptname)" +
                            "`nLine Number: $($LogEntry.InvocationInfo.ScriptLineNumber)" +
                            "`nColumn Number: $($LogEntry.InvocationInfo.OffsetInLine)" +
                            "`nLine: $($LogEntry.InvocationInfo.Line)"
                        }
                        if ( ($logObject.DefaultErrorEventID) -and ([system.string]::IsNullOrEmpty($EventID)) )
                        {
                            $EventID = $logObject.DefaultErrorEventID
                        }

                    }
                    'FailureAudit'
                    {
                        $cmType = '3'
                        if ( ($logObject.DefaultFailureAuditEventID) -and ([system.string]::IsNullOrEmpty($EventID)) )
                        {
                            $EventID = $logObject.DefaultFailureAuditEventID
                        }
                    }
                    'Information'
                    {
                        $cmType = '6'
                        if ( ($logObject.DefaultInformationalEventID) -and ([system.string]::IsNullOrEmpty($EventID)) )
                        {
                            $EventID = $logObject.DefaultInformationalEventID
                        }
                    }
                    'SuccessAudit'
                    {
                        $cmType = '4'
                        if ( ($logObject.DefaultSuccessAuditEventID) -and ([system.string]::IsNullOrEmpty($EventID)) )
                        {
                            $EventID = $logObject.DefaultSuccessAuditEventID
                        }
                    }
                    'Warning'
                    {
                        $cmType = '2'
                        if ( ($logObject.DefaultWarningEventID) -and ([system.string]::IsNullOrEmpty($EventID)) )
                        {
                            $EventID = $logObject.DefaultWarningEventID
                        }
                    }
                    'Verbose'
                    {
                        $cmType = '4'
                        if ( ($logObject.DefaultVerboseEventID) -and ([system.string]::IsNullOrEmpty($EventID)) )
                        {
                            $EventID = $logObject.DefaultVerboseEventID
                        }
                    }
                    'Debug'
                    {
                        $cmType = '5'
                        if ( ($logObject.DefaultDebugEventID) -and ([system.string]::IsNullOrEmpty($EventID)) )
                        {
                            $EventID = $logObject.DefaultDebugEventID
                        }
                    }
                    DEFAULT {$cmType = '1'}
                }
                Write-Debug "$LogType : $cmType"
            }

            if ($logObject.Type -eq 'EventLog')
            {
                # if EventID is not specified use default event id from the log object
                if ([system.string]::IsNullOrEmpty($EventID))
                {
                    switch ($LogType)
                    {
                        'Information' { $EventID = $logObject.DefaultInformationalEventID }
                    }
                    $EventID = $logObject.DefaultEventID
                }

                if ($LogType -notin ('Error', 'FailureAudit', 'SuccessAudit', 'Warning'))
                {
                    $LogType = 'Information'
                }

                $LogEntryString = $LogEntry
                Write-Verbose "LogEntryString: $LogEntryString"
                Write-Verbose "lo.name: $($logObject.Name)"
                Write-Verbose "lo.Source: $($logObject.Source)"
                Write-Verbose "EntryType: $($LogType)"
                Write-Verbose "EventId: $($EventID)"

                Write-Verbose 'Trying to write to the event log'
                Write-EventLog -LogName $logObject.Name -Source $logObject.Source -EntryType $LogType -EventId $EventID -Message $LogEntryString -Verbose
            }

            else
            {
                $DateTime = New-Object -ComObject WbemScripting.SWbemDateTime
                $DateTime.SetVarDate($(Get-Date))
                $UtcValue = $DateTime.Value
                $UtcOffset = $UtcValue.Substring(21, $UtcValue.Length - 21)

                $Date = Get-Date -Format 'MM-dd-yyyy'
                $Time = "$(Get-Date -Format HH:mm:ss.fff)$($UtcOffset)"

                # handle the different log file formats
                switch ($logObject.Format)
                {

                    'Minimal' { $logEntryString = $LogEntry}

                    'PlainText'
                    {
                        $logEntryString = "$Date $Time"
                        if ($IncludeStreamName)
                        {
                            $LogEntryString = "$logEntryString $($LogType.ToUpper()):"
                        }
                        $LogEntryString = "$LogEntryString $($LogEntry)"
                    }

                    'CMTrace'
                    {

                        # Get invocation information about the script/function/module that called us
                        $thisInvocation = (Get-Variable -Name 'MyInvocation' -Scope 2).Value

                        # get calling script info
                        if (-not ($thisInvocation.ScriptName))
                        {
                            $scriptName = $thisInvocation.MyCommand
                            $Source = "$($scriptName)"
                        }
                        else
                        {
                            $scriptName = Split-Path -Leaf ($thisInvocation.ScriptName)
                            $Source = "$($scriptName):$($thisInvocation.ScriptLineNumber)"
                        }

                        # get calling command info
                        $component = "$($thisInvocation.MyCommand)"

                        $Context = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

                        $Source = (Get-PSCallStack)[1].Location

                        if ( (Get-PSCallStack)[1].FunctionName )
                        {
                            $Component = (Get-PSCallStack)[1].FunctionName
                        }
                        else
                        {
                            $Component = (Get-PSCallStack)[1].Command
                        }

                        #Set Component Information
                        if ($Source -eq '<No file>')
                        {
                            $Source = (Get-Process -Id $PID).ProcessName
                        }

                        $Line = '<![LOG[{0}]LOG]!><time="{1}" date="{2}" component="{3}" context="{4}" type="{5}" thread="{6}" file="{7}">'
                        $LineFormat = $LogEntry, $Time, $Date, $Component, $Context, $CMType, $PID, $Source
                        $logEntryString = $Line -f $LineFormat

                        Write-Debug "$logEntryString"
                    }
                }
                $PendingWrite = $true
                $Counter = 0
                $MaxLoops = 100
                <#
                While ($PendingWrite -and ($Counter -lt $MaxLoops)) {
                    $Counter++
                    try {
                        # create a mutex, so we can lock the file while writing to it
                        $mutex = New-Object System.Threading.Mutex($false, 'LogMutex')
                        # write to the log file
                        Add-Content -Path $logObject.Path -Value $logEntryString -ErrorAction Stop
                        $PendingWrite = $false
                        $mutex.ReleaseMutex()
                    } catch {
                        [void]$mutex.WaitOne()
                    } finally {
                        if ($Counter -eq $MaxLoops) {
                            Write-Warning "Unable to gain lock on file at $($logObject.Path)"
                        }
                    }
                }
                #>
                While ($PendingWrite -and ($Counter -lt $MaxLoops))
                {
                    $Mutex = New-Object System.Threading.Mutex($false, "LoggingMutex")
                    Write-Debug "Requesting mutex to write to log"
                    [void]$Mutex.WaitOne(1000)
                    Write-Debug "Received Mutex to write to log"
                    Try
                    {
                        Add-Content -Path $logObject.Path -Value $logEntryString -ErrorAction Stop
                        $PendingWrite = $false
                    }
                    Catch
                    {
                        $Counter++
                        Write-Debug $_
                    }
                    Finally
                    {
                        Write-Debug "Releasing Mutex to access log"
                        [void]$Mutex.ReleaseMutex()
                    }
                }



                # invoke log rotation if log is file
                if ($logObject.LogType -eq 'LogFile')
                {
                    $logObject | Invoke-LogRotation
                }
            }
        }

        catch
        {
            Write-Warning $_.Exception.Message
        }

    } #process
    End
    {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"

        if (!$NoHostWriteBack)
        {
            Write-Verbose "Writing message back to host"
            Write-MessageToHost -LogEntry $LogEntryString -LogType $LogType
        }

        # handle PassThru
        if ($PassThru)
        {
            Write-Output $LogEntry
        }

    } #end
} #close Write-Log