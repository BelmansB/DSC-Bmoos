Configuration bmoos_dsc
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
        $SafeModePassword,

        $StartPageURL = 'C:\inetpub\wwwroot\index.html'
    )
    Import-DscResource -ModuleName PSDscResources  
    Import-DscResource -Module NetworkingDsc -ModuleVersion 7.4.0.0
    Import-DscResource -Module ComputerManagementDsc -ModuleVersion 7.1.0.0
    Import-DscResource -ModuleName ActiveDirectoryDsc -ModuleVersion 5.0.0
    Import-DscResource -Module XDhcpServer -ModuleVersion 2.0.0.0
    Import-DscResource -ModuleName xSMBShare
    Import-DSCResource -ModuleName xInternetExplorerHomePage 
       
    Node $allnodes.nodename
    {
	    ##Statisch IP adres##
        IPAddress NewIPv4Address
        {
            IPAddress      = '192.168.1.10'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
        }
       
        ##Default Gateway##
        DefaultGatewayAddress SetDefaultGateway
        {
            Address        = '192.168.1.1'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            DependsOn      = '[IPAddress]NewIPv4Address'
        }       
        ##DNS instellen ##
        DnsServerAddress DnsServerAddress
        {
            Address        = '192.168.1.10'
            InterfaceAlias = 'Ethernet'
            AddressFamily  = 'IPv4'
            DependsOn      = '[DefaultGatewayAddress]SetDefaultGateway'
        }
    	#PC Hernoemen#
        Computer NewName
        {
            Name       = 'DC01'
            Credential = $Credential
            DependsOn  = '[IPAddress]NewIPv4Address'
        }

        ##ADDomain NewForest CONFIGURATION##
        ##Komt van https://github.com/dsccommunity/ActiveDirectoryDsc/blob/master/source/Examples/Resources/ADDomain/1-ADDomain_NewForest_Config.ps1##
        WindowsFeature 'ADDS'
        {
            Name   = 'AD-Domain-Services'
            Ensure = 'Present'
        }
       
        WindowsFeature 'RSAT'
        {
            Name   = 'RSAT-AD-PowerShell'
            Ensure = 'Present'
        }

        ADDomain 'bmoos.local'
        {
            DomainName                    = 'bmoos.local'
            Credential                    = $Credential
            SafemodeAdministratorPassword = $SafeModePassword
            ForestMode                    = 'WinThreshold'
            DependsOn                     = '[Computer]NewName'
        }

        ### xDhcpServer 
        ### https://github.com/dsccommunity/xDhcpServer
        WindowsFeature “DHCP-Server”
        {
            Name      = “DHCP”
            Ensure    = “Present”
            DependsOn = '[ADDomain]bmoos.local'
        }

        WindowsFeature RSATDHCP
        {
            Name      = "RSAT-DHCP"
            Ensure    = "Present"
            DependsOn = '[WindowsFeature]DHCP-server'
        }
               
        xDhcpServerScope "Scope"
        {
            Ensure = 'Present'
            ScopeID = '192.168.1.0'
            IPStartRange = '192.168.1.20' 
            IPEndRange = '192.168.1.200'
            Name = 'IPv4ScopeBmoos' 
            SubnetMask = '255.255.255.0' 
            LeaseDuration = '00:08:00' 
            State = 'Active' 
            AddressFamily = 'IPv4'
            DependsOn     = "[WindowsFeature]DHCP-server"
        }

        XDhcpServerAuthorization Authorization
        {
            Ensure        = “Present”
            IPAddress     = "192.168.1.10"
        }

        ### IIS
        WindowsFeature WebServer
        {
            Ensure = "Present"
            Name   = "Web-Server"
	    DependsOn     = "[WindowsFeature]RSATDHCP"
        }

        ADUser 'bmoos\User1'
        {
            Ensure     = 'Present'
            UserName   = 'User1'
            Password   = $Password
            DomainName = 'bmoos.local'
            Path       = 'CN=Users,DC=bmoos,DC=local'
        }
        ADUser 'bmoos\User2'
        {
            Ensure     = 'Present'
            UserName   = 'User2'
            Password   = $Password
            DomainName = 'bmoos.local'
            Path       = 'CN=Users,DC=bmoos,DC=local'
        }
        ADUser 'bmoos\User3'
        {
            Ensure     = 'Present'
            UserName   = 'User3'
            Password   = $Password
            DomainName = 'bmoos.local'
            Path       = 'CN=Users,DC=bmoos,DC=local'
        }
        ADUser 'bmoos\User4'
        {
            Ensure     = 'Present'
            UserName   = 'User4'
            Password   = $Password
            DomainName = 'bmoos.local'
            Path       = 'CN=Users,DC=bmoos,DC=local'
        }
        ADUser 'bmoos\User5'
        {
            Ensure     = 'Present'
            UserName   = 'User5'
            Password   = $Password
            DomainName = 'bmoos.local'
            Path       = 'CN=Users,DC=bmoos,DC=local'
        }

        ADGroup 'FileServer_R'
        {
            Description = 'Directory Read Rights for Fileserver'
            GroupName = 'FileServer_R'
            GroupScope = 'Global'
            Ensure = 'Present'
            Members = 'User1', 'User2', 'User3', 'User4', 'User5'
        }
        File HR
        {
            DestinationPath = 'C:\Fileserver\HR'
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn= '[WindowsFeature]WebServer'
        }
        xSMBShare HR
        {
            Name = 'HR'
            Path = 'C:\Fileserver\HR'
            FullAccess = 'administrator'
            ReadAccess = 'FileServer_R'
            FolderEnumerationMode = 'AccessBased'
            Ensure = 'Present'
            DependsOn = '[File]HR'
        }
        File Marketing
        {
            DestinationPath = 'C:\Fileserver\Marketing'
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn= '[File]HR'
        }
        xSMBShare Marketing
        {
            Name = 'Marketing'
            Path = 'C:\Fileserver\Marketing'
            FullAccess = 'administrator'
            ReadAccess = 'FileServer_R'
            FolderEnumerationMode = 'AccessBased'
            Ensure = 'Present'
            DependsOn = '[File]Marketing'
        }
        File Production
        {
            DestinationPath = 'C:\Fileserver\Production'
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn= '[File]Marketing'
        }
        xSMBShare Production
        {
            Name = 'Production'
            Path = 'C:\Fileserver\Production'
            FullAccess = 'administrator'
            ReadAccess = 'FileServer_R'
            FolderEnumerationMode = 'AccessBased'
            Ensure = 'Present'
            DependsOn = '[File]Production'
        }
        File Research
        {
            DestinationPath = 'C:\Fileserver\Research'
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn= '[WindowsFeature]WebServer'
        }
        xSMBShare Research
        {
            Name = 'Research'
            Path = 'C:\Fileserver\Research'
            FullAccess = 'administrator'
            ReadAccess = 'FileServer_R'
            FolderEnumerationMode = 'AccessBased'
            Ensure = 'Present'
            DependsOn = '[File]Research'
        }
        File Logistics
        {
            DestinationPath = 'C:\Fileserver\Logistics'
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn= '[WindowsFeature]WebServer'
        }
        xSMBShare Logistics
        {
            Name = 'Logistics'
            Path = 'C:\Fileserver\Logistics'
            FullAccess = 'administrator'
            ReadAccess = 'FileServer_R'
            FolderEnumerationMode = 'AccessBased'
            Ensure = 'Present'
            DependsOn = '[File]Logistics'
        }
        File Website
        {
            DestinationPath = 'c:\inetpub\wwwroot\web'
            Type = 'Directory'
            Ensure = 'Present'
            DependsOn= '[WindowsFeature]WebServer'
        }
        Firewall EnableBuiltInFirewallRule
        {
            Name = 'IIS-WebServerRole-HTTP-In-TCP'
            Ensure = 'Present'
            Enabled = 'True'
            DependsOn ='[File]Website'
        }
        File WebsiteContent 
        {
            Ensure = 'Present'
            SourcePath = 'C:\test\index.html'
            DestinationPath = 'C:\inetpub\wwwroot\'
            DependsOn='[File]Website'
        }
        xInternetExplorerHomePage IEHomePage 
        { 
          StartPage = $StartPageURL 
          Ensure = 'Present'
          DependsOn='[WindowsFeature]WebServer'
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

Bmoos_dsc -ConfigurationData $cd -StartPageURL "http://bmoos"
Start-DscConfiguration .\bmoos_dsc -Verbose -Wait -Force