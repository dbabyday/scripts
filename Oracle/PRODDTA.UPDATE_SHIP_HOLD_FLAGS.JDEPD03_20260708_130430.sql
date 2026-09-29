
  CREATE OR REPLACE EDITIONABLE PROCEDURE "PRODDTA"."UPDATE_SHIP_HOLD_FLAGS" AS
	v_rows_updated NUMBER := 0;
BEGIN
	MERGE INTO PRODDTA.F5542650 target
	USING (
		SELECT B.rowid AS row_id
		FROM PRODDTA.F4211 A
		JOIN PRODDTA.F5542650 B
			ON A.SDDOCO = B.TSDOCO
			AND A.SDDCTO = B.TSDCTO
			AND A.SDLNID = B.TSLNID
		WHERE A.SDNXTR = '560'
			AND B.TS$PRCFLG = ' '
	) src
	ON (target.rowid = src.row_id)
	WHEN MATCHED THEN
		UPDATE SET target.TS$PRCFLG = 'Y', target.TS$RSP = 'D';

	v_rows_updated := SQL%ROWCOUNT;

	COMMIT;

	DBMS_OUTPUT.PUT_LINE('Successfully updated ' || v_rows_updated || ' records.');

EXCEPTION
	WHEN OTHERS THEN
		ROLLBACK;
		DBMS_OUTPUT.PUT_LINE('Error encountered: ' || SQLERRM);
		RAISE;
END;


1 row selected.

