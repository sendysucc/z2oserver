#!/bin/sh

SRVROOT=`find ~ -name "z2oserver" -type d`

$SRVROOT/redis/redis-server $SRVROOT/redis/redis-development.conf
