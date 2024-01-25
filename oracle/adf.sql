/*

https://github.com/dbabyday

Name: adf.sql
Description: add data file
Substitution variables:
	1. TABLESPACE_NAME - tablespace to which you are adding a datafile
	2. DATAFILE_NAME - full path name of the new datafile

*/


set define "&"
set feedback off
prompt ;
prompt substitution variable 1 is for TABLESPACE_NAME
prompt substitution variable 1 is for DATAFILE_NAME
column my_tablespace_name new_value TABLESPACE_NAME noprint;
column my_datafile_name new_value DATAFILE_NAME noprint;
select '&1' my_tablespace_name, '&2' my_datafile_name from dual;
set feedback on

set echo on

alter tablespace &&TABLESPACE_NAME
	add datafile '&&DATAFILE_NAME'
	size 1g
	autoextend on next 1g
	maxsize unlimited;

set echo off

undefine 1
undefine 2
undefine TABLESPACE_NAME
undefine DATAFILE_NAME