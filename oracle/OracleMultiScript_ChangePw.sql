whenever sqlerror exit sql.sqlcode
whenever oserror exit failure


set feedback off


column my_username new_value _USERNAME noprint;
column my_new_pw new_value _NEW_PW noprint;
select '&1' my_username, '&2' my_new_pw from dual;


set feedback on

begin
	execute immediate 'alter user "&&_USERNAME" identified by "&&_NEW_PW"';

	for x in (
		select   'drop database link '||db_link stmt_drop_dblink
		       , replace(dbms_metadata.get_ddl('DB_LINK',DB_LINK,OWNER),q'^VALUES ':1'^','"&&_NEW_PW"') stmt_create_dblink
		from     dba_db_links
		where    username='&&_USERNAME'
		order by db_link
	)
	loop
		execute immediate x.stmt_drop_dblink;
		execute immediate x.stmt_create_dblink;
	end loop;
end;
/


undefine 1
undefine 2
undefine _USERNAME
undefine _NEW_PW

exit;