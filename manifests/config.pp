# == Class: zfs_nas::config
#
#
class zfs_nas::config () {

  class { 'nfs':
    server_enabled => true,
    nfs_v4         => false;
  }

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

  package { 'zfs': ensure  => installed; }

  file { '/etc/modprobe.d/zfs':
    content => "install zfs\n",
    notify  => Exec['modprobe_zfs'],
    require => Package['zfs'];
  }

  exec { 'modprobe_zfs':
    command     => 'modprobe zfs',
    path        => '/usr/bin:/usr/sbin:/bin:/sbin',
    refreshonly => true;
  }

}
