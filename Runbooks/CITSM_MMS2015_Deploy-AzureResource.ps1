<#
Name:         CITSM_MMS2015_Deploy-AzureResource.ps1
Description:  Script to deploy resources into Azure
Author:       Christopher Mank
Date:         11/10/2015
#>

<# 
.SYNOPSIS
	Deploys resources to Azure via ARM
 
.DESCRIPTION
    Deploys resources to Azure via ARM

.PARAMETER
	
.EXAMPLE
 
.NOTES
    AUTHOR:  Christopher Mank
    LASTEDIT: November 10, 2015
#>


Try
{
    # Verbose preference
    # SilentlyContinue (Default) - Do not show messages on the output/test pane
    # Continue - Show messages on the output/test pane
    $VerbosePreference = "Continue"

	# Function/Try Started
	Write-VerboseStream "*** Try Started ***"    

    # Connect to Azure Account
    $ObjCredential = Get-AutomationPSCredential -Name 'CpmAzureO365Cred'
    Add-AzureRMAccount -SubscriptionName 'Concurrency, Inc. Development' -Credential $ObjCredential
    Write-VerboseStream "Connected to Azure"

    # Set the Resource Group Name
    $StrResouceGroupName = 'MMS2015_ARM'
    Write-VerboseStream "Variable StrResouceGroupName set to $StrResouceGroupName"

    # Set the template parameters
    $HshParameters = @{
        VMName = 'mms2015server03'
        StorageAccountName = 'mms2015storage'
        adminUsername = 'cmank'
        adminPassword = 'Random123!'
        subnet1Name = 'default'
        virtualNetworkName = 'Vnet_MMS2015a'  
    }
    Write-VerboseStream "Variable HshParameters set to $HshParameters"

    # Set the template file
    $strTemplateUri = 'https://github.com/cmank/MMS2015/blob/master/Templates/WindowsVirtualMachine.json'
    Write-VerboseStream "Variable strTemplateUri set to $strTemplateUri"

    # Deploy the resource
    New-AzureRMResourceGroupDeployment -ResourceGroupName $StrResouceGroupName -templateParameterObject $HshParameters -TemplateUri $strTemplateUri -Verbose
    Write-VerboseStream "Resouce Group deployed"
}

Catch
{
	# Catch Started
	Write-VerboseStream "*** Catch Started ***"

    # Log error
    Write-VerboseStream $Error[0].Exception.ToString()
	Write-ErrorStream $Error[0].Exception.ToString()
        
	# Catch Finished
	Write-VerboseStream "*** Catch Finished ***"
}

Finally
{
	# Finally Started
	Write-VerboseStream "*** Finally Started ***"

	# Write Output	
    Write-VerboseStream "Write-Output set to: "

	# Function/Finally Finished
	Write-VerboseStream "*** Finally Finished ***"

    # Write Output
    Write-Output ''
}