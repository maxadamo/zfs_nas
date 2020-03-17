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

You have an option to let this module configure monit or you can configure monit yourself.
I recommend to set a check interval between 15 and 60 seconds. Check interval in monit is called "cycle". We run our monit cheks every "1 cycles" (hence every 15 seconds). There are few modules available to configure monit.

### Setup Requirements

* sanoid package is not available. It can be compiled following the instructions: [Install Sanoid](https://github.com/jimsalterjrs/sanoid/blob/master/INSTALL.md)

* zfs repositories and gpg key are needed in CentOS (I haven't tested CentOS 8 yet) and I am using the package provided by zfs

### Beginning with zfs_nas

Zfs_nas will will set cron jobs inside the file `/etc/cron.d/zfs-auto-snapshot`.

Furthermore, every 15 seconds, syncoid will run on the slave, to pull data from the master.

The zpool is created with the name `zfs_nas`. I don't see a reason to customize the name.

## Usage

### ZFS NAS server

In hiera you could have something as following:

```yaml
---
nodes_hostnames:
  - "test-zfs01.domain.org"
  - "test-zfs02.domain.org"
nodes_ip4:
  - '192.168.2.92'
  - '192.168.2.93'
nodes_ip6:
  - '2001:.....:233'
  - '2001:.....:234'
vip_ip4: '192.168.2.94'
vip_ip4_subnet: 22
vip_ip6: '2001:.....:235'
vip_ip6_subnet: 64
pool_disks: 'sdb'
zfs_shares:
  academy:
    ensure: present
    client_list:
      - 'rw=@192.168.2.24,sec=insecure,async,no_root_squash,no_subtree_check'
      - 'rw=@192.168.2.25,sec=insecure,async,no_root_squash,no_subtree_check'
      - 'rw=@2001.....12c,sec=,insecure,async,no_root_squash,no_subtree_check'
      - 'rw=@2001.....12d,sec=insecure,async,no_root_squash,no_subtree_check'
ssh_pub_key: 'AAAAB3N.......zNTg/NjqJ'
ssh_id_rsa: >
    ENC[PKCS7,Mblahblahblah....
    ...
    kjhkhkh]
```

And you call the module as following:

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

* sanoid package must be compiled following the instructions available here: [Install Sanoid](https://github.com/jimsalterjrs/sanoid/blob/master/INSTALL.md)
* there is no unit test available yet (you trust what I'm doing)

## Development

Feel free to make pull requests and/or open issues on [Zfs Nas GitHub Repository](https://github.com/maxadamo/zfs_nas)
