$script:ModuleName = $ENV:BHProjectName

$script:Source = Join-Path $BuildRoot $ModuleName
$script:Output = Join-Path $BuildRoot output
$script:Destination = Join-Path $Output $ModuleName
$script:ModulePath = "$Destination\$ModuleName.psm1"
$script:ManifestPath = "$Destination\$ModuleName.psd1"
$script:Imports = ( 'private', 'public', 'classes' )
$script:VariablesPath = Join-Path $PSScriptRoot "$ModuleName\private\Variables.csv"
$script:TestFile = "$PSScriptRoot\output\TestResults_PS$PSVersion`_$TimeStamp.xml"
$script:DocsRootDir = Join-Path $PSScriptRoot docs
$script:DefaultLocale = 'en-US'
$script:UpdatableHelpOutDir = Join-Path "$DocsRootDir\$DefaultLocale" OfflineHelp
$script:ModuleOutDir = $ModuleName
$global:SUTPath = $script:ManifestPath

Task Init SetAsLocal, InstallSUT
Task Default Build, Pester, Publish
Task BuildAndPublish Build, Pester, Publish
Task Build InstallSUT, CopyToOutput, BuildPSM1, BuildPSD1
Task Pester Build, UnitTests, FullTests
Task BuildHelp Build, GenerateMarkdown, GenerateHelpFiles
Task BuildUpdatableHelp BuildHelp, CoreBuildUpdatableHelp
Task BuildAllHelp BuildHelp, BuildUpdatableHelp

Task Analyze {
    Write-Output "The Analyze... it does nothing!"
}

Task Install {
    Write-Output "The Install... it does nothing!  At some point, it may copy the module to a default module location"
}

function CalculateFingerprint {
    param(
        [Parameter(ValueFromPipeline)]
        [System.Management.Automation.FunctionInfo[]] $CommandList
    )

    process {
        $fingerprint = foreach ($command in $CommandList )
        {
            foreach ($parameter in $command.parameters.keys)
            {
                '{0}:{1}' -f $command.name, $command.parameters[$parameter].Name
                $command.parameters[$parameter].aliases | Foreach-Object { '{0}:{1}' -f $command.name, $_}
            }
        }
        $fingerprint
    }
}
function PublishTestResults
{
    param(
        [string]$Path
    )
    if ($ENV:BHBuildSystem -eq 'Unknown')
    {
        return
    }
    Write-Output "Publishing test result file"
    switch ($ENV:BHBuildSystem)
    {
        'AppVeyor'
        {
            (New-Object 'System.Net.WebClient').UploadFile(
                "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
                $Path )
        }
        'VSTS'
        {
            # Skip; publish logic defined as task in vsts build config (see .vsts-ci.yml)
        }
        Default
        {
            Write-Warning "Publish test result not implemented for build system '$($ENV:BHBuildSystem)'"
        }
    }
}

function Read-Module {
    param (
        [Parameter(Mandatory)]
        [string] $Name,
        [Parameter(Mandatory)]
        [string] $Repository,
        [Parameter(Mandatory)]
        [string] $Path)

    $reader = {
        param (
            [string] $Name,
            [string] $Repository,
            [string] $Path)
        try {

            # we need to ensure $Path is one of the locations that PS will look when resolving
            # dependencies of the module it is being asked to import
            $originalPath = Get-Item -Path Env:\PSModulePath | Select-Object -Exp Value
            $psModulePaths = $originalPath -split ';' | Where-Object {$_ -ne $Path}
            $revisedPath = ( @($Path) + @($psModulePaths) | Select-Object -Unique ) -join ';'
            Set-Item -Path Env:\PSModulePath -Value $revisedPath  -EA Stop

            try {
                Save-Module -Name $Name -Path $Path -Repository $Repository -EA Stop
                Import-Module "$Path\$Name" -PassThru -EA Stop
            }
            finally {
                Set-Item -Path Env:\PSModulePath -Value $originalPath -EA Stop
            }
        }
        catch {
            if ($_ -match "No match was found for the specified search criteria") {
                @()
            }
            else {
                $_
            }
        }
    }

    $params = @{
        Name       = $Name
        Repository = $Repository
        Path       = $Path
    }

    # Create a runspace and run our $reader script to return the module requested
    # The purpose of using a runspace is to avoid loading old/duplicate versions of modules
    # into the current PS session and thus avoid any potential conflicts
    $PowerShell = [Powershell]::Create()
    [void]$PowerShell.AddScript($reader).AddParameters($params)

    # return module
    $PowerShell.Invoke()
}

Task InstallSUT {
    Invoke-PSDepend -Path "$PSScriptRoot\test.depend.psd1" -Install -Force
}

Task SetAsLocal {
    # ensure source code rather than compiled code in the output directory is being debugged / tested
    $global:SUTPath = $env:BHPSModuleManifest
}

Task Clean {
    $null = Remove-Item $Output -Recurse -ErrorAction Ignore
    $null = New-Item  -Type Directory -Path $Destination
}

Task UnitTests {
    $TestResults = Invoke-Pester -Path Tests\*unit* -PassThru -Tag Build -ExcludeTag Slow
    if ($TestResults.FailedCount -gt 0)
    {
        Write-Error "Failed [$($TestResults.FailedCount)] Pester tests"
    }
}

Task FullTests {
    $TestResults = Invoke-Pester -Path Tests -PassThru -OutputFormat NUnitXml -OutputFile $testFile -Tag Build

    PublishTestResults $testFile

    if ($TestResults.FailedCount -gt 0)
    {
        Write-Error "Failed [$($TestResults.FailedCount)] Pester tests"
    }
}

Task Specification {

    $TestResults = Invoke-Gherkin $PSScriptRoot\Spec -PassThru
    if ($TestResults.FailedCount -gt 0)
    {
        Write-Error "[$($TestResults.FailedCount)] specification are incomplete"
    }
}

Task CopyToOutput {

    Write-Output "  Create Directory [$Destination]"
    $null = New-Item -Type Directory -Path $Destination -ErrorAction Ignore

    Get-ChildItem $source -File |
        Where-Object name -NotMatch "$ModuleName\.ps[dm]1" |
        Copy-Item -Destination $Destination -Force -PassThru |
        ForEach-Object { "  Create [.{0}]" -f $_.fullname.replace($PSScriptRoot, '')}

    Get-ChildItem $source -Directory |
        Where-Object name -NotIn $imports |
        Copy-Item -Destination $Destination -Recurse -Force -PassThru |
        ForEach-Object { "  Create [.{0}]" -f $_.fullname.replace($PSScriptRoot, '')}
}

Task BuildPSM1 -Inputs (Get-Item "$source\*\*.ps1") -Outputs $ModulePath {

    [System.Text.StringBuilder]$stringbuilder = [System.Text.StringBuilder]::new()

    # Checking for variables first...
    if (Test-Path $VariablesPath) {
        $ModuleVariables = Import-Csv -Path $VariablesPath
        foreach ($Item in $ModuleVariables) {
            # Convert string versions of true and false to boolean versions if needed

            switch ($ExecutionContext.InvokeCommand.ExpandString($Item.Value)) {
                'true' {
                    $Line = "New-Variable -Name ""$($Item.VariableName)"" -Value `$true -Scope $($Item.Scope)"
                }
                'false' {
                    $Line = "New-Variable -Name ""$($Item.VariableName)"" -Value `$false -Scope $($Item.Scope)"
                }
                default {
                    $Line = "New-Variable -Name ""$($Item.VariableName)"" -Value ""$($Item.Value)"" -Scope $($Item.Scope)"
                }
            }

            [void]$stringbuilder.AppendLine($Line)

            # I don't know if these should be added to the module manifest :(
        }
    }

    foreach ($folder in $imports )
    {
        [void]$stringbuilder.AppendLine( "Write-Verbose 'Importing from [$Source\$folder]'" )
        if (Test-Path "$source\$folder")
        {
            $fileList = Get-ChildItem "$source\$folder\*.ps1" | Where-Object Name -NotLike '*.Tests.ps1'
            foreach ($file in $fileList)
            {
                $shortName = $file.fullname.replace($PSScriptRoot, '')
                Write-Output "  Importing [.$shortName]"
                [void]$stringbuilder.AppendLine( "# .$shortName" )
                [void]$stringbuilder.AppendLine( [System.IO.File]::ReadAllText($file.fullname) )
            }
        }
    }

    Write-Output "  Creating module [$ModulePath]"
    Set-Content -Path  $ModulePath -Value $stringbuilder.ToString()
}

Task PublishedModuleInfo -if (-Not ( Test-Path "$output\previous-module-info.xml" ) ) -Before BuildPSD1 {
    $downloadPath = "$output\previous-vs"
    if (-not(Test-Path $downloadPath)) {
        New-Item $downloadPath -ItemType Directory | Out-Null
    }

    $previousModule = Read-Module -Name $ModuleName -Repository ($env:PublishRepository) -Path $downloadPath

    if ($null -ne $previousModule -and $previousModule.GetType() -eq [System.Management.Automation.ErrorRecord])
    {
        Write-Error $previousModule
        return
    }

    $moduleInfo = if ($null -eq $previousModule)
    {
        [PsCustomObject] @{
            Version = [System.Version]::new(0, 0, 1)
            Fingerprint = @()
        }
    }
    else
    {
        [PsCustomObject] @{
            Version = $previousModule.Version
            Fingerprint = $previousModule.ExportedFunctions.Values | CalculateFingerprint
        }
    }
    $moduleInfo | Export-Clixml -Path "$output\previous-module-info.xml"
}

Task BuildPSD1 -inputs (Get-ChildItem $Source -Recurse -File) -Outputs $ManifestPath {

    Write-Output "  Update [$ManifestPath]"
    Copy-Item "$source\$ModuleName.psd1" -Destination $ManifestPath


    $functions = Get-ChildItem "$ModuleName\Public\*.ps1" | Where-Object { $_.name -notmatch 'Tests'} | Select-Object -ExpandProperty basename
    Set-ModuleFunctions -Name $ManifestPath -FunctionsToExport $functions
    Set-ModuleFunctions -Name "$source\$ModuleName.psd1" -FunctionsToExport $functions

    Set-ModuleAliases -Name $ManifestPath
    Set-ModuleAliases -Name "$source\$ModuleName.psd1"

    $previousModuleInfo = Import-Clixml -Path "$output\previous-module-info.xml"

    Write-Output "  Detecting semantic versioning"

    # avoid error trying to load a module twice
    Unload-SUT
    $commandList = (Import-Module ".\$ModuleName" -PassThru).ExportedFunctions.Values
    # cleanup PS session
    Unload-SUT

    Write-Output "    Calculating fingerprint"
    $fingerprint = $commandList | CalculateFingerprint

    $oldFingerprint = $previousModuleInfo.Fingerprint

    $bumpVersionType = 'Patch'
    '    Detecting new features'
    $fingerprint | Where-Object {$_ -notin $oldFingerprint } | Foreach-Object {$bumpVersionType = 'Minor'; "      $_"}
    '    Detecting breaking changes'
    $oldFingerprint | Where-Object {$_ -notin $fingerprint } | Foreach-Object {$bumpVersionType = 'Major'; "      $_"}

    # Bump the module version
    $version = [version] (Get-Metadata -Path $manifestPath -PropertyName 'ModuleVersion')

    if ( $version -lt ([version]'1.0.0') )
    {
        '    Still in beta, don''t bump major version'
        if ( $bumpVersionType -eq 'Major'  )
        {
            $bumpVersionType = 'Minor'
        }
        else
        {
            $bumpVersionType = 'Patch'
        }
    }

    $publishedVersion = $previousModuleInfo.Version
    if ( $version -lt $publishedVersion )
    {
        $version = $publishedVersion
    }
    if ($version -eq $publishedVersion)
    {
        Write-Output "  Stepping [$bumpVersionType] version [$version]"
        $version = [version] (Step-Version $version -Type $bumpVersionType)
        Write-Output "  Using version: $version"
        Update-Metadata -Path $ManifestPath -PropertyName ModuleVersion -Value $version
    }
    else
    {
        Write-Output "  Using version from $ModuleName.psd1: $version"
    }
}

Task UpdateSource {
    Copy-Item $ManifestPath -Destination "$source\$ModuleName.psd1"
}

Task PublishOld {
    # Gate deployment
    if (
        $ENV:BHBuildSystem -ne 'Unknown' -and
        $ENV:BHBranchName -eq "master" -and
        $ENV:BHCommitMessage -match '!deploy'
    )
    {
        $Params = @{
            Path  = "$BuildRoot\deploy.PSDeploy.ps1"
            Force = $true
        }

        Invoke-PSDeploy @Verbose @Params
    }
    else
    {
        "Skipping deployment: To deploy, ensure that...`n" +
        "`t* Just so you know, the path is $BuildRoot`n" +
        "`t* You are in a known build system (Current: $ENV:BHBuildSystem)`n" +
        "`t* You are committing to the master branch (Current: $ENV:BHBranchName) `n" +
        "`t* Your commit message includes !deploy (Current: $ENV:BHCommitMessage)"
    }
}

Task Publish {
    # Gate deployment
    if ( $ENV:BHCommitMessage -match '!deploy' ) {
        Write-Output 'Picked up the !deploy command'

        # Build Params
        $Params = @{
            Force = $true
            Tags = @()
        }

        switch ($ENV:BHBranchName) {
            'master' {
                Write-Output 'Adding the "prod" tag to the deployment options'
                $Params.Tags += "prod"
            }
            'develop' {
                Write-Output 'Adding the "dev" tag to the deployment options'
                $Params.Tags += "dev"
            }
        }

        if ( $ENV:BHBuildSystem -ne 'Unknown' ) {
            Write-Output 'We are using a known build system... Setting path accordingly'
            $Params.Path = $BuildRoot
        } else {
            Write-Output 'We are NOT using a known build system, so we are probably deploying privately. Updating path'
            $Params.Path = "$BuildRoot\private.PSDeploy.ps1"
        }
    }

    Write-Output "Verifying parameters"
    if ( (Test-Path -Path $Params.Path) -and ($Params.Tags -in @('prod','dev')) ) {
        Invoke-PSDeploy @Verbose @Params
    } else {
        "Skipping deployment: To deploy, ensure that...`n" +
        "`t* The Path parameter resolves to an actual path (Current: $($Params.Path))`n" +
        "`t* You are committing to the master or develop branch (Current: $ENV:BHBranchName) `n" +
        "`t* Your commit message includes !deploy (Current: $ENV:BHCommitMessage)"
    }
}

Task GenerateMarkdown {
    if (!(Get-Module platyPS -ListAvailable)) {
        "platyPS module is not installed. Skipping $($psake.context.currentTaskName) task."
        return
    }

    $moduleInfo = Import-Module $ManifestPath -Global -Force -PassThru

    try {
        if ($moduleInfo.ExportedCommands.Count -eq 0) {
            "No commands have been exported. Skipping $($psake.context.currentTaskName) task."
            return
        }

        if (!(Test-Path -LiteralPath $DocsRootDir)) {
            New-Item $DocsRootDir -ItemType Directory > $null
        }

        if (Get-ChildItem -LiteralPath $DocsRootDir -Filter *.md -Recurse) {
            Get-ChildItem -LiteralPath $DocsRootDir -Directory | ForEach-Object {
                Update-MarkdownHelp -Path $_.FullName -Verbose:$VerbosePreference > $null
            }
        }

        # ErrorAction set to SilentlyContinue so this command will not overwrite an existing MD file.
        New-MarkdownHelp -Module $ModuleName -Locale $DefaultLocale -OutputFolder $DocsRootDir\$DefaultLocale `
                         -WithModulePage -ErrorAction SilentlyContinue -Verbose:$VerbosePreference > $null
    }
    finally {
        Remove-Module $ModuleName
    }
}

Task GenerateHelpFiles {
    if (!(Get-Module platyPS -ListAvailable)) {
        "platyPS module is not installed. Skipping $($psake.context.currentTaskName) task."
        return
    }

    if (!(Get-ChildItem -LiteralPath $DocsRootDir -Filter *.md -Recurse -ErrorAction SilentlyContinue)) {
        "No markdown help files to process. Skipping $($psake.context.currentTaskName) task."
        return
    }

    $helpLocales = (Get-ChildItem -Path $DocsRootDir -Directory).Name

    # Generate the module's primary MAML help file.
    foreach ($locale in $helpLocales) {
        New-ExternalHelp -Path $DocsRootDir\$locale -OutputPath $ModuleOutDir\$locale -Force `
                         -ErrorAction SilentlyContinue -Verbose:$VerbosePreference > $null
    }
}

Task CoreBuildUpdatableHelp {
    if (!(Get-Module platyPS -ListAvailable)) {
        "platyPS module is not installed. Skipping $($psake.context.currentTaskName) task."
        return
    }

    $helpLocales = (Get-ChildItem -Path $DocsRootDir -Directory).Name

    # Create updatable help output directory.
    if (!(Test-Path -LiteralPath $UpdatableHelpOutDir)) {
        New-Item $UpdatableHelpOutDir -ItemType Directory -Verbose:$VerbosePreference > $null
    }
    else {
        Write-Verbose "$($psake.context.currentTaskName) - directory already exists '$UpdatableHelpOutDir'."
        Get-ChildItem $UpdatableHelpOutDir | Remove-Item -Recurse -Force -Verbose:$VerbosePreference
    }

    # Generate updatable help files.  Note: this will currently update the version number in the module's MD
    # file in the metadata.
    foreach ($locale in $helpLocales) {
        New-ExternalHelpCab -CabFilesFolder $ModuleOutDir\$locale -LandingPagePath $DocsRootDir\$locale\$ModuleName.md `
                            -OutputFolder $UpdatableHelpOutDir -Verbose:$VerbosePreference > $null
    }
}