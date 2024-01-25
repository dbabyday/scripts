set echo on 

alter tablespace XXAPPS add datafile '/oradb/jdepd03/data/xxapps61.dbf' size 1g autoextend on next 1g maxsize unlimited;
alter tablespace XXAPPS add datafile '/oradb/jdepd03/data/xxapps62.dbf' size 1g autoextend on next 1g maxsize unlimited;
alter tablespace XXAPPS add datafile '/oradb/jdepd03/data/xxapps63.dbf' size 1g autoextend on next 1g maxsize unlimited;

set echo off