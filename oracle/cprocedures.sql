column obj format a50
column procedure_name format a30


select   object_type
       , subprogram_id
       , case when procedure_name is null then owner||'.'||object_name
              else owner||'.'||object_name||'.'||procedure_name
         end obj
from     dba_procedures
where    upper(owner)=upper('&owner')
order by object_name
       , subprogram_id;
