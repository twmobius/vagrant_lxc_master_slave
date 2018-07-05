class role::lxc::master {
    class { 'rsync::server':
        use_xinetd => false,
    }

    class { 'lxc':
        lxc_networking_type           => 'veth',
        lxc_networking_nat_enable     => false,
        lxc_networking_flags          => 'up',
        lxc_networking_nat_bridge     => 'lxcbr0',
        lxc_networking_nat_address    => '10.1.1.1',
        lxc_networking_nat_mask       => '255.255.255.0',
        lxc_networking_nat_network    => '10.1.1.0/24',
        lxc_cgmanager_service_ensure  => false,
        lxc_cgmanager_service_enabled => false,
    }

    lxc { 'ubuntu_test':
        ensure          => 'present',
        state           => 'running',
        autostart       => 'true',
        template        => 'ubuntu',
        storage_backend => 'dir',
    }

    rsync::server::module { 'lxc':
        path => '/var/lib/lxc',
    }
}
