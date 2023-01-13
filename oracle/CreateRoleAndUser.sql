SQL> select distinct owner from dba_tables order by 1;

OWNER
------------------------------
APEX_030200
APPQOSSYS
CTXSYS
DBSNMP
EXFSYS
FLOWS_FILES
GGADMIN
MDSYS
OLAPSYS
ORDDATA
ORDSYS

OWNER
------------------------------
OUTLN
OWBSYS
PRODCTL
PRODDTA
SCOTT
SYS
SYS7333
SYSMAN
SYSTEM
WMSYS
XDB

22 rows selected.

SQL> create role ggro not identified;

Role created.

SQL> set pages 0 feedback off lines 2000 trimspool on
SQL> spool cr_ggro.sql

select 'grant select on '||owner||'.'||table_name||' to ggro;'
from dba_tables
where owner in ('PRODCTL','PRODDTA','SYS7333')
order by owner, table_name
SQL> /

grant select on PRODCTL.F0005 to ggro;
grant select on PRODCTL.F00821 to ggro;
grant select on PRODDTA.F0006 to ggro;
grant select on PRODDTA.F0010 to ggro;
grant select on PRODDTA.F0011 to ggro;
grant select on PRODDTA.F0014 to ggro;
grant select on PRODDTA.F0015 to ggro;
grant select on PRODDTA.F0101 to ggro;
grant select on PRODDTA.F0111 to ggro;
grant select on PRODDTA.F0115 to ggro;
grant select on PRODDTA.F01151 to ggro;
grant select on PRODDTA.F0116 to ggro;
grant select on PRODDTA.F0150 to ggro;
grant select on PRODDTA.F0301 to ggro;
grant select on PRODDTA.F0311 to ggro;
grant select on PRODDTA.F0312 to ggro;
grant select on PRODDTA.F03B11 to ggro;
grant select on PRODDTA.F03B11Z1 to ggro;
grant select on PRODDTA.F03B13 to ggro;
grant select on PRODDTA.F03B14 to ggro;
grant select on PRODDTA.F0401 to ggro;
grant select on PRODDTA.F0411 to ggro;
grant select on PRODDTA.F0413 to ggro;
grant select on PRODDTA.F0414 to ggro;
grant select on PRODDTA.F04572 to ggro;
grant select on PRODDTA.F04573 to ggro;
grant select on PRODDTA.F04UI004 to ggro;
grant select on PRODDTA.F0901 to ggro;
grant select on PRODDTA.F0902 to ggro;
grant select on PRODDTA.F0911 to ggro;
grant select on PRODDTA.F0911Z1 to ggro;
grant select on PRODDTA.F09UI006 to ggro;
grant select on PRODDTA.F30006 to ggro;
grant select on PRODDTA.F30008 to ggro;
grant select on PRODDTA.F3002 to ggro;
grant select on PRODDTA.F30026 to ggro;
grant select on PRODDTA.F3003 to ggro;
grant select on PRODDTA.F3009 to ggro;
grant select on PRODDTA.F3011 to ggro;
grant select on PRODDTA.F3102 to ggro;
grant select on PRODDTA.F3111 to ggro;
grant select on PRODDTA.F3111T to ggro;
grant select on PRODDTA.F3112 to ggro;
grant select on PRODDTA.F31122 to ggro;
grant select on PRODDTA.F3112T to ggro;
grant select on PRODDTA.F3411 to ggro;
grant select on PRODDTA.F3412 to ggro;
grant select on PRODDTA.F3413 to ggro;
grant select on PRODDTA.F34UI003 to ggro;
grant select on PRODDTA.F38010 to ggro;
grant select on PRODDTA.F38011 to ggro;
grant select on PRODDTA.F38012 to ggro;
grant select on PRODDTA.F38013 to ggro;
grant select on PRODDTA.F38014 to ggro;
grant select on PRODDTA.F40051 to ggro;
grant select on PRODDTA.F4006 to ggro;
grant select on PRODDTA.F4021W to ggro;
grant select on PRODDTA.F4074 to ggro;
grant select on PRODDTA.F41002 to ggro;
grant select on PRODDTA.F41003 to ggro;
grant select on PRODDTA.F4101 to ggro;
grant select on PRODDTA.F41015 to ggro;
grant select on PRODDTA.F4101T to ggro;
grant select on PRODDTA.F4102 to ggro;
grant select on PRODDTA.F41021 to ggro;
grant select on PRODDTA.F4104 to ggro;
grant select on PRODDTA.F4105 to ggro;
grant select on PRODDTA.F4108 to ggro;
grant select on PRODDTA.F4111 to ggro;
grant select on PRODDTA.F4201 to ggro;
grant select on PRODDTA.F4211 to ggro;
grant select on PRODDTA.F42119 to ggro;
grant select on PRODDTA.F42199 to ggro;
grant select on PRODDTA.F4301 to ggro;
grant select on PRODDTA.F4311 to ggro;
grant select on PRODDTA.F4311T to ggro;
grant select on PRODDTA.F43121 to ggro;
grant select on PRODDTA.F43199 to ggro;
grant select on PRODDTA.F47011 to ggro;
grant select on PRODDTA.F47012 to ggro;
grant select on PRODDTA.F47016 to ggro;
grant select on PRODDTA.F47017 to ggro;
grant select on PRODDTA.F47041 to ggro;
grant select on PRODDTA.F47042 to ggro;
grant select on PRODDTA.F47056 to ggro;
grant select on PRODDTA.F470563 to ggro;
grant select on PRODDTA.F4706 to ggro;
grant select on PRODDTA.F4801 to ggro;
grant select on PRODDTA.F4801T to ggro;
grant select on PRODDTA.F550101T to ggro;
grant select on PRODDTA.F5501043 to ggro;
grant select on PRODDTA.F5503021 to ggro;
grant select on PRODDTA.F5503022 to ggro;
grant select on PRODDTA.F5503023 to ggro;
grant select on PRODDTA.F5503024 to ggro;
grant select on PRODDTA.F5503025 to ggro;
grant select on PRODDTA.F5503027 to ggro;
grant select on PRODDTA.F5504001 to ggro;
grant select on PRODDTA.F5504004 to ggro;
grant select on PRODDTA.F550401T to ggro;
grant select on PRODDTA.F5509016 to ggro;
grant select on PRODDTA.F5530026 to ggro;
grant select on PRODDTA.F5531006 to ggro;
grant select on PRODDTA.F5531007 to ggro;
grant select on PRODDTA.F5531008 to ggro;
grant select on PRODDTA.F5531009 to ggro;
grant select on PRODDTA.F5531010 to ggro;
grant select on PRODDTA.F5531011 to ggro;
grant select on PRODDTA.F5531023 to ggro;
grant select on PRODDTA.F5531030 to ggro;
grant select on PRODDTA.F5531041 to ggro;
grant select on PRODDTA.F5531051 to ggro;
grant select on PRODDTA.F553106W to ggro;
grant select on PRODDTA.F553107W to ggro;
grant select on PRODDTA.F5534011 to ggro;
grant select on PRODDTA.F5538009 to ggro;
grant select on PRODDTA.F5538011 to ggro;
grant select on PRODDTA.F5541005 to ggro;
grant select on PRODDTA.F5541007 to ggro;
grant select on PRODDTA.F5541012 to ggro;
grant select on PRODDTA.F5541017 to ggro;
grant select on PRODDTA.F5541018 to ggro;
grant select on PRODDTA.F5541019 to ggro;
grant select on PRODDTA.F554102 to ggro;
grant select on PRODDTA.F5541021 to ggro;
grant select on PRODDTA.F5541024 to ggro;
grant select on PRODDTA.F554102T to ggro;
grant select on PRODDTA.F5541030 to ggro;
grant select on PRODDTA.F5541032 to ggro;
grant select on PRODDTA.F5541044 to ggro;
grant select on PRODDTA.F5541046 to ggro;
grant select on PRODDTA.F5541081 to ggro;
grant select on PRODDTA.F5541101 to ggro;
grant select on PRODDTA.F5541102 to ggro;
grant select on PRODDTA.F5541172 to ggro;
grant select on PRODDTA.F5542005 to ggro;
grant select on PRODDTA.F5542009 to ggro;
grant select on PRODDTA.F5542011 to ggro;
grant select on PRODDTA.F5542012 to ggro;
grant select on PRODDTA.F5542015 to ggro;
grant select on PRODDTA.F5542018 to ggro;
grant select on PRODDTA.F5542055 to ggro;
grant select on PRODDTA.F554211G to ggro;
grant select on PRODDTA.F5542200 to ggro;
grant select on PRODDTA.F5542206 to ggro;
grant select on PRODDTA.F5542207 to ggro;
grant select on PRODDTA.F5542215 to ggro;
grant select on PRODDTA.F5543001 to ggro;
grant select on PRODDTA.F5543002 to ggro;
grant select on PRODDTA.F5543009 to ggro;
grant select on PRODDTA.F5543011 to ggro;
grant select on PRODDTA.F5543012 to ggro;
grant select on PRODDTA.F5543013 to ggro;
grant select on PRODDTA.F5543024 to ggro;
grant select on PRODDTA.F5543035 to ggro;
grant select on PRODDTA.F5543051 to ggro;
grant select on PRODDTA.F5543110 to ggro;
grant select on PRODDTA.F5543121 to ggro;
grant select on PRODDTA.F5543123 to ggro;
grant select on PRODDTA.F554312T to ggro;
grant select on PRODDTA.F5543199 to ggro;
grant select on PRODDTA.F5547013 to ggro;
grant select on PRODDTA.F5547054 to ggro;
grant select on PRODDTA.F5547055 to ggro;
grant select on PRODDTA.F5547056 to ggro;
grant select on PRODDTA.F5547074 to ggro;
grant select on PRODDTA.F5547075 to ggro;
grant select on PRODDTA.F5547076 to ggro;
grant select on PRODDTA.F5547202 to ggro;
grant select on PRODDTA.F5548001 to ggro;
grant select on PRODDTA.F5548003 to ggro;
grant select on PRODDTA.F5548005 to ggro;
grant select on PRODDTA.F554800W to ggro;
grant select on PRODDTA.F55911WF to ggro;
grant select on SYS7333.F00950 to ggro;
grant select on SYS7333.F9312 to ggro;
grant select on SYS7333.F98223 to ggro;
grant select on SYS7333.F98224 to ggro;
grant select on SYS7333.F98230 to ggro;
grant select on SYS7333.F9829 to ggro;

SQL> spool off
SQL> !vi cr_ggro.sql
set echo on feedback on
spool cr_ggro
grant select on PRODCTL.F0005 to ggro;
grant select on PRODCTL.F00821 to ggro;
grant select on PRODDTA.F0006 to ggro;
grant select on PRODDTA.F0010 to ggro;
grant select on PRODDTA.F0011 to ggro;
grant select on PRODDTA.F0014 to ggro;
grant select on PRODDTA.F0015 to ggro;
grant select on PRODDTA.F0101 to ggro;
grant select on PRODDTA.F0111 to ggro;
grant select on PRODDTA.F0115 to ggro;
grant select on PRODDTA.F01151 to ggro;
grant select on PRODDTA.F0116 to ggro;
...
grant select on PRODDTA.F0150 to ggro;
grant select on PRODDTA.F0301 to ggro;
grant select on PRODDTA.F0311 to ggro;
grant select on PRODDTA.F0312 to ggro;
grant select on PRODDTA.F03B11 to ggro;
grant select on PRODDTA.F03B11Z1 to ggro;
grant select on PRODDTA.F03B13 to ggro;
grant select on PRODDTA.F03B14 to ggro;
grant select on PRODDTA.F0401 to ggro;
grant select on PRODDTA.F5548001 to ggro;
grant select on PRODDTA.F5548003 to ggro;
grant select on PRODDTA.F5548005 to ggro;
grant select on PRODDTA.F554800W to ggro;
grant select on PRODDTA.F55911WF to ggro;
grant select on SYS7333.F00950 to ggro;
grant select on SYS7333.F9312 to ggro;
grant select on SYS7333.F98223 to ggro;
grant select on SYS7333.F98224 to ggro;
grant select on SYS7333.F98230 to ggro;
grant select on SYS7333.F9829 to ggro;
spool off

SQL> @cr_ggro.sql
SQL> spool cr_ggro
SQL> grant select on PRODCTL.F0005 to ggro;

Grant succeeded.

SQL> grant select on PRODCTL.F00821 to ggro;

Grant succeeded.

SQL> grant select on PRODDTA.F0006 to ggro;

Grant succeeded.

SQL> grant select on PRODDTA.F0010 to ggro;

Grant succeeded.
...

SQL> grant select on SYS7333.F98223 to ggro;

Grant succeeded.

SQL> grant select on SYS7333.F98224 to ggro;

Grant succeeded.

SQL> grant select on SYS7333.F98230 to ggro;

Grant succeeded.

SQL> grant select on SYS7333.F9829 to ggro;

Grant succeeded.

SQL> spool off

SQL> create user wconnor identified by "n0tthepassword!" default tablespace users profile plexus_user_profile;

User created.

SQL> grant create session to wconnor;

Grant succeeded.

SQL> grant ggro to wconnor;

Grant succeeded.

SQL> alter user wconnor quota unlimited on users;

User altered.

SQL> password wconnor
Changing password for wconnor
New password: 
Retype new password: 
Password changed
SQL> alter user wconnor password expire;

User altered.

