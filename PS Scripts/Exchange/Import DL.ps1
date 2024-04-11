Import-Csv "C:\scripts\ExportDGs.csv"| ForEach-Object{
    $Name =$_.name
    $DisplayName=$_.DisplayName
    $Alias =$_.Alias
    $PrimarySmtpAddress=$_.PrimarySmtpAddress
    $GroupType =$_.GroupType
    $RequireSenderAuthenticationEnabled=[System.Convert]::ToBoolean($_.RequireSenderAuthenticationEnabled)
    $ManagedBy=$_.ManagedBy -split ';'
    $MemberJoinRestriction=$_.MemberJoinRestriction
    $MemberDepartRestriction=$_.MemberDepartRestriction

    if ($GroupType -eq "MailUniversalSecurityGroup")
        {
        if ($ManagedBy)
            {
            New-DistributionGroup -Type security -Name $Name -DisplayName $DisplayName -Alias $Alias -PrimarySmtpAddress $PrimarySmtpAddress -RequireSenderAuthenticationEnabled $RequireSenderAuthenticationEnabled -MemberJoinRestriction $MemberJoinRestriction -MemberDepartRestriction $MemberDepartRestriction -ManagedBy $ManagedBy
            Start-Sleep -s 10
            Set-DistributionGroup -Identity $Name
            }
            Else
            {
            New-DistributionGroup -Type security -Name $Name -DisplayName $DisplayName -Alias $Alias -PrimarySmtpAddress $PrimarySmtpAddress -RequireSenderAuthenticationEnabled $RequireSenderAuthenticationEnabled -MemberJoinRestriction $MemberJoinRestriction -MemberDepartRestriction $MemberDepartRestriction
            Start-Sleep -s 10
            Set-DistributionGroup -Identity $Name
            }
        }
 
    if ($GroupType -eq "MailUniversalDistributionGroup")
        {
        if ($ManagedBy)
            {
            New-DistributionGroup -Name $Name -DisplayName $DisplayName -Alias $Alias -PrimarySmtpAddress $PrimarySmtpAddress -RequireSenderAuthenticationEnabled $RequireSenderAuthenticationEnabled -MemberJoinRestriction $MemberJoinRestriction -MemberDepartRestriction $MemberDepartRestriction -ManagedBy $ManagedBy
            Start-Sleep -s 10
            Set-DistributionGroup -Identity $Name
            }
            Else
            {
            New-DistributionGroup -Name $Name -DisplayName $DisplayName -Alias $Alias -PrimarySmtpAddress $PrimarySmtpAddress -RequireSenderAuthenticationEnabled $RequireSenderAuthenticationEnabled -MemberJoinRestriction $MemberJoinRestriction -MemberDepartRestriction $MemberDepartRestriction
            Start-Sleep -s 10
            Set-DistributionGroup -Identity $Name
	    }
	}
}