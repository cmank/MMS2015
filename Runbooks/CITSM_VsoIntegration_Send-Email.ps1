<# 
.SYNOPSIS  
	Sends email containing data from Visual Studio Online
 
.DESCRIPTION 
    This runbook receives webhook data from Visual Studio Online (VSO).  This data is sent to the runbook
	via a Service Hook setup in VSO.  The runbook will parse the data sent and send an email out to the 
	addresses specified.  The runbook uses an Automation Credential to authenticate the user sending the email.
 
.PARAMETER WebhookData 
    Object containing the data from VSO in JSON
	
.EXAMPLE 
    CITSM_VsoIntegration_Send-Email -WebhookData {}
 
.NOTES 
    AUTHOR:  Christopher Mank
    LASTEDIT: November 8, 2015
#>

Workflow CITSM_VsoIntegration_Send-Email
{	
	# Inputs
    param (
        [Object] $WebhookData
    )
	
	# Manually configured variables
	$StrCredentialName = "CpmAzureO365Cred"
	$StrMessageTo = @("cmank@concurrency.com", "cmank@concurrency.com")
	$StrSmtpServer = 'smtp.office365.com'
	
    # Convert request JSON to PS object
	$StrRequestBody = $WebhookData.RequestBody
	$ObjRequestBody = $StrRequestBody | ConvertFrom-Json
	
	# Build Work Item variables
	$StrTitle = $ObjRequestBody.resource.fields.'System.Title'
	$StrCreatedBy = $ObjRequestBody.resource.fields.'System.CreatedBy'
	$StrAreaPath = $ObjRequestBody.resource.fields.'System.AreaPath'
	$StrTeamProject = $ObjRequestBody.resource.fields.'System.TeamProject'
	$StrWorkItemType = $ObjRequestBody.resource.fields.'System.WorkItemType'
	$StrSeverity = $ObjRequestBody.resource.fields.'Microsoft.VSTS.Common.Severity'
	$StrWorkItemId = $ObjRequestBody.resource.'id'
	$StrUrl = $ObjRequestBody.resource.'url'
	
	# Build email variables
	$StrMessageSubject = 'New ' + $StrWorkItemType + ' created in the ' + $StrTeamProject + ' project'
	$StrMessageBody = "<font face=`"Calibri`">Hey Folks!<br><br>
    
        There was a new $StrWorkItemType created in the $StrTeamProject project.<br><br>
        	
		<b>Work Item Details</b><br>
		Id:  $StrWorkItemId<br>
		Title:  $StrTitle<br>
		Area Path:  $StrAreaPath<br>
		Type:  $StrWorkItemType<br>
		Severity:  $StrSeverity<br>
		Created By:  $StrCreatedBy<br>
		URL:  $StrUrl<br><br>
		
		This item will be reviewed and prioritized appropriately.<br><br>
		
		Thank you!<br><br>
		
		The $StrTeamProject Project Team</font>"
 
    # Retrieve Office365 credentials
    $ObjAzureCred = Get-AutomationPSCredential -Name $StrCredentialName
	
 	# Send Email
    if ($ObjAzureCred) 
    {
        Send-MailMessage -To $StrMessageTo -Subject $StrMessageSubject -Body $StrMessageBody -UseSsl -Port 587 -SmtpServer $StrSmtpServer -From $ObjAzureCred.UserName -BodyAsHtml -Credential $ObjAzureCred
	}
}