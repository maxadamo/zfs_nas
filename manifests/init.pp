# == Class: zfs_nas
#
#
class zfs_nas () inherits zfs_nas::params {

  include zfs_nas::config

}
