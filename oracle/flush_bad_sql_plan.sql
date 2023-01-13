


select address, hash_value from v$sqlarea where sql_id='0td8hcfuhc1cx';
-- @$ORACLE_HOME/rdbms/admin/dbmspool.sql
exec sys.dbms_shared_pool.purge('20000003F6C56D80, 3037070749', 'C');


select 'exec sys.dbms_shared_pool.purge('''||address||', '||to_char(hash_value)||''', ''C'');' from v$sqlarea where sql_id='7yyg6f1snt84f';


