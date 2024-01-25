set echo off feedback off pages 0 trimout on

column table_name for a20
column duplicates for 999,999,999,999

select 'F0911' table_name, count(*) duplicates --a.gldct, a.gldoc, a.glkco, a.gldgj, a.gljeln, a.gllt, a.glextl
from arcdta.f0911 a
join proddta.f0911@jdepd03_jlutsey t
on t.glkco=a.glkco and t.gldct=a.gldct and t.gldoc=a.gldoc and t.gldgj=a.gldgj and t.gljeln=a.gljeln and t.glextl=a.glextl and t.gllt=a.gllt;

