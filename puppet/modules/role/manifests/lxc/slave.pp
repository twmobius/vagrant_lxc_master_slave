class role::lxc::slave(
    $master,
){
    class { 'rsync::server':
        use_xinetd => false,
    }

    rsync::get { 'lxc':
        source => "rsync://${master}/lxc/",
    }

    class { 'lxc':
        lxc_networking_type           => 'veth',
        lxc_networking_nat_enable     => false,
        lxc_networking_flags          => 'up',
        lxc_networking_nat_bridge     => 'lxcbr0',
        lxc_networking_nat_address    => '10.1.1.2',
        lxc_networking_nat_mask       => '255.255.255.0',
        lxc_networking_nat_network    => '10.1.1.0/24',
        lxc_cgmanager_service_ensure  => false,
        lxc_cgmanager_service_enabled => false,
    }

    $lxc_defaults = {
        ensure          => 'present',
        template        => 'ubuntu',
        storage_backend => 'dir',
        require         => Rsync::Get['lxc'],
    }
    $lxcs = {
        'db-1' => { state => 'stopped', autostart => false, },
        'db-2' => { state => 'running', autostart => true, },
        'web-1' => { state => 'stopped', autostart => false, },
        'web-2' => { state => 'running', autostart => true, },
        'ad-1' => { state => 'stopped', autostart => false, },
        'dns-1' => { state => 'stopped', autostart => false, },
        'queue-1' => { state => 'stopped', autostart => false, },
        'search-1' => { state => 'stopped', autostart => false, },
        'live-1' => { state => 'stopped', autostart => false, },
        'logs-1' => { state => 'stopped', autostart => false, },
        'vpn-1' => { state => 'stopped', autostart => false, },
        'mail-1' => { state => 'stopped', autostart => false, },
        'mc-1' => { state => 'stopped', autostart => false, },
        'various-1' => { state => 'stopped', autostart => false, },
        'redis-1' => { state => 'stopped', autostart => false, },
        'zabbix-1' => { state => 'stopped', autostart => false, },
    }
    create_resources(lxc, $lxcs, $lxc_defaults)

    $lxc_interface_defaults = {
        device_name => 'eth0',
        ensure      => present,
        index       => 0,
        link        => 'lxcbr0',
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
