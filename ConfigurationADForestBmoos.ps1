Configuration ADDomain_NewForest_Config
{
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        $SafeModePassword
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ActiveDirectoryDsc

    node $allnodes.nodename
    {
        WindowsFeature 'ADDS'
        {
            Name   = 'AD-Domain-Services'
            Ensure = 'Present'
        }
        WindowsFeature 'RSAT'
        {
            Name   = 'RSAT-AD-PowerShell'
            Ensure = 'Present'
        }

        ADDomain 'bmoos.com'
        {
            DomainName                    = 'bmoos.com'
            Credential                    = $Credential
            SafemodeAdministratorPassword = $SafeModePassword
            ForestMode                    = 'WinThreshold'
        }
    }
}
$cd = @{
    AllNodes = @(    
        @{  
            NodeName = "localhost"
            PsDscAllowPlainTextPassword = $true
        }
    ) 
}

ADDomain_NewForest_Config -ConfigurationData $cd
Start-dscconfiguration .\ADDomain_NewForest_Config -wait -verbose