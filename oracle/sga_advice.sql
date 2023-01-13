column gb format 9999.9

SELECT   sga_size
       , sga_size/1024 gb
       , sga_size_factor
       , estd_db_time_factor
FROM     v$sga_target_advice
ORDER BY sga_size ASC;

