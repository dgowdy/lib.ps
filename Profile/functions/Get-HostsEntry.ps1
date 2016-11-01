﻿function Get-HostsEntry {
<# 
.SYNOPSIS 
  Breaks the Hosts file in PS Objects

.DESCRIPTION 
    Just a simple script to parse the hosts file

.EXAMPLE 
    Get-HostsEntry.ps1

    Outputs the entire hosts file with name, IP, and comment (if any)

.EXAMPLE
    Get-HostsEntry.ps1 | Where-Object { $_.Computer -match "SRV" }

    Filters the list to names that contain SRV
#> 

    $HostsFile = "$env:windir\System32\drivers\etc\hosts"

    $results = get-content  $HostsFile | Where-Object { ((-not $_.StartsWith("#")) -and ($_.Trim().Length -gt 0)) }

    $results | ForEach-Object {
        [string] $ip, [string] $hostname, [string] $comment = $_.ToString().Trim() -split "\s+"

        $InfoHash =  @{
            IP = $ip
            Computer = $hostname
            Comment = $comment.TrimStart("#").Trim()
        }
        $InfoStack = New-Object -TypeName PSObject -Property $InfoHash

        #Add a (hopefully) unique object type name
        $InfoStack.PSTypeNames.Insert(0,"Hosts.Information")

        #Sets the "default properties" when outputting the variable... but really for setting the order
        $defaultProperties = @('Computer', 'IP', 'Comment')
        $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultProperties)
        $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
        $InfoStack | Add-Member MemberSet PSStandardMembers $PSStandardMembers

        $InfoStack
    }
}

set-alias -name hosts -value Get-HostsEntry -Description "List entries in the Hosts file" -Force