﻿Function Find-Files{
#Find-Files -Locations "\\Server1\c$\Temp", "\\Server1\c$\Test1" -SearchFor "Install.cmd"
    Param([String[]]$Locations, $SearchFor)

    Begin { }

    Process {
        $Files = @()
        ForEach ($Location in $Locations) {
            if (test-path $Location) {
                $Files += Get-ChildItem -Path $Location -Filter $SearchFor -Recurse -ErrorAction SilentlyContinue
           }
        }
    }

    End { return $Files }
}

New-Alias -name find -Value Find-Files -Description "Search multiple folders for files" -Force

function Find-InTextFile {
<# 
.SYNOPSIS 
  Search files for specified keywords

.DESCRIPTION 
    The Find-InTextFile function performs a keyword search on text files. By default,
    the function searches the current folder for files that include the plain text keyword.
    The keyword can be a regular expression if you use the -RegEx switch.
    
    The default view shows the file, line number, and a truncated excerpt of the line.
    To see the entire line of text, use the "-List" switch. 

.EXAMPLE 
    C:\> Find-InTextFile -Keyword foreach -include "*.ps1"
    
    Searches all *.ps1 files from the root of C:\ containing the word "foreach" 

.EXAMPLE
    C:\> Find-InTextFile -path c:\Scripts -keyword alias -Exclude "*.ps?1","*.ps1"

    Searches C:\Scripts for "alias" - but ignores all .ps1 and .psm1, .psd1, etc. files

.EXAMPLE 
    C:\> Find-InTextFile -Keyword ^alias -include "*.*" -regex
    
    Searches all files for lines that start with the word alias

.EXAMPLE 
    C:\> Find-InTextFile -KeyWord "^\s+[Ww]rite" -Recurse -RegEx
    
    Searches all files for lines that start with any number of spaces followed by the word Write or write

.PARAMETER <Path> 
    By default, the path will use your present working directory ($pwd)

.PARAMETER <Recurse> 
    Search subdirectories as well (default is to search only the current folder)

.PARAMETER <Include> 
    The value for this parameter filters by file name; by default it's "*.*" (all files)

.PARAMETER <Keyword> 
    This is the text for which to search. The value can be "plain" text or (with the -RegEx parameter) a regular expression 

.PARAMETER <List> 
    The default output is via Format-Table, which truncates the line with the found text. This switch will use Format-List with the full text of the line visible.

.PARAMETER <CaseSensitive>
    Performs a case sensitive search (KeyWord is different than Keyword or keyword) - of course, Regular Expressions handle case differently....

.PARAMETER <RegEx>
    The keyword is a regular expression and should be treated as such

.PARAMETER <Shorten>
    Tries to shrink the paths and text to fit more in the width of the screen (by replacing the path root with '.' and trimming spaces from text)
#> 
    PARAM( 
        [ValidateScript({ 
            If (Test-Path -Path $_.ToString() -PathType Container) { 
                $true 
            } 
            else { 
                Throw "$_ is not a valid destination folder. Enter in 'c:\directory' format" 
            } 
        })] 
        [String[]] $Path = $pwd, 
        [Alias('Filter')] 
        [String] $Include = "*.*", 
        [String[]] $Exclude,
        [Alias('Text','SearchTerm')]
        [String] $KeyWord = (Read-Host "Please enter the text for which to search: "),
        [Switch] $List,
        [Alias('Subfolders')]
        [Switch] $Recurse = $false,
        [Switch] $CaseSensitive = $false,
        [Alias('IsRegEx','RegularExpression')]
        [Switch] $RegEx = $false,
        [Switch] $NoTotals = $false,
        [Switch] $Shorten = $false
    )
    #Eesh - Get-ChildItem prefers * in the path if you actually want to find items w/out rescurse....
    $Path = (resolve-path $Path).ProviderPath
    $WorkingPath = "$($Path)*"

    if (-not $NoTotals) { Write-Host "`nSearch Root: $Path" }


    $gciParams = @{}
    $gciParams.Path = $WorkingPath
    $gciParams.Filter = $Include
    $gciParams.Recurse = $Recurse
    $gciParams.ErrorAction = 'SilentlyContinue'
    if ($exclude) { $gciParams.Exclude = $Exclude }

    $ssParams = @{}
    $ssParams.Pattern = $KeyWord
    $ssParams.CaseSensitive = $CaseSensitive
    $ssParams.SimpleMatch = -not $RegEx

    Get-ChildItem @gciParams | sort Directory,CreationTime  -Unique | 
        Select-String @ssParams -OutVariable RetVal | Out-Null 

    if ($List) {  
        $RetVal | Format-List -Property Path,LineNumber,Line  
    }  
    else {
        if ($shorten) {
            $pathFormat = @{Expression={$_.Path.ToString().Replace($path,".\")};Label="File"}
            $lineFormat = @{Expression={$_.Line.ToString().Trim()};Label="Text"}
        }
        else {
            $pathFormat = @{Expression={$_.Path};Label="File"}
            $lineFormat = @{Expression={$_.Line};Label="Text"}
    }
        $noFormat = @{Expression={$_.LineNumber};Label="Line"}
        $RetVal | Format-Table -Property $pathFormat,$noFormat,$lineFormat -AutoSize
        if (-not $NoTotals) { Write-Host "Found $($RetVal.Count) results in $(($RetVal | sort Path -unique).Count) files" }
    }
}

New-Alias -name findin -value Find-InTextFile -Description "Search files for specified keywords" -Force

function Find-Commands { get-command $args"*" }
New-Alias -name which -value Find-Commands -Description "Lists/finds commands with specified text" -Force