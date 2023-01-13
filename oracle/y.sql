BEGIN
        ca.databases_upsert(
                  in_dbid => 87905393
                , in_dbname => 'JDRF02'
                , in_created => to_date('20220825 091634','YYYYMMDD HH24MISS')
                , in_log_mode => 'NOARCHIVELOG'
                , in_cdb => 'NO'
                , in_con_id => 0
                , in_con_dbid => 87905393
                , in_host_name => 'dcc-ora-xf-001'
                , in_version => '19.0.0.0.0'
                , in_edition => 'EE'
                , in_oracle_home => '/orahome/19.15.0.0.220419'
                , in_archive_lag_target => 900
                , in_compatible => '19.0.0'
                , in_control_files => '/oradb/jdrf02/redo/controlfile/control01.ctl, /oradb/jdrf02/redo/controlfile/control02.ctl'
                , in_cpu_count => 48
                , in_db_block_size => 8192
                , in_memory_max_target => 0
                , in_memory_target => 0
                , in_processes => 200
                , in_sga_max_size => 8589934592
                , in_sga_target => 8589934592
                , in_spfile => '/orahome/19.15.0.0.220419/dbs/spfilejdrf02.ora'
                , in_entry_time => to_date('20220902 144543','YYYYMMDD HH24MISS')
        );

        ca.databases_upsert(
                  in_dbid => 3783313587
                , in_dbname => 'JDRF01'
                , in_created => to_date('20220526 123434','YYYYMMDD HH24MISS')
                , in_log_mode => 'NOARCHIVELOG'
                , in_cdb => 'NO'
                , in_con_id => 0
                , in_con_dbid => 3783313587
                , in_host_name => 'dcc-ora-xf-001'
                , in_version => '19.0.0.0.0'
                , in_edition => 'EE'
                , in_oracle_home => '/orahome/19.15.0.0.220419'
                , in_archive_lag_target => 900
                , in_compatible => '19.0.0'
                , in_control_files => '/oradb/jdrf01/redo/controlfile/control01.ctl, /oradb/jdrf01/redo/controlfile/control02.ctl'
                , in_cpu_count => 48
                , in_db_block_size => 8192
                , in_memory_max_target => 0
                , in_memory_target => 0
                , in_processes => 200
                , in_sga_max_size => 8589934592
                , in_sga_target => 8589934592
                , in_spfile => '/orahome/19.15.0.0.220419/dbs/spfilejdrf01.ora'
                , in_entry_time => to_date('20220902 144752','YYYYMMDD HH24MISS')
        );
END;
/
