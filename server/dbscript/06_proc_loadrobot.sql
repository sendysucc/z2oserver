use z2oserver;
drop procedure if exists proc_loadrobots;

delimiter ;;

create procedure proc_loadrobots(IN startIdx INT, IN loadCounts INT)
label_loadrob:begin
    select userid, username, nickname, avatoridx, gender, gold , diamond , disable, isrobot from User where User.isrobot = 1 and User.userid >= ( 900000 + startIdx ) and (userid < 900000 + loadCounts) order by gold asc;
end
;;