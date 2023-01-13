set linesize 200

col parameter format a40 wrap
col description format a60 wrap
col session_value format a15 wrap
col instance_value format a15 wrap

SELECT   a.ksppinm  AS parameter,
         a.ksppdesc AS description,
         b.ksppstvl AS session_value,
         c.ksppstvl AS instance_value
FROM     x$ksppi  a
JOIN     x$ksppcv b on a.indx = b.indx
JOIN     x$ksppsv c on a.indx = c.indx
WHERE    a.ksppinm LIKE '%extended_cursor%'
ORDER BY a.ksppinm;


/*

-- disable ECS
alter system set "_optimizer_extended_cursor_sharing_rel" = none;
alter system set "_optimizer_extended_cursor_sharing" = none;

-- rollback
alter system set "_optimizer_extended_cursor_sharing_rel" = simple;
alter system set "_optimizer_extended_cursor_sharing" = udo; 

*/

gcc-ora-pd-005