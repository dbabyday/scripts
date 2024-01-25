/*

https://github.com/dbabyday
Warranty: The software is provided "AS IS", without warranty of any kind

Name: cadminprivs.sql
Description: See elevated privileges in the database

*/



set linesize 300
set pagesize 50000
set trimout on

set pages 10000 lines 200 trimspool on colsep , feedback off

-- column username format a20
-- column granted_role format a20

-- selects users with the ability perform ddl operations in "ANY" schema
select    u.username
        , null as granted_role
        , p.privilege
        , u.account_status
        , to_char(u.expiry_date,'DD-MON-YYYY') ExpireDate
from      sys.dba_users     u
join      sys.dba_sys_privs p on p.grantee=u.username
where     u.oracle_maintained='N'  -- exclude Oracle default accounts
          and (  p.privilege like '% ANY %'
                 or p.privilege like 'FLASHBACK%'
                 or p.privilege in ('ANALYZE','ASSOCIATE STATISTICS','DISASSOCIATE STATISTICS','AUDIT','NOAUDIT')
              )
          and p.privilege not like 'SELECT ANY%'
union all
-- selects users in roles that have the ability to perform ddl operations in "ANY" schema
select    u.username
        , r.granted_role
        , p.privilege
        , u.account_status
        , to_char(u.expiry_date,'DD-MON-YYYY') ExpireDate
from      sys.dba_role_privs r
join      sys.dba_sys_privs  p on p.grantee=r.granted_role
join      sys.dba_users      u on u.username=r.grantee
where     u.oracle_maintained='N'  -- exclude Oracle default accounts
          and (  p.privilege like '% ANY %'
                 or p.privilege like 'FLASHBACK%'
                 or p.privilege in ('ANALYZE','ASSOCIATE STATISTICS','DISASSOCIATE STATISTICS','AUDIT','NOAUDIT')
              )
          and p.privilege not like 'SELECT ANY%'
order by  username
        , granted_role
        , privilege;

/*

select    u.username
        , null as granted_role
        , p.privilege
        , u.account_status
        , u.expiry_date as expire_date
from      sys.dba_users     u
join      sys.dba_sys_privs p on p.grantee=u.username
where     u.oracle_maintained='N'
          and (    (    p.privilege like '% ANY %'
                        and p.privilege not like '%SELECT%'
                   )
                   or p.privilege='FLASHBACK ARCHIVE ADMINISTER'
              )
union
select    rp.grantee as username
        , rp.granted_role
        , p.privilege
        , null as account_status
        , null as expire_date
from      sys.dba_roles      r
join      sys.dba_sys_privs  p  on p.grantee=r.role
join      sys.dba_role_privs rp on rp.GRANTED_ROLE=r.role
join      sys.dba_users      u  on u.username=rp.grantee
where     u.oracle_maintained='N'
          and (    (    p.privilege like '% ANY %'
                        and p.privilege not like '%SELECT%'
                   )
                   or p.privilege='FLASHBACK ARCHIVE ADMINISTER'
              )
order by  username
        , granted_role
        , privilege;

*/