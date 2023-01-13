
column policy_name           format a30
column entity_names          format a30
column success               format a7
column failure               format a7


/* get the names and enabled options of unified audit policies */
select    n.policy_name
        , e.enabled_option
        , listagg(e.entity_name,', ') within group (order by e.entity_name) entity_names
        , e.success
        , e.failure
from      (  select   policy_name
             from     audit_unified_policies
             group by policy_name
          ) n
left join audit_unified_enabled_policies e on n.policy_name=e.policy_name
group by  n.policy_name
        , e.enabled_option
        , e.success
        , e.failure
order by  n.policy_name
        , e.enabled_option;
