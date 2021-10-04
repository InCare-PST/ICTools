function update-EsxiHost {
    [cmdletbinding()]
        param(

            [string]$server


        )

Begin{

    $creds = Get-Credential -Message "Please Enter EXSi Host Credentials"


}
process{}
end{}
    

Connect-VIServer -Credential $creds -Server $servername
Get-VMHost
}


