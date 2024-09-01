
$script:CurrentLocation = Get-Location 
$script:CurrentLocation = $CurrentLocation.Path
function Get-WeatherData {
    param (
        $CitySelected
    )
    $CityConverter = Import-Csv "$script:CurrentLocation\worldcities.csv"
    $CitySelected = $CitySelected.split(",")
    $AdmSelected = $CitySelected[1].tostring()
    $AdmSelected = $AdmSelected.trim()
    foreach ($City in $CityConverter) {
        if ($City.city -eq $CitySelected[0] -and $City.Admin_name -eq $AdmSelected) {
            Write-Output $city
            $ReturnLatLong = $City | Select-Object lat, lng
            $Lat = $ReturnLatLong.lat
            $Long = $ReturnLatLong.lng
        }
    }
    [string]$ForecastUri = "https://api.weather.gov/points/$lat,$long"
    $Request = Invoke-RestMethod -uri "$ForecastUri"
    $SecondRequest = $Request.properties.forecast
    $Forecast = Invoke-RestMethod -uri $SecondRequest
    $ReturnedForecast = $Forecast.properties.periods
    $ReturnedForecast = $ReturnedForecast | Select-Object name, temperature, temperatureUnit, windSpeed, windDirection, detailedForecast
    $CitySelected = $CitySelected.trim()
    $ReturnedForecast | Out-GridView -Title "Weather Forecast for $CitySelected"
    #get icons to work
}

<#region FORM CREATION#>
<#Form Creation#>
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$MainMenu = New-Object System.Windows.Forms.Form
$MainMenu.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$script:CurrentLocation\cloud.ico") #.\cloud.ico for exe, use full path for testings
$MainMenu.Font = New-Object Drawing.Font("Cambria", 12, [Drawing.FontStyle]::Regular)
$MainMenu.Size = New-Object System.Drawing.Size(470, 200)
$MainMenu.StartPosition = "CenterScreen"
$MainMenu.Text = "No BS Weather App"
$MainMenu.ForeColor = [System.Drawing.Color]::Black
$MainMenu.BackColor = [System.Drawing.Color]::WhiteSmoke

<#Label Creation#>
$MainMenuLabel = New-Object Windows.Forms.Label
$MainMenuLabel.Text = "Enter City and Administravive Devison."    
$MainMenuLabel.Location = New-Object System.Drawing.Size(30,20) 
$MainMenuLabel.Size = New-Object System.Drawing.Size(340,20) 

<#Textbox #>
$MainMenuTxtBox = New-Object Windows.Forms.TextBox
$MainMenuTxtBox.AutoSize = $true
$MainMenuTxtBox.Padding = New-Object -TypeName System.Windows.Forms.Padding -ArgumentList (10,10,10,10)
$MainMenuTxtBox.Location = New-Object System.Drawing.Size(30,40)
$MainMenuTxtBox.Size = New-Object System.Drawing.Size(260,20) 


<#Button Creation#>
$MainMenuBttn = New-Object Windows.Forms.Button
$MainMenuBttn.Location = New-Object System.Drawing.Size($MainMenuTxtBox.Right, $MainMenuTxtBox.Top)
$MainMenuBttn.Size = New-Object System.Drawing.Size(75,20)
$MainMenuBttn.Text = "Get Forecast"
$MainMenuBttn.AutoSize = $true
$MainMenuBttn.Add_Click({ 
    Set-Variable -Name CityFromTxtBox -Value "$($MainMenuTxtBox.Text)"
    Get-WeatherData -CitySelected "$CityFromTxtBox"
})

<#Add Controls and Show Form#>
$MainMenu.Controls.Add($MainMenuBttn)
$MainMenu.Controls.Add($MainMenuTxtBox)
$MainMenu.Controls.Add($MainMenuLabel)
$MainMenu.Topmost = $True
$MainMenu.Add_Shown({ $MainMenu.Activate() })
[void]$MainMenu.ShowDialog()
<#endregion FORM CREATION#>