Function Popup-Reboot{
    Add-Type -AssemblyName PresentationCore,PresentationFramework
    $ButtonType = [System.Windows.MessageBoxButton]::YesNo
    $MessageIcon = [System.Windows.MessageBoxImage]::Exclamation
    $MessageBody = "This script requires a reboot, would you like to reboot now?"
    $MessageTitle = "Confirm Reboot"

    $Result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
    switch ($Result){
    "Yes" {
            write-host -ForegroundColor Green"Windows will restart in 30 seconds"
            start-sleep 30
            restart-computer -force
     }
    "No" {
    write-host -ForegroundColor Red "Please restart your computer later"
    Restart-Service NlaSvc -Force

    }
  }
}
