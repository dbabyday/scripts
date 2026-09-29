
  CREATE OR REPLACE EDITIONABLE PROCEDURE "PRODDTA"."P_EINV_MY_CNOTE_INSERT" PROCEDURE	        P_EINV_MY_CNOTE_INSERT IS

/**********************************************************************************

	Program Name    :   P_EINV_MY_CNOTE_INSERT
	
	Description     :   This procedure is used for E-Invoicing Malaysia.  It will
                        insert credit note records into F550301H and F550301D
	
	Date written    :   25-Jul-2024
	
	Author          :   Kyle Floros

    Change Log      :

        CHG093908 - 01-Aug-2024 - New

        CHG094158 - 23-Aug-2024 - Kyle Floros
            - Enter X for EV03 (QR Code Status Flag) if Buyer County <> MY

        CHG095872 - 06-Dec-2024 - Kyle Floros
            - Load invoice date into URDT

        CHG096837 - 28-Jan-2025 - Kyle Floros / Bill Chermak
            - Exclude SO/S1+DO billing
	
**********************************************************************************/

    ------------------------------------------------------
    -- Declare Exception Variables
    ------------------------------------------------------
    v_err_job_name          VARCHAR2(30)        := 'P_EINV_MY_CNOTE_INSERT';
    v_err_nbr               VARCHAR2(10)        := ' ';
    v_err_msg               VARCHAR2(2000)      := ' ';

    ------------------------------------------------------
    -- Declare Audit Variables
    ------------------------------------------------------
    v_pid                   VARCHAR2(10)        := 'EI_MY_CN';
    v_jobn                  VARCHAR2(10)        := '';
    v_user                  VARCHAR2(10)        := 'STRDPROC';
    v_upmj                  NUMBER(6)           := 0;
    v_upmt                  NUMBER(6)           := 0;

    ------------------------------------------------------
    -- Declare Cursor Variables
    ------------------------------------------------------
    v_ar_doc                NUMBER          :=  0;
    v_ar_dct                CHAR(2 BYTE)    :=  ' ';
    v_ar_kco                CHAR(5 BYTE)    :=  ' ';
    v_ar_dgj                NUMBER          :=  0;
    v_ar_ptc                CHAR(3 BYTE)    :=  ' ';
    v_sod_doco              NUMBER          :=  0;
    v_sod_dcto              CHAR(2 BYTE)    :=  ' ';
    v_sod_kcoo              CHAR(5 BYTE)    :=  ' ';
    v_sod_lnid              NUMBER          :=  0;
    v_sod_itm               NUMBER          :=  0;
    v_seller_an8            NUMBER          :=  0;
    v_buyer_an8             NUMBER          :=  0;
    v_buyer_tax             CHAR(20 BYTE)   :=  ' ';
    v_buyer_ctr             CHAR(3 BYTE)    :=  ' ';
    v_tax_rate_efdj         NUMBER          :=  0;

    ------------------------------------------------------
    -- Declare Other Variables
    ------------------------------------------------------
    v_detail_line_counter   NUMBER          :=  0;
    v_batch_id              NUMBER          :=  0;
    v_previous_invoice      NUMBER          :=  0;
    v_previous_buyer_ctr    CHAR(3 BYTE)    :=  ' ';
    v_first_loop            BOOLEAN         :=  TRUE;
    v_records_found         BOOLEAN         :=  FALSE;
    v_records_found_overall BOOLEAN         :=  FALSE;


    ------------------------------------------------------
    -- Declare Cursor Variables
    ------------------------------------------------------
    CURSOR c_records IS
        SELECT
             AR_Detail.rpdoc
            ,AR_Detail.rpdct
            ,AR_Detail.rpkco
            ,AR_Detail.rpdgj
            ,AR_Detail.rpptc
            ,SO_Detail.sddoco
            ,SO_Detail.sddcto
            ,SO_Detail.sdkcoo
            ,SO_Detail.sdlnid
            ,SO_Detail.sditm
            ,Seller_Detail.aban8
            ,Buyer_Detail.aban8
            ,Buyer_Detail.abtax
            ,Buyer_Detail.alctr
            ,Tax_Rate.taefdj
        FROM
            (
                SELECT
                     f4211.sddoc
                    ,f4211.sdodoc
                    ,f4211.sdlnid
                    ,f4211.sduorg
                    ,f4211.sduom
                    ,f4211.sdfea
                    ,f4211.sdaexp
                    ,f4211.sdcrcd
                    ,f4211.sdlitm
                    ,f4211.sddsc1
                    ,f4211.sddsc2
                    ,f4211.sdfup
                    ,f4211.sduprc
                    ,f4211.sddct
                    ,f4211.sdkco
                    ,f4211.sdtxa1
                    ,f4211.sddoco
                    ,f4211.sddcto
                    ,f4211.sdkcoo
                    ,f4211.sditm
                    ,f4211.sdlttr
                    ,f4211.sdnxtr
                FROM
                    PRODDTA.F4211
                WHERE TRIM(sdglc) <> 'NS29'
                UNION ALL
                SELECT
                     f42119.sddoc
                    ,f42119.sdodoc
                    ,f42119.sdlnid
                    ,f42119.sduorg
                    ,f42119.sduom
                    ,f42119.sdfea
                    ,f42119.sdaexp
                    ,f42119.sdcrcd
                    ,f42119.sdlitm
                    ,f42119.sddsc1
                    ,f42119.sddsc2
                    ,f42119.sdfup
                    ,f42119.sduprc
                    ,f42119.sddct
                    ,f42119.sdkco
                    ,f42119.sdtxa1
                    ,f42119.sddoco
                    ,f42119.sddcto
                    ,f42119.sdkcoo
                    ,f42119.sditm
                    ,f42119.sdlttr
                    ,f42119.sdnxtr
                FROM PRODDTA.F42119
                WHERE TRIM(sdglc) <> 'NS29'
            ) SO_Detail
                LEFT JOIN
                    (
                        SELECT
                             rpdoc
                            ,rpkco
                            ,rpdct
                            ,rpskco
                            ,rpsdct
                            ,rpsdoc
                            ,rpdgj
                            ,rppyr
                            ,rpptc
                            ,rpdivj
                            ,MAX(rpddj) AS rpddj
                            ,rpcrrm
                            ,rpcrcd
                            ,rpbcrc
                            ,rpan8
                            ,SUM(rpctam) AS rpctam
                            ,SUM(rpstam) AS rpstam
                            ,SUM(rpatxa) AS rpatxa
                            ,SUM(rpctxa) AS rpctxa
                            ,SUM(rpatxn) AS rpatxn
                            ,SUM(rpctxn) AS	rpctxn
                            ,SUM(rpacr) AS rpacr
                            ,SUM(rpag) AS rpag
                        FROM proddta.f03b11
                        GROUP BY
                             rpdoc
                            ,rpkco
                            ,rpdct
                            ,rpskco
                            ,rpsdct
                            ,rpsdoc
                            ,rpdgj
                            ,rpcrrm
                            ,rpcrcd
                            ,rpbcrc
                            ,rppyr
                            ,rpptc
                            ,rpdivj
                            ,rpddj
                            ,rpan8
                    ) AR_Detail
                        ON  AR_Detail.rpdct  = SO_Detail.sddct
                        AND AR_Detail.rpkco  = SO_Detail.sdkco
                        AND AR_Detail.rpdoc  = SO_Detail.sddoc
                LEFT JOIN
                    (
                        SELECT
                            *
                        FROM
                            proddta.f0101 f0101
                        INNER JOIN proddta.f0116 f0116
                            ON  f0101.aban8     = f0116.alan8
                            AND f0101.abeftb    = f0116.aleftb
                        INNER JOIN proddta.f0111 f0111
                            ON  f0101.aban8     = f0111.wwan8
                            AND f0111.wwidln    = 0
                        LEFT JOIN proddta.f0115 f0115
                            ON  f0101.aban8     = f0115.wpan8
                            AND f0115.wpphtp    = '    '
                    ) Seller_Detail
                        ON Seller_Detail.aban8 = AR_Detail.rpkco
                INNER JOIN
                    (
                        SELECT
                            aban8
                            ,abat1
                            ,abmcu
                            ,abtax
                            ,abtx2
                            ,alctr
                            ,CASE
                                WHEN abat1 = 'IC ' AND alctr = 'MY '
                            THEN 'IC'
                                ELSE 'NIC'
                            END AS IC_FLAG
                            ,aladd1
                            ,aladd2
                            ,aladd3
                            ,aladd4
                            ,alcty1
                            ,aladds
                            ,aladdz
                            ,alcoun
                            ,wwslnm
                            ,wwmlnm
                            ,wpph1
                        FROM
                            proddta.f0101 f0101
                        INNER JOIN proddta.f0116 f0116
                            ON  f0101.aban8     = f0116.alan8
                            AND f0101.abeftb    = f0116.aleftb
                        INNER JOIN proddta.f0111 f0111
                            ON f0101.aban8      = f0111.wwan8
                            AND f0111.wwidln    = 0
                        LEFT JOIN
                            (
                                SELECT
                                    f0115.wpan8
                                    ,f0115.wpph1
                                FROM
                                    (
                                        SELECT
                                            wpan8
                                            ,wpph1
                                            ,RANK() OVER (PARTITION BY wpan8 ORDER BY wpidln,wprck7 DESC) AS rnk
                                        FROM PRODDTA.f0115
                                        WHERE wpphtp = '    '
                                    ) f0115
                                WHERE f0115.rnk = 1
                            ) Buyer_Phone
                            ON Buyer_Phone.wpan8 = f0101.aban8
                    ) Buyer_Detail
                        ON Buyer_Detail.aban8 = AR_Detail.rpan8
                LEFT JOIN proddta.f0014 f0014
                    ON AR_Detail.rpptc = f0014.pnptc
                LEFT JOIN
                    (
                        SELECT
                            *
                        FROM
                            proddta.f4008 f4008
                        WHERE
                            TO_NUMBER(TO_CHAR(SYSDATE,'YYYYDDD'))-1900000 - 1 <= f4008.taefdj
                            AND TO_NUMBER(TO_CHAR(SYSDATE,'YYYYDDD'))-1900000 - 1 >= f4008.taeftj
                            AND f4008.tata1 = 11648878
                    ) Tax_Rate
                    ON Tax_Rate.tatxa1 = SO_Detail.sdtxa1
                LEFT JOIN proddta.f550301h UUID_Look_Up
                    ON UUID_Look_Up.ehurab = SO_Detail.SDODOC
                    AND SO_Detail.SDODOC <> 0
                    AND UUID_Look_Up.ehev02 = 'M'
                    AND UUID_Look_Up.ehev01 = 'I'
                    AND UUID_Look_Up.ehedsp = 'Y'
            WHERE
                AR_Detail.rpkco IN ('00037','00039','00048','00071','00083','00084','00092','00096')
                AND
                    (
                        (
                            SO_Detail.sdlttr != '980'
                            AND SO_Detail.sdnxtr = '999'
                        )
                        OR
                        (
                            SO_Detail.sdlttr IS NULL
                            AND SO_Detail.sdnxtr IS NULL
                        )
                    )
                AND AR_Detail.rpdct IN ('RM')
                AND Buyer_Detail.IC_FLAG <> 'IC'
				AND AR_Detail.rpag <> 0
                AND NOT EXISTS
                (
                    SELECT
                        1
                    FROM
                        proddta.f550301d f550301d
                    WHERE
                        f550301d.eddoc      = AR_Detail.rpdoc
                        AND f550301d.eddct  = AR_Detail.rpdct
                        AND f550301d.edkco  = AR_Detail.rpkco
                        AND f550301d.eddoco = SO_Detail.sddoco
                        AND f550301d.eddcto = SO_Detail.sddcto
                        AND f550301d.edkcoo = SO_Detail.sdkcoo
                        AND f550301d.edlnid = SO_Detail.sdlnid
                )
        ORDER BY
            AR_Detail.rpdoc;
BEGIN

    ------------------------------------------------------
    -- Get Audit Information
    ------------------------------------------------------
    SELECT
         UPPER(SUBSTR(SYS_CONTEXT('USERENV','HOST'), INSTR(SYS_CONTEXT('USERENV','HOST'), '\',1,1)+1,10))
        ,TO_NUMBER(TO_CHAR(SYSDATE,'yyyyddd')) - 1900000
        ,TO_NUMBER(TO_CHAR(SYSDATE,'hh24miss'))
    INTO
         v_jobn
        ,v_upmj
        ,v_upmt
    FROM
        dual;

    ------------------------------------------------------
    -- Generate next Batch Id DL01
    ------------------------------------------------------
    SELECT
        TO_CHAR(proddta.e_invoice_romania_out_seq.nextval)
    INTO
        v_batch_id
    FROM
        dual;

    ------------------------------------------------------
    -- Loop through Detail Cursor Records
    ------------------------------------------------------
    OPEN c_records;

    LOOP

        FETCH
            c_records
        INTO
             v_ar_doc
            ,v_ar_dct
            ,v_ar_kco
            ,v_ar_dgj
            ,v_ar_ptc
            ,v_sod_doco
            ,v_sod_dcto
            ,v_sod_kcoo
            ,v_sod_lnid
            ,v_sod_itm
            ,v_seller_an8
            ,v_buyer_an8
            ,v_buyer_tax
            ,v_buyer_ctr
            ,v_tax_rate_efdj;

        v_records_found := c_records%FOUND;

        ------------------------------------------------------
        -- If this is not the first loop, enter a header record
        ------------------------------------------------------
        -- Normal condition to insert header record where the doc number changes
        -- and we are working on a new invoice.  Like a level break in JDE E1 programming
        IF
        (
            v_previous_invoice <> v_ar_doc
            AND v_first_loop = FALSE
        )
        -- These conditions in the OR are for capturing the last header record
        -- The fetch above would not have returned records so v_records_found
        -- will be false.  However we don't exit the loop until after this IF statement
        -- Since the v_records_found_overall flag is TRUE we know records were
        -- returned this run and we have a final header record to insert.
        OR
        (
            v_records_found_overall = TRUE
            AND v_records_found = FALSE
        )
        THEN

            ------------------------------------------------------
            -- Insert into Header Table
            ------------------------------------------------------
            INSERT INTO proddta.f550301h
            (
                 ehtaskid	-- Unique of the table (GUID)
                ,ehedsp	    -- Processed Flag
                ,ehdl01	    -- Link between Header and Detail Tables
                ,ehev01	    -- I for Invoice, C for Credit note
                ,ehev02	    -- R for Romania, M for Malaysia
                ,ehev04     -- NULL to have QR Code process integration record, X to have QR Code integration ignore (non MY buyer)
                ,ehurab     -- Invoice Number
                ,ehurdt     -- GL Date
                ,ehpid		-- Audit
                ,ehjobn	    -- Audit
                ,ehuser	    -- Audit
                ,ehupmj	    -- Audit
                ,ehupmt	    -- Audit
            )
            VALUES
            (
                 SYS_GUID()	        -- ehtaskid
                ,'N'	            -- ehedsp
                ,v_batch_id	        -- ehdl01
                ,'C'	            -- ehev01
                ,'M'	            -- ehev02
                ,CASE
                    WHEN
                        TRIM(v_previous_buyer_ctr) = 'MY'
                    THEN
                        NULL
                    ELSE
                        'X'
                 END                -- ev04
                ,v_previous_invoice	-- ehurab
                ,v_ar_dgj
                ,v_pid
                ,v_jobn
                ,v_user
                ,v_upmj
                ,v_upmt
            );

            ------------------------------------------------------
            -- Generate next Batch Id DL01
            ------------------------------------------------------
            SELECT
                TO_CHAR(proddta.e_invoice_romania_out_seq.nextval)
            INTO
                v_batch_id
            FROM
                dual;

            ------------------------------------------------------
            -- Reset Line Number Counter
            ------------------------------------------------------
            v_detail_line_counter   :=  0;

        END IF;

        ------------------------------------------------------
        -- Put the loop exit here to capture the final header
        -- record above
        ------------------------------------------------------
        EXIT WHEN v_records_found = FALSE;

        ------------------------------------------------------
        -- Needed for capturing final header record.
        -- The fetch will not have returned records
        -- but we had records overall this run
        ------------------------------------------------------
        v_records_found_overall := TRUE;


        ------------------------------------------------------
        -- Set first loop flag.  Needed to avoid inserting
        -- a header record on the first loop
        ------------------------------------------------------
        IF v_first_loop = TRUE THEN

            v_first_loop := FALSE;

        END IF;

        ------------------------------------------------------
        -- Set previous doc number for compare next loop
        ------------------------------------------------------
        v_previous_invoice := v_ar_doc;

        ------------------------------------------------------
        -- Set previous buyer for setting ev03 when header is inserted
        ------------------------------------------------------
        v_previous_buyer_ctr := v_buyer_ctr;

        ------------------------------------------------------
        -- Increment Line Number Counter
        ------------------------------------------------------
        v_detail_line_counter   :=  v_detail_line_counter + 1;

        ------------------------------------------------------
        -- Insert into Detail Table
        ------------------------------------------------------
        INSERT INTO proddta.f550301d
        (
             edtaskid	-- Internal Task ID						Unique of the table
            ,ededsp	    -- EDI - Successfully Processed			Processed Flag
            ,eddl01	    -- Description							BatchID (when each script run)
            ,ededln	    -- Line									Increment by 1
            ,edev01	    -- J.D. EnterpriseOne Event Point 01	Indicate it is Invoice or Credit Note (I/C)
            ,eddoc		-- Document (Voucher, Invoice, etc.)	F03B11 Unique Key
            ,eddct		-- Document Type						F03B11 Unique Key
            ,edkco		-- Document Company						F03B11 Unique Key
            ,eddoco	    -- Document (Order No, Invoice, etc.)	F4211 SO Detail Key
            ,eddcto	    -- Order Type							F4211 SO Detail Key
            ,edkcoo	    -- Order Company (Order Number)			F4211 SO Detail Key
            ,edlnid	    -- Line Number							F4211 SO Detail Key
            ,edptc		-- Payment Terms Code					Payment Term
            ,editm		-- Item Number - Short					Item Master
            ,edan8		-- Address Number	Seller 				Detail(who is seller)
            ,edpyr		-- Payor Address Number					Buyer Detail (who is buyer)
            ,eddl02	    -- Description 02						Reserved Fields(ABTAX)
            ,edurrf	    -- User Reserved Reference				Reserved Fields(CTR)
            ,edurdt	    -- User Reserved Date					Reserved Fields(EFDJ)
            ,edpid		-- Program ID							Audit Fields
            ,edjobn	    -- Work Station ID						Audit Fields
            ,eduser	    -- User ID								Audit Fields
            ,edupmj	    -- Date - Updated						Audit Fields
            ,edupmt	    -- Time - Last Updated					Audit Fields
        )
        VALUES
        (
             SYS_GUID()	            -- Internal Task ID						Unique of the table
            ,' '    	            -- EDI - Successfully Processed			Processed Flag
            ,v_batch_id	            -- Description							BatchID (when each script run)
            ,v_detail_line_counter	-- Line									Increment by 1
            ,'C'	                -- J.D. EnterpriseOne Event Point 01	Indicate it is Invoice or Credit Note (I/C)
            ,v_ar_doc		        -- Document (Voucher, Invoice, etc.)	F03B11 Unique Key
            ,v_ar_dct		        -- Document Type						F03B11 Unique Key
            ,v_ar_kco		        -- Document Company						F03B11 Unique Key
            ,v_sod_doco	            -- Document (Order No, Invoice, etc.)	F4211 SO Detail Key
            ,v_sod_dcto	            -- Order Type							F4211 SO Detail Key
            ,v_sod_kcoo	            -- Order Company (Order Number)			F4211 SO Detail Key
            ,v_sod_lnid	            -- Line Number							F4211 SO Detail Key
            ,v_ar_ptc		        -- Payment Terms Code					Payment Term
            ,v_sod_itm		        -- Item Number - Short					Item Master
            ,v_seller_an8		    -- Address Number	Seller 				Detail(who is seller)
            ,v_buyer_an8		    -- Payor Address Number					Buyer Detail (who is buyer)
            ,v_buyer_tax	        -- Description 02						Reserved Fields(ABTAX)
            ,v_buyer_ctr	        -- User Reserved Reference				Reserved Fields(CTR)
            ,v_tax_rate_efdj	    -- User Reserved Date					Reserved Fields(EFDJ)
            ,v_pid		            -- Program ID							Audit Fields
            ,v_jobn	                -- Work Station ID						Audit Fields
            ,v_user	                -- User ID								Audit Fields
            ,v_upmj	                -- Date - Updated						Audit Fields
            ,v_upmt	                -- Time - Last Updated					Audit Fields
        );

    END LOOP;

    CLOSE c_records;

    COMMIT;

    EXCEPTION
        WHEN OTHERS THEN

            v_err_nbr := SQLCODE;
            v_err_msg := v_err_job_name || ' - '||SQLERRM;

            ------------------------------------------------------
            -- Rollback changes
            ------------------------------------------------------
            ROLLBACK;

            ------------------------------------------------------
            -- Insert record into PL/SQL logging table
            ------------------------------------------------------
            INSERT INTO
                commobj.joberr
                (
                    job_name,
                    err#,
                    err_msg,
                    TIMESTAMP
                )
                VALUES
                (
                    v_err_job_name,
                    v_err_nbr,
                    v_err_msg,
                    SYSDATE
                );

            COMMIT;

            RAISE_APPLICATION_ERROR(-20000, v_err_msg);

END P_EINV_MY_CNOTE_INSERT;


1 row selected.

