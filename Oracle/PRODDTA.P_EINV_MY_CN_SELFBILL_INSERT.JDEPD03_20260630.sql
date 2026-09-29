
  CREATE OR REPLACE EDITIONABLE PROCEDURE "PRODDTA"."P_EINV_MY_CN_SELFBILL_INSERT" (
    p_choose_month_date_jdejulian IN number DEFAULT 0
)
IS

/**********************************************************************************

	Program Name    :   P_EINV_MY_CN_SELFBILL_INSERT

	Description     :   This procedure is used for E-Invoicing Malaysia.  It will
                        insert invoice records into F550301H and F550301D

    Date        Who             Description
    ----------  --------------  ---------------------------------------------------
    2024-09-19  Kyle Floros     CHG094774 - New
	2024-10-14  Kyle Floros     CHG095202
                                    - New hardcoded dates
                                    - Bug Fix - Copied FROM/WHERE clauses from XML Select to keep in sync
    2024-10-31  Kyle Floros     CHG095203 - Find run dates dynamically using new function
    2024-12-06  Kyle Floros     CHG095872 - Load invoice date into URDT
    2025-05-09  Kyle Floros     CHG098725
                                    - Pass zero into dates function
                                    - Use URDT instead of UPMJ in WHERE
    2026-01-21  Kai Abshire     CHG103499 - Change the where clause to avoid error if document is shared accross document types
    2026-03-05  James Lutsey    CHG103499 - Allow manual month choice by replacing 0 with a paramter in proddta.f_get_f0008_start_end_dates

    Manual month execution example (just change the date being assigned to v_choose_month_date):
        DECLARE
            v_choose_month_date date := TO_DATE('2025-12-01', 'YYYY-MM-DD');
            v_choose_month_date_jdejulian number := TO_NUMBER(TO_CHAR(v_choose_month_date, 'YYYYDDD')) - 1900000;
        BEGIN
            PRODDTA.P_EINV_MY_CN_SELFBILL_INSERT (v_choose_month_date_jdejulian);
        END;
        /

**********************************************************************************/

    ------------------------------------------------------
    -- Declare Exception Variables
    ------------------------------------------------------
    v_err_job_name          VARCHAR2(30)        := 'P_EINV_MY_CN_SELFBILL_INSERT';
    v_err_nbr               VARCHAR2(10)        := ' ';
    v_err_msg               VARCHAR2(2000)      := ' ';

    ------------------------------------------------------
    -- Declare Audit Variables
    ------------------------------------------------------
    v_pid                   VARCHAR2(10)        := 'EI_MY_SBC';
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
    v_pod_doco              NUMBER          :=  0;
    v_pod_dcto              CHAR(2 BYTE)    :=  ' ';
    v_pod_kcoo              CHAR(5 BYTE)    :=  ' ';
    v_pod_lnid              NUMBER          :=  0;
    v_pod_itm               NUMBER          :=  0;

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
    v_dates_obj             proddta.t_start_end_dates;


    ------------------------------------------------------
    -- Declare Cursor Variables
    ------------------------------------------------------
    CURSOR c_records IS
        SELECT
             AP_Ledger.F0411_Voucher_Number
            ,AP_Ledger.rpdct
            ,AP_Ledger.rpkco
            ,AP_Ledger.F0411_Voucher_GL_Date
            ,Purchase_Order_Detail.pddoco
            ,Purchase_Order_Detail.pddcto
            ,Purchase_Order_Detail.pdkcoo
            ,Purchase_Order_Detail.pdlnid
            ,Purchase_Order_Detail.pditm
        FROM
            (
                SELECT
                    rpkco
                    ,rpdoc AS F0411_Voucher_Number
                    ,rpdct
                    ,rpan8
                    ,rpvod
                    ,rpdcta AS F0411_Doc_Type_Adjusting
                    ,rpdgj AS F0411_Voucher_GL_Date
                    ,SUM(rpag) AS F0411_Base_Gross_Amount
                    ,SUM(rpacr) AS F0411_Foreign_Gross_Amount
                    ,SUM(CASE
                            WHEN
                                rppst = 'P'
                            THEN
                                rpadsa
                            ELSE
                                rpadsc
                        END) AS F0411_Base_Discount_Amount
                    ,SUM(CASE
                            WHEN
                                rppst = 'P'
                            THEN
                                rpcdsa
                            ELSE
                                rpcds
                        END) AS F0411_Foreign_Discount_Amount
                    ,SUM(rpstam) AS F0411_Base_Amount_Tax
                    ,SUM(rpctam) AS F0411_Foreign_Amount_Tax
                    ,SUM(rpatxa) AS F0411_Base_Amount_Taxable
                    ,SUM(rpctxa) AS F0411_Foreign_Amount_Taxable
                    ,SUM(rpatxn) AS F0411_Base_Amount_Non_Taxable
                    ,SUM(rpctxn) AS F0411_Foreign_Amount_Non_Taxable
                    ,rpcrrm AS F0411_Currency_Mode
                    ,rpcrcd AS F0411_Foreign_Currency
                    ,rpbcrc AS F0411_Base_Currency
                    ,Void_In_Month_Check.Voucher_GL_Date AS Void_Check_Voucher_GL_Date
                    ,Void_In_Month_Check.F550301h_Voucher_Number AS F550301h_Voucher_Number
                    ,Void_In_Month_Check.F550301h_UUID AS F550301h_UUID
                    ,Void_In_Month_Check.F550301h_Update_Date AS F550301h_Update_Date
                    ,Seller_Detail.wwmlnm AS Seller_Name
                    ,Seller_Detail.aladd1 AS Seller_Address_Line_1
                    ,Seller_Detail.aladd2 AS Seller_Address_Line_2
                    ,Seller_Detail.aladd3 AS Seller_Address_Line_3
                    ,Seller_Detail.aladd4 AS Seller_Address_Line_4
                    ,Seller_Detail.alcty1 AS Seller_City
                    ,Seller_Detail.aladdz AS Seller_Zip
                    ,Seller_Detail.alctr AS Seller_Country
                    ,Seller_Detail.wpph1 AS Seller_Phone_Number
                    ,Seller_Detail.a6txa2 AS Seller_Tax_Code
                    ,Buyer_Detail.aladd2 AS Buyer_Address_Line_2
                    ,Buyer_Detail.aladd3 AS Buyer_Address_Line_3
                    ,Buyer_Detail.aladd4 AS Buyer_Address_Line_4
                    ,Buyer_Detail.aladd1 AS Buyer_Address_Line_1
                    ,Buyer_Detail.alcty1 AS Buyer_City
                    ,Buyer_Detail.aladdz AS Buyer_Zip_Code
                FROM PRODDTA.F0411
                LEFT JOIN
                    (
                        SELECT
                                rpkco AS Voucher_Company
                                ,rpdoc AS Voucher_Number
                                ,rpdct AS Voucher_Doc_Type
                                ,TRIM(ehurab) AS F550301h_Voucher_Number
                                ,TRIM(ehconstr1) AS F550301h_UUID
                                ,ehupmj AS F550301h_Update_Date
                                ,rpdgj AS Voucher_GL_Date
                                ,'Void_Does_Match' AS Void_Check
                            FROM PRODDTA.f0411
                            INNER JOIN PRODDTA.f550301h
                                ON TRIM(ehurab) = rpdoc
                                AND ehev02 = 'S'
                                AND ehev01 = 'I'
                                AND ehedsp = 'Y'
                                AND ehurdt < v_dates_obj.start_date
                            WHERE
                                rpvod = 'V'
                                AND TRIM(rpdcta) IS NOT NULL
                                AND rpdgj BETWEEN v_dates_obj.start_date AND v_dates_obj.end_date
                    ) Void_In_Month_Check
                    ON Void_In_Month_Check.Voucher_Company = rpkco
                    AND Void_In_Month_Check.Voucher_Number = rpdoc
                    AND Void_In_Month_Check.Voucher_Doc_Type = rpdct
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
                                WHEN TRIM(alctr) = 'MY'
                            THEN 'MY_SELLER'
                                ELSE 'NON_MY_SELLER'
                            END AS MY_SELLER_FLAG
                            ,aladd1
                            ,aladd2
                            ,aladd3
                            ,aladd4
                            ,alcty1
                            ,aladds
                            ,aladdz
                            ,alcoun
                            ,a6txa2
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
                        LEFT JOIN proddta.f0401 f0401
                            ON f0101.aban8 = f0401.a6an8
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
                                        FROM
                                            PRODDTA.f0115
                                        WHERE
                                            TRIM(wpphtp) IS NULL
                                    ) f0115
                                WHERE f0115.rnk = 1
                            ) Seller_Phone
                            ON Seller_Phone.wpan8 = f0101.aban8
                    ) Seller_Detail
                    ON Seller_Detail.aban8 = rpan8
                LEFT JOIN
                    (
                        SELECT
                            aban8
                            ,aladd2
                            ,aladd3
                            ,aladd4
                            ,aladd1
                            ,alcty1
                            ,aladdz
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
                        ) Buyer_Detail
                        ON Buyer_Detail.aban8 = rpkco
                   WHERE
                        rpkco IN ('00037','00039','00048','00071','00083','00084','00092','00096')
                        AND
                            CASE
                                WHEN rpptc IN ('PRE','204','205') AND TRIM(rppo) IS NULL
                            THEN
                                1
                            ELSE
                                0
                            END = 0
                        AND
                            CASE
                                WHEN TRIM(rpvod) = 'V' AND Void_In_Month_Check.Void_Check IS NULL
                            THEN
                                3
                            ELSE
                                2
                            END = 2
                        AND rpdgj BETWEEN v_dates_obj.start_date AND v_dates_obj.end_date
                        AND Seller_Detail.MY_SELLER_FLAG = 'NON_MY_SELLER'
                        AND Seller_Detail.abat1 IN ('V','TC','IC','I')
                    GROUP BY rpkco,rpdoc,rpdct,rpan8,rpvod,rpdcta,rpdgj,rpcrrm,rpcrcd,rpbcrc
                                ,Void_In_Month_Check.Voucher_GL_Date,F550301h_Voucher_Number,Void_In_Month_Check.F550301h_UUID,F550301h_Update_Date
                                    ,Seller_Detail.wwmlnm,Seller_Detail.aladd1,Seller_Detail.aladd2,Seller_Detail.aladd3,Seller_Detail.aladd4,Seller_Detail.alcty1,Seller_Detail.aladdz,Seller_Detail.alctr,Seller_Detail.a6txa2,Seller_Detail.wpph1
                                        ,Buyer_Detail.aladd2,Buyer_Detail.aladd3,Buyer_Detail.aladd4,Buyer_Detail.aladd1,Buyer_Detail.alcty1,Buyer_Detail.aladdz
            ) AP_Ledger
            LEFT JOIN
                (
                    SELECT
                        cvcrcd
                        , cvcdec
                        , CASE
                            WHEN cvcdec = 0 THEN 1
                            WHEN cvcdec = 1 THEN .1
                            WHEN cvcdec = 2 THEN .01
                            WHEN cvcdec = 3 THEN .001
                            WHEN cvcdec = 4 THEN .0001
                            WHEN cvcdec = 5 THEN .00001
                            WHEN cvcdec = 6 THEN .000001
                            WHEN cvcdec = 7 THEN .0000001
                            WHEN cvcdec = 8 THEN .00000001
                            WHEN cvcdec = 9 THEN .000000001
                            ELSE .01
                            END AS Decimal_Position
                    FROM PRODDTA.f0013
                ) F0411_Foreign_Currency
                ON AP_Ledger.F0411_Foreign_Currency = F0411_Foreign_Currency.cvcrcd
            LEFT JOIN
                (
                    SELECT
                        cvcrcd
                        , cvcdec
                        , CASE
                            WHEN cvcdec = 0 THEN 1
                            WHEN cvcdec = 1 THEN .1
                            WHEN cvcdec = 2 THEN .01
                            WHEN cvcdec = 3 THEN .001
                            WHEN cvcdec = 4 THEN .0001
                            WHEN cvcdec = 5 THEN .00001
                            WHEN cvcdec = 6 THEN .000001
                            WHEN cvcdec = 7 THEN .0000001
                            WHEN cvcdec = 8 THEN .00000001
                            WHEN cvcdec = 9 THEN .000000001
                            ELSE .01
                            END AS Decimal_Position
                    FROM PRODDTA.f0013
                ) F0411_Base_Currency
                ON AP_Ledger.F0411_Base_Currency = F0411_Base_Currency.cvcrcd
                LEFT JOIN PRODDTA.F43121 PO_Receiver
                    ON PO_Receiver.prkco = AP_Ledger.rpkco
                    AND PO_Receiver.prdoc = AP_Ledger.F0411_Voucher_Number
                    AND PO_Receiver.prdct = AP_Ledger.rpdct
                    AND PO_Receiver.prmatc IN ('2','3')
                LEFT JOIN
                    (
                        SELECT
                            tatxa1
                            ,tatxr1 F4008_Tax_Rate_1
                        FROM
                            proddta.f4008
                        WHERE
                            TO_NUMBER(TO_CHAR(SYSDATE,'YYYYDDD'))-1900000 - 1 <= taefdj
                            AND TO_NUMBER(TO_CHAR(SYSDATE,'YYYYDDD'))-1900000 - 1 >= taeftj
                            AND tata1 = 11648878
                    ) Tax_Rate
                    ON Tax_Rate.tatxa1 = AP_Ledger.Seller_Tax_Code
                LEFT JOIN proddta.f4311 Purchase_Order_Detail
                    ON Purchase_Order_Detail.pddoco = PO_Receiver.prdoco
                    AND Purchase_Order_Detail.pddcto = PO_Receiver.prdcto
                    AND Purchase_Order_Detail.pdkcoo = PO_Receiver.prkcoo
                    AND Purchase_Order_Detail.pdsfxo = PO_Receiver.prsfxo
                    AND Purchase_Order_Detail.pdlnid = PO_Receiver.prlnid
            LEFT JOIN
            (
               SELECT
                   DISTINCT
                        --prdoc AS Receipt_Number
                        prdoco AS PO_Number
                        ,prdcto AS PO_Doc_Type
                        ,prlnid AS PO_Line_ID
                        ,prmcu AS Business_Unit
                        ,prnlin AS Number_of_Lines
                        ,LISTAGG(TRIM(crk74cude), ' / ') AS Tracking_Number_ID
                FROM proddta.F43121
                LEFT JOIN proddta.f5543125
                    ON crdoc = prdoc
                    AND crdoco = prdoco
                    AND crdcto = prdcto
                    AND crlnid = prlnid
                    AND crmcu = prmcu
                    AND prmatc = ('1')
                WHERE TRIM(crk74cude) <> ' '
                GROUP BY prdoco,prdcto,prlnid,prmcu,prnlin
            UNION ALL
                SELECT
                    DISTINCT
                        --prdoc AS Receipt_Number
                        prdoco AS PO_Number
                        ,prdcto AS PO_Doc_Type
                        ,prlnid AS PO_Line_ID
                        ,prmcu AS Business_Unit
                        ,prnlin AS Number_of_Lines
                        ,LISTAGG(TRIM(redl31),' / ') AS Tracking_Number_ID
                FROM proddta.f43121
                INNER JOIN proddta.f574108
                    ON prmcu = remcu
                    AND prlotn = relotn
                    AND pritm = reitm
                WHERE
                    prmcu = LPAD('920',12)
                    AND prmatc = '1'
                    AND prurec IS NOT NULL
                    AND TRIM(prlotn) <> ' '
                    AND pritm <> 0
                    AND TRIM(redl31) <> ' '
                GROUP BY prdoco,prdcto,prlnid,prmcu,prnlin
            ) Tracking_Number
            ON PO_receiver.prdoco = Tracking_Number.PO_Number
              AND PO_receiver.prdcto = Tracking_Number.PO_Doc_Type
              AND PO_receiver.prlnid = Tracking_Number.PO_Line_ID
              AND PO_receiver.prnlin = Tracking_Number.Number_of_Lines
              AND PO_receiver.prmcu = Tracking_Number.Business_Unit
            LEFT JOIN PRODDTA.F0411 AP_Ledger_Line_Detail
                ON AP_Ledger_Line_Detail.rpdoc = AP_Ledger.F0411_Voucher_Number
                AND AP_Ledger_Line_Detail.rpkco = AP_Ledger.rpkco
                AND AP_Ledger_Line_Detail.rpdct = AP_Ledger.rpdct
                AND PO_receiver.prdoc IS NULL
            LEFT JOIN prodctl.f0005 UDC_f0411
                ON AP_Ledger_Line_Detail.rpum = TRIM(UDC_f0411.drky)
                AND UDC_f0411.drsy = '55'
                AND UDC_f0411.drrt = 'UM'
            LEFT JOIN prodctl.f0005 UDC_f43121
                ON PO_Receiver.pruom = TRIM(UDC_f43121.drky)
                AND UDC_f43121.drsy = '55'
                AND UDC_f43121.drrt = 'UM'
        WHERE
            AP_LEDGER.F0411_Base_Gross_Amount < 0
            AND NOT EXISTS
            (
                SELECT
                    1
                FROM
                    proddta.f550301h f550301h
                WHERE
                    f550301h.ehurab     = AP_Ledger.F0411_Voucher_Number
                    AND f550301h.ehev01 = 'C'
					AND f550301h.ehev02 = 'S'
            )
        ORDER BY
            AP_Ledger.F0411_Voucher_Number;
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
    -- Call function to get start/end dates from F0008 for this run
    ------------------------------------------------------
    v_dates_obj := proddta.f_get_f0008_start_end_dates(p_choose_month_date_jdejulian);

--    DBMS_OUTPUT.PUT_LINE(v_dates_obj.start_date);
--    DBMS_OUTPUT.PUT_LINE(v_dates_obj.end_date);

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
            ,v_pod_doco
            ,v_pod_dcto
            ,v_pod_kcoo
            ,v_pod_lnid
            ,v_pod_itm;

        v_records_found := c_records%FOUND;

--        DBMS_OUTPUT.PUT_LINE('Loop');
--        DBMS_OUTPUT.PUT_LINE('v_previous_invoice: ' || v_previous_invoice);
--        DBMS_OUTPUT.PUT_LINE('v_ar_doc: ' || v_ar_doc);
--        DBMS_OUTPUT.PUT_LINE('v_buyer_ctr: ' || v_buyer_ctr);
--        DBMS_OUTPUT.PUT_LINE('v_first_loop: ' || sys.diutil.bool_to_int(v_first_loop));
--        DBMS_OUTPUT.PUT_LINE('v_records_found_overall: ' || sys.diutil.bool_to_int(v_records_found_overall));
--        DBMS_OUTPUT.PUT_LINE('v_records_found: ' || sys.diutil.bool_to_int(v_records_found));

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


--        DBMS_OUTPUT.PUT_LINE('');
--        DBMS_OUTPUT.PUT_LINE('Header Insert');
--        DBMS_OUTPUT.PUT_LINE('v_ar_doc: ' || v_ar_doc);
--        DBMS_OUTPUT.PUT_LINE('');

            ------------------------------------------------------
            -- Insert into Header Table
            ------------------------------------------------------
            INSERT INTO proddta.f550301h
            (
                 ehtaskid	-- Unique of the table (GUID)
                ,ehedsp	    -- Processed Flag
                ,ehdl01	    -- Processed Flag
                ,ehev01	    -- I for Invoice, C for Credit note
                ,ehev02	    -- R for Romania, M for Malaysia
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
                ,'S'	            -- ehev02            -- ev03
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
            ,editm		-- Item Number - Short					Item Master
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
            ,v_pod_doco	            -- Document (Order No, Invoice, etc.)	F4211 SO Detail Key
            ,v_pod_dcto	            -- Order Type							F4211 SO Detail Key
            ,v_pod_kcoo	            -- Order Company (Order Number)			F4211 SO Detail Key
            ,v_pod_lnid	            -- Line Number							F4211 SO Detail Key
            ,v_pod_itm		        -- Item Number - Short					Item Master
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

END P_EINV_MY_CN_SELFBILL_INSERT;


1 row selected.

