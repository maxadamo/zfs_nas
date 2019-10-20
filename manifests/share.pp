# == Class: zfs_nas::share
#
#
define zfs_nas::share (
  $ensure,
  $zpool_name,
  $client_list,
  $share_name = $name,
) {

  $client_string = join($client_list, ',')

  zfs { "${zpool_name}/${share_name}":
    ensure     => $ensure,
    mountpoint => "/zfs/${zpool_name}/${share_name}",
    sharenfs   => $client_string,
    require    => Class['nfs'];
  }

}
