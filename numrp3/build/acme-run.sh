#!/bin/sh
# /etc/periodic/weekly/acme-run.sh

hosts=${HOSTS_ACME:-}
if [ -z "$hosts" ]; then
    exit 0
fi
for host in $hosts; do
    acme-client -a https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf -Nnmv $host && renew=1
done

#[ "$renew" = 1 ] && rc-service nginx reload
[ "$renew" = 1 ] && sv hup nginx
