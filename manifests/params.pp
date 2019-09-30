# == Class: zfs_nas::params
#
#
class zfs_nas::params {

  $zfs_package = $facts['os']['name'] ? {
    'Ubuntu' => 'zfs-utils',
    'CentOS' => 'zfs'
  }

}
