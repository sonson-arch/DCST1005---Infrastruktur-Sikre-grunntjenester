$rootpath = "C:\git-projects\dcst1005\dcst1005"


$scriptBlock = {
    # Capturing performance data
    $data = @()
    $data += Get-Counter '\Processor(_Total)\% Processor Time' | ForEach-Object { $_.CounterSamples }
    $data += Get-Counter '\Memory\% Committed Bytes In Use' | ForEach-Object { $_.CounterSamples }
    $data += Get-Counter '\Memory\Available MBytes' | ForEach-Object { $_.CounterSamples }
    $data
}

# Duration and interval settings
$duration = 1 # 10 minutes 
$interval = 10 # 10 second intervals
$startTime = Get-Date

# Initialize $results_DC1 and $results_SRV1 as arrays
$results_DC1 = @()
$results_SRV1 = @()

# Loop to collect data every interval for the duration of 24 hours
while ((New-TimeSpan -Start $startTime).TotalMinutes -lt $duration) {

    # Append the results of each iteration to $results_DC1 and $results_SRV1
    $results_DC1 += Invoke-Command -ComputerName dc1 -ScriptBlock $scriptBlock
    Start-Sleep -Seconds $interval

    $results_SRV1 += Invoke-Command -ComputerName srv1 -ScriptBlock $scriptBlock
    Start-Sleep -Seconds $interval
}


<# Sample structure for $results to simulate the actual data collection
$results = @(
    # Processor Time samples
    @{Path='\Processor(_Total)\% Processor Time'; CookedValue=20; Timestamp=(Get-Date).AddSeconds(-90)},
    @{Path='\Memory\% Committed Bytes In Use'; CookedValue=30; Timestamp=(Get-Date).AddSeconds(-90)},
    @{Path='\Memory\Available MBytes'; CookedValue=8000; Timestamp=(Get-Date).AddSeconds(-90)},
)
#>


# Initialize strings to hold formatted data for each metric
$processorTimeDataJS_DC1 = @()
$committedBytesDataJS_DC1 = @()
$availableMBytesDataJS_DC1 = @()

$processorTimeDataJS_SRV1 = @()
$committedBytesDataJS_SRV1 = @()
$availableMBytesDataJS_SRV1 = @()

foreach ($sample in $results_DC1) {
    $timestamp = $sample.Timestamp.ToString("HH:mm:ss")
    switch -Wildcard ($sample.Path) {
        '*\Processor(_Total)\% Processor Time' {
            $processorTimeDataJS_DC1 += "[`"$timestamp`", $($sample.CookedValue)]"
        }
        '*\Memory\% Committed Bytes In Use' {
            $committedBytesDataJS_DC1 += "[`"$timestamp`", $($sample.CookedValue)]"
        }
        '*\Memory\Available MBytes' {
            $availableMBytesDataJS_DC1 += "[`"$timestamp`", $($sample.CookedValue)]"
        }
    }
}

foreach ($sample in $results_SRV1) {
    $timestamp = $sample.Timestamp.ToString("HH:mm:ss")
    switch -Wildcard ($sample.Path) {
        '*\Processor(_Total)\% Processor Time' {
            $processorTimeDataJS_SRV1 += "[`"$timestamp`", $($sample.CookedValue)]"
        }
        '*\Memory\% Committed Bytes In Use' {
            $committedBytesDataJS_SRV1 += "[`"$timestamp`", $($sample.CookedValue)]"
        }
        '*\Memory\Available MBytes' {
            $availableMBytesDataJS_SRV1 += "[`"$timestamp`", $($sample.CookedValue)]"
        }
    }
}
# Combine into JavaScript arrays for both computers
$ProcessorTimeDataJS_DC1 = $processorTimeDataJS_DC1 -join ", "
$CommittedBytesDataJS_DC1 = $committedBytesDataJS_DC1 -join ", "
$AvailableMBytesDataJS_DC1 = $availableMBytesDataJS_DC1 -join ", "

$ProcessorTimeDataJS_SRV1 = $processorTimeDataJS_SRV1 -join ", "
$CommittedBytesDataJS_SRV1 = $committedBytesDataJS_SRV1 -join ", "
$AvailableMBytesDataJS_SRV1 = $availableMBytesDataJS_SRV1 -join ", "

# Create the HTML content
$htmlTemplate = @"
<html>
<head>
    <title>Performance Report - DC1 & SRV1</title>
    <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
    <script type="text/javascript">
        google.charts.load('current', {'packages':['corechart']});
        google.charts.setOnLoadCallback(drawCharts);

        function drawCharts() {
            drawChart('dc1_processorTime_chart', '% Processor Time', [['Time', 'Processor Time'], PLACEHOLDER_PROCESSOR_TIME_DATA_DC1]);
            drawChart('dc1_committedBytes_chart', '% Committed Bytes In Use', [['Time', '% Committed Bytes'], PLACEHOLDER_COMMITTED_BYTES_DATA_DC1]);
            drawChart('dc1_availableMBytes_chart', 'Available MBytes', [['Time', 'Available MBytes'], PLACEHOLDER_AVAILABLE_MBYTES_DATA_DC1]);
            drawChart('srv1_processorTime_chart', '% Processor Time', [['Time', 'Processor Time'], PLACEHOLDER_PROCESSOR_TIME_DATA_SRV1]);
            drawChart('srv1_committedBytes_chart', '% Committed Bytes In Use', [['Time', '% Committed Bytes'], PLACEHOLDER_COMMITTED_BYTES_DATA_SRV1]);
            drawChart('srv1_availableMBytes_chart', 'Available MBytes', [['Time', 'Available MBytes'], PLACEHOLDER_AVAILABLE_MBYTES_DATA_SRV1]);
        }

        function drawChart(elementId, title, dataRows) {
            var data = google.visualization.arrayToDataTable(dataRows);
            var options = {
                title: title,
                curveType: 'function',
                legend: { position: 'bottom' }
            };
            var chart = new google.visualization.LineChart(document.getElementById(elementId));
            chart.draw(data, options);
        }
    </script>
</head>
<body>
    <h2>Performance Report for DC1</h2>
    <div id="dc1_processorTime_chart" style="width: 900px; height: 500px"></div>
    <div id="dc1_committedBytes_chart" style="width: 900px; height: 500px"></div>
    <div id="dc1_availableMBytes_chart" style="width: 900px; height: 500px"></div>

    <h2>Performance Report for SRV1</h2>
<div id="srv1_processorTime_chart" style="width: 900px; height: 500px"></div>
<div id="srv1_committedBytes_chart" style="width: 900px; height: 500px"></div>
<div id="srv1_availableMBytes_chart" style="width: 900px; height: 500px"></div>

</body>
</html>
"@

# Replace placeholders in the HTML template with the actual data
$htmlContent = $htmlTemplate -replace 'PLACEHOLDER_PROCESSOR_TIME_DATA_DC1', $ProcessorTimeDataJS_DC1 `
                             -replace 'PLACEHOLDER_COMMITTED_BYTES_DATA_DC1', $CommittedBytesDataJS_DC1 `
                             -replace 'PLACEHOLDER_AVAILABLE_MBYTES_DATA_DC1', $AvailableMBytesDataJS_DC1 `
                             -replace 'PLACEHOLDER_PROCESSOR_TIME_DATA_SRV1', $ProcessorTimeDataJS_SRV1 `
                             -replace 'PLACEHOLDER_COMMITTED_BYTES_DATA_SRV1', $CommittedBytesDataJS_SRV1 `
                             -replace 'PLACEHOLDER_AVAILABLE_MBYTES_DATA_SRV1', $AvailableMBytesDataJS_SRV1
            

# Save the modified HTML content to a file
$htmlContent | Out-File -FilePath "$rootpath\performanceReport.html" -Force
