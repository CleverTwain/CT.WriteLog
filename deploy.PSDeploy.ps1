# Generic module deployment.
# This stuff should be moved to psake for a cleaner deployment view

# ASSUMPTIONS:

# folder structure of:
# - RepoFolder
#   - This PSDeploy file
#   - ModuleName
#     - ModuleName.psd1

# Nuget key in $ENV:NugetApiKey

# Set-BuildEnvironment from BuildHelpers module has populated ENV:BHProjectName

# find a folder that has psd1 of same name...


if ($ENV:BHProjectName -and $ENV:BHProjectName.Count -eq 1)
{
    Deploy Module {

        By PSGalleryModule {
            FromSource output\$ENV:BHProjectName
            To $env:PublishRepository
            WithOptions @{
                ApiKey = $ENV:NugetApiKey
            }
            Tagged prod
        }

        By AppVeyorModule {
            FromSource output\$ENV:BHProjectName
            To AppVeyor
            WithOptions @{
                Version = $env:APPVEYOR_BUILD_VERSION
            }
            Tagged dev
        }
    }
}
else
{
    "Skipping deployment: To deploy, ensure that...`n" +
    "`t* You're in a known build system (Current: $ENV:BHBuildSystem)`n" +
    "`t* You're committing to the master branch (Current: $ENV:BHBranchName) `n" +
    "`t* Your commit message includes !deploy (Current: $ENV:BHCommitMessage)" |
        Write-Output
}