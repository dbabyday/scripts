

set define "&"

column granted_role format a30
column parent_role format a30

prompt substitution variable 1: USERNAME;
column my_username new_value _USERNAME noprint;
select '&1' my_username from dual;

with sa as (
	select privilege#, level role_level, grantee#
	from sys.sysauth$
	connect by prior privilege# = grantee#
	start with grantee# = (select user# from sys.user$ where name='&&_USERNAME') or grantee# = 1
)
select
	  u1.name granted_role
	, s.role_level
	, u2.name parent_role
from
	sa s
join
	sys.user$ u1 on u1.user# = s.privilege#
join
	sys.user$ u2 on u2.user# = s.grantee#
union all
select
	  username granted_role
	, 0 role_level
	, null parent_role
from
	dba_users
where
	username='&&_USERNAME'
union all
select
	  'PUBLIC' granted_role
	, 1 role_level
	, '&&_USERNAME' parent_role
from
	dba_users
where
	username='&&_USERNAME'
order by
	  role_level
	, granted_role;


UNDEFINE 1
UNDEFINE _USERNAME