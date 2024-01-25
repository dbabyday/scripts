col current_scn format 999999999999999

select name, sysdate, current_scn from v$database;
