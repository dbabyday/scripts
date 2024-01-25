column release_update format a20

select
          case
          	when patch_id in (35042068,35050341) then '19.19.0.0.230418'
          	else ''
          end release_update
        , patch_id
        , action
        , status
        , to_char(action_time,'DD Month YYYY') action_date
from
        dba_registry_sqlpatch
order by
        action_time;

