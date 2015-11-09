<#
Name:         Cncy.Common.psm1
Description:  Module file for Cncy.Common
Author:       Christopher Mank
Date:         09/05/2015
#>

<# 
.SYNOPSIS
	Writes a message to the verbose stream
 
.DESCRIPTION
    This cmdlet takes in one string input. It then prepends the current datetime in UTC to the
	message and writes it to the Verbose PowerShell stream.

.PARAMETER StrMessage
    The message text you wish to write to the verbose stream
	
.EXAMPLE
    Write-VerboseStream -StrMessage "Todo lo puedo en Cristo que me fortalece"
 
.NOTES
    AUTHOR:  Christopher Mank
    LASTEDIT: September, 05, 2015
#>

Try
{
	Write-Output (Get-Random -Minimum 0 -Maximum 100).ToString()
}

Catch
{
	# Write the error to the Verbose and Error streams directly
    Write-Verbose $Error[0].Exception.ToString()
	Write-Error $Error[0].Exception.ToString()
}

Finally
{
	# Finally
}