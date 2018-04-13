# This framework is built in such a way that each public function MUST reside in its own file.

# Get public and private function definition files
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

# Dot sourcing those files loads them into memory
Foreach ($File in @($Public + $Private))
{
    Try
    {
        . $File.FullName
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($File.FullName): $_"
    }
}

$Script:ModuleBase = $PSScriptRoot

Export-ModuleMember -Function $($Public | Select-Object -ExpandProperty BaseName)