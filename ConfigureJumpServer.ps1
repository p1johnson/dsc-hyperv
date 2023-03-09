Configuration JumpServer {

    Param ()

    #Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
    Import-DscResource -ModuleName PSDesiredStateConfiguration, cChoco, GPRegistryPolicyDsc, NetworkingDsc

    $Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    $InterfaceAlias = $($Interface.Name)

    Node 'localhost'

    {
       cChocoInstaller InstallChoco {
            InstallDir = "C:\Choco"
        }

        cChocoPackageInstaller InstallFirefox {
            Name      = 'firefox'
            Ensure    = 'Present'
            Params    = '/NoAutoUpdate'
            DependsOn = '[cChocoInstaller]InstallChoco'
        }

        cChocoPackageInstaller InstallPutty {
            Name      = 'putty.install'
            Ensure    = 'Present'
            DependsOn = '[cChocoInstaller]InstallChoco'
        }

        cChocoPackageInstaller InstallFileZilla {
            Name      = 'filezilla'
            Ensure    = 'Present'
            DependsOn = '[cChocoInstaller]InstallChoco'
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

        WindowsFeature RSAT
        {
            Name = 'RSAT'
            Ensure = 'Present'
            IncludeAllSubFeature = $true
        }
    }

}