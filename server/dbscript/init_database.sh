#!/bin/sh

sudo mysql -uroot -phansen < ./01_init_db.sql

WEBPATH=`find ~ -name "z2oWebend" -type d | head -1`
rm -rf $WEBPATH/ProxyAgent/*.pyc
rm -rf $WEBPATH/ProxyAgent/migrations/*
rm -rf $WEBPATH/z2oWebend/*.pyc

python $WEBPATH/manage.py makemigrations ProxyAgent
python $WEBPATH/manage.py migrate


mysql -usendy -psendy -Dz2oserver < ./03_proc_register.sql
mysql -usendy -psendy -Dz2oserver < ./04_proc_login.sql
mysql -usendy -psendy -Dz2oserver < ./05_proc_createrobot.sql
mysql -usendy -psendy -Dz2oserver < ./06_proc_loadrobot.sql

mysql -usendy -psendy -Dz2oserver < ./02_init_data.sql

