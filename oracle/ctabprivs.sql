

set define "&"

column granted_role format a30
column parent_role format a30

prompt substitution variable 1: USERNAME;
column my_username new_value _USERNAME noprint;
select '&1' my_username from dual;

with 
	  sa as (
		select privilege#, grantee#
		from sys.sysauth$
		connect by prior privilege# = grantee#
		start with grantee# = (select user# from sys.user$ where name='&&_USERNAME') or grantee# = 1
	  )
	, granted_roles as (
		select distinct
			  u1.name
		from
			sa s
		join
			sys.user$ u1 on u1.user# = s.privilege#
		join
			sys.user$ u2 on u2.user# = s.grantee#
		union all
		select
			  username name
		from
			dba_users
		where
			username='&&_USERNAME'
		-- union all
		-- select
		-- 	  'PUBLIC' name
		-- from
		-- 	dba_users
		-- where
		-- 	username='&&_USERNAME'
	  )
select distinct
	  p.privilege
	, p.owner
	, p.table_name
from
	dba_tab_privs p
join
	granted_roles r on r.name=p.grantee
order by
	  p.owner
	, p.table_name
	, p.privilege;


UNDEFINE 1
UNDEFINE _USERNAME