# == Class: zfs_nas::params
#
#
class zfs_nas::params {

  $zfs_package = $facts['os']['name'] ? {
    'Ubuntu' => [
      'zfsutils-linux', 'zfs-auto-snapshot',
      'debhelper', 'libcapture-tiny-perl',
      'libconfig-inifiles-perl', 'pv', 'lzop',
      'mbuffer'],
    'CentOS' => ['zfs', 'zfs-auto-snapshot']
  }

}
