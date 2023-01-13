select   u.username
       , null as granted_role
       , p.privilege
       , u.account_status
       , to_char(u.expiry_date, 'YYYY-MM-DD HH24:MI:SS') expire_date
from     sys.dba_users     u
join     sys.dba_sys_privs p on p.grantee=u.username
where    u.username not in ('DBSNMP','GGSYS','GSMADMIN_INTERNAL','GSMCATUSER','GSMUSER','ORACLE_OCM','OUTLN','SYS','SYSBACKUP','SYSRAC','SYSTEM','WMSYS','XDB')
         and p.privilege not like '%SELECT%'
         and p.privilege like '%ANY%'
union
select   u.username
       , r.granted_role
       , p.privilege
       , u.account_status
       , to_char(u.expiry_date, 'YYYY-MM-DD HH24:MI:SS') expire_date
from     sys.dba_users      u
join     sys.dba_role_privs r on r.grantee=u.username
join     sys.dba_sys_privs  p on p.grantee=r.granted_role
where    u.username not in ('DBSNMP','GGSYS','GSMADMIN_INTERNAL','GSMCATUSER','GSMUSER','ORACLE_OCM','OUTLN','SYS','SYSBACKUP','SYSRAC','SYSTEM','WMSYS','XDB')
         and p.privilege not like '%SELECT%'
         and p.privilege like '%ANY%'
order by username
       , privilege;