#!/bin/sh

SRVROOT=`find ~ -name "z2oserver" -type d`

$SRVROOT/redis/redis-server --port 6379
