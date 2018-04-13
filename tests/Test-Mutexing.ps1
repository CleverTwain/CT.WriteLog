function Test-Mutexing
{

    <#
    .SYNOPSIS
        Short description
    .DESCRIPTION
        Long description
    .EXAMPLE
        Example of how to use this cmdlet
    .EXAMPLE
        Another example of how to use this cmdlet
    .INPUTS
        Inputs to this cmdlet (if any)
    .OUTPUTS
        Output from this cmdlet (if any)
    .NOTES
        General notes
    .COMPONENT
        The component this cmdlet belongs to
    .ROLE
        The role this cmdlet belongs to
    .FUNCTIONALITY
        The functionality that best describes this cmdlet
    #>

    [CmdletBinding(DefaultParameterSetName='Parameter Set 1',
        SupportsShouldProcess,
        PositionalBinding,
        HelpUri = 'http://www.microsoft.com/',
        ConfirmImpact='Medium')]
    [Alias()]
    [OutputType([String])]
    Param (
        $LogFile = 'D:\ScriptTest\TestLog.log',
        $Throttle = 20, #Don't really know what this means... It is probably related to the number of jobs that should run at once
        $Count = 2,#100, #Threads to Use
        $Loops = 10, #Loops per thread
        $WriteCount = 5, #Writes per thread
        [switch]$UseMutex #Use mutex via script AND module
    )

    Begin
    {
        if (Test-Path $LogFile) {
            Remove-Item $LogFile -Force
            Write-Verbose "Removed"
        }

        Remove-Module WriteAHGLog
        Import-Module WriteAHGLog
        $MutexTestLog = New-AHGLog -Minimal -Path $LogFile -Append -MaxLogSize 10485760 -UseLocalVariable -Verbose
        Write-Verbose "$MutexTestLog"
        $MutexTestLog | Write-AHGLog -LogEntry "Thread,WriteCount,Counter" -LogType Information -Verbose

        $Parameters = @{
            LogFile = $LogFile
            UseMutex = $UseMutex
            Counter = $Counter
            WriteCount = $WriteCount
            Loops = $Loops
        }

        $DebugPreference = 'Continue'

        $RunspacePool = [runspacefactory]::CreateRunspacePool(
            1, #Min Runspaces
            10, #Max Runspaces
            [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault(), #Initial Session State; defines available commands and Language availability
            $host #PowerShell host
        )

        $RunspacePool.Open()

        $jobs = New-Object System.Collections.ArrayList
        Write-Host "Jobs: $($jobs.count)"

        1..$Count | ForEach-Object {
            $PowerShell = [powershell]::Create()

            $PowerShell.RunspacePool = $RunspacePool

            $Counter = $_
            Write-Verbose "Counter: $_ : $Counter"

            $Parameters = @{
                LogFile = $LogFile
                UseMutex = $UseMutex
                Counter = $Counter
                WriteCount = $WriteCount
                Loops = $Loops
            }

            [void]$PowerShell.AddScript({
                Param(
                    $LogFile,
                    $UseMutex,
                    $Counter,
                    $WriteCount,
                    $Loops
                )
                1..$WriteCount | ForEach-Object {
                    If ($UseMutex) {
                        $mtx = New-Object System.Threading.Mutex($false, "LogMutex")
                        Write-Verbose "[$(Get-Date)][PID: $($PID)][TID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)] Requesting mutex!" -Verbose
                        $mtx.WaitOne()
                        Write-Verbose "[$(Get-Date)][PID: $($PID)][TID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)] Recieved mutex!" -Verbose
                    }
                    Try {
                        <#
                        Import-Module WriteAHGLog
                        $MutexTestLog = New-AHGLog -Minimal -Path $LogFile -Append -UseLocalVariable -Verbose
                        #$MutexTestLog | Write-AHGLog -LogEntry "Updating log from thread [TID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)] | WriteNumber $_" -LogType Information
                        $MutexTestLog | Write-AHGLog -LogEntry "$([System.Threading.Thread]::CurrentThread.ManagedThreadId),$_,$Counter" -Verbose
                        Write-Verbose "[TID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)] Writing data $($_) to $LogFile" -Verbose
                        #"[$(Get-Date)] | ThreadID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId) | ProcessID $($PID) | Data: $($_)" | Out-File $LogFile -Append
                        #>
                        function Start-Test ($Num) {

                            $OriginalEAP = $ErrorActionPreference
                            $OriginalInformationPref = $InformationPreference
                            $OriginalDebugPref = $DebugPreference
                            $OriginalWarningPref = $WarningPreference
                            $InformationPreference = 'Continue'
                            $ErrorActionPreference = 'Continue'
                            #$ErrorActionPreference = 'SilentlyContinue'
                            $DebugPreference = 'Continue'

                            #$TestLog | Write-AHGLog '***************************'

                            Switch ($Num % 8 ) {

                                1 {$TestLog | Write-AHGLog -LogEntry "$([System.Threading.Thread]::CurrentThread.ManagedThreadId), 1, $Num" -LogType SuccessAudit -NoHostWriteBack -verbose}
                                2 {$TestLog | Write-AHGLog -LogEntry "$([System.Threading.Thread]::CurrentThread.ManagedThreadId), 2, $Num" -LogType FailureAudit -NoHostWriteBack -verbose}
                                3 {Write-AHGLog -Log $TestLog -LogEntry "$([System.Threading.Thread]::CurrentThread.ManagedThreadId), 3, $Num" -Type Warning -NoHostWriteBack -Verbose}

                            #Write-Host "Writing an to the host manually, without using the function"
                            <#
                            $MyText = 'Here is My Text'
                            $OtherText = 'This should be the name of my exception'
                            [System.Exception]$MyException = $MyText
                            $ErrorID = 'CustomErrorID'
                            [System.Management.Automation.ErrorCategory]$ErrorCategory = [System.Management.Automation.ErrorCategory]::WriteError
                            $ErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList ($MyException, $ErrorID, $ErrorCategory,$MyText)
                            Write-Error $ErrorRecord
                            #>

                            #Write-Host "Writing an error to the log without writing it back to the host"
                                4{Write-AHGLog -Log $TestLog -Message "$([System.Threading.Thread]::CurrentThread.ManagedThreadId), 4, $Num" -Type Error -NoHostWriteBack -Verbose}
                            #Write-Host "Writing an error to the log and also writing it back to the host"
                                5{Write-AHGLog -Log $TestLog -Message "$([System.Threading.Thread]::CurrentThread.ManagedThreadId), 5, $Num" -Type Error -NoHostWriteBack -Verbose}

                            #Write-Host "Generating an exception on purpose"
                            <#
                            Try {
                                Get-Process -Name DoesnotExist -ea stop
                            }
                            Catch {

                                Write-AHGLog -Log $TestLog -Message $Error[0] -Type Error -NoHostWriteBack -Verbose
                            }
                            #>
                            #Write-Host "First"
                                6 {Write-AHGLog -Log $TestLog -Message "$([System.Threading.Thread]::CurrentThread.ManagedThreadId), 6, $Num" -Type Verbose -NoHostWriteBack -Verbose}
                            #Write-Host "Second"
                                7 {Write-AHGLog -Log $TestLog -Message "$([System.Threading.Thread]::CurrentThread.ManagedThreadId), 7, $Num" -Type Debug -NoHostWriteBack -Verbose}
                            #Write-Host "Third"
                                8 {Write-AHGLog -Log $TestLog -Message "$([System.Threading.Thread]::CurrentThread.ManagedThreadId), 8, $Num" -Type Information -NoHostWriteBack -Verbose }
                        }


                            $InformationPreference = $OriginalInformationPref
                            $DebugPreference = $OriginalDebugPref
                            $ErrorActionPreference = $OriginalEAP
                            $WarningPreference = $OriginalWarningPref
                            }




                            Remove-Module WriteAHGLog
                            Import-Module WriteAHGLog -Verbose
                            $LogPath = 'D:\ScriptTest\TestLog.log'
                            #Remove-Item -Path $LogPath -Force
                            #$TestLog = New-AHGLog -EventLog -Verbose
                            $TestLog = New-AHGLog -Minimal -Path $LogPath -Append -MaxLogSize 10485760 -UseLocalVariable -Verbose
                            #Write-Host "New Log File Created"

                            #Write-Host "*******************************************"

                            1..$Loops | ForEach-Object {
                                $i
                                Start-Test $i

                            }
                    } Catch {
                        Write-Warning $_
                    }
                    If ($UseMutex) {
                        Write-Verbose "[$(Get-Date)][PID: $($PID)][TID: $([System.Threading.Thread]::CurrentThread.ManagedThreadId)] Releasing mutex" -Verbose
                        [void]$mtx.ReleaseMutex()
                    }
                }
            })
            Write-Verbose "Adding Parameters" -Verbose
            Write-Verbose "Adding $($Parameters.Counter)" -Verbose
            [void]$PowerShell.AddParameters($Parameters)

            $Handle = $PowerShell.BeginInvoke()
            $temp = '' | Select-Object PowerShell,Handle
            $temp.PowerShell = $PowerShell
            $temp.handle = $Handle
            [void]$jobs.Add($Temp)

            Write-Debug ("Available Runspaces in RunspacePool: {0}" -f $RunspacePool.GetAvailableRunspaces())
            Write-Debug ("Remaining Jobs: {0}" -f @($jobs | Where-Object {
                $_.handle.iscompleted -ne 'Completed'
            }).Count)
        }

        #Verify completed
        Write-Debug ("Available Runspaces in RunspacePool: {0}" -f $RunspacePool.GetAvailableRunspaces())
        Write-Debug ("Remaining Jobs: {0}" -f @($jobs | Where-Object {
            $_.handle.iscompleted -ne 'Completed'
        }).Count)

        #$return = $jobs | ForEach-Object {
        $jobs | ForEach-Object {
            $_.powershell.EndInvoke($_.handle);$_.PowerShell.Dispose()
        }

        $jobs.clear()
    }
}

function Start-Test ($LogFile = 'D:\ScriptTest\TestLog.log') {
    $Throttle = 20
    $Threads = 10
    $WriteCount = 7
    $Loops = 2
    $MessageTypes = 8 # Don't ever change this....
    clear-host
    remove-module writeahglog
    import-module writeahglog -verbose
    Test-Mutexing -LogFile $LogFile -Throttle $Throttle -Count $Threads -WriteCount $WriteCount -Loops $Loops -verbose -Debug

    $Content = Get-Content $LogFile
    $CSV = $Content | ConvertFrom-Csv
    # 8 messages per loop
    # 9 loops
    # Write-Count is 5
    # Count is 2
    $CSV | Group-Object thread
    $CSV.count -eq $Threads * $WriteCount * $Loops * $MessageTypes
}