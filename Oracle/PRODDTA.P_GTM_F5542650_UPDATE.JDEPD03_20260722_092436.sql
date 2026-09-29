
  CREATE OR REPLACE EDITIONABLE PROCEDURE "PRODDTA"."P_GTM_F5542650_UPDATE" IS

/**********************************************************************************

	Program Name    : p_gtm_f5542650_upd
	
	Description     : Temporary procedure to fix GTM bug causing indefinite hold
	
	Date written    : 15-Jul-2024
	
	Author          : Kyle Floros

	Initial CHG     : EMERGENCY
	
*********************************************************************************/

    -- Audit variables.
    v_upd_pid                 VARCHAR2(10);   --Program ID
    v_upd_user                VARCHAR2(10);   --User ID
    v_upd_upmj                NUMBER(6);      --Date - Updated
    v_upd_upmt                NUMBER(6);      --Time - Last Updated

    -- Exception logic variables.
    v_err_job_name            VARCHAR2(30);
    v_err_nbr                 VARCHAR2(10);
    v_err_msg                 VARCHAR2(2000);

BEGIN
    -- Initialize variables.
    v_upd_pid            := 'STRDPROC';
    v_err_job_name       := 'P_GTM_F5542650_UPD';
    v_err_nbr            := NULL;
    v_err_msg            := NULL;

    -- Get Audit Information
    SELECT
        SUBSTR(SYS_CONTEXT('USERENV','HOST'), INSTR(SYS_CONTEXT('USERENV','HOST'), '\',1,1)+1,10)
       ,TO_NUMBER(TO_CHAR(SYSDATE,'yyyyddd')) - 1900000  --Julian date
       ,TO_NUMBER(TO_CHAR(SYSDATE,'hh24miss'))
    INTO
        v_upd_user
       ,v_upd_upmj
       ,v_upd_upmt
    FROM
        dual;

    -- Update records
    UPDATE
        proddta.f5542650
    SET
         ts$rsp = 'D'
        ,tspid  = v_upd_pid
        ,tsuser = v_upd_user
        ,tsupmj = v_upd_upmj
        ,tsupmt = v_upd_upmt
    WHERE
        tskcoo||tsdoco||tsdcto||tslnid
    IN
    (
        SELECT
            tskcoo||tsdoco||tsdcto||tslnid
        FROM
            proddta.f5542650
            JOIN proddta.f4211
                ON  tskcoo = sdkcoo
                AND tsdoco = sddoco
                AND tsdcto = sddcto
                AND tslnid = sdlnid
        WHERE
            ts$prcflg = 'Y'
            AND ts$rsp = 'S'
            AND tsqc04 = 'PASSED'
            AND tsqc05 = 'PASSED'
            AND tsqc06 = 'COMPLETE'
            AND tsqc07 = 'PASSED'
            AND tsqc08 = 'PASSED'
            AND sdnxtr < '561'
        GROUP BY
             tskcoo
            ,tsmcu
            ,tsdcto
            ,tsdoco
            ,tslnid
    );

	COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            v_err_nbr := SQLCODE;
            v_err_msg := SQLERRM;

            -- Rollback changes.
            ROLLBACK;

            INSERT INTO commobj.joberr
                ( job_name
                 ,err#
                 ,err_msg
                 ,TIMESTAMP)
            VALUES
                ( v_err_job_name
                 ,v_err_nbr
                 ,v_err_msg
                 ,SYSDATE);

            -- Commit commobj.joberr record to the database.
            COMMIT;

            RAISE_APPLICATION_ERROR(v_err_nbr, v_err_msg);

END p_gtm_f5542650_update;
/
