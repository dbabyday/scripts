prompt
prompt UNDO sizing report
prompt ==================
prompt 
prompt Reports current undo set up, and minimum/maximum required undo tablespace size based on historical AWR data
prompt
prompt Note:
prompt   a) if your undo datafiles are not fixed size (all of them), you are doing it wrong most likely
prompt   b) awr_snapshots_count is used as a period to calculate maximum required undo size with guaranteed undo retention
prompt   c) there is no way to calculate sufficient undo size with a good precision and this report is an approximation
prompt 
prompt For feedback mailto:timur.akhmadeev@gmail.com
prompt
 
col inst_id                         format 99 head 'In|st'
col current_size_mb                 format 999,999,999 head 'Current|undo, MB'
col is_autoextensible               format a4 head 'Auto|ext?'
col undo_retention                  format 999.9 head 'Retention|hours'
col undo_size_min_mb                format 999,999,999 head 'Minimumal|req UNDO, MB'
col undo_size_guarantee_mb          format 999,999,999 head 'Max req|UNDO, MB'
col longest_sql                     format 999,999.9 head 'Longest|SQL, h'
col longest_sql_id                  format a13 head 'Longest|sql_id'
col max_ora1555_cnt                 format 999,999 head 'Max ORA-|1555 cnt'
col max_no_space_cnt                format 999,999 head 'Max no|space cnt'
 
select
  ua.inst_id,
  ua.current_size_mb,
  ua.is_autoextensible,
  ua.undo_retention/3600 undo_retention,
  um.undo_size_min_mb,
  u.undo_size_guarantee_mb,
  um.longest_sql/3600 longest_sql,
  um.longest_sql_id,
  um.max_ora1555_cnt,
  um.max_no_space_cnt
from
  gv$parameter p,
  ( -- how much undo is required to guarantee undo retention for awr_snapshots_count period
    select
      inst_id,
      max(required_undo_mb) undo_size_guarantee_mb
    from
    (
      select
        inst_id,
        sum(undo_size) over (partition by inst_id order by begin_interval_time rows &awr_snapshots_count preceding) required_undo_mb
      from
      (     
        select
          s.instance_number inst_id,
          s.begin_interval_time,
          round((ss.value - lag(ss.value) over (partition by s.instance_number order by s.begin_interval_time))/1024/1024) undo_size
        from
          dba_hist_snapshot s,
          v$database d,
          dba_hist_sysstat ss,
          v$statname n
        where
          s.dbid = d.dbid and
          s.dbid = ss.dbid and
          s.instance_number = ss.instance_number and
          s.snap_id = ss.snap_id and
          ss.stat_id = n.stat_id and
          n.name = 'undo change vector size'
      )
    )
    group by inst_id
  ) u,
  ( -- minimally required undo as max active blocks
    select
      uh.instance_number inst_id,
      max(activeblks * p.value/1024/1024) undo_size_min_mb,
      max(maxquerylen) longest_sql,
      max(maxquerysqlid) keep (dense_rank first order by maxquerylen desc) longest_sql_id,
      max(ssolderrcnt) max_ora1555_cnt,
      max(nospaceerrcnt) max_no_space_cnt
    from
      dba_hist_snapshot s,
      v$database d,
      dba_hist_undostat uh,
      v$parameter p
    where
      s.dbid = d.dbid and
      s.dbid = uh.dbid and
      s.instance_number = uh.instance_number and
      s.snap_id = uh.snap_id and
      p.name = 'db_block_size'
    group by
      uh.instance_number
  ) um,
  ( -- current undo setup
    select
      p.inst_id,
      round(sum(bytes)/1024/1024) current_size_mb,
      max(t.autoextensible) is_autoextensible,
      max(ur.value) undo_retention
    from
      dba_data_files t, 
      gv$parameter p,
      (select inst_id, value from gv$parameter where name = 'undo_retention') ur
    where
      t.tablespace_name = p.value and
      p.name = 'undo_tablespace' and
      p.inst_id = ur.inst_id
    group by
      p.inst_id
  ) ua
where
  p.inst_id = u.inst_id and
  p.name = 'undo_retention' and
  u.inst_id = ua.inst_id and
  ua.inst_id = um.inst_id
;