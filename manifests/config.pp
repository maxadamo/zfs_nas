# == Class: zfs_nas::config
#
#
class zfs_nas::config (
  $zfs_package,
  $manage_sanoid,
  $sanoid_ensure
) {

  class { 'nfs':
    server_enabled => true,
    nfs_v4         => false;
  }

  if $facts['os']['family'] == 'RedHat' {
    file_line {
      default:
        ensure  => present,
        path    => '/etc/modprobe.d/lockd.conf',
        require => Class['nfs'];
      'nlm_udpport':
        line    => 'options lockd nlm_udpport=4045',
        match   => '^*options\ lockd\ nlm_udpport',
        replace => true;
      'nlm_tcpport':
        line    => 'options lockd nlm_tcpport=4045',
        match   => '^*options\ lockd\ nlm_tcpport',
        replace => true;
    }
  }

  package { $zfs_package: ensure  => installed; }
  if ($manage_sanoid) {
    package { 'sanoid':
      ensure => $sanoid_ensure
    }
  }

  file {
    '/etc/modprobe.d/zfs':
      content => "install zfs\n",
      notify  => Exec['modprobe_zfs'],
      require => Package[$zfs_package];
    '/etc/cron.d/zfs-auto-snapshot':
      notify  => Exec["restart_cron_${module_name}"],
      source  => "puppet:///modules/${module_name}/zfs-auto-snapshot",
      require => Package[$zfs_package];
  }

  exec {
    default:
      path        => '/usr/bin:/usr/sbin:/bin:/sbin',
      refreshonly => true;
    'modprobe_zfs':
      command     => 'modprobe zfs';
    "restart_cron_${module_name}":
      command     => 'systemctl restart cron.service';
  }

}
