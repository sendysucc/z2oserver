use z2oserver;
drop procedure if exists proc_createrobots;

delimiter ;;

create procedure proc_createrobots(IN robottype int,IN nums int)
label_createrob:begin

    declare createcount int;
    declare maxrobotid int;
    declare newrobotid int;
    declare defaultwealth int;
    
    declare r_username varchar(12);
    declare r_nickname varchar(30);
    declare r_avatoridx int;
    declare r_cellphone varchar(11);
    declare r_idx int;
    declare r_gender int;
    declare r_password varchar(40);
    declare r_gold int;
    declare r_diamond int;
    declare typebase int;


    set createcount = nums;
    set r_idx = 1;

    if robottype <=> 1 then
        set typebase = 100;
    elseif robottype <=> 2 then
        set typebase = 1000;
    elseif robottype <=> 3 then
        set typebase = 10000;
    elseif robottype <=> 4 then
        set typebase = 100000;
    elseif robottype <=> 5 then
        set typebase = 1000000;
    else 
        select 'robot type error';
        leave label_createrob;
    end if;

    select max(userid) into maxrobotid from User where User.isrobot = 1 ;
    if ifnull(maxrobotid,0) <=> 0 then
        set newrobotid = 900000;
    else
        set newrobotid = maxrobotid + 1;
    end if;

    while createcount > 0 do
        set r_username = concat('10000', newrobotid);
        set r_nickname = concat('z2o玩家',newrobotid);
        set r_avatoridx = r_idx % 10;
        if r_avatoridx <=> 0 then
            set r_avatoridx = 10;
        end if;
        set r_cellphone = r_username;
        set r_gender = ( r_idx % 3 + 1) % 2;  #男:女 = 2:1
        set r_password = sha1(r_cellphone);
        set r_gold = floor(rand() * typebase);
        if r_gold < typebase/10 then
            set r_gold = r_gold + typebase /2 ;
        end if;
        set r_diamond = floor(rand() * typebase);
        if r_diamond < typebase /10 then
            set r_diamond = r_diamond + typebase/2;
        end if;

        insert into User(userid,username,nickname,avatoridx,gender,cellphone,password,gold,diamond,createtime,disable,agentid,promoteid,isrobot) 
            values (newrobotid , r_username, r_nickname, r_avatoridx, r_gender , r_cellphone, r_password ,  r_gold, r_diamond, now(), 0, 1,1,1);

        set createcount = createcount - 1;
        set r_idx = r_idx + 1;
        set newrobotid = newrobotid + 1;
    end while;
end
;;