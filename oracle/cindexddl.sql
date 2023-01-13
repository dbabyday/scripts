set linesize 300 define on long 10000
col stmt format a200

select dbms_metadata.get_ddl('INDEX','&INDEX_NAME','&OWNER') stmt from dual;

undefine INDEX_NAME;
undefine OWNER;