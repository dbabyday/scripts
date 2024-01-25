SELECT /*Jorge304*/
            TRIM(Lpml.Lmmcu) As "Site",
            "MPF",
            "CustomerId Name",
            TRUNC(Lpml.lmlpndc)  As Lpndc,
            -- Rank()Over(Partition by Trunc(Lpml.lmlpndc),  Lpml.Lmlpnu, Lpml.Lmlpsc order by Lpml.Lmrulukid desc) as Rank_List,
            -- for an LP at status get the earliest record by LPNDC and UKID
            RANK() OVER(PARTITION by Lpml.Lmlpnu, Lpml.Lmlpsc ORDER BY TRUNC(Lpml.lmlpndc) ASC,  Lpml.Lmrulukid ASC) as Rank_List,
            TO_CHAR(lpml.Lmuupmj, 'dd-mon-yy hh24:mi:ss' ) as "UUPMJ",
            TRIM(Lpml.Lmrulukid) As "UKID",
            TRIM(Lpml.Lmpid) As PID,
            TRIM(Lpml.Lmuser) As "User",
            TRIM(Lpml.Lmlocn) As "Location",
            TRIM(Lpml.Lmlpnu) As "Liscense Plate", 
            TRIM(Lpml.Lmlpsc) As "LP Status",
            "Product Model",
            LMLPTT,
            "Short Item",
            "Item Number"
            --'F46L10LOG' As "Source"
            FROM 
                Proddta.F46L10LOG Lpml
                ,(--using the site (MCU) and LP find the Item Number
                SELECT  
                    Lph.Lmlpnu as LPHLP
                    ,Lph.Lmmcu as LPHMCU
                    ,Ib.Ibprp4 as MPF
                    ,Lph.Lmlptt as LMLPTT
                    ,lmitm as "Short Item"
                    ,lmitm2 as "Item Number"
                    ,Pm.Pbprodm as "Product Model"
                    ,Pm.Pbprodf as "Product Family"
                    ,RANK()OVER(PARTITION BY Lph.Lmlpnu,Lph.Lmitm  ORDER BY Lph.Lmukid desc) as Rank_List2
                    FROM 
                        Proddta.F46L99 Lph,  Proddta.F4102 Ib, Proddta.f41171 Pm
                    WHERE 
                        Lph.Lmmcu = lpad('920',12,' ') --:Site_Name
                        AND Lph.Lmlptt = 'ITMAD'
                        AND Lph.Lmmcu = Ib.Ibmcu
                        AND Lph.Lmitm = Ib.Ibitm
                        AND Lph.Lmmcu = Pm.Pbmmcu (+)
                        AND Lph.Lmitm = Pm.Pbitm (+)
                )   
                ,( -- customer name
                    SELECT DISTINCT 
                        TRIM(B.Drky) As UTCMPF, B.Drdl01 As "Customer Name", 
                        TRIM(b.drdl01) | | ' - ' | | TRIM(B.Drky) AS "CustomerId Name"
                        FROM  
                            Prodctl.F0005 B
                        WHERE   
                            B.Drsy = '41' And B.Drrt = 'P4' 
                )

            WHERE 
                lpml.Lmmcu = lpad('920',12,' ') --:Site_Name
                -- AND (:Customer_MPF Is Null Or "MPF" = :Customer_MPF)
                -- AND Ib.Ibprp4 in (:Customer_MPF) 
                AND Lpml.Lmmcu = LPHMCU (+)
                AND Lpml.Lmlpnu =  LPHLP (+)
                AND Rank_List2 = 1
                AND "MPF" = UTCMPF
                AND Lpml.LmDS20 <> 'BEFORE UPDATE'
                AND (Lpml.Lmuser <> rpad('SCHED',10,' ') And Lpml.Lmpid <> rpad('R5746L99',10,' '))
                AND Lpml.Lmuser NOT IN (rpad('SRVCDSIPD',10,' '), rpad('DBSERVER',10,' '))
                AND Lpml.Lmlpnu = rpad('AJF00252901',40,' ')
            ORDER BY 
                Lpml.Lmlpsc, lpml.Lmrulukid;
