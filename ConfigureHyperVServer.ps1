Configuration HyperVServer {

    Param ()

    #Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
    Import-DscResource -ModuleName PSDesiredStateConfiguration, GPRegistryPolicyDsc, NetworkingDsc, ComputerManagementDsc

    #$Interface = Get-NetAdapter | Where-Object Name -Like "Ethernet*" | Select-Object -First 1
    #$InterfaceAlias = $($Interface.Name)

    $switchName = "InternalNAT"
    $natPrefix = "192.168.0.0/24"
    $natAddress = "192.168.0.1"
    $natPrefixLength = 24
    $scopeStart = "192.168.0.50"
    $scopeEnd = "192.168.0.100"
    $scopeMask = "255.255.255.0"
    $dnsServer = "168.63.129.16"

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

        #NetConnectionProfile SetPrivateInterface
        #{
        #    InterfaceAlias   = $InterfaceAlias
        #    NetworkCategory  = 'Private'
        #}
        
        #FirewallProfile ConfigurePrivateFirewallProfile
        #{
        #    Name = 'Private'
        #    Enabled = 'False'
        #}

        WindowsFeature Hyper-V
        {
            Name = 'Hyper-V'
            Ensure = 'Present'
            DependsOn = '[WindowsFeature]Hyper-V-Tools', '[WindowsFeature]Hyper-V-Powershell', '[WindowsFeature]DHCP', '[WindowsFeature]RSAT-DHCP'
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

        Script ConfigureHyperVNetwork
        {
            GetScript = {
                $returnValue = (Get-NetAdapter | Where-Object {$_.name -like "*$using:switchName)"})
                return $returnValue
            }
            TestScript = {
                if (Get-NetAdapter | Where-Object {$_.name -like "*$using:switchName)"})
                {
                    return $true
                }
                else 
                {
                    return $false
                }
            }
            SetScript = {
                New-VMSwitch -Name $using:switchName -SwitchType Internal
                New-NetNat -Name $using:switchName -InternalIPInterfaceAddressPrefix $using:natPrefix
                $ifIndex = (Get-NetAdapter | Where-Object {$_.name -like "*$using:switchName)"}).ifIndex
                New-NetIPAddress -IPAddress $using:natAddress -InterfaceIndex $ifIndex -PrefixLength $using:natPrefixLength
                Add-DhcpServerV4Scope -Name "DHCP-$using:switchName" -StartRange $using:scopeStart -EndRange $using:scopeEnd -SubnetMask $using:scopeMask
                Set-DhcpServerV4OptionValue -Router $using:natAddress -DnsServer $using:dnsServer
                Restart-Service -Name dhcpserver
            }
            DependsOn = '[PendingReboot]Reboot'
        }
    }

}