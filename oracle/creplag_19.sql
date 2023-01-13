set feedback off


prompt ;
prompt ==================================;
prompt ==// CURRENT LAG              //==;
prompt ==================================;
prompt ;

column source_db format a9
column target_db format a9
column incoming_path format a25

select   remote_database source_db
       , local_database  target_db
       , incoming_path
       , round(incoming_lag/60,0) incoming_lag_minutes
--       , round(incoming_lag/3600,1) incoming_lag_hours
from     gg_adm.gg_lag
order by incoming_path;




prompt ;
prompt ;
prompt ;
prompt ==================================;
prompt ==// LAG HISTORY              //==;
prompt ==//     - past 24 hours      //==;
prompt ==//     - lag > 10 minutes   //==;
prompt ==================================;
prompt ;

set termout off
column extract   format a7
column data_pump format a9
column replicat  format a8

column offset new_value _OFFSET noprint;
select case when substr(tz_offset(sessiontimezone),1,1) = '-' and substr(tz_offset(sessiontimezone),5,2) = '30' then to_number('-' || substr(tz_offset(sessiontimezone),2,2) || '.5')
            when substr(tz_offset(sessiontimezone),1,1) = '+' and substr(tz_offset(sessiontimezone),5,2) = '30' then to_number(       substr(tz_offset(sessiontimezone),2,2) || '.5')
            when substr(tz_offset(sessiontimezone),1,1) = '-' and substr(tz_offset(sessiontimezone),5,2) = '00' then to_number('-' || substr(tz_offset(sessiontimezone),2,2)        )
            when substr(tz_offset(sessiontimezone),1,1) = '+' and substr(tz_offset(sessiontimezone),5,2) = '00' then to_number(       substr(tz_offset(sessiontimezone),2,2)        )
       end offset
from   dual;
set termout on

/* https://www.ateam-oracle.com/oracle-goldengate-integrated-heartbeat */
select   to_char(heartbeat_received_ts + numtodsinterval(&&_OFFSET/24,'day'),'YYYY-MM-DD HH24:MI:SS') heartbeat_received
       , round((extract(day from (heartbeat_received_ts - incoming_heartbeat_ts))*24*60*60 + extract(hour from (heartbeat_received_ts - incoming_heartbeat_ts))*60*60 + extract(minute from (heartbeat_received_ts - incoming_heartbeat_ts))*60 + extract(second from (heartbeat_received_ts - incoming_heartbeat_ts)))/60,0) total_lag_minutes
       , incoming_extract extract
       , round((extract(day from (incoming_extract_ts - incoming_heartbeat_ts))*24*60*60 + extract(hour from (incoming_extract_ts - incoming_heartbeat_ts))*60*60 + extract(minute from (incoming_extract_ts - incoming_heartbeat_ts))*60 + extract(second from (incoming_extract_ts - incoming_heartbeat_ts)))/60,0) extract_lag
       , incoming_routing_path data_pump
       , round((extract(day from (incoming_routing_ts - incoming_extract_ts))*24*60*60 + extract(hour from (incoming_routing_ts - incoming_extract_ts))*60*60 + extract(minute from (incoming_routing_ts - incoming_extract_ts))*60 + extract(second from (incoming_routing_ts - incoming_extract_ts)))/60,0) data_pump_read_lag
       , incoming_replicat replicat
       , round((extract(day from (incoming_replicat_ts - incoming_routing_ts))*24*60*60 + extract(hour from (incoming_replicat_ts - incoming_routing_ts))*60*60 + extract(minute from (incoming_replicat_ts - incoming_routing_ts))*60 + extract(second from (incoming_replicat_ts - incoming_routing_ts)))/60,0) replicat_read_lag
       , round((extract(day from (heartbeat_received_ts - incoming_replicat_ts))*24*60*60 + extract(hour from (heartbeat_received_ts - incoming_replicat_ts))*60*60 + extract(minute from (heartbeat_received_ts - incoming_replicat_ts))*60 + extract(second from (heartbeat_received_ts - incoming_replicat_ts)))/60,0) replicat_apply_lag
from     gg_adm.gg_heartbeat_history
where    heartbeat_received_ts > systimestamp+numtodsinterval(-1/24,'day') /*records for past 1 day*/
         -- and incoming_replicat='RPYA'
         and 10 < /*total_lag_min*/ (extract(day from (heartbeat_received_ts - incoming_heartbeat_ts))*24*60*60 + extract(hour from (heartbeat_received_ts - incoming_heartbeat_ts))*60*60 + extract(minute from (heartbeat_received_ts - incoming_heartbeat_ts))*60 + extract(second from (heartbeat_received_ts - incoming_heartbeat_ts)))/60
order by heartbeat_received_ts desc
/




prompt ;

undefine _OFFSET
set feedback on