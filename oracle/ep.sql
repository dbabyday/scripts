set linesize 200 pagesize 10000
explain plan for
DELETE FROM proddta.F5541046 WHERE ZW$SN50 = 'KD0753001PXA002109' AND ZWCO = '00080' AND ZWMCU = '         800' AND ZWSRL1 = 'KD0753001PXA002109' AND ZWLITM = 'KD0753001-780'
;
select * from table(dbms_xplan.display);
rollback;
