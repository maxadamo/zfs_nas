# zfs_nas

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with zfs_nas](#setup)
    * [What zfs_nas affects](#what-zfs_nas-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with zfs_nas](#beginning-with-zfs_nas)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)

## Description

This modules is the successor of the great [Tiny NAS](https://forge.puppet.com/maxadamo/tiny_nas) :-)
In comparison with Tiny_NAS, it allows the normal load that you'd expect from a NAS.

The module sets up two servers sharing a filesystem through NFS (**SMB is a roadmap feature**).
Development is at an early stage: there are oddities described in the [Limitations](#limitations) section.

## Setup

### What zfs_nas affects

If you have monit already, you may need to reconfigure it, and use a check_interval of 15, or 30 (I'd recommend not more than 60).

Something as following can be used:

```puppet
  class { 'monit':
    manage_firewall => false,
    httpd           => true,
    check_interval  => 15,
    httpd_allow     => 'localhost',
    httpd_user      => 'admin',
    httpd_password  => $mmonit_password,
    mmonit_password => $mmonit_password;
  }
```

Next version of the module will include better support for monit configuration, with different scenarios.

### Setup Requirements

* You need to setup monit, using this module: [monit](https://forge.puppet.com/soli/monit) and you need to set a check_interval of 15 seconds. Check interval in monit is called "cycle". We run our monit cheks every "1 cycles" (every 15 seconds).

* sanoid package is not available. It can be compiled following the instructions: [Install Sanoid](https://github.com/jimsalterjrs/sanoid/blob/master/INSTALL.md)

* zfs repositories and gpg key are needed in CentOS and I am using the package provided by zfs

### Beginning with zfs_nas

The very basic steps needed for a user to get the module up and running. This can include setup steps, if necessary, or it can be an example of the most basic use of the module.

## Usage

### ZFS NAS server

```puppet
$ssh_id_rsa = Sensitive(lookup('ssh_id_rsa'))

class { 'zfs_nas':
  zfs_shares      => lookup('zfs_shares'),
  pool_disks      => lookup('pool_disks'),
  nodes_hostnames => lookup('nodes_hostnames'),
  nodes_ip4       => lookup('nodes_ip4'),
  nodes_ip6       => lookup('nodes_ip6'),
  vip_ip4         => lookup('vip_ip4'),
  vip_ip4_subnet  => lookup('vip_ip4_subnet'),
  vip_ip6         => lookup('vip_ip6'),
  vip_ip6_subnet  => lookup('vip_ip6_subnet'),
  ssh_id_rsa      => $ssh_id_rsa,
  ssh_pub_key     => lookup('ssh_pub_key');
}
```

### ZFS Nas client

```puppet
zfs_nas::client { '/test':
  ensure => present,
  server => 'test-zfs.domain.org',   # this is the VIP of the cluster
  share  => '/zfs_nas/test_influx';
}
```

## Limitations

* puppet will create a zpool on both hosts, but syncoid, pretends to create the zpool for the first time on the slave. This is an odd situation that I cannot easily address. **You need to destroy the the zpools on the slave for the first time only and let syncoid create them**. You'll see the errors in `/var/log/monit.log`
* sanoid package must be compiled following the instructions available here: [Install Sanoid](https://github.com/jimsalterjrs/sanoid/blob/master/INSTALL.md)
* there is no unit test available yet

## Development

Feel free to make pull requests and/or open issues on [Zfs Nas GitHub Repository](https://github.com/maxadamo/zfs_nas)
