use z2oserver;

drop procedure if exists proc_register;

delimiter ;;

create procedure proc_register (IN cellphone varchar(11), IN passwd varchar(40), IN agentcode varchar(6),IN promotecode varchar(50))
label_reg:begin
    declare errcode int;
    declare o_agentid int;
    declare o_promoteid int;
    declare o_userid int;
    declare o_maxuserid int;
    declare o_newuserid int;
    declare o_nickname varchar(30);

    set errcode = 0;
    set o_agentid = 0;
    set o_promoteid = 0;
    set o_userid = 0;
    set o_maxuserid = 0;

    select agentid into o_agentid from Agent where Agent.code = agentcode;
    if ifnull(o_agentid,0) <=> 0 then
        select agentid into o_agentid from Agent where Agent.code = 'adv1301';
    end if;

    select promoteid into o_promoteid from Promote where Promote.code = promotecode;
    if ifnull(o_promoteid,0) <=> 0 then
        select promoteid into o_promoteid from Promote where Promote.promoteid = 1;
    end if;

  
    select userid into o_userid from User where User.cellphone = cellphone;
    if ifnull(o_userid,0) != 0 then
        set errcode = 8;  #user already exists
        select errcode as 'errcode';
        leave label_reg;
    end if;

    select max(userid) into o_maxuserid from User where User.isrobot = 0;
    if ifnull(o_maxuserid,10000) <=> 10000 then
        set o_maxuserid = 10000;
    end if;

    set o_newuserid = o_maxuserid + 1;
    select concat('z2o玩家',o_newuserid) into o_nickname;

    insert into User(userid,username,nickname , avatoridx, gender,cellphone,password, gold, diamond,createtime,disable,agentid,promoteid,isrobot) 
        value( o_newuserid ,cellphone, o_nickname, 1 , 1,cellphone, passwd, 0 , 0, now(), false, o_agentid, o_promoteid, 0);

    select errcode as 'errcode';
end
;;