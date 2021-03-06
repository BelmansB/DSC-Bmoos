[DSCLocalConfigurationManager()]
configuration LCMConfig
{
    Node localhost
    {
        Settings
        {
            RefreshMode = 'Push'
            RebootNodeIfNeeded = $True
            RefreshFrequencyMins =             30
            ConfigurationMode = 'ApplyAndAutoCorrect'
        }
    }
}
lcmconfig
Set-DscLocalConfigurationManager .\LCMConfig