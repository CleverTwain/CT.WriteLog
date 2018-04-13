Function Test-WriteLog
{
    [cmdletbinding()]
    Param(
        # VariableName help description
        [Parameter(ValueFromPipeline)]
        [object[]]$VariableName
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"



    } #begin
    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] $VariableName "

        function Start-Test ($Num) {

            $OriginalEAP = $ErrorActionPreference
            $OriginalInformationPref = $InformationPreference
            $OriginalDebugPref = $DebugPreference
            $OriginalWarningPref = $WarningPreference
            $InformationPreference = 'Continue'
            $ErrorActionPreference = 'Continue'
            #$ErrorActionPreference = 'SilentlyContinue'
            $DebugPreference = 'Continue'

            #$TestLog | Write-Log '***************************'

            $TestLog | Write-Log -LogEntry "Test test 123...SuccessAudit $Num" -LogType SuccessAudit -NoHostWriteBack -verbose
            $TestLog | Write-Log -LogEntry "Test test 123...FailureAudit $Num" -LogType FailureAudit -NoHostWriteBack -verbose
            Write-Log -Log $TestLog -LogEntry "Warning Message $Num" -Type Warning -NoHostWriteBack -Verbose

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
            Write-Log -Log $TestLog -Message 'This is my custom error message without host writeback $Num' -Type Error -NoHostWriteBack -Verbose
            #Write-Host "Writing an error to the log and also writing it back to the host"
            Write-Log -Log $TestLog -Message 'This is my custom error message with host writeback $Num' -Type Error -NoHostWriteBack -Verbose

            #Write-Host "Generating an exception on purpose"
            <#
            Try {
                Get-Process -Name DoesnotExist -ea stop
            }
            Catch {

                Write-Log -Log $TestLog -Message $Error[0] -Type Error -NoHostWriteBack -Verbose
            }
            #>
            #Write-Host "First"
            Write-Log -Log $TestLog -Message "Loop Number $Num" -Type Verbose -NoHostWriteBack -Verbose
            #Write-Host "Second"
            Write-Log -Log $TestLog -Message "Loop Number $Num" -Type Debug -NoHostWriteBack -Verbose
            #Write-Host "Third"
            Write-Log -Log $TestLog -Message "Loop Number $Num" -Type Information -NoHostWriteBack -Verbose


            $InformationPreference = $OriginalInformationPref
            $DebugPreference = $OriginalDebugPref
            $ErrorActionPreference = $OriginalEAP
            $WarningPreference = $OriginalWarningPref
            }




            Remove-Module WriteLog
            Import-Module WriteLog -Verbose
            $LogPath = 'D:\ScriptTest\TestLog.log'
            Remove-Item -Path $LogPath -Force
            #$TestLog = New-Log -EventLog -Verbose
            $TestLog = New-Log -CMTrace -Path $LogPath -Append -UseLocalVariable -Verbose
            Write-Host "New Log File Created"

            Write-Host "*******************************************"

            for ($i = 1; $i -lt 100; $i++)
            {
                $i
                Start-Test $i

            }

    } #process
    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($MyInvocation.MyCommand)"



    } #end
} #close Test-WriteLog

Function Test-WriteLogV2
{
    [cmdletbinding()]
    Param(
        # VariableName help description
        [Parameter(ValueFromPipeline)]
        [object[]]$VariableName
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"



    } #begin
    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] $VariableName "

        function Start-Test ($Num) {

            $OriginalEAP = $ErrorActionPreference
            $OriginalInformationPref = $InformationPreference
            $OriginalDebugPref = $DebugPreference
            $OriginalWarningPref = $WarningPreference
            $InformationPreference = 'Continue'
            $ErrorActionPreference = 'Continue'
            #$ErrorActionPreference = 'SilentlyContinue'
            $DebugPreference = 'Continue'

            #$TestLog | Write-Log '***************************'

            $TestLog | Write-Log -LogEntry "Test test 123...SuccessAudit $Num" -LogType SuccessAudit -NoHostWriteBack -verbose
            $TestLog | Write-Log -LogEntry "Test test 123...FailureAudit $Num" -LogType FailureAudit -NoHostWriteBack -verbose
            Write-Log -Log $TestLog -LogEntry "Warning Message $Num" -Type Warning -NoHostWriteBack -Verbose

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
            Write-Log -Log $TestLog -Message 'This is my custom error message without host writeback $Num' -Type Error -NoHostWriteBack -Verbose
            #Write-Host "Writing an error to the log and also writing it back to the host"
            Write-Log -Log $TestLog -Message 'This is my custom error message with host writeback $Num' -Type Error -NoHostWriteBack -Verbose

            #Write-Host "Generating an exception on purpose"
            Try {
                Get-Process -Name DoesnotExist -ea stop
            }
            Catch {

                Write-Log -Log $TestLog -Message $Error[0] -Type Error -NoHostWriteBack -Verbose
            }
            #Write-Host "First"
            Write-Log -Log $TestLog -Message "Loop Number $Num" -Type Verbose -NoHostWriteBack -Verbose
            #Write-Host "Second"
            Write-Log -Log $TestLog -Message "Loop Number $Num" -Type Debug -NoHostWriteBack -Verbose
            #Write-Host "Third"
            Write-Log -Log $TestLog -Message "Loop Number $Num" -Type Information -NoHostWriteBack -Verbose


            $InformationPreference = $OriginalInformationPref
            $DebugPreference = $OriginalDebugPref
            $ErrorActionPreference = $OriginalEAP
            $WarningPreference = $OriginalWarningPref
            }




            Remove-Module CT.WriteLog
            Import-Module WriteLog -Verbose
            $LogPath = 'D:\ScriptTest\TestLog.log'
            Remove-Item -Path $LogPath -Force
            #$TestLog = New-Log -EventLog -Verbose
            $TestLog = New-Log -CMTrace -Path $LogPath -Append -UseLocalVariable -Verbose
            Write-Host "New Log File Created"

            Write-Host "*******************************************"

            for ($i = 1; $i -lt 100; $i++)
            {
                $i
                Start-Test $i

            }

    } #process
    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($MyInvocation.MyCommand)"



    } #end
} #close Test-WriteLog