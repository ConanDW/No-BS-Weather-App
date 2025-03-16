#region FUNCTIONS
$script:CurrentLocation = Get-Location
$script:CurrentLocation = $CurrentLocation.Path
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Modern Color Scheme
$backgroundColor = [System.Drawing.ColorTranslator]::FromHtml("#F0F4F8") # Light Gray
$textColor = [System.Drawing.ColorTranslator]::FromHtml("#333333")      # Dark Gray
$accentColor = [System.Drawing.ColorTranslator]::FromHtml("#29ABE2")      # Light Blue

# Encoded API Key
$EncodedApiKey = "QURPWkhrdTRORnh0Y2t0TW9wYXVpZz09eW45cHBvWU9jdjFNY3M5NQ=="
$DecodedApiKey = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($EncodedApiKey))
$script:ApiKey = "$DecodedApiKey"

# Registry Key for Saved Cities
$script:RegKey = Get-ItemProperty -Path "HKCU:\Software\NoBSWeatherApp" -Name "SavedCities"
if (-not $script:RegKey) {
    New-Item -Path "HKCU:\Software\NoBSWeatherApp" -Name "SavedCities" -force
    New-ItemProperty -Path "HKCU:\Software\NoBSWeatherApp" -Name "SavedCities" -Value "" -Type MultiString
}
#endregion DECLORATIONS

#region FUNCTIONS
function Get-WeatherData {
    Param (
        [Parameter(Mandatory, Position = 0)]
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

        # NWS API to get forecast periods (for icons)
        [string]$ForecastUri = "https://api.weather.gov/points/$lat,$long"
        $Request = Invoke-RestMethod -uri "$ForecastUri"
        $SecondRequest = $Request.properties.forecast
        $Forecast = Invoke-RestMethod -uri $SecondRequest
        $script:ReturnedForecast = $Forecast.properties.periods | Select-Object name, @{n='Day';e='name'}, temperature, @{n='Forecasted Temperature';e='temperature'}, temperatureUnit, @{n='F/C';e='temperatureUnit'}, windSpeed, @{n='Wind Speed';e='windSpeed'}, windDirection, @{n='Wind Direction';e='windDirection'}, icon
        $script:ReturnedForecastTwo = $Forecast.properties.periods | Select-Object detailedForecast
        $script:ReturnedForecastTwo = $script:ReturnedForecastTwo | Select-Object detailedForecast, @{
                n = 'Full Forecast'
            ;
                e = 'detailedForecast'
            }
        $script:ReturnedForecastTwo = $script:ReturnedForecastTwo | Select-Object 'Full Forecast'

        # Api-Ninjas to get current weather
        $WeatherUrl = "https://api.api-ninjas.com/v1/weather?lat=$Lat&lon=$Long"
        $Header = @{
            'X-Api-Key' = "$script:ApiKey"
        }
        $Weather = Invoke-RestMethod -Uri $WeatherUrl -Headers $Header
        $script:CurrentWeather = $Weather | Select-Object temperature, feels_like, humidity, wind_speed, wind_direction, cloud_pct

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
    $DataForm.Font = New-Object Drawing.Font("Segoe UI", 12, [Drawing.FontStyle]::Regular)
    $DataForm.AutoSize = $true
    $DataForm.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$script:CurrentLocation\cloud.ico") #.\cloud.ico for exe, use full path for testings
    $DataForm.StartPosition = "CenterScreen"
    $DataForm.BackColor = $backgroundColor

    #location of the data grids on data form
    $WeatherDataOutput = New-Object System.Windows.Forms.DataGridView
    $WeatherDataOutput.Location = New-Object System.Drawing.Size(20, 100)
    $WeatherDataOutputTwo = New-Object System.Windows.Forms.DataGridView
    $WeatherDataOutputTwo.Location = New-Object System.Drawing.Size(20, 500)
    $WeatherDataOutputThree = New-Object System.Windows.Forms.DataGridView
    $WeatherDataOutputThree.Location = New-Object System.Drawing.Size(20, 900)

    # Picture Box Setup
    #$PictureBox = New-Object Windows.Forms.PictureBox
    #$PictureBox.Location = New-Object System.Drawing.Size(20, 700) # Adjust location as needed
    #$PictureBox.Size = New-Object System.Drawing.Size(200, 200)   # Adjust size as needed
    #$PictureBox.SizeMode = [Windows.Forms.PictureBoxSizeMode]::Zoom # Or another suitable mode
    #$DataForm.Controls.Add($PictureBox)

    try {
        # Create a temporary directory for the icons
        $TempDir = Join-Path $script:CurrentLocation "picturestemp"
        New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

        # Create a table layout panel to hold the forecast information
        $forecastTable = New-Object System.Windows.Forms.TableLayoutPanel
        $forecastTable.Location = New-Object System.Drawing.Size(20, 700)
        $forecastTable.AutoSize = $true
        $DataForm.Controls.Add($forecastTable)

        # Set the table layout panel to have as many columns as there are forecast periods
        $forecastTable.ColumnCount = $script:ReturnedForecast.Count

        # Loop through the forecast periods and display the information
        $i = 0
        foreach ($forecast in $script:ReturnedForecast) {
            # Download the icon
            $imgUrl = $forecast.icon
            $iconPath = Join-Path $TempDir "$($forecast.Day).png"
            Invoke-WebRequest -Uri $imgUrl -OutFile $iconPath

            # Load the image
            $WeatherPNG = [System.Drawing.Image]::FromFile($iconPath)

            # Create a PictureBox for the icon
            $PictureBox = New-Object System.Windows.Forms.PictureBox
            $PictureBox.Image = $WeatherPNG
            $PictureBox.Size = New-Object System.Drawing.Size(50, 50)
            $PictureBox.SizeMode = [Windows.Forms.PictureBoxSizeMode]::Zoom

            # Create a label for the day
            $dayLabel = New-Object System.Windows.Forms.Label
            $dayLabel.Text = $forecast.Day
            $dayLabel.AutoSize = $true

            # Create a label for the temperature
            $temperatureLabel = New-Object System.Windows.Forms.Label
            $temperatureLabel.Text = "$($forecast.'Forecasted Temperature') $($forecast.'F/C')"
            $temperatureLabel.AutoSize = $true

            # Add the controls to the table layout panel
            $forecastTable.Controls.Add($PictureBox, $i, 0) # Column, Row
            $forecastTable.Controls.Add($dayLabel, $i, 1)
            $forecastTable.Controls.Add($temperatureLabel, $i, 2)

            $i++
        }
    }
    catch {
        Write-Warning "Failed to download or display weather icons: $($_.Exception.Message)"
    }

    $WeatherArry = New-Object System.Collections.ArrayList
    $WeatherArry.AddRange(@($script:ReturnedForecast))

    $WeatherArryTwo = New-Object System.Collections.ArrayList
    $WeatherArryThree = New-Object System.Collections.ArrayList
    $WeatherArryThree.AddRange(@($script:ReturnedForecastTwo))

    $WeatherArryFour = New-Object System.Collections.ArrayList
    $WeatherArryFour.AddRange(@($script:CurrentWeather))

    $WeatherDataOutput.DataSource = $WeatherArry
    $WeatherDataOutput.AutoSize = $true
    $WeatherDataOutput.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
    $WeatherDataOutput.AutoSizeRowsMode = [System.Windows.Forms.DataGridViewAutoSizeRowsMode]::AllCells
    $WeatherDataOutput.ColumnHeadersHeightSizeMode = [System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::AutoSize

    $WeatherDataOutputTwo.DataSource = $WeatherArryFour
    $WeatherDataOutputTwo.AutoSize = $true
    $WeatherDataOutputTwo.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
    $WeatherDataOutputTwo.AutoSizeRowsMode = [System.Windows.Forms.DataGridViewAutoSizeRowsMode]::AllCells
    $WeatherDataOutputTwo.ColumnHeadersHeightSizeMode = [System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::AutoSize

    $WeatherDataOutputThree.DataSource = $WeatherArryThree
    $WeatherDataOutputThree.AutoSize = $true
    $WeatherDataOutputThree.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
    $WeatherDataOutputThree.AutoSizeRowsMode = [System.Windows.Forms.DataGridViewAutoSizeRowsMode]::AllCells
    $WeatherDataOutputThree.MaximumSize = New-Object System.Drawing.Size(1000, 1000) # Set maximum size
    $WeatherDataOutputThree.ScrollBars = "Both"
    $WeatherDataOutputThree.ColumnHeadersHeightSizeMode = [System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::AutoSize

    $DataForm.Controls.Add($WeatherDataOutput)
    $DataForm.Controls.Add($WeatherDataOutputTwo)
    $DataForm.Controls.Add($WeatherDataOutputThree)
    $WeatherDataOutputTwo.PerformLayout()

    $DataForm.Topmost = $True
    $DataForm.Add_Shown({$DataForm.Activate()})
    [void]$DataForm.ShowDialog()
}
#endregion FUNCTIONS

#region FORM CREATION
<#Form Creation#>
$MainMenu = New-Object System.Windows.Forms.Form
$MainMenu.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$script:CurrentLocation\cloud.ico") #.\cloud.ico for exe, use full path for testings
$MainMenu.Font = New-Object Drawing.Font("Segoe UI", 12, [Drawing.FontStyle]::Regular)
$MainMenu.Size = New-Object System.Drawing.Size(470, 200)
$MainMenu.AutoSize = $true
$MainMenu.StartPosition = "CenterScreen"
$MainMenu.Text = "No BS Weather App"
$MainMenu.BackColor = $backgroundColor

<#Label Creation#>
$MainMenuLabel = New-Object Windows.Forms.Label
$MainMenuLabel.Text = "Enter City and Country. EX: Cleveland, USA"
$MainMenuLabel.Location = New-Object System.Drawing.Size(30, 20)
$MainMenuLabel.Size = New-Object System.Drawing.Size(340, 20)
$MainMenuLabel.ForeColor = $textColor

<#Textbox #>
$MainMenuTxtBox = New-Object Windows.Forms.TextBox
$MainMenuTxtBox.AutoSize = $true
$MainMenuTxtBox.Padding = New-Object -TypeName System.Windows.Forms.Padding -ArgumentList (10, 10, 10, 10)
$MainMenuTxtBox.Location = New-Object System.Drawing.Size(30, 40)
$MainMenuTxtBox.Size = New-Object System.Drawing.Size(260, 20)

<#Button Creation#>
$MainMenuBttn = New-Object Windows.Forms.Button
$MainMenuBttn.Location = New-Object System.Drawing.Size($MainMenuTxtBox.Right, $MainMenuTxtBox.Top)
$MainMenuBttn.Size = New-Object System.Drawing.Size(75, 20)
$MainMenuBttn.Text = "Get Forecast"
$MainMenuBttn.AutoSize = $true
$MainMenuBttn.BackColor = $accentColor
$MainMenuBttn.ForeColor = [System.Drawing.Color]::White
$MainMenuBttn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat # Flat style for a modern look
$MainMenuBttn.Add_Click({
        Set-Variable -Name CityFromTxtBox -Value "$($MainMenuTxtBox.Text)" -Force
        Get-WeatherData -CitySelected "$CityFromTxtBox"
    })

#FOR NEXT DEV, FIGURE OUT HOW TO RUN IT AS A JOB OR RUNSPACE FOR THE SAVE BUTTON TO AUTO UPDATE THE SAVED CITIES WITHOUT CLOSING THE APP

$SaveBttn = New-Object Windows.Forms.Button
$SaveBttn.Size = New-Object System.Drawing.Size(75, 20)
$SaveBttn.Text = "Save City"
$SaveBttn.AutoSize = $true
$SaveBttn.BackColor = $accentColor
$SaveBttn.ForeColor = [System.Drawing.Color]::White
$SaveBttn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat

# Calculate the location of SaveBttn
$SaveBttnLocationX = $MainMenuBttn.Location.X
$SaveBttnLocationY = [System.Math]::Max($MainMenuBttn.Location.Y, $MainMenuBttn.Bottom) + 10

$SaveBttn.Location = New-Object System.Drawing.Point($SaveBttnLocationX, $SaveBttnLocationY)
$SaveBttn.Add_Click({
        $CurrentValues = $script:RegKey.SavedCities
        $AllValues = $CurrentValues + "$($MainMenuTxtBox.Text)\0"
        Set-ItemProperty -Path "HKCU:\Software\NoBSWeatherApp" -Name "SavedCities" -Value "$($AllValues)" -Type MultiString
    })
if ($script:RegKey) {
    $i = 0
    $SavedCitiesArray = $script:RegKey.SavedCities.Trim()
    $SavedCitiesArray = $SavedCitiesArray.Split("\0")
    $SavedCitiesArray = $SavedCitiesArray | Where-Object {
        $_.Trim() -ne ""
    }
    $SavedCitiesArray = $SavedCitiesArray.Trim()
    $script:SaveBttnLocationX = $SaveBttn.Location.X
    $script:SaveBttnBottom = $SaveBttn.Bottom
    $LastSavedButtonName = $null # Initialize the variable
    foreach ($city in $SavedCitiesArray) {
        $SaveBttnLocationForNewBttnX = $script:SaveBttnLocationX
        if ($LastSavedButtonName) {
            # If there is a last button, position the new button below it
            $SaveBttnLocationForNewBttnY = $LastSavedButtonName.Bottom + 10
        } else {
            # If this is the first button, position it below the Save button
            $SaveBttnLocationForNewBttnY = $script:SaveBttnBottom + 10
        }
        $NewSavedCityButton = New-Object Windows.Forms.Button
        $NewSavedCityButton.Location = New-Object System.Drawing.Point($SaveBttnLocationForNewBttnX, $SaveBttnLocationForNewBttnY)
        $NewSavedCityButton.Size = New-Object System.Drawing.Size(75, 20)
        $NewSavedCityButton.Text = "$City"
        $NewSavedCityButton.AutoSize = $true
        $NewSavedCityButton.BackColor = $accentColor
        $NewSavedCityButton.ForeColor = [System.Drawing.Color]::White
        $NewSavedCityButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $NewSavedCityButton.Add_Click({
                Set-Variable -Name CityFromTxtBox -Value "$($NewSavedCityButton.Text)" -Force
                Get-WeatherData -CitySelected "$CityFromTxtBox"
            })
        $MainMenu.Controls.Add($NewSavedCityButton)
        $LastSavedButtonName = $NewSavedCityButton # Update the last button
    }
}

<#Add Controls and Show Form#>
$MainMenu.Controls.Add($MainMenuBttn)
$MainMenu.Controls.Add($SaveBttn)
$MainMenu.Controls.Add($MainMenuTxtBox)
$MainMenu.Controls.Add($MainMenuLabel)
$MainMenu.Topmost = $True
$MainMenu.Add_Shown({
        $MainMenu.Activate()
    })
[void]$MainMenu.ShowDialog()
#endregion FORM CREATION