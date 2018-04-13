Function Write-MessageToHost
{
    [cmdletbinding()]
    Param(
        # LogEntry help description
        [Parameter(ValueFromPipeline)]
        [object]$LogEntry,

        [Parameter()]
        [ValidateSet('Error', 'FailureAudit', 'Information', 'SuccessAudit', 'Warning', 'Verbose', 'Debug')]
        [Alias('Type')]
        [string] $LogType = 'Information',

        $NoHostWriteBack
    )
    Begin {
        Write-Verbose "[$((Get-Date).TimeofDay) BEGIN  ] Starting $($myinvocation.mycommand)"

        switch ($LogType) {
            'Error' {$cmType = '3'}
            'FailureAudit' {$cmType = '3'}
            'Information' {$cmType = '6'}
            'SuccessAudit' {$cmType = '4'}
            'Warning' {$cmType = '2'}
            'Verbose' {$cmType = '4'}
            'Debug' {$cmType = '5'}
            DEFAULT {$cmType = '1'}
        }



    } #begin
    Process {
        Write-Verbose "[$((Get-Date).TimeofDay) PROCESS] $LogEntry "

            switch ($cmType) {
                2 {
                    # Write the warning message back to the host
                    $WarningPreference = $PSCmdlet.GetVariableValue('WarningPreference')
                    Write-Warning -Message "$LogEntry"
                }

                3 {
                    if ($PSCmdlet.GetVariableValue('ErrorActionPreference') -ne 'SilentlyContinue' ) {
                        $ErrorActionPreference = $PSCmdlet.GetVariableValue('ErrorActionPreference')
                        $Host.Ui.WriteErrorLine("ERROR: $([String]$LogEntry.Exception.Message)")
                        Write-Error $LogEntry -ErrorAction ($PSCmdlet.GetVariableValue('ErrorActionPreference'))
                    }
                }

                4 {
                    # Write the verbose message back to the host
                    $VerbosePreference = $PSCmdlet.GetVariableValue('VerbosePreference')
                    Write-Verbose -Message "$LogEntry"
                }

                5 {
                    # Write the debug message to the Host.
                    $DebugPreference = $PSCmdlet.GetVariableValue('DebugPreference')
                    Write-Debug -Message "$LogEntry"
                }

                default {
                    # Write the informational message back to the host.
                    if ($PSVersionTable.PSVersion -gt 5.0.0.0){
                        $InformationPreference = $PSCmdlet.GetVariableValue('InformationPreference')
                        Write-Information -MessageData "INFORMATION: $LogEntry"
                    } else {
                        # The information stream was introduced in PowerShell v5.
                        # We have to use Write-Host in earlier versions of PowerShell.
                        Write-Debug "We are using an older version of PowerShell. Reverting to Write-Output"
                        Write-Output "INFORMATION: $LogEntry"
                    }
                }#Information
            }

    } #process
    End {
        Write-Verbose "[$((Get-Date).TimeofDay) END    ] Ending $($myinvocation.mycommand)"



    } #end
} #close Write-LogToHost