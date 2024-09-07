#region FUNCTIONS
$script:CurrentLocation = Get-Location 
$script:CurrentLocation = $CurrentLocation.Path
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
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
        $CityConverter = Import-Csv "$script:CurrentLocation\worldcities.csv"
        $CitySelected = $CitySelected.split(",")
        $AdmSelected = $CitySelected[1].tostring()
        $AdmSelected = $AdmSelected.trim()
    } catch {
        Write-Error "Cannot Find City CSV" | Out-GridView
    }
    try {
        foreach ($City in $CityConverter) {
            if ($City.city -eq $CitySelected[0] -and $City.Admin_name -eq $AdmSelected) {
                $ReturnLatLong = $City | Select-Object lat, lng
                $Lat = $ReturnLatLong.lat
                $Long = $ReturnLatLong.lng
            }
        }
        [string]$ForecastUri = "https://api.weather.gov/points/$lat,$long"
        $Request = Invoke-RestMethod -uri "$ForecastUri"
        $SecondRequest = $Request.properties.forecast
        $Forecast = Invoke-RestMethod -uri $SecondRequest
        $script:ReturnedForecast = $Forecast.properties.periods | Select-Object name, temperature, temperatureUnit, windSpeed, windDirection
        $script:ReturnedForecastTwo = $Forecast.properties.periods | Select-Object detailedForecast
    } catch {
        If ($error.CategoryInfo.category[1] -eq "InvalidData") {
            Write-Error "Invalid city or the request failed, please try again." | Out-GridView
        }
    }
    Display-WeatherData $script:ReturnedForecast $script:ReturnedForecastTwo
    #End { $ReturnedForecast | Out-GridView -Title "Weather for $CitySelected"}
    #get icons to work
}
function Display-WeatherData {
    Param (
        $DataFromGetWeatherData,
        $DataFromGetWeatherDataTwo
    )
    $DataForm = New-Object Windows.Forms.Form
    $DataForm.Text = "Weather for: $script:CityOutput"
    $DataForm.Font = New-Object Drawing.Font("Cambria", 12, [Drawing.FontStyle]::Regular)
    $DataForm.AutoSize = $true
    $DataForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$script:CurrentLocation\cloud.ico") #.\cloud.ico for exe, use full path for testings
    $DataForm.StartPosition = "CenterScreen"
    $DataForm.BackColor = [System.Drawing.Color]::WhiteSmoke
    $WeatherDataOutput = New-Object System.Windows.Forms.DataGridView  
    $WeatherDataOutput.Location = New-Object System.Drawing.Size(20,100)
    $WeatherDataOutputTwo = New-Object System.Windows.Forms.DataGridView  
    $WeatherDataOutputTwo.Location = New-Object System.Drawing.Size(20,500) 
    $PictureBox = new-object Windows.Forms.PictureBox
    $PictureBox.AutoSize = $true
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
    $WeatherArry.AddRange($DataFromGetWeatherData)
    $WeatherArryTwo = New-Object System.Collections.ArrayList
    $WeatherArryTwo.AddRange($DataFromGetWeatherDataTwo)
    $WeatherDataOutput.DataSource = $WeatherArry
    $WeatherDataOutput.AutoSize = $true
    $WeatherDataOutput.AutoSizeColumnsMode = "AllCells"
    $WeatherDataOutput.AutoSizeRowsMode = "AllCells"
    $WeatherDataOutputTwo.DataSource = $WeatherArryTwo
    $WeatherDataOutputTwo.AutoSize = $true
    $WeatherDataOutputTwo.AutoSizeColumnsMode = "AllCells"
    $WeatherDataOutputTwo.AutoSizeRowsMode = "AllCells"
    $DataForm.Controls.Add($WeatherDataOutput)
    $DataForm.Controls.Add($WeatherDataOutputTwo)
    #$DataForm.Controls.Add($PictureBox)
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
    Set-Variable -Name CityFromTxtBox -Value "$($MainMenuTxtBox.Text)" -Force
    Get-WeatherData -CitySelected "$CityFromTxtBox"
})

<#Add Controls and Show Form#>
$MainMenu.Controls.Add($MainMenuBttn)
$MainMenu.Controls.Add($MainMenuTxtBox)
$MainMenu.Controls.Add($MainMenuLabel)
$MainMenu.Topmost = $True
$MainMenu.Add_Shown({ $MainMenu.Activate() })
[void]$MainMenu.ShowDialog()
#endregion FORM CREATION