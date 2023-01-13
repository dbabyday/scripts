set linesize 300
set pagesize 5000
set trimspool on
column "00" format 99
column "01" format 99
column "02" format 99
column "03" format 99
column "04" format 99
column "05" format 99
column "06" format 99
column "07" format 99
column "08" format 99
column "09" format 99
column "10" format 99
column "11" format 99
column "12" format 99
column "13" format 99
column "14" format 99
column "15" format 99
column "16" format 99
column "17" format 99
column "18" format 99
column "19" format 99
column "20" format 99
column "21" format 99
column "22" format 99
column "23" format 99
column "Day" format a3

prompt
prompt Redo Log Switches
prompt

SELECT
	  to_char (trunc (first_time),'YYYY-MM-DD') "Date"
	, to_char (trunc (first_time),'Dy') "Day"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 0, 1)) "00"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 1, 1)) "01"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 2, 1)) "02"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 3, 1)) "03"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 4, 1)) "04"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 5, 1)) "05"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 6, 1)) "06"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 7, 1)) "07"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 8, 1)) "08"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 9, 1)) "09"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 10, 1)) "10"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 11, 1)) "11"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 12, 1)) "12"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 13, 1)) "13"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 14, 1)) "14"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 15, 1)) "15"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 16, 1)) "16"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 17, 1)) "17"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 18, 1)) "18"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 19, 1)) "19"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 20, 1)) "20"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 21, 1)) "21"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 22, 1)) "22"
	, sum (decode (to_number (to_char (first_time, 'HH24')), 23, 1)) "23"
from
	v$log_history
-- where
-- 	trunc (first_time) >= trunc (sysdate) - 14 -- last X days. 0 = today only. 1 = today and yesterday
group by
	trunc (first_time)
order by
	trunc (first_time) desc;