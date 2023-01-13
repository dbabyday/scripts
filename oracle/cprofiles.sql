
set linesize 200 pagesize 5000 verify off

column profile format a20
column limit format a30
column common format a6
column inherited format a9
column implicit format a8

select   *
from     sys.dba_profiles
where    resource_type='PASSWORD'
order by profile
       , resource_type
       , resource_name;
