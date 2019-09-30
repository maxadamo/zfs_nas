# == Class: zfs_nas::share
#
#
define zfs_nas::share (
  $pool_disk,
  $pool_name,
) {

# my_fancy_pool:
#   my_fancy_share:
#     mount_point: /var/blahbla
#     share_properties: 'ro@83.97.92.0/22,sec=sys'

  zpool { $pool_name:
    disk    => $pool_disk,
    require => Exec['modprobe_zfs'];
  }

  zfs { 'repositories/pub':
    ensure     => present,
    mountpoint => '/var/repositories/pub',
    sharenfs   => 'ro=@83.97.92.0/22,sec=sys',
    require    => Class['nfs'];
  }

}
