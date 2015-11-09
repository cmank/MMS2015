<#
	Name:         AdvancedNotifications
	Description:  Sends notifications to users via Everbridge
	Author:       Christopher Mank
	Date:         10/12/2015
	Trace:        $script:strtracemessage -replace "~~", "`n"
#>

Try
{
    Function Main
    {
		# Function Started
		LogTraceMessage "*** Function Main Started ***"
		
        # Set Global Environment Variables (Inputs)
        SetGlobalEnvVariables

        # Import PS Modules
        ImportPsModules
        
        # QueryForNotifications
        QueryForNotifications
		
		# Function Finished
		LogTraceMessage "*** Function Main Finished ***"
    }

    Function SetGlobalEnvVariables
    {
        # Function Started
		LogTraceMessage "*** Function SetGlobalEnvVariables Started ***"
		
		# Set variables with global scope
        $script:intTraceState = ''
        LogTraceMessage "Variable intTraceState set to $script:intTraceState"
        
        $script:strErrorMessage = ''
        LogTraceMessage "Variable strErrorMessage set to $script:strErrorMessage"
        
        $script:intErrorState = 0
        LogTraceMessage "Variable intErrorState set to $script:intErrorState"

        $script:strSmServer = 'j201mc05.jcidev.com'
        LogTraceMessage "Variable strSmServer set to $script:strSmServer"
		
		$script:strInvokeQueryModule = 'D:\Runbooks\InvokeQueryDatabase.psm1'
        LogTraceMessage "Variable strInvokeQueryModule set to $script:strInvokeQueryModule"

        $script:strSmletsModule = 'C:\Program Files\Common Files\SMLets\SMLets.psd1'
        LogTraceMessage "Variable strSmletsModule set to $script:strSmletsModule"
		
		$script:strCncyCommonModule = 'D:\Runbooks\AdvancedNotifications\Cncy.Common.psm1'
        LogTraceMessage "Variable strCncyCommonModule set to $script:strCncyCommonModule"
		
		$script:strCncyEverbridgeModule = 'D:\Runbooks\AdvancedNotifications\Cncy.Everbridge.psm1'
        LogTraceMessage "Variable strCncyEverbridgeModule set to $script:strCncyEverbridgeModule"

        $script:strValidationClass = 'Microsoft.AD.User'
        LogTraceMessage "Variable strValidationClass set to $script:strValidationClass"

        $script:strValidationDomain = 'JCIDEV'
        LogTraceMessage "Variable strValidationDomain set to $script:strValidationDomain"

        $script:strValidationUserName = 'a320162'
        LogTraceMessage "Variable strValidationUserName set to $script:strValidationUserName"

        $script:strDataSource = 'j201ma84.jcidev.com'
        LogTraceMessage "Variable strDataSource set to $script:strDataSource"

        $script:strDataSourceDb = 'ServiceManager'
        LogTraceMessage "Variable strDataSourceDb set to $script:strDataSourceDb"

        $script:strQuery = 'EXEC dbo.p_CITSM_AdvNotifications_GenerateNotifications'
        LogTraceMessage "Variable strQuery set to $script:strQuery"

		# Function Finished
		LogTraceMessage "*** Function SetGlobalEnvVariables Finished ***"
    }

    Function ImportPsModules
    {
		# Function Started
		LogTraceMessage "*** Function ImportPsModules Started ***"

        # Import modules
        Import-Module $script:strSmletsModule -Force
        LogTraceMessage "Module Smlets imported"
		
		Import-Module $script:strCncyCommonModule -Force
        LogTraceMessage "Module Cncy.Common imported"
		
		Import-Module $script:strCncyEverbridgeModule -Force
        LogTraceMessage "Module Cncy.Everbridge imported"
                
        # Create EMG connection
        $mpcAdUser = Get-SCSMClass -ComputerName $script:strSmServer -Name $script:strValidationClass$
        $emoUser = Get-SCSMObject -ComputerName $script:strSmServer -Class $mpcAdUser -Filter "UserName -eq '$script:strValidationUserName' -and Domain -eq '$script:strValidationDomain'"
        LogTraceMessage "EMG created and connected"
		
		# Function Finished
		LogTraceMessage "*** Function ImportPsModules Finished ***"
    }

    Function QueryForNotifications
    {
        # Function Started
		LogTraceMessage "*** Function QueryForNotifications Started ***"

        # Query the data source
		LogTraceMessage "Running the following in SQL:  $script:strQuery"
        Invoke-QueryDatabase -DataSource $script:strDataSource -InitialCatalog $script:strDataSourceDb -CommandText $script:strQuery -CommandType "Text" |
        # Skip 1 is used since the 1st element from Invoke-QueryDatabase is total rows returned (int)
        Select-Object -Skip 1 |
        ConvertTo-CSV -NoTypeInformation -Delimiter "," -OutVariable objOutput
        $strTotalRows = ($objOutput.Count - 1).ToString()
        LogTraceMessage "Invoke query returned $strTotalRows rows"

        # ProcessNotifications
        ProcessNotifications ($objOutput)

        # Function Finished
		LogTraceMessage "*** Function QueryForNotifications Finished ***"
    }

    Function ProcessNotifications ($objOutput)
    {
        # Function Started
		LogTraceMessage "*** Function ProcessNotifications Started ***"

        # Generate process time and input object
        $dteNowUtc = (Get-Date).ToUniversalTime()
		LogTraceMessage "Variable dteNowUtc set to $dteNowUtc"
		
        $objNotificationsToSend = @()
		$objNotificationsToUpdate = @()
		
        # Loop through rows and notifiy if needed
		LogTraceMessage "Looping through each row returned from SQL..."
        ForEach ($strRow In $objOutput)
        {
            # Split array and assign variables
			LogTraceMessage "Variable strRow set to $strRow"
            $arrRow = $strRow.Split(",")
			
			$strCalendarId = $arrRow[0].Replace('"', '')
			LogTraceMessage "Variable strCalendarId set to $strCalendarId"
			
            $strTemplateHours = $arrRow[28].Replace('"', '')
			LogTraceMessage "Variable strTemplateHours set to $strTemplateHours"
			
			$strTemplateType = $arrRow[23].Replace('"', '') # Initial Assignment or Escalation
			LogTraceMessage "Variable strTemplateType set to $strTemplateType"
			
			$strEntityChangeLogId = $arrRow[1].Replace('"', '')
			LogTraceMessage "Variable strEntityChangeLogId set to $strEntityChangeLogId"
			
			$strNotificationId = $arrRow[21].Replace('"', '')
			LogTraceMessage "Variable strNotificationId set to $strNotificationId"
			
            $strActualHours = ""
			LogTraceMessage "Variable strActualHours set to $strActualHours"			
			
            If ($strTemplateHours -eq "Both" -Or $strCalendarId -eq "CalendarId")
            {
                # The calendar hours do not matter, no need to check that logic
                $strActualHours = "Both"
				$strTemplateHours = "Both"
				LogTraceMessage "Variable strActualHours set to $strActualHours"
				LogTraceMessage "Template Hours = Both. The calendar hours do not matter, no need to check that logic"
            }
            Else
            {
                # Get the calendar
				LogTraceMessage "Need to figure out if it's currently Business Hours or After Hours"
                $mpcCalendar = Get-SCSMClass -ComputerName $script:strSmServer -Name System.Calendar$
                $emoCalendar = Get-SCSMObject -ComputerName $script:strSmServer -Class $mpcCalendar -Filter "Id -eq '$strCalendarId'"
				LogTraceMessage "Variable emoCalendar set to $emoCalendar"

                # Get the calendar time zone
                $strCalendarTimeZone = $emoCalendar.Timezone.Split(";")[0]
                $tziCalendarTimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById($strCalendarTimeZone)
				LogTraceMessage "Variable strCalendarTimeZone set to $strCalendarTimeZone"

                # Determine local day and date
                $dteCurrentLocalTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($dteNowUtc, $tziCalendarTimeZone)
				LogTraceMessage "Variable dteCurrentLocalTime set to $dteCurrentLocalTime"
				
                $dteCurrentLocalDayOfWeek = $dteCurrentLocalTime.DayOfWeek
				LogTraceMessage "Variable dteCurrentLocalDayOfWeek set to $dteCurrentLocalDayOfWeek"
				
                $dteCurrentDateLocal = Get-Date -Date $dteCurrentLocalTime -Format d
				LogTraceMessage "Variable dteCurrentDateLocal set to $dteCurrentDateLocal"

                # Get the calendar day and determine local start and end times
                $mprCalendarHasWorkDays = Get-SCSMRelationshipClass -ComputerName $script:strSmServer -Name System.CalendarHasWorkDay$
                $emoDays = Get-SCSMRelatedObject -ComputerName $script:strSmServer -SMObject $emoCalendar -Relationship $mprCalendarHasWorkDays

				LogTraceMessage "Loop through the work days to find the right one"
                ForEach ($objDay In $emoDays)
                {
                    If ($objDay.DayOfWeek.DisplayName -eq $dteCurrentLocalDayOfWeek -and $objDay.IsEnabled -eq $true)
                    {
                        # This is the calendar day for the current day and it's enabled, find local times
						LogTraceMessage "Found the correct day and it's enabled, find local times"
						
                        $dteCalendarStartTimeLocal = [System.TimeZoneInfo]::ConvertTimeFromUtc($objDay.StartTime, $tziCalendarTimeZone)	
                        $dteCalendarEndTimeLocal = [System.TimeZoneInfo]::ConvertTimeFromUtc($objDay.EndTime, $tziCalendarTimeZone)
						
                        $dteCalendarStartTimeLocal = Get-Date -Date $dteCalendarStartTimeLocal -Format T
						LogTraceMessage "Variable dteCalendarStartTimeLocal set to $dteCalendarStartTimeLocal"
						
                        $dteCalendarEndTimeLocal = Get-Date -Date $dteCalendarEndTimeLocal -Format T
						LogTraceMessage "Variable dteCalendarEndTimeLocal set to $dteCalendarEndTimeLocal"

                        $strActualHours = ""
                        Break
                    }
                    Else
                    {
                        # This is not the calendar day or it is the calendar day, but the day is not enabled
                        $strActualHours = "After Hours"
                    }
                }
                
                # Determine if notification falls into On hours
                If ($strActualHours -eq "After Hours")
                {
                    # We know the notification is after hours, no need to check time range
					LogTraceMessage "We know the notification is after hours, no need to check time range"
                }
                Else
                {
                    # We still don't know if the actual hours are On or Off hours, let's check
                    # Build the start and end dates based on local date and calendar time
					LogTraceMessage "We still don't know if the actual hours are On or Off hours, let's check"
                    $dteStartTime = Get-Date -Date "$dteCurrentDateLocal $dteCalendarStartTimeLocal"
                    $dteEndTime = Get-Date -Date "$dteCurrentDateLocal $dteCalendarEndTimeLocal"
                    
                    # Convert the calendar times to UTC
                    $dteCalendarStartTimeUtc = [System.TimeZoneInfo]::ConvertTimeToUtc($dteStartTime, $tziCalendarTimeZone)
					LogTraceMessage "Variable dteCalendarStartTimeUtc set to $dteCalendarStartTimeUtc"
					
                    $dteCalendarEndTimeUtc = [System.TimeZoneInfo]::ConvertTimeToUtc($dteEndTime, $tziCalendarTimeZone)
					LogTraceMessage "Variable dteCalendarEndTimeUtc set to $dteCalendarEndTimeUtc"

                    # Check if current time is On or Off hours
                    If ($dteNowUtc -ge $dteCalendarStartTimeUtc -and $dteNowUtc -le $dteCalendarEndTimeUtc)
                    {
                        $strActualHours = "Business Hours"
						LogTraceMessage "Variable strActualHours set to $strActualHours"
                    }
                    Else
                    {
                        $strActualHours = "After Hours"
						LogTraceMessage "Variable strActualHours set to $strActualHours"
                    }
                }
            }

            # Check if we have a match to send the notification
            If ($strTemplateHours -eq $strActualHours)
            {
				<#
					The template and actual hours match. This means the notification needs to be sent.
					Add the row to an array to pass to Everbridge. Once they are sent, these rows will
					be updated in the tracking table in SQL.
				#>
               $objNotificationsToSend += $strRow
			   LogTraceMessage "Template Hours and Actual Hours match, add to objNotificationsToSend array to pass to Everbridge"
            }
			ElseIf ($strTemplateType -eq "Initial Assignment")
			{
				<#
					The template and actual hours do not match. This means the notification does not need
					to be sent out. However, any notification with a type of Initial Assignment, whether
					Assigned User or Support Group, dos not follow store-forward. These notifications can
					be set to Completed in the tracking table as they did not apply when the change occured.
				#>
				$strNewRow = $strEntityChangeLogId + "," + $strNotificationId			
				$objNotificationsToUpdate += $strNewRow
				LogTraceMessage "Template Type is Initial Assignment, no need to send but row will be completed in tracking table"
			}
        }

        # Send notifications
        If ($objNotificationsToSend.Count -gt 0)
        {
            # There is at least one notification to send
            # Send notifications
            $objItemsToUpdate = SendEverbridge ($objNotificationsToSend)

            # Update tracking table
            UpdateTrackingTable ($objItemsToUpdate)
        }
		
		# Complete Initial Assignment notifications that did not have an hour match
        If ($objNotificationsToUpdate.Count -gt 0)
        {
            # Update tracking table
            UpdateTrackingTable ($objNotificationsToUpdate)
        }		

        # Function Finished
		LogTraceMessage "*** Function ProcessNotifications Finished ***"
    }

    Function SendEverbridge ($objNotifications)
    {
        # Function Started
		LogTraceMessage "*** Function SendEverbridge Started ***"

        # Send to Everbridge
		$objConnection = [Hashtable] @{ Username = "a3201122"; Credential = "YTMyMDExMjI6NTIhRWthYjY1Kjk5eUFk"; OrganizationId = "892807736723659"; ApiUrl = "https://api.everbridge.net/rest" }
		$objDeliverWithEB = $objNotifications | ConvertFrom-CSV
		$objReturn = SendToEverbridge -DeliverWithEB $objDeliverWithEB -ObjConnection $objConnection       
        Return $objReturn

        # Function Finished
		LogTraceMessage "*** Function SendEverbridge Finished ***"
    }

    Function UpdateTrackingTable ($objItemsToUpdate)
    {
        # Function Started
		LogTraceMessage "*** Function UpdateTrackingTable Started ***"

        # Create data table
        $tblStage = New-Object System.Data.DataTable
        $tblStage.Columns.Add("EntityChangeLogId", [Long])
        $tblStage.Columns.Add("NotificationId", [String])
		LogTraceMessage "Created data table and columns"

        # Loop through successfully sent notifications and add to data table
		LogTraceMessage "Loop through each row to add to table..."
        ForEach ($strRow In $objItemsToUpdate.Data)
        {	
            $tblStage.Rows.Add($strRow.EntityChangeLogId, $strRow.NotificationId)
			LogTraceMessage "Added row: $strEntityChangeLogId, $strNotificationId"
        }

        # Update tracking table so they are not sent again        
        $hshTblNotifications = @{"ParamterName" = "@tblNotifications"; "ParameterValue" = $tblStage; "TypeName" = "dbo.CITSM_AdvNotificationsType"}
        $arrParams = $($hshTblNotifications)
        Invoke-QueryDatabase -DataSource $script:strDataSource -InitialCatalog $script:strDataSourceDb -Params $arrParams -CommandText 'dbo.p_CITSM_AdvNotifications_UpdateTracking' -CommandType "StoredProcedure" 

        # Function Finished
		LogTraceMessage "*** Function UpdateTrackingTable Finished ***"
    }

    Function Invoke-QueryDatabase
    {
	    Param
        (
	        [Parameter(Mandatory=$True)]
            [String]$DataSource,

            [Parameter(Mandatory=$True)]
            [String]$InitialCatalog,

            [Parameter(Mandatory=$False)]
            [String]$ApplicationIntent,
        
            [Parameter(Mandatory=$True)]
            [String]$CommandText,		   
		
		    [Parameter(Mandatory=$False)]
		    [Array]$Params=@(),

		    [Parameter(Mandatory=$True)]
		    [String]$CommandType
        )
		
		# Function Started
		LogTraceMessage "*** Function Invoke-QueryDatabase Started ***"

        # Connect to SQL     
        If ($ApplicationIntent -eq 'ReadOnly')
        {
            $SqlConnString = "Data Source=$DataSource;Initial Catalog=$InitialCatalog;Integrated Security=SSPI;ApplicationIntent=$ApplicationIntent"
        }
        Else
        {
            $SqlConnString = "Data Source=$DataSource;Initial Catalog=$InitialCatalog;Integrated Security=SSPI"
        }
       
	    # Set the timeout
        $CommandTimeout = 60

        # Create the connection
        $SqlConn = New-Object System.Data.SqlClient.SqlConnection
        $SqlConn.ConnectionString = $SqlConnString
        $SqlConn.Open()

        # Create the command
        $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
        $SqlCmd.Connection = $SqlConn
        $SqlCmd.CommandTimeout = $CommandTimeout
        $SqlCmd.CommandText = $CommandText

        If ($CommandType -eq "Text")
        {
            # Set command type
            $SqlCmd.CommandType = [System.Data.CommandType]::Text            

            # Create the adapter
            $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
            $SqlAdapter.SelectCommand = $SqlCmd

            # Fill the data set
            $SqlDataSet = New-Object System.Data.DataSet
            $SqlAdapter.Fill($SqlDataSet)
            $SqlConn.Close()

            # Function Finished
		    LogTraceMessage "*** Function Invoke-QueryDatabase Finished ***"
    
            Return $SqlDataSet.Tables[0].Rows
        }
        ElseIf ($CommandType -eq "StoredProcedure")
        {
            # Set command type
            $SqlCmd.CommandType = [System.Data.CommandType]::StoredProcedure

            # Create the parameters
            ForEach($hshParam In $Params)
		    {
                $SqlParam = New-Object System.Data.SqlClient.SqlParameter
                $SqlParam.ParameterName = $hshParam.ParamterName
                $SqlParam.Value = $hshParam.ParameterValue
                $SqlParam.TypeName = $hshParam.TypeName

                $SqlCmd.Parameters.Add($SqlParam)
		    }

            # Execute the command
            $SqlCmd.ExecuteNonQuery()
            $SqlConn.Close()
        }
        Else
        {
            $SqlConn.Close()
        }
		
		# Function Finished
		LogTraceMessage "*** Function Invoke-QueryDatabase Finished ***"
    }

    Function LogTraceMessage ($strMessage)
    {
        $script:strTraceMessage += (Get-Date).ToString() + ':  ' + $strMessage + '~~'
    }

    # Script Started
	LogTraceMessage "*** Script AdvancedNotifications Started ***"
	
	# Main
	Main
}

Catch
{
	# Catch Started
	LogTraceMessage "*** Catch Started ***"
	
	# Log error messages
	$script:strErrorMessage = $Error[0].Exception.ToString()
	LogTraceMessage "Variable strErrorMessage set to $script:strErrorMessage"
	
	$script:intErrorState = 3
	LogTraceMessage "Variable intErrorState set to $script:intErrorState"
	
	# Catch Finished
	LogTraceMessage "*** Catch Finished ***"
}

Finally
{
	# Finally Started
	LogTraceMessage "*** Finally Started ***"
	
	# Log Error State/Message
	LogTraceMessage "Variable intErrorState = $script:intErrorState"
	
	# Finally Finished
	LogTraceMessage "*** Finally Finished ***"
	
	# Script Finished
	LogTraceMessage "*** Script AdvancedNotifications Finished ***"
}