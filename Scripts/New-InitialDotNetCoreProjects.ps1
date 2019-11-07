<#
.SYNOPSIS
Create an initial dotnet core project

.DESCRIPTION
Create an initial dotnet core project,  also populating the project guids from the solution file into the csproj files.

.PARAMETER Prefix
The prefix for the project name.  
The script will create:

A web project called $Prefix
A unit test project called $Prefix.UnitTests
A solution file called $Prefix.sln

.EXAMPLE
New-InitialDotNetCoreProjects.ps1 --Prefix SomeProject

#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string] $Name
)

function New-BasicProject {
    param(
        [Parameter(Mandatory=$true)]
        [string] $Name    
    )


    $testProject = $Name + ".UnitTests"

    & "dotnet" "new" "web" "--name" $Name
    & "dotnet" "new" "xunit" "--name" $testProject

    & "dotnet" "new" "sln" "--name" $Name
    & "dotnet" "sln" "add" "$($Name)/$($Name).csproj"
    & "dotnet" "sln" "add" "$($testProject)/$($testProject).csproj"
}

function Invoke-PopulateProjectGuidFromSolution {
    param(        
        [Parameter(Mandatory=$true)]
        [string] $SolutionName
    )

    $solutionContent = Get-Content -Path $SolutionName

    $projects = $solutionContent | Select-String -Pattern "^Project\(.*\) = `"(.*)`", `"(.*)`", `"(.*)`"$"
    
    foreach($project in $projects) {
        $projectFile = Resolve-Path $project.Matches.Groups[2].Value
        $projectGuid = $project.Matches.Groups[3].Value

        [xml]$projectDocument = Get-Content -Path  $projectFile
        
        $projectGuidElement = $projectDocument.CreateElement("ProjectGuid")
        $projectGuidElement.InnerText = $projectGuid 

        $projectDocument.Project.PropertyGroup.AppendChild($projectGuidElement)

        $projectDocument.Save($projectFile)
    }
}

Write-Output "Creating template project for '$Name'"
New-BasicProject -Name $Name
Write-Output "Updating project files with ProjectGuids from solution"
Invoke-PopulateProjectGuidFromSolution -SolutionName "$($Name).sln"
Write-Output "Done"