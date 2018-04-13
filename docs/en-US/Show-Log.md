---
external help file: CT.WriteLog-help.xml
Module Name: CT.WriteLog
online version: http://ctwritelog.readthedocs.io/en/latest/Show-Log/
schema: 2.0.0
---

# Show-Log

## SYNOPSIS
Shows a log

## SYNTAX

```
Show-Log [[-LogObject] <Object>] [[-EventLog] <String>] [[-Path] <String>] [<CommonParameters>]
```

## DESCRIPTION
The Show-Log function is used to display a log file, event log, or log object.

## EXAMPLES

### EXAMPLE 1
```
Show-Log '.\myScript.log'
```

Create a new log file called 'myScript.log' in the current folder, and save the log object in $PSLOG

### EXAMPLE 2
```
New-Log '.\myScript.log' -Header 'MyHeader - MyScript' -Append -CMTrace
```

Create a new log file called 'myScript.log' if it doesn't exist already, and add a custom header to it.
The log format used for logging by Write-Log is the CMTrace format.

### EXAMPLE 3
```
$log1 = New-Log '.\myScript_log1.log'; $log2 = New-Log '.\myScript_log2.log'
```

Create two different logs that can be written to depending on your own internal script logic.
Remember to pass the correct log object to Write-Log!

### EXAMPLE 4
```
New-Log -EventLogName 'PowerShell Scripts' -EventLogSource 'MyScript'
```

Create a new log called 'PowerShell Scripts' with a source of 'MyScript', for logging to the Windows Event Log.

## PARAMETERS

### -LogObject
Log object to show

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $Script:PSLOG
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -EventLog
Event log to show

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
File log to show

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
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

## RELATED LINKS
