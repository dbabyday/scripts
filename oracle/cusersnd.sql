set linesize 150
set pagesize 50000
set heading on
set feedback on

column non_default_users format a20
column profile           format a20
column account_status    format a20
column created           format a12
column lock_date         format a19
column expire_date       format a19

select   username  non_default_users
       , profile
       , account_status
       , to_char(created,    'YYYY-MM-DD')            created
       , to_char(lock_date,  'YYYY-MM-DD HH24:MI:SS') lock_date
       , to_char(expiry_date,'YYYY-MM-DD HH24:MI:SS') expire_date
from     sys.dba_users
where    oracle_managed='N'
-- where    username not in (   'ANONYMOUS'
--                            , 'APPQOSSYS'
--                            , 'AUDSYS'
--                            , 'CTXSYS'
--                            , 'DBSFWUSER'
--                            , 'DBSNMP'
--                            , 'DIP'
--                            , 'DVF'
--                            , 'DVSYS'
--                            , 'GGSYS'
--                            , 'GSMADMIN_INTERNAL'
--                            , 'GSMCATUSER'
--                            , 'GSMUSER'
--                            , 'LBACSYS'
--                            , 'MDDATA'
--                            , 'MDSYS'
--                            , 'OJVMSYS'
--                            , 'OLAPSYS'
--                            , 'ORACLE_OCM'
--                            , 'ORDDATA'
--                            , 'ORDPLUGINS'
--                            , 'ORDSYS'
--                            , 'OUTLN'
--                            , 'REMOTE_SCHEDULER_AGENT'
--                            , 'SI_INFORMTN_SCHEMA'
--                            , 'SPATIAL_CSW_ADMIN_USR'
--                            , 'SYS'
--                            , 'SYS$UMF'
--                            , 'SYSBACKUP'
--                            , 'SYSDG'
--                            , 'SYSKM'
--                            , 'SYSRAC'
--                            , 'SYSTEM'
--                            , 'WMSYS'
--                            , 'XDB'
--                            , 'XS$NULL'
--                          )
order by username;