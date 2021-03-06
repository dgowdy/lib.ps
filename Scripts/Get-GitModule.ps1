﻿<# 
.SYNOPSIS 
    Gets a PS Module from GitHub

.DESCRIPTION 
    Intended as a simple way to "build" my PowerShell library's Module folder. Provided the github url (well, git url, really), this script will clone the module into the folder specifed ($LibPath [C:\Scripts\Modules] or the current folder [if $LibPath isn't defined] by default). The module can be "read-only" - meaning it will only include 1 level of history (i.e., the current version) - or can be a full, normal clone.

    By default, this script will not update anything if the folder exists. I don't intend the library modules to be "live" clones, so the standard action if the module has already been cloned is to do Nothing. If you want to download a new copy, you must specify -Force, which will delete the module files and then re-download them.
    
    In my lib configuration (until I splurge on a code signing cert, anyway), I've adjusted permissions so this script must be run as admin.

    Generally, unless there are problems, this is a silent script - use -Verbose to make it noisier.

.PARAMETER Source
    Path to the git repository - any path supported by git should work (although I've only tested https)

.PARAMETER Destination
    The path where the module will copied. This is the parent path, where the name of the module (seen ModuleName parameter) will be the actual folder. Defaults to $LibPath (c:\Scripts\lib.ps\Modules) or the current folder if $LibPath isn't defined.

.PARAMETER ModuleName
    The default will be the repo name (the end of the URL path). Can be over-ridden with this switch

.PARAMETER ReadOnly
    Only clones the current version (i.e., runs 'git clone --depth 1') so as to make a "non-publishable" copy of the repo

.PARAMETER Force
    Force the removal of any existing files for this module and redownload the files. Useful for updates to "read-only" copies

.EXAMPLE
    PS C:\> Get-GitModule.ps1 -Source https://github.com/brsh/psSysInfo -Verbose -Force -ReadOnly

    Pulls down my psSysInfo module, over-writing all files, showing all messages

.EXAMPLE
    PS C:\> Get-GitModule.ps1 -Source https://github.com/brsh/psSysInfo -Force -ReadOnly -ModuleName "Dave"

    Pulls down my psSysInfo module, over-writing all files, but calls the destination folder "Dave"

.EXAMPLE
    PS C:\> Get-GitModule.ps1 -Source https://github.com/brsh/psSysInfo

    Tries to create a standard clone, failing if the destination folder already exists
#> 


param (
    [Parameter(Mandatory=$true,ValueFromPipeLine=$true)]
    [Alias('URL', 'Source')]
    [string[]] $urlPath,
    [string] $Destination = $(if ($LibPath) { "$LibPath\Modules" } else { $pwd.ProviderPath } ),
    [Parameter(Mandatory=$false)]
    [string] $ModuleName,
    [switch] $ReadOnly = $false,
    [switch] $force = $false
)

BEGIN {
    if (-not (test-path $Destination -PathType Container)) {
        try {
            mkdir $Destination -ErrorAction Stop | ForEach-Object { "Successfully created $_" }
        }
        Catch {
            Write-Warning "Failed to create the library's Module directory"
            return
        }
    }
 }

PROCESS {
    foreach ($url in $urlPath) {

        if (-not $ModuleName) {
            $ModuleName = $url.Split("/")[-1]
        }
        
        $destPath = "${Destination}\${ModuleName}"
        remove-variable ModuleName
        
        if (test-path $destPath) {
            if ($force) {
                Write-Verbose "Removing $destpath ..."
                try { 
                    Remove-Item $destPath -Force -Recurse -ErrorAction Stop
                }
                Catch {
                    Write-Warning "Unable to remove full directory structure"
                    "Error Message: {0}" -f $_.Exception.Message | Write-Warning
                    break
                }
            }
            else {
                Write-Verbose "Failed to clone $destPath"
                Write-Warning "Path $destPath already exists"
                Write-Warning "Use the -Force switch to overwrite"
                break
            }
        
        }
                
        if ($ReadOnly) {
            if ($VerbosePreference -ne [System.Management.Automation.ActionPreference]::SilentlyContinue) {
                git clone $url $destPath --depth 1
            }
            else {
                git clone $url $destPath --depth 1 --quiet
            }
        }
        else {
            if ($VerbosePreference -ne [System.Management.Automation.ActionPreference]::SilentlyContinue) {
                git clone $url $destpath
            }
            else {
                git clone $url $destpath --quiet
            }
        }
    }
}

END { }
