select
          patch_id
        , action
        , status
        , action_time
from
        dba_registry_sqlpatch
order by
        action_time;
