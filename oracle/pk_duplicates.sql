set echo off feedback off pages 0 trimout on

column table_name for a20
column duplicates for 999,999,999,999

select 'F0018' table_name, count(*) duplicates --a.tddoco, a.tddcto, a.tdkcoo, a.tdsfxo, a.tdlnid, a.tdupmj, a.tdupmt
from arcdta.f0018 a
join proddta.f0018@jdepd03_jlutsey t
on t.tddcto=a.tddcto and t.tddoco=a.tddoco and t.tdsfxo=a.tdsfxo and t.tdlnid=a.tdlnid and t.tdupmj=a.tdupmj and t.tdupmt=a.tdupmt and t.tdkcoo=a.tdkcoo;

select 'F03B11' table_name, count(*) duplicates --a.rpdoc, a.rpdct, a.rpkco, a.rpsfx
from arcdta.f03b11 a
join proddta.f03b11@jdepd03_jlutsey t
on t.rpdoc=a.rpdoc and t.rpdct=a.rpdct and t.rpkco=a.rpkco and t.rpsfx=a.rpsfx;

select 'F03B112' table_name, count(*) duplicates --a.rwdoc, a.rwdct, a.rwkco, a.rwsfx, a.rwsfxe
from arcdta.f03b112 a
join proddta.f03b112@jdepd03_jlutsey t
on t.rwdoc=a.rwdoc and t.rwdct=a.rwdct and t.rwkco=a.rwkco and t.rwsfx=a.rwsfx and t.rwsfxe=a.rwsfxe;

select 'F03B13' table_name, count(*) duplicates --a.rypyid
from arcdta.f03b13 a
join proddta.f03b13@jdepd03_jlutsey t
on t.rypyid=a.rypyid;

select 'F03B14' table_name, count(*) duplicates --a.rzpyid, a.rzrc5
from arcdta.f03b14 a
join proddta.f03b14@jdepd03_jlutsey t
on t.rzpyid=a.rzpyid and t.rzrc5=a.rzrc5;

select 'F0411' table_name, count(*) duplicates --a.rpdoc, a.rpdct, a.rpkco, a.rpsfx, a.rpsfxe
from arcdta.f0411 a
join proddta.f0411@jdepd03_jlutsey t
on t.rpkco=a.rpkco and t.rpdoc=a.rpdoc and t.rpdct=a.rpdct and t.rpsfx=a.rpsfx and t.rpsfxe=a.rpsfxe;

select 'F0413' table_name, count(*) duplicates --a.rmpyid
from arcdta.f0413 a
join proddta.f0413@jdepd03_jlutsey t
on t.rmpyid=a.rmpyid;

select 'F0414' table_name, count(*) duplicates --a.rnpyid, a.rnrc5
from arcdta.f0414 a
join proddta.f0414@jdepd03_jlutsey t
on t.rnpyid=a.rnpyid and t.rnrc5=a.rnrc5;

select 'F0911' table_name, count(*) duplicates --a.gldct, a.gldoc, a.glkco, a.gldgj, a.gljeln, a.gllt, a.glextl
from arcdta.f0911 a
join proddta.f0911@jdepd03_jlutsey t
on t.glkco=a.glkco and t.gldct=a.gldct and t.gldoc=a.gldoc and t.gldgj=a.gldgj and t.gljeln=a.gljeln and t.glextl=a.glextl and t.gllt=a.gllt;

select 'F3002' table_name, count(*) duplicates --a.ixkit, a.ixmmcu, a.ixtbm, a.ixbqty, a.ixcpnb, a.ixsbnt, a.ixcoby
from arcdta.f3002 a
join proddta.f3002@jdepd03_jlutsey t
on t.ixtbm=a.ixtbm and t.ixkit=a.ixkit and t.ixmmcu=a.ixmmcu and t.ixsbnt=a.ixsbnt and t.ixbqty=a.ixbqty and t.ixcoby=a.ixcoby and t.ixcpnb=a.ixcpnb;

select 'F3003' table_name, count(*) duplicates --a.irmmcu, a.irkit, a.irtrt, a.irbqty, a.iropsq, a.iropsc, a.irline, a.irefff
from arcdta.f3003 a
join proddta.f3003@jdepd03_jlutsey t
on t.irtrt=a.irtrt and t.irkit=a.irkit and t.irmmcu=a.irmmcu and t.irline=a.irline and t.iropsq=a.iropsq and t.irefff=a.irefff and t.irbqty=a.irbqty and t.iropsc=a.iropsc;

select 'F3003T' table_name, count(*) duplicates --a.irmmcu, a.irkit, a.irtrt, a.irbqty, a.iropsq, a.iropsc, a.irline, a.irefff
from arcdta.f3003t a
join proddta.f3003t@jdepd03_jlutsey t
on t.irtrt=a.irtrt and t.irkit=a.irkit and t.irmmcu=a.irmmcu and t.irline=a.irline and t.iropsq=a.iropsq and t.irefff=a.irefff and t.irbqty=a.irbqty and t.iropsc=a.iropsc;

select 'F3007' table_name, count(*) duplicates --a.wumcu, a.wuctry, a.wuyr, a.wumt, a.wummcu, a.wuum, a.wustyl, a.wushft
from arcdta.f3007 a
join proddta.f3007@jdepd03_jlutsey t
on t.wumcu=a.wumcu and t.wuyr=a.wuyr and t.wumt=a.wumt and t.wummcu=a.wummcu and t.wuum=a.wuum and t.wustyl=a.wustyl and t.wushft=a.wushft and t.wuctry=a.wuctry;

select 'F3011' table_name, count(*) duplicates --a.izmmcu, a.iztday, a.izkit, a.izbqty, a.iztbm, a.izcpnb, a.izsbnt, a.izupmj
from arcdta.f3011 a
join proddta.f3011@jdepd03_jlutsey t
on t.iztbm=a.iztbm and t.izkit=a.izkit and t.izmmcu=a.izmmcu and t.izsbnt=a.izsbnt and t.izbqty=a.izbqty and t.izupmj=a.izupmj and t.iztday=a.iztday and t.izcpnb=a.izcpnb;

select 'F3013' table_name, count(*) duplicates --a.cydoco, a.cypsq, a.cyrsq
from arcdta.f3013 a
join proddta.f3013@jdepd03_jlutsey t
on t.cydoco=a.cydoco and t.cypsq=a.cypsq and t.cyrsq=a.cyrsq;

select 'F3015' table_name, count(*) duplicates --a.cqukid
from arcdta.f3015 a
join proddta.f3015@jdepd03_jlutsey t
on t.cqukid=a.cqukid;

select 'F3102' table_name, count(*) duplicates --a.igdoco, a.igitm, a.igcost, a.igpart, a.igmcu
from arcdta.f3102 a
join proddta.f3102@jdepd03_jlutsey t
on t.igdoco=a.igdoco and t.igitm=a.igitm and t.igcost=a.igcost and t.igpart=a.igpart and t.igmcu=a.igmcu;

select 'F3102T' table_name, count(*) duplicates --a.igdoco, a.igpart, a.igitm, a.igcost
from arcdta.f3102t a
join proddta.f3102t@jdepd03_jlutsey t
on t.igdoco=a.igdoco and t.igitm=a.igitm and t.igcost=a.igcost and t.igpart=a.igpart;

select 'F3105' table_name, count(*) duplicates --a.isdoco, a.isdct, a.ismcu, a.islins
from arcdta.f3105 a
join proddta.f3105@jdepd03_jlutsey t
on t.isdoco=a.isdoco and t.isdct=a.isdct and t.ismcu=a.ismcu and t.islins=a.islins;

select 'F3106' table_name, count(*) duplicates --a.sdicut, a.sduser, a.sddoco, a.sddoc, a.sddgj
from arcdta.f3106 a
join proddta.f3106@jdepd03_jlutsey t
on t.sddoco=a.sddoco and t.sddoc=a.sddoc and t.sddgj=a.sddgj and t.sdicut=a.sdicut and t.sduser=a.sduser;

select 'F3111' table_name, count(*) duplicates --a.wmukid
from arcdta.f3111 a
join proddta.f3111@jdepd03_jlutsey t
on t.wmukid=a.wmukid;

select 'F3111T' table_name, count(*) duplicates --a.wmukid
from arcdta.f3111t a
join proddta.f3111t@jdepd03_jlutsey t
on t.wmukid=a.wmukid;

select 'F3112' table_name, count(*) duplicates --a.wldoco, a.wlopsq, a.wlopsc, a.wlmcu
from arcdta.f3112 a
join proddta.f3112@jdepd03_jlutsey t
on t.wldoco=a.wldoco and t.wlmcu=a.wlmcu and t.wlopsq=a.wlopsq and t.wlopsc=a.wlopsc;

select 'F31122' table_name, count(*) duplicates --a.wtukid
from arcdta.f31122 a
join proddta.f31122@jdepd03_jlutsey t
on t.wtukid=a.wtukid;

select 'F31122T' table_name, count(*) duplicates --a.wtukid
from arcdta.f31122t a
join proddta.f31122t@jdepd03_jlutsey t
on t.wtukid=a.wtukid;

select 'F3112T' table_name, count(*) duplicates --a.wldoco, a.wlopsq, a.wlopsc, a.wlmcu
from arcdta.f3112t a
join proddta.f3112t@jdepd03_jlutsey t
on t.wldoco=a.wldoco and t.wlopsq=a.wlopsq and t.wlopsc=a.wlopsc and t.wlmcu=a.wlmcu;

select 'F3112Z1' table_name, count(*) duplicates --a.szedus, a.szedbt, a.szedtn, a.szedln, a.szopsq, a.szopsc, a.szmcu
from arcdta.f3112z1 a
join proddta.f3112z1@jdepd03_jlutsey t
on t.szedus=a.szedus and t.szedbt=a.szedbt and t.szedtn=a.szedtn and t.szedln=a.szedln and t.szmcu=a.szmcu and t.szopsq=a.szopsq and t.szopsc=a.szopsc;

select 'F3118' table_name, count(*) duplicates --a.wnmmcu, a.wnitm, a.wndoco, a.wndcto, a.wndrqj, a.wnmcu
from arcdta.f3118 a
join proddta.f3118@jdepd03_jlutsey t
on t.wnmmcu=a.wnmmcu and t.wnitm=a.wnitm and t.wndoco=a.wndoco and t.wndcto=a.wndcto and t.wndrqj=a.wndrqj and t.wnmcu=a.wnmcu;

select 'F4006' table_name, count(*) duplicates --a.oadoco, a.oadcto, a.oakcoo, a.oaanty
from arcdta.f4006 a
join proddta.f4006@jdepd03_jlutsey t
on t.oadoco=a.oadoco and t.oadcto=a.oadcto and t.oakcoo=a.oakcoo and t.oaanty=a.oaanty;

select 'F4074' table_name, count(*) duplicates --a.aldoco, a.aldcto, a.alkcoo, a.alsfxo, a.allnid, a.alakid, a.alsrcfd, a.aloseq, a.alsubseq, a.altier, a.alpa04
from arcdta.f4074 a
join proddta.f4074@jdepd03_jlutsey t
on t.aldoco=a.aldoco and t.aldcto=a.aldcto and t.alkcoo=a.alkcoo and t.alsfxo=a.alsfxo and t.allnid=a.allnid and t.alakid=a.alakid and t.alsrcfd=a.alsrcfd and t.aloseq=a.aloseq and t.alsubseq=a.alsubseq and t.altier=a.altier and t.alpa04=a.alpa04;

select 'F4104' table_name, count(*) duplicates --a.ivitm, a.ivxrt, a.ivan8, a.ivcitm, a.ivexdj, a.ivcirv
from arcdta.f4104 a
join proddta.f4104@jdepd03_jlutsey t
on t.ivan8=a.ivan8 and t.ivxrt=a.ivxrt and t.ivitm=a.ivitm and t.ivexdj=a.ivexdj and t.ivcitm=a.ivcitm and t.ivcirv=a.ivcirv;

select 'F4111' table_name, count(*) duplicates --a.ilukid
from arcdta.f4111 a
join proddta.f4111@jdepd03_jlutsey t
on t.ilukid=a.ilukid;

select 'F4140' table_name, count(*) duplicates --a.picyno
from arcdta.f4140 a
join proddta.f4140@jdepd03_jlutsey t
on t.picyno=a.picyno;

select 'F4141' table_name, count(*) duplicates --a.pjcyno, a.pjlitm, a.pjmcu, a.pjlocn, a.pjlotn, a.pjstun
from arcdta.f4141 a
join proddta.f4141@jdepd03_jlutsey t
on t.pjcyno=a.pjcyno and t.pjlitm=a.pjlitm and t.pjmcu=a.pjmcu and t.pjlocn=a.pjlocn and t.pjlotn=a.pjlotn and t.pjstun=a.pjstun;

select 'F4209' table_name, count(*) duplicates --a.hohcod, a.hodcto, a.hodoco, a.hokcoo, a.hosfxo, a.holnid, a.hodlnid, a.hordj, a.hordt, a.hoasts, a.horper
from arcdta.f4209 a
join proddta.f4209@jdepd03_jlutsey t
on t.hohcod=a.hohcod and t.horper=a.horper and t.hokcoo=a.hokcoo and t.hodoco=a.hodoco and t.hodcto=a.hodcto and t.hosfxo=a.hosfxo and t.holnid=a.holnid and t.hordj=a.hordj and t.hordt=a.hordt and t.hoasts=a.hoasts and t.hodlnid=a.hodlnid;

select 'F42199' table_name, count(*) duplicates --a.sldoco, a.sldcto, a.slkcoo, a.sllnid, a.slupmj, a.sltday
from arcdta.f42199 a
join proddta.f42199@jdepd03_jlutsey t
on t.slkcoo=a.slkcoo and t.sldoco=a.sldoco and t.sldcto=a.sldcto and t.sllnid=a.sllnid and t.slupmj=a.slupmj and t.sltday=a.sltday;

select 'F4301' table_name, count(*) duplicates --a.phdoco, a.phdcto, a.phkcoo, a.phsfxo
from arcdta.f4301 a
join proddta.f4301@jdepd03_jlutsey t
on t.phkcoo=a.phkcoo and t.phdoco=a.phdoco and t.phdcto=a.phdcto and t.phsfxo=a.phsfxo;

select 'F43092' table_name, count(*) duplicates --a.pxdoco, a.pxdcto, a.pxkcoo, a.pxsfxo, a.pxlnid, a.pxnlin, a.pxuom, a.pxoprs
from arcdta.f43092 a
join proddta.f43092@jdepd03_jlutsey t
on t.pxkcoo=a.pxkcoo and t.pxdoco=a.pxdoco and t.pxdcto=a.pxdcto and t.pxsfxo=a.pxsfxo and t.pxlnid=a.pxlnid and t.pxnlin=a.pxnlin and t.pxoprs=a.pxoprs and t.pxuom=a.pxuom;

select 'F43099' table_name, count(*) duplicates --a.podoco, a.podcto, a.pokcoo, a.posfxo, a.polnid, a.ponlin, a.poupmj, a.potday, a.pomcde
from arcdta.f43099 a
join proddta.f43099@jdepd03_jlutsey t
on t.pokcoo=a.pokcoo and t.podoco=a.podoco and t.podcto=a.podcto and t.posfxo=a.posfxo and t.polnid=a.polnid and t.ponlin=a.ponlin and t.pomcde=a.pomcde and t.poupmj=a.poupmj and t.potday=a.potday;

select 'F4311' table_name, count(*) duplicates --a.pddoco, a.pddcto, a.pdkcoo, a.pdsfxo, a.pdlnid
from arcdta.f4311 a
join proddta.f4311@jdepd03_jlutsey t
on t.pdkcoo=a.pdkcoo and t.pddoco=a.pddoco and t.pddcto=a.pddcto and t.pdsfxo=a.pdsfxo and t.pdlnid=a.pdlnid;

select 'F4311T' table_name, count(*) duplicates --a.pdkcoo, a.pddoco, a.pddcto, a.pdsfxo, a.pdlnid
from arcdta.f4311t a
join proddta.f4311t@jdepd03_jlutsey t
on t.pdkcoo=a.pdkcoo and t.pddoco=a.pddoco and t.pddcto=a.pddcto and t.pdsfxo=a.pdsfxo and t.pdlnid=a.pdlnid;

select 'F43121' table_name, count(*) duplicates --a.prmatc, a.prdoco, a.prdcto, a.prkcoo, a.prsfxo, a.prlnid, a.prnlin, a.prdoc
from arcdta.f43121 a
join proddta.f43121@jdepd03_jlutsey t
on t.prmatc=a.prmatc and t.prkcoo=a.prkcoo and t.prdoco=a.prdoco and t.prdcto=a.prdcto and t.prsfxo=a.prsfxo and t.prlnid=a.prlnid and t.prnlin=a.prnlin and t.prdoc=a.prdoc;

select 'F43121T' table_name, count(*) duplicates --a.prmatc, a.prdoco, a.prdcto, a.prkcoo, a.prsfxo, a.prlnid, a.prnlin, a.prdoc
from arcdta.f43121t a
join proddta.f43121t@jdepd03_jlutsey t
on t.prmatc=a.prmatc and t.prkcoo=a.prkcoo and t.prdoco=a.prdoco and t.prdcto=a.prdcto and t.prlnid=a.prlnid and t.prnlin=a.prnlin and t.prdoc=a.prdoc and t.prsfxo=a.prsfxo;

select 'F4314' table_name, count(*) duplicates --a.jmdoco, a.jmdcto, a.jmkcoo, a.jmlnid, a.jmlins
from arcdta.f4314 a
join proddta.f4314@jdepd03_jlutsey t
on t.jmkcoo=a.jmkcoo and t.jmdoco=a.jmdoco and t.jmdcto=a.jmdcto and t.jmlnid=a.jmlnid and t.jmlins=a.jmlins;

select 'F4318' table_name, count(*) duplicates --a.pydoco, a.pydcto, a.pykcoo, a.pysfxo, a.pylnid
from arcdta.f4318 a
join proddta.f4318@jdepd03_jlutsey t
on t.pykcoo=a.pykcoo and t.pydoco=a.pydoco and t.pydcto=a.pydcto and t.pysfxo=a.pysfxo and t.pylnid=a.pylnid;

select 'F43199' table_name, count(*) duplicates --a.olukid
from arcdta.f43199 a
join proddta.f43199@jdepd03_jlutsey t
on t.olukid=a.olukid;

select 'F4332' table_name, count(*) duplicates --a.p2doco, a.p2dcto, a.p2kcoo, a.p2sfxo, a.p2lnid, a.p2oorn, a.p2octo, a.p2okco, a.p2ogno
from arcdta.f4332 a
join proddta.f4332@jdepd03_jlutsey t
on t.p2kcoo=a.p2kcoo and t.p2doco=a.p2doco and t.p2dcto=a.p2dcto and t.p2lnid=a.p2lnid and t.p2oorn=a.p2oorn and t.p2octo=a.p2octo and t.p2okco=a.p2okco and t.p2ogno=a.p2ogno and t.p2sfxo=a.p2sfxo;

select 'F4801' table_name, count(*) duplicates --a.wadoco
from arcdta.f4801 a
join proddta.f4801@jdepd03_jlutsey t
on t.wadoco=a.wadoco;

select 'F4801T' table_name, count(*) duplicates --a.wadoco
from arcdta.f4801t a
join proddta.f4801t@jdepd03_jlutsey t
on t.wadoco=a.wadoco;

select 'F4802' table_name, count(*) duplicates --a.wbdoco, a.wbdcto, a.wbsfxo, a.wbtypr, a.wblins
from arcdta.f4802 a
join proddta.f4802@jdepd03_jlutsey t
on t.wbdoco=a.wbdoco and t.wbdcto=a.wbdcto and t.wbsfxo=a.wbsfxo and t.wbtypr=a.wbtypr and t.wblins=a.wblins;

select 'F4818' table_name, count(*) duplicates --a.cbdoco, a.cbgrpg, a.cboseq
from arcdta.f4818 a
join proddta.f4818@jdepd03_jlutsey t
on t.cbdoco=a.cbdoco and t.cbgrpg=a.cbgrpg and t.cboseq=a.cboseq;

select 'F5531002' table_name, count(*) duplicates --a.wpmcu, a.wpdoco
from arcdta.f5531002 a
join proddta.f5531002@jdepd03_jlutsey t
on t.wpdoco=a.wpdoco and t.wpmcu=a.wpmcu;

select 'F5531003' table_name, count(*) duplicates --a.wpukid, a.wpdoco, a.wpmcu
from arcdta.f5531003 a
join proddta.f5531003@jdepd03_jlutsey t
on t.wpdoco=a.wpdoco and t.wpmcu=a.wpmcu and t.wpukid=a.wpukid;

select 'F5531005' table_name, count(*) duplicates --a.ilukid
from arcdta.f5531005 a
join proddta.f5531005@jdepd03_jlutsey t
on t.ilukid=a.ilukid;

select 'F5531033' table_name, count(*) duplicates --a.wmukid, a.wmupmj, a.wmtday
from arcdta.f5531033 a
join proddta.f5531033@jdepd03_jlutsey t
on t.wmupmj=a.wmupmj and t.wmtday=a.wmtday and t.wmukid=a.wmukid;

select 'F5531038' table_name, count(*) duplicates --a.cln001, a.cluser, a.cldoco
from arcdta.f5531038 a
join proddta.f5531038@jdepd03_jlutsey t
on t.cln001=a.cln001 and t.cluser=a.cluser and t.cldoco=a.cldoco;

select 'F5531051' table_name, count(*) duplicates --a.wm$refnum
from arcdta.f5531051 a
join proddta.f5531051@jdepd03_jlutsey t
on t.wm$refnum=a.wm$refnum;

select 'F5543011' table_name, count(*) duplicates --a.atdoco, a.atdcto, a.atkcoo, a.atsfxo, a.atlnid
from arcdta.f5543011 a
join proddta.f5543011@jdepd03_jlutsey t
on t.atdoco=a.atdoco and t.atdcto=a.atdcto and t.atkcoo=a.atkcoo and t.atsfxo=a.atsfxo and t.atlnid=a.atlnid;

select 'F5543022' table_name, count(*) duplicates --a.ermatc, a.erdoco, a.erdcto, a.erkcoo, a.ersfxo, a.erlnid, a.ernlin, a.erdoc
from arcdta.f5543022 a
join proddta.f5543022@jdepd03_jlutsey t
on t.ermatc=a.ermatc and t.erdoco=a.erdoco and t.erdcto=a.erdcto and t.erkcoo=a.erkcoo and t.ersfxo=a.ersfxo and t.erlnid=a.erlnid and t.ernlin=a.ernlin and t.erdoc=a.erdoc;

select 'F5543121' table_name, count(*) duplicates --a.rtmatc, a.rtdoco, a.rtdcto, a.rtkcoo, a.rtsfxo, a.rtlnid, a.rtnlin, a.rtdoc
from arcdta.f5543121 a
join proddta.f5543121@jdepd03_jlutsey t
on t.rtmatc=a.rtmatc and t.rtdoco=a.rtdoco and t.rtdcto=a.rtdcto and t.rtkcoo=a.rtkcoo and t.rtsfxo=a.rtsfxo and t.rtlnid=a.rtlnid and t.rtnlin=a.rtnlin and t.rtdoc=a.rtdoc;

select 'F5543122' table_name, count(*) duplicates --a.pwmatc, a.pwdoco, a.pwdcto, a.pwkcoo, a.pwsfxo, a.pwlnid, a.pwnlin, a.pwdoc
from arcdta.f5543122 a
join proddta.f5543122@jdepd03_jlutsey t
on t.pwmatc=a.pwmatc and t.pwdoco=a.pwdoco and t.pwdcto=a.pwdcto and t.pwkcoo=a.pwkcoo and t.pwsfxo=a.pwsfxo and t.pwlnid=a.pwlnid and t.pwnlin=a.pwnlin and t.pwdoc=a.pwdoc;

select 'F5543123' table_name, count(*) duplicates --a.ncmatc, a.ncdoco, a.ncdcto, a.nckcoo, a.ncsfxo, a.nclnid, a.ncnlin, a.ncdoc
from arcdta.f5543123 a
join proddta.f5543123@jdepd03_jlutsey t
on t.ncmatc=a.ncmatc and t.ncdoco=a.ncdoco and t.ncdcto=a.ncdcto and t.nckcoo=a.nckcoo and t.ncsfxo=a.ncsfxo and t.nclnid=a.nclnid and t.ncnlin=a.ncnlin and t.ncdoc=a.ncdoc;

select 'F554312T' table_name, count(*) duplicates --a.rtmatc, a.rtdoco, a.rtdcto, a.rtkcoo, a.rtsfxo, a.rtlnid, a.rtnlin, a.rtdoc
from arcdta.f554312t a
join proddta.f554312t@jdepd03_jlutsey t
on t.rtmatc=a.rtmatc and t.rtdoco=a.rtdoco and t.rtdcto=a.rtdcto and t.rtkcoo=a.rtkcoo and t.rtsfxo=a.rtsfxo and t.rtlnid=a.rtlnid and t.rtnlin=a.rtnlin and t.rtdoc=a.rtdoc;

select 'F5543199' table_name, count(*) duplicates --a.ltdoco, a.ltdcto, a.ltkcoo, a.ltsfxo, a.ltlnid, a.ltlt, a.ltcord, a.ltupmj, a.lttday
from arcdta.f5543199 a
join proddta.f5543199@jdepd03_jlutsey t
on t.ltdoco=a.ltdoco and t.ltdcto=a.ltdcto and t.ltkcoo=a.ltkcoo and t.ltsfxo=a.ltsfxo and t.ltlnid=a.ltlnid and t.ltlt=a.ltlt and t.ltcord=a.ltcord and t.ltupmj=a.ltupmj and t.lttday=a.lttday;

select 'F5548002' table_name, count(*) duplicates --a.wldoco
from arcdta.f5548002 a
join proddta.f5548002@jdepd03_jlutsey t
on t.wldoco=a.wldoco;
