$rootpath = "C:\git-projects\dcst1005\dcst1005"
$DC1 = "DC1"
$SRV1 = "SRV1"
$servicesDC1 = @("NTDS", "DNS", "Kdc", "DFSR", "Netlogon")
$servicesSRV1 = @("W3SVC", "DFS")

# Script block to check and start services
$scriptBlockDC1 = {
    param($services)
    $result = foreach ($service in $services) {
        try {
            $svc = Get-Service -Name $service -ErrorAction Stop
            if ($svc.Status -ne 'Running') {
                Start-Service $service
                Start-Sleep -Seconds 2 # Wait a bit to check the status again
                $svc.Refresh()
                if ($svc.Status -ne 'Running') {
                    throw "Failed to start."
                } else {
                    "$service started successfully."
                }
            } else {
                "$service is running on DC1."
            }
        } catch {
            "$service could not be started on DC1. Error: $_"
        }
    }
    $result
}

# Script block to check and start services on SRV1
$scriptBlockSRV1 = {
    param($services)
    $result = foreach ($service in $services) {
        try {
            $svc = Get-Service -Name $service -ErrorAction Stop
            if ($svc.Status -ne 'Running') {
                Start-Service $service
                Start-Sleep -Seconds 2 # Wait a bit to check the status again
                $svc.Refresh()
                if ($svc.Status -ne 'Running') {
                    throw "Failed to start."
                } else {
                    "$service started successfully."
                }
            } else {
                "$service is running on SRV1."
            }
        } catch {
            "$service could not be started on SRV1. Error: $_"
        }
    }
    $result
}

# Invoke the command on both machines
$resultsDC1 = Invoke-Command -ComputerName $DC1 -ScriptBlock $scriptBlockDC1 -ArgumentList (,$servicesDC1)
$resultsSRV1 = Invoke-Command -ComputerName $SRV1 -ScriptBlock $scriptBlockSRV1 -ArgumentList (,$servicesSRV1)

# Combine results from both machines
$results = $resultsDC1 + $resultsSRV1

# Generate HTML content
$html = "<html><body><h1>Service Status Report for $DC1 and $SRV1</h1><table border='1'><tr><th>Service</th><th>Status</th></tr>"
foreach ($result in $results) {
    # Split the result to separate the service name from its status message
    $splitResult = $result -split ' ', 3
    $serviceName = $splitResult[0]
    $deviceName = $splitResult[2]
    $statusMessage = $splitResult[1]
    
    if ($statusMessage -match "successfully|running") {
        $html += "<tr><td>$serviceName</td><td>$statusMessage $deviceName</font></td></tr>"
    } else {
        $html += "<tr><td>$serviceName</td><td>$statusMessage $deviceName</font></td></tr>"
    }
}
$html += "</table></body></html>"

# Specify the path where the HTML file will be saved
$filePath = "$rootpath\serviceStatusReport.html"

# Save the HTML content to a file
$html | Out-File -FilePath $filePath

# Output the path to the HTML report
Write-Host "Service status report saved to: $filePath"

# Copy the HTML report to SRV1
$session = New-PSSession -ComputerName $SRV1
Copy-Item -Path $filePath -Destination "C:\inetpub\wwwroot" -ToSession $session
