use z2oserver;

drop procedure if exists proc_login;

delimiter ;;

create procedure proc_login(IN cellphone varchar(11), IN passwd varchar(40))
label_login:begin
    declare errcode int;
    declare o_paswd varchar(40);

    declare o_userid int;
    declare o_username varchar(12);
    declare o_nickname varchar(30);
    declare o_gender int;
    declare o_disable tinyint;
    declare o_createtime datetime;
    declare o_agentid int;
    declare o_promoteid int;
    declare o_avatoridx int;
    declare o_gold int;
    declare o_diamond int;

    set errcode = 0;
    set o_paswd = '';

    select password into o_paswd from User where User.cellphone = cellphone;
    if ifnull(o_paswd,'') <=> '' then
        set errcode = 8;    #cellphone not exists
        select errcode as 'errcode';
        leave label_login;
    end if;

    if o_paswd != passwd then
        set errcode = 7;
        select errcode as 'errcode';
        leave label_login;
    end if;

    select userid, username, nickname, gender, createtime, disable, agentid, promoteid, avatoridx, gold , diamond into 
        o_userid, o_username, o_nickname, o_gender, o_createtime, o_disable, o_agentid ,o_promoteid, o_avatoridx, o_gold, o_diamond from User where User.cellphone = cellphone;

    if ifnull(o_disable,0) <=> 1 then
        set errcode = 9;
        select errcode as 'errcode';
        leave label_login;
    end if;

    select errcode as 'errcode', o_userid as 'userid', o_username as 'username', o_nickname as 'nickname', o_gender as 'gender', cellphone as 'cellphone',
        passwd as 'password', o_createtime as 'createtime', o_disable as 'disable', o_agentid as 'agentid', o_promoteid as 'promoteid' , o_avatoridx as 'avatoridx', o_gold as 'gold', o_diamond as 'diamond';
end
;;