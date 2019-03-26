drop database if exists z2oserver;

create database if not exists z2oserver default charset utf8 collate utf8_general_ci;

use z2oserver;

drop user if exists  'sendy'@'%';

create user 'sendy'@'%' identified by 'sendy';

grant all on z2oserver.* to 'sendy'@'%';