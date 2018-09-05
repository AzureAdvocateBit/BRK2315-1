[CmdletBinding()]
PARAM()

<# CONSTANTS 

$AzureDefaultRuleNames contains the names of the defaule rules in an Azure Network Security Group.
These names can be updated if Microsoft introduce new default rules in to Azure Network Security Groups.

#>
$AzureDefaultRuleNames = @("ALLOW VNET INBOUND","ALLOW AZURE LOAD BALANCER INBOUND","DENY ALL INBOUND","ALLOW VNET OUTBOUND","ALLOW INTERNET OUTBOUND","DENY ALL OUTBOUND")
$AzureDefaultRmRuleNames = @("AllowVnetInBound","AllowAzureLoadBalancerInBound","DenyAllInBound","AllowVnetOutBound","AllowInternetOutBound","DenyAllOutBound")
#region Azure Network Security Group Validation Rules

<#
.Synopsis
   Validates a port range for use with an Azure Network Security Group
.DESCRIPTION
   This ensures that the requested port range is valid for Azure Network Security Groups
.PARAMETER PortRange
   This is the port range to be validated. It could a single integer between 0 and 65000, a range between 0 and 65000 or an * to denote all ports
.EXMAPLE
   Test-AzurePortRange -PortRange 0-1000
.EXAMPLE
   Test-AzurePortRange -PortRange 100
.EXAMPLE
   Test-AzurePortRange -PortRange *
#>
function Test-AzurePortRange(){
[CmdletBinding()]

    param(
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        $PortRange
    )
    
    
    #New Code
    if($PortRange.ToString() -match "\*"){
        return $true
    } elseif($PortRange.ToString() -match "-"){
        $PortRangeNumbers = $PortRange -split "-"
        if(-not($PortRangeNumbers[0] -in 0..65535)){
            return $false
        }

        if(-not($PortRangeNumbers[1] -in 0..65535)){
            return $false
        }

        return $true
    } elseif($PortRange -in 0..65535){
        #number
        return $true
    } else {
        return $false
    }
    
 
}

<#
.Synopsis
    Validates an Azure Network Security Group Rule action
.DESCRIPTION
    Validates that the required action is permitted
.PARAMETER Action
    This is either Allow or Deny
.EXAMPLE
    Test-AzureNetworkSecurityRuleAction -Action Allow
.EXAMPLE
    Test-AzureNetworkSecurityRuleAction -Action Deny
#>
function Test-AzureNetworkSecurityRuleAction(){
[CmdletBinding()]
param(
        [Parameter(Mandatory=$true,
                Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $Action
)
    return ($Action -match "^(Allow|Deny)$")
}

<#
.Synopsis
    Validates an Azure Network Destination Address Prefix will be permitted
.DESCRIPTION
    Validates that the passed value is one of the following:
        1. VIRTUAL_NETWORK
        2. INTERNET
        3. AZURE_LOADBALANCER
        4. IP in CIDR form (examples are 10.0.0.0/24 or 10.0.0.5/32)
        5. * (which denotes any)
.PARAMETER AddressPrefix
    This is the value to validate
.EXAMPLE
    Test-AzureNetworkSecurityAddressPrefix -AddressPrefix 10.0.0.0/25
.EXAMPLE
    Test-AzureNetworkSecurityAddressPrefix -AddressPrefix VIRTUAL_NETWORK
#>
function Test-AzureNetworkSecurityAddressPrefix(){
[CmdletBinding()]
param(
        [Parameter(Mandatory=$true,
                Position=1)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $AddressPrefix,

        [Parameter(Mandatory=$false,
                Position=2)]
        [switch]$IsARM = $false
)
    if(-not($IsARM)){
        return ($AddressPrefix -match "^(VIRTUAL_NETWORK|AZURE_LOADBALANCER|INTERNET|(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]).){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(/([1-9]|1[0-9]|2[0-9]|3[0-2]))|\*)$")
    } else {
        return ($AddressPrefix -match "^(VirtualNetwork|AzureLoadBalancer|INTERNET|(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]).){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(/([1-9]|1[0-9]|2[0-9]|3[0-2]))|\*)$")
    }
    
}

<#
.Synopsis
    Validates an Azure Network Security Group, or Rule, Name
.DESCRIPTION
    Validates that the name doesn't contain a $ or `
.PARAMETER Name
    This is the value to validate
.EXAMPLE
    Test-AzureNetworkSecurityName -Name RDP$
    This test would fail
.EXAMPLE
    Test-AzureNetworkSecurityName -Name RDP
#>
function Test-AzureNetworkSecurityName(){
[CmdletBinding()]
param(
        [Parameter(Mandatory=$true,
                Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $Name,

        [Parameter(Mandatory=$false,
                Position=2)]
        [switch]$IsARM = $false
)
        if(-not($IsArm)){
            if(($Name -match "\`$") -or ($Name -match "``") -or ($AzureDefaultRuleNames -contains $Name) ){
                return $false
            }
        }
        else{
            if($AzureDefaultRmRuleNames -contains $Name){
                return $false
            }

            return $Name -match "^(?=[\S\s]{1,80}$)([a-zA-Z0-9]{1}[a-zA-Z0-9_.-]{1,78}[a-zA-Z0-9_])$"
        }


        return $true
        



        

}

<#
.Synopsis
    Validates an Azure Network Security Rule Priority
.DESCRIPTION
    Validates that the priority is in a valid range
.PARAMETER Priority
    This is the value to validate
.EXAMPLE
    Test-AzureNetworkSecurityRulePriority -Priority 100
.EXAMPLE
    Test-AzureNetworkSecurityRulePriority -Priority 5000
    This test would fail
#>
function Test-AzureNetworkSecurityRulePriority(){
[CmdletBinding()]
param(
        [Parameter(Mandatory=$true,
                Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $Priority
)

        return ($Priority -in 100..4096)
}

<#
.Synopsis
    Validates an Azure Network Security Group Rule Protocol
.DESCRIPTION
    Validates that the required Protocol is permitted by Azure NSG Rules
.PARAMETER Protocol
    This is either TCP, UDP or *
.EXAMPLE
    Test-AzureNetworkSecurityRuleProtocol -Protocol TCP
.EXAMPLE
    Test-AzureNetworkSecurityRuleProtocol -Protocol UDP
#>
function Test-AzureNetworkSecurityRuleProtocol(){
[CmdletBinding()]
param(
        [Parameter(Mandatory=$true,
                Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $Protocol
)

    return ($Protocol -match "^(TCP|UDP|\*)$")

}

<#
.Synopsis
    Validates an Azure Network Security Group Rule Type
.DESCRIPTION
    Validates that the required type is permitted by Azure NSG Rules
.PARAMETER Type
    This is either inbound or outbound
.EXAMPLE
    Test-AzureNetworkSecurityRuleType -Type Inbound
.EXAMPLE
    Test-AzureNetworkSecurityRuleType -Type Outbound
#>
function Test-AzureNetworkSecurityRuleType(){
[CmdletBinding()]
param(
        [Parameter(Mandatory=$true,
                Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $Type
)

    return ($Type -match "^(inbound|outbound)$")

}

<#
.Synopsis
    Validates a list of Azure Network Security Group Rules
.DESCRIPTION
    Validates that the list of rules defined in a CSV. 
.PARAMETER NetworkSecurityRules
    This is usually the content of the CSV file
.EXAMPLE
    Test-AzureNetworkSecurityGroupRules -NetworkSecurityRules (import-csv <path>)
.EXAMPLE
    $NSGRules = import-csv <path>
    Test-AzureNetworkSecurityGroupRules -NetworkSecurityRules $NSG
#>
function Test-AzureNetworkSecurityGroupRules(){
[CmdletBinding()]
    
    Param
    (
        #Rule List
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty()]
        $NetworkSecurityRules,

        [Parameter(Mandatory=$false,
                Position=1)]
        [switch]$IsARM = $false
    )
    #Rule numbers
    $i = 1

    Write-Verbose "Testing in ARM Mode: $IsArm"

    #This contains the failed rules to be thrown at the user
    $FailedRules = @()

    #Validate each rule
    ForEach($NSR in $NetworkSecurityRules){
        
        Write-Verbose "Validating Rule $i"
        
        #Validate Action is Allow or Deny
        Write-Verbose "Validating Action..."
        if(-not($IsARM)){
            if(-not(Test-AzureNetworkSecurityRuleAction -Action $NSR.Action)){
                $FailedRules += New-FailedAzureNetworkGroupRule -RuleNumber $i -Message "$($NSR.Action) is not a valid NSG Action"
            }
        } else {
            if(-not(Test-AzureNetworkSecurityRuleAction -Action $NSR.Access)){
                $FailedRules += New-FailedAzureNetworkGroupRule -RuleNumber $i -Message "$($NSR.Access) is not a valid NSG Access"
            }
        }
        
        #Validate the Source Prefix address is valid and is one of VIRTUAL_NETWORK, INTERNET, AZURE_LOADBALANCER, an IP CIDR or *
        Write-Verbose "Validating Destination Address Prefix..."
        if(-not(Test-AzureNetworkSecurityAddressPrefix -AddressPrefix $NSR.DestinationAddressPrefix -IsARM:$IsARM)){
            $FailedRules += New-FailedAzureNetworkGroupRule -RuleNumber $i -Message "$($NSR.DestinationAddressPrefix) is not a valid Destination Address Prefix in an Azure NSG"
        }
        
        #Validate the it is a number, range or *
        Write-Verbose "Validating Destination Port Range..."
        if(-not(Test-AzurePortRange -PortRange $NSR.DestinationPortRange)){
            $FailedRules += New-FailedAzureNetworkGroupRule -RuleNumber $i -Message "$($NSR.DestinationPortRange) is not a valid Destination Port Range"
        }

        #Validate the name doesn't contain a $ or ` symbol
        Write-Verbose "Validating Name..."
        if(-not(Test-AzureNetworkSecurityName -Name $NSR.Name -IsARM:$IsARM)){
            $FailedRules += New-FailedAzureNetworkGroupRule -RuleNumber $i -Message "$($NSR.Name) is not valid for a NSG rule name"
        }
        else{
            #Check the rule name is unique
            if($RuleNames -contains $NSR.Name){
                $FailedRules += New-FailedAzureNetworkGroupRule -RuleNumber $i -Message "The rule name $($NSR.Name) is not unique within the NSG"
            }
            else{
                $RuleNames += $NSR.Name
            }
        }
        
        #Validate the priority is a number in range
        Write-Verbose "Validating Priority..."
        if(-not(Test-AzureNetworkSecurityRulePriority -Priority $NSR.Priority)){
            $FailedRules += New-FailedAzureNetworkGroupRule -RuleNumber $i -Message "$($NSR.Priority) is not a valid Priority number in an Azure NSG"
        }

        #Validate the protocol is either TCP, UDP or * (for either)
        Write-Verbose "Validating Protocol..."
        if(-not(Test-AzureNetworkSecurityRuleProtocol -Protocol $NSR.Protocol)){
            $FailedRules += New-FailedAzureNetworkGroupRule -RuleNumber $i -Message "$($NSR.Protocol) is not a valid Protocol in an Azure NSG"
        }

        #Validate the Source Prefix address is valid and is one of VIRTUAL_NETWORK, INTERNET, AZURE_LOADBALANCER, an IP CIDR or *
        Write-Verbose "Validating Source Address Prefix..."
        if(-not(Test-AzureNetworkSecurityAddressPrefix -AddressPrefix $NSR.SourceAddressPrefix -IsARM:$IsARM)){
            $FailedRules += New-FailedAzureNetworkGroupRule -RuleNumber $i -Message "$($NSR.SourceAddressPrefix) is not a valid Source Address Prefix in an Azure NSG"
        }
        
        #Validate the it is a number, range or *
        Write-Verbose "Validating Source Port Range..."
        if(-not(Test-AzurePortRange -PortRange $NSR.SourcePortRange)){
            $FailedRules += New-FailedAzureNetworkGroupRule -RuleNumber $i -Message "$($NSR.Source) is not a valid Source Port Range"
        }

        #Validate Type is either Inbound or Outbound
        Write-Verbose "Validating Type..."
        if(-not($IsARM)){
            if(-not(Test-AzureNetworkSecurityRuleType -Type $NSR.Type)){
                $FailedRules += New-FailedAzureNetworkGroupRule -RuleNumber $i -Message "$($NSR.Type) is not a valid Type in an Azure NSG Rule."
            }
        } else {
            if(-not(Test-AzureNetworkSecurityRuleType -Type $NSR.Direction)){
                $FailedRules += New-FailedAzureNetworkGroupRule -RuleNumber $i -Message "$($NSR.Direction) is not a valid Type in an Azure NSG Rule."
            }
        }
 
        #Validate there is no other rule of the same type that has the same priority
        Write-Verbose "Validating the Priority Number"
        if(($NetworkSecurityRules | ?{(($_.Priority -eq $NSR.Priority) -and ($_.Type -eq $NSR.Type) -and ($_.Name -ne $NSR.Name))}).Count -gt 0){
            $FailedRules += New-FailedAzureNetworkGroupRule -RuleNumber $i -Message "The Priority number $($NSR.Priority) is duplicated for the direction $($NSR.Type)"
        }
        
        #Increment Rule Number
        $i++
    }
    #Return the FailedRules (if any)
    $FailedRules
}

<#
.Synopsis
    Creates an object that contains the rule number and reason why it failed
.DESCRIPTION
    Creates an object that contains the rule number and reason why it failed. Custom PowerShell object 
.PARAMETER RuleNumber
    This is the rule number is the CSV file
.PARAMETER Message
    This is the reason why the rule failed validation
.EXAMPLE
    New-FailedAzureNetworkGroupRule -RuleNumber 1 -Message "The type declared in this rule is not permitted"
#>
function New-FailedAzureNetworkGroupRule(){
[CmdletBinding()]
    
    Param(
        [Parameter(Mandatory=$true)]
        [int]$RuleNumber,
        [Parameter(Mandatory=$true)]
        [string]$Message

    )

    #Build and return the object    
    New-Object –TypeName PSObject -Property @{RuleNumber=$RuleNumber; Message=$Message}

}

<#
.Synopsis
    Creates an object that contains the rule number, the reason why it failed and the direction the rule applies in
.DESCRIPTION
    Creates an object that contains the rule number, the reason why it failed and the direction the rule applies in. Custom PowerShell object 
.PARAMETER RuleNumber
    This is the rule number is the CSV file
.PARAMETER Message
    This is the reason why the rule failed validation
.EXAMPLE
    New-FailedUpdateAzureNetworkGroupRule -RuleNumber 1 -Message "The type declared in this rule is not permitted" -Direction
#>
function New-FailedUpdateAzureNetworkGroupRule(){
[CmdletBinding()]
    
    Param(
        [Parameter(Mandatory=$true)]
        [int]$RuleNumber,
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$true)]
        [string]$Direction

    )

    #Build and return the object    
    New-Object –TypeName PSObject -Property @{RuleNumber=$RuleNumber; Message=$Message; Direction=$Direction}

}

#endregion

#region Azure Resource Manager Network Security Group
<#
.Synopsis
   Creates an Azure Network Security Group based on the CSV file that is passed
.DESCRIPTION
  This script accepts a path to a CSV file where the rule definitions are listed.
  It iterates through each rule in the CSV adding to the required Azure NSG.
.PARAMETER CSVPath
  The location of the CSV that contains the rules to apply
.PARAMETER AzureLocation
  A valid Azure Location, for example "North Europe"
.PARAMETER ResourceGroupName
  The name of the Resource Group where the Network Security Group is to be created
.PARAMETER NetworkSecurityGroupName
  The name of the Azure Network Security Group to create
.PARAMETER Tags
  The Azure tags to apply. This can be a hashtable or an array of hastables
.EXAMPLE
   New-AzureRmCustomNetworkSecurityGroup -CSVPath .\Rules.csv -AzureLocation "North Europe" -ResourceGroupName TEST-RG -NetworkSecurityGroupName NSG-DMZ-1 -Tags @{Name="State";Value="Production"}
#>
function New-AzureRmCustomNetworkSecurityGroup(){
[CmdletBinding()]
    
    Param
    (
        # CSVPath is the path to the CSV containin the rules
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateScript({
            
            Test-Path -Path $_ -PathType Leaf
        })]
        [string] $CSVPath,


         # Which Azure Location will this NSG reside in
        [Parameter(Mandatory=$true,
                   Position=1)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            $DesiredLocation = $_
            if(-not(Get-AzureRmLocation | ?{($_.DisplayName -eq $DesiredLocation) -or ($_.Location -eq $DesiredLocation)})){
                Throw "The location you requested ""$DesiredLocation"" is not a valid Azure location"
            }
            $true
        })]
        [string]$AzureLocation,


        # Resource Group Name
        [Parameter(Mandatory=$true,
                   Position=2)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            
            $RequiredResourceGroupName = Get-AzureRmResourceGroup -Name $_ -Location $AzureLocation -ErrorAction SilentlyContinue
            if(-not($RequiredResourceGroupName)){
                Throw "The Resource Group Name ""$_"" cannot be found."
            }
            $true
            
        })]
        [string] $ResourceGroupName,

        # Network Security Group Name
        [Parameter(Mandatory=$true,
                   Position=3)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            
            $RequiredNSGName = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName | Where-Object -Property Name -EQ -Value $_
            if($RequiredNSGName){
                Throw "The Network Security Group Name ""$_"" is already in use. Consider using Update-AzureRmCustomNetworkSecurityGroup"
            }
            $true
            
        })]
        [string] $NetworkSecurityGroupName,

        #Azure Tags
        [Parameter(Mandatory=$false,
                   Position=4)]
        $Tags,

        [Parameter(Mandatory=$false,
                   Position=5)]
        [switch]$PassThru = $false
    )

    #Import the CSV file
    Write-Verbose "Importing CSV from: $CSVPath"
    $NetworkSecurityRules = Import-Csv -Path $CSVPath

    #Confirm there are rules in the CSV
    if(-not($NetworkSecurityRules)){
        Throw "There are no Azure Network Security Rules defined in the CSV ($CSVPath)"
    }

    #Test the rules to see if they'll be accepted by Azure   
    $FailedRules = Test-AzureNetworkSecurityGroupRules -NetworkSecurityRules $NetworkSecurityRules -IsARM

    #If there are failed rules then stop
    if($FailedRules){
        $FailedRules | %{
            Write-Error "Rule: $($_.RuleNumber) FAILED because $($_.Message)"
        }
        Throw ($FailedRules)
    }
      
    #ARM
    #Create rules then create group

    
    $newRule = "New-AzureRmNetworkSecurityRuleConfig -Name '{0}' -Access {1} -Description '{2}' -DestinationAddressPrefix {3} -DestinationPortRange {4} -Direction {5} -Priority {6} -Protocol {7} -SourceAddressPrefix {8} -SourcePortRange {9} -Debug:`$false"

    $newRules = @()

    ForEach($NSR in $NetworkSecurityRules){
        Write-Verbose "Creating rule name $($NSR.Name)"
        #Use PowerShell formating to substitute the parameters in the $SetRule
        $RuleToCreate = $newRule -f $NSR.Name,$NSR.Access,$NSR.Description,$NSR.DestinationAddressPrefix,$NSR.DestinationPortRange,$NSR.Direction,$NSR.Priority,$NSR.Protocol,$NSR.SourceAddressPrefix,$NSR.SourcePortRange
        $newRules += (Invoke-Expression $RuleToCreate)
    }

    if(-not($Tags)){
        $Tags = @{}
    }

    #$newRules
    Write-Verbose "Creating NSG: $NetworkSecurityGroupName"
    $CreatedNSG = New-AzureRmNetworkSecurityGroup -Location $AzureLocation -Name $NetworkSecurityGroupName -ResourceGroupName $ResourceGroupName -SecurityRules $newRules -Tag $Tags
    
    #Does the user want the NSG back?
    if($PassThru){
        $CreatedNSG
    }


}

<#
.Synopsis
   Updates an Azure Network Security Group based on the CSV file that is passed and ensures that the NSG in Azure matches the CSV file
.DESCRIPTION
  This script accepts a path to a CSV file where the rule definitions are listed.
  Removes all the rules from the existing NSG and replaces them with the updated rules. Azure is only updated with the updated rules. This is different from Classic Azure
.PARAMETER CSVPath
  The location of the CSV that contains the rules to apply
  .PARAMETER ResourceGroupName
  The name of the Resource Group where the Network Security Group resides
.PARAMETER NetworkSecurityGroupName
  The name of the Azure Network Security Group to update
.EXAMPLE
   Update-AzureRmCustomNetworkSecurityGroup -CSVPath C:\AzureNetworkSecuriyGroupRules\RulesARM.csv -ResourceGroupName TEST-RG -NetworkSecurityGroupName NSG-DMZ-1
#>
function Update-AzureRmCustomNetworkSecurityGroup{
[CmdletBinding()]
    param(
         # CSVPath is the path to the CSV where the rules are stored
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateScript({
            #Ensure the CSV file exists
            Test-Path -Path $_ -PathType Leaf
        })]
        [string] $CSVPath,

        # Resource Group Name
        [Parameter(Mandatory=$true,
                   Position=1)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            
            $RequiredResourceGroupName = Find-AzureRmResourceGroup | Where-Object -Property Name -EQ -Value $_
            if(-not($RequiredResourceGroupName)){
                Throw "The Resource Group Name ""$_"" cannot be found."
            }
            $true
            
        })]
        [string] $ResourceGroupName,

        # Network Security Group Name
        [Parameter(Mandatory=$true,
                   Position=2)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            $RequiredNSGName = Get-AzureRmNetworkSecurityGroup | Where-Object -Property Name -EQ -Value $_
            if(-not($RequiredNSGName)){
                Throw "The Network Security Group Name ""$_"" does not exist. Consider using New-AzureRmCustomNetworkSecurityGroup"
            }
            $true
        })]
        [string] $NetworkSecurityGroupName,

        #Azure Tags
        [Parameter(Mandatory=$false,
                   Position=3)]
        $Tags,

        [Parameter(Mandatory=$false,
                   Position=4)]
        [switch]$PassThru = $false

    )

    #Import the CSV file
    Write-Verbose "Importing CSV from: $CSVPath"
    $NetworkSecurityRules = Import-Csv -Path $CSVPath

    #Confirm there are rules in the CSV
    if($NetworkSecurityRules.Count -lt 1){
        Throw "There are no Azure Network Security Rules defined in the CSV ($CSVPath). If you want to remove the NSG then use Remove-AzureRmNetworkSecurityGroup -Name ""$NetworkSecurityGroupName"" -ResourceGroupName ""$"""
    }

    Write-Verbose "Validating all rules, inbound and outbound"

    #Test the rules to see if they'll be accepted by Azure   
    $FailedRules = Test-AzureNetworkSecurityGroupRules -NetworkSecurityRules $NetworkSecurityRules -IsARM

    Write-Verbose "Rule Validation Complete"

    #If there are failed rules then stop
    if($FailedRules){
        Write-Warning "Some rules have failed to process:"
        $FailedRules | %{
            Write-Warning "Rule: $($_.RuleNumber) FAILED because $($_.Message)"
        }
        Throw ($FailedRules)
    }

    #Get the Existing NSG from Azure Rm
    $ExistingNSG = Get-AzureRmNetworkSecurityGroup -Name $NetworkSecurityGroupName -ResourceGroupName $ResourceGroupName
    
    #Get the rules from Azure Rm NSG
    $ExistingNSGRules = Get-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $ExistingNSG

    #Remove all existing rules - WILL NOT UPDATE AZURE
    ForEach($ExistingNSGRule in $ExistingNSGRules){
        $ExistingNSG | Remove-AzureRmNetworkSecurityRuleConfig -Name $ExistingNSGRule.Name | Out-Null
    }

    #Create the new rules and add them to the NSG, 
    $newRule = "`$ExistingNSG | Add-AzureRmNetworkSecurityRuleConfig -Name '{0}' -Access {1} -Description '{2}' -DestinationAddressPrefix {3} -DestinationPortRange {4} -Direction {5} -Priority {6} -Protocol {7} -SourceAddressPrefix {8} -SourcePortRange {9} -Debug:`$false"

    $newRules = @()

    ForEach($NSR in $NetworkSecurityRules){
        Write-Verbose "Creating updated rule name $($NSR.Name)"
        #Use PowerShell formating to substitute the parameters in the $SetRule
        $RuleToCreate = $newRule -f $NSR.Name,$NSR.Access,$NSR.Description,$NSR.DestinationAddressPrefix,$NSR.DestinationPortRange,$NSR.Direction,$NSR.Priority,$NSR.Protocol,$NSR.SourceAddressPrefix,$NSR.SourcePortRange
        Invoke-Expression $RuleToCreate | Out-Null
    }

    if($Tags){
        $ExistingNSG.Tag = $Tags
    }

    Write-Verbose "Updating NSG: $($ExistingNSG.Name)"
    $ExistingNSG = $ExistingNSG | Set-AzureRmNetworkSecurityGroup
    if($PassThru){
        $ExistingNSG
    }
    
}

<#
.Synopsis
   Exports an existing Azure Network Security Group to a CSV file.
.DESCRIPTION
  This script will export all the rules from an existing Network Security Group to a CSV file, this CSV can then be used with Update-AzureRmCustomNetworkSecurityGroup or New-AzureRmCustomNetworkSecurityGroup
.PARAMETER CSVPath
  The location of the CSV to export the rules to
.PARAMETER ResourceGroupName
  The name of the Resource Group where the Network Security Group resides
.PARAMETER NetworkSecurityGroupName
  The name of the Azure Network Security Group to export
.EXAMPLE
   Export-AzureRmCustomNetworkSecurityGroup -CSVPath .\Rules.csv -ResourceGroupName TEST-RG -NetworkSecurityGroupName NSG-DMZ-1
#>
function Export-AzureRmNetworkSecurityGroup{
    param(
         # CSVPath is the path to the CSV where the rules are stored
        [Parameter(Mandatory=$true,
                   Position=0)]
        [string] $CSVPath,

        # Resource Group Name
        [Parameter(Mandatory=$true,
                   Position=1)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            
            $RequiredResourceGroupName = Find-AzureRmResourceGroup | Where-Object -Property Name -EQ -Value $_
            if(-not($RequiredResourceGroupName)){
                Throw "The Resource Group Name ""$_"" cannot be found."
            }
            $true
            
        })]
        [string] $ResourceGroupName,

        # Network Security Group Name
        [Parameter(Mandatory=$true,
                   Position=2)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            $RequiredNSGName = Get-AzureRmNetworkSecurityGroup | Where-Object -Property Name -EQ -Value $_
            if(-not($RequiredNSGName)){
                Throw "The Network Security Group Name ""$_"" does not exist. Cannot export and non-existent Network Security Group."
            }
            $true
        })]
        [string] $NetworkSecurityGroupName
    )

    Write-Verbose "Getting the NSG from Azure RM"
    #Get the Existing NSG from Azure Rm
    $ExistingNSG = Get-AzureRmNetworkSecurityGroup -Name $NetworkSecurityGroupName -ResourceGroupName $ResourceGroupName
    
    Write-Verbose "Extracting the Security Rules"
    #Get the rules from Azure Rm NSG
    $ExistingNSGRules = Get-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $ExistingNSG

    
    #If existing rule then export them
    if($ExistingNSGRules){
        Write-Verbose "Exporting rules to $CSVPath"
        $Rules = @()
        $ExistingNSGRules | ForEach-Object {
            $Rules += New-Object -TypeName PSObject -Property @{
                Name = $_.Name
                Priority = $_.Priority
                Access = $_.Access
                SourceAddressPrefix = $_.SourceAddressPrefix
                SourcePortRange = $_.SourcePortRange
                DestinationAddressPrefix =$_.DestinationAddressPrefix
                DestinationPortRange = $_.DestinationPortRange
                Protocol = $_.Protocol
                Direction = $_.Direction
                Description = $_.Description
            }
        }
        
        $Rules | Export-Csv -Path $CSVPath -NoTypeInformation -Force
        
        #Sort-Object Direction,Priority | Select Name,Priority,Access,SourceAddressPrefix,SourcePortRange,DestinationAddressPrefix,DestinationPortRange,Protocol,Direction,Description | Export-CSV -Path $CSVPath -NoTypeInformation -Force
    } else {
        Write-Error "No rules in the NSG to export"   
    }

}

#endregion

#region Azure Classic Network Security Group

<#
.Synopsis
   Creates an Azure Network Security Group based on the CSV file that is passed
.DESCRIPTION
  This script accepts a path to a CSV file where the rule definitions are listed.
  It iterates through each rule in the CSV adding to the required Azure NSG.
.PARAMETER CSVPath
  The location of the CSV that contains the rules to apply
.PARAMETER NetworkSecurityGroupName
  The name of the Azure Network Security Group to create
.PARAMETER AzureLocation
  A valid Azure Location, for example "North Europe"
.PARAMETER NetworkSecurityGroupLabel
  The description to apply to the NSG in Azure
.EXAMPLE
   New-AzureCustomNetworkSecurityGroup -CSVPath .\Rules.csv -NetworkSecurityGroupName NSG-DMZ-1 -AzureLocation "North Europe" -NetworkSecurityGroupLabel "Default NSG for VNet Dub-Prod, VSubnet DMZ"
#>
function New-AzureCustomNetworkSecurityGroup(){
[CmdletBinding()]
    
    Param
    (
        # CSVPath is the path to the CSV containin the rules
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateScript({
            
            Test-Path -Path $_ -PathType Leaf
        })]
        [string] $CSVPath,

        # Network Security Group Name
        [Parameter(Mandatory=$true,
                   Position=1)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            
            $RequiredNSGName = Get-AzureNetworkSecurityGroup -Name $_ -ErrorAction SilentlyContinue
            if($RequiredNSGName){
                Throw "The Network Security Group Name ""$_"" is already in use. Consider using Update-AzureCustomNetworkSecurityGroup"
            }
            $true
            
        })]
        [string] $NetworkSecurityGroupName,

         # Which Azure Location will this NSG reside in
        [Parameter(Mandatory=$true,
                   Position=2)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            $DesiredLocation = $_
            if(-not(Get-AzureLocation | ?{($_.Name -eq $DesiredLocation)})){
                Throw "The location you requested ""$DesiredLocation"" is not a valid Azure location"
            }
            $true
        })]
        [string]$AzureLocation,

         # Network Security Group Label in Azure - i.e. the description for the NSG
        [Parameter(Mandatory=$true,
                   Position=3)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string]$NetworkSecurityGroupLabel

    )

    #Import the CSV file
    Write-Verbose "Importing CSV from: $CSVPath"
    $NetworkSecurityRules = Import-Csv -Path $CSVPath

    #Confirm there are rules in the CSV
    if($NetworkSecurityRules.Count -lt 1){
        Throw "There are no Azure Network Security Rules defined in the CSV ($CSVPath)"
    }

    #Test the rules to see if they'll be accepted by Azure   
    $FailedRules = Test-AzureNetworkSecurityGroupRules -NetworkSecurityRules $NetworkSecurityRules

    #If there are failed rules then stop
    if($FailedRules){
        $FailedRules | %{
            Write-Error "Rule: $($_.RuleNumber) FAILED because $($_.Message)"
        }
        Throw ($FailedRules)
    }
      

    #Creating Azure Network Security Group
    Write-Verbose "Creating Azure Network Security Group $NetworkSecurityGroupName"
    $NSG = New-AzureNetworkSecurityGroup -Name $NetworkSecurityGroupName -Location $AzureLocation -Label $NetworkSecurityGroupLabel

    #Base Rule - used to format the rule and passed to Invoke-Expression
    $SetRule = "Set-AzureNetworkSecurityRule -Action {0} -DestinationAddressPrefix {1} -DestinationPortRange {2} -Name ""{3}"" -NetworkSecurityGroup `$NSG -Priority {4} -Protocol {5} -SourceAddressPrefix {6} -SourcePortRange {7} -Type {8}"

    Write-Verbose "Creating Azure Network Security Group Rules in Azure Network Security Group $NetworkSecurityGroupName"
    #As rules have passed validation create them in the NSG
    ForEach($NSR in $NetworkSecurityRules){
        Write-Verbose "Creating rule name $($NSR.Name)"
        #Use PowerShell formating to substitute the parameters in the $SetRule
        $RuleToCreate = $SetRule -f $NSR.Action,$NSR.DestinationAddressPrefix,$NSR.DestinationPortRange,$NSR.Name,$NSR.Priority,$NSR.Protocol,$NSR.SourceAddressPrefix,$NSR.SourcePortRange,$NSR.Type
        Invoke-Expression $RuleToCreate | Out-Null
    }

    Write-Verbose "Created the Azure Network Security Group $NetworkSecurityGroupName"

    #return the detailed NSG
    Get-AzureNetworkSecurityGroup -Name $NetworkSecurityGroupName -Detailed
}

<#
.Synopsis
   Updates an Azure Network Security Group based on the CSV file that is passed and ensures that the NSG in Azure matches the CSV file
.DESCRIPTION
  This script accepts a path to a CSV file where the rule definitions are listed.
  It iterates through each rule in the CSV adding it to, or updating, the required Azure Network Security Group.
  If the Azure Network Security Group contains rules no longer the CSV it will remove the rule in NSG.

  This does not make any alterations to the default Azure Network Security Group rules as this is not permitted.
.PARAMETER CSVPath
  The location of the CSV that contains the rules to apply
.PARAMETER NetworkSecurityGroupName
  The name of the Azure Network Security Group to update
.EXAMPLE
   Update-AzureCustomNetworkSecurityGroup -CSVPath .\Rules.csv -NetworkSecurityGroupName NSG-DMZ-1
#>
function Update-AzureCustomNetworkSecurityGroup{
[CmdletBinding()]
    param(
         # CSVPath is the path to the CSV where the rules are stored
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateScript({
            #Ensure the CSV file exists
            Test-Path -Path $_ -PathType Leaf
        })]
        [string] $CSVPath,

        # Network Security Group Name
        [Parameter(Mandatory=$true,
                   Position=1)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
            $RequiredNSGName = Get-AzureNetworkSecurityGroup -Name $_ -ErrorAction SilentlyContinue
            if(-not($RequiredNSGName)){
                Throw "The Network Security Group Name ""$_"" does not exist. Consider using New-AzureCustomNetworkSecurityGroup"
            }
            $true
        })]
        [string] $NetworkSecurityGroupName
    )

    #Import the CSV file
    Write-Verbose "Importing CSV from: $CSVPath"
    $NetworkSecurityRules = Import-Csv -Path $CSVPath

    #Confirm there are rules in the CSV
    if($NetworkSecurityRules.Count -lt 1){
        Throw "There are no Azure Network Security Rules defined in the CSV ($CSVPath). If you want to remove the NSG then use Remove-AzureNetworkSecurityGroup -Name ""$NetworkSecurityGroupName"""
    }

    Write-Verbose "Validating all rules, inbound and outbound"

    #Test the rules to see if they'll be accepted by Azure   
    $FailedRules = Test-AzureNetworkSecurityGroupRules -NetworkSecurityRules $NetworkSecurityRules

    Write-Verbose "Rule Validation Complete"

    #If there are failed rules then stop
    if($FailedRules){
        Write-Warning "Some rules have failed to process:"
        $FailedRules | %{
            Write-Warning "Rule: $($_.RuleNumber) FAILED because $($_.Message)"
        }
        Throw ($FailedRules)
    }

    ###################################################################################
    #region Inbound Rules
    ###################################################################################
        Write-Verbose "Updating the inbound rules"

        #Get the current rules in the NSG
        $CurrentRules = (Get-AzureNetworkSecurityGroup -Name $NetworkSecurityGroupName -Detailed).Rules
        $CurrentInboundRules = $CurrentRules | ?{($_.Type -eq "Inbound") -and ($AzureDefaultRuleNames -notcontains $_.Name)}

        #Breakdown the rules defined in the CSV
        $NetworkSecurityRulesInbound = $NetworkSecurityRules | ?{$_.Type -eq "inbound"} | Sort-Object Priority

        $NSG = Get-AzureNetworkSecurityGroup -Name $NetworkSecurityGroupName

        #Base Rule - used to format the rule and passed to Invoke-Expression
        $SetRule = "Set-AzureNetworkSecurityRule -Action {0} -DestinationAddressPrefix {1} -DestinationPortRange {2} -Name ""{3}"" -NetworkSecurityGroup `$NSG -Priority {4} -Protocol {5} -SourceAddressPrefix {6} -SourcePortRange {7} -Type {8}"
    
        #Holds objects to help set the priority numbers correct
        $RequestPriorityNumbers = @()
    
        #This holds rules that have failed for some reason. A failed run will not fail the function at this time
        $FailedRules = @()

        #Process the rules in the CSV file, updating or creating.
        ForEach($NSR in $NetworkSecurityRulesInbound){
            #See if the rule exists in the current set of NSG rules
            $CurrentRule = $CurrentInboundRules | ?{$_.Name -eq $NSR.Name}
        
            #Found?
            if($CurrentRule){
                #Build the currrent rule set statement
                $CurrentSetRule = $SetRule -f $CurrentRule.Action,$CurrentRule.DestinationAddressPrefix,$CurrentRule.DestinationPortRange,$CurrentRule.Name,$CurrentRule.Priority,$CurrentRule.Protocol,$CurrentRule.SourceAddressPrefix,$CurrentRule.SourcePortRange,$CurrentRule.Type

                #Build the new rule set statement
                $NewSetRule = $SetRule -f $NSR.Action,$NSR.DestinationAddressPrefix,$NSR.DestinationPortRange,$NSR.Name,$NSR.Priority,$NSR.Protocol,$NSR.SourceAddressPrefix,$NSR.SourcePortRange,$NSR.Type

                #Are the set statements the same? if so then the rules are the same
                if($CurrentSetRule -ne $NewSetRule){
                    #Rules are different, has the Priority Changed?
                    If($CurrentRule.Priority -ne $NSR.Priority){
                        if($CurrentInboundRules | ?{$_.Priority -eq $NSR.Priority}){
                            #Found a rule with the same priority as the new updated rule
                            #Keep iterating reducing the priority by one each time until we've foun a free number and use that otherwise fail the rule.
                            [int]$i = $NSR.Priority
                            while($i -ge 100){
                                if(-not($CurrentInboundRules | ?{$_.Priority -eq $i})){
                                    #Not rule in the current Active NSG that has the same priority, use that temporarily (will be changed later)
                                    $RequestPriorityNumbers += (New-Object –TypeName PSObject -Property @{Name=$NSR.Name; RequestedPriority=$NSR.Priority; TemporaryPriority = $i})
                                    $NSR.Priority = $i
                                    break
                                }
                                if($i -eq 100){
                                    #can't create the rule
                                    $FailedRules += New-FailedUpdateAzureNetworkGroupRule -RuleNumber $($NetworkSecurityRulesInbound.IndexOf($NSR +1)) -Message "The rule failed as there are no temporary priorty numbers left between the requested number and 100" -Direction "Inbound"
                                }
                                $i--
                            } # End of while loop
                             #Update the set rule with the new temporary priority
                            $NewSetRule = $SetRule -f $NSR.Action,$NSR.DestinationAddressPrefix,$NSR.DestinationPortRange,$NSR.Name,$NSR.Priority,$NSR.Protocol,$NSR.SourceAddressPrefix,$NSR.SourcePortRange,$NSR.Type
                        }
                    }
                    #Update the rule
                    Invoke-Expression $NewSetRule
                }
            }
            else{
                #New rule. Create the rule

                #Check the Priority is available
                if($CurrentInboundRules | ?{$_.Priority -eq $NSR.Priority}){
                    #Found a rule with the same priority as the new updated rule
                    #Keep iterating reducing the priority by one each time
                    [int]$i = $NSR.Priority
                    while($i -ge 100){
                        if(-not($CurrentInboundRules | ?{$_.Priority -eq $i})){
                            #No rule in the current Active NSG has the same priority as $i, use that temporarily (will be changed to what it should be later)
                            $RequestPriorityNumbers += (New-Object –TypeName PSObject -Property @{Name=$NSR.Name; RequestedPriority=$NSR.Priority; TemporaryPriority = $i})
                            $NSR.Priority = $i
                            break
                        }
                        if($i -eq 100){
                            #Reached the bottom number of the permitted priority rules. Fail the rule
                            $FailedRules += New-FailedUpdateAzureNetworkGroupRule -RuleNumber $($NetworkSecurityRulesInbound.IndexOf($NSR +1)) -Message "The rule failed as there are no temporary priorty numbers left between the requested number and 100" -Direction "Inbound"
                        }
                        $i--
                    }
                }
                #Build the new rule set statement
                $SetRule2 = "`$NSG | Set-AzureNetworkSecurityRule -Action {0} -DestinationAddressPrefix {1} -DestinationPortRange {2} -Name ""{3}"" -Priority {4} -Protocol {5} -SourceAddressPrefix {6} -SourcePortRange {7} -Type {8}"
            
                $NewSetRule = $SetRule2 -f $NSR.Action,$NSR.DestinationAddressPrefix,$NSR.DestinationPortRange,$NSR.Name,$NSR.Priority,$NSR.Protocol,$NSR.SourceAddressPrefix,$NSR.SourcePortRange,$NSR.Type
                Write-Verbose "Updating the Rule using this PowerShell: $NewSetRule"
                #Update the rule
                Invoke-Expression $NewSetRule

            }
        }

        #See if any rules have failed
        if($FailedRules){
            Write-Warning "Some rules have failed to process:"
            $FailedRules | %{
                Write-Warning "Rule: $($_.RuleNumber) FAILED because $($_.Message)"
            }
        }

        #Get the updated NSG
        $NSG = Get-AzureNetworkSecurityGroup -Name $NetworkSecurityGroupName -Detailed

        #Get the current rules in the NSG
        $CurrentRules = $NSG.Rules
        $CurrentInboundRules = $CurrentRules | ?{($_.Type -eq "Inbound") -and ($AzureDefaultRuleNames -notcontains $_.Name)}

        #Process the rules in the current NSG that no longer appear in the CSV file
        ForEach($CurrentRule in $CurrentInboundRules){
            #See if the rule exists
            $Found = $NetworkSecurityRulesInbound | ?{($_.Name -eq $CurrentRule.Name)}
            if(-not($Found)){
                #The rule doesn't exist in the CSV remove from the NSG
                Write-Verbose "Removing the NSG rule name $($CurrentRule.Name)"
                Remove-AzureNetworkSecurityRule -Name $CurrentRule.Name -NetworkSecurityGroup $NSG -Force
            }
        }
    
        #Update the rules so they have the correct priorities now that the NSG should match the CSV
        ForEach($RequestPriorityNumber in $RequestPriorityNumbers){
            #Get the rule from the NSG
            #Create a new set rule for the rule
            $RuleToUpdate = $CurrentInboundRules | ?{$_.Name -eq $RequestPriorityNumber.Name}
            #Found a rule to update
            if($RuleToUpdate){
                #rule found
                $NewRule = $SetRule -f $RuleToUpdate.Action,$RuleToUpdate.DestinationAddressPrefix,$RuleToUpdate.DestinationPortRange,$RuleToUpdate.Name,$RequestPriorityNumber.RequestedPriority,$RuleToUpdate.Protocol,$RuleToUpdate.SourceAddressPrefix,$ruletoupdate.SourcePortRange,$RuleToUpdate.Type
                Invoke-expression $NewRule
            }
        }

        Write-Verbose "Completed inbound rules"

    ###################################################################################
    #endregion #Inbound Rules
    ###################################################################################

    ###################################################################################
    #region Outbound Rules
    ###################################################################################

        Write-Verbose "Updating the outbound rules"

        #Get the current rules in the NSG
        $CurrentRules = (Get-AzureNetworkSecurityGroup -Name $NetworkSecurityGroupName -Detailed).Rules
        $CurrentOutboundRules = $CurrentRules | ?{($_.Type -eq "Outbound") -and ($AzureDefaultRuleNames -notcontains $_.Name)}

        #Breakdown the rules defined in the CSV
        $NetworkSecurityRulesOutbound = $NetworkSecurityRules | ?{$_.Type -eq "Outbound"} | Sort-Object Priority

        $NSG = Get-AzureNetworkSecurityGroup -Name $NetworkSecurityGroupName

        #Base Rule - used to format the rule and passed to Invoke-Expression
        $SetRule = "Set-AzureNetworkSecurityRule -Action {0} -DestinationAddressPrefix {1} -DestinationPortRange {2} -Name ""{3}"" -NetworkSecurityGroup `$NSG -Priority {4} -Protocol {5} -SourceAddressPrefix {6} -SourcePortRange {7} -Type {8}"
    
        #Holds objects to help set the priority numbers correct
        $RequestPriorityNumbers = @()
    
        #This holds rules that have failed for some reason. A failed run will not fail the function at this time
        $FailedRules = @()

        #Process the rules in the CSV file, updating or creating.
        ForEach($NSR in $NetworkSecurityRulesOutbound){
            #See if the rule exists in the current set of NSG rules
            $CurrentRule = $CurrentOutboundRules | ?{$_.Name -eq $NSR.Name}
        
            #Found?
            if($CurrentRule){
                #Build the currrent rule set statement
                $CurrentSetRule = $SetRule -f $CurrentRule.Action,$CurrentRule.DestinationAddressPrefix,$CurrentRule.DestinationPortRange,$CurrentRule.Name,$CurrentRule.Priority,$CurrentRule.Protocol,$CurrentRule.SourceAddressPrefix,$CurrentRule.SourcePortRange,$CurrentRule.Type

                #Build the new rule set statement
                $NewSetRule = $SetRule -f $NSR.Action,$NSR.DestinationAddressPrefix,$NSR.DestinationPortRange,$NSR.Name,$NSR.Priority,$NSR.Protocol,$NSR.SourceAddressPrefix,$NSR.SourcePortRange,$NSR.Type

                #Are the set statements the same? if so then the rules are the same
                if($CurrentSetRule -ne $NewSetRule){
                    #Rules are different, has the Priority Changed?
                    If($CurrentRule.Priority -ne $NSR.Priority){
                        if($CurrentOutboundRules | ?{$_.Priority -eq $NSR.Priority}){
                            #Found a rule with the same priority as the new updated rule
                            #Keep iterating reducing the priority by one each time until we've foun a free number and use that otherwise fail the rule.
                            [int]$i = $NSR.Priority
                            while($i -ge 100){
                                if(-not($CurrentOutboundRules | ?{$_.Priority -eq $i})){
                                    #Not rule in the current Active NSG that has the same priority, use that temporarily (will be changed later)
                                    $RequestPriorityNumbers += (New-Object –TypeName PSObject -Property @{Name=$NSR.Name; RequestedPriority=$NSR.Priority; TemporaryPriority = $i})
                                    $NSR.Priority = $i
                                    break
                                }
                                if($i -eq 100){
                                    #can't create the rule
                                    $FailedRules += New-FailedUpdateAzureNetworkGroupRule -RuleNumber $($NetworkSecurityRulesOutbound.IndexOf($NSR +1)) -Message "The rule failed as there are no temporary priorty numbers left between the requested number and 100" -Direction "Outbound"
                                }
                                $i--
                            } # End of while loop
                             #Update the set rule with the new temporary priority
                            $NewSetRule = $SetRule -f $NSR.Action,$NSR.DestinationAddressPrefix,$NSR.DestinationPortRange,$NSR.Name,$NSR.Priority,$NSR.Protocol,$NSR.SourceAddressPrefix,$NSR.SourcePortRange,$NSR.Type
                        }
                    }
                    #Update the rule
                    Invoke-Expression $NewSetRule
                }
            }
            else{
                #New rule. Create the rule

                #Check the Priority is available
                if($CurrentOutboundRules | ?{$_.Priority -eq $NSR.Priority}){
                    #Found a rule with the same priority as the new updated rule
                    #Keep iterating reducing the priority by one each time
                    [int]$i = $NSR.Priority
                    while($i -ge 100){
                        if(-not($CurrentOutboundRules | ?{$_.Priority -eq $i})){
                            #No rule in the current Active NSG has the same priority as $i, use that temporarily (will be changed to what it should be later)
                            $RequestPriorityNumbers += (New-Object –TypeName PSObject -Property @{Name=$NSR.Name; RequestedPriority=$NSR.Priority; TemporaryPriority = $i})
                            $NSR.Priority = $i
                            break
                        }
                        if($i -eq 100){
                            #Reached the bottom number of the permitted priority rules. Fail the rule
                            $FailedRules += New-FailedUpdateAzureNetworkGroupRule -RuleNumber $($NetworkSecurityRulesOutbound.IndexOf($NSR +1)) -Message "The rule failed as there are no temporary priorty numbers left between the requested number and 100" -Direction "Outbound"
                        }
                        $i--
                    }
                }
                #Build the new rule set statement
                $SetRule2 = "`$NSG | Set-AzureNetworkSecurityRule -Action {0} -DestinationAddressPrefix {1} -DestinationPortRange {2} -Name ""{3}"" -Priority {4} -Protocol {5} -SourceAddressPrefix {6} -SourcePortRange {7} -Type {8}"
            
                $NewSetRule = $SetRule2 -f $NSR.Action,$NSR.DestinationAddressPrefix,$NSR.DestinationPortRange,$NSR.Name,$NSR.Priority,$NSR.Protocol,$NSR.SourceAddressPrefix,$NSR.SourcePortRange,$NSR.Type
                Write-Verbose "Updating the Rule using this PowerShell: $NewSetRule"
                #Update the rule
                Invoke-Expression $NewSetRule

            }
        }

        #See if any rules have failed
        if($FailedRules){
            Write-Warning "Some rules have failed to process:"
            $FailedRules | %{
                Write-Warning "Rule: $($_.RuleNumber) FAILED because $($_.Message)"
            }
        }

        #Get the updated NSG
        $NSG = Get-AzureNetworkSecurityGroup -Name $NetworkSecurityGroupName -Detailed

        #Get the current rules in the NSG
        $CurrentRules = $NSG.Rules
        $CurrentOutboundRules = $CurrentRules | ?{($_.Type -eq "Outbound") -and ($AzureDefaultRuleNames -notcontains $_.Name)}

        #Process the rules in the current NSG that no longer appear in the CSV file
        ForEach($CurrentRule in $CurrentOutboundRules){
            #See if the rule exists
            $Found = $NetworkSecurityRulesOutbound | ?{($_.Name -eq $CurrentRule.Name)}
            if(-not($Found)){
                #The rule doesn't exist in the CSV remove from the NSG
                Write-Verbose "Removing the NSG rule name $($CurrentRule.Name)"
                Remove-AzureNetworkSecurityRule -Name $CurrentRule.Name -NetworkSecurityGroup $NSG -Force
            }
        }
    
        #Update the rules so they have the correct priorities now that the NSG should match the CSV
        ForEach($RequestPriorityNumber in $RequestPriorityNumbers){
            #Get the rule from the NSG
            #Create a new set rule for the rule
            $RuleToUpdate = $CurrentOutboundRules | ?{$_.Name -eq $RequestPriorityNumber.Name}
            #Found a rule to update
            if($RuleToUpdate){
                #rule found
                $NewRule = $SetRule -f $RuleToUpdate.Action,$RuleToUpdate.DestinationAddressPrefix,$RuleToUpdate.DestinationPortRange,$RuleToUpdate.Name,$RequestPriorityNumber.RequestedPriority,$RuleToUpdate.Protocol,$RuleToUpdate.SourceAddressPrefix,$ruletoupdate.SourcePortRange,$RuleToUpdate.Type
                Invoke-expression $NewRule
            }
        }

        Write-Verbose "Completed inbound rules"

    ###################################################################################
    #endregion
    ###################################################################################

    #return the detailed NSG
    Get-AzureNetworkSecurityGroup -Name $NetworkSecurityGroupName -Detailed
}

#endregion


