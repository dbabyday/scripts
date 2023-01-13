set echo off
set feedback off
set pagesize 0
set linesize 32767
set trimout on
set trimspool on
set serveroutput on format wrapped

spool y.sql append

DECLARE
	l_dbname             varchar2(9);
	l_dbid               varchar2(38);
	l_created            varchar2(15);
	l_log_mode           varchar2(12);
	l_cdb                varchar2(3);
	l_con_id             varchar2(38);
	l_con_dbid           varchar2(38);
	l_host_name          varchar2(64);
	l_version            varchar2(17);
	l_edition            varchar2(7);
	l_oracle_home        varchar2(4000);
	l_archive_lag_target varchar2(38);
	l_compatible         varchar2(17);
	l_control_files      varchar2(4000);
	l_cpu_count          varchar2(38);
	l_db_block_size      varchar2(38);
	l_memory_max_target  varchar2(38);
	l_memory_target      varchar2(38);
	l_processes          varchar2(38);
	l_sga_max_size       varchar2(38);
	l_sga_min_size       varchar2(38);
	l_sga_target         varchar2(38);
	l_spfile             varchar2(4000);
BEGIN
	------------------------------------
	--// get the values             //--
	------------------------------------

	select   name, to_char(dbid), to_char(created,'YYYYMMDD HH24MISS'),   log_mode
	into   l_dbname,       l_dbid,        l_created,                      l_log_mode
	from   v$database;

	select   host_name,   version
	into   l_host_name, l_version
	from   v$instance;

	sys.dbms_system.get_env('ORACLE_HOME',l_oracle_home);

	select value into l_archive_lag_target from v$system_parameter where name='archive_lag_target';
	select value into l_compatible         from v$system_parameter where name='compatible';
	select value into l_control_files      from v$system_parameter where name='control_files';
	select value into l_cpu_count          from v$system_parameter where name='cpu_count';
	select value into l_db_block_size      from v$system_parameter where name='db_block_size';
	select value into l_memory_max_target  from v$system_parameter where name='memory_max_target';
	select value into l_memory_target      from v$system_parameter where name='memory_target';
	select value into l_processes          from v$system_parameter where name='processes';
	select value into l_sga_max_size       from v$system_parameter where name='sga_max_size';
	-- select value into l_sga_min_size       from v$system_parameter where name='sga_min_size';
	select value into l_sga_target         from v$system_parameter where name='sga_target';
	select value into l_spfile             from v$system_parameter where name='spfile';



	------------------------------------
	--// script upsert statements   //--
	------------------------------------
	dbms_output.put_line('        ca.databases_upsert('                                                                                    );
	dbms_output.put_line('                  in_dbid => '||l_dbid                                                                           );
	dbms_output.put_line('                , in_dbname => '''||l_dbname||''''                                                               );
	dbms_output.put_line('                , in_created => to_date('''||l_created||''',''YYYYMMDD HH24MISS'')'                              );
	dbms_output.put_line('                , in_log_mode => '''||l_log_mode||''''                                                           );
	-- dbms_output.put_line('                , in_cdb => '''||l_cdb||''''                                                                     );
	-- dbms_output.put_line('                , in_con_id => '||l_con_id                                                                       );
	-- dbms_output.put_line('                , in_con_dbid => '||l_con_dbid                                                                   );
	dbms_output.put_line('                , in_host_name => '''||l_host_name||''''                                                         );
	dbms_output.put_line('                , in_version => '''||l_version||''''                                                             );
	-- dbms_output.put_line('                , in_edition => '''||l_edition||''''                                                             );
	dbms_output.put_line('                , in_oracle_home => '''||l_oracle_home||''''                                                     );
	dbms_output.put_line('                , in_archive_lag_target => '||l_archive_lag_target                                               );
	dbms_output.put_line('                , in_compatible => '''||l_compatible||''''                                                       );
	dbms_output.put_line('                , in_control_files => '''||l_control_files||''''                                                 );
	dbms_output.put_line('                , in_cpu_count => '||l_cpu_count                                                                 );
	dbms_output.put_line('                , in_db_block_size => '||l_db_block_size                                                         );
	dbms_output.put_line('                , in_memory_max_target => '||l_memory_max_target                                                 );
	dbms_output.put_line('                , in_memory_target => '||l_memory_target                                                         );
	dbms_output.put_line('                , in_processes => '||l_processes                                                                 );
	dbms_output.put_line('                , in_sga_max_size => '||l_sga_max_size                                                           );
	-- dbms_output.put_line('                , in_sga_min_size => '||l_sga_min_size                                                           );
	dbms_output.put_line('                , in_sga_target => '||l_sga_target                                                               );
	dbms_output.put_line('                , in_spfile => '''||l_spfile||''''                                                               );
	dbms_output.put_line('                , in_entry_time => to_date('''||to_char(sysdate,'YYYYMMDD HH24MISS')||''',''YYYYMMDD HH24MISS'')');
	dbms_output.put_line('        );'||chr(10)                                                                                             );
END;
/

spool off
exit