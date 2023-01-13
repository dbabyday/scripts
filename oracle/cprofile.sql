
set linesize 200 pagesize 50 verify off

column profile format a20
column resource_name format a25
column limit format a30
column common format a6
column inherited format a9
column implicit format a8


-- profile
-- resource_name
-- resource_type
-- limit
-- common
-- inherited
-- implicit

select *
from   sys.dba_profiles
where  profile=upper('&profile');


undefine profile
