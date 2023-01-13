set long 100000
set lines 10000
set pages 10000
set trimout on
set trimspool on
col sql_fulltext format a1000

spool csqls.log

select sql_id,sql_fulltext from v$sql where sql_id in (
 '06zua6fybz820'
,'0bubznzs8ts6t'
,'0kaykr76au1fj'
,'12scyzv2rrpyt'
,'1h5fb614gju0q'
,'1kthqdu5puxyc'
,'2022mhbg8y9dx'
,'269mm5rya6hu5'
,'3606vwbknmcmg'
,'36mbfg2tku4t2'
,'3kjg7tucth0b5'
,'40tua6upz7rdj'
,'4h34zs3z3r0cf'
,'4nqyavanrnnnq'
,'4rqb8rqv26qpx'
,'5acn785sktr31'
,'5kq7av377923v'
,'5xnxjjaygn9uk'
,'5zup2nbg5h94u'
,'61qb4auhuj52v'
,'6589hp2f2hbm8'
,'6crwqzvuct3rk'
,'6g41gmbqrp5tk'
,'70spgjya5f9f7'
,'7rpwvsrrwxf6s'
,'7safua20n2bna'
,'7t3n0audkfwuh'
,'7tps63wnnw6ru'
,'813x02pz610a8'
,'86vrr9gzu7vv4'
,'87huxbyjzqnn1'
,'87k39qjpdj6vj'
,'8ayamar1ckcv5'
,'8ffbdhku0tmhq'
,'8p563ppcm4snk'
,'8tmk5fdfn050x'
,'937gsm7cd3k0w'
,'98d8sun9cbzmq'
,'9a8vndr2haphh'
,'9jtgqdfuxwyzf'
,'ag3fz0ugw7ktv'
,'ar2w74srbah5k'
,'atft82kwus0ff'
,'au7rx86133v78'
,'b919tvr027ffq'
,'c35wqvmdh4bmm'
,'cc02wfjcrbavy'
,'cubtbv8r24mqs'
,'du4rjbfyngmxq'
,'dz6ry941b2x2q'
,'fb53g0cqr20yw'
,'fhft6nkb7w944'
,'fxag7bkxyu9w1'
,'ghzpny5zqg73k'
,'gtaq9z74g2j38'
)
order by sql_id;

spool off
