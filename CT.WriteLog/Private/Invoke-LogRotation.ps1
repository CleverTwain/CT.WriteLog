function Invoke-LogRotation {
    <#
        .SYNOPSIS
            Handle log rotation.
        .DESCRIPTION
            Invoke-LogRotation handles log rotation, using the log parameters defined in the log object.
            This function is called within the Write-Log function so that log rotation are invoked after
            each write to the log file.
        .NOTES
            Author: CleverTwain
            Date: 4.8.2018
            Version: 0.1.0
    #>
    [CmdletBinding()]
    param (
        # The log object created using the New-Log function. Defaults to reading the global PSLOG variable.
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullorEmpty()]
        [object] $Log = $Script:PSLOG
    )

    try {

        # get current size of log file
        $currentSize = (Get-Item $Log.Path).Length

        # get log name
        $logFileName = Split-Path $Log.Path -Leaf
        $logFilePath = Split-Path $Log.Path
        $logFileNameWithoutExtension = [System.IO.Path]::GetFileNameWithoutExtension($logFileName)
        $logFileNameExtension = [System.IO.Path]::GetExtension($logFileName)

        # if MaxLogFiles is 1 just keep the original one and let it grow
        if (-not($Log.MaxLogFiles -eq 1)) {
            if ($currentSize -ge $Log.MaxLogSize) {
                Write-Verbose 'We have hit the max log size'

                # construct name of archived log file
                $newLogFileName = $logFileNameWithoutExtension + (Get-Date -Format 'yyyyMMddHHmmss').ToString() + $logFileNameExtension

                # copy old log file to new using the archived name constructed above
                Copy-Item -Path $Log.Path -Destination (Join-Path (Split-Path $Log.Path) $newLogFileName)

                # set new empty log file
                if ([string]::IsNullOrEmpty($Log.Header)) {
                    Set-Content -Path $Log.Path -Value $null -Encoding 'UTF8' -Force
                }

                else {
                    Set-Content -Path $Log.Path -Value $Log.Header -Encoding 'UTF8' -Force
                }

                # if MaxLogFiles is 0 don't delete any old archived log files
                if (-not($Log.MaxLogFiles -eq 0)) {

                    Write-Verbose 'We shouldnt need to delete old log files...'

                    # set filter to search for archived log files
                    $archivedLogFileFilter = $logFileNameWithoutExtension + '??????????????' + $logFileNameExtension

                    # get archived log files
                    $oldLogFiles = Get-Item -Path "$(Join-Path -Path $logFilePath -ChildPath $archivedLogFileFilter)"

                    if ([bool]$oldLogFiles) {
                        # compare found log files to MaxLogFiles parameter of the log object, and delete oldest until we are
                        # back to the correct number
                        if (($oldLogFiles.Count + 1) -gt $Log.MaxLogFiles) {
                            Write-Verbose "Okay... maybe we do need to delete some old logs"
                            [int]$numTooMany = (($oldLogFiles.Count) + 1) - $log.MaxLogFiles
                            $oldLogFiles | Sort-Object 'LastWriteTime' | Select-Object -First $numTooMany | Remove-Item
                        }
                    }
                }
            }
        }
    }

    catch {
        Write-Warning $_.Exception.Message
    }
}