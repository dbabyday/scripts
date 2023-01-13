select text
from   dba_source
where  owner='&owner'
       and name='&name'
       and type='&type'
       and line=&line;