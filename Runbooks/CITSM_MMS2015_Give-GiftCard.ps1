<#
Name:         CITSM_MMS2015_Give-GiftCard.ps1
Description:  Script to chose winner of MMS 2015 gift card
Author:       Christopher Mank
Date:         11/09/2015
#>

<# 
.SYNOPSIS
	Picks a winner for the gift card
 
.DESCRIPTION
    This script will look up all the registered attendes of the given MMS 2015 session and
    pick a winner of the gift card

.PARAMETER
	
.EXAMPLE
 
.NOTES
    AUTHOR:  Christopher Mank
    LASTEDIT: November 9, 2015
#>


Try
{
    # Verbose preference
    # SilentlyContinue (Default) - Do not show messages on the output/test pane
    # Continue - Show messages on the output/test pane
    $VerbosePreference = "Continue"

    # Import some modules
    Import-Module "C:\Program Files\WindowsPowerShell\Modules\Cncy.Common"
    Write-VerboseStream "Module Cncy.Common imported"

	# Function/Try Started
	Write-VerboseStream "*** Try Started ***"

    # Set some variables
    $StrUrl = "http://mms2015.sched.org/event-goers/d4a7170658261d03b11057900d2d8e13#.VkAlj_mrSUk"
    Write-VerboseStream "Variable StrUrl set to: $StrUrl"

    $hshResult = @{}
    Write-VerboseStream "Variable hshResult declared"

    # Invoke the web request to get list of attendees
    Write-VerboseStream "Inovking WebRequest..."
    $StrResult = Invoke-WebRequest $StrUrl

    # Convert the inner HTML to PSCustomObject
    Write-VerboseStream "Converting HTML response to PSCustomObject..."
    $ObjResult = $StrResult.AllElements | Where Class -eq "sched-container-inner sched-container-inner-section" | Select -First 1 -ExpandProperty innerHTML | ConvertFrom-String -Delimiter "<LI>"

    # Convert the PSCustomObject to a hashtable
    Write-VerboseStream "Converting PSCustomObject to hashtable..."
    $ObjResult.PSObject.Properties | Foreach { $hshResult[$_.Name] = $_.Value.Substring(10, ($_.Value.IndexOf("""", 10)-10)) }

    # Pick a random name
    $intRandomNumber = Get-Random -minimum 2 -maximum $hshResult.Count
    Write-VerboseStream "Variable intRandomNumber set to: $intRandomNumber"

    # Build the correct hashtable item
    $strItem = "P" + $intRandomNumber
    Write-VerboseStream "Variable strItem set to: $strItem"

    # Get the winner string
    $strWinnerName = $hshResult.Get_Item($strItem)
    $StrWinnerString = "The winner is:  " + $strWinnerName + "!!!"

    # Manually configured variables
    $StrCredentialName = "CpmAzureO365Cred"
    $StrMessageTo = @("cmank@concurrency.com", "cmank@concurrency.com")
	#$StrMessageTo = @("nlasnoski@concurrency.com", "cmank@concurrency.com")
    $StrSmtpServer = 'smtp.office365.com'
    Write-VerboseStream "Email settings configured"

    # Build email variables
    $StrMessageSubject = 'MMS 2015 Gift Card Giveaway'
    $StrMessageBody = "<font face=`"Calibri`">Hey Nate,<br><br>

	    Um...can you do me a favor? Can you give $StrWinnerName this gift card?<br><br>
		
	    Thanks Dude!</font>"

    Write-VerboseStream "Email Subject and Message configured"
    
    # Retrieve Office365 credentials
    $ObjAzureCred = Get-AutomationPSCredential -Name $StrCredentialName
    Write-VerboseStream "Got the Office365 credential from AA"

	# Send Email
	If ($ObjAzureCred) 
	{
		Send-MailMessage -To $StrMessageTo -Subject $StrMessageSubject -Body $StrMessageBody -UseSsl -Port 587 -SmtpServer $StrSmtpServer -From $ObjAzureCred.UserName -BodyAsHtml -Credential $ObjAzureCred
        Write-VerboseStream "Email sent"
	}
	
	# Write message to Event Log for OMS
	Write-EventLog –LogName Application –Source “AzureAutomationHybridWorker” –EntryType "Information" –EventID 900 -Message $StrWinnerString
}

Catch
{
	# Catch Started
	Write-VerboseStream "*** Catch Started ***"

    # Log error
    $ObjOutput.ExitCode = "1"
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
    Write-VerboseStream "Write-Output set to: $StrWinnerString"

	# Function/Finally Finished
	Write-VerboseStream "*** Finally Finished ***"
	Write-VerboseStream "*** Function Get-NotificationTemplates Finished ***"

    # Write Output
    Write-Output $StrWinnerString
}