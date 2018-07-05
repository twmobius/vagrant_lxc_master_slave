class role::lxc::slave(
    $master,
){
    class { 'rsync':
        package_ensure => 'latest',
    }

    rsync::get { 'lxc':
        source => "rsync://${master}/lxc/",
    }
}
