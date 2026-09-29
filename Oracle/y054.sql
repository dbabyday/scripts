        ca.databases_upsert(
                  in_dbid => 1641275879
                , in_dbname => 'AGLPRD01'
                , in_created => to_date('20160717 082407','YYYYMMDD HH24MISS')
                , in_log_mode => 'ARCHIVELOG'
                , in_cdb => 'NO'
                , in_con_id => 0
                , in_con_dbid => 1641275879
                , in_host_name => 'co-db-054'
                , in_version => '12.1.0.2.0'
                , in_edition => 'EE'
                , in_oracle_home => '/oracle/12.1.0.2.190716'
                , in_archive_lag_target => 900
                , in_compatible => '12.0.0'
                , in_control_files => '/archive1/aglprd01/controlfile/ctl01aglprd01.ctl, /archive2/aglprd01/controlfile/ctl02aglprd01.ctl, /db/aglprd01/controlfile/ctl03aglprd01.ctl'
                , in_cpu_count => 64
                , in_db_block_size => 8192
                , in_memory_max_target => 0
                , in_memory_target => 0
                , in_processes => 350
                , in_sga_max_size => 8589934592
                , in_sga_target => 8589934592
                , in_spfile => '/oracle/12.1.0.2.190716/dbs/spfileaglprd01.ora'
                , in_entry_time => to_date('20220606 125913','YYYYMMDD HH24MISS')
        );

        ca.databases_upsert(
                  in_dbid => 2227778854
                , in_dbname => 'AGLQA01'
                , in_created => to_date('20220602 131616','YYYYMMDD HH24MISS')
                , in_log_mode => 'ARCHIVELOG'
                , in_cdb => 'NO'
                , in_con_id => 0
                , in_con_dbid => 2227778854
                , in_host_name => 'co-db-054'
                , in_version => '12.1.0.2.0'
                , in_edition => 'EE'
                , in_oracle_home => '/oracle/12.1.0.2.190716'
                , in_archive_lag_target => 900
                , in_compatible => '12.0.0'
                , in_control_files => '/archive1/aglqa01/controlfile/ctl01aglqa01.ctl, /archive2/aglqa01/controlfile/ctl02aglqa01.ctl, /db/aglqa01/controlfile/ctl03aglqa01.ctl'
                , in_cpu_count => 64
                , in_db_block_size => 8192
                , in_memory_max_target => 0
                , in_memory_target => 0
                , in_processes => 350
                , in_sga_max_size => 4294967296
                , in_sga_target => 4294967296
                , in_spfile => '/oracle/12.1.0.2.190716/dbs/spfileaglqa01.ora'
                , in_entry_time => to_date('20220606 130021','YYYYMMDD HH24MISS')
        );

        ca.databases_upsert(
                  in_dbid => 1641275879
                , in_dbname => 'AGLRO01'
                , in_created => to_date('20220606 070312','YYYYMMDD HH24MISS')
                , in_log_mode => 'NOARCHIVELOG'
                , in_cdb => 'NO'
                , in_con_id => 0
                , in_con_dbid => 1641275879
                , in_host_name => 'co-db-054'
                , in_version => '12.1.0.2.0'
                , in_edition => 'EE'
                , in_oracle_home => '/oracle/12.1.0.2.190716'
                , in_archive_lag_target => 0
                , in_compatible => '12.0.0'
                , in_control_files => '/archive1/aglro01/controlfile/ctl01aglro01.ctl, /archive2/aglro01/controlfile/ctl02aglro01.ctl, /db/aglro01/controlfile/ctl03aglro01.ctl'
                , in_cpu_count => 64
                , in_db_block_size => 8192
                , in_memory_max_target => 0
                , in_memory_target => 0
                , in_processes => 350
                , in_sga_max_size => 1979711488
                , in_sga_target => 0
                , in_spfile => ''
                , in_entry_time => to_date('20220606 130053','YYYYMMDD HH24MISS')
        );

