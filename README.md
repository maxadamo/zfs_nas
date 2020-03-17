# zfs_nas

Welcome to your new module. A short overview of the generated parts can be found in the PDK documentation at https://puppet.com/pdk/latest/pdk_generating_modules.html .

The README template below provides a starting point with details about what information to include in your README.

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

This modules sets up two servers sharing a filesystem through NFS (SMB is in the roadmap).
The module is still at an early stage development.

## Setup

### What zfs_nas affects **OPTIONAL**

If it's obvious what your module touches, you can skip this section. For example, folks can probably figure out that your mysql_instance module affects their MySQL instances.

If there's more that they should know about, though, this is the place to mention:

* Files, packages, services, or operations that the module will alter, impact, or execute.
* Dependencies that your module automatically installs.
* Warnings or other important notices.

### Setup Requirements

* You need to setup monit, using this module: [monit](https://forge.puppet.com/soli/monit) and you need to set a check_interval of 15 seconds
  check interval is monit is called "cycle". We run our monit cheks every "1 cycles" (every 15 seconds)

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

## Reference

This section is deprecated. Instead, add reference information to your code as Puppet Strings comments, and then use Strings to generate a REFERENCE.md in your module. For details on how to add code comments and generate documentation with Strings, see the Puppet Strings [documentation](https://puppet.com/docs/puppet/latest/puppet_strings.html) and [style guide](https://puppet.com/docs/puppet/latest/puppet_strings_style.html)

If you aren't ready to use Strings yet, manually create a REFERENCE.md in the root of your module directory and list out each of your module's classes, defined types, facts, functions, Puppet tasks, task plans, and resource types and providers, along with the parameters for each.

For each element (class, defined type, function, and so on), list:

  * The data type, if applicable.
  * A description of what the element does.
  * Valid values, if the data type doesn't make it obvious.
  * Default value, if any.

For example:

```
### `pet::cat`

#### Parameters

##### `meow`

Enables vocalization in your cat. Valid options: 'string'.

Default: 'medium-loud'.
```

## Limitations

In the Limitations section, list any incompatibilities, known issues, or other warnings.

## Development

In the Development section, tell other users the ground rules for contributing to your project and how they should submit their work.

## Release Notes/Contributors/Etc. **Optional**

If you aren't using changelog, put your release notes here (though you should consider using changelog). You can also add any additional sections you feel are necessary or important to include here. Please use the `## ` header.
