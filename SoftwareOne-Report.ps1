#
# SoftwareOne-Report.ps1
#

# Created by:   Marco Musolesi
# Created on:   2023-10-09

# Version:      1.0

# Description:  This script is used to manage report on oneclub api

# Usage:        SoftwareOne-Report.ps1 -username <username> -password <password> -apikey <apikey>

# Notes:        This script requires the SoftwareOne-Authenticate.ps1 script to be in the same folder.

# Swagger:      https://app.swaggerhub.com/apis/OneClub/CHAAS/1.0

$oneclubapi_url = "https://oneclubapi.softwareone.com"

$inisettings = Get-Content -Path ".\SoftwareOne.ini"

# ask for a custom ini file

$ini = Read-Host -Prompt "Do you want to use a custom ini file? (Y/N)"
if ($ini -eq "Y") {
    $inifile = Read-Host -Prompt "Please enter the path of the ini file"
    $inisettings = Get-Content -Path $inifile
}

#load setting from ini

foreach ($line in $inisettings) {
    if ($line -like "username=*") {
        $username = $line.Substring(9)
    }
    if ($line -like "password=*") {
        $password = $line.Substring(9)
    }
    if ($line -like "apikey=*") {
        $apikey = $line.Substring(7)
    }
}

$ExportPath = "C:\Temp\SoftwareOne"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ExportPath = "$ExportPath\$timestamp"

# If path doesn't exist, create it

if (!(Test-Path -Path $ExportPath)) {
    New-Item -ItemType Directory -Path $ExportPath
}

function Connect-SoftwareOne {
    param (
        [Parameter(Mandatory = $true)]
        [string]$username,
        [Parameter(Mandatory = $true)]
        [string]$password,
        [Parameter(Mandatory = $true)]
        [string]$apikey
    )

    # Connect to SoftwareOne API
    
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/json")

    $body = "{`"username`": `"$username`", `"password`": `"$password`", `"apikey`": `"$apikey`"}"

    $url = "$global:oneclubapi_url/oauth_token"

    write-host "Function: Connect-SoftwareOne: this function retrieve the oauth token"
    write-host "API /oauth_token"
    write-host "Going to call: $url"
    write-host $url

    $response = Invoke-RestMethod $url -Method 'POST' -Headers $headers -Body $body
    return $response.oauthToken
    
}

function get-SoftwareOneCustomers {
    param (
        [Parameter(Mandatory = $true)]
        [string]$token
    )

    # Get a List of all customers
    
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $token")

    $url = "$global:oneclubapi_url/ECustOperations/get"

    write-host "Function: get-SoftwareOneCustomers: this function retrieve the customers"
    write-host "API /ECustOperations/get"
    write-host "Going to call: $url"
    write-host $url


    $response = Invoke-RestMethod $url -Method 'GET' -Headers $headers
    return $response.data.data
}

function get-SoftwareOneCustomerDetail {
    param (
        [Parameter(Mandatory = $true)]
        [string]$token,
        [Parameter(Mandatory = $true)]
        [string]$customerID
    )
    
    # Get a customer by Id
        
    $url = "$global:oneclubapi_url/ECustOperations/getById"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $token")

    $params = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $params.Add("id", $customerID)
    
    $url += "?" + (($params.GetEnumerator() | ForEach-Object { $_.Key + "=" + $_.Value }) -join '&')

    write-host "Function: get-SoftwareOneCustomerDetail: this function retrieve the customer details"
    write-host "API /ECustOperations/getById"
    write-host "Going to call: $url"
    write-host $url

    $response = Invoke-RestMethod $url -Method 'GET' -Headers $headers

    return $response.data
}

function get-SoftwareOneSubscriptions {
    param (
        [Parameter(Mandatory = $true)]
        [string]$token
    )

    # Get a List of all subscriptions

    $url = "$global:oneclubapi_url/subscriptionOperatios/getSubscriptions"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $token")

    $params = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $params.Add("page", "1")
    $params.Add("pageSize", "-1")
    $params.Add("offset", "0")
    
    $url += "?" + (($params.GetEnumerator() | ForEach-Object { $_.Key + "=" + $_.Value }) -join '&')

    write-host "Function: get-SoftwareOneSubscriptions: this function retrieve the subscriptions"
    write-host "API /subscriptionOperatios/getSubscriptions"
    write-host "Going to call: $url"
    write-host $url

    $response = Invoke-RestMethod $url -Method 'GET' -Headers $headers

    return $response
}

function get-SoftwareOneSubscriptionDetails {
    param (
        [Parameter(Mandatory = $true)]
        [string]$token,
        [Parameter(Mandatory = $true)]
        [string]$subscriptionID
    )

    # Get a subscription by Id

    $url = "$global:oneclubapi_url/subscriptionOperatios/getSubscriptionById"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $token")

    $params = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $params.Add("id", $subscriptionID)
    $params.Add("pageSize", "-1")
    $params.Add("offset", "0")
    
    $url += "?" + (($params.GetEnumerator() | ForEach-Object { $_.Key + "=" + $_.Value }) -join '&')

    write-host "Function: get-SoftwareOneSubscriptionDetails: this function retrieve the subscription details"
    write-host "API /subscriptionOperatios/getSubscriptionById"
    write-host "Going to call: $url"
    write-host $url

    $response = Invoke-RestMethod $url -Method 'GET' -Headers $headers

    return $response.data.data   
}

function get-AzureModrenCommerceReport {
    param (
        [Parameter(Mandatory = $true)]
        [string]$token,
        [Parameter(Mandatory = $true)]
        [string]$subscriptionID,
        [Parameter(Mandatory = $true)]
        [string]$microsoftId,
        [Parameter(Mandatory = $true)]
        [datetime]$billingDate,
        [Parameter(Mandatory = $true)]
        [string]$reportType,
        [Parameter(Mandatory = $true)]
        [string]$viewType
    )

    # Get Azure Plan Billing Report
    
    $url = "$global:oneclubapi_url/v1/azureOperations/getAzureModrenCommerceReport"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $token")


    $billingDateISO = $billingDate.ToString("yyyy-MM-ddTHH:mm:ss.fffZ+00:00")
  

    $params = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $params.Add("pageSize", "-1")
    $params.Add("offset", "0")
    $params.Add("microsoftId", $microsoftId)
    $params.Add("subscriptionId", $subscriptionID)
    $params.Add("viewType", $viewType)
    $params.Add("period", "Previous")
    $params.Add("reportType", $reportType)
    $params.Add("billingDate", $billingDateISO)

    $url += "?" + (($params.GetEnumerator() | ForEach-Object { $_.Key + "=" + $_.Value }) -join '&')

    write-host "Function: get-AzureModrenCommerceReport: this function retrieve billing report of a subscription for a specific period"
    write-host "API /v1/azureOperations/getAzureModrenCommerceReport"
    write-host "Going to call: $url"
    
    $response = Invoke-RestMethod $url -Method 'GET' -Headers $headers

    return $response
    
}

function get-modernAzureDetailedBilling {
    param (
        [Parameter(Mandatory = $true)]
        [string]$token,
        [Parameter(Mandatory = $true)]
        [string]$subscriptionID,
        [Parameter(Mandatory = $true)]
        [string]$microsoftId,
        [Parameter(Mandatory = $true)]
        [datetime]$billingDate,
        [Parameter(Mandatory = $true)]
        [string]$reportType,
        [Parameter(Mandatory = $true)]
        [string]$viewType
    )

    # Get Azure Plan Detailed Billing Report
    
    $url = "$global:oneclubapi_url/azureOperations/v1/modernAzureDetailedBilling"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorizazion", "Bearer $token")

    $billingDateISO = $billingDate.ToString("yyyy-MM-ddTHH:mm:ss.fffZ+00:00")

    $params = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $params.Add("pageSize", "-1")
    $params.Add("offset", "0")
    $params.Add("microsoftId", $microsoftId)
    $params.Add("subscriptionId", $subscriptionID)
    $params.Add("billingDate", $billingDateISO)
    $params.Add("reportType", $reportType)
    $params.Add("viewType", $viewType)

    $url += "?" + (($params.GetEnumerator() | ForEach-Object { $_.Key + "=" + $_.Value }) -join '&')

    write-host "Function: get-modernAzureDetailedBilling: this function retrieve the detalied billing report for a subscription for a secific billing date"
    write-host "API /azureOperations/v1/modernAzureDetailedBilling"
    write-host "Going to call: $url"

    $response = Invoke-RestMethod $url -Method 'GET' -Headers $headers

    return $response

}

function get-modernOneTimeUnbilledReport {
    param (
        [Parameter(Mandatory = $true)]
        [string]$token,
        [Parameter(Mandatory = $true)]
        [string]$subscriptionID,
        [Parameter(Mandatory = $true)]
        [string]$microsoftId,
        [Parameter(Mandatory = $true)]
        [datetime]$startDate,
        [Parameter(Mandatory = $true)]
        [datetime]$endDate,
        [Parameter(Mandatory = $true)]
        [string]$reportType,
        [Parameter(Mandatory = $true)]
        [string]$viewType
    )

    # Get Azure Utilization (unbilled) Report

    $url = "$global:oneclubapi_url/v1/azureOperations/modernOneTimeUnbilledReport"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorizazion", "Bearer $token")

    $startDateISO = $startDate.ToString("yyyy-MM-ddTHH:mm:ss.fffZ+00:00")
    $endDateISO = $endDate.ToString("yyyy-MM-ddTHH:mm:ss.fffZ+00:00")

    $params = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $params.Add("pageSize", "-1")
    $params.Add("offset", "0")
    $params.Add("microsoftId", $microsoftId)
    $params.Add("subscriptionId", $subscriptionID)
    $params.Add("startDate", $startDateISO)
    $params.Add("endDate", $endDateISO)
    $params.Add("reportType", $reportType)
    $params.Add("viewType", $viewType)

    $url += "?" + (($params.GetEnumerator() | ForEach-Object { $_.Key + "=" + $_.Value }) -join '&')

    write-host "Function: get-modernOneTimeUnbilledReport: this function retrieve the unbilled report for a subscription from a start date to an end date"
    write-host "API /v1/azureOperations/modernOneTimeUnbilledReport"
    write-host "Going to call: $url"

    $response = Invoke-RestMethod $url -Method 'GET' -Headers $headers

    return $response    
}


function get-SoftwareOneUnbilledReportSummary {
    param (
        [Parameter(Mandatory = $true)]
        [string]$token,
        [Parameter(Mandatory = $true)]
        [string]$subscriptionID,
        [Parameter(Mandatory = $true)]
        [string]$microsoftId
    )

    # No documentation found on swagger
    
    $url = "$global:oneclubapi_url/v1/azureOperations/modernOneTimeUnbilledReportSummary"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Bearer $token")

    $params = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $params.Add("pageSize", "-1")
    $params.Add("offset", "0")
    $params.Add("microsoftId", $microsoftId)
    $params.Add("subscriptionId", $subscriptionID)
    $params.Add("viewType", "RS")
    $params.Add("period", "Previous")

    $url += "?" + (($params.GetEnumerator() | ForEach-Object { $_.Key + "=" + $_.Value }) -join '&')

    write-host "Function: get-SoftwareOneUnbilledReportSummary: this function retrieve undocumented report data"
    write-host "API /v1/azureOperations/modernOneTimeUnbilledReportSummary"
    write-host "Going to call: $url"
    write-host $url

    $response = Invoke-RestMethod $url -Method 'GET' -Headers $headers

    return $response
    
    
}

$oauthToken=Connect-SoftwareOne -username $username -password $password -apikey $apikey
$customers=get-SoftwareOneCustomers -token $oauthToken

Export-Csv -InputObject $customers -NoTypeInformation -Delimiter ";" -NoClobber -Path "$ExportPath\customers.csv"

$customerdetail = get-SoftwareOneCustomerDetail -token $oauthToken -customerID $customers[0].id

Export-Csv -InputObject $customerdetail -NoTypeInformation -Delimiter ";" -NoClobber -Path "$ExportPath\customerdetail.csv"

$subscriptionlist = get-SoftwareOneSubscriptions -token $oauthToken

# convert $subscriptionlist.orderData to be exported in csv

$subscriptionlist.orderData | ConvertTo-Csv -NoTypeInformation -Delimiter ";" | Out-File -Encoding utf8 "$ExportPath\subscriptions-orderData.csv"

Export-Csv -InputObject $subscriptionlist.subscriptionSummary -NoTypeInformation -Delimiter ";" -NoClobber -Path "$ExportPath\subscriptions-summary.csv"

foreach ($subscription in $subscriptionlist.orderData) {

    $AzureModrenCommerceReport = get-AzureModrenCommerceReport -token $oauthToken -subscriptionID $subscription.subscriptionId -microsoftId $subscription.microsoftId -billingDate $subscription.billingDate -reportType "AP" -viewType "viewType"

    write-host "Exporting AzureModrenCommerceReport for subscription $($subscription.subscriptionId)"
    Read-Host -Prompt "Press Enter to continue"
    write-host $AzureModrenCommerceReport
    Read-Host -Prompt "Press Enter to continue"


    Export-Csv -InputObject $AzureModrenCommerceReport -NoTypeInformation -Delimiter ";" -NoClobber -Path "$ExportPath\AzureModrenCommerceReport.csv" -Append

    
}

foreach  ($subscription in $subscriptionlist.orderData) {

    $AzureModrenCommerceReport = get-modernAzureDetailedBilling -token $oauthToken -subscriptionID $subscription.subscriptionId -microsoftId $subscription.microsoftId -billingDate $subscription.billingDate -reportType "AP" -viewType "viewType"

    write-host "Exporting modernAzureDetailedBilling for subscription $($subscription.subscriptionId)"
    Read-Host -Prompt "Press Enter to continue"
    write-host $AzureModrenCommerceReport
    Read-Host -Prompt "Press Enter to continue"

    Export-Csv -InputObject $AzureModrenCommerceReport -NoTypeInformation -Delimiter ";" -NoClobber -Path "$ExportPath\modernAzureDetailedBilling.csv" -Append

}

foreach  ($subscription in $subscriptionlist.orderData) {

    for ($i = 0; $i -lt 3; $i++) {
        $startDate = (Get-Date).AddMonths(-$i).AddDays(-((Get-Date).AddMonths(-3).Day - 1)).Date
        $endDate = $startDate.AddMonths(1).AddSeconds(-1)

        #write-host "startDate: $startDate - endDate: $endDate"
        $modernOneTimeUnbilledReport = get-modernOneTimeUnbilledReport -token $oauthToken -subscriptionID $subscription.subscriptionId -microsoftId $subscription.microsoftId -startDate $startDate -endDate $endDate -reportType "AP" -viewType "viewType"

        write-host "Exporting modernOneTimeUnbilledReport for subscription $($subscription.subscriptionId) from $startDate to $endDate"
        Read-Host -Prompt "Press Enter to continue"
        write-host $modernOneTimeUnbilledReport
        Read-Host -Prompt "Press Enter to continue"

        Export-Csv -InputObject $modernOneTimeUnbilledReport -NoTypeInformation -Delimiter ";" -NoClobber -Path "$ExportPath\modernOneTimeUnbilledReport.csv" -Append
    }
}
