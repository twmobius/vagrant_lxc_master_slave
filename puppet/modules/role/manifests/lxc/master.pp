class role::lxc::master {

    $private_interface = 'enp0s8' # TODO: Actually find this

    class { 'netplan':
        config_file   => '/etc/netplan/01-custom.yaml',
        ethernets     => {
            $private_interface => {
                'dhcp4' => false,
            },
        },
        bridges       => {
            'br0' => {
                'addresses'  => ['10.1.1.1/24'],
                'interfaces' => [$private_interface], # TODO: Find the correct interface for
            },
        },
        netplan_apply => true,
    }

    class { 'rsync::server':
        use_xinetd => false,
    }
    rsync::server::module { 'lxc':
        path => '/var/lib/lxc',
    }

    class { 'lxc':
        lxc_networking_device_link    => 'br0',
        lxc_networking_type           => 'veth',
        lxc_networking_flags          => 'up',
        lxc_networking_nat_enable     => false,
        lxc_cgmanager_service_ensure  => false,
        lxc_cgmanager_service_enabled => false,
    }

    $lxc_defaults = {
        ensure          => 'present',
        template        => 'ubuntu',
        storage_backend => 'dir',
    }
    $lxcs = {
        'db-1' => { state => 'running', autostart => true, },
        'db-2' => { state => 'stopped', autostart => false, },
        'web-1' => { state => 'running', autostart => true, },
        'web-2' => { state => 'stopped', autostart => false, },
        'ad-1' => { state => 'running', autostart => true, },
        'dns-1' => { state => 'running', autostart => true, },
        'queue-1' => { state => 'running', autostart => true, },
        'search-1' => { state => 'running', autostart => true, },
        'live-1' => { state => 'running', autostart => true, },
        'logs-1' => { state => 'running', autostart => true, },
        'vpn-1' => { state => 'running', autostart => true, },
        'mail-1' => { state => 'running', autostart => true, },
        'mc-1' => { state => 'running', autostart => true, },
        'various-1' => { state => 'running', autostart => true, },
        'redis-1' => { state => 'running', autostart => true, },
        'zabbix-1' => { state => 'running', autostart => true, },
    }
    create_resources(lxc, $lxcs, $lxc_defaults)

    $lxc_interface_defaults = {
        device_name => 'eth0',
        ensure      => present,
        index       => 0,
        link        => 'br0',
        type        => 'veth',
        restart     => true,
    }
    $lxc_interfaces = {
        'db-1' => { container => 'db-1', ipv4 => ['10.1.1.10/24'], },
        'db-2' => { container => 'db-2', ipv4 => ['10.1.1.11/24'], },
        'web-1' => { container => 'web-1', ipv4 => ['10.1.1.20/24'], },
        'web-2' => { container => 'web-2', ipv4 => ['10.1.1.21/24'], },
        'ad-1' => { container => 'ad-1', ipv4 => ['10.1.1.30/24'], },
        'dns-1' => { container => 'dns-1', type => 'none' }, # This is on the host namespace
        'queue-1' => { container => 'queue-1', ipv4 => ['10.1.1.40/24'], },
        'search-1' => { container => 'search-1', ipv4 => ['10.1.1.50/24'], },
        'live-1' => { container => 'live-1', ipv4 => ['10.1.1.60/24'], },
        'logs-1' => { container => 'logs-1', ipv4 => ['10.1.1.70/24'], },
        'vpn-1'  => { container => 'vpn-1', type => 'none' }, # On the host namespace
        'mail-1' => { container => 'mail-1', ipv4 => ['10.1.1.80/24'], },
        'mc-1' => { container => 'mc-1', ipv4 => ['10.1.1.90/24'], },
        'various-1' => { container => 'various-1', ipv4 => ['10.1.1.100/24'], },
        'redis-1' => { container => 'redis-1', ipv4 => ['10.1.1.110/24'], },
        'zabbix-1' => { container => 'redis-1', type => 'none' }, # On the host namespace
    }
    create_resources(lxc_interface, $lxc_interfaces, $lxc_interface_defaults)
}
