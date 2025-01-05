#region FUNCTIONS
$script:CurrentLocation = Get-Location 
$script:CurrentLocation = $CurrentLocation.Path
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$script:ApiKey = "ADOZHku4NFxtcktMopauig==yn9ppoYOcv1Mcs95" #API KEY IS ON DESKTOP
$envVar = [Environment]::GetEnvironmentVariable("LocationSavedForWeather", "User")
if (-not $envVar) {
    [Environment]::SetEnvironmentVariable("LocationSavedForWeather", "$LocationSavedData", "User")
}
$SavedCities = $envVar
#endregion DECLORATIONS
#region FUNCTIONS
function Get-WeatherData {
    Param (
        [Parameter(Mandatory, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$CitySelected
    )
    try {
        $script:CityOutput = $CitySelected
        $CityArray = $CitySelected.Split(",")
        $City = $CityArray[0].ToString()
        $Country = $CityArray[1].ToString()
        $LatLongUrl = "https://api.api-ninjas.com/v1/geocoding?city=$City&country=$Country"
        $Header = @{
            'X-Api-Key' = "$script:ApiKey"
        }
        $ReturnLatLong = Invoke-RestMethod -Uri $LatLongUrl -Headers $Header
        $Lat = $ReturnLatLong.latitude[0]
        $Long = $ReturnLatLong.longitude[0]
        [string]$ForecastUri = "https://api.weather.gov/points/$lat,$long"
        $Request = Invoke-RestMethod -uri "$ForecastUri"
        $SecondRequest = $Request.properties.forecast
        $Forecast = Invoke-RestMethod -uri $SecondRequest
        $script:ReturnedForecast = $Forecast.properties.periods | Select-Object name, @{n='Day'; e='name'}, `
            temperature, @{n='Forecasted Temperature'; e='temperature'}, temperatureUnit, @{n='F/C'; e='temperatureUnit'}, `
                windSpeed, @{n='Wind Speed'; e='windSpeed'}, windDirection, @{n='Wind Direction'; e='windDirection'}
        $script:ReturnedForecast = $script:ReturnedForecast | Select-Object 'Day', 'Forecasted Temperature', 'F/C', 'Wind Speed', 'Wind Direction'
        $script:ReturnedForecastTwo = $Forecast.properties.periods | Select-Object detailedForecast
        $script:ReturnedForecastTwo = $script:ReturnedForecastTwo | Select-Object detailedForecast, @{n='Full Forecast'; e='detailedForecast'}
        $script:ReturnedForecastTwo = $script:ReturnedForecastTwo | Select-Object 'Full Forecast'
    } catch {
        If ($error.CategoryInfo.category[1] -eq "InvalidData") {
            Write-Error "Invalid city or the request failed, please try again." | Out-GridView
        }
    }
    #get icons to work
    Display-WeatherData
}
function Display-WeatherData {
    #create data form
    $DataForm = New-Object Windows.Forms.Form
    $DataForm.Text = "Weather for: $script:CityOutput"
    $DataForm.Font = New-Object Drawing.Font("Cambria", 12, [Drawing.FontStyle]::Regular)
    $DataForm.AutoSize = $true
    $DataForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$script:CurrentLocation\cloud.ico") #.\cloud.ico for exe, use full path for testings
    $DataForm.StartPosition = "CenterScreen"
    $DataForm.BackColor = [System.Drawing.Color]::WhiteSmoke
    $DataForm.WindowState = "Maximized"
    #location of the data grids on data form
    $WeatherDataOutput = New-Object System.Windows.Forms.DataGridView  
    $WeatherDataOutput.Location = New-Object System.Drawing.Size(20,100)
    $WeatherDataOutputTwo = New-Object System.Windows.Forms.DataGridView  
    $WeatherDataOutputTwo.Location = New-Object System.Drawing.Size(20,500)
    #declare forms above, props below
    #$PictureBox = new-object Windows.Forms.PictureBox
    #$PictureBox.AutoSize = $true
    <#
    mkdir "$script:CurrentLocation\picturestemp" -Force
    $i = 1
    foreach ($img in $script:ReturnedForecast.icon) {
        Invoke-WebRequest -Uri $img -OutFile "$script:CurrentLocation\picturestemp\icon$i.png"
        $i++
    }
    NEED TO GET THIS TO WORK, MUST FIGURE OUT HOW TO ITERATE THROUGH AND ADD PICTURES TO THE PICTURE BOX
    $TempDir = Get-ChildItem -Path "$script:CurrentLocation\picturestemp"
    foreach ($png in $TempDir.Name) {
        $Picture = Get-Item "$script:CurrentLocation\picturestemp\$png"
        $WeatherPNG = [System.Drawing.Image]::FromFile($Picture)
        $PictureBox.Image += $WeatherPNG
    }
    #>
    $WeatherArry = New-Object System.Collections.ArrayList
    $WeatherArry.AddRange($script:ReturnedForecast)
    $WeatherArryTwo = New-Object System.Collections.ArrayList
    $WeatherArryTwo.AddRange($script:ReturnedForecastTwo)
    $WeatherDataOutput.DataSource = $WeatherArry
    $WeatherDataOutput.AutoSize = $true
    $WeatherDataOutput.AutoSizeColumnsMode = "AllCells"
    $WeatherDataOutput.AutoSizeRowsMode = "AllCells"
    $WeatherDataOutputTwo.DataSource = $WeatherArryTwo
    $WeatherDataOutputTwo.AutoSize = $true
    $WeatherDataOutputTwo.AutoSizeColumnsMode = "AllCells"
    $WeatherDataOutputTwo.AutoSizeRowsMode = "AllCells"
    $WeatherDataOutputTwo.MaximumSize = New-Object System.Drawing.Size(1000, 1000) # Set maximum size
    $WeatherDataOutputTwo.ScrollBars = "Both"
    $DataForm.Controls.Add($WeatherDataOutput)
    $DataForm.Controls.Add($WeatherDataOutputTwo)
    $WeatherDataOutputTwo.PerformLayout()
    $DataForm.Topmost = $True
    $DataForm.Add_Shown({ $DataForm.Activate() })
    [void]$DataForm.ShowDialog()
}
#endregion FUNCTIONS

#region FORM CREATION
<#Form Creation#>
$MainMenu = New-Object System.Windows.Forms.Form
$MainMenu.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$script:CurrentLocation\cloud.ico") #.\cloud.ico for exe, use full path for testings
$MainMenu.Font = New-Object Drawing.Font("Cambria", 12, [Drawing.FontStyle]::Regular)
$MainMenu.Size = New-Object System.Drawing.Size(470, 200)
$MainMenu.StartPosition = "CenterScreen"
$MainMenu.Text = "No BS Weather App"
$MainMenu.BackColor = [System.Drawing.Color]::WhiteSmoke

<#Label Creation#>
$MainMenuLabel = New-Object Windows.Forms.Label
$MainMenuLabel.Text = "Enter City and Country. EX: Cleveland, USA"    
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
    Set-Variable -Name CityFromTxtBox -Value "$($MainMenuTxtBox.Text)" -Force
    Get-WeatherData -CitySelected "$CityFromTxtBox"
})
$SaveBttn = New-Object Windows.Forms.Button
$SaveBttn.Location = New-Object System.Drawing.Size($MainMenuTxtBox.Center, $MainMenuTxtBox.Top)
$SaveBttn.Size = New-Object System.Drawing.Size(75,20)
$SaveBttn.Text = "Save City"
$SaveBttn.AutoSize = $true
$SaveBttn.Add_Click({
    [Environment]::SetEnvironmentVariable("LocationSavedForWeather", "$($MainMenuTxtBox.Text)", "User")
})
if ($SavedCities) {
    $i = 0
    foreach ($city in $SavedCities) {
        $i++
        ${$NewSavedCityButton + $i} = New-Object Windows.Forms.Button
        ${$NewSavedCityButton + $i} = New-Object Windows.Forms.Button
        ${$NewSavedCityButton + $i}.Location = New-Object System.Drawing.Size($MainMenuTxtBox.Right, $MainMenuTxtBox.Bottom)
        ${$NewSavedCityButton + $i}.Size = New-Object System.Drawing.Size(75,20)
        ${$NewSavedCityButton + $i}.Text = "Get Forecast"
        ${$NewSavedCityButton + $i}.AutoSize = $true
        ${$NewSavedCityButton + $i}.Add_Click({ 
            Set-Variable -Name CityFromTxtBox -Value "$(${$NewSavedCityButton + $i}.Text)" -Force
            Get-WeatherData -CitySelected "$CityFromTxtBox"
        })
    }
}
<#Add Controls and Show Form#>
$MainMenu.Controls.Add($MainMenuBttn)
$MainMenu.Controls.Add($SaveBttn)
$MainMenu.Controls.Add($MainMenuTxtBox)
$MainMenu.Controls.Add($MainMenuLabel)
$MainMenu.Topmost = $True
$MainMenu.Add_Shown({ $MainMenu.Activate() })
[void]$MainMenu.ShowDialog()
#endregion FORM CREATION