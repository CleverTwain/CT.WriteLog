---
external help file: CT.WriteLog-help.xml
Module Name: CT.WriteLog
online version: http://ctwritelog.readthedocs.io/en/latest/New-Log/
schema: 2.0.0
---

# New-Log

## SYNOPSIS
Creates a new log

## SYNTAX

### PlainText (Default)
```
New-Log [-PlainText] [[-Path] <String>] [[-Header] <String>] [-Append] [-MaxLogSize <Int64>]
 [-MaxLogFiles <Int32>] [-UseLocalVariable] [-NoHostWriteBack] [-IncludeStreamName] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### Minimal
```
New-Log [-Minimal] [[-Path] <String>] [[-Header] <String>] [-Append] [-MaxLogSize <Int64>]
 [-MaxLogFiles <Int32>] [-UseLocalVariable] [-NoHostWriteBack] [-IncludeStreamName] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### CMTrace
```
New-Log [-CMTrace] [[-Path] <String>] [-Append] [-MaxLogSize <Int64>] [-MaxLogFiles <Int32>]
 [-UseLocalVariable] [-NoHostWriteBack] [-IncludeStreamName] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### EventLog
```
New-Log [-EventLog] [[-EventLogName] <String>] [-EventLogSource <String>] [-DefaultEventID <String>]
 [-UseLocalVariable] [-NoHostWriteBack] [-IncludeStreamName] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The New-Log function is used to create a new log file or Windows Event log.
A log object is also created
and either saved in the global PSLOG variable (default) or sent to the pipeline.
The latter is useful if
you need to write to different log files in the same script/function.

## EXAMPLES

### EXAMPLE 1
```
New-Log '.\myScript.log'
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

### -PlainText
Create or append to a Plain Text log file
Log Entry Example:
03-22-2018 12:37:59.168-240 INFORMATION: Generic Log Entry

```yaml
Type: SwitchParameter
Parameter Sets: PlainText
Aliases:

Required: False
Position: 1
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Minimal
Create or append to a Minimal log file
Log Entry Example:
Generic Log Entry

```yaml
Type: SwitchParameter
Parameter Sets: Minimal
Aliases:

Required: False
Position: 1
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CMTrace
Create or append to a CMTrace log file

```yaml
Type: SwitchParameter
Parameter Sets: CMTrace
Aliases:

Required: False
Position: 1
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -EventLog
Create or append to a Windows Event Log

```yaml
Type: SwitchParameter
Parameter Sets: EventLog
Aliases:

Required: False
Position: 1
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Path
Path to log file.

```yaml
Type: String
Parameter Sets: PlainText, Minimal, CMTrace
Aliases:

Required: False
Position: 2
Default value: "$env:TEMP\$(Get-Date -Format FileDateTimeUniversal).log"
Accept pipeline input: False
Accept wildcard characters: False
```

### -Header
Optionally define a header to be added when a new empty log file is created.
    Headers only apply to files, and do not apply to CMTrace files

```yaml
Type: String
Parameter Sets: PlainText, Minimal
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Append
If log file already exist, append instead of creating a new empty log file.

```yaml
Type: SwitchParameter
Parameter Sets: PlainText, Minimal, CMTrace
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxLogSize
Maximum size of log file.

```yaml
Type: Int64
Parameter Sets: PlainText, Minimal, CMTrace
Aliases:

Required: False
Position: Named
Default value: 5242880
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxLogFiles
Maximum number of log files to keep.
Default is 3.
Setting MaxLogFiles to 0 will keep all log files.

```yaml
Type: Int32
Parameter Sets: PlainText, Minimal, CMTrace
Aliases:

Required: False
Position: Named
Default value: 3
Accept pipeline input: False
Accept wildcard characters: False
```

### -EventLogName
Specifies the name of the event log.

```yaml
Type: String
Parameter Sets: EventLog
Aliases:

Required: False
Position: 4
Default value: CT.WriteLog
Accept pipeline input: False
Accept wildcard characters: False
```

### -EventLogSource
Specifies the name of the event log source.

```yaml
Type: String
Parameter Sets: EventLog
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DefaultEventID
Define the default Event ID to use when writing to the Windows Event Log.
This Event ID will be used when writing to the Windows log, but can be overrided by the Write-Log function.

```yaml
Type: String
Parameter Sets: EventLog
Aliases:

Required: False
Position: Named
Default value: 1000
Accept pipeline input: False
Accept wildcard characters: False
```

### -UseLocalVariable
When UseLocalVariable is True, the log object is not saved in the global PSLOG variable,
otherwise it's returned to the pipeline.

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
Messages written via Write-Log are also written back to the host by default.
Specifying this option, disables
that functionality for the log object.

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

### -IncludeStreamName
When writing to the log, the data stream name (DEBUG, WARNING, VERBOSE, etc.) is not included by default.
Specifying this option will include the stream name in all Write-Log messages.

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
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
