[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node localhost
    {
        Settings
        {
            RefreshMode = 'Push'
            RebootNodeIfNeeded = $True
            RefreshFrequencyMins =             15
            ConfigurationMode = 'ApplyAndAutoCorrect'
        }
    }
}
lcmconfig
Set-DscLocalConfigurationManager .\LCMConfig