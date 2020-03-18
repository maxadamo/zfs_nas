#!/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

systemctl reload nfs-server.service

for SHARE in <%= $zfs_share_list %>; do
    flock /tmp/syncoid_${SHARE} syncoid --quiet root@<%= $peer_fqdn[0] %>:zfs_nas/${SHARE} zfs_nas/${SHARE} || echo "ERROR synchronizing ${SHARE}"
done
