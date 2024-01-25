/*

https://github.com/dbabyday
Warranty: The software is provided "AS IS", without warranty of any kind

Name: capture_server_errors.sql
Description: Create the table and trigger to capture server errors thrown by Oracle Database

*/


-- create objects as sysdba

create table sys.server_errors (
	  id                    number         not null
	, error_date            date           not null
	, ora_sysevent          varchar2(128)
	, ora_login_user        varchar2(128)
	, ora_server_error_msg  varchar2(4000)
	, sid                   number
	, host                  varchar2(256)
	, ip                    varchar2(15)
	, module                varchar2(4000)
	, serverhost            varchar2(256)
	, sql                   clob
);

create unique index sys.server_errors_plxs_01 on sys.server_errors (id);

alter table sys.server_errors add (
	constraint server_errors_pk
	primary key (id)
	using index sys.server_errors_plxs_01
	enable validate
);



create sequence sys.server_error_seq;



create or replace trigger sys.server_error_trg
after servererror on database
disable
declare
	v_sql_text ora_name_list_t;
	v_sql      clob;
	v_n        number;
begin
	v_n := ora_sql_txt(v_sql_text);
	for i in 1 .. v_n loop
		v_sql := v_sql || v_sql_text(i);
	end loop;

	-- if you find a huge number of irrelevant errors, you might want to filter them out here.

	insert into server_errors (
		  id
		, error_date
		, ora_sysevent
		, ora_login_user
		, ora_server_error_msg
		, sid
		, host
		, ip
		, module
		, serverhost
		, sql
	)
	values (
		  server_error_seq.nextval
		, sysdate
		, ora_sysevent
		, ora_login_user
		, ora_server_error_msg(1)
		, sys_context ('USERENV','SID')
		, sys_context ('USERENV','HOST')
		, sys_context ('USERENV','IP_ADDRESS')
		, sys_context ('USERENV','MODULE')
		, sys_context ('USERENV','SERVER_HOST')
		, v_sql
	);
	commit;

-- never raise an exception from this trigger
-- no matter what happens we don't want recursive errors
exception when others then
	null;
end;
/


/*  -- run as sysdba

alter trigger sys.server_error_trg enable;

alter trigger sys.server_error_trg disable;

truncate table sys.server_errors;

*/


-- select	  id
-- 	, error_date
-- 	, ora_sysevent
-- 	, ora_login_user
-- 	, ora_server_error_msg
-- 	, sid
-- 	, host
-- 	, ip
-- 	, module
-- 	, serverhost
-- 	, sql
-- from	  sys.server_errors
-- --where	  ora_server_error_msg like 'ORA-00001: unique constraint%PRODDTA.F5530269_PK%'
-- order by  error_date;



/*

column ora_login_user format a14
column host format a25
column module format a20
column ora_server_error_msg format a50
column sql format a50
select	  error_date
	, ora_login_user
	, host
	, module
	, ora_server_error_msg
	, sql
from	  sys.server_errors
--where	  ora_server_error_msg like 'ORA-00001: unique constraint%PRODDTA.F5530269_PK%'
order by  error_date;


*/

