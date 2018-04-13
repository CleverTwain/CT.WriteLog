---
external help file: CT.WriteLog-help.xml
Module Name: CT.WriteLog
online version: http://ctwritelog.readthedocs.io/en/latest/Write-Log/
schema: 2.0.0
---

# Write-Log

## SYNOPSIS
Write to the log and back to the host by default.

## SYNTAX

```
Write-Log [[-LogEntry] <Object>] [-LogType <String>] [-IncludeStreamName] [-NoHostWriteBack]
 [-EventID <String>] [-Log <Object>] [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
The Write-Log function is used to write to the log and by default, also write back to the host.
It is using the log object created by New-AHGLog to determine if it's going to write to a log file
or to a Windows Event log.
Log files can be created in multiple formats

## EXAMPLES

### EXAMPLE 1
```
Write-AHGLog 'Finished running WMI query'
```

Get the log object from $PSLOG and write to the log.

### EXAMPLE 2
```
$myLog | Write-AHGLog 'Finished running WMI query'
```

Use the log object saved in $myLog and write to the log.

### EXAMPLE 3
```
Write-AHGLog 'WMI query failed - Access denied!' -LogType Error -PassThru | Write-Warning
```

Will write an error to the event log, and then pass the log entry to the Write-Warning cmdlet.

## PARAMETERS

### -LogEntry
The text you want to write to the log.
Not limiting this to a string, as this function can catch exceptions as well

```yaml
Type: Object
Parameter Sets: (All)
Aliases: Message

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogType
The type of log entry.
Valid choices are 'Error', 'FailureAudit','Information','SuccessAudit' and 'Warning'.
Note that the CMTrace format only supports 3 log types (1-3), so 'Error' and 'FailureAudit' are translated to CMTrace log type 3, 'Information' and 'SuccessAudit'
are translated to 1, while 'Warning' is translated to 2.
'FailureAudit' and 'SuccessAudit' are only really included since they are valid log types when
writing to the Windows Event Log.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Type

Required: False
Position: Named
Default value: Information
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeStreamName
Include the stream name in the log entry when writing CMTrace logs

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NoHostWriteBack
Do not write the message back to the host via the specified stream
    By default, log entries are written back to the host via the specified data stream.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -EventID
Event ID.
Only applicable when writing to the Windows Event Log.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Log
The log object created using the New-Log function.
Defaults to reading the PSLOG variable.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: LogFile

Required: False
Position: Named
Default value: $Script:PSLOG
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -PassThru
PassThru passes the log entry to the pipeline for further processing.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Author: CleverTwain
Date: 4.8.2018
Dependencies: Invoke-AHGLogRotation

## RELATED LINKS
