export SRVROOT=`find ~ -name "z2oserver" -type d`

$SRVROOT/redis/redis-server &


$SRVROOT/skynet/skynet $SRVROOT/server/config/config.v.0.1
