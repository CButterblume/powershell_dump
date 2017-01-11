#region Misc Functions
function Get-LdapEscapedText
{
    param(
        [parameter(Position = 0, Mandatory = $true)]
        $Text
        )

        $Text -replace '([^\\])([\s"#\+,;<=>\\])', "`$1\`$2"
}

function Get-DomainDN
{
    $rootDse = New-Object System.DirectoryServices.DirectoryEntry("LDAP://RootDSE")
    $rootDse.DefaultNamingContext
}

function Get-ObjectCount
{
    param(
        [parameter(ValueFromPipeline = $true, Position = 0)]
        $Data
    )
    if ($Data -is [array])
    {
        return $Data.Count
    }
    if ($Data -eq $null) 
    {
        return 0
    }
    return 1
}

function Get-LdapQuery
{
    param(
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [string[]]$query
    )

    $queryString = "(&"
    $query | % { $queryString += "($($_))" }
    $query += ")"
    return $query
}


function Convert-GuidToLdap
{
    param(
        [parameter(Position = 0, Mandatory = $true)]
        [guid]$Guid
        )
        ($Guid.ToByteArray() | foreach { '\' + $_.ToString('x2') }) -join ''
}
#endregion

#region FolderPath functions
function Test-FolderPath
{

    param(
    [parameter(Mandatory = $true, Position = 0)]
    $Path,
    [parameter(Position = 1, ValueFromPipeline = $true, ParameterSetName = "Remote")]
    $ComputerName
    )
    
    process
    {
        $server = New-Object PSObject

        if ($PSCmdlet.ParameterSetName -ne "Remote")
        {
            $result = Test-Path $Path -ErrorAction SilentlyContinue -ErrorVariable te
            if ($te -ne $null)
            {
                $server | Add-Member -MemberType NoteProperty -Name "Name" -Value "LocalComputer"
                $server | Add-Member -MemberType NoteProperty -Name "Path" -Value $Path
                $server | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed"
                $server | Add-Member -MemberType NoteProperty -Name "Message" -Value $te
                return $server
            } else {
                if ($result)
                {
                    $server | Add-Member -MemberType NoteProperty -Name "Name" -Value "LocalComputer"
                    $server | Add-Member -MemberType NoteProperty -Name "Path" -Value $Path
                    $server | Add-Member -MemberType NoteProperty -Name "Status" -Value "Success"
                    $server | Add-Member -MemberType NoteProperty -Name "Message" -Value "The specified path exists."
                } else {
                    $server | Add-Member -MemberType NoteProperty -Name "Name" -Value "LocalComputer"
                    $server | Add-Member -MemberType NoteProperty -Name "Path" -Value $Path
                    $server | Add-Member -MemberType NoteProperty -Name "Status" -Value "PathNotFound"
                    $server | Add-Member -MemberType NoteProperty -Name "Message" -Value "The specified path does not exist."
                }
                return $server
            }
        }

        $server | Add-Member -MemberType NoteProperty -Name "Name" -Value $ComputerName
        $server | Add-Member -MemberType NoteProperty -Name "Path" -Value $Path
        $serverObject = Get-ADComputer $ComputerName -ErrorAction SilentlyContinue -ErrorVariable ec
        if ($ec -ne $null)
        {
            $server | Add-Member -MemberType NoteProperty -Name "DistinguishedName" -Value "N/A"
            $server | Add-Member -MemberType NoteProperty -Name "Address" -Value "N/A"
            $server | Add-Member -MemberType NoteProperty -Name "ResponseTime" -Value "N/A"
            $server | Add-Member -MemberType NoteProperty -Name "RemotePath" -Value "N/A"
            $server | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed"
            $server | Add-Member -MemberType NoteProperty -Name "Message" -Value ($ec -join "`r`n")
            return $server
        }
        $server | Add-Member -MemberType NoteProperty -Name "DistinguishedName" -Value $serverObject.DistinguishedName

        $pingResult = Test-Connection $ComputerName -Count 4 -ErrorVariable e -ErrorAction SilentlyContinue
        if ($e -ne $null)
        {
            $server | Add-Member -MemberType NoteProperty -Name "Address" -Value "N/A"
            $server | Add-Member -MemberType NoteProperty -Name "ResponseTime" -Value "N/A"
            $server | Add-Member -MemberType NoteProperty -Name "RemotePath" -Value "N/A"
            $server | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed"
            $server | Add-Member -MemberType NoteProperty -Name "Message" -Value ($e -join "`r`n")
            return $server
            
        }
        $pingAverage = ($pingResult.ResponseTime | Measure-Object -Average).Average
        $server | Add-Member -MemberType NoteProperty -Name "Address" -Value $pingResult[0].IPV4Address
        $server | Add-Member -MemberType NoteProperty -Name "ResponseTime" -Value $pingAverage

        $p = $Path -replace "^([A-Za-z]):\\(.*?)$", "\\$ComputerName\`$1`$\`$2"
        $driveCheckPath = $Path -replace "^([A-Za-z]):\\(.*?)$", "\\$ComputerName\`$1`$"
        $server | Add-Member -MemberType NoteProperty -Name "RemotePath" -Value $p
        $driveCheck = Test-Path $driveCheckPath -ErrorAction SilentlyContinue -ErrorVariable dce

        if ($dce -ne $null)
        {
            $server | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed"
            $server | Add-Member -MemberType NoteProperty -Name "Message" -Value $dce
            return $server
        }
        if (-not $driveCheck)
        {
            $server | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed"
            $server | Add-Member -MemberType NoteProperty -Name "Message" -Value "Drive not found."
            return $server
        }

        $result = Test-Path $p -ErrorAction SilentlyContinue -ErrorVariable rte
        if ($rte -ne $null)
        {
            $server | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed"
            $server | Add-Member -MemberType NoteProperty -Name "Message" -Value $rte
            return $server
        }
        if ($result)
        {
            $server | Add-Member -MemberType NoteProperty -Name "Status" -Value "Success"
            $server | Add-Member -MemberType NoteProperty -Name "Message" -Value "The specified path exists."
        } else {
            $server | Add-Member -MemberType NoteProperty -Name "Status" -Value "PathNotFound"
            $server | Add-Member -MemberType NoteProperty -Name "Message" -Value "The specified path does not exist."
        }
        return $server
    }
}

function New-FolderPath
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='High')]
    param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        $Path,
        $ComputerName,
        [switch]$SkipFolderCreation
        )
    process
    {
        $local = Test-FolderPath $Path -ComputerName $ComputerName
        if ($local.Status -eq "Failed")
        {
            Write-Error "There is an error with the path specified: $($local.Message)"
            return $false
        }
        if ($local.Status -eq "PathNotFound" -and -not $SkipFolderCreation)
        {
            if ($pscmdlet.ShouldProcess("$($local.Path) on $($local.Name)"))
            {
                New-Item -Type Directory -Path $local.RemotePath -ErrorAction SilentlyContinue -ErrorVariable pc | Out-Null
                if ($pc -ne $null)
                {
                    Write-Error "There was an error creating the path specified: $pc"
                    return $false
                }
            } else {
                return $false
            }
        } 
        return $true
    }
}

#endregion
#region DfsrConnection

<#
.SYNOPSIS
Gets connection(s) for a given member or replication group.

.DESCRIPTION
Gets connection(s) for a given member or replication group.

.PARAMETER Member
The member to retrieve connection(s) for.

.PARAMETER ReplicationGroup
The replication group to retrieve connection(s) for.

.PARAMETER Guid
The Guid of the connection to retrieve.

.PARAMETER SendingMember
The name of the SendingMember to retrieve the connection for.

.PARAMETER Expires
Specifies that only connections that expire should be retrieved.

.PARAMETER IsExpired
Specifies that only connections that are currently expired should be retrieved.

.PARAMETER Enabled
Specified that only connections that are enabled should be returned.

.PARAMETER ResultSize
Specifies how many objects to return. If not specified, all results are returned.

.INPUTS
DfsrMember | DfsrReplicationGroup

.OUTPUTS
DfsrConnection

.EXAMPLE
Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrConnection

.EXAMPLE
Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrMember -ComputerName MyMember | Get-DfsrConnection

.EXAMPLE
#Get all expired connections
Get-DfsrConnection -IsExpired

.EXAMPLE
Get-DfsrConnection
#>
function Get-DfsrConnection
{
    [CmdletBinding()]
    param(
        [parameter(Position = 0, ValueFromPipeline = $true, ParameterSetName = "Member", Mandatory = $true)]
        [Mwcc.Management.Dfs.DfsrMember]$Member,
        [parameter(ParameterSetName = "ReplicationGroup", Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [Mwcc.Management.Dfs.DfsrReplicationGroup]$ReplicationGroup,
        [parameter(ParameterSetName = "Guid", Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [Guid]$Guid,
        [Mwcc.Management.Dfs.DfsrMember]$SendingMember,
        [switch]$Expires,
        [switch]$IsExpired,
        [System.Nullable``1[[bool]]]$Enabled,
        [System.Nullable``1[[int]]]$ResultSize,
        [parameter(ParameterSetName = "All")]
        [switch]$All
    )

    begin
    {
        if ($ResultSize -eq 0) { $Resultsize = $null }
        $ldapQuery = "(&(objectClass=msDFSR-Connection)"
        if ($SendingMember -ne $null)
        {
            $ldapQuery += "(fromServer=$($SendingMember.DistinguishedName))"
        }
        
        if ($Expires -or $IsExpired)
        {
            $ldapQuery += "(description={ConnectionExpires*})"
        }
        if ($Enabled -ne $null)
        {
            $ldapQuery += "(msDFSR-Enabled=$($Enabled.ToString().ToUpper()))"
        }
        
        $ldapQuery += ")"
        $properties = "name, objectGuid, fromServer, msDFSR-Enabled, msDFSR-Options, msDFSR-Schedule, msDFSR-RdcEnabled, msDFSR-RdcMinFileSizeInKb, msDFSR-Keywords, whenCreated, whenChanged, distinguishedName, description, objectGuid"
        $resultCounter = 0
    }

    process
    {
        if ($ResultSize -ne $null -and $resultCounter -ge $ResultSize) { break }
        if ($PSCmdlet.ParameterSetName -eq "ReplicationGroup")
        {
            Write-Debug "Getting connections for replication group $($ReplicationGroup.Name)."
            $members = $ReplicationGroup | Get-DfsrMember
            [int]$counter = 0
            foreach($tMember in $members)
            {
                $obj = Get-ADObject -searchbase "$($tMember.DistinguishedName)" -ldapfilter $ldapQuery -Properties $properties.Replace(" ", "").Split(",") -ResultSetSize $ResultSize
                foreach($o in $obj)
                {
                    if ($ResultSize -ne $null -and $resultCounter -ge $ResultSize) { break }
                    $sendMem = Get-ADObject $o."fromServer" -Properties @("msDFSR-ComputerReference")
                    $cObj = [Mwcc.Management.Dfs.DfsrConnection]::LoadFromADObject($o, $tMember, $sendMem."msDFSR-ComputerReference")
                    if ($IsExpired)
                    {
                        if ($cObj.ExpireTimestamp -lt [DateTime]::Now)
                        {
                            $cObj
                        }
                    } else {
                        $cObj
                    }
                    $resultCounter++
                }
            }
            return
        } elseif ($PSCmdlet.ParameterSetName -eq "Member")
        {
            Write-Debug "Getting connections for $($Member.ComputerName)."
            $obj = Get-ADObject -searchbase "$($Member.DistinguishedName)" -ldapfilter $ldapQuery -Properties $properties.Replace(" ", "").Split(",") -ResultSetSize $ResultSize 
        
            $now = [DateTime]::Now
            foreach($o in $obj)
            {
                if ($ResultSize -ne $null -and $resultCounter -ge $ResultSize) { break }
                $sendMem = Get-ADObject $o."fromServer" -Properties @("msDFSR-ComputerReference")
                $connObj = [Mwcc.Management.Dfs.DfsrConnection]::LoadFromADObject($o, $Member, $sendMem."msDFSR-ComputerReference")
                if ($IsExpired)
                {
                    if ($connObj.ExpireTimestamp -lt $now) { $connObj }
                } else {
                    $connObj
                }
                $resultCounter++
            }
        } elseif ($PSCmdlet.ParameterSetName -eq "Guid")
        {
            Write-Debug "Getting connections with guid of $Guid."
            $obj = Get-ADObject -ldapfilter "(&(objectClass=msDFSR-Connection)(objectGuid=$(Convert-GuidToLdap $Guid)))" -Properties $properties.Replace(" ", "").Split(",") -ResultSetSize $ResultSize
        
            $now = [DateTime]::Now
            if ($obj -eq $null) { return }
            if ($obj.DistinguishedName -imatch "^CN=[A-Z0-9-]+,(CN=[A-Z0-9-]+,CN=Topology,(CN=.*?,.*?))$")
            {
                $sName = $Matches[1]
                $replDN = $Matches[2]
                $recMem = Get-ADObject $sName -Properties @("msDFSR-ComputerReference")
            }
            $sendMem = Get-ADObject $obj."fromServer" -Properties @("msDFSR-ComputerReference")
            $connObj = [Mwcc.Management.Dfs.DfsrConnection]::LoadFromADObject($obj, $recMem."msDFSR-ComputerReference", $sendMem."msDFSR-ComputerReference", $replDN)
            if ($IsExpired)
            {
                if ($connObj.ExpireTimestamp -lt $now) { $connObj }
            } else {
                $connObj
            }
            $resultCounter++
        } else {
            Write-Debug "Getting all connections with the following query: $ldapQuery."
            $obj = Get-ADObject -searchbase "CN=DFSR-GlobalSettings,CN=System,$(Get-DomainDN)" -ldapfilter $ldapQuery -Properties $properties.Replace(" ", "").Split(",") -ResultSetSize $ResultSize
        
            $now = [DateTime]::Now
            foreach($o in $obj)
            {
                if ($ResultSize -ne $null -and $resultCounter -ge $ResultSize) { break }
                if ($o.DistinguishedName -imatch "^CN=[A-Z0-9-]+,(CN=[A-Z0-9-]+,CN=Topology,(CN=.*?,.*?))$")
                {
                    $sName = $Matches[1]
                    $replDN = $Matches[2]
                    $recMem = Get-ADObject $sName -Properties @("msDFSR-ComputerReference")
                }
                $sendMem = Get-ADObject $o."fromServer" -Properties @("msDFSR-ComputerReference")
                $connObj = [Mwcc.Management.Dfs.DfsrConnection]::LoadFromADObject($o, $recMem."msDFSR-ComputerReference", $sendMem."msDFSR-ComputerReference", $replDN)
                if ($IsExpired)
                {
                    if ($connObj.ExpireTimestamp -lt $now) { $connObj }
                } else {
                    $connObj
                }
                $resultCounter++
            }
        }
    }

    end 
    {
        Write-Verbose "Found $($resultCounter) connections."
    }
}

<#
.SYNOPSIS
Modifies a DFS connection.

.DESCRIPTION
Modifies a DFS connection.

.PARAMETER Connection
The connection to modify.

.PARAMETER Keywords
The description or keywords for the connection.

.PARAMETER Enabled
Whether the connection is enabled or disabled.

.PARAMETER RdcEnabled
Whether RDC (Remote Differential Compression) is enabled or disabled.

.PARAMETER RdcMinFileSizeInKb
If RDC is enabled, specifies the minimum file size (in KB) that RDC should be used for.

.PARAMETER UseLocalTime
If the connection schedule should use local time or UTC. True is local time.

.PARAMETER Schedule
The replication schedule for the connection. If this is not set or null, the replication
group schedule is used.

.PARAMETER Expires
Specifies that this connection should expire.

.PARAMETER ExpiresTimestamp
Specifies that this connection should expire on the timestamp provided. This parameter
requires that the Expires property must be set to True.

.PARAMETER PassThru
If this switch is specified, then the modified connection object(s) will be returned.

.INPUTS
DfsrConnection

.OUTPUTS
DfsrConnection (if the PassThru parameter is specified)

.EXAMPLE
$connections = Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrConnection
$connection | Set-DfsrConnection -RdcEnabled $true

.EXAMPLE
$connection = Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrMember -ComputerName MyMember | Get-DfsrConnection
$connection.Enabled = $false
Set-DfsrConnection -Connection $connection
#>
function Set-DfsrConnection
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    param(
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [Mwcc.Management.Dfs.DfsrConnection]$Connection,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$Keywords,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [bool]$Enabled,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [bool]$RdcEnabled,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [int]$RdcMinFileSizeInKb,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [bool]$UseLocalTime,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [Mwcc.Management.Dfs.DfsrReplicationSchedule]$Schedule,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [bool]$Expires,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [System.Nullable``1[[DateTime]]]$ExpireTimestamp,
        [switch]$PassThru
    )

    process
        {

        Write-Debug "Updating the following connect: $($Connection.SendingMember) to $($Connection.ReceivingMember)..."

        $replace = @{}
        [array]$clear = @()

        if ($Expires -eq $true)
        {
            $replace.Add("description", "{ConnectionExpires$($ExpireTimestamp.ToFileTime())}")
        } elseif ($Expires -eq $false)
        {
            $clear += "description"
        }

        if ($UseLocalTime -eq $true)
        {
            $replace.Add("msDFSR-Options", 1)
        } else {
            $replace.Add("msDFSR-Options", 0)
        }
        $replace.Add("msDFSR-Enabled", $Enabled)
        $replace.Add("msDFSR-RdcEnabled", $RdcEnabled)
        $replace.Add("msDFSR-RdcMinFileSizeInKb", $RdcMinFileSizeInKb)

        if ([string]::IsNullOrEmpty($Keywords))
        {
            $clear += "msDFSR-Keywords"
        } else {
            $replace.Add("msDFSR-Keywords", $Keywords)
        }

        if ($Schedule -ne $null)
        {
            $replace.Add("msDFSR-Schedule", $Schedule.GetBinaryData())
        } else {
            $clear += "msDFSR-Schedule"
        }

        if ($pscmdlet.ShouldProcess("$($Connection.SendingMember) to $($Connection.ReceivingMember)"))
        {
            if ($clear.Count -gt 0)
            {
                Set-ADObject $Connection.DistinguishedName -Replace $replace -Clear $clear
            } else {
                Set-ADObject $Connection.DistinguishedName -Replace $replace
            }

            if ($PassThru)
            {
                Get-DfsrConnection -Guid $Connection.Guid
            }
        }

        Write-Verbose "Updated the following connection: $($Connection.SendingMember) to $($Connection.ReceivingMember)"
    }
}

<#
.SYNOPSIS
Creates a new DFS connection.

.DESCRIPTION
Creates a new DFS connection for a member.

.PARAMETER Member
The member to create this connection for. This is the receiving member.

.PARAMETER SendingMember
The member that will be the sending member.

.PARAMETER Keywords
The description or keywords for the connection.

.PARAMETER Enabled
Whether the connection is enabled or disabled.

.PARAMETER RdcEnabled
Whether RDC (Remote Differential Compression) is enabled or disabled.

.PARAMETER RdcMinFileSizeInKb
If RDC is enabled, specifies the minimum file size (in KB) that RDC should be used for.

.PARAMETER UseLocalTime
If the connection schedule should use local time or UTC. True is local time.

.PARAMETER Schedule
The replication schedule for the connection. If this is not set or null, the replication
group schedule is used.

.PARAMETER Expires
Specifies that this connection should expire.

.PARAMETER ExpiresTimestamp
Specifies that this connection should expire on the timestamp provided. This parameter
requires that the Expires property must be set to True.

.PARAMETER PassThru
If this switch is specified, then the modified connection object(s) will be returned.

.INPUTS
DfsrConnection

.OUTPUTS
DfsrConnection (if the PassThru parameter is specified)

.EXAMPLE
# Add a new member, then add connections to the existing members
$replicationGroup = Get-DfsrReplicationGroup -Name "MyReplicationGroup"
$members = $replicationGroup | Get-DfsrMember
$newMember = $replicationGroup | New-DfsrMember -ComputerName MyNewMember
# Add a connection from New Member -> Existing Members
$members | Foreach-Object { New-DfsrConnection -Member $newMember -SendingMember $_ -Enabled $true }
# Add a connection from Existing members -> New Member
$members | New-DfsrConnection -SendingMember $newMember -Enabled $true

.EXAMPLE
# Create a new one-way, temporary connection between two existing members
$replicationGroup = Get-DfsrReplicationGroup -Name "MyReplicationGroup"
$member1 = $replicationGroup | Get-DfsrMember -ComputerName Member1
$member2 = $replicationGroup | Get-DfsrMember -ComputerName Member2
$connection = New-DfsrConnection -Member $member1 -SendingMember $member2 -Enabled $true -Expires $true -ExpiresTimestamp "12:00AM 12/31/2013"
#>
function New-DfsrConnection
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    param(
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [Mwcc.Management.Dfs.DfsrMember]$Member,
        [parameter(Mandatory = $true)]
        [Mwcc.Management.Dfs.DfsrMember]$SendingMember,
        [string]$Keywords,
        [bool]$Enabled = $true,
        [bool]$RdcEnabled = $true,
        [int]$RdcMinFileSizeInKb = 64,
        [bool]$UseLocalTime = $true,
        [Mwcc.Management.Dfs.DfsrReplicationSchedule]$Schedule,
        [switch]$PassThru,
        [bool]$Expires,
        [DateTime]$ExpireTimestamp
    )

    process
    {
        Write-Debug "Creating connection from $($SendingMember.ComputerName) to $($Member.ComputerName)."

        if ((Get-DfsrConnection -Member $Member -SendingMember $SendingMember) -ne $null)
        {
            Write-Error "A connection already exists between these servers."
            return
        }

        $properties = @{}
        if ($Expires -eq $true)
        {
            $properties.Add("description", "{ConnectionExpires$($ExpireTimestamp.ToFileTime())}")
        }

        if ($UseLocalTime -eq $true)
        {
            $properties.Add("msDFSR-Options", 1)
        } else {
            $properties.Add("msDFSR-Options", 0)
        }
        $properties.Add("msDFSR-Enabled", $Enabled)
        $properties.Add("msDFSR-RdcEnabled", $RdcEnabled)
        $properties.Add("msDFSR-RdcMinFileSizeInKb", $RdcMinFileSizeInKb)

        if (![string]::IsNullOrEmpty($Keywords))
        {
            $properties.Add("msDFSR-Keywords", $Keywords)
        }

        if ($Schedule -ne $null)
        {
            $properties.Add("msDFSR-Schedule", $Schedule.GetBinaryData())
        }

        $testServer = Test-DfsrServer $SendingMember.ComputerName
        if ($testServer.Status -ne "Success")
        {
            Write-Error "Cannot add connection:`r`n$($testServer.Message)"
            return $null
        }

        if ($Member.ReplicationGroupDN -ne $SendingMember.ReplicationGroupDN)
        {
            Write-Error "The specified DFS Servers are not members of the same replication group."
            return $null
        }

        $properties.Add("fromServer", $SendingMember.DistinguishedName)

        $guid = [guid]::NewGuid().ToString()

        if ($pscmdlet.ShouldProcess("$($SendingMember.ComputerName) to $($Member.ReceivingMember)"))
        {
            $returnObject = New-ADObject -Name $guid -Path $Member.DistinguishedName -OtherAttributes $properties -Type "msDFSR-Connection" -PassThru
            if ($PassThru)
            {
                Get-DfsrConnection -Guid $returnObject.ObjectGUID
            }
            Write-Verbose "Created connection from $($SendingMember.ComputerName) to $($Member.ComputerName)."
        }
    }
}

<#
.SYNOPSIS
Removes a DFS connection.

.DESCRIPTION
Removes a DFS connection.

.PARAMETER Connection
The connection to remove.

.INPUTS
DfsrConnection

.OUTPUTS
None

.EXAMPLE
$connections = Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrConnection
$connection | Remove-DfsrConnection
#>
function Remove-DfsrConnection
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='High')]
    param(
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [Mwcc.Management.Dfs.DfsrConnection]$Connection
    )

    process
    {
        Write-Debug "Removing connection from $($Connection.SendingComputer) to $($Connection.ComputerName)."

        if ($pscmdlet.ShouldProcess("$($Connection.SendingMember) to $($Connection.ComputerName)"))
        {
            Remove-ADObject $Connection.DistinguishedName
        }
        Write-Verbose "Removed connection from $($Connection.SendingComputer) to $($Connection.ComputerName)."
    }
}
#endregion
#region DfsrDelegatedAccess

<#
.SYNOPSIS
Gets the list of users that have been delegated access to a specified replication group(s).

.DESCRIPTION
Retrieves a list of users that have been delegated access to a replication group(s). The
replication group can be specified by either passing one or more DfsrReplicationGroup objects or by
passing one or more DistinguishedNames of replication groups. This function returns an array of type
DfsrDelegatedAccess.

.PARAMETER ReplicationGroup
This parameter specifies the replication group(s) to retrieve delegated access for.

.PARAMETER DistinguishedName
This parameter specifies the replication group(s) to retrieve delegated access for.

.INPUTS
DfsrReplicationGroup | string

.OUTPUTS
DfsrDelegatedAccess

.EXAMPLE
Get-DfsrDelegatedAccess -ReplicationGroup "CN=MyReplicationGroup,CN=DFSR-GlobalSettings,CN=System,DC=myDomain,DC=local"

.EXAMPLE
$replicationGroups = @("MyReplicationGroup", "MyOtherReplicationGroup") | Get-DfsrReplicationGroup
$replicationGroups | Get-DfsrDelegatedAccess
#>
function Get-DfsrDelegatedAccess
{
    [CmdletBinding()]
    param(
    [parameter(ValueFromPipeline = $true, Position = 0, Mandatory = $true, ParameterSetName = "Replication Group")]
    [Mwcc.Management.Dfs.DfsrReplicationGroup]$ReplicationGroup,
    [parameter(ValueFromPipeline = $true, Position = 0, Mandatory = $true, ParameterSetName = "Distinguished Name")]
    [string]$DistinguishedName
    )

    process 
    {
        if ($PSCmdlet.ParameterSetName -eq "Replication Group")
        {
            $acl = Get-Acl "AD:\$($ReplicationGroup.DistinguishedName)"
        } else {
            $acl = Get-Acl "AD:\$DistinguishedName"
        }
        $nullGuid = "00000000-0000-0000-0000-000000000000"
        $allResults = $acl.Access | ? { $_.ActiveDirectoryRights -eq "GenericAll" -and $_.ObjectType -eq $nullGuid -and $_.InheritedObjectType -eq $nullGuid -and $_.InheritanceType -eq "All" -and $_.AccessControlType -eq "Allow" }
        
        $results = $allResults | Select-Object IdentityReference -Unique | % { New-Object Mwcc.Management.Dfs.DfsrDelegatedAccess($_.IdentityReference) }
        foreach ($result in $results)
        {
            $iFlag = $false
            $allResults | ? { $_.IdentityReference -eq $result.IdentityReference } | % { if ($_.IsInherited) { $iFlag = $true } }
            if ($iFlag)
            {
                $result.SetIsInherited($true)
            } else {
                $result.SetIsInherited($false)
            }
        }
        $results
    }
}

<#
.SYNOPSIS
Grants a user delegated access to the specified replication group(s).

.DESCRIPTION
Grants a user delegated access to one or more replication groups. The replication group
is specified by passing one or more DfsrReplicationGroup objects. This function does not return a value
unless the PassThru switch is used.

.PARAMETER ReplicationGroup
This parameter specifies the replication group(s) to grant access to.

.PARAMETER Member
This parameter specifies the member to set permission on instead of a replication group. This parameter 
is primarily for internal use. Use of this parameter can result in inconsistent access between
members within a replication group. Use with caution.

.PARAMETER Username
This parameter specifies the username to grant delegated access to.

.PARAMETER PassThru
This parameter specified that this function should return the DfsrDelegatedAccess objects it has created.

.INPUTS
DfsrReplicationGroup

.OUTPUTS
DfsrDelegatedAccess (if PassThru is specified)

.EXAMPLE
$replicationGroup = Get-DfsrReplicationGroup "MyReplicationGroup"
New-DfsrDelegatedAccess -ReplicationGroup $replicationGroup -Username Domain\Username

.EXAMPLE
$replicationGroups = @("MyReplicationGroup", "MyOtherReplicationGroup") | Get-DfsrReplicationGroup
$replicationGroups | New-DfsrDelegatedAccess -Username Domain\Username
#>
function New-DfsrDelegatedAccess
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true, ParameterSetName = "ReplicationGroup")]
        [Mwcc.Management.Dfs.DfsrReplicationGroup]$ReplicationGroup,
        [Parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true, ParameterSetName = "Member")]
        [Mwcc.Management.Dfs.DfsrMember]$Member,
        [Parameter(Position = 1, Mandatory = $true)]
        [string]$Username,
        [switch]$PassThru
    )

    begin 
    {
        $pattern = "^(?:[^/\\\[\]\:;=\+\*\?<>""@]+\\[^/\\\[\]\:;=\+\*\?<>""@]+|[^/\\\[\]\:;=\+\*\?<>""@]+@[^/\\\[\]\:;=\+\*\?<>""@]+\.[^/\\\[\]\:;=\+\*\?<>""@]+)$"
        if ($Username -notmatch $pattern)
        {
            $Username = "$($env:USERDOMAIN)\$Username"
        }

        $account = New-Object System.Security.Principal.NTAccount($Username)
        [guid]$nullGuid  = [guid]"00000000-0000-0000-0000-000000000000"
        $rRights = [System.DirectoryServices.ActiveDirectoryRights]::GenericAll
        $rControlType = [System.Security.AccessControl.AccessControlType]::Allow
        $rInheritenceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::All
    }

    process
    {
        if ($pscmdlet.ParameterSetName -eq "ReplicationGroup")
        {
            Write-Debug "Attempting to add permission for $Username to Replication Group: $($ReplicationGroup.Name)."

            if ((Get-DfsrDelegatedAccess $ReplicationGroup).IdentityReference -contains $Username)
            {
                Write-Error "This user already has access to this replication group."
                return
            }

            [Mwcc.Management.Dfs.DfsrMember[]]$members = $ReplicationGroup | Get-DfsrMember
            Write-Verbose "Found $(Get-ObjectCount $members) member(s) in replication group. Permissions will be set for each member."
        } elseif ($pscmdlet.ParameterSetName -eq "Member")
        {
            Write-Debug "Attempting to add permission for $Username to Member: $($Member.Name)."
            [Mwcc.Management.Dfs.DfsrMember[]]$members = $Member
        }

        # Set permissions for each member
        if ($members.Count -gt 0)
        {
            $members | New-DelegatedAccessForMember -Username $Username
        }

        if ($pscmdlet.ParameterSetName -eq "Member")
        {
            # Don't need to set replication group permissions
            Write-Verbose "Set permissions for $Username on member: $($Member.Name)."
            if ($PassThru)
            {
                New-Object Mwcc.Management.Dfs.DfsrDelegatedAccess($Username)
            }
            return
        }

        # Set permission on replication group
        $rAcl = Get-Acl "AD:\$($ReplicationGroup.DistinguishedName)"
        $rRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($account,$rRights,$rControlType, $nullGuid, $rInheritenceType, $nullGuid)
        $rAcl.AddAccessRule($rRule)
        if ($pscmdlet.ShouldProcess("$($ReplicationGroup.Name)"))
        {
            Set-Acl $rAcl -Path "AD:\$($ReplicationGroup.DistinguishedName)"
            Write-Verbose "Set permissions for $Username on replication group: $($ReplicationGroup.Name)."
            if ($PassThru)
            {
                New-Object Mwcc.Management.Dfs.DfsrDelegatedAccess($Username)
            }
        }
    }
}

<#
.SYNOPSIS
Removes a user's delegated access to the specified replication group(s).

.DESCRIPTION
Removes a user's delegated access to one or more replication groups. The replication group
is specified by passing one or more DfsrReplicationGroup objects. This function does not return a value.

.PARAMETER ReplicationGroup
This parameter specifies the replication group(s) to remove access to.

.PARAMETER Username
This parameter specifies the username to remove delegated access to.

.INPUTS
DfsrReplicationGroup

.OUTPUTS
None

.EXAMPLE
$replicationGroup = Get-DfsrReplicationGroup "MyReplicationGroup"
Remove-DfsrDelegatedAccess -ReplicationGroup $replicationGroup -Username Domain\Username

.EXAMPLE
$replicationGroups = @("MyReplicationGroup", "MyOtherReplicationGroup") | Get-DfsrReplicationGroup
$replicationGroups | Remove-DfsrDelegatedAccess -Username Domain\Username
#>
function Remove-DfsrDelegatedAccess 
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [Mwcc.Management.Dfs.DfsrReplicationGroup]$ReplicationGroup,
        [Parameter(Position = 1, Mandatory = $true)]
        [string]$Username
    )

    begin 
    {
        $pattern = "^(?:[^/\\\[\]\:;=\+\*\?<>""@]+\\[^/\\\[\]\:;=\+\*\?<>""@]+|[^/\\\[\]\:;=\+\*\?<>""@]+@[^/\\\[\]\:;=\+\*\?<>""@]+\.[^/\\\[\]\:;=\+\*\?<>""@]+)$"
        if ($Username -notmatch $pattern)
        {
            $Username = "$($env:USERDOMAIN)\$Username"
        }

        $account = New-Object System.Security.Principal.NTAccount($Username)
        [guid]$nullGuid  = [guid]"00000000-0000-0000-0000-000000000000"
        $rRights = [System.DirectoryServices.ActiveDirectoryRights]::GenericAll
        $rControlType = [System.Security.AccessControl.AccessControlType]::Allow
        $rInheritenceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::All
    }

    process
    {
        if ((Get-DfsrDelegatedAccess $ReplicationGroup).IdentityReference -notcontains $Username)
        {
            Write-Error "This user does not currently have delegated access to this replication group."
            return
        }
        Write-Debug "Attempting to remove permission for $Username from Replication Group: $($ReplicationGroup.Name)."
        [Mwcc.Management.Dfs.DfsrMember[]]$members = $ReplicationGroup | Get-DfsrMember
        Write-Verbose "Found $(Get-ObjectCount $members) member(s) in replication group. Permissions will be removed for each member."

        # Remove permissions for each member
        $members | Remove-DelegatedAccessForMember -Username $Username

        # Remove permission on replication group
        $rAcl = Get-Acl "AD:\$($ReplicationGroup.DistinguishedName)"

        $access = $rAcl.Access | ? { $_.IdentityReference -eq $Username }

        foreach ($ace in $access)
        {
            if ($ace.ObjectType -eq $nullGuid -and $ace.ActiveDirectoryRights -eq $rRights -and $ace.AccessControlType -eq $rControlType `
                -and $ace.InheritanceType -eq $rInheritenceType -and $ace.InheritedObjectType -eq $nullGuid -and $ace.IsInherited -eq $false)
            {
                $rAcl.RemoveAccessRule($ace) | Out-Null
            }
        }

        if ($pscmdlet.ShouldProcess("$($ReplicationGroup.Name)"))
        {
            Set-Acl $rAcl -Path "AD:\$($ReplicationGroup.DistinguishedName)"
            Write-Verbose "Set permissions for $Username on replication group: $($ReplicationGroup.Name)."
        }
    }
}

function New-DelegatedAccessForMember
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    param(
        [parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0)]
        [Mwcc.Management.Dfs.DfsrMember]$Member,
        [parameter(Mandatory = $true, Position = 1)]
        $Username
    )

    begin
    {
        $pattern = "^(?:[^/\\\[\]\:;=\+\*\?<>""@]+\\[^/\\\[\]\:;=\+\*\?<>""@]+|[^/\\\[\]\:;=\+\*\?<>""@]+@[^/\\\[\]\:;=\+\*\?<>""@]+\.[^/\\\[\]\:;=\+\*\?<>""@]+)$"
        if ($Username -notmatch $pattern)
        {
            $Username = "$($env:USERDOMAIN)\$Username"
        }

        $account = New-Object System.Security.Principal.NTAccount($Username)
        [guid]$nullGuid  = [guid]"00000000-0000-0000-0000-000000000000"
        $controlType = [System.Security.AccessControl.AccessControlType]::Allow
        $rights = [System.DirectoryServices.ActiveDirectoryRights]::WriteProperty
        $inheritType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::Children
        [guid]$inheritedObjectType = [guid]"67212414-7bcc-4609-87e0-088dad8abdee"
        $deleteRights = [System.DirectoryServices.ActiveDirectoryRights]::DeleteTree
        $deleteControlType = [System.Security.AccessControl.AccessControlType]::Allow
        $deleteInheritenceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::SelfAndChildren
        $fcRights = [System.DirectoryServices.ActiveDirectoryRights]::GenericAll
        $fcControlType = [System.Security.AccessControl.AccessControlType]::Allow
        $fcInheritenceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::None

        [guid[]]$dfsrObjectType = @()
        $dfsrObjectType += [guid]"78f011ec-a766-4b19-adcf-7b81ed781a4d"
        $dfsrObjectType += [guid]"03726ae7-8e7d-4446-8aae-a91657c00993"
        $dfsrObjectType += [guid]"db7a08e7-fc76-4569-a45f-f5ecb66a88b5"
        $dfsrObjectType += [guid]"9ad33fc9-aacf-4299-bb3e-d1fc6ea88e49"
        $dfsrObjectType += [guid]"90b769ac-4413-43cf-ad7a-867142e740a3"
        $dfsrObjectType += [guid]"f7b85ba9-3bf9-428f-aab4-2eee6d56f063"
        $dfsrObjectType += [guid]"fe515695-3f61-45c8-9bfa-19c148c57b09"
        $dfsrObjectType += [guid]"51928e94-2cd8-4abe-b552-e50412444370"
        $dfsrObjectType += [guid]"2ab0e48d-ac4e-4afc-83e5-a34240db6198"
        $dfsrObjectType += [guid]"d6d67084-c720-417d-8647-b696237a114c"
        $dfsrObjectType += [guid]"4c5d607a-ce49-444a-9862-82a95f5d1fcc"
        $dfsrObjectType += [guid]"5ac48021-e447-46e7-9d23-92c0c6a90dfb"
        $dfsrObjectType += [guid]"250a8f20-f6fc-4559-ae65-e4b24c67aebe"
    }

    process
    {
        Write-Debug "Attempting to add permissions for $Username on DFSR Member: $($Member.ComputerName)."
        $acl = Get-Acl "AD:\CN=$($Member.Name),CN=DFSR-LocalSettings,$($Member.ComputerNameDN)"
        Write-Verbose "Found ACL for Member: $($Member.ComputerName)."
        foreach($objectType in $dfsrObjectType)
        {
            $rule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($account,$rights,$controlType, $objectType, $inheritType, $inheritedObjectType)
            try 
            {
                $acl.AddAccessRule($rule)
            }
            catch
            {
                Write-Error "An error occurred while trying to delegate permission on $($Member.ComputerName) for user $Username."
                return
            }
        }

        $deleteRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($account,$deleteRights,$deleteControlType, $nullGuid, $deleteInheritenceType, $nullGuid)
        $acl.AddAccessRule($deleteRule)

        $fcRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($account,$fcRights,$fcControlType, $nullGuid, $fcInheritenceType, $nullGuid)
        $acl.AddAccessRule($fcRule)

        if ($pscmdlet.ShouldProcess("$($Member.ComputerName)"))
        {
            Set-Acl $acl -Path "AD:\CN=$($Member.Name),CN=DFSR-LocalSettings,$($Member.ComputerNameDN)"
            Write-Verbose "Set ACL for Member: $($Member.ComputerName)."
        }
    }
}

function Remove-DelegatedAccessForMember
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    param(
        [parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0)]
        [Mwcc.Management.Dfs.DfsrMember]$Member,
        [parameter(Mandatory = $true, Position = 1)]
        $Username
    )

    begin
    {
        $pattern = "^(?:[^/\\\[\]\:;=\+\*\?<>""@]+\\[^/\\\[\]\:;=\+\*\?<>""@]+|[^/\\\[\]\:;=\+\*\?<>""@]+@[^/\\\[\]\:;=\+\*\?<>""@]+\.[^/\\\[\]\:;=\+\*\?<>""@]+)$"
        if ($Username -notmatch $pattern)
        {
            $Username = "$($env:USERDOMAIN)\$Username"
        }

        $account = New-Object System.Security.Principal.NTAccount($Username)
        [guid]$nullGuid  = [guid]"00000000-0000-0000-0000-000000000000"
        $controlType = [System.Security.AccessControl.AccessControlType]::Allow
        $rights = [System.DirectoryServices.ActiveDirectoryRights]::WriteProperty
        $inheritType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::Children
        [guid]$inheritedObjectType = [guid]"67212414-7bcc-4609-87e0-088dad8abdee"
        $deleteRights = [System.DirectoryServices.ActiveDirectoryRights]::DeleteTree
        $deleteControlType = [System.Security.AccessControl.AccessControlType]::Allow
        $deleteInheritenceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::SelfAndChildren
        $fcRights = [System.DirectoryServices.ActiveDirectoryRights]::GenericAll
        $fcControlType = [System.Security.AccessControl.AccessControlType]::Allow
        $fcInheritenceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::None

        [guid[]]$dfsrObjectType = @()
        $dfsrObjectType += [guid]"78f011ec-a766-4b19-adcf-7b81ed781a4d"
        $dfsrObjectType += [guid]"03726ae7-8e7d-4446-8aae-a91657c00993"
        $dfsrObjectType += [guid]"db7a08e7-fc76-4569-a45f-f5ecb66a88b5"
        $dfsrObjectType += [guid]"9ad33fc9-aacf-4299-bb3e-d1fc6ea88e49"
        $dfsrObjectType += [guid]"90b769ac-4413-43cf-ad7a-867142e740a3"
        $dfsrObjectType += [guid]"f7b85ba9-3bf9-428f-aab4-2eee6d56f063"
        $dfsrObjectType += [guid]"fe515695-3f61-45c8-9bfa-19c148c57b09"
        $dfsrObjectType += [guid]"51928e94-2cd8-4abe-b552-e50412444370"
        $dfsrObjectType += [guid]"2ab0e48d-ac4e-4afc-83e5-a34240db6198"
        $dfsrObjectType += [guid]"d6d67084-c720-417d-8647-b696237a114c"
        $dfsrObjectType += [guid]"4c5d607a-ce49-444a-9862-82a95f5d1fcc"
        $dfsrObjectType += [guid]"5ac48021-e447-46e7-9d23-92c0c6a90dfb"
        $dfsrObjectType += [guid]"250a8f20-f6fc-4559-ae65-e4b24c67aebe"
    }

    process
    {
        Write-Debug "Attempting to remove permissions for $Username on DFSR Member: $($Member.ComputerName)."
        $acl = Get-Acl "AD:\CN=$($Member.Name),CN=DFSR-LocalSettings,$($Member.ComputerNameDN)"
        $access = $acl.Access | ? { $_.IdentityReference -eq $Username }

        Write-Verbose "Found ACL for Member: $($Member.ComputerName)."

        foreach ($ace in $access)
        {
            if ($dfsrObjectType -contains $ace.ObjectType -and $ace.ActiveDirectoryRights -eq $rights -and $ace.AccessControlType -eq $controlType `
                -and $ace.InheritanceType -eq $inheritType -and $ace.InheritedObjectType -eq $inheritedObjectType -and $ace.IsInherited -eq $false)
            {
                $acl.RemoveAccessRule($ace) | Out-Null
            }

            if ($ace.ObjectType -eq $nullGuid -and $ace.ActiveDirectoryRights -eq $fcRights -and $ace.AccessControlType -eq $fcControlType `
                -and $ace.InheritanceType -eq $fceInheritenceType -and $ace.InheritedObjectType -eq $nullGuid -and $ace.IsInherited -eq $false)
            {
                $acl.RemoveAccessRule($ace) | Out-Null
            }

            if ($ace.ObjectType -eq $nullGuid -and $ace.ActiveDirectoryRights -eq $deleteRights -and $ace.AccessControlType -eq $deleteControlType `
                -and $ace.InheritanceType -eq $deleteInheritenceType -and $ace.InheritedObjectType -eq $nullGuid -and $ace.IsInherited -eq $false)
            {
                $acl.RemoveAccessRule($ace) | Out-Null
            }
        }

        if ($pscmdlet.ShouldProcess("$($Member.ComputerName)"))
        {
            Set-Acl $acl -Path "AD:\CN=$($Member.Name),CN=DFSR-LocalSettings,$($Member.ComputerNameDN)"
            Write-Verbose "Set ACL for Member: $($Member.ComputerName)."
        }
    }
}

<#
.SYNOPSIS
Test if a user has delegated access to the specified replication group(s) and member(s) of the replication groups.

.DESCRIPTION
Tests if a user has delegated access to one or more replication groups. The replication group
is specified by passing a DfsrReplicationGroup object. This function does not return a value.

.PARAMETER ReplicationGroup
This parameter specifies the replication group(s) to test.

.PARAMETER Username
This parameter specifies the username to test.

.INPUTS
None

.OUTPUTS
Bool

.EXAMPLE
$replicationGroup = Get-DfsrReplicationGroup "MyReplicationGroup"
Test-DfsrDelegatedAccess -ReplicationGroup $replicationGroup -Username Domain\Username
#>
function Test-DfsrDelegatedAccess
{
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [Mwcc.Management.Dfs.DfsrReplicationGroup]$ReplicationGroup,
        [Parameter(Position = 1, Mandatory = $true)]
        [string]$Username
    )

    begin 
    {
        $pattern = "^(?:[^/\\\[\]\:;=\+\*\?<>""@]+\\[^/\\\[\]\:;=\+\*\?<>""@]+|[^/\\\[\]\:;=\+\*\?<>""@]+@[^/\\\[\]\:;=\+\*\?<>""@]+\.[^/\\\[\]\:;=\+\*\?<>""@]+)$"
        if ($Username -notmatch $pattern)
        {
            $Username = "$($env:USERDOMAIN)\$Username"
        }

        $account = New-Object System.Security.Principal.NTAccount($Username)
        [guid]$nullGuid  = [guid]"00000000-0000-0000-0000-000000000000"
        $rRights = [System.DirectoryServices.ActiveDirectoryRights]::GenericAll
        $rControlType = [System.Security.AccessControl.AccessControlType]::Allow
        $rInheritenceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::All
    }

    process
    {
        Write-Debug "Attempting to test permission for $Username from Replication Group: $($ReplicationGroup.Name)."
        #$userList = $ReplicationGroup.DelegatedAccess.IdentityReference
        [Mwcc.Management.Dfs.DfsrMember[]]$members = $ReplicationGroup | Get-DfsrMember
        Write-Verbose "Found $(Get-ObjectCount $members) member(s) in replication group. Permissions will be checked for each member."

        # Check permission on replication group
        $rAcl = Get-Acl "AD:\$($ReplicationGroup.DistinguishedName)"

        [array]$access = $rAcl.Access | ? { $_.IdentityReference -eq $Username }

        if ($access.Count -eq 0) { return $false }
        foreach ($ace in $access)
        {
            if ($ace.ObjectType -ne $nullGuid -or $ace.ActiveDirectoryRights -ne $rRights -or $ace.AccessControlType -ne $rControlType `
                -or $ace.InheritanceType -ne $rInheritenceType -or $ace.InheritedObjectType -ne $nullGuid)
            {
                return $false
            }
        }

        Write-Verbose "Access is set properly for the replication group."
        
        Write-Verbose "Checking permissions on each member."
        foreach($memberObject in $members)
        {
            $testMember = Test-DelegatedAccessForMember -Member $memberObject -Username $Username
            if ($testMember -eq $false)
            {
                return $false
            }
            Write-Verbose "Access is set properly on $($member.ComputerName)."
        }

        return $true
    }
}

function Test-DelegatedAccessForMember
{
    [CmdletBinding()]
    param(
        [parameter(ValueFromPipeline = $true, Mandatory = $true, Position = 0)]
        [Mwcc.Management.Dfs.DfsrMember]$Member,
        [parameter(Mandatory = $true, Position = 1)]
        $Username
    )

    begin
    {
        $pattern = "^(?:[^/\\\[\]\:;=\+\*\?<>""@]+\\[^/\\\[\]\:;=\+\*\?<>""@]+|[^/\\\[\]\:;=\+\*\?<>""@]+@[^/\\\[\]\:;=\+\*\?<>""@]+\.[^/\\\[\]\:;=\+\*\?<>""@]+)$"
        if ($Username -notmatch $pattern)
        {
            $Username = "$($env:USERDOMAIN)\$Username"
        }

        $account = New-Object System.Security.Principal.NTAccount($Username)
        [guid]$nullGuid  = [guid]"00000000-0000-0000-0000-000000000000"
        $controlType = [System.Security.AccessControl.AccessControlType]::Allow
        $rights = [System.DirectoryServices.ActiveDirectoryRights]::WriteProperty
        $inheritType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::Children
        [guid]$inheritedObjectType = [guid]"67212414-7bcc-4609-87e0-088dad8abdee"
        $deleteRights = [System.DirectoryServices.ActiveDirectoryRights]::DeleteTree
        $deleteControlType = [System.Security.AccessControl.AccessControlType]::Allow
        $deleteInheritenceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::SelfAndChildren
        $fcRights = [System.DirectoryServices.ActiveDirectoryRights]::GenericAll
        $fcControlType = [System.Security.AccessControl.AccessControlType]::Allow
        $fcInheritenceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::None

        [guid[]]$dfsrObjectType = @()
        $dfsrObjectType += [guid]"78f011ec-a766-4b19-adcf-7b81ed781a4d"
        $dfsrObjectType += [guid]"03726ae7-8e7d-4446-8aae-a91657c00993"
        $dfsrObjectType += [guid]"db7a08e7-fc76-4569-a45f-f5ecb66a88b5"
        $dfsrObjectType += [guid]"9ad33fc9-aacf-4299-bb3e-d1fc6ea88e49"
        $dfsrObjectType += [guid]"90b769ac-4413-43cf-ad7a-867142e740a3"
        $dfsrObjectType += [guid]"f7b85ba9-3bf9-428f-aab4-2eee6d56f063"
        $dfsrObjectType += [guid]"fe515695-3f61-45c8-9bfa-19c148c57b09"
        $dfsrObjectType += [guid]"51928e94-2cd8-4abe-b552-e50412444370"
        $dfsrObjectType += [guid]"2ab0e48d-ac4e-4afc-83e5-a34240db6198"
        $dfsrObjectType += [guid]"d6d67084-c720-417d-8647-b696237a114c"
        $dfsrObjectType += [guid]"4c5d607a-ce49-444a-9862-82a95f5d1fcc"
        $dfsrObjectType += [guid]"5ac48021-e447-46e7-9d23-92c0c6a90dfb"
        $dfsrObjectType += [guid]"250a8f20-f6fc-4559-ae65-e4b24c67aebe"
    }

    process
    {
        Write-Debug "Checking permissions for $Username on DFSR Member: $($Member.ComputerName)."
        $acl = Get-Acl "AD:\CN=$($Member.Name),CN=DFSR-LocalSettings,$($Member.ComputerNameDN)"
        $access = $acl.Access | ? { $_.IdentityReference -eq $Username }

        Write-Verbose "Found ACL for Member: $($Member.ComputerName)."

        [guid[]]$checkGuidList = @()
        [bool]$checkGuid = $true
        foreach ($ace in $access)
        {
            if ($dfsrObjectType -contains $ace.ObjectType -and $ace.ActiveDirectoryRights -eq $rights -and $ace.AccessControlType -eq $controlType `
                -and $ace.InheritanceType -eq $inheritType -and $ace.InheritedObjectType -eq $inheritedObjectType)
            {
                $checkGuidList += [guid]$ace.ObjectType
            }

            if ($ace.ObjectType -eq $nullGuid -and $ace.ActiveDirectoryRights -eq $fcRights -and $ace.AccessControlType -eq $fcControlType `
                -and $ace.InheritanceType -eq $fceInheritenceType -and $ace.InheritedObjectType -eq $nullGuid)
            {
                $checkFullControl = $true
            }

            if ($ace.ObjectType -eq $nullGuid -and $ace.ActiveDirectoryRights -eq $deleteRights -and $ace.AccessControlType -eq $deleteControlType `
                -and $ace.InheritanceType -eq $deleteInheritenceType -and $ace.InheritedObjectType -eq $nullGuid)
            {
                $checkDelete = $true
            }
        }

        $dfsrObjectType | % { if ($checkGuidList -notcontains $_) { $checkGuid = $false } }

        if ($checkDelete -eq $true -and $checkGuid -eq $true)
        {
            return $true
        } else {
            return $false
        }
    }
}
#endregion
#region DfsrFolder

<#
.SYNOPSIS
Gets a folder(s) for a replication group.

.DESCRIPTION
Gets a folder(s) for a replication group.

.PARAMETER ReplicationGroup
The replication group to retrieve folder(s) for.

.PARAMETER Name
The name of the folder(s) to retrieve.

.PARAMETER Guid
The Guid of the connection to retrieve.

.PARAMETER ResultSize
Specifies how many objects to return. If not specified, all results are returned.

.INPUTS
DfsrReplicationGroup | string

.OUTPUTS
DfsrFolder

.EXAMPLE
Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrFolder

.EXAMPLE
Get-DfsrFolder -Name "MyFolder"

.EXAMPLE
#Get all folders
Get-DfsrFolder
#>
function Get-DfsrFolder
{
    [CmdletBinding()]
    param(
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true, ParameterSetName = "ReplicationGroup")]
        [Mwcc.Management.Dfs.DfsrReplicationGroup]$ReplicationGroup,
        [parameter(ParameterSetName = "ReplicationGroup")]
        [parameter(ParameterSetName = "Name", Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Name,
        [parameter(ParameterSetName = "Guid", Position = 0, Mandatory = $true)]
        [Guid]$Guid,
        [System.Nullable``1[[int]]]$ResultSize,
        [parameter(ParameterSetName = "All")]
        [switch]$All
    )

    begin
    {
        if ($ResultSize -eq 0) { $ResultSize = $null }
        $properties = "name, description, msDFSR-DfsPath, msDFSR-FileFilter, msDFSR-DirectoryFilter, whenCreated, whenChanged, distinguishedName, objectGuid"
        $resultCount = 0
    }

    process
    {
        if ($ResultSize -ne $null -and $resultCounter -ge $ResultSize) { break }
        if ($PSCmdlet.ParameterSetName -eq "Guid")
        {
            Write-Debug "Searching for Folder with a Guid of: $Guid"
            $ldapQuery = "(&(objectClass=msDFSR-ContentSet)(objectGuid=$(Convert-GuidToLdap $Guid)))"
            $searchBase = "CN=DFSR-GlobalSettings,CN=System,$(Get-DomainDN)"

        } elseif ($PSCmdlet.ParameterSetName -eq "All")
        {
            Write-Debug "Searching for all folders."
            $ldapQuery = "(objectClass=msDFSR-ContentSet)"
            $searchBase = "CN=DFSR-GlobalSettings,CN=System,$(Get-DomainDN)"

        } elseif ($PSCmdlet.ParameterSetName -eq "ReplicationGroup") {
            $msg = "Getting DFSR folders for replication group: $($ReplicationGroup.Name)"
       
            $ldapQuery = "(objectClass=msDFSR-ContentSet)"
            if (![string]::IsNullOrEmpty($Name))
            {
                $ldapQuery = "(&$($ldapQuery)(name=$($Name)))"
                $msg += ", with a name like $($Name)"
            }

            $searchBase = "CN=Content,$($ReplicationGroup.DistinguishedName)"

            Write-Debug "$msg."
        } elseif ($PSCmdlet.ParameterSetName -eq "Name")
        {
            Write-Debug "Searching for folders with a name of: $Name..."
            $ldapQuery = "(&(objectClass=msDFSR-ContentSet)(name=$($Name)))"
            $searchBase = "CN=DFSR-GlobalSettings,CN=System,$(Get-DomainDN)"
        }

        $obj = Get-ADObject -searchbase $searchBase -ldapfilter $ldapQuery -Properties $properties.Replace(" ", "").Split(",") -ResultSetSize $ResultSize
        foreach($o in $obj)
        {
            if ($ResultSize -ne $null -and $resultCount -ge $ResultSize) { break }
            if ($PSCmdlet.ParameterSetName -eq "ReplicationGroup")
            {
                [Mwcc.Management.Dfs.DfsrFolder]::LoadFromADObject($o, $ReplicationGroup)
            } else {
                if ($o.DistinguishedName -match "^CN=.*?,CN=Content,(CN=.*?,.*?)$")
                {
                    $groupDistinguishedName = $Matches[1]
                }
                [Mwcc.Management.Dfs.DfsrFolder]::LoadFromADObject($o, $groupDistinguishedName)
            }
            $resultCount++
        }
    }

    end
    {
        Write-Verbose "Found $($resultCount) Folders."
    }
}

<#
.SYNOPSIS
Modifies a DFS folder.

.DESCRIPTION
Modifies a DFS folder.

.PARAMETER Folder
The folder to modify.

.PARAMETER Description
The description for the folder.

.PARAMETER DfsnPath
The UNC path of this folder when used with DFSN.

.PARAMETER FileFilter
A comma separated list of files to exclude. This can include wildcards.

.PARAMETER DirectoryFilter
A comma separated list of directories to exclude. This can include wildcards.

.PARAMETER PassThru
If this switch is specified, then the modified connection object(s) will be returned.

.INPUTS
DfsrFolder

.OUTPUTS
DfsrFolder (if the PassThru parameter is specified)

.EXAMPLE
# Get all folders in a namespace
$folders = Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrFolder
# Set the DFSN path
$folders | Set-DfsrFolder -DfsnPath "\\domain.local\Path"

.EXAMPLE
$folder = Get-DfsrFolder "MyFolder"
$folder.Description = "My description"
$folder.FileFilter = "~*, *.tmp, *.bak"
$folder | Set-DfsrFolder
#>
function Set-DfsrFolder
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    param(
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [Mwcc.Management.Dfs.DfsrFolder]$Folder,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$Description,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$DfsnPath,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$FileFilter,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$DirectoryFilter,
        [switch]$PassThru
    )

    process
    {
        [array]$clear = @()
        $replace = @{}

        Write-Debug "Updating DFSR Folder: $($Folder.Name)."

        if ([string]::IsNullOrEmpty($Description))
        {
            $clear += "description"
        } else {
            $replace.Add("description", $Description)
        }

        if ([string]::IsNullOrEmpty($DfsnPath))
        {
            $clear += "msDFSR-DfsPath"
        } else {
            $replace.Add("msDFSR-DfsPath", $DfsnPath)
        }

        if ([string]::IsNullOrEmpty($FileFilter))
        {
            $clear += "msDFSR-FileFilter"
        } else {
            $replace.Add("msDFSR-FileFilter", $FileFilter)
        }

        if ([string]::IsNullOrEmpty($DirectoryFilter))
        {
            $clear += "msDFSR-DirectoryFilter"
        } else {
            $replace.Add("msDFSR-DirectoryFilter", $DirectoryFilter)
        }

        if ($pscmdlet.ShouldProcess("$($Folder.Name)"))
        {
            if ($replace.Count -gt 0 -and $clear.Count -gt 0)
            {
                Set-ADObject $Folder.DistinguishedName -Replace $replace -Clear $clear
            } 
            elseif ($replace.Count -gt 0 -and $clear.Count -le 0)
            {
                Set-ADObject $Folder.DistinguishedName -Replace $replace
            }
            elseif ($replace.Count -le 0 -and $clear.Count -gt 0)
            {
                Set-ADObject $Folder.DistinguishedName -Clear $clear
            }

            if ($PassThru)
            {
                Get-DfsrFolder -Guid $Folder.Guid
            }
            Write-Verbose "Updated Folder: $($Folder.Name)."
        }
    }
}

<#
.SYNOPSIS
Creates a new DFS folder.

.DESCRIPTION
Creates a new DFS folder.

.PARAMETER ReplicationGroup
The replication group to create this folder in.

.PARAMETER Name
The name of the folder to create.

.PARAMETER Description
The description for the folder.

.PARAMETER DfsnPath
The UNC path of this folder when used with DFSN.

.PARAMETER FileFilter
A comma separated list of files to exclude. This can include wildcards.

.PARAMETER DirectoryFilter
A comma separated list of directories to exclude. This can include wildcards.

.PARAMETER PassThru
If this switch is specified, then the modified connection object(s) will be returned.

.INPUTS
DfsrReplicationGroup

.OUTPUTS
DfsrFolder (if the PassThru parameter is specified)

.EXAMPLE
$newFolder = Get-DfsrReplicationGroup -Name "MyReplicationGroup" | New-DfsrFolder -Name "MyNewFolder" -Description "A description" -PassThru
#>
function New-DfsrFolder
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    param(
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [Mwcc.Management.Dfs.DfsrReplicationGroup]$ReplicationGroup,
        [parameter(Position = 1, Mandatory = $true)]
        [string]$Name,
        [string]$Description,
        [string]$DfsnPath,
        [string]$FileFilter = "~*, *.bak, *.tmp",
        [string]$DirectoryFilter,
        [switch]$PassThru
    )

    process
    {
        Write-Debug "Creating new Folder $Name in replication group $($ReplicationGroup.Name)."
        if ((Get-DfsrFolder -ReplicationGroup $ReplicationGroup -Name $Name) -ne $null)
        {
            Write-Error "A folder with this name already exists in this replication group."
            return
        }

        $properties = @{}
        if (![string]::IsNullOrEmpty($Description)) { $properties.Add("description", $Description) }
        if (![string]::IsNullOrEmpty($DfsnPath)) { $properties.Add("msDFSR-DfsPath", $DfsnPath) }
        if (![string]::IsNullOrEmpty($FileFilter)) { $properties.Add("msDFSR-FileFilter", $FileFilter) }
        if (![string]::IsNullOrEmpty($DirectoryFilter)) { $properties.Add("msDFSR-DirectoryFilter", $DirectoryFilter) }

        if ($pscmdlet.ShouldProcess("$($Name)"))
        {
            New-ADObject -Name $Name -Path "CN=Content,$($ReplicationGroup.DistinguishedName)" -OtherAttributes $properties -Type "msDFSR-ContentSet"
            if ($PassThru)
            {
                Get-DfsrFolder $Name
            }
            Write-Verbose "Created new folder $Name in replication group $($ReplicationGroup.Name)."
        }
    }
}

<#
.SYNOPSIS
Removes a DFS folder.

.DESCRIPTION
Removes a DFS folder. This will also remove any folder memberships for this folder.
If the -SkipMembershipRemoval switch is used, then folder memberships will be
left in place.

.PARAMETER Folder
The folder to remove.

.PARAMETER SkipMembershipRemoval
If this switch is specified, then folder memberships for this folder will
not be removed.

.INPUTS
DfsrFolder

.OUTPUTS
None

.EXAMPLE
# Remove all folders in a namespace
$folders = Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Remove-DfsrFolder

.EXAMPLE
$folder = Get-DfsrFolder "MyFolder"
Remove-DfsrFolder -Folder $folder
#>
function Remove-DfsrFolder
{
[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='High')]
    param(
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [Mwcc.Management.Dfs.DfsrFolder]$Folder,
        [switch]$SkipMembershipRemoval
    )

    process
    {
        Write-Debug "Removing DFSR Folder $($Folder.Name) in replication group $($Folder.ReplicationGroup)."

        if (!$SkipMembershipRemoval)
        {
            Write-Verbose "Attempting to remove folder memberships for folder $($Folder.Name)."
            Get-DfsrFolderMembership -Folder $Folder | Remove-DfsrFolderMembership
        }

        if ($pscmdlet.ShouldProcess("$($Folder.Name)"))
        {
            Remove-ADObject $Folder.DistinguishedName
            Write-Verbose "Removed $($Folder.Name)."
        }
    }

}
#endregion
#region DfsrFolderMembership

<#
.SYNOPSIS
Gets a folder membership for a DFS folder.

.DESCRIPTION
Gets a folder membership for a DFS folder.

.PARAMETER Folder
The DFS folder to retrieve membership of.

.PARAMETER Member
The member server to retrieve folder membership for.

.PARAMETER ComputerName
The name of a member to retrieve folder membership for.

.PARAMETER Guid
The Guid of the folder membership to retrieve.

.PARAMETER Enabled
Specifies that only folder memberships that are enabled (true) or disabled (false) should be returned. 
Specifying a value of null or omitting this parameter returns folder memberships regardless of being enabled or disabled.

.PARAMETER Expires
Specifies that only folder memberships that expire should be retrieved.

.PARAMETER IsExpired
Specifies that only folder memberships that are currently expired should be retrieved.

.PARAMETER ResultSize
Specifies how many objects to return. If not specified, all results are returned.

.INPUTS
DfsrFolder | DfsrMember | string

.OUTPUTS
DfsrFolderMembers

.EXAMPLE
$folder = Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrFolder "FolderName"
$folderMembership = Get-DfsrFolderMembership -Folder $folder

.EXAMPLE
Get-DfsrFolderMembership -ComputerName "MyServer"

.EXAMPLE
#Get all folder memberships
Get-DfsrFolderMembership
#>
function Get-DfsrFolderMembership
{
    [CmdletBinding()]
    param(
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true, ParameterSetName = "Folder")]
        [Mwcc.Management.Dfs.DfsrFolder]$Folder,
        [parameter(ParameterSetName = "Folder")]
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true, ParameterSetName = "Member")]
        [Mwcc.Management.Dfs.DfsrMember]$Member,
        [parameter(ParameterSetName = "Folder")]
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true, ParameterSetName = "ComputerName")]
        [string]$ComputerName,
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true, ParameterSetName = "Guid")]
        [Guid]$Guid,
        [parameter(ParameterSetName = "Folder")]
        [parameter(ParameterSetName = "Member")]
        [parameter(ParameterSetName = "ComputerName")]
        [System.Nullable``1[[int]]]$Enabled = $null,
        [switch]$Expires,
        [switch]$IsExpired,
        [parameter(ParameterSetName = "All")]
        [switch]$All,
        [System.Nullable``1[[int]]]$ResultSize
    )

    begin
    {
        if ($ResultSize -eq 0) { $ResultSize = $null }
        $properties = "name, objectGuid, description, msDFSR-ConflictPath, msDFSR-ConflictSizeInMb, msDFSR-ContentSetGuid, whenCreated, whenChanged, distinguishedName, msDFSR-DfsLinkTarget, "
        $properties += "msDFSR-Enabled, msDFSR-Options, msDFSR-ReadOnly, msDFSR-ReplicationGroupGuid, msDFSR-RootPath, msDFSR-RootSizeInMb, msDFSR-StagingPath, "
        $properties += "msDFSR-StagingSizeInMb"
        $resultCounter = 0
    }

    process 
    { 
        if ($ResultSize -ne $null -and $resultCounter -ge $ResultSize) { break }
        $ldapQuery = "(&(objectClass=msDFSR-Subscription)"
        if ($PSCmdlet.ParameterSetName -eq "Folder")
        {
            Write-Debug "Get folder membership for folder $($Folder.Name)."
            $ldapQuery += "(msDFSR-ContentSetGuid=$(Convert-GuidToLdap $Folder.Guid))"
            if ($Member -ne $null)
            {
                $searchBase = $Member.DistinguishedName
            } else {
                if (-not [string]::IsNullOrEmpty($ComputerName))
                {
                    $comp = Get-ADObject -LDAPFilter "(&(objectClass=computer)(name=$ComputerName))"
                    if ($comp -ne $null)
                    {
                        $searchBase = $comp.DistinguishedName
                    }
                } else {
                    $searchBase = Get-DomainDN
                }
            }
        } elseif ($PSCmdlet.ParameterSetName -eq "Member")
        {
            Write-Debug "Get folder membership for member $($Member.ComputerName)."
            $searchBase = $Member.ComputerNameDN
        } elseif ($PSCmdlet.ParameterSetName -eq "ComputerName")
        {
            Write-Debug "Get folder membership for computer $($ComputerName)."
            $comp = Get-ADObject -LDAPFilter "(&(objectClass=computer)(name=$ComputerName))"
            if ($comp -ne $null)
            {
                $searchBase = $comp.DistinguishedName
            } else {
                Write-Error "Computer $ComputerName was not found."
            }
        } elseif ($PSCmdlet.ParameterSetName -eq "Guid")
        {
            Write-Debug "Get folder membership for Guid $($Guid)."
            $ldapQuery += "(objectGuid=$(Convert-GuidToLdap $Guid))"
            $searchBase = Get-DomainDN
        } elseif ($PSCmdlet.ParameterSetName -eq "All")
        {
            Write-Debug "Get all folder memberships."
            $searchBase = Get-DomainDN
        }
        if ($Expires -or $IsExpired)
        {
            $ldapQuery += "(description={MembershipExpires*})"
        }

        if ($Enabled -eq $true)
        {
            $ldapQuery += "(msDFSR-Enabled=TRUE)"
        } elseif ($Enabled -eq $false)
        {
            $ldapQuery += "(msDFSR-Enabled=FALSE)"
        }

        $ldapQuery += ")"

        $obj = Get-ADObject -SearchBase $searchBase -LdapFilter $ldapQuery -Properties $properties.Replace(" ", "").Split(",") -ResultSetSize $ResultSize 
        foreach($o in $obj)
        {
            if ($ResultSize -ne $null -and $resultCounter -ge $ResultSize) { break }
            if ($Folder -ne $null)
            {
                $folderDN = $Folder.DistinguishedName
            } else {
                $guid = [guid]$o."msDFSR-ContentSetGuid"
                $folderDN = (Get-DfsrFolder -Guid $guid).DistinguishedName
            }

            if ($Member -ne $null)
            {
                $computerDN = $Member.ComputerNameDN
                $replicationGroupDN = $Member.ReplicationGroupDN
            } else {
                if ($o.DistinguishedName -imatch "^CN=.*?,CN=.*?,CN=DFSR-LocalSettings,(CN=.*?,.*?)$")
                {
                    $computerDN = $Matches[1]
                    $guid = [guid]$o."msDFSR-ReplicationGroupGuid"
                    $replicationGroupDN = (Get-DfsrReplicationGroup -Guid $guid).DistinguishedName
                } else {
                    Write-Error "Computer name DN could not be found."
                    return
                }
            }

            $fmObj = [Mwcc.Management.Dfs.DfsrFolderMembership]::LoadFromADObject($o, $folderDN, $computerDN, $replicationGroupDN)
            if ($IsExpired)
            {
                if ($fmObj.ExpireTimestamp -lt [DateTime]::Now)
                {
                    $fmObj
                }
            } else {
                $fmObj
            }
            $resultCounter++
        }
    }

    end
    {
        Write-Verbose "Found $($resultCounter) folder memberships."
    }
}

<#
.SYNOPSIS
Modifies a DFS folder membership.

.DESCRIPTION
Modifies a DFS folder membership. When specifying paths (LocalPath, StagingPath, ConflictPath)
the server is contacted and the path is verified to exist. If it does not exist,
then the path is created. -SkipDirectoryCheck overrides this behavior and will set
the paths regardless of connectivity to the server.

.PARAMETER Membership
The folder membership to modify.

.PARAMETER DfsLinkTarget
The path of the DFSN folder target for this membership.

.PARAMETER Enabled
Whether this folder membership is enabled or disabled.

.PARAMETER Expires
Specifies that this folder membership should expire.

.PARAMETER ExpiresTimestamp
Specifies that this folder membership should expire on the timestamp provided. This parameter
requires that the Expires property must be set to True.

.PARAMETER ReadOnly
Whether this folder membership is read only or not.

.PARAMETER PrimaryMember
Whether this folder membership is the primary membership.

.PARAMETER LocalPath
The local path for this replicated folder on this server.

.PARAMETER LocalPathSizeInMB
The size limit for the local path.

.PARAMETER StagingPath
The Staging path for this replicated folder on this server.

.PARAMETER StagingPathSizeInMB
The size limit for Staging items.

.PARAMETER ConflictPath
The Conflict and Deleted path for this replicated folder on this server.

.PARAMETER ConflictPathSizeInMB
The size limit for Conflict and Deleted items.

.PARAMETER SkipDirectoryCheck
If this switch is specified, then paths are not validated to exist. This is typically
used when configuring the LocalPath, StagingPath or ConflictPath when the server
is not accessible.

.PARAMETER PassThru
If this switch is specified, then the modified connection object(s) will be returned.

.INPUTS
DfsrFolderMembership

.OUTPUTS
DfsrFolderMembership (if the PassThru parameter is specified)

.EXAMPLE
$folder = Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrFolder "FolderName"
$folderMembership = Get-DfsrFolderMembership -Folder $folder
$folderMembership.Enabled = $true
$folderMembership | Set-DfsrFolderMembership
#>
function Set-DfsrFolderMembership
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    param(
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [Mwcc.Management.Dfs.DfsrFolderMembership]$Membership,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$DfsnLinkTarget,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [bool]$Enabled,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [bool]$Expires,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [System.Nullable``1[[DateTime]]]$ExpireTimestamp,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [bool]$ReadOnly,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [bool]$PrimaryMember,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$LocalPath,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [int]$LocalPathSizeInMB,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$StagingPath,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [int]$StagingPathSizeInMB,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$ConflictPath,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [int]$ConflictPathSizeInMB,
        [switch]$SkipDirectoryCheck,
        [switch]$PassThru
    )

    process
    {
        Write-Debug "Updating membership for $($Membership.Folder) on $($Membership.ComputerName)."
        [array]$clear = @()
        $replace = @{}

        if ([string]::IsNullOrEmpty($DfsnLinkTarget))
        {
            $clear += "msDFSR-DfsLinkTarget"
        } else {
            $replace.Add("msDFSR-DfsLinkTarget", $DfsnLinkTarget)
        }

        $replace.Add("msDFSR-Enabled", $Enabled)
        $replace.Add("msDFSR-ReadOnly", $ReadOnly)

        if ($Expires -eq $true)
        {
            $replace.Add("description", "{MembershipExpires$($ExpireTimestamp.ToFileTime())}")
        } elseif ($Expires -eq $false)
        {
            $clear += "description"
        }

        if ($PrimaryMember)
        {
            $replace.Add("msDFSR-Options", 1)
        } else {
            $replace.Add("msDFSR-Options", 0)
        }

        if ([string]::IsNullOrEmpty($LocalPath))
        {
            $clear += "msDFSR-RootPath"
        } else {
            if (!$SkipDirectoryCheck)
            {
                if (!(New-FolderPath $LocalPath -ComputerName $Membership.ComputerName)) { return $null }
            } 
            $replace.Add("msDFSR-RootPath", $LocalPath)
        }

        if ([string]::IsNullOrEmpty($LocalPathSizeInMB))
        {
            $clear += "msDFSR-RootSizeInMb"
        } else {
            $replace.Add("msDFSR-RootSizeInMb", $LocalPathSizeInMB)
        }

        if ([string]::IsNullOrEmpty($StagingPath))
        {
            if (![string]::IsNullOrEmpty($LocalPath))
            {
                if ($LocalPath.EndsWith("\"))
                {
                    $p = "$($LocalPath)DfsrPrivate\Staging"
                } else {
                    $p = "$($LocalPath)\DfsrPrivate\Staging"
                }
                if (!$SkipDirectoryCheck)
                {
                    if (!(New-FolderPath $p -ComputerName $Membership.ComputerName)) { return $null }
                } 
                $replace.Add("msDFSR-StagingPath", $p)
            } else {
                $clear += "msDFSR-StagingPath"
            }
        } else {
            if (!$SkipDirectoryCheck)
            {
                if (!(New-FolderPath $StagingPath -ComputerName $Membership.ComputerName)) { return $null }
            } 
            $replace.Add("msDFSR-StagingPath", $StagingPath)
        }

        if ([string]::IsNullOrEmpty($StagingPathSizeInMB))
        {
            $clear += "msDFSR-StagingSizeInMb"
        } else {
            $replace.Add("msDFSR-StagingSizeInMb", $StagingPathSizeInMB)
        }

        if ([string]::IsNullOrEmpty($ConflictPath))
        {
            if (![string]::IsNullOrEmpty($LocalPath))
            {
                if ($LocalPath.EndsWith("\"))
                {
                    $p = "$($LocalPath)DfsrPrivate\ConflictAndDeleted"
                } else {
                    $p = "$($LocalPath)\DfsrPrivate\ConflictAndDeleted"
                }
                if (!$SkipDirectoryCheck)
                {
                    if (!(New-FolderPath $p -ComputerName $Membership.ComputerName -SkipFolderCreation)) { return $null }
                } 
                $replace.Add("msDFSR-ConflictPath", $p)
            } else {
                $clear += "msDFSR-ConflictPath"
            }
        } else {
            if (!$SkipDirectoryCheck)
            {
                if (!(New-FolderPath $ConflictPath -ComputerName $Membership.ComputerName -SkipFolderCreation)) { return $null }
            } 
            $replace.Add("msDFSR-ConflictPath", $ConflictPath)
        }

        if ([string]::IsNullOrEmpty($ConflictPathSizeInMB))
        {
            $clear += "msDFSR-ConflictSizeInMb"
        } else {
            $replace.Add("msDFSR-ConflictSizeInMb", $ConflictPathSizeInMB)
        }

        if ($pscmdlet.ShouldProcess("$($Membership.Folder) on $($Membership.ComputerName)."))
        {
            if ($clear.Count -gt 0) 
            { 
                $resultObject = Set-ADObject $Membership.DistinguishedName -Replace $replace -Clear $clear -PassThru
            } else {
                $resultObject = Set-ADObject $Membership.DistinguishedName -Replace $replace -PassThru
            }
            if ($PassThru)
            {
                Get-DfsrFolderMembership -Guid $resultObject.ObjectGUID
            }
            Write-Verbose "Updated membership for $($Membership.Folder) on $($Membership.ComputerName)."
        }
    }
}

<#
.SYNOPSIS
Creates a new DFS folder membership for a given member and folder.

.DESCRIPTION
Creates a new DFS folder membership. When specifying paths (LocalPath, StagingPath, ConflictPath)
the server is contacted and the path is verified to exist. If it does not exist,
then the path is created. -SkipDirectoryCheck overrides this behavior and will set
the paths regardless of connectivity to the server.

.PARAMETER Member
The member to create the membership for.

.PARAMETER Folder
The folder to create the membership for.

.PARAMETER DfsLinkTarget
The path of the DFSN folder target for this membership.

.PARAMETER Enabled
Whether this folder membership is enabled or disabled.

.PARAMETER Expires
Specifies that this folder membership should expire.

.PARAMETER ExpiresTimestamp
Specifies that this folder membership should expire on the timestamp provided. This parameter
requires that the Expires property must be set to True.

.PARAMETER ReadOnly
Whether this folder membership is read only or not.

.PARAMETER PrimaryMember
Whether this folder membership is the primary membership.

.PARAMETER LocalPath
The local path for this replicated folder on this server.

.PARAMETER LocalPathSizeInMB
The size limit for the local path.

.PARAMETER StagingPath
The Staging path for this replicated folder on this server.

.PARAMETER StagingPathSizeInMB
The size limit for Staging items.

.PARAMETER ConflictPath
The Conflict and Deleted path for this replicated folder on this server.

.PARAMETER ConflictPathSizeInMB
The size limit for Conflict and Deleted items.

.PARAMETER SkipDirectoryCheck
If this switch is specified, then paths are not validated to exist. This is typically
used when configuring the LocalPath, StagingPath or ConflictPath when the server
is not accessible.

.PARAMETER PassThru
If this switch is specified, then the modified connection object(s) will be returned.

.INPUTS
DfsrMember

.OUTPUTS
DfsrFolderMembership (if the PassThru parameter is specified)

.EXAMPLE
$folder = Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrFolder "FolderName"
$member1 = Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrMember -ComputerName "Server1"
$member2 = Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrMember -ComputerName "Server2"
$member1 | New-DfsrFolderMembership -Folder $folder -Enabled $true -PrimaryMember $true -LocalPath C:\Data\FolderName
$member2 | New-DfsrFolderMembership -Folder $folder -Enabled $true -PrimaryMember $true -LocalPath C:\Data\FolderName -StagingPath S:\Data\FolderName\DfsrPrivate\Staging -StagingPathSizeInMB 10240

.EXAMPLE
$folder = Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrFolder "FolderName"
$members = Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrMember
# Add folder memberhsip for each member
$members | New-DfsrFolderMembership -Folder $folder -Enabled $true -LocalPath C:\Data\FolderName
#>
function New-DfsrFolderMembership
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    param(
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [Mwcc.Management.Dfs.DfsrMember]$Member,
        [parameter(Mandatory = $true, Position = 1)]
        [Mwcc.Management.Dfs.DfsrFolder]$Folder,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$DfsnLinkTarget,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [bool]$Enabled = $true,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [bool]$Expires,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [System.Nullable``1[[DateTime]]]$ExpireTimestamp,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [bool]$ReadOnly = $false,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [bool]$PrimaryMember = $false,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$LocalPath,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [int]$LocalPathSizeInMB = 10240,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$StagingPath,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [int]$StagingPathSizeInMB = 4096,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$ConflictPath,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [int]$ConflictPathSizeInMB = 660,
        [switch]$SkipDirectoryCheck,
        [switch]$PassThru
    )

    process
    {
        if ((Get-DfsrFolderMembership -Folder $folder -ComputerName $Member.ComputerName) -ne $null)
        {
            Write-Error "A folder membership for this folder and computer already exists."
            return
        }

        $properties = @{}

        $replicationGroup = Get-DfsrReplicationGroup $Member.ReplicationGroup
        if ($replicationGroup -eq $null)
        {
            Write-Error "The replication group could not be found."
            return $null
        }

        Write-Debug "Creating membership for $($folder.Name) on $($Member.ComputerName)."

        if ($Expires -eq $true)
        {
            $properties.Add("description", "{MembershipExpires$($ExpireTimestamp.ToFileTime())}")
        }

        if ($pscmdlet.ShouldProcess("$($Folder.Name) on $($Member.ComputerName)"))
        {
            $properties.Add("msDFSR-ReplicationGroupGuid", $replicationGroup.Guid.ToByteArray())
            $properties.Add("msDFSR-ContentSetGuid", $folder.Guid.ToByteArray())

            if (![string]::IsNullOrEmpty($DfsnLinkTarget))
            {
                $properties.Add("msDFSR-DfsLinkTarget", $DfsnLinkTarget)
            }

            $properties.Add("msDFSR-Enabled", $Enabled)
            $properties.Add("msDFSR-ReadOnly", $ReadOnly)

            if ($PrimaryMember)
            {
                $properties.Add("msDFSR-Options", 1)
            } else {
                $properties.Add("msDFSR-Options", 0)
            }

            if (![string]::IsNullOrEmpty($LocalPath))
            {
                if (-not $SkipDirectoryCheck)
                {
                    if (-not (New-FolderPath $LocalPath -ComputerName $Member.ComputerName)) { return $null }
                } 
                $properties.Add("msDFSR-RootPath", $LocalPath)
            }

            $properties.Add("msDFSR-RootSizeInMb", $LocalPathSizeInMB)
        
            if (![string]::IsNullOrEmpty($StagingPath))
            {
                if (!$SkipDirectoryCheck)
                {
                    if (!(New-FolderPath $StagingPath -ComputerName $Member.ComputerName)) { return $null }
                } 
                $properties.Add("msDFSR-StagingPath", $StagingPath)
            } else {
                if (![string]::IsNullOrEmpty($LocalPath))
                {
                    if ($LocalPath.EndsWith("\"))
                    {
                        $p = "$($LocalPath)DfsrPrivate\Staging"
                    } else {
                        $p = "$($LocalPath)\DfsrPrivate\Staging"
                    }
                    if (!$SkipDirectoryCheck)
                    {
                        if (!(New-FolderPath $p -ComputerName $Member.ComputerName)) { return $null }
                    } 
                    $properties.Add("msDFSR-StagingPath", $p)
                }
            }

            $properties.Add("msDFSR-StagingSizeInMb", $StagingPathSizeInMB)

            if (![string]::IsNullOrEmpty($ConflictPath))
            {
                if (!$SkipDirectoryCheck)
                {
                    if (!(New-FolderPath $ConflictPath -ComputerName $Member.ComputerName -SkipFolderCreation)) { return $null }
                } 
                $properties.Add("msDFSR-ConflictPath", $ConflictPath)
            } else {
                if (![string]::IsNullOrEmpty($LocalPath))
                {
                    if ($LocalPath.EndsWith("\"))
                    {
                        $p = "$($LocalPath)DfsrPrivate\ConflictAndDeleted"
                    } else {
                        $p = "$($LocalPath)\DfsrPrivate\ConflictAndDeleted"
                    }
                    if (!$SkipDirectoryCheck)
                    {
                        if (!(New-FolderPath $p -ComputerName $Member.ComputerName -SkipFolderCreation)) { return $null }
                    } 
                    $properties.Add("msDFSR-ConflictPath", $p)
                }
            }

            $properties.Add("msDFSR-ConflictSizeInMb", $ConflictPathSizeInMB)

            $guid = [guid]::NewGuid().ToString()

            $resultObject = New-ADObject -Name $guid -Path "CN=$($Member.Name),CN=DFSR-LocalSettings,$($Member.ComputerNameDN)" -Type "msDFSR-Subscription" -OtherAttributes $properties -PassThru
            if ($PassThru)
            {
                Get-DfsrFolderMembership -Guid $resultObject.ObjectGUID
            }
            Write-Verbose "Created membership for $($Folder.Name) on $($Member.ComputerName)."
        }
    }
}

<#
.SYNOPSIS
Removes a DFS folder membership.

.DESCRIPTION
Removes a DFS folder membership. 

.PARAMETER FolderMembership
The folder membership to remove.

.INPUTS
DfsrFolderMembership

.OUTPUTS
None

.EXAMPLE
$folder = Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrFolder "FolderName"
Get-DfsrFolderMembership -Folder $folder | Remove-DfsrFolderMembership

.EXAMPLE
$folder = Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrFolder "FolderName"
Get-DfsrFolderMembership -Folder $folder -ComputerName MyServer | Remove-DfsrFolderMembership
#>
function Remove-DfsrFolderMembership
{
[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='High')]
    param(
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
        [Mwcc.Management.Dfs.DfsrFolderMembership]$Membership
    )

    process
    {
        Write-Debug "Removing folder membership for $($Membership.Folder) on $($Membership.ComputerName)..."

        if ($pscmdlet.ShouldProcess("$($Membership.Folder) on $($Membership.ComputerName)"))
        {
            Remove-ADObject $Membership.DistinguishedName
            Write-Verbose "Removed folder membership for $($Membership.Folder) on $($Membership.ComputerName)."
        }
    }
}
#endregion
#region DfsrBacklog

<#
.SYNOPSIS
Gets the count of backlogged items for each folder in a given set of folders and connections.

.DESCRIPTION
Retrieves count of backlogged items. The results are returned per folder and connection. A given
folder has a backlog result for each connection (and folder membership) that is enabled.

.PARAMETER ReplicationGroup
The replication group object to retrieve the backlog count for.

.PARAMETER Member
The Guid of the member to retrieve.

.PARAMETER Connection
The name of the member to retrieve.

.PARAMETER ComputerName
Specifies that only members that expire should be retrieved.

.PARAMETER Folder
Specifies that only members that are currently expired should be retrieved.

.PARAMETER MaxJobs
Specifies the maximum number of jobs to run concurrently. The default value is 10, this can be lowered if performance is impacted while this cmdlet is running.

.PARAMETER ResultSize
Specifies how many objects to return. If not specified, all results are returned.

.OUTPUTS
Mwcc.Management.Dfs.DfsrBacklogStatistic

.EXAMPLE
# Retrieve backlog information for the entire DFSR environment
Get-DfsrBacklog

.EXAMPLE
# Retrieve backlog information for a single server
Get-DfsrBacklog -ComputerName MyServer

.EXAMPLE
# Retrieve backlog information for a single folder on three servers
$ReplicationGroup = Get-DfsrReplicationGroup "MyReplicationGroup"
$Members = @()
$Members += $ReplicationGroup | Get-DfsrMember "Member1"
$Members += $ReplicationGroup | Get-DfsrMember "Member2"
$Members += $ReplicationGroup | Get-DfsrMember "Member3"
$Folder = Get-DfsrFolder "MyFolder"
$Members | Get-DfsrBacklog -Folder $Folder
#>
function Get-DfsrBacklog
{
    [CmdletBinding()]
    param(
        [parameter(ParameterSetName = "ReplicationGroup", Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [parameter(ParameterSetName = "Member")]
        [parameter(ParameterSetName = "Connection")]
        [parameter(ParameterSetName = "ComputerName")]
        [parameter(ParameterSetName = "Folder")]
        [Mwcc.Management.Dfs.DfsrReplicationGroup]$ReplicationGroup,
        [parameter(ParameterSetName = "Member", Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Mwcc.Management.Dfs.DfsrMember]$Member,
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true, ParameterSetName = "Connection")]
        [Mwcc.Management.Dfs.DfsrConnection]$Connection,
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true, ParameterSetName = "ComputerName")]
        [string]$ComputerName,
        [parameter(ParameterSetName = "Folder", Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [parameter(ParameterSetName = "Member")]
        [parameter(ParameterSetName = "Connection")]
        [parameter(ParameterSetName = "ComputerName")]
        [parameter(ParameterSetName = "ReplicationGroup")]
        [Mwcc.Management.Dfs.DfsrFolder]$Folder,
        [int]$MaxJobs = 10,
        [System.Nullable``1[[int]]]$ResultSize,
        [parameter(ParameterSetName = "All")]
        [switch]$All
    )

    begin 
    {
        $resultCounter = 0
        $totalBacklog = 0
        $availableServerList = New-Object System.Collections.Generic.List[string]
        $failedServerList = New-Object System.Collections.Generic.List[string]
    }

    process
    {
        if ($ResultSize -ne $null -and $resultCounter -ge $ResultSize)
        {
            break
        }

        $recordsToProcess = New-Object System.Collections.Generic.List[PSObject]
        [array]$connectionList = @()

        Write-Progress -Activity "Collecting List of Servers"
        if ($PSCmdlet.ParameterSetName -eq "All")
        {
            $connectionList += Get-DfsrConnection 
        }

        if ($PSCmdlet.ParameterSetName -eq "ReplicationGroup")
        {
            $connectionList += $ReplicationGroup | Get-DfsrConnection
        }

        if ($PSCmdlet.ParameterSetName -eq "Member")
        {
            $connectionList += $Member | Get-DfsrConnection
        }

        if ($PSCmdlet.ParameterSetName -eq "Folder")
        {
            $replicationGroupObj = Get-DfsrReplicationGroup $Folder.ReplicationGroup
            $folderMemberships = $Folder | Get-DfsrFolderMembership -Enabled $true
            foreach($membership in $folderMemberships)
            {
                $connectionList += $replicationGroupObj | Get-DfsrConnection
            }
        }

        if ($PSCmdlet.ParameterSetName -eq "ComputerName")
        {
            $connectionList += Get-DfsrMember -ComputerName $ComputerName | Get-DfsrConnection
        }

        if ($PSCmdlet.ParameterSetName -eq "Connection")
        {
            $connectionList += $Connection
        }
        Write-Progress -Activity "Collecting List of Servers" -Completed

        Write-Progress -Activity "Checking server availability"
        $totalCount = $connectionList.Count * 2
        $pCounter = 0
        foreach($conn in $connectionList)
        {
            Write-Progress -Activity "Checking server availability" -Status "Validating $($conn.SendingMember)" -PercentComplete ($pCounter / $totalCount * 100)
            $senderAvailablity = Test-ServerAvailability -ComputerName $conn.SendingMember `
                -AvailableComputerList $availableServerList -FailedComputerList $failedServerList
            $pCounter++
            Write-Progress -Activity "Checking server availability" -Status "Validating $($conn.ComputerName)" -PercentComplete ($pCounter / $totalCount * 100)
            $receiverAvailability = Test-ServerAvailability -ComputerName $conn.ComputerName `
                -AvailableComputerList $availableServerList -FailedComputerList $failedServerList
            $pCounter++
            if ($senderAvailablity -and $receiverAvailability)
            {
                Add-Record -SendingMember $conn.SendingMember -ReceivingMember $conn.ComputerName -RecordCollection $recordsToProcess -ReplicationGroup $conn.ReplicationGroup
            }
        }

        Write-Progress -Activity "Checking server availability" -Completed
        $serversToProcess = $recordsToProcess.SendingMember | Select-Object -Unique
        
        Write-Progress -Activity "Retrieving Backlog Information" -Status "Submitting Jobs"
        $recordCounter = 0
        $Script:queue = [System.Collections.Queue]::Synchronized( (New-Object System.Collections.Queue) )
        foreach($server in $serversToProcess)
        {
            $Script:queue.Enqueue($server)
        }

        $Script:jobs = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))

        Write-Progress -Activity "Retrieving Backlog Information" -Status "Processing Jobs" -PercentComplete 0
        do
        {
            #Start-Sleep -Seconds 3
            $jCount = ($Script:jobs | Where-Object { $_.State -ne "Completed" }).Count
            if ($jCount -lt $MaxJobs)
            {
                for($i = 0; $i -lt ($MaxJobs - $jCount); $i++)
                {
                    RunJob -RecordsToProcess $recordsToProcess -Folder $Folder
                }
            }
            Write-Progress -Activity "Retrieving Backlog Information" -Status "Processing Jobs" -PercentComplete ($Script:jobs.Count / $serversToProcess.Count * 100)
            #$Script:jobs | Where-Object { $_.State -eq "Completed" } | Receive-Job | ForEach-Object { 
            $Script:jobs | Receive-Job -Wait | ForEach-Object { 
                $_ | ForEach-Object { 
                    $totalBacklog += $_.Backlog
                    $_
                    $resultCounter++
                    if ($ResultSize -ne $null -and $resultCounter -ge $ResultSize)
                    {
                        $jobs | Stop-Job
                        Write-Verbose "Reached the ResultSize limit, stopping jobs and returning results."
                        break
                    }
                }
                #$_ | Remove-Job
            }
        } while($Script:queue.Count -gt 0 -and ($Script:jobs | Where-Object { $_.State -eq "Completed" }).Count -ne $serversToProcess.Count)

        Write-Progress -Activity "Retrieving Backlog Information" -Complete
    }

    end
    {
        Write-Verbose "Finished retrieving backlog information. There are currently $totalBacklog backlogged items across $resultCounter connections."
    }
}


function RunJob
{
    [CmdletBinding()]
    param(
        $RecordsToProcess,
        $Folder
    )
    if ($Script:queue.Count -gt 0)
    {
        $Script:jobs += Start-Job {
            Import-Module Dfsr
            # Re-set variables
            $server = $args[0]
            $recordsToProcess = $args[1]
            $Folder = $args[2]

            #Write-Verbose "Submitting job for $server"
            $recordCollection = $recordsToProcess | Where-Object { $_.SendingMember -eq $server }

            $sender = $server
            $query = "SELECT * FROM DfsrReplicatedFolderInfo"
            [array]$queryConditions = @()
            if ($Folder -ne $null)
            {
                $queryConditions += "ReplicatedFolderName = '$($Folder.Name)'" 
            }

            if ($queryConditions.Count -gt 0)
            {
                $query += " WHERE "
                $query += $queryConditions -join " AND "
            }

            $senderWmi = Get-WmiObject -ComputerName $sender -Namespace "root\MicrosoftDFS" -Query $query

            foreach($record in $recordCollection)
            {
                $receiver = $record.ReceivingMember
                $receiverWmi = Get-WmiObject -ComputerName $receiver -Namespace "root\MicrosoftDFS" -Query $query

                foreach($sWmi in ($senderWmi | Where-Object { $record.ReplicationGroup -eq $_.ReplicationGroupName }))
                {
                    $rWmi = $receiverWmi | Where-Object { $_.ReplicatedFolderName -eq $sWmi.ReplicatedFolderName }
                    if ($rWmi -eq $null)
                    {
                        #Write-Error "The partner folder for folder $($sWmi.ReplicatedFolderName) from server $sender does not exist on $receiver."
                        continue
                    }
                    $versionVector = $rWmi.GetVersionVector().VersionVector
                    $backlogCount = $sWmi.GetOutboundBacklogFileCount($versionVector).BacklogFileCount
                    New-Object Mwcc.Management.Dfs.DfsrBacklogStatistic($sender, $receiver, $sWmi.ReplicationGroupName, $sWmi.ReplicatedFolderName, $backlogCount)
                }
            }
        } -ArgumentList @($Script:queue.Dequeue(), $recordsToProcess, $Folder)
    }
}
<#
.SYNOPSIS
Generate a report for the specified DFS environment backlogged items.

.DESCRIPTION


.PARAMETER Title
The title of the report.

.PARAMETER TemplatePath
The path to the template for the HTML report.

.PARAMETER LargeBacklogThreshold
The threshold for marking a given backlog as 'Large'.

.PARAMETER AsHtml
Specifying this switch will have this cmdlet output HTML, rather than providing no output. This is independent of the Filename or SendEmail parameters and only controls the console output of the script.

.PARAMETER Filename
Providing a Filename will save the HTML report to a file.

.PARAMETER SendEmail
This switch will set the script to send an HTML email report. If this switch is specified, then the To, From and SmtpServers are required.

.PARAMETER To
When SendEmail is used, this sets the recipients of the email report.

.PARAMETER From
When SendEmail is used, this sets the sender of the email report.

.PARAMETER SmtpServer
When SendEmail is used, this is the SMTP Server to send the report through.

.PARAMETER Subject
When SendEmail is used, this sets the subject of the email report.

.PARAMETER NoAttachment
When SendEmail is used, specifying this switch will set the email report to not include the HTML Report as an attachment. It will still be sent in the body of the email.

.INPUTS
DfsrBacklogStatistic if -Backlog is specified

.OUTPUTS
String if -AsHTML is specified

.EXAMPLE
# Save a report for the entire environment to a file
New-DfsrBacklogReport -Filename "C:\Users\Me\Desktop\MyDfsrReport.html"

.EXAMPLE
# Email a report for a single server
Get-DfsrBacklog -ComputerName "MyServer" | New-DfsrBacklogReport -SendEmail -To "Me@domain.local" -From "DfsrReport@domain.local" -SmtpServer "smtp.domain.local"

#>
function New-DfsrBacklogReport
{
    [CmdletBinding()]
    param(
        [string]$Title = "DFS Replication Report",
        [string]$TemplatePath = "$PSScriptRoot\DfsrHealthReportTemplate.html",
        [int]$LargeBacklogThreshold = 100,
        [parameter(ParameterSetName = "Backlog", ValueFromPipeline = $true)]
        $Backlog,
        [switch]$AsHtml,
        [string]$Filename,
        [switch]$SendEmail,
        [string[]]$To,
        [string]$From,
        [string]$SmtpServer,
        [string]$Subject = "DFS Replication Report",
        [switch]$NoAttachment
        )

        begin
        {
            # Validate parameters
            if ($SendEmail)
            {
                [array]$newTo = @()
                foreach($recipient in $To)
                {
                    if ($recipient -imatch "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z0-9.-]+$")
                    {
                        $newTo += $recipient
                    }
                }
                $To = $newTo
                if (-not $To.Count -gt 0)
                {
                    Write-Error "The -To parameter is required when using the -SendEmail switch. If this parameter was used, verify that valid email addresses were specified."
                    return
                }
    
                if ($From -inotmatch "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z0-9.-]+$")
                {
                    Write-Error "The -From parameter is not valid. This parameter is required when using the -SendEmail switch."
                    return
                }

                if ([string]::IsNullOrEmpty($SmtpServer))
                {
                    Write-Error "You must specify a SmtpServer. This parameter is required when using the -SendEmail switch."
                    return
                }
                if ((Test-Connection $SmtpServer -Quiet -Count 2) -ne $true)
                {
                    Write-Error "The SMTP server specified ($SmtpServer) could not be contacted."
                    return
                }
            }
            [array]$backlogStats = @()
        }

        process
        {
            
            if ($PSCmdlet.ParameterSetName -eq "Backlog")
            {
                $backlogStats += $Backlog
            } else {
                $backlogStats = Get-DfsrBacklog
            }
        }

        end
        {
            $templateText = [System.IO.File]::ReadAllText($TemplatePath)
            $reportText = Invoke-Expression $($templateText)

            if ($AsHTML)
            {
                $reportText
            }

            if (-not [string]::IsNullOrEmpty($Filename))
            {
                $reportText | Out-File $Filename
            }

            if ($SendEmail)
            {
                if ($NoAttachment)
                {
                    Send-MailMessage -SmtpServer $SmtpServer -BodyAsHtml -Body $reportText -From $From -To $To -Subject $Subject
                } else {
                    if (-not [string]::IsNullOrEmpty($Filename))
                    {
                        $attachment = $Filename
                    } else {
                        $attachment = "$($Env:TEMP)\DFS Report - $([DateTime]::Now.ToString("MM-dd-yy")).html"
                        $reportText | Out-File $attachment
                    }
                    Send-MailMessage -SmtpServer $SmtpServer -BodyAsHtml -Body $reportText -From $From -To $To -Subject $Subject -Attachments $attachment
                    if ([string]::IsNullOrEmpty($Filename))
                    {
                        Remove-Item $attachment -Confirm:$false -Force
                    }
                }
            }
        }
}


function Test-ServerAvailability
{
    param(
        [parameter(Position = 0, Mandatory = $true)]
        [string]$ComputerName,
        [parameter(Position = 1, Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$AvailableComputerList,
        [parameter(Position = 2, Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[string]]$FailedComputerList
    )

    if ($AvailableComputerList -icontains $ComputerName)
    {
        return $true
    }
    if ($FailedComputerList -icontains $ComputerName)
    {
        return $false
    }

    $serverAvailablity = Test-Connection $ComputerName -Count 3 -ErrorAction SilentlyContinue
    if ($serverAvailablity.Count -ge 2)
    {
        $AvailableComputerList.Add($ComputerName)
        return $true
    } else {
        $FailedComputerList.Add($ComputerName)
        return $false
    }
}

function Add-Record
{
    param(
        [parameter(Position = 0, Mandatory = $true)]
        $SendingMember,
        [parameter(Position = 1, Mandatory = $true)]
        $ReceivingMember,
        [parameter(Position = 2, Mandatory = $true)]
        $ReplicationGroup,
        [parameter(Position = 3, Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[PSObject]]$RecordCollection
    )

    $dupeCheck = $RecordCollection | Where-Object { 
        $_.SendingMember -eq $SendingMember -and $_.ReceivingMember -eq $ReceivingMember -and $_.ReplicationGroup -eq $ReplicationGroup }
    if ($dupeCheck.Count -eq 0)
    {
        $RecordCollection.Add((New-Object PSObject -Property @{
            "SendingMember" = $SendingMember;
            "ReceivingMember" = $ReceivingMember;
            "ReplicationGroup" = $ReplicationGroup;
        }))
        Write-Verbose "Added $SendingMember and $ReceivingMember for replication group $ReplicationGroup to collection ($($RecordCollection.Count) results)."
    }
}

#endregion
#region DfsrMember

<#
.SYNOPSIS
Gets members of a replication group.

.DESCRIPTION
Retrieves members of a replication group. 

.PARAMETER ReplicationGroup
The replication group object to retrieve the members for.

.PARAMETER Guid
The Guid of the member to retrieve.

.PARAMETER ComputerName
The name of the member to retrieve.

.PARAMETER Expires
Specifies that only members that expire should be retrieved.

.PARAMETER IsExpired
Specifies that only members that are currently expired should be retrieved.

.PARAMETER ResultSize
Specifies how many objects to return. If not specified, all results are returned.

.INPUTS
DfsrReplicationGroup

.OUTPUTS
DfsrMember

.EXAMPLE
Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrMember

.EXAMPLE
Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrMember -ComputerName MyMember

.EXAMPLE
# Get all members for all replication groups
Get-DfsrMember
#>
function Get-DfsrMember
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true, ParameterSetName = "ReplicationGroup")]
        [Mwcc.Management.Dfs.DfsrReplicationGroup]$ReplicationGroup,
        [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true, ParameterSetName = "Guid")]
        [Guid]$Guid,
        [string]$ComputerName,
        [switch]$Expires,
        [switch]$IsExpired,
        [System.Nullable``1[[int]]]$ResultSize,
        [parameter(ParameterSetName = "All")]
        [switch]$All
    )
    begin
    {
        if ($ResultSize -eq 0) { $ResultSize = $null }
        $properties = "name, msDFSR-ComputerReference, msDFSR-Keywords, whenCreated, whenChanged, distinguishedName, objectGuid, description"
        $resultCount = 0
    }
   
    process
    {
        if ($ResultSize -ne $null -and $resultCounter -ge $ResultSize) { break }
        $ldapQuery = "(objectClass=msDFSR-Member)"
        if ($PSCmdlet.ParameterSetName -eq "ReplicationGroup")
        {
            Write-Debug "Getting members for $($ReplicationGroup.Name)."
            $searchBase = $ReplicationGroup.DistinguishedName
        } elseif ($PSCmdlet.ParameterSetName -eq "All")
        {
            Write-Debug "Getting all members."
            $searchBase = "CN=DFSR-GlobalSettings,CN=System,$(Get-DomainDN)"
        } elseif ($PSCmdlet.ParameterSetName -eq "Guid")
        {
            Write-Debug "Getting member with Guid of $Guid."
            $searchBase = "CN=DFSR-GlobalSettings,CN=System,$(Get-DomainDN)"
            $ldapQuery = "(&$ldapQuery(objectGuid=$(Convert-GuidToLdap $Guid)))"
        }
        if ($Expires -or $IsExpired)
        {
            $ldapQuery = "(&$ldapQuery(description={MemberExpires*}))"
        }
        
        $obj = Get-ADObject -searchbase $searchBase -ldapfilter $ldapQuery -Properties $properties.Replace(" ", "").Split(",")

        foreach($o in $obj)
        {
            if ($ResultSize -ne $null -and $resultCounter -ge $ResultSize) { break }
            if ($PSCmdlet.ParameterSetName -ne "ReplicationGroup")
            {
                if ($o.DistinguishedName -imatch "^CN=[A-Z0-9-]+,CN=Topology,(CN=.*?,.*?)$")
                {
                    $replDN = $Matches[1]
                }
            } else {
                $replDN = $ReplicationGroup
            }
            $returnObject = [Mwcc.Management.Dfs.DfsrMember]::LoadFromADObject($o, $replDN)
            if ([string]::IsNullOrEmpty($ComputerName))
            {
                if ($IsExpired)
                {
                    if ($cObj.ExpireTimestamp -lt [DateTime]::Now)
                    {
                        $returnObject
                        $resultCounter++
                    }
                } else {
                    $returnObject
                    $resultCounter++
                }
            } else {
                if ($returnObject.ComputerName -ilike "$ComputerName")
                {
                    if ($IsExpired)
                    {
                        if ($cObj.ExpireTimestamp -lt [DateTime]::Now)
                        {
                            $returnObject
                            $resultCounter++
                        }
                    } else {
                        $returnObject
                        $resultCounter++
                    }
                }
            }
        }
    }

    end
    {
        Write-Verbose "Found $($resultCounter) member(s)."
    }
}

<#
.SYNOPSIS
Modifies member(s) of a replication group.

.DESCRIPTION
Modifies member(s) of a replication group. 

.PARAMETER Member
The member object to modify.

.PARAMETER Keywords
Keywords for the member.

.PARAMETER Expires
Specifies that this member should expire.

.PARAMETER ExpiresTimestamp
Specifies that this member should expire on the timestamp provided. This parameter
requires that the Expires property must be set to True.

.PARAMETER PassThru
If this switch is specified, then the modified member object(s) will be returned.

.INPUTS
DfsrMember

.OUTPUTS
DfsrMember (if PassThru has been specified)

.EXAMPLE
$members = Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrMember
# $members has all of the members for the MyReplicationGroup replication group.
foreach($member in $members)
{
    $member.Keywords = "My Description"
    $member | Set-DfsrMember
}

.EXAMPLE
Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrMember -ComputerName MyMember | Set-DfsrMember -Keywords "Hub Server"
#>
function Set-DfsrMember
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Alias("ReplicationGroupMember")]
        [Mwcc.Management.Dfs.DfsrMember]$Member,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        $Keywords,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [bool]$Expires,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [System.Nullable``1[[DateTime]]]$ExpireTimestamp,
        [switch]$PassThru
    )

    process 
    {
        Write-Debug "Updating member: $($Member.ComputerName)"
        
        $clear = @()
        $replace = @{}

        if ([string]::IsNullOrEmpty($Keywords))
        {
            $clear += "msDFSR-Keywords"
        } else {
            $replace.Add("msDFSR-Keywords", $Keywords)
        }

        if ($Expires -eq $true)
        {
            $replace.Add("description", "{MemberExpires$($ExpireTimestamp.ToFileTime())}")
        } elseif ($Expires -eq $false)
        {
            $clear += "description"
        }

        if ($pscmdlet.ShouldProcess("$($Member.Name)"))
        {
            if ($clear.Count -gt 0)
            {
                if ($replace.Count -gt 0)
                {
                    Set-ADObject $($Member.DistinguishedName) -Clear $clear -Replace $replace
                } else {
                    Set-ADObject $($Member.DistinguishedName) -Clear $clear
                }
            } else {
                if ($replace.Count -gt 0)
                {
                    Set-ADObject $($Member.DistinguishedName) -Replace $replace
                }
            }
            if ($PassThru)
            {
                Get-DfsrReplicationGroup $Member.ReplicationGroup | Get-DfsrMember -ComputerName $Member.ComputerName
            }
            Write-Verbose "Updated $($Member.Name)."
        }
    }
}

<#
.SYNOPSIS
Creates a new member(s) of a replication group.

.DESCRIPTION
Creates a new member(s) of a replication group. 

.PARAMETER ReplicationGroup
The replication group to add this member to.

.PARAMETER ComputerName
The name of the computer to add as a member.

.PARAMETER Keywords
Keywords for the member.

.PARAMETER Expires
Specifies that this member should expire.

.PARAMETER ExpiresTimestamp
Specifies that this member should expire on the timestamp provided. This parameter
requires that the Expires property must be set to True.

.PARAMETER PassThru
If this switch is specified, then the modified member object(s) will be returned.

.INPUTS
DfsrReplicationGroup

.OUTPUTS
DfsrMember (if PassThru has been specified)

.EXAMPLE
Get-DfsrReplicationGroup -Name "MyReplicationGroup" | New-DfsrMember -ComputerName MyNewMemberServer

.EXAMPLE
$replicationGroup = Get-DfsrReplicationGroup -Name "MyReplicationGroup"
$newMember = New-DfsrMember -ReplicationGroup $replicationGroup -ComputerName MyNewMemberServer -PassThru
#>
function New-DfsrMember
{
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Mwcc.Management.Dfs.DfsrReplicationGroup]$ReplicationGroup,
        [parameter(Mandatory = $true)]
        $ComputerName,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [bool]$Expires,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [System.Nullable``1[[DateTime]]]$ExpireTimestamp,
        [switch]$PassThru,
        $Keywords
    )

    process
    {
        Write-Debug "Creating new member $ComputerName on $repGroup.Name"

        if ((Get-DfsrMember -ReplicationGroup $ReplicationGroup -ComputerName $ComputerName) -ne $null)
        {
            Write-Error "This server is already a member of this replication group."
            return
        }

        $properties = @{}
        $testServer = Test-DfsrServer $ComputerName
        if ($testServer.Status -ne "Success")
        {
            Write-Error "Cannot add connection:`r`n$($testServer.Message)"
            return $null
        }
        $properties.Add("msDFSR-ComputerReference", $testServer.DistinguishedName)
        if (![string]::IsNullOrEmpty($Keywords))
        {
            $properties.Add("msDFSR-Keywords", $Keywords)
        }

        if ($Expires -eq $true)
        {
            $properties.Add("description", "{MemberExpires$($ExpireTimestamp.ToFileTime())}")
        }

    
        $guid = [guid]::NewGuid().ToString()

	    $computerProps = @{}
	    $computerProps.Add("msDFSR-MemberReference", "CN=$guid,CN=Topology,$($ReplicationGroup.DistinguishedName)")
	    $computerProps.Add("msDFSR-ReplicationGroupGuid", $ReplicationGroup.Guid.ToByteArray())

        if ($pscmdlet.ShouldProcess("$($ComputerName)"))
        {
	
            New-ADObject -Name $guid -Path "CN=Topology,$($ReplicationGroup.DistinguishedName)" -OtherAttributes $properties -Type "msDFSR-Member"
            Write-Verbose "Created member object at: CN=$guid,CN=Topology,$($ReplicationGroup.DistinguishedName)."
            # Check if DFSR-LocalSettings exists, if not, create it
	        try 
            {
                $localSettings = Get-ADObject "CN=DFSR-LocalSettings,$($testServer.DistinguishedName)"
            }
            catch 
            {
                New-ADObject -Name "DFSR-LocalSettings" -Path "$($testServer.DistinguishedName)" -Type "msDFSR-LocalSettings" -OtherAttributes @{"msDFSR-Version" = "1.0.0.0"}
            }

	        New-ADObject -Name $guid -Path "CN=DFSR-LocalSettings,$($testServer.DistinguishedName)" -OtherAttributes $computerProps -Type "msDFSR-Subscriber"
            # Set permissions
            $newMember = $ReplicationGroup | Get-DfsrMember -ComputerName $ComputerName
            $ReplicationGroup.DelegatedAccess.IdentityReference | % { New-DfsrDelegatedAccess -Member $newMember -Username $_ }
            #$ReplicationGroup.DelegatedAccess.IdentityReference | New-DelegatedAccessForMember -DistinguishedName "CN=$guid,CN=DFSR-LocalSettings,$($testServer.DistinguishedName)"
            Write-Verbose "Created member object for for computer object at: CN=$guid,CN=DFSR-LocalSettings,$($testServer.DistinguishedName)."

            if ($PassThru)
            {
                $newMember
            }
        }
    }
}

<#
.SYNOPSIS
Removes member(s) of a replication group.

.DESCRIPTION
Removes member(s) of a replication group. If the member has any connections, then the -Force switch must be specified.

.PARAMETER Member
The member to remove.

.PARAMETER Force
Specifies that the member and any connections for the member should be removed. By default,
this includes connections on other member objects that reference the member to be deleted.

.PARAMETER SkipReverseConnectionRemoval
When used with the Force parameter, this specifies that connections from other members
that point to this member should not be removed.

.INPUTS
DfsrMember

.OUTPUTS
None

.EXAMPLE
Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrMember -ComputerName MyNewMemberServer | Remove-DfsrMember

.EXAMPLE
# Force removal of all members of a given replication group
Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Get-DfsrMember | Remove-DfsrMember -Force
#>
function Remove-DfsrMember
{
[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='High')]
    param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Mwcc.Management.Dfs.DfsrMember]$Member,
        [switch]$Force,
        [switch]$SkipReverseConnectionRemoval
    )

    process
    {
        Write-Debug "Removing $($Member.ComputerName)..."

        [array]$obj = Get-ADObject -LdapFilter "(objectClass=msDFSR-Connection)" -SearchBase "$($Member.DistinguishedName)"
        [array]$reverseObj = Get-ADObject -LdapFilter "(&(objectClass=msDFSR-Connection)(fromServer=$($Member.DistinguishedName)))" -SearchBase "$($Member.ReplicationGroupDN)"
        
        Write-Verbose "$($obj.Count) connections and $($reverseObj.Count) reverse connections found for this object."
        if (!$Force)
        {
            if ($obj.Count -gt 0)
            {
                Write-Error "There are connections present for this member. Please remove the connections first, or use the -Force switch to forcibly remove them."
                return $null
            }
            if ($reverseObj.Count -gt 0)
            {
                Write-Error "There are connections present that point to this member. Please remove the connections first, or use the -Force switch to forcibly remove them."
            }
        }
           
        if ($pscmdlet.ShouldProcess("$($Member.ComputerName)"))
        {
            if (!$SkipReverseConnectionRemoval)
            {
                Write-Debug "Removing reverse connections..."
                Write-Verbose "Removing $(Get-ObjectCount $reverseObj) connections that point to $($Member.ComputerName)."
                if ($reverseObj.Count -gt 0)
                {
                    $reverseObj | Remove-ADObject
                }
            }
	        Remove-ADObject $Member.DistinguishedName -Recursive -Confirm:$false
	        Remove-ADObject "CN=$($Member.Name),CN=DFSR-LocalSettings,$($Member.ComputerNameDN)" -Recursive -Confirm:$false
            Write-Verbose "Removed $($Member.ComputerName)."
        }
    }
}
#endregion
#region DfsrReplicationGroup

<#
.SYNOPSIS
Gets a DFS replication group.

.DESCRIPTION
Retrieves a DFS replication group. This contains information about the
group itself, and can also be passed to other cmdlets in this module.

.PARAMETER Name
The name or names of the replication group(s) to retrieve.

.PARAMETER Guid
The Guid of the replication group to retrieve.

.PARAMETER ComputerName
The name of the computer to look for this replication group on. Only replication
groups that have the specified computer as a member will be returned.

.PARAMETER Version
The version of the replication group to retrieve.

.PARAMETER Type
The type of the replication group to retrieve.

.PARAMETER ResultSize
Specifies how many objects to return. If not specified, all results are returned.

.INPUTS
string

.OUTPUTS
DfsrReplicationGroup

.EXAMPLE
Get-DfsrReplicationGroup -Name "MyReplicationGroup"

.EXAMPLE
$replicationGroups = @("MyReplicationGroup", "MyOtherReplicationGroup")
$replicationGroups | Get-DfsrReplicationGroup

.EXAMPLE
Get-DfsrReplicationGroup -ComputerName MyDFSServer

.EXAMPLE
# Get all replication groups
Get-DfsrReplicationGroup
#>
function Get-DfsrReplicationGroup
{
    [CmdletBinding()]
    param(
    
    [parameter(Position = 0, ValueFromPipeline = $true, ParameterSetName = "Name", Mandatory = $true)]
    [string]$Name,
    [parameter(Position = 0, ParameterSetName = "Guid", Mandatory = $true)]
    [Guid]$Guid,
    [string]$ComputerName,
    [int]$Version,
    [System.Nullable``1[[System.Int32]]]$Type = $null,
    [System.Nullable``1[[int]]]$ResultSize,
    [parameter(ParameterSetName = "All")]
    [switch]$All
    )

    begin 
    {
        if ($ResultSize -eq 0) { $ResultSize = $null }
        $properties = "name, distinguishedName, msDFSR-Version, whenCreated, whenChanged, msDFSR-Options, msDFSR-ReplicationGroupType, msDFSR-Schedule, description, objectGuid"
        $resultCounter = 0
    }

    process
    {
        if ($ResultSize -ne $null -and $resultCounter -ge $ResultSize) { return }
        if (![string]::IsNullOrEmpty($ComputerName))
        {
            # TODO Clean this up
            Write-Debug "Searching for Replication Groups by computer name: $($ComputerName)"
            [array]$computers = Get-ADObject -searchbase $(Get-DomainDN) -ldapfilter "(&(objectClass=computer)(name=$ComputerName))" -Properties @("name", "distinguishedName")
            Write-Verbose "Found $($computers.Count) computer(s) that match the specified computer name."
            $guids = @()
            $subs = $computers | % { Get-ADObject -SearchBase $_.DistinguishedName -LdapFilter "(objectClass=msDFSR-Subscriber)" -Properties @("msDFSR-ReplicationGroupGuid") -ResultSetSize $ResultSize }
            Write-Verbose "Found $($subs.Count) DFSR members on $($computers.count) computer(s)."
            $subs | % { $guids += (Convert-GuidToLdap ([guid]$_."msDFSR-ReplicationGroupGuid")) }
            if ($guids.Count -eq 0)
            {
                Write-Verbose "No replication groups found for computer: $ComputerName."
                return
            }
            $rGroups = @()
            if ([string]::IsNullOrEmpty($Name)) { $nameQuery = "" } else { $nameQuery = "(name=$Name)" }
            if ($Version -gt 0) { $versionQuery = "(msDFSR-Version=$("{0:N1}" -f $Version))" } else { $versionQuery = "" }
            if ($Type -ne $null) { $typeQuery = "(msDFSR-ReplicationGroupType=$($Type))" } else { $typeQuery = "" }
            $guids | % { $rGroups += Get-ADObject -SearchBase "CN=DFSR-GlobalSettings,CN=System,$(Get-DomainDN)" -LdapFilter "(&(objectClass=msDFSR-ReplicationGroup)(objectGuid=$($_))$($nameQuery)$($versionQuery)$($typeQuery))" -Properties $properties.Replace(" ", "").Split(",") }
            $resultCounter += Get-ObjectCount $rGroups
            return $rGroups | % { $aList = $rGroups.distinguishedName | Get-DfsrDelegatedAccess; [Mwcc.Management.Dfs.DfsrReplicationGroup]::LoadFromADObject($_, $aList) }
        }

        $Name = $Name.Replace("\", "\5C")
        $Name = $Name.Replace("(", "\28")
        $Name = $Name.Replace(")", "\29")
        $ldapQuery = "(&(objectClass=msDFSR-ReplicationGroup)"
        if ($PSCmdlet.ParameterSetName -eq "Guid")
        {
            $ldapQuery += "(objectGuid=$(Convert-GuidToLdap $Guid))"
        } else {
            if (-not [string]::IsNullOrEmpty($Name)) { $ldapQuery += "(name=$Name)" }
            if ($Version -gt 0) { $ldapQuery += "(msDFSR-Version=$("{0:N1}" -f $Version))" }
            if ($Type -ne $null) { $ldapQuery += "(msDFSR-ReplicationGroupType=$($Type))" }
        }
        $ldapQuery += ")"
        Write-Debug "Searching for Replication Groups with Ldap Query: $($ldapQuery)"

        $obj = Get-ADObject -searchbase "CN=DFSR-GlobalSettings,CN=System,$(Get-DomainDN)" -ldapfilter $ldapQuery -Properties $properties.Replace(" ", "").Split(",")
        foreach($o in $obj)
        {
            if ($ResultSize -ne $null -and $resultCounter -ge $ResultSize) { return }
            [Mwcc.Management.Dfs.DfsrDelegatedAccess[]]$aList = $o.distinguishedName | Get-DfsrDelegatedAccess
            [Mwcc.Management.Dfs.DfsrReplicationGroup]::LoadFromADObject($o, $aList)
            $resultCounter++
        }
    }

    end
    {
        Write-Verbose "Found $($resultCounter) Replication Groups."
    }
}

<#
.SYNOPSIS
Sets properties on a DFS replication group.

.DESCRIPTION
Sets properties on a DFS replication group.

.PARAMETER ReplicationGroup
The Replication Group object(s) to modify.

.PARAMETER Description
The description of the replication group.

.PARAMETER UseLocalTime
If the replication group schedule should use local time or UTC. True is local time.

.PARAMETER Schedule
The replication group schedule.

.PARAMETER Type
The type of the replication group.

.PARAMETER PassThru
If this switch is specified, then the modified replication group objects will be returned.

.INPUTS
DfsrReplicationGroup

.OUTPUTS
DfsrReplicationGroup (if PassThru is specified)

.EXAMPLE
$replicationGroup = Get-DfsrReplicationGroup -Name "MyReplicationGroup"
$replicationGroup.Description = "My New Description"
$replicationGroup | Set-DfsrReplicationGroup

.EXAMPLE
Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Set-DfsrReplicationGroup -Description "My New Description"

.EXAMPLE
$replicationGroups = @("MyReplicationGroup", "MyOtherReplicationGroup")
$modifiedReplicationGroups = $replicationGroups | Get-DfsrReplicationGroup | Set-DfsrReplicationGroup -UseLocalTime $false -PassThru
#>
function Set-DfsrReplicationGroup
{   
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Mwcc.Management.Dfs.DfsrReplicationGroup]$ReplicationGroup,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [bool]$UseLocalTime = $true,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$Description = "",
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [Mwcc.Management.Dfs.DfsrReplicationSchedule]$Schedule,
        [parameter(ValueFromPipelineByPropertyName = $true)]
        [int]$Type = 0,
        [bool]$PassThru
    )

    process
    {
        Write-Debug "Updating replication group: $($ReplicationGroup.Name)"

        $replace = @{}
        [array]$clear = @()
        if ($UseLocalTime -eq $true)
        {
            $replace.Add("msDFSR-Options", 1)
        } else {
            $replace.Add("msDFSR-Options", 0)
        }

        if ($Schedule -ne $null)
        {
            $replace.Add("msDFSR-Schedule", $Schedule.GetBinaryData())
        } else {
            $clear += "msDFSR-Schedule"
        }

        if ([string]::IsNullOrEmpty($Description))
        {
            $clear += "description"
        } else {
            $replace.Add("description", $Description)
        }

        $replace.Add("msDFSR-ReplicationGroupType", $Type)

        if ($pscmdlet.ShouldProcess("$($ReplicationGroup.Name)"))
        {
            if ($clear.Count -gt 0)
            {
                Set-ADObject $($ReplicationGroup.DistinguishedName) -Replace $replace -Clear $clear
            } else {
                Set-ADObject $($ReplicationGroup.DistinguishedName) -Replace $replace
            }

            if ($PassThru)
            {
                Get-DfsrReplicationGroup $ReplicationGroup.Name
            }
            Write-Verbose "Modified replication group: $($ReplicationGroup.Name)"
        }
    }
}

<#
.SYNOPSIS
Create a new DFS replication group.

.DESCRIPTION
Create a new DFS replication group.

.PARAMETER Name
The name of the replication group to create.

.PARAMETER Description
The description of the replication group.

.PARAMETER UseLocalTime
If the replication group schedule should use local time or UTC. True is local time.

.PARAMETER Schedule
The replication group schedule.

.PARAMETER Type
The type of the replication group.

.PARAMETER PassThru
If this switch is specified, then the modified replication group objects will be returned.

.INPUTS
string

.OUTPUTS
DfsrReplicationGroup (if PassThru is specified)

.EXAMPLE
New-DfsrReplicationGroup -Name "MyReplicationGroup" -Description "My group description"

.EXAMPLE
$replicationGroup = New-DfsrReplicationGroup -Name "MyReplicationGroup" -UseLocalTime $true -PassThru

.EXAMPLE
$replicationGroupNames = @("MyReplicationGroup", "MyOtherReplicationGroup")
$replicationGroupNames | New-DfsrReplicationGroup -UseLocalTime $true
#>
function New-DfsrReplicationGroup
{ 
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        $Name,
        $Description,
        [bool]$UseLocalTime = $true,
        [Mwcc.Management.Dfs.DfsrReplicationSchedule]$Schedule = (New-DfsrReplicationSchedule),
        [int]$Type = 0,
        [switch]$PassThru
    )

    begin 
    {
        $properties = @{}
        if ($UseLocalTime)
        {
            $properties.Add("msDFSR-Options", 1)
        } else {
            $properties.Add("msDFSR-Options", 0)
        }

        $properties.Add("msDFSR-Version", "1.0")
        $properties.Add("msDFSR-ReplicationGroupType", $Type)
        $properties.Add("msDFSR-Schedule", $Schedule.GetBinaryData())

        if (![string]::IsNullOrEmpty($Description))
        {
            $properties.Add("description", $Description)
        }
    }

    process 
    {
        Write-Debug "Beginning creation of $Name..."
        if ((Get-DfsrReplicationGroup $Name) -ne $null)
        {
            Write-Error "A replication group with this name already exists."
            return
        }

        if ($pscmdlet.ShouldProcess("$($Name)"))
        {
            New-ADObject -Name $Name -Type "msDFSR-ReplicationGroup" -Path "CN=DFSR-GlobalSettings,CN=System,$(Get-DomainDN)" -OtherAttributes $properties
            New-ADObject -Name "Content" -Type "msDFSR-Content" -Path "CN=$(Get-LdapEscapedText $Name),CN=DFSR-GlobalSettings,CN=System,$(Get-DomainDN)"
            New-ADObject -Name "Topology" -Type "msDFSR-Topology" -Path "CN=$(Get-LdapEscapedText $Name),CN=DFSR-GlobalSettings,CN=System,$(Get-DomainDN)"
            if ($PassThru)
            {
                Get-DfsrReplicationGroup $Name
            }
            Write-Verbose "Created replication group: $Name"
        }
    }
}

<#
.SYNOPSIS
Delete a DFS replication group.

.DESCRIPTION
Delete a DFS replication group. If the replication group has folders or members present,
then the -Force switch must be used.

.PARAMETER ReplicationGroup
The Replication Group object(s) to delete.

.PARAMETER Force
The replication group(s) should be deleted, even if they still contain folders or members.

.INPUTS
DfsrReplicationGroup

.OUTPUTS
None

.EXAMPLE
Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Remove-DfsrReplicationGroup

.EXAMPLE
$replicationGroups = @("MyReplicationGroup", "MyOtherReplicationGroup") | Get-DfsrReplicationGroup
$replicationGroups | Remove-DfsrReplicationGroup -Force
#>
function Remove-DfsrReplicationGroup
{
[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='High')]
    param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Mwcc.Management.Dfs.DfsrReplicationGroup]$ReplicationGroup,
        [switch]$Force
        )

    process
    {
        $removeTree = $false
        Write-Debug "Removing replication group $($ReplicationGroup.Name)."

        if (!$Force)
        {
            [array]$obj = Get-ADObject -LdapFilter "(objectClass=*)" -SearchBase "CN=Content,$($ReplicationGroup.DistinguishedName)"
            [array]$obj2 = Get-ADObject -LdapFilter "(objectClass=*)" -SearchBase "CN=Topology,$($ReplicationGroup.DistinguishedName)"
            if ($obj.Count -gt 1 -or $obj2.Count -gt 1)
            {
                Write-Error "There are folders or members present for this replication group. Please remove them first, or use the -Force switch to forcibly remove them."
                return $null
            }
        } else {
            $removeTree = $true
        }

        if ($pscmdlet.ShouldProcess("$($ReplicationGroup.Name)"))
        {
            if ($removeTree)
            {
                Write-Verbose "The -Force switch was used, so attempting to remove members and folders."
                Write-Debug "Removing replication group members..."
                $ReplicationGroup | Get-DfsrMember | Remove-DfsrMember -Force
                Write-Debug "Removing replication group folders..."
                $ReplicationGroup | Get-DfsrFolder | Remove-DfsrFolder
            }
	        Remove-ADObject $ReplicationGroup.DistinguishedName -Recursive -Confirm:$false
            Write-Verbose "Removed $($ReplicationGroup.Name) replication group."
        }
    }
}

<#
.SYNOPSIS
Rename a DFS replication group.

.DESCRIPTION
Rename a DFS replication group. All members, folders, connections and folder memberships will not be affected.

.PARAMETER ReplicationGroup
The Replication Group object to rename.

.PARAMETER NewName
The new name for the replication group

.INPUTS
DfsrReplicationGroup

.OUTPUTS
None

.EXAMPLE
Get-DfsrReplicationGroup -Name "MyReplicationGroup" | Rename-DfsrReplicationGroup -NewName "MyNewNamedGroup"
#>
function Rename-DfsrReplicationGroup
{
[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='High')]
    param(
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Mwcc.Management.Dfs.DfsrReplicationGroup]$ReplicationGroup,
        [parameter(Mandatory = $true, Position = 1)]
        [string]$NewName
        )

    process
    {
        Write-Debug "Renaming replication group $($ReplicationGroup.Name)."

        if ($pscmdlet.ShouldProcess("$($ReplicationGroup.Name)"))
        {
	        Rename-ADObject $ReplicationGroup.DistinguishedName -NewName $NewName
            Write-Verbose "Renamed $($ReplicationGroup.Name) replication group to $NewName."
        }
    }
}
#endregion
#region DfsrReplicationSchedule

<#
.SYNOPSIS
Modify a DFS replication schedule.

.DESCRIPTION
Modify a DFS replication schedule. Each day can be specified individually, or by using the
Weekdays, Weekends or AllDays parameters. 

Schedule information is specified by a single hexadecimal digital (reference available 
in Notes section) per 15 minute interval. So, each hour is represented by four digits 
(i.e. FFFF), and 24 hours for each day. This can be specified as an array of hours, with
each hour containing four digits (FFFF), or shortened to a single digit, which will be 
repeated for each 15 minute increment for that hour (F). 

A string can also be specified, in which case hours are separated by a command (,). For 
example, the first two hours of the day can be specified as "F,F", "AAAA,AAAA", "FAFF, F", etc.

Schedule information can also be passed in a single hexadecimal digit for the entire day. In this
case, that speed is set for the entire day.

.PARAMETER Schedule
The replication schedule object to modify.

.PARAMETER Weekdays
A string or array specifying the schedule of all weekdays (Monday-Friday).

.PARAMETER Weekends
A string or array specifying the schedule of all weekends (Saturday and Sunday).

.PARAMETER AllDays
A string or array specifying the schedule of all days.

.PARAMETER Sunday
A string or array specifying the schedule for the given day.

.PARAMETER Monday
A string or array specifying the schedule for the given day.

.PARAMETER Tuesday
A string or array specifying the schedule for the given day.

.PARAMETER Wednesday
A string or array specifying the schedule for the given day.

.PARAMETER Thursday
A string or array specifying the schedule for the given day.

.PARAMETER Friday
A string or array specifying the schedule for the given day.

.PARAMETER Saturday
A string or array specifying the schedule for the given day.

.PARAMETER PassThru
If this switch is specified, then the modified replication schedule(s) will be returned.

.INPUTS
DfsrReplicationSchedule

.OUTPUTS
DfsrReplicationSchedule (if PassThru is passed)

.EXAMPLE
$schedule = (Get-DfsrReplicationGroup -Name "MyReplicationGroup").Schedule
$schedule | Set-DfsrReplicationSchedule -Weekdays "9" -Weekends "F"

.EXAMPLE
$schedule = (Get-DfsrReplicationGroup -Name "MyReplicationGroup").Schedule
$schedule | Set-DfsrReplicationSchedule -Weekdays "9,9,9,9,9,9,f,f,f,f,f,f,f,f,f,f,f,f,f,f,9,9,9,9" -Weekends "F"

.EXAMPLE
$schedule = (Get-DfsrReplicationGroup -Name "MyReplicationGroup").Schedule
$schedule | Set-DfsrReplicationSchedule -AllDays "FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF,FFFF"

.NOTES
When setting scheduling data, each hexadecimal digit corresponds to a speed. The chart below denotes which hex digit is which speed.

0 - No replication
1 - 16Kbps
2 - 64 Kbps
3 - 128 Kbps
4 - 256 Kbps
5 - 512 Kbps
6 - 1Mbps
7 - 2 Mbps
8 - 4 Mbps
9 - 8 Mbps
A - 16 Mbps
B - 32 Mbps
C - 64 Mbps
D - 128 Mbps
E - 256 Mbps
F - Full (unlimited) replication
#>
function Set-DfsrReplicationSchedule
{
    [CmdletBinding()]
    param(
        [parameter(ValueFromPipeline = $true, Position = 0, Mandatory = $true)]
        [Mwcc.Management.Dfs.DfsrReplicationSchedule]$Schedule,
        $Weekdays,
        $Weekends,
        $AllDays,
        $Sunday,
        $Monday,
        $Tuesday,
        $Wednesday,
        $Thursday,
        $Friday,
        $Saturday,
        [switch]$PassThru
    )

    process
    {
        Write-Verbose "Updating new schedule from parameters."

        # AllDays specified, create schedule
        if ($AllDays -ne $null)
        {
            Write-Verbose "Setting all days of schedule object."
            $data = Get-ReplicationGroupScheduleData -ScheduleData $AllDays
            if ($data -eq $null)
            {
                return $null
            }
            $Schedule.Sunday = $data
            $Schedule.Monday = $data
            $Schedule.Tuesday = $data
            $Schedule.Wednesday = $data
            $Schedule.Thursday = $data
            $Schedule.Friday = $data
            $Schedule.Saturday = $data
            return $Schedule
        }

        # Weekdays specified, create schedule
        if ($Weekdays -ne $null)
        {
            Write-Verbose "Setting weekdays of schedule object."
            $data = Get-ReplicationGroupScheduleData -ScheduleData $Weekdays
            if ($data -ne $null)
            {
                $Schedule.Monday = $data
                $Schedule.Tuesday = $data
                $Schedule.Wednesday = $data
                $Schedule.Thursday = $data
                $Schedule.Friday = $data    
            }
        }

        # Weekends specified, create schedule
        if ($Weekends -ne $null)
        {
            Write-Verbose "Setting weekend of schedule object."
            $data = Get-ReplicationGroupScheduleData -ScheduleData $Weekends
            if ($data -ne $null)
            {
                $Schedule.Sunday = $data
                $Schedule.Saturday = $data  
            }
        }

        if ($Sunday -ne $null) { $Schedule.Sunday = Get-ReplicationGroupScheduleData -ScheduleData $Sunday }
        if ($Monday -ne $null) { $Schedule.Monday = Get-ReplicationGroupScheduleData -ScheduleData $Monday }
        if ($Tuesday -ne $null) { $Schedule.Tuesday = Get-ReplicationGroupScheduleData -ScheduleData $Tuesday }
        if ($Wednesday -ne $null) { $Schedule.Wednesday = Get-ReplicationGroupScheduleData -ScheduleData $Wednesday }
        if ($Thursday -ne $null) { $Schedule.Thursday = Get-ReplicationGroupScheduleData -ScheduleData $Thursday }
        if ($Friday -ne $null) { $Schedule.Friday = Get-ReplicationGroupScheduleData -ScheduleData $Friday }
        if ($Saturday -ne $null) { $Schedule.Saturday = Get-ReplicationGroupScheduleData -ScheduleData $Saturday }

        if ($PassThru) 
        {
            return $newSchedule
        }
    }
}

<#
.SYNOPSIS
Create a DFS replication schedule.

.DESCRIPTION
Create a DFS replication schedule. Each day can be specified individually, or by using the
Weekdays, Weekends or AllDays parameters. 

Schedule information is specified by a single hexadecimal digital (reference available 
in Notes section) per 15 minute interval. So, each hour is represented by four digits 
(i.e. FFFF), and 24 hours for each day. This can be specified as an array of hours, with
each hour containing four digits (FFFF), or shortened to a single digit, which will be 
repeated for each 15 minute increment for that hour (F). 

A string can also be specified, in which case hours are separated by a command (,). For 
example, the first two hours of the day can be specified as "F,F", "AAAA,AAAA", "FAFF, F", etc.

Schedule information can also be passed in a single hexadecimal digit for the entire day. In this
case, that speed is set for the entire day.

.PARAMETER Weekdays
A string or array specifying the schedule of all weekdays (Monday-Friday).

.PARAMETER Weekends
A string or array specifying the schedule of all weekends (Saturday and Sunday).

.PARAMETER AllDays
A string or array specifying the schedule of all days.

.PARAMETER Sunday
A string or array specifying the schedule for the given day.

.PARAMETER Monday
A string or array specifying the schedule for the given day.

.PARAMETER Tuesday
A string or array specifying the schedule for the given day.

.PARAMETER Wednesday
A string or array specifying the schedule for the given day.

.PARAMETER Thursday
A string or array specifying the schedule for the given day.

.PARAMETER Friday
A string or array specifying the schedule for the given day.

.PARAMETER Saturday
A string or array specifying the schedule for the given day.

.INPUTS
None

.OUTPUTS
DfsrReplicationSchedule

.EXAMPLE
$schedule = New-DfsrReplicationSchedule -Weekdays "9" -Weekends "F"

.EXAMPLE
$schedule = (Get-DfsrReplicationGroup -Name "MyReplicationGroup").Schedule
$schedule.Schedule = New-DfsrReplicationSchedule -Weekdays "9,9,9,9,9,9,f,f,f,f,f,f,f,f,f,f,f,f,f,f,9,9,9,9" -Weekends "F"

.NOTES
When setting scheduling data, each hexadecimal digit corresponds to a speed. The chart below denotes which hex digit is which speed.

0 - No replication
1 - 16Kbps
2 - 64 Kbps
3 - 128 Kbps
4 - 256 Kbps
5 - 512 Kbps
6 - 1Mbps
7 - 2 Mbps
8 - 4 Mbps
9 - 8 Mbps
A - 16 Mbps
B - 32 Mbps
C - 64 Mbps
D - 128 Mbps
E - 256 Mbps
F - Full (unlimited) replication
#>
function New-DfsrReplicationSchedule
{
    [CmdletBinding()]
    param(
        $Weekdays,
        $Weekends,
        $AllDays,
        $Sunday,
        $Monday,
        $Tuesday,
        $Wednesday,
        $Thursday,
        $Friday,
        $Saturday
    )

    $Schedule = New-Object Mwcc.Management.Dfs.DfsrReplicationSchedule

    Write-Verbose "Creating new schedule from parameters."

    # AllDays specified, create schedule
    if ($AllDays -ne $null)
    {
        Write-Verbose "Setting all days of schedule object."
        $data = Get-ReplicationGroupScheduleData -ScheduleData $AllDays
        if ($data -eq $null)
        {
            return $null
        }
        $Schedule.Sunday = $data
        $Schedule.Monday = $data
        $Schedule.Tuesday = $data
        $Schedule.Wednesday = $data
        $Schedule.Thursday = $data
        $Schedule.Friday = $data
        $Schedule.Saturday = $data
        return $newSchedule
    }

    # Weekdays specified, create schedule
    if ($Weekdays -ne $null)
    {
        Write-Verbose "Setting weekdays of schedule object."
        $data = Get-ReplicationGroupScheduleData -ScheduleData $Weekdays
        if ($data -ne $null)
        {
            $Schedule.Monday = $data
            $Schedule.Tuesday = $data
            $Schedule.Wednesday = $data
            $Schedule.Thursday = $data
            $Schedule.Friday = $data    
        }
    }

    # Weekends specified, create schedule
    if ($Weekends -ne $null)
    {
        Write-Verbose "Setting weekend of schedule object."
        $data = Get-ReplicationGroupScheduleData -ScheduleData $Weekends
        if ($data -ne $null)
        {
            $Schedule.Sunday = $data
            $Schedule.Saturday = $data  
        }
    }

    if ($Sunday -ne $null) { $Schedule.Sunday = Get-ReplicationGroupScheduleData -ScheduleData $Sunday }
    if ($Monday -ne $null) { $Schedule.Monday = Get-ReplicationGroupScheduleData -ScheduleData $Monday }
    if ($Tuesday -ne $null) { $Schedule.Tuesday = Get-ReplicationGroupScheduleData -ScheduleData $Tuesday }
    if ($Wednesday -ne $null) { $Schedule.Wednesday = Get-ReplicationGroupScheduleData -ScheduleData $Wednesday }
    if ($Thursday -ne $null) { $Schedule.Thursday = Get-ReplicationGroupScheduleData -ScheduleData $Thursday }
    if ($Friday -ne $null) { $Schedule.Friday = Get-ReplicationGroupScheduleData -ScheduleData $Friday }
    if ($Saturday -ne $null) { $Schedule.Saturday = Get-ReplicationGroupScheduleData -ScheduleData $Saturday }

    return $Schedule
}

function Get-ReplicationGroupScheduleData
{
    param(
    [parameter(Position = 0, ValueFromPipeline = $true, Mandatory = $true)]
    $ScheduleData
    )

    if ($ScheduleData -is [string])
    {
        if ($ScheduleData -imatch "^(?:[0-9A-F],){23}[0-9A-F]$")
        {
            [array]$sData = @()
            $ScheduleData.Split(",") | % { $sData += "$_$_$_$_" }
            $ScheduleData = $sData
        } elseif ($ScheduleData -imatch "[0-9A-F]")
        {
            [array]$sData = @()
            1..24 | % { $sData += "$($ScheduleData)$($ScheduleData)$($ScheduleData)$($ScheduleData)" }
            $ScheduleData = $sData
        }
        # $ScheduleData = $ScheduleData.Split(",")
    }

    if ($ScheduleData -is [array])
    {
        if ($ScheduleData.Count -ne 24)
        {
            Write-Error "The supplied data was an array, but did not match a known input format. The array should be 24 elements long with each element containing 2 hex pairs (24 elements of 0000-FFFF). Each element represents an hour in the day, and each character represents a 15 minute time block."
            return $null
        }
        foreach($d in $ScheduleData)
        {
            if ($d -inotmatch "[0-9A-F]{4}")
            {
                if ($d -imatch "^[0-9A-F]$")
                {
                    $d = "$d$d$d$d"
                } else {
                Write-Error "The supplied data was an array, but did not match a known input format. The array should be 24 elements long with each element containing 2 hex pairs (24 elements of 0000-FFFF). Each element represents an hour in the day, and each character represents a 15 minute time block."
                return $null
                }
            }
        }
        return $ScheduleData -join ","
    }

    Write-Error "The supplied data was an array, but did not match a known input format. The array should be 24 elements long with each element containing 2 hex pairs (24 elements of 0000-FFFF). Each element represents an hour in the day, and each character represents a 15 minute time block."
    return $null
}
#endregion
#region DfsrServer
<#
.SYNOPSIS
Get all DFS Servers in the domain.

.DESCRIPTION
Searches Active Directory to find all DFS member servers in the domain.

.PARAMETER ComputerName
Specifies the name of the server(s) to search for. Wildcards (*) are permitted.

.PARAMETER ResultSize
Specifies the number of results to return. If this is omitted or 0 is specified, then all results are returned.

.OUTPUTS
Result Object

.EXAMPLE
Get-DfsrServers
#>
function Get-DfsrServers
{
    param(
    [int]$ResultSize = 0,
    $ComputerName
    )

    $ldapQuery = "(objectClass=msDFSR-Member)"
    if ($ResultSize -eq $null) { $ResultSize = 0 }
    $results = Get-ADObject -searchbase "CN=DFSR-GlobalSettings,CN=System,$(Get-DomainDN)" -ldapfilter $ldapQuery -Properties "msDFSR-ComputerReference" | select @{Label="Server";Expression={$_."msDFSR-ComputerReference".Substring(3, $_."msDFSR-ComputerReference".IndexOf(",") - 3) } } -unique
    if (-not [string]::IsNullOrEmpty($ComputerName)) 
    {
        $results = $results | ? { $_.Server -ilike $ComputerName }
    }
	$results | Select -First $ResultSize
}

<#
.SYNOPSIS
Test connectivity to a DFS server.

.DESCRIPTION
Test connectivity and DFS availability on a server. For testing, the server is
contacted to ensure it is available over the network. After contacting the server,
then the DFS Replication Service is validated to be installed and running.

.PARAMETER ComputerName
The name of the server to validate.

.INPUTS
string

.OUTPUTS
Result Object

.EXAMPLE
$result = Test-DfsrServer -ComputerName MyServer
if ($result.Status -eq "Success")
{
    # The server is available
}
else
{
    # The server is not available
    Write-Error $result.Message
}
#>
function Test-DfsrServer
{
    [CmdletBinding()]
    param(
    [parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    $ComputerName
    )

    process
    {
        $server = New-Object PSObject
        if ($_ -eq $null)
        {
            $computer = $ComputerName
        } else {
            $computer = $_
        }
        Write-Debug "Testing $computer for DFSR connectivity..."

        $server | Add-Member -MemberType NoteProperty -Name "Name" -Value $computer
        try 
        {
            $serverObject = Get-ADComputer $computer -ErrorAction SilentlyContinue -ErrorVariable ec
        }
        catch 
        {
            $server | Add-Member -MemberType NoteProperty -Name "DistinguishedName" -Value "N/A"
            $server | Add-Member -MemberType NoteProperty -Name "Address" -Value "N/A"
            $server | Add-Member -MemberType NoteProperty -Name "ResponseTime" -Value "N/A"
            $server | Add-Member -MemberType NoteProperty -Name "DFSRServiceInstalled" -Value "N/A"
            $server | Add-Member -MemberType NoteProperty -Name "DFSRServiceStatus" -Value "N/A"
            $server | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed"
            $server | Add-Member -MemberType NoteProperty -Name "Message" -Value ($ec -join "`r`n")
            Write-Verbose "Cannot find AD Computer account for $computername."
            return $server
        }

        $server | Add-Member -MemberType NoteProperty -Name "DistinguishedName" -Value $serverObject.DistinguishedName

        $pingResult = Test-Connection $computer -Count 4 -ErrorVariable e -ErrorAction SilentlyContinue
        if ($e.Count -ge 3)
        {
            $server | Add-Member -MemberType NoteProperty -Name "Address" -Value "N/A"
            $server | Add-Member -MemberType NoteProperty -Name "ResponseTime" -Value "N/A"
            $server | Add-Member -MemberType NoteProperty -Name "DFSRServiceInstalled" -Value "N/A"
            $server | Add-Member -MemberType NoteProperty -Name "DFSRServiceStatus" -Value "N/A"
            $server | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed"
            $server | Add-Member -MemberType NoteProperty -Name "Message" -Value ($e -join "`r`n")
            Write-Verbose "Cannot connect to $computername."
            return $server
            
        }
        $pingAverage = ($pingResult.ResponseTime | Measure-Object -Average).Average
        $server | Add-Member -MemberType NoteProperty -Name "Address" -Value $pingResult[0].IPV4Address
        $server | Add-Member -MemberType NoteProperty -Name "ResponseTime" -Value $pingAverage
        $dfsrService = Get-Service -ComputerName $computer DFSR -ErrorVariable se -ErrorAction SilentlyContinue
        if ($se -ne $null)
        {
            if ($se -match "Cannot find any service with the service name")
            {
                Write-Verbose "The DFSR service is not installed on $computername."
                $server | Add-Member -MemberType NoteProperty -Name "DFSRServiceInstalled" -Value $false
            } else {
                $server | Add-Member -MemberType NoteProperty -Name "DFSRServiceInstalled" -Value "N/A"
            }
            $server | Add-Member -MemberType NoteProperty -Name "DFSRServiceStatus" -Value "N/A"
            $server | Add-Member -MemberType NoteProperty -Name "Status" -Value "Failed"
            $server | Add-Member -MemberType NoteProperty -Name "Message" -Value ($se -join "`r`n")
            Write-Verbose "There was an error getting the status of the DFSR service on $computername."
            return $server
        }
        $server | Add-Member -MemberType NoteProperty -Name "DFSRServiceInstalled" -Value $true
        $server | Add-Member -MemberType NoteProperty -Name "DFSRServiceStatus" -Value $dfsrService.Status
        $server | Add-Member -MemberType NoteProperty -Name "Status" -Value "Success"
        $server | Add-Member -MemberType NoteProperty -Name "Message" -Value "Verificaton completed successfully."
        $server
        Write-Verbose "Successfully validated that DFSR is running and reachable on $computername."
    }
}
#endregion
