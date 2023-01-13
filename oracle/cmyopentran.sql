select t.status
from   v$transaction t
join   v$session     s on t.ses_addr = s.saddr
where  s.sid = sys_context('USERENV', 'SID');
