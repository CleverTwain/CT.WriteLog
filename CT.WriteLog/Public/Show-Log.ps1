Function Show-Log
{
    <#
        .SYNOPSIS
            Shows a log
        .DESCRIPTION
            The Show-Log function is used to display a log file, event log, or log object.
        .EXAMPLE
            Show-Log '.\myScript.log'
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
    [cmdletbinding()]
    Param(
        # Log object to show
        [Parameter(ValueFromPipeline)]
        [object]$LogObject = $Script:PSLOG,

        # Event log to show
        [string]$EventLog,

        # File log to show
        [string]$Path
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"

    } #begin
    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] $LogObject "

        if ($Path -or $LogObject.Type -eq 'LogFile') {
            Write-Verbose "Working with a logfile"
            if ($LogObject.Path) {
                $Path = $LogObject.Path
            }
            Write-Verbose "Trying to invoke-item $Path"
            Invoke-Item $Path
        }

        if ($EventLog -or $LogObject.Type -eq 'EventLog') {
            Write-Verbose "Working with event log"
            if ($LogObject.Name) {
                $EventLog = $LogObject.Name
            }
            Write-Verbose "Trying to EventVwr.exe /c:'$EventLog'"
            EventVwr.exe /c:"$EventLog"
        }

            # If the log is a file, invoke-item on it.  That should just open the file with
            #   the users preferred log viewer

            <#
            You can get the properties of the event log file itself by typing
            WevtUtil.exe Get-Log "$EventLogName" /format:xml
            Here is how you can get the location

            [xml]$EventLog = WevtUtil.exe Get-Log "$EventLogName" /format:xml
            $LogPath = $EventLog.Channel.Logging.LogFileName

            ---
            The log can be pulled up directly  by running:
            EventVwr.exe /c:"$EventLogName"

            (Except on my machine, because it is a piece of crap!)
            #>

    } #process
    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"



    } #end
} #close Show-Log