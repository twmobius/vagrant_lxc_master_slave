# Role lxc
class role::lxc (
    $public_interface = 'enp0s3',
    $private_interface = 'enp0s8',
    $lxc_bridge = 'br0',
    $bridge_ip = '192.168.1.1',
    $bridge_netmask = '24',
    $lxc_path = '/var/lib/lxc',
    $master = false,
    $rsync_master = undef,
    $rsync_allow = undef,
){

    # Network configuration
    class { 'netplan':
        config_file   => '/etc/netplan/01-custom.yaml',
        ethernets     => {
            $private_interface => {
                'dhcp4' => false,
            },
        },
        bridges       => {
            $lxc_bridge => {
                'addresses'  => ["${bridge_ip}/${bridge_netmask}"],
                'interfaces' => [$private_interface],
            },
        },
        netplan_apply => true,
    }

    # Firewalling host configuration
    class { 'firehol':
        ensure => true,
    }

    firehol::variable { 'FIREHOL_ENABLE_SPINNER':
      variable => 'FIREHOL_ENABLE_SPINNER',
      value    => '1'
    }

    firehol::variable { 'FIREHOL_FAST_ACTIVATION':
      variable => 'FIREHOL_FAST_ACTIVATION',
      value    => '1'
    }

    firehol::variable { 'FIREHOL_LOG_MODE':
      variable => 'FIREHOL_LOG_MODE',
      value    => 'NFLOG'
    }

    firehol::variable { 'FIREHOL_LOG_FREQUENCY':
      variable => 'FIREHOL_LOG_FREQUENCY',
      value    => '10/second'
    }

    firehol::variable { 'FIREHOL_LOG_BURST':
      variable => 'FIREHOL_LOG_BURST',
      value    => '60'
    }

    firehol::variable { 'DEFAULT_CLIENT_PORTS':
      variable => 'DEFAULT_CLIENT_PORTS',
      value    => '0:65535'
    }

    firehol::variable { 'FIREHOL_DROP_ORPHAN_TCP_ACK_FIN':
      variable => 'FIREHOL_DROP_ORPHAN_TCP_ACK_FIN',
      value    => '1'
    }

    firehol::dnat4 { 'http':
        interface => $public_interface,
        backend   => '10.1.1.20',
        matches   => 'proto tcp dport "80 443"',
    }

    firehol::dnat4 { 'vpn-tcp':
        interface => $public_interface,
        backend   => '10.1.1.100',
        matches   => 'proto tcp dport 1194',
    }

    firehol::dnat4 { 'vpn-udp':
        interface => $public_interface,
        backend   => '10.1.1.100',
        matches   => 'proto udp dport 1194',
    }

    firehol::dnat4 { 'mail':
        interface => $public_interface,
        backend   => '10.1.1.110',
        matches   => 'proto tcp dport "25 465 110 143 993 995 587"',
    }

    firehol::dnat4 { 'ftp':
        interface => $public_interface,
        backend   => '10.1.1.20',
        matches   => 'proto tcp dport "20 21"',
    }

    firehol::ipv6 { 'ipv6': }

    firehol::interface { $public_interface: interface_name => 'public', }

    firehol::interface { $lxc_bridge: interface_name => 'private', }

    firehol::router { 'lxc_router':
        inface  => $lxc_bridge,
        outface => $public_interface,
    }

    firehol::service { 'sshalt': server => 'tcp/2222', }

    firehol::rule { 'public-server':
        interface => $public_interface,
        direction => 'server',
        service   => ['icmp', 'smtp', 'smtps', 'imap', 'imaps', 'sshalt', 'http', 'https', 'openvpn', 'ftp'],
    }

    firehol::rule { 'public-client':
        interface => $public_interface,
        direction => 'client',
        service   => 'all',
    }

    firehol::rule { 'bridge-server':
        interface => $lxc_bridge,
        direction => 'server',
        service   => ['icmp', 'sshalt', 'http', 'https'],
    }

    firehol::rule { 'bridge-client':
        interface => $lxc_bridge,
        direction => 'client',
        service   => 'all',
    }

    firehol::router_rule { 'masquerade':
        router    => 'lxc_router',
        direction => '',
        action    => 'masquerade',
        service   => '',
    }

    firehol::router_rule { 'route_all':
        router    => 'lxc_router',
        direction => 'route',
        action    => 'accept',
        service   => 'all',
    }

    if $rsync_allow {
        firehol::rule { 'rsync-allow':
            interface => $lxc_bridge,
            direction => 'server',
            service   => 'rsync',
            src       => $rsync_allow,
        }
    }

    class { 'rsync::server':
        use_xinetd => false,
    }

    # LXC configuration, dependent on master/slave

    class { 'lxc':
        lxc_networking_device_link    => $lxc_bridge,
        lxc_networking_type           => 'veth',
        lxc_networking_flags          => 'up',
        lxc_networking_nat_enable     => false,
        lxc_cgmanager_service_ensure  => false,
        lxc_cgmanager_service_enabled => false,
        require                       => Class['netplan'],
    }

    file { $lxc_path:
        mode    => 'o+x',
        require => Class['lxc'],
    }

    $lxc_defaults = {
        ensure          => 'present',
        template        => 'download',
        template_options => [
            '--dist', 'ubuntu',
            '--release', 'bionic',
            '--arch', 'amd64',
        ],
        storage_backend => 'dir',
    }

    $lxc_interface_defaults = {
        device_name  => 'eth0',
        ensure       => present,
        index        => 0,
        link         => $lxc_bridge,
        ipv4_gateway => $bridge_ip,
        type         => 'veth',
        restart      => false,
    }

    $::lxcs.each |$key, $value| {
        # Run the containers on the master except a few that only run on the slave
        $master_container_state = ($master and $value['on_master']) ? {
            true    => 'running',
            false   => 'stopped',
            default => 'stopped',
        }
        if ($master and $value['on_master']) or !$master and !$value['on_master'] {
            $container_autostart = true
        } else {
            $container_autostart = false
        }
        $lxc = {
            $key => {
                state     => $master_container_state,
                autostart => $container_autostart,
            }
        }
        $lxc_interface = {
            $key => {
                container => $key,
                ipv4      => ["${value['ipv4']}/${bridge_netmask}"],
            }
        }
        create_resources(lxc, $lxc, $lxc_defaults)
        # Only define the interface of the lxcs on the respective host
        if ($master and $value['on_master']) or !$master and !$value['on_master'] {
            create_resources(lxc_interface, $lxc_interface, $lxc_interface_defaults)
        }
    }

    # To be excluded because they are started on the slave
    # Rsync configuration, dependent on master/slave
    if $master {
        rsync::server::module { 'lxc':
            path => $lxc_path,
            uid  => 0,
            gid  => 0,
        }
    } elsif $rsync_master {
        $t = $::lxcs.filter |$k, $v| { !$v['on_master'] }
        $excluded = $t.map |$k, $v| { "${lxc_path}/${k}" }
        rsync::get { 'lxc':
            source  => "rsync://${rsync_master}/lxc/",
            purge   => true,
            exclude => $excluded,
            path    => $lxc_path,
        }
        $t2 = $excluded.map |$value| { "--exclude ${value}" }
        $cron_excluded = join($t2, ' ')
        cron { 'rsync-lxc':
            command => "/usr/bin/rsync -axHAX --delete ${cron_excluded} rsync://${rsync_master}/lxc/ ${lxc_path} >/dev/null 2>&1",
            user    => 'root',
            minute  => '*/10',
        }
    } # Otherwise we are neither master, nor slave
}
