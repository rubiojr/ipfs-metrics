#!/bin/bash

# Add to /etc/cron.d:
#
# PATH=/usr/lib/sysstat:/usr/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/local/bin
# */5 * * * * ipfs /usr/local/bin/ipfs-stats.sh >> /tmp/ipfs-stats.log 2>&1
#

GRAPHITE_HOST=my-graphite-host
GRAPHITE_PORT=2003 # UDP
IPFS_GATEWAY_URL="http://gateway.ipfs.io/ipfs/QmTeW79w7QQ6Npa3b1d5tANreCDxF2iDaAPsDvW6KtLmfB"

send_metric(){
  local m="$1"
  echo $m | nc -w 1 -u $GRAPHITE_HOST $GRAPHITE_PORT
  # debug
  echo $m
}

nodes() {
  # Sleep random number of seconds so we don't gather/send all the metrics at the same time
  sleep $(( ( RANDOM % 30 )  + 1 ))

  local tstart=$(date +%s)
  local nodes=$(ipfs diag net| grep "seconds connected" | wc -l) || 0
  send_metric "ipfs.global.nodes $nodes $(date +%s)"

  local tend=$(date +%s)
  local elapsed=$((tend - tstart))
  send_metric "ipfs.global.diag_net_time $elapsed $(date +%s)"
}

gateway_get() {
  # Sleep random number of seconds so we don't gather/send all the metrics at the same time
  sleep $(( ( RANDOM % 30 )  + 1 ))

  local tstart=$(date +%s)
  local elapsed=0
  if curl -L -v $IPFS_GATEWAY_URL 2>&1 | grep -q "200 OK"; then
    local tend=$(date +%s)
    local elapsed=$((tend - tstart))
  fi
  send_metric "ipfs.global.gateway_get $nodes $(date +%s)"
  send_metric "ipfs.global.gateway_get_elapsed $elapsed $(date +%s)"
}

nodes &
gateway_get &

wait
