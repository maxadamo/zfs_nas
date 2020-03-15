# == Class: zfs_nas::share
#
#
define zfs_nas::share (
  $ensure,
  $client_list,
  $share_name = $name,
) {

  $client_string = join($client_list, ',')

  zfs { "zfs_nas/${share_name}":
    ensure     => $ensure,
    mountpoint => "/zfs_nas/${share_name}",
    sharenfs   => $client_string,
    require    => Class['nfs'];
  }

}
