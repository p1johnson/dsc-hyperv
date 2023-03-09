Configuration HyperVServer {

    Param ()

    #Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
    Import-DscResource -ModuleName PSDesiredStateConfiguration, GPRegistryPolicyDsc, NetworkingDsc, ComputerManagementDsc

    $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)

    Node 'localhost'

    {
        LocalConfigurationManager
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
        
        RegistryPolicyFile DisableServerManagerStart {
            Key        = 'Software\Policies\Microsoft\Windows\Server\ServerManager'
            TargetType = 'ComputerConfiguration'
            ValueName  = 'DoNotOpenAtLogon'
            ValueData  = 1
            ValueType  = 'DWORD'
        }

        RegistryPolicyFile DisableNewNetworkPrompt {
            Key        = 'System\CurrentControlSet\Control\Network\NewNetworkWindowOff'
            TargetType = 'ComputerConfiguration'
            ValueName = '(Default)'
            ValueType = 'String'
            Ensure = 'Present'
        }

        RefreshRegistryPolicy RefreshPolicy {
            IsSingleInstance = 'Yes'
            DependsOn        = '[RegistryPolicyFile]DisableServerManagerStart','[RegistryPolicyFile]DisableNewNetworkPrompt'
        }

        NetConnectionProfile SetPrivateInterface
        {
            InterfaceAlias   = $InterfaceAlias
            NetworkCategory  = 'Private'
        }
        
        FirewallProfile ConfigurePrivateFirewallProfile
        {
            Name = 'Private'
            Enabled = 'False'
        }

        WindowsFeature Hyper-V
        {
            Name = 'Hyper-V'
            Ensure = 'Present'
            DependsOn = '[NetConnectionProfile]SetPrivateInterface', '[WindowsFeature]Hyper-V-Tools', '[WindowsFeature]Hyper-V-Powershell', '[WindowsFeature]DHCP', '[WindowsFeature]RSAT-DHCP'
        }

        WindowsFeature Hyper-V-Tools
        {
            Name = 'Hyper-V-Tools'
            Ensure = 'Present'
        }

        WindowsFeature Hyper-V-Powershell
        {
            Name = 'Hyper-V-Powershell'
            Ensure = 'Present'
        }

        WindowsFeature DHCP
        {
            Name = 'DHCP'
            Ensure = 'Present'
        }

        WindowsFeature RSAT-DHCP
        {
            Name = 'RSAT-DHCP'
            Ensure = 'Present'
        }

        PendingReboot Reboot
        {
            Name = 'Reboot'
            DependsOn = '[WindowsFeature]Hyper-V'
        }
    }

}