# Deployment steps
This is a note to myself to help ensure consistency as I release versions. At some point this should move from being a doc to being a script ;-)

## Steps
The steps are:
* Update version number in `posh-dcos.psd1`
* Update version number in `posh-dcos.nuspec`
* commit changes
* create git tag `git tag -a v0.0.x -m "version 0.0.x"`
* push changes + tag
* Run `BuildPackage.ps1` to create nuget package
* Use tools/NuGet.exe to publish to myget feed (`.\tools\NuGet.exe push .\posh-dcos.0.0.11.nupkg -Source https://www.myget.org/F/posh-dcos/api/v2/package`)
* Use Publish-Module cmdlet to publish to PowerShell Gallery (`Publish-Module -NuGetApiKey $key -Path .\`)

## Future
* Start scripting some of this!
* Add commands where missing