# == Class: zfs_nas::pool
#
#
define zfs_nas::pool (
  $pool_disk,
  $pool_name = $name
) {

  zpool { $pool_name:
    disk    => $pool_disk,
    require => Exec['modprobe_zfs'];
  }

}
