set linesize 32767
set pagesize 50000

column grantee format a20
column owner format a20
column table_name format a30
column privilege format a20
column grantor format a20
column grantable format a9
column hierarchy format a9

select count(*) as user_exists 
from   dba_users 
where  username = '&&username';

select count(*) as table_exists 
from   dba_tables 
where  owner = '&&owner' 
       and table_name = '&&table_name';
       
select   grantee
       , owner
       , table_name
       , privilege
       , grantor
       , grantable
       , hierarchy 
from     dba_tab_privs  
where    (  grantee in (  select granted_role 
                          from   dba_role_privs 
                          where  grantee = upper('&&username')  )
            or grantee = upper('&&username')  )
         and owner = '&&owner'
         and table_name = '&&table_name'
order by owner
       , table_name
       , privilege;

undefine username;
undefine owner;
undefine table_name;