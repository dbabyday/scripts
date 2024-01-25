
  CREATE OR REPLACE EDITIONABLE PACKAGE "BIZTALK"."PKG_AMS_OUTBOUND" is

  -- Author  : ANN.MELEWSKI
  -- Created : 2/15/2021 1:32:31 PM
  -- Purpose : Package to gather AMS data to send to customers


 FUNCTION  UFN_F58INT11_ACKNOWLEDGEMENT_POLL (
                                        SGAN8_IN VARCHAR2 := NULL,
                                        SGDOLLARSRCDEST_IN VARCHAR2 := NULL
                                    ) RETURN NUMBER;

 FUNCTION  UFN_F58INT11_RECEIVING_POLL  (
                                        SGAN8_IN VARCHAR2 := NULL,
                                        SGDOLLARSRCDEST_IN VARCHAR2 := NULL
                                    ) RETURN NUMBER;

 FUNCTION  UFN_F58INT11_WO_POLL (
                                        SGAN8_IN VARCHAR2 := NULL,
                                        SGDOLLARSRCDEST_IN VARCHAR2 := NULL
                                    ) RETURN NUMBER;

 FUNCTION  UFN_F58INT11_SHIPPING_POLL (
                                        SGAN8_IN VARCHAR2 := NULL,
                                        SGDOLLARSRCDEST_IN VARCHAR2 := NULL
                                    ) RETURN NUMBER;

FUNCTION  UFN_ISODATE_TO_DATE (ISODateString VARCHAR := NULL) RETURN DATE;

 PROCEDURE USP_AMS_ACKNOWLEDGEMENT_SELECT(SGAN8_IN VARCHAR2 := NULL, SGDOLLARSRCDEST_IN VARCHAR2 := NULL, OUT_CLOBData OUT NOCOPY CLOB, OUT_RetMsg OUT VARCHAR2 );

 PROCEDURE USP_AMS_RECEIVING_SELECT(SGAN8_IN VARCHAR2 := NULL, SGDOLLARSRCDEST_IN VARCHAR2 := NULL, OUT_CLOBData OUT NOCOPY CLOB, OUT_RetMsg OUT VARCHAR2 );

 PROCEDURE USP_AMS_WO_SELECT(SGAN8_IN VARCHAR2 := NULL, SGDOLLARSRCDEST_IN VARCHAR2 := NULL,OUT_CLOBData OUT NOCOPY CLOB, OUT_RetMsg OUT VARCHAR2 );

 PROCEDURE USP_AMS_SHIPPING_SELECT(SGAN8_IN VARCHAR2 := NULL, SGDOLLARSRCDEST_IN VARCHAR2 := NULL,OUT_CLOBData OUT NOCOPY CLOB, OUT_RetMsg OUT VARCHAR2 );

 PROCEDURE USP_F58INT11_UPDATE(SG$TRANSID_IN IN VARCHAR2
                                      ,SGAN8_IN NUMBER
                                         ,SGURLNAME_IN IN VARCHAR2
                                         ,SG$RSP_IN IN VARCHAR2
                                         ,SGLONGMSG_IN IN VARCHAR2
                                         ,SGUSER_IN VARCHAR2
                                         ,SGUPMJ_IN VARCHAR2
                                         ,SGUPMT_IN VARCHAR2
                                         ,SGCREATEDT_IN VARCHAR2
                                         ,P_RETMSG_OUT OUT VARCHAR2);

FUNCTION GET_TRANSMISSIONID_FROM_F00022
  (P_TABLENAME      IN CHAR)
  RETURN VARCHAR;

PROCEDURE USP_AMS_SERVICE_DETAILS_SELECT(
  ACCOUNT_NUMBER    IN VARCHAR2
  ,PRODUCT_FAMILY  IN VARCHAR2
  ,MPF  IN VARCHAR2
  ,OUT_CLOBData OUT NOCOPY CLOB
  ,OUT_RetMsg OUT VARCHAR2 );

PROCEDURE USP_AMS_SERVICE_DETAILS_STATUS_UPDATE
 (
   P_CLOBData_in  IN CLOB
  ,P_RetMsg_out   OUT VARCHAR2
 );

 PROCEDURE USP_AMS_REPROCESS_SERVICE_DETAILS_SELECT(
  ACCOUNT_NUMBER    IN VARCHAR2
  ,PRODUCT_FAMILY  IN VARCHAR2
  ,MPF  IN VARCHAR2
  ,START_DATE IN VARCHAR2
  ,REPROCESS_ERRORS IN VARCHAR2
  ,OUT_CLOBData OUT NOCOPY CLOB
  ,OUT_RetMsg OUT VARCHAR2 );

  PROCEDURE GET_REPDAYS_FROM_F58INT00
 (
   ACCOUNT_NUMBER    IN VARCHAR2
  ,OUT_RepDays    OUT NUMBER
 );

FUNCTION  UFN_F58INT11_SDM_POLL RETURN NUMBER;

PROCEDURE USP_AMS_SERVICE_DETAILS_OUTBOUND_SELECT(
  OUT_CLOBData OUT NOCOPY CLOB
  ,OUT_RetMsg OUT VARCHAR2 );

 PROCEDURE USP_F58INT11_BATCHUPDATE(SG$TRANSID_IN IN VARCHAR2
                                      ,SGAN8_IN NUMBER
                                         ,SGURLNAME_IN IN VARCHAR2
                                         ,SG$RSP_IN IN VARCHAR2
                                         ,SGLONGMSG_IN IN VARCHAR2
                                         ,SGUSER_IN VARCHAR2
                                         ,SGUPMJ_IN VARCHAR2
                                         ,SGUPMT_IN VARCHAR2
                                         ,SGCREATEDT_IN VARCHAR2
                                         ,API_RESPONSEDATA_IN IN CLOB
                                         ,P_RETMSG_OUT OUT VARCHAR2);

FUNCTION  UFN_F58INT11_ACKNOWLEDGEMENT_POLL_MultiplePoll(
                                        SGAN8_IN varchar := NULL
                                    ) RETURN NUMBER;

PROCEDURE USP_AMS_ACKNOWLEDGEMENT_SELECT_MultiplePolling(
                                        SGAN8_IN VARCHAR2
                                        ,OUT_CLOBData OUT NOCOPY CLOB
                                        ,OUT_RetMsg OUT VARCHAR2);

end PKG_AMS_OUTBOUND;








CREATE OR REPLACE EDITIONABLE PACKAGE BODY "BIZTALK"."PKG_AMS_OUTBOUND" is

  FUNCTION UFN_F58INT11_ACKNOWLEDGEMENT_POLL (
                                        SGAN8_IN VARCHAR2 := NULL,
                                        SGDOLLARSRCDEST_IN VARCHAR2 := NULL
                                    ) RETURN NUMBER IS
  --Return a count of 1 if at least one record is waiting to Be transmitted.
    ncount NUMBER;
    BEGIN

  --SET SGDOLLARSRCDEST_IN := 'SAP PRD';

    SELECT COUNT(*)
    INTO ncount
    FROM proddta.F58INT11
    WHERE SG$RSP = 'D'
    AND SGC75DCT = 'Case Acknowledgement'
    AND SGAN8 IN (
            with rws as (
              select SGAN8_IN as str from dual
            )
              select regexp_substr (
                       str,
                       '[^|]+',
                       1,
                       level
                     ) value
              from   rws
              connect by level <=
                length ( str ) - length ( replace ( str, '|' ) ) + 1
    )
    AND (SGDOLLARSRCDEST_IN IS NULL OR SG$SRCDEST = RPAD(SGDOLLARSRCDEST_IN, 50));

    return(ncount);
  end UFN_F58INT11_ACKNOWLEDGEMENT_POLL;

  FUNCTION UFN_F58INT11_RECEIVING_POLL (
                                        SGAN8_IN VARCHAR2 := NULL,
                                        SGDOLLARSRCDEST_IN VARCHAR2 := NULL
                                    ) RETURN NUMBER IS
  --Return a count of 1 if at least one record is waiting to Be transmitted.
    ncount NUMBER;
  BEGIN
    SELECT COUNT(*)
    INTO ncount
    FROM proddta.F58INT11
    WHERE SG$RSP = 'D'
    AND SGC75DCT = 'Receiving'
    AND SGAN8 IN (
            with rws as (
              select SGAN8_IN as str from dual
            )
              select regexp_substr (
                       str,
                       '[^|]+',
                       1,
                       level
                     ) value
              from   rws
              connect by level <=
                length ( str ) - length ( replace ( str, '|' ) ) + 1
    )
    AND (SGDOLLARSRCDEST_IN IS NULL OR SG$SRCDEST = RPAD(SGDOLLARSRCDEST_IN, 50));

    return(ncount);
  end UFN_F58INT11_RECEIVING_POLL;

  FUNCTION UFN_F58INT11_WO_POLL (
                                        SGAN8_IN VARCHAR2 := NULL,
                                        SGDOLLARSRCDEST_IN VARCHAR2 := NULL
                                    ) RETURN NUMBER IS
  --Return a count of 1 if at least one record is waiting to Be transmitted.
    ncount NUMBER;
  BEGIN
    SELECT COUNT(*)
    INTO ncount
    FROM proddta.F58INT11
    WHERE SG$RSP = 'D'
    AND (SGC75DCT = 'WO In Process'
         OR SGC75DCT = 'WO Completion')
    AND SGAN8 IN (
            with rws as (
              select SGAN8_IN as str from dual
            )
              select regexp_substr (
                       str,
                       '[^|]+',
                       1,
                       level
                     ) value
              from   rws
              connect by level <=
                length ( str ) - length ( replace ( str, '|' ) ) + 1
    )
    AND (SGDOLLARSRCDEST_IN IS NULL OR SG$SRCDEST = RPAD(SGDOLLARSRCDEST_IN, 50));

    return(ncount);
  end UFN_F58INT11_WO_POLL;

FUNCTION UFN_F58INT11_SHIPPING_POLL (
                                        SGAN8_IN VARCHAR2 := NULL,
                                        SGDOLLARSRCDEST_IN VARCHAR2 := NULL
                                    ) RETURN NUMBER IS
  --Return a count of 1 if at least one record is waiting to Be transmitted.
    ncount NUMBER;
  BEGIN
    SELECT COUNT(*)
    INTO ncount
    FROM proddta.F58INT11
    WHERE SG$RSP = 'D'
    AND SGC75DCT = 'Shipping Details'
    AND SGAN8 IN (
            with rws as (
              select SGAN8_IN as str from dual
            )
              select regexp_substr (
                       str,
                       '[^|]+',
                       1,
                       level
                     ) value
              from   rws
              connect by level <=
                length ( str ) - length ( replace ( str, '|' ) ) + 1
    )
    AND (SGDOLLARSRCDEST_IN IS NULL OR SG$SRCDEST = RPAD(SGDOLLARSRCDEST_IN, 50));

    return(ncount);
  end UFN_F58INT11_SHIPPING_POLL;


FUNCTION UFN_ISODATE_TO_DATE (ISODateString VARCHAR := NULL)
RETURN DATE is
  --Return a date from ISO Date
    ConvertedDate DATE;
  BEGIN

    IF ISODateString IS NULL THEN
        SELECT NULL INTO ConvertedDate FROM DUAL;
    ELSE
        SELECT TO_DATE(SUBSTR(ISODateString, 1, 19),
        'YYYY-MM-DD"T"HH24:MI:SS') INTO ConvertedDate FROM DUAL;
    END IF;

    return(ConvertedDate);
  end UFN_ISODATE_TO_DATE;

 PROCEDURE USP_AMS_ACKNOWLEDGEMENT_SELECT(SGAN8_IN VARCHAR2 := NULL, SGDOLLARSRCDEST_IN VARCHAR2 := NULL, OUT_CLOBData OUT NOCOPY CLOB, OUT_RetMsg OUT VARCHAR2 ) IS
      --Declarations
      Temp_RetMsg VARCHAR2(4000):='';
      v_TransmissionID VARCHAR(150);
      v_Customer NUMBER;

      l_domdoc dbms_xmldom.DOMDocument;
      l_xmltype XMLTYPE;

      l_root_node dbms_xmldom.DOMNode;

      l_DOCUMENT_INFO_node dbms_xmldom.DOMNode;

      l_EXTENDED_DATA_node dbms_xmldom.DOMNode;

      l_RECIPIENT_INFO_element dbms_xmldom.DOMElement;
      l_RECIPIENT_INFO_node dbms_xmldom.DOMNode;

      l_CASE_ACKN_DETAILS_element dbms_xmldom.DOMElement;
      l_CASE_ACKN_DETAILS_node dbms_xmldom.DOMNode;

      l_SENDER_INFO_element dbms_xmldom.DOMElement;
      l_SENDER_INFO_node dbms_xmldom.DOMNode;

      l_UKID_node dbms_xmldom.DOMNode;
      l_UKID_textnode dbms_xmldom.DOMNode;

      l_AN8_node dbms_xmldom.DOMNode;
      l_AN8_textnode dbms_xmldom.DOMNode;

      l_DOCUMENT_TYPE_node dbms_xmldom.DOMNode;
      l_DOCUMENT_TYPE_textnode dbms_xmldom.DOMNode;

      l_MODULE_node dbms_xmldom.DOMNode;
      l_MODULE_textnode dbms_xmldom.DOMNode;

      l_VERSION_node dbms_xmldom.DOMNode;
      l_VERSION_textnode dbms_xmldom.DOMNode;

      l_TEST_FLAG_node dbms_xmldom.DOMNode;
      l_TEST_FLAG_textnode dbms_xmldom.DOMNode;

      l_TRANSMISSION_DATE_node dbms_xmldom.DOMNode;
      l_TRANSMISSION_DATE_textnode dbms_xmldom.DOMNode;

      l_TRANSMISSION_ID_node dbms_xmldom.DOMNode;
      l_TRANSMISSION_ID_textnode dbms_xmldom.DOMNode;

      l_CUSTOMER_node dbms_xmldom.DOMNode;
      l_CUSTOMER_textnode dbms_xmldom.DOMNode;

      l_MPF_node dbms_xmldom.DOMNode;
      l_MPF_textnode dbms_xmldom.DOMNode;

      l_DESTINATION_ERP_node dbms_xmldom.DOMNode;
      l_DESTINATION_ERP_textnode dbms_xmldom.DOMNode;

      l_COMPANY_node dbms_xmldom.DOMNode;
      l_COMPANY_textnode dbms_xmldom.DOMNode;

      l_ACKN_BRANCH_PLANT_node dbms_xmldom.DOMNode;
      l_ACKN_BRANCH_PLANT_textnode dbms_xmldom.DOMNode;

      l_PLXS_CASE_NUMBER_node dbms_xmldom.DOMNode;
      l_PLXS_CASE_NUMBER_textnode dbms_xmldom.DOMNode;

      l_CUSTOMER_REFERENCE1_node dbms_xmldom.DOMNode;
      l_CUSTOMER_REFERENCE1_textnode dbms_xmldom.DOMNode;

      l_CUSTOMER_REFERENCE2_node dbms_xmldom.DOMNode;
      l_CUSTOMER_REFERENCE2_textnode dbms_xmldom.DOMNode;

      l_CUSTOMER_REFERENCE3_node dbms_xmldom.DOMNode;
      l_CUSTOMER_REFERENCE3_textnode dbms_xmldom.DOMNode;

      l_PLXS_ITEM_NUMBER_node dbms_xmldom.DOMNode;
      l_PLXS_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;

      l_ITEM_DESC_node dbms_xmldom.DOMNode;
      l_ITEM_DESC_textnode dbms_xmldom.DOMNode;

      l_CUSTOMER_ITEM_NUMBER_node dbms_xmldom.DOMNode;
      l_CUSTOMER_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;

      l_CUSTOMER_REV_node dbms_xmldom.DOMNode;
      l_CUSTOMER_REV_textnode dbms_xmldom.DOMNode;

      l_LOT_SERIAL_NUMBER_node dbms_xmldom.DOMNode;
      l_LOT_SERIAL_NUMBER_textnode dbms_xmldom.DOMNode;

      l_QTY_node dbms_xmldom.DOMNode;
      l_QTY_textnode dbms_xmldom.DOMNode;

      l_AREA_TYPE_node dbms_xmldom.DOMNode;
      l_AREA_TYPE_textnode dbms_xmldom.DOMNode;

      l_AREA_DESC_node dbms_xmldom.DOMNode;
      l_AREA_DESC_textnode dbms_xmldom.DOMNode;

      l_STATUS_node dbms_xmldom.DOMNode;
      l_STATUS_textnode dbms_xmldom.DOMNode;

      l_ERROR_MESSAGE_node dbms_xmldom.DOMNode;
      l_ERROR_MESSAGE_textnode dbms_xmldom.DOMNode;

      TEMP_UKID NUMBER;
      TEMP_AN8 NUMBER;
      TEMP_$TRANSID VARCHAR(150);
      TEMP_C75DCT VARCHAR(60);
      TEMP_LRSSM VARCHAR(5);
      TEMP_B76VER NUMBER;
      TEMP_$TSTFLAG VARCHAR(1);
      TEMP_UPMJ VARCHAR(20);
      TEMP_UPMT VARCHAR(20);
      TEMP_ALPH VARCHAR(40);
      TEMP_$MPFNUM VARCHAR(25);
      TEMP_$SRCDEST VARCHAR(50);
      TEMP_$SERMCU VARCHAR(15);
      TEMP_DOCO VARCHAR(8);
      TEMP_RF1 VARCHAR(30);
      TEMP_RF2 VARCHAR(30);
      TEMP_RF3 VARCHAR(30);
      TEMP_LITM VARCHAR(25);
      TEMP_DSC1 VARCHAR(30);
      TEMP_$CUSPRTN VARCHAR(30);
      TEMP_DL03 VARCHAR(30);
      TEMP_LOTN VARCHAR(30);
      TEMP_TRQT NUMBER;
      TEMP_$NOTETYP VARCHAR(100);
      TEMP_GPTX VARCHAR(1500);
      TEMP_STTUS VARCHAR(10);
      TEMP_$VALMSG VARCHAR(2000);

   BEGIN
      --Creates an exmpty XML Document
      l_domdoc := dbms_xmldom.newDOMDocument;

      --Creates a root node
      l_root_node := dbms_xmldom.makeNode(l_domdoc);

      BEGIN

          -- Find first record to be sent
          SELECT sg$transid
                ,sgan8
          INTO v_TransmissionID
          ,v_Customer
          FROM proddta.F58INT11
          WHERE ROWNUM = 1
          AND SGC75DCT = 'Case Acknowledgement'
          AND sg$rsp = 'D'
          --AND sg$transid = 'ACK000000000000234'
          AND SGAN8 IN (
                with rws as (
                  select SGAN8_IN as str from dual
                )
                  select regexp_substr (
                           str,
                           '[^|]+',
                           1,
                           level
                         ) value
                  from   rws
                  connect by level <=
                    length ( str ) - length ( replace ( str, '|' ) ) + 1
            )
          AND (SGDOLLARSRCDEST_IN IS NULL OR SG$SRCDEST = RPAD(SGDOLLARSRCDEST_IN, 50))
          ORDER BY sg$transid;


          --Update record that is being processed
            UPDATE proddta.F58INT11
            SET sg$rsp = 'B'
                ,sguser = 'BIZTALK'
                ,sgupmt = to_char(cast(SYSDATE as date),'hh24miss')
                ,sgupmj = To_Number(To_Char(To_Number(To_Char(sysdate, 'yyyy')) - 1900) || To_Char(sysdate, 'ddd'))
            WHERE sg$transid = v_TransmissionID
            AND sgan8 = v_Customer;
          COMMIT;

          --Create Header or Non-Repeating XML nodes based on one record of the
          --TransmissionID/Customer Number
          FOR AMS_HEADER_REC in
              (SELECT TRIM(sgukid) sgukid
                      ,SGAN8
                      ,TRIM(sg$transid) sg$transid
                      ,TRIM(sgc75dct) sgc75dct
                      ,TRIM(sglrssm) sglrssm
                      ,TRIM(sgb76ver) sgb76ver
                      ,TRIM(sg$tstflag)sg$tstflag
                      ,TRIM(sgupmj) sgupmj
                      ,TRIM(sgupmt) sgupmt
                      ,TRIM(sgalph) sgalph
                      ,TRIM(sg$mpfnum) sg$mpfnum
                      ,TRIM(sg$srcdest) sg$srcdest
               FROM proddta.F58INT11
               WHERE sg$transid = v_TransmissionID
               AND sgan8 = v_Customer
               AND ROWNUM = 1)

              LOOP
                TEMP_UKID := AMS_HEADER_REC.SGUKID;
                TEMP_AN8 := AMS_HEADER_REC.SGAN8;
                TEMP_$TRANSID := AMS_HEADER_REC.SG$TRANSID;
                TEMP_C75DCT := AMS_HEADER_REC.SGC75DCT ;
                TEMP_LRSSM:= AMS_HEADER_REC.SGLRSSM ;
                TEMP_B76VER := AMS_HEADER_REC.SGB76VER;
                TEMP_$TSTFLAG := AMS_HEADER_REC.SG$TSTFLAG;
                TEMP_UPMJ:= AMS_HEADER_REC.SGUPMJ;
                TEMP_UPMT := AMS_HEADER_REC.SGUPMT;
                TEMP_ALPH:= AMS_HEADER_REC.SGALPH;
                TEMP_$MPFNUM:= AMS_HEADER_REC.SG$MPFNUM;
                TEMP_$SRCDEST := ams_header_rec.sg$srcdest;

                 --Create the XML structure for the Header/Non repeating sections
                l_DOCUMENT_INFO_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'DOCUMENT_INFO')));

                l_an8_node := dbms_xmldom.appendChild(l_DOCUMENT_INFO_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AN8' )));
                l_an8_textnode := dbms_xmldom.appendChild( l_an8_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_an8 )));

                l_DOCUMENT_TYPE_node := dbms_xmldom.appendChild(l_DOCUMENT_INFO_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DOCUMENT_TYPE' )));
                l_DOCUMENT_TYPE_textnode := dbms_xmldom.appendChild( l_DOCUMENT_TYPE_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_C75DCT )));

                l_MODULE_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'MODULE' )));
                l_MODULE_textnode := dbms_xmldom.appendChild( l_MODULE_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_LRSSM )));

                l_VERSION_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'VERSION' )));
                l_VERSION_textnode := dbms_xmldom.appendChild( l_VERSION_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_B76VER )));

                l_TEST_FLAG_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                       , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TEST_FLAG' )));
                l_TEST_FLAG_textnode := dbms_xmldom.appendChild( l_TEST_FLAG_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$TSTFLAG)));

                l_TRANSMISSION_DATE_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRANSMISSION_DATE' )));
                l_TRANSMISSION_DATE_textnode := dbms_xmldom.appendChild( l_TRANSMISSION_DATE_node
                                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP),'YYYY-MM-DD"T"HH24:MI:SS.ff3"Z"') )));

                l_TRANSMISSION_ID_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRANSMISSION_ID' )));
                l_TRANSMISSION_ID_textnode := dbms_xmldom.appendChild( l_TRANSMISSION_ID_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$TRANSID)));

                l_RECIPIENT_INFO_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'RECIPIENT_INFO')));

                l_CUSTOMER_node := dbms_xmldom.appendChild(l_RECIPIENT_INFO_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER' )));
                l_CUSTOMER_textnode := dbms_xmldom.appendChild( l_CUSTOMER_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_ALPH )));

                l_MPF_node := dbms_xmldom.appendChild(l_RECIPIENT_INFO_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'MPF' )));
                l_MPF_textnode := dbms_xmldom.appendChild( l_MPF_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$MPFNUM)));
                l_DESTINATION_ERP_node := dbms_xmldom.appendChild(l_RECIPIENT_INFO_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DESTINATION_ERP' )));
                l_DESTINATION_ERP_textnode := dbms_xmldom.appendChild( l_DESTINATION_ERP_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$SRCDEST )));

                l_SENDER_INFO_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'SENDER_INFO')));

                l_COMPANY_node := dbms_xmldom.appendChild(l_SENDER_INFO_node
                                                       , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'COMPANY' )));
                l_COMPANY_textnode := dbms_xmldom.appendChild( l_COMPANY_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, 'Plexus Corp.' )));
              end loop;

             --Create Detail or repeating section of the XML based on TransmissionID and Customer
           FOR AMS_OUT_REC in
               (SELECT TRIM(sgukid) sgukid
                       ,TRIM(sg$sermcu) sg$sermcu
                       ,TRIM(sgdoco) sgdoco
                       ,TRIM(sgrf1) sgrf1
                       ,TRIM(sgrf2) sgrf2
                       ,TRIM(sgrf3) sgrf3
                       ,TRIM(sglitm) sglitm
                       ,TRIM(sgdsc1) sgdsc1
                       ,TRIM(sg$cusprtn) sg$cusprtn
                       ,TRIM(sgdl03) sgdl03
                       ,TRIM(sg$cuslitm) sg$cuslitm
                       ,TRIM(sglotn) sglotn
                       ,TRIM(sgtrqt) sgtrqt
                       ,TRIM(sg$gs04) sg$gs04
                       ,TRIM(sgsttus) sgsttus
                       ,TRIM(sg$valmsg) sg$valmsg

                FROM proddta.F58INT11
                WHERE sg$transid = v_TransmissionID
                AND sgan8 = v_Customer)

                LOOP

                TEMP_UKID := AMS_OUT_REC.SGUKID;
                TEMP_$SERMCU:= AMS_OUT_REC.SG$SERMCU;
                TEMP_DOCO:= AMS_OUT_REC.SGDOCO;
                TEMP_RF1:= AMS_OUT_REC.SGRF1;
                TEMP_RF2:= AMS_OUT_REC.SGRF2;
                TEMP_RF3:= AMS_OUT_REC.SGRF3;
                TEMP_LITM:= AMS_OUT_REC.SGLITM;
                TEMP_DSC1:= AMS_OUT_REC.SGDSC1;
                TEMP_$CUSPRTN:= AMS_OUT_REC.SG$CUSPRTN;
                TEMP_DL03:= AMS_OUT_REC.SGDL03;
                TEMP_LOTN:= AMS_OUT_REC.SGLOTN;
                TEMP_TRQT := AMS_OUT_REC.SGTRQT;
                TEMP_STTUS := AMS_OUT_REC.Sgsttus;
                TEMP_$VALMSG := AMS_OUT_REC.Sg$valmsg;

                l_CASE_ACKN_DETAILS_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'CASE_ACKN_DETAILS')));

                l_ukid_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'UNIQUE_ID' )));
                l_ukid_textnode := dbms_xmldom.appendChild( l_ukid_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_ukid )));

                l_ACKN_BRANCH_PLANT_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ACKN_BRANCH_PLANT' )));
                l_ACKN_BRANCH_PLANT_textnode := dbms_xmldom.appendChild( l_ACKN_BRANCH_PLANT_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$SERMCU )));

                l_PLXS_CASE_NUMBER_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_CASE_NUMBER' )));
                l_PLXS_CASE_NUMBER_textnode := dbms_xmldom.appendChild( l_PLXS_CASE_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_DOCO )));

                l_CUSTOMER_REFERENCE1_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE1' )));
                l_CUSTOMER_REFERENCE1_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REFERENCE1_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_RF1 )));

                l_CUSTOMER_REFERENCE2_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE2' )));
                l_CUSTOMER_REFERENCE2_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REFERENCE2_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_RF2 )));

                l_CUSTOMER_REFERENCE3_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE3' )));
                l_CUSTOMER_REFERENCE3_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REFERENCE3_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_RF3 )));

                l_PLXS_ITEM_NUMBER_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_ITEM_NUMBER' )));
                l_PLXS_ITEM_NUMBER_textnode := dbms_xmldom.appendChild( l_PLXS_ITEM_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_LITM )));

                l_ITEM_DESC_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ITEM_DESC' )));
                l_ITEM_DESC_textnode := dbms_xmldom.appendChild( l_ITEM_DESC_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_DSC1 )));

                l_CUSTOMER_ITEM_NUMBER_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_ITEM_NUMBER' )));
                l_CUSTOMER_ITEM_NUMBER_textnode := dbms_xmldom.appendChild( l_CUSTOMER_ITEM_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$CUSPRTN )));

                l_CUSTOMER_REV_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REV' )));
                l_CUSTOMER_REV_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REV_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_DL03 )));

                l_LOT_SERIAL_NUMBER_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'LOT_SERIAL_NUMBER' )));
                l_LOT_SERIAL_NUMBER_textnode := dbms_xmldom.appendChild( l_LOT_SERIAL_NUMBER_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_LOTN )));

                l_QTY_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'QTY' )));
                l_QTY_textnode := dbms_xmldom.appendChild( l_QTY_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_TRQT )));

                l_EXTENDED_DATA_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'EXTENDED_DATA')));

                FOR AMS_OUT_EXT_REC in
               (SELECT TRIM(nt$notetyp ) nt$notetyp
                       ,TRIM(ntgptx) ntgptx
                FROM proddta.f58INT12
                WHERE ntukid = TEMP_UKID
                AND   ntc75dct =  RPAD(TRIM(TEMP_C75DCT),60)
                    )
                LOOP
                TEMP_$notetyp := ams_out_ext_rec.nt$notetyp;
                TEMP_GPTX := ams_out_ext_rec.ntgptx;

                  l_AREA_TYPE_node := dbms_xmldom.appendChild(l_EXTENDED_DATA_node
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AREA_TYPE' )));
                  l_AREA_TYPE_textnode := dbms_xmldom.appendChild( l_AREA_TYPE_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$notetyp )));

                  l_AREA_DESC_node := dbms_xmldom.appendChild(l_EXTENDED_DATA_node
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AREA_DESC' )));
                  l_AREA_DESC_textnode := dbms_xmldom.appendChild( l_AREA_DESC_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_GPTX)));
                END LOOP;

                l_STATUS_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'STATUS' )));
                l_STATUS_textnode := dbms_xmldom.appendChild( l_STATUS_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_STTUS )));

                l_ERROR_MESSAGE_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ERROR_MESSAGE' )));
                l_ERROR_MESSAGE_textnode := dbms_xmldom.appendChild( l_ERROR_MESSAGE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$VALMSG )));

            END LOOP;

        EXCEPTION
             WHEN OTHERS THEN

             --UPDATE PRODDTA.F58INT11 SET SG$RSP='E' WHERE sg$transid = v_TransmissionID AND sgan8 = v_Customer;
             --COMMIT;

             Temp_RetMsg :='Error: - '||SQLCODE||' -ERROR- '||substr(SQLERRM,1,2000) || ' -TransmissionID - '||NVL(v_TransmissionID, '') ||' -Customer- '||NVL(v_Customer, '');
        END; --END TRANSACTION

        l_xmltype := dbms_xmldom.getXmlType(l_domdoc);
        dbms_xmldom.freeDocument(l_domdoc);

        OUT_CLOBData := l_xmltype.getClobVal;

        OUT_RetMsg :=  Temp_RetMsg;

    END;

 PROCEDURE USP_AMS_RECEIVING_SELECT(SGAN8_IN VARCHAR2 := NULL, SGDOLLARSRCDEST_IN VARCHAR2 := NULL, OUT_CLOBData OUT NOCOPY CLOB, OUT_RetMsg OUT VARCHAR2 ) IS
          Temp_RetMsg VARCHAR2(4000):='';

          v_TransmissionID VARCHAR(150);
          v_Customer NUMBER;
          l_domdoc dbms_xmldom.DOMDocument;
          l_xmltype XMLTYPE;

          l_root_node dbms_xmldom.DOMNode;

          l_DOCUMENT_INFO_node dbms_xmldom.DOMNode;

          l_RECIPIENT_INFO_element dbms_xmldom.DOMElement;
          l_RECIPIENT_INFO_node dbms_xmldom.DOMNode;

          l_RECEIVING_DETAIL_element dbms_xmldom.DOMElement;
          l_RECEIVING_DETAIL_node dbms_xmldom.DOMNode;

          l_SHIP_TO_INFO_element dbms_xmldom.DOMElement;
          l_SHIP_TO_INFO_node dbms_xmldom.DOMNode;

          l_SENDER_INFO_element dbms_xmldom.DOMElement;
          l_SENDER_INFO_node dbms_xmldom.DOMNode;

          l_UKID_node dbms_xmldom.DOMNode;
          l_UKID_textnode dbms_xmldom.DOMNode;

          l_AN8_node dbms_xmldom.DOMNode;
          l_AN8_textnode dbms_xmldom.DOMNode;

          l_DOCUMENT_TYPE_node dbms_xmldom.DOMNode;
          l_DOCUMENT_TYPE_textnode dbms_xmldom.DOMNode;

          l_MODULE_node dbms_xmldom.DOMNode;
          l_MODULE_textnode dbms_xmldom.DOMNode;

          l_VERSION_node dbms_xmldom.DOMNode;
          l_VERSION_textnode dbms_xmldom.DOMNode;

          l_TEST_FLAG_node dbms_xmldom.DOMNode;
          l_TEST_FLAG_textnode dbms_xmldom.DOMNode;

          l_TRANSMISSION_DATE_node dbms_xmldom.DOMNode;
          l_TRANSMISSION_DATE_textnode dbms_xmldom.DOMNode;

          l_TRANSMISSION_ID_node dbms_xmldom.DOMNode;
          l_TRANSMISSION_ID_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_node dbms_xmldom.DOMNode;
          l_CUSTOMER_textnode dbms_xmldom.DOMNode;

          l_MPF_node dbms_xmldom.DOMNode;
          l_MPF_textnode dbms_xmldom.DOMNode;

          l_DESTINATION_ERP_node dbms_xmldom.DOMNode;
          l_DESTINATION_ERP_textnode dbms_xmldom.DOMNode;

          l_COMPANY_node dbms_xmldom.DOMNode;
          l_COMPANY_textnode dbms_xmldom.DOMNode;

          l_BRANCH_PLANT_node dbms_xmldom.DOMNode;
          l_BRANCH_PLANT_textnode dbms_xmldom.DOMNode;

          l_PLXS_CASE_NUMBER_node dbms_xmldom.DOMNode;
          l_PLXS_CASE_NUMBER_textnode dbms_xmldom.DOMNode;

          l_RECEIPT_NUMBER_node dbms_xmldom.DOMNode;
          l_RECEIPT_NUMBER_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_REFERENCE1_node dbms_xmldom.DOMNode;
          l_CUSTOMER_REFERENCE1_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_REFERENCE2_node dbms_xmldom.DOMNode;
          l_CUSTOMER_REFERENCE2_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_REFERENCE3_node dbms_xmldom.DOMNode;
          l_CUSTOMER_REFERENCE3_textnode dbms_xmldom.DOMNode;

          l_PLXS_ITEM_NUMBER_node dbms_xmldom.DOMNode;
          l_PLXS_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;

          l_ITEM_DESC_node dbms_xmldom.DOMNode;
          l_ITEM_DESC_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_ITEM_NUMBER_node dbms_xmldom.DOMNode;
          l_CUSTOMER_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_REV_node dbms_xmldom.DOMNode;
          l_CUSTOMER_REV_textnode dbms_xmldom.DOMNode;

          l_SECONDARY_CUSTOMER_ITEM_NUMBER_node dbms_xmldom.DOMNode;
          l_SECONDARY_CUSTOMER_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;

          l_LOT_SERIAL_NUMBER_node dbms_xmldom.DOMNode;
          l_LOT_SERIAL_NUMBER_textnode dbms_xmldom.DOMNode;

          l_QTY_node dbms_xmldom.DOMNode;
          l_QTY_textnode dbms_xmldom.DOMNode;

          l_DOCK_DATE_node dbms_xmldom.DOMNode;
          l_DOCK_DATE_textnode dbms_xmldom.DOMNode;

          l_RECEIPT_DATE_node dbms_xmldom.DOMNode;
          l_RECEIPT_DATE_textnode dbms_xmldom.DOMNode;

          l_INBOUND_TRACKING_NUMBER_node dbms_xmldom.DOMNode;
          l_INBOUND_TRACKING_NUMBER_textnode dbms_xmldom.DOMNode;

          l_RETURN_REASON_node dbms_xmldom.DOMNode;
          l_RETURN_REASON_textnode dbms_xmldom.DOMNode;

          l_RCVR_NOTE_node dbms_xmldom.DOMNode;
          l_RCVR_NOTE_textnode dbms_xmldom.DOMNode;

          l_NAME_node dbms_xmldom.DOMNode;
          l_NAME_textnode dbms_xmldom.DOMNode;

          l_ADDRESS1_node dbms_xmldom.DOMNode;
          l_ADDRESS1_textnode dbms_xmldom.DOMNode;

          l_ADDRESS2_node dbms_xmldom.DOMNode;
          l_ADDRESS2_textnode dbms_xmldom.DOMNode;

          l_ADDRESS3_node dbms_xmldom.DOMNode;
          l_ADDRESS3_textnode dbms_xmldom.DOMNode;

          l_ADDRESS4_node dbms_xmldom.DOMNode;
          l_ADDRESS4_textnode dbms_xmldom.DOMNode;

          l_CITY_node dbms_xmldom.DOMNode;
          l_CITY_textnode dbms_xmldom.DOMNode;

          l_ZIP_CODE_node dbms_xmldom.DOMNode;
          l_ZIP_CODE_textnode dbms_xmldom.DOMNode;

          l_STATE_node dbms_xmldom.DOMNode;
          l_STATE_textnode dbms_xmldom.DOMNode;

          l_COUNTRY_node dbms_xmldom.DOMNode;
          l_COUNTRY_textnode dbms_xmldom.DOMNode;

          l_AREACODE_node dbms_xmldom.DOMNode;
          l_AREACODE_textnode dbms_xmldom.DOMNode;

          l_PHONE_node dbms_xmldom.DOMNode;
          l_PHONE_textnode dbms_xmldom.DOMNode;

          l_CONTACT_FN_node dbms_xmldom.DOMNode;
          l_CONTACT_FN_textnode dbms_xmldom.DOMNode;

          l_CONTACT_LN_node dbms_xmldom.DOMNode;
          l_CONTACT_LN_textnode dbms_xmldom.DOMNode;

          TEMP_UKID NUMBER;
          TEMP_AN8 NUMBER;
          TEMP_C75DCT VARCHAR(60);
          TEMP_LRSSM VARCHAR(5);
          TEMP_B76VER NUMBER;
          TEMP_$TSTFLAG VARCHAR(1);
          TEMP_UPMJ VARCHAR(20);
          TEMP_UPMT VARCHAR(20);
          TEMP_ALPH VARCHAR(40);
          TEMP_$MPFNUM VARCHAR(25);
          TEMP_$transid VARCHAR(150);
          TEMP_$SRCDEST VARCHAR(100);
          TEMP_$SERMCU VARCHAR(15);
          TEMP_DOCO VARCHAR(8);
          TEMP_ANUR VARCHAR(8);
          TEMP_RF1 VARCHAR(30);
          TEMP_RF2 VARCHAR(30);
          TEMP_RF3 VARCHAR(30);
          TEMP_LITM VARCHAR(25);
          TEMP_DSC1 VARCHAR(30);

          TEMP_$CUSPRTN VARCHAR(30);
          TEMP_DL03 VARCHAR(30);
          TEMP_$CUSTLITM VARCHAR(50);
          TEMP_LOTN VARCHAR(30);
          TEMP_TRQT NUMBER;
          TEMP_RECDATE VARCHAR(25);
          TEMP_RCTM VARCHAR(10);
          TEMP_$TRK VARCHAR(64);
          TEMP_ISSUE VARCHAR(80);
          TEMP_96NOTES VARCHAR(250);
          TEMP_SHANAPLH VARCHAR(40);
          TEMP_SHL1 VARCHAR(40);
          TEMP_SHL2 VARCHAR(40);
          TEMP_SHL3 VARCHAR(40);
          TEMP_SHL4 VARCHAR(40);
          TEMP_VSTCT VARCHAR(25);
          TEMP_ZIPCD VARCHAR(12);
          TEMP_STPROV VARCHAR(5);
          TEMP_CNTRYDES VARCHAR(5);
          TEMP_AR1 VARCHAR(6);
          TEMP_TELNUMB VARCHAR(20);
          TEMP_GNNM VARCHAR(25);
          TEMP_SRNM VARCHAR(25);
          TEMP_DOCKDATE varchar(25);

    BEGIN

        --Creates an exmpty XML Document
         l_domdoc := dbms_xmldom.newDOMDocument;

         --Creates a root node
         l_root_node := dbms_xmldom.makeNode(l_domdoc);

         BEGIN

          SELECT sg$transid
                ,sgan8
          INTO v_TransmissionID
          ,v_Customer
          FROM proddta.F58INT11
          WHERE ROWNUM = 1
          AND SGC75DCT = 'Receiving'
          AND sg$rsp = 'D'
          --AND sg$transid = 'REC001'
          AND SGAN8 IN (
                with rws as (
                  select SGAN8_IN as str from dual
                )
                  select regexp_substr (
                           str,
                           '[^|]+',
                           1,
                           level
                         ) value
                  from   rws
                  connect by level <=
                    length ( str ) - length ( replace ( str, '|' ) ) + 1
            )
          AND (SGDOLLARSRCDEST_IN IS NULL OR SG$SRCDEST = RPAD(SGDOLLARSRCDEST_IN, 50))
          ORDER BY sg$transid;

           --Update record that is being processed
            UPDATE proddta.F58INT11
            SET sg$rsp = 'B'
                ,sguser = 'BIZTALK'
                ,sgupmt = to_char(cast(SYSDATE as date),'hh24miss')
                ,sgupmj = To_Number(To_Char(To_Number(To_Char(sysdate, 'yyyy')) - 1900) || To_Char(sysdate, 'ddd'))
            WHERE sg$transid = v_TransmissionID
            AND sgan8 = v_Customer;
            COMMIT;

            FOR AMS_HEAD_OUT_REC in
                (SELECT TRIM(sgan8) sgan8
                    ,TRIM(sgc75dct) sgc75dct
                   ,TRIM(sglrssm) sglrssm
                   ,TRIM(sgb76ver) sgb76ver
                   ,TRIM(sg$tstflag)sg$tstflag
                   ,TRIM(sgupmj) sgupmj
                   ,TRIM(sgupmt) sgupmt
                   ,TRIM(sgalph) sgalph
                   ,TRIM(sg$mpfnum) sg$mpfnum
                   ,TRIM(sg$srcdest) sg$srcdest
                   ,TRIM(sg$transid) sg$transid
                 FROM proddta.F58INT11
                 WHERE sg$transid = v_TransmissionID
                  AND sgan8 = v_Customer
                  AND rownum = 1
                 )

                 LOOP


                TEMP_AN8 := AMS_HEAD_OUT_REC.sgan8;
                TEMP_C75DCT := AMS_HEAD_OUT_REC.SGC75DCT ;
                TEMP_LRSSM:= AMS_HEAD_OUT_REC.SGLRSSM ;
                TEMP_B76VER := AMS_HEAD_OUT_REC.SGB76VER;
                TEMP_$TSTFLAG := AMS_HEAD_OUT_REC.SG$TSTFLAG;
                TEMP_UPMJ:= AMS_HEAD_OUT_REC.SGUPMJ;
                TEMP_UPMT := AMS_HEAD_OUT_REC.SGUPMT;
                TEMP_ALPH:= AMS_HEAD_OUT_REC.SGALPH;
                TEMP_$MPFNUM:= AMS_HEAD_OUT_REC.SG$MPFNUM;
                TEMP_$SRCDEST:= AMS_HEAD_OUT_REC.SG$SRCDEST;  --??DO NOT KNOW SIZE
                TEMP_$transid := AMS_HEAD_OUT_REC.SG$TRANSID;




                 l_DOCUMENT_INFO_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'DOCUMENT_INFO')));

                 l_an8_node := dbms_xmldom.appendChild(l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AN8' )));
                 l_an8_textnode := dbms_xmldom.appendChild( l_an8_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_an8 )));


                 l_DOCUMENT_TYPE_node := dbms_xmldom.appendChild(l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DOCUMENT_TYPE' )));
                 l_DOCUMENT_TYPE_textnode := dbms_xmldom.appendChild( l_DOCUMENT_TYPE_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_C75DCT )));

                 l_MODULE_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'MODULE' )));
                 l_MODULE_textnode := dbms_xmldom.appendChild( l_MODULE_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_LRSSM )));

                 l_VERSION_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'VERSION' )));
                 l_VERSION_textnode := dbms_xmldom.appendChild( l_VERSION_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_B76VER )));

                 l_TEST_FLAG_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TEST_FLAG' )));
                 l_TEST_FLAG_textnode := dbms_xmldom.appendChild( l_TEST_FLAG_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$TSTFLAG)));

                 l_TRANSMISSION_DATE_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRANSMISSION_DATE' )));
                 l_TRANSMISSION_DATE_textnode := dbms_xmldom.appendChild( l_TRANSMISSION_DATE_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP),'YYYY-MM-DD"T"HH24:MI:SS"Z"') )));

                 l_TRANSMISSION_ID_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRANSMISSION_ID' )));
                 l_TRANSMISSION_ID_textnode := dbms_xmldom.appendChild( l_TRANSMISSION_ID_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,TEMP_$transid )));


                 l_RECIPIENT_INFO_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'RECIPIENT_INFO')));

                 l_CUSTOMER_node := dbms_xmldom.appendChild(l_RECIPIENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER' )));
                 l_CUSTOMER_textnode := dbms_xmldom.appendChild( l_CUSTOMER_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_ALPH )));

                 l_MPF_node := dbms_xmldom.appendChild(l_RECIPIENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'MPF' )));
                 l_MPF_textnode := dbms_xmldom.appendChild( l_MPF_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$MPFNUM)));
                 l_DESTINATION_ERP_node := dbms_xmldom.appendChild(l_RECIPIENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DESTINATION_ERP' )));
                 l_DESTINATION_ERP_textnode := dbms_xmldom.appendChild( l_DESTINATION_ERP_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$SRCDEST )));

                 l_SENDER_INFO_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'SENDER_INFO')));

                 l_COMPANY_node := dbms_xmldom.appendChild(l_SENDER_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'COMPANY' )));
                 l_COMPANY_textnode := dbms_xmldom.appendChild( l_COMPANY_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, 'Plexus Corp.' )));




       END LOOP;

            FOR AMS_OUT_REC in
                (SELECT
                   TRIM(sgukid) sgukid
                   ,TRIM(sg$sermcu) sg$sermcu
                   ,TRIM(sgdoco) sgdoco
                   ,TRIM(sganur) sganur
                   ,TRIM(sgrf1) sgrf1
                   ,TRIM(sgrf2) sgrf2
                   ,TRIM(sgrf3) sgrf3
                   ,TRIM(sglitm) sglitm
                   ,TRIM(sgdsc1) sgdsc1
                   ,TRIM(sg$cusprtn) sg$cusprtn
                   ,TRIM(sgdl03) sgdl03
                   ,TRIM(sg$cuslitm) sg$cuslitm
                   ,TRIM(sglotn) sglotn
                   ,TRIM(sgtrqt) sgtrqt
                   ,DECODE(sg$GS04,0,'0',TO_CHAR(TO_DATE(TO_CHAR(sg$GS04 + 1900000),'YYYYDDD'),'yyyy-mm-dd'))||'T'|| decode(sg54RCTT,0,'00:00:00',to_char(to_date(LPAD(TO_CHAR(sg54RCTT),6,'0') , 'hh24miss'),'hh24:mi:ss')) ||'Z' Dock_date
                   ,DECODE(sgrecdate,0,'0',TO_CHAR(TO_DATE(TO_CHAR(sgrecdate + 1900000),'YYYYDDD'),'yyyy-mm-dd'))||'T'|| decode(sgrctm,0,'00:00:00',to_char(to_date(LPAD(TO_CHAR(sgrctm),6,'0') , 'hh24miss'),'hh24:mi:ss'))||'Z' Rec_Date
                   ,TRIM(sg$trk) sg$trk
                   ,TRIM(sgissue) sgissue
                   ,TRIM(sg96notes) sg96notes
                   ,TRIM(sgshanalph) sgshanalph
                   ,TRIM(sgshl1) sgshl1
                   ,TRIM(sgshl2) sgshl2
                   ,TRIM(sgshl3) sgshl3
                   ,TRIM(sgshl4) sgshl4
                   ,TRIM(sgvstct) sgvstct
                   ,TRIM(sgzipcd) sgzipcd
                   ,TRIM(sgstprov) sgstprov
                   ,TRIM(sgcntrydes) sgcntrydes
                   ,TRIM(sgar1) sgar1
                   ,TRIM(sgtelnumb) sgtelnumb
                   ,TRIM(sggnnm) sggnnm
                   ,TRIM(sgsrnm) sgsrnm

                 FROM proddta.F58INT11
                 WHERE sg$transid = v_TransmissionID
                 AND sgan8 = v_Customer
                 )

                 LOOP
                TEMP_UKID := AMS_OUT_REC.SGUKID;
                TEMP_$SERMCU:= AMS_OUT_REC.SG$SERMCU;
                TEMP_DOCO:= AMS_OUT_REC.SGDOCO;
                TEMP_ANUR:= AMS_OUT_REC.SGANUR;
                TEMP_RF1:= AMS_OUT_REC.SGRF1;
                TEMP_RF2:= AMS_OUT_REC.SGRF2;
                TEMP_RF3:= AMS_OUT_REC.SGRF3;
                TEMP_LITM:= AMS_OUT_REC.SGLITM;
                TEMP_DSC1:= AMS_OUT_REC.SGDSC1;

                TEMP_$CUSPRTN:= AMS_OUT_REC.SG$CUSPRTN;
                TEMP_DL03:= AMS_OUT_REC.SGDL03;
                TEMP_$CUSTLITM := AMS_OUT_REC.SG$CUSLITM;
                TEMP_LOTN:= AMS_OUT_REC.SGLOTN;
                TEMP_TRQT := AMS_OUT_REC.SGTRQT;
                TEMP_DOCKDATE := AMS_OUT_REC.Dock_Date;
                TEMP_RECDATE :=ams_out_rec.rec_date;
                TEMP_$TRK := AMS_OUT_REC.SG$TRK;
                TEMP_ISSUE := AMS_OUT_REC.SGISSUE;
                TEMP_96NOTES:= AMS_OUT_REC.SG96NOTES;
                TEMP_SHANAPLH:= AMS_OUT_REC.SGSHANALPH;
                TEMP_SHL1:= AMS_OUT_REC.SGSHL1;
                TEMP_SHL2 :=AMS_OUT_REC.SGSHL2;
                TEMP_SHL3 :=AMS_OUT_REC.SGSHL3;
                TEMP_SHL4 :=AMS_OUT_REC.SGSHL4;
                TEMP_VSTCT := AMS_OUT_REC.SGVSTCT;
                TEMP_ZIPCD := AMS_OUT_REC.SGZIPCD;
                TEMP_STPROV:= AMS_OUT_REC.SGSTPROV;
                TEMP_CNTRYDES:= AMS_OUT_REC.SGCNTRYDES;
                TEMP_AR1 := AMS_OUT_REC.SGAR1;
                TEMP_TELNUMB:= AMS_OUT_REC.SGTELNUMB;
                TEMP_GNNM:= AMS_OUT_REC.SGGNNM;
                TEMP_SRNM := AMS_OUT_REC.SGSRNM;

         l_RECEIVING_DETAIL_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'RECEIVING_DETAIL')));

         l_ukid_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'UNIQUE_ID' )));
         l_ukid_textnode := dbms_xmldom.appendChild( l_ukid_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_ukid )));

         l_BRANCH_PLANT_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'RECEIVING_BRANCH_PLANT' )));
         l_BRANCH_PLANT_textnode := dbms_xmldom.appendChild( l_BRANCH_PLANT_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$SERMCU )));

         l_PLXS_CASE_NUMBER_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_CASE_NUMBER' )));
         l_PLXS_CASE_NUMBER_textnode := dbms_xmldom.appendChild( l_PLXS_CASE_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_DOCO )));

         l_RECEIPT_NUMBER_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'RECEIPT_NUMBER' )));
         l_RECEIPT_NUMBER_textnode := dbms_xmldom.appendChild( l_RECEIPT_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_ANUR )));


         l_CUSTOMER_REFERENCE1_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE1' )));
         l_CUSTOMER_REFERENCE1_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REFERENCE1_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_RF1 )));

         l_CUSTOMER_REFERENCE2_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE2' )));
         l_CUSTOMER_REFERENCE2_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REFERENCE2_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_RF2 )));

         l_CUSTOMER_REFERENCE3_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE3' )));
         l_CUSTOMER_REFERENCE3_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REFERENCE3_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_RF3 )));

         l_PLXS_ITEM_NUMBER_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_ITEM_NUMBER' )));
         l_PLXS_ITEM_NUMBER_textnode := dbms_xmldom.appendChild( l_PLXS_ITEM_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_LITM )));

         l_ITEM_DESC_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ITEM_DESC' )));
         l_ITEM_DESC_textnode := dbms_xmldom.appendChild( l_ITEM_DESC_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_DSC1 )));

         l_CUSTOMER_ITEM_NUMBER_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_ITEM_NUMBER' )));
         l_CUSTOMER_ITEM_NUMBER_textnode := dbms_xmldom.appendChild( l_CUSTOMER_ITEM_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$CUSPRTN )));

         l_CUSTOMER_REV_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REV' )));
         l_CUSTOMER_REV_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REV_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_DL03 )));

         l_SECONDARY_CUSTOMER_ITEM_NUMBER_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'SECONDARY_CUSTOMER_ITEM_NUMBER' )));
         l_SECONDARY_CUSTOMER_ITEM_NUMBER_textnode := dbms_xmldom.appendChild( l_SECONDARY_CUSTOMER_ITEM_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$CUSTLITM )));

         l_LOT_SERIAL_NUMBER_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'LOT_SERIAL_NUMBER' )));
         l_LOT_SERIAL_NUMBER_textnode := dbms_xmldom.appendChild( l_LOT_SERIAL_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_LOTN )));

         l_QTY_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'QTY' )));
         l_QTY_textnode := dbms_xmldom.appendChild( l_QTY_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_TRQT )));

         l_DOCK_DATE_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DOCK_DATE' )));
         l_DOCK_DATE_textnode := dbms_xmldom.appendChild( l_DOCK_DATE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_DOCKDATE )));

         l_RECEIPT_DATE_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'RECEIPT_DATE' )));
         l_RECEIPT_DATE_textnode := dbms_xmldom.appendChild( l_RECEIPT_DATE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_RECDATE )));

         l_INBOUND_TRACKING_NUMBER_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'INBOUND_TRACKING_NUMBER' )));
         l_INBOUND_TRACKING_NUMBER_textnode := dbms_xmldom.appendChild( l_INBOUND_TRACKING_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$TRK )));

         l_RETURN_REASON_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'RETURN_REASON' )));
         l_RETURN_REASON_textnode := dbms_xmldom.appendChild( l_RETURN_REASON_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_ISSUE )));

         l_RCVR_NOTE_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'RCVR_NOTE' )));
         l_RCVR_NOTE_textnode := dbms_xmldom.appendChild( l_RCVR_NOTE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_96NOTES )));

         l_SHIP_TO_INFO_node := dbms_xmldom.appendChild(l_RECEIVING_DETAIL_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'SHIP_TO_INFO')));


         l_NAME_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'NAME' )));
         l_NAME_textnode := dbms_xmldom.appendChild( l_NAME_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_SHANAPLH )));

         l_ADDRESS1_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ADDRESS1' )));
         l_ADDRESS1_textnode := dbms_xmldom.appendChild( l_ADDRESS1_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_SHL1 )));

         l_ADDRESS2_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ADDRESS2' )));
         l_ADDRESS2_textnode := dbms_xmldom.appendChild( l_ADDRESS2_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_SHL2 )));

         l_ADDRESS3_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ADDRESS3' )));
         l_ADDRESS3_textnode := dbms_xmldom.appendChild( l_ADDRESS3_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_SHL3 )));

         l_ADDRESS4_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ADDRESS4' )));
         l_ADDRESS4_textnode := dbms_xmldom.appendChild( l_ADDRESS4_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_SHL4 )));

         l_CITY_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CITY' )));
         l_CITY_textnode := dbms_xmldom.appendChild( l_CITY_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_VSTCT )));

         l_ZIP_CODE_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ZIP_CODE' )));
         l_ZIP_CODE_textnode := dbms_xmldom.appendChild( l_ZIP_CODE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_ZIPCD )));

         l_STATE_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'STATE' )));
         l_STATE_textnode := dbms_xmldom.appendChild( l_STATE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_STPROV )));

         l_COUNTRY_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'COUNTRY' )));
         l_COUNTRY_textnode := dbms_xmldom.appendChild( l_COUNTRY_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_CNTRYDES )));

         l_AREACODE_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AREACODE' )));
         l_AREACODE_textnode := dbms_xmldom.appendChild( l_AREACODE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_AR1 )));

         l_PHONE_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PHONE' )));
         l_PHONE_textnode := dbms_xmldom.appendChild( l_PHONE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_TELNUMB )));

         l_CONTACT_FN_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CONTACT_FN' )));
         l_CONTACT_FN_textnode := dbms_xmldom.appendChild( l_CONTACT_FN_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_GNNM )));

         l_CONTACT_LN_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CONTACT_LN' )));
         l_CONTACT_LN_textnode := dbms_xmldom.appendChild( l_CONTACT_LN_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_SRNM )));

        END LOOP;

        EXCEPTION
             WHEN OTHERS THEN

             --UPDATE PRODDTA.F58INT11 SET SG$RSP='E' WHERE sg$transid = v_TransmissionID AND sgan8 = v_Customer;
             --COMMIT;

             Temp_RetMsg :='Error: - '||SQLCODE||' -ERROR- '||substr(SQLERRM,1,2000) || ' -TransmissionID - '||NVL(v_TransmissionID, '') ||' -Customer- '||NVL(v_Customer, '');
        END; --END TRANSACTION

       l_xmltype := dbms_xmldom.getXmlType(l_domdoc);
       dbms_xmldom.freeDocument(l_domdoc);

       OUT_CLOBData := l_xmltype.getClobVal;

       OUT_RetMsg :=  Temp_RetMsg;
  END;

 PROCEDURE USP_AMS_WO_SELECT(SGAN8_IN VARCHAR2 := NULL, SGDOLLARSRCDEST_IN VARCHAR2 := NULL,OUT_CLOBData OUT NOCOPY CLOB, OUT_RetMsg OUT VARCHAR2 ) IS
          Temp_RetMsg VARCHAR2(4000):='';

          v_TransmissionID VARCHAR(150);
          v_Customer NUMBER;
          l_domdoc dbms_xmldom.DOMDocument;
          l_xmltype XMLTYPE;

          l_root_node dbms_xmldom.DOMNode;

          l_DOCUMENT_INFO_node dbms_xmldom.DOMNode;

          l_EXTENDED_DATA_node dbms_xmldom.DOMNode;

          l_COMPONENTS_node dbms_xmldom.DOMNode;

          l_RECIPIENT_INFO_element dbms_xmldom.DOMElement;
          l_RECIPIENT_INFO_node dbms_xmldom.DOMNode;

          l_WO_DETAILS_element dbms_xmldom.DOMElement;
          l_WO_DETAILS_node dbms_xmldom.DOMNode;

          l_SHIP_TO_INFO_element dbms_xmldom.DOMElement;
          l_SHIP_TO_INFO_node dbms_xmldom.DOMNode;

          l_SENDER_INFO_element dbms_xmldom.DOMElement;
          l_SENDER_INFO_node dbms_xmldom.DOMNode;

          l_UKID_node dbms_xmldom.DOMNode;
          l_UKID_textnode dbms_xmldom.DOMNode;

          l_AN8_node dbms_xmldom.DOMNode;
          l_AN8_textnode dbms_xmldom.DOMNode;

          l_DOCUMENT_TYPE_node dbms_xmldom.DOMNode;
          l_DOCUMENT_TYPE_textnode dbms_xmldom.DOMNode;

          l_MODULE_node dbms_xmldom.DOMNode;
          l_MODULE_textnode dbms_xmldom.DOMNode;

          l_VERSION_node dbms_xmldom.DOMNode;
          l_VERSION_textnode dbms_xmldom.DOMNode;

          l_TEST_FLAG_node dbms_xmldom.DOMNode;
          l_TEST_FLAG_textnode dbms_xmldom.DOMNode;

          l_TRANSMISSION_DATE_node dbms_xmldom.DOMNode;
          l_TRANSMISSION_DATE_textnode dbms_xmldom.DOMNode;

          l_TRANSMISSION_ID_node dbms_xmldom.DOMNode;
          l_TRANSMISSION_ID_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_node dbms_xmldom.DOMNode;
          l_CUSTOMER_textnode dbms_xmldom.DOMNode;

          l_MPF_node dbms_xmldom.DOMNode;
          l_MPF_textnode dbms_xmldom.DOMNode;

          l_DESTINATION_ERP_node dbms_xmldom.DOMNode;
          l_DESTINATION_ERP_textnode dbms_xmldom.DOMNode;

          l_COMPANY_node dbms_xmldom.DOMNode;
          l_COMPANY_textnode dbms_xmldom.DOMNode;

          l_BRANCH_PLANT_node dbms_xmldom.DOMNode;
          l_BRANCH_PLANT_textnode dbms_xmldom.DOMNode;

          l_PLXS_CASE_NUMBER_node dbms_xmldom.DOMNode;
          l_PLXS_CASE_NUMBER_textnode dbms_xmldom.DOMNode;

          l_TRX_TYPE_node dbms_xmldom.DOMNode;
          l_TRX_TYPE_textnode dbms_xmldom.DOMNode;

          l_WORK_ORDER_NUMBER_node dbms_xmldom.DOMNode;
          l_WORK_ORDER_NUMBER_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_REFERENCE1_node dbms_xmldom.DOMNode;
          l_CUSTOMER_REFERENCE1_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_REFERENCE2_node dbms_xmldom.DOMNode;
          l_CUSTOMER_REFERENCE2_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_REFERENCE3_node dbms_xmldom.DOMNode;
          l_CUSTOMER_REFERENCE3_textnode dbms_xmldom.DOMNode;

          l_PLXS_ITEM_NUMBER_node dbms_xmldom.DOMNode;
          l_PLXS_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;

          l_ITEM_DESC_node dbms_xmldom.DOMNode;
          l_ITEM_DESC_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_ITEM_NUMBER_node dbms_xmldom.DOMNode;
          l_CUSTOMER_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_REV_node dbms_xmldom.DOMNode;
          l_CUSTOMER_REV_textnode dbms_xmldom.DOMNode;

          l_SECONDARY_CUSTOMER_ITEM_NUMBER_node dbms_xmldom.DOMNode;
          l_SECONDARY_CUSTOMER_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;

          l_LOT_SERIAL_NUMBER_node dbms_xmldom.DOMNode;
          l_LOT_SERIAL_NUMBER_textnode dbms_xmldom.DOMNode;

          l_QTY_node dbms_xmldom.DOMNode;
          l_QTY_textnode dbms_xmldom.DOMNode;

          l_TRX_DATE_node dbms_xmldom.DOMNode;
          l_TRX_DATE_textnode dbms_xmldom.DOMNode;

          l_NAME_node dbms_xmldom.DOMNode;
          l_NAME_textnode dbms_xmldom.DOMNode;

          l_ADDRESS1_node dbms_xmldom.DOMNode;
          l_ADDRESS1_textnode dbms_xmldom.DOMNode;

          l_ADDRESS2_node dbms_xmldom.DOMNode;
          l_ADDRESS2_textnode dbms_xmldom.DOMNode;

          l_ADDRESS3_node dbms_xmldom.DOMNode;
          l_ADDRESS3_textnode dbms_xmldom.DOMNode;

          l_ADDRESS4_node dbms_xmldom.DOMNode;
          l_ADDRESS4_textnode dbms_xmldom.DOMNode;

          l_CITY_node dbms_xmldom.DOMNode;
          l_CITY_textnode dbms_xmldom.DOMNode;

          l_ZIP_CODE_node dbms_xmldom.DOMNode;
          l_ZIP_CODE_textnode dbms_xmldom.DOMNode;

          l_STATE_node dbms_xmldom.DOMNode;
          l_STATE_textnode dbms_xmldom.DOMNode;

          l_COUNTRY_node dbms_xmldom.DOMNode;
          l_COUNTRY_textnode dbms_xmldom.DOMNode;

          l_AREACODE_node dbms_xmldom.DOMNode;
          l_AREACODE_textnode dbms_xmldom.DOMNode;

          l_PHONE_node dbms_xmldom.DOMNode;
          l_PHONE_textnode dbms_xmldom.DOMNode;

          l_CONTACT_FN_node dbms_xmldom.DOMNode;
          l_CONTACT_FN_textnode dbms_xmldom.DOMNode;

          l_CONTACT_LN_node dbms_xmldom.DOMNode;
          l_CONTACT_LN_textnode dbms_xmldom.DOMNode;

          l_AREA_TYPE_node dbms_xmldom.DOMNode;
          l_AREA_TYPE_textnode dbms_xmldom.DOMNode;

          l_AREA_DESC_node dbms_xmldom.DOMNode;
          l_AREA_DESC_textnode dbms_xmldom.DOMNode;

          l_LOT_SERIAL_NUMBER13_node dbms_xmldom.DOMNode;
          l_LOT_SERIAL_NUMBER13_textnode dbms_xmldom.DOMNode;

          l_PART_NUMBER_node dbms_xmldom.DOMNode;
          l_PART_NUMBER_textnode dbms_xmldom.DOMNode;

          l_REQUESTED_QUANTITY_node dbms_xmldom.DOMNode;
          l_REQUESTED_QUANTITY_textnode dbms_xmldom.DOMNode;

          l_ISSUED_QUANTITY_node dbms_xmldom.DOMNode;
          l_ISSUED_QUANTITY_textnode dbms_xmldom.DOMNode;

          TEMP_UKID NUMBER;
          TEMP_AN8 NUMBER;
          TEMP_C75DCT VARCHAR(60);
          TEMP_LRSSM VARCHAR(5);
          TEMP_B76VER NUMBER;
          TEMP_$TSTFLAG VARCHAR(1);
          TEMP_UPMJ VARCHAR(20);
          TEMP_UPMT VARCHAR(20);
          TEMP_ALPH VARCHAR(40);
          TEMP_$MPFNUM VARCHAR(25);
          TEMP_$transid VARCHAR(150);
          TEMP_$SRCDEST VARCHAR(100);
          TEMP_$SERMCU VARCHAR(15);
          TEMP_DOCO VARCHAR(8);
          TEMP_WOD NUMBER;
          TEMP_RF1 VARCHAR(30);
          TEMP_RF2 VARCHAR(30);
          TEMP_RF3 VARCHAR(30);
          TEMP_LITM VARCHAR(25);
          TEMP_DSC1 VARCHAR(30);

          TEMP_$CUSPRTN VARCHAR(30);
          TEMP_DL03 VARCHAR(30);
          TEMP_$CUSTLITM VARCHAR(50);
          TEMP_LOTN VARCHAR(30);
          TEMP_TRQT NUMBER;
          TEMP_SHANAPLH VARCHAR(40);
          TEMP_SHL1 VARCHAR(40);
          TEMP_SHL2 VARCHAR(40);
          TEMP_SHL3 VARCHAR(40);
          TEMP_SHL4 VARCHAR(40);
          TEMP_VSTCT VARCHAR(25);
          TEMP_ZIPCD VARCHAR(12);
          TEMP_STPROV VARCHAR(5);
          TEMP_CNTRYDES VARCHAR(5);
          TEMP_AR1 VARCHAR(6);
          TEMP_TELNUMB VARCHAR(20);
          TEMP_GNNM VARCHAR(25);
          TEMP_SRNM VARCHAR(25);
          TEMP_TRXDATE varchar(25);
          TEMP_$NOTETYP VARCHAR(100);
          TEMP_GPTX VARCHAR(1500);
          TEMP_LOTN13 varchar(30);
          TEMP_CPIL varchar(25);
          TEMP_UORG number;
          TEMP_Trqt13 number;
		  TEMP_TRNDES varchar(30);

    BEGIN
         --Creates an exmpty XML Document
         l_domdoc := dbms_xmldom.newDOMDocument;

         --Creates a root node
         l_root_node := dbms_xmldom.makeNode(l_domdoc);

        BEGIN

          SELECT sg$transid
                ,sgan8
          INTO v_TransmissionID
          ,v_Customer
          FROM proddta.F58INT11
          WHERE ROWNUM = 1
          AND  SG$RSP = 'D'
          AND (SGC75DCT = 'WO In Process'
               OR SGC75DCT = 'WO Completion')
          AND SGAN8 IN (
                with rws as (
                  select SGAN8_IN as str from dual
                )
                  select regexp_substr (
                           str,
                           '[^|]+',
                           1,
                           level
                         ) value
                  from   rws
                  connect by level <=
                    length ( str ) - length ( replace ( str, '|' ) ) + 1
            )
          AND (SGDOLLARSRCDEST_IN IS NULL OR SG$SRCDEST = RPAD(SGDOLLARSRCDEST_IN, 50))
          ORDER BY sg$transid;

           --Update record that is being processed
            UPDATE proddta.F58INT11
            SET sg$rsp = 'B'
                ,sguser = 'BIZTALK'
                ,sgupmt = to_char(cast(SYSDATE as date),'hh24miss')
                ,sgupmj = To_Number(To_Char(To_Number(To_Char(sysdate, 'yyyy')) - 1900) || To_Char(sysdate, 'ddd'))
            WHERE sg$transid = v_TransmissionID
            AND sgan8 = v_Customer;
            COMMIT;


            FOR AMS_HEAD_OUT_REC in
                (SELECT TRIM(sgan8) sgan8
                    ,TRIM(sgc75dct) sgc75dct
                   ,TRIM(sglrssm) sglrssm
                   ,TRIM(sgb76ver) sgb76ver
                   ,TRIM(sg$tstflag)sg$tstflag
                   ,TRIM(sgupmj) sgupmj
                   ,TRIM(sgupmt) sgupmt
                   ,TRIM(sgalph) sgalph
                   ,TRIM(sg$mpfnum) sg$mpfnum
                   ,TRIM(sg$srcdest) sg$srcdest
                   ,TRIM(sg$transid) sg$transid
                 FROM proddta.F58INT11
                 WHERE sg$transid = v_TransmissionID
                  AND sgan8 = v_Customer
                  AND rownum = 1
                 )

                 LOOP


                TEMP_AN8 := AMS_HEAD_OUT_REC.sgan8;
                TEMP_C75DCT := AMS_HEAD_OUT_REC.SGC75DCT ;
                TEMP_LRSSM:= AMS_HEAD_OUT_REC.SGLRSSM ;
                TEMP_B76VER := AMS_HEAD_OUT_REC.SGB76VER;
                TEMP_$TSTFLAG := AMS_HEAD_OUT_REC.SG$TSTFLAG;
                TEMP_UPMJ:= AMS_HEAD_OUT_REC.SGUPMJ;
                TEMP_UPMT := AMS_HEAD_OUT_REC.SGUPMT;
                TEMP_ALPH:= AMS_HEAD_OUT_REC.SGALPH;
                TEMP_$MPFNUM:= AMS_HEAD_OUT_REC.SG$MPFNUM;
                TEMP_$SRCDEST:= AMS_HEAD_OUT_REC.SG$SRCDEST;
                TEMP_$transid := AMS_HEAD_OUT_REC.SG$TRANSID;


                 l_DOCUMENT_INFO_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'DOCUMENT_INFO')));

                 l_an8_node := dbms_xmldom.appendChild(l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AN8' )));
                 l_an8_textnode := dbms_xmldom.appendChild( l_an8_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_an8 )));


                 l_DOCUMENT_TYPE_node := dbms_xmldom.appendChild(l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DOCUMENT_TYPE' )));
                 l_DOCUMENT_TYPE_textnode := dbms_xmldom.appendChild( l_DOCUMENT_TYPE_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_C75DCT )));

                 l_MODULE_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'MODULE' )));
                 l_MODULE_textnode := dbms_xmldom.appendChild( l_MODULE_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_LRSSM )));

                 l_VERSION_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'VERSION' )));
                 l_VERSION_textnode := dbms_xmldom.appendChild( l_VERSION_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_B76VER )));

                 l_TEST_FLAG_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TEST_FLAG' )));
                 l_TEST_FLAG_textnode := dbms_xmldom.appendChild( l_TEST_FLAG_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$TSTFLAG)));

                 l_TRANSMISSION_DATE_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRANSMISSION_DATE' )));
                 l_TRANSMISSION_DATE_textnode := dbms_xmldom.appendChild( l_TRANSMISSION_DATE_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP),'YYYY-MM-DD"T"HH24:MI:SS"Z"') )));

                 l_TRANSMISSION_ID_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRANSMISSION_ID' )));
                 l_TRANSMISSION_ID_textnode := dbms_xmldom.appendChild( l_TRANSMISSION_ID_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,TEMP_$transid )));


                 l_RECIPIENT_INFO_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'RECIPIENT_INFO')));

                 l_CUSTOMER_node := dbms_xmldom.appendChild(l_RECIPIENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER' )));
                 l_CUSTOMER_textnode := dbms_xmldom.appendChild( l_CUSTOMER_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_ALPH )));

                 l_MPF_node := dbms_xmldom.appendChild(l_RECIPIENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'MPF' )));
                 l_MPF_textnode := dbms_xmldom.appendChild( l_MPF_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$MPFNUM)));
                 l_DESTINATION_ERP_node := dbms_xmldom.appendChild(l_RECIPIENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DESTINATION_ERP' )));
                 l_DESTINATION_ERP_textnode := dbms_xmldom.appendChild( l_DESTINATION_ERP_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$SRCDEST )));

                 l_SENDER_INFO_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'SENDER_INFO')));

                 l_COMPANY_node := dbms_xmldom.appendChild(l_SENDER_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'COMPANY' )));
                 l_COMPANY_textnode := dbms_xmldom.appendChild( l_COMPANY_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, 'Plexus Corp.' )));




       END LOOP;

           FOR AMS_OUT_REC in
                (SELECT
                   TRIM(sgukid) sgukid
                   ,TRIM(sg$sermcu) sg$sermcu
                   ,TRIM(sgdoco) sgdoco
                   ,TRIM(sgrf1) sgrf1
                   ,TRIM(sgrf2) sgrf2
                   ,TRIM(sgrf3) sgrf3
                   ,TRIM(sglitm) sglitm
                   ,TRIM(sgdsc1) sgdsc1
                   ,TRIM(sg$cusprtn) sg$cusprtn
                   ,TRIM(sgdl03) sgdl03
                   ,TRIM(sg$cuslitm) sg$cuslitm
                   ,TRIM(sglotn) sglotn
                   ,TRIM(sgtrqt) sgtrqt
                   ,sgwod sgwod
                   ,DECODE(sg$GS04,0,'0',TO_CHAR(TO_DATE(TO_CHAR(sg$GS04 + 1900000),'YYYYDDD'),'yyyy-mm-dd'))||'T'|| decode(sg54RCTT,0,'00:00:00',to_char(to_date(LPAD(TO_CHAR(sg54RCTT),6,'0') , 'hh24miss'),'hh24:mi:ss')) ||'Z' TRXDATE
                   ,TRIM(sgshanalph) sgshanalph
                   ,TRIM(sgshl1) sgshl1
                   ,TRIM(sgshl2) sgshl2
                   ,TRIM(sgshl3) sgshl3
                   ,TRIM(sgshl4) sgshl4
                   ,TRIM(sgvstct) sgvstct
                   ,TRIM(sgzipcd) sgzipcd
                   ,TRIM(sgstprov) sgstprov
                   ,TRIM(sgcntrydes) sgcntrydes
                   ,TRIM(sgar1) sgar1
                   ,TRIM(sgtelnumb) sgtelnumb
                   ,TRIM(sggnnm) sggnnm
                   ,TRIM(sgsrnm) sgsrnm
                    ,TRIM(SGTRNDES) SGTRNDES
                 FROM proddta.F58INT11
                 WHERE sg$transid = v_TransmissionID
                 AND sgan8 = v_Customer
                 )

                 LOOP
                TEMP_UKID := AMS_OUT_REC.SGUKID;
                TEMP_$SERMCU:= AMS_OUT_REC.SG$SERMCU;
                TEMP_DOCO:= AMS_OUT_REC.SGDOCO;
                TEMP_RF1:= AMS_OUT_REC.SGRF1;
                TEMP_RF2:= AMS_OUT_REC.SGRF2;
                TEMP_RF3:= AMS_OUT_REC.SGRF3;
                TEMP_LITM:= AMS_OUT_REC.SGLITM;
                TEMP_DSC1:= AMS_OUT_REC.SGDSC1;

                TEMP_$CUSPRTN:= AMS_OUT_REC.SG$CUSPRTN;
                TEMP_DL03:= AMS_OUT_REC.SGDL03;
                TEMP_$CUSTLITM := AMS_OUT_REC.SG$CUSLITM;
                TEMP_LOTN:= AMS_OUT_REC.SGLOTN;
                TEMP_TRQT := AMS_OUT_REC.SGTRQT;
                TEMP_WOD := ams_out_rec.sgwod;
                TEMP_TRXDATE := AMS_OUT_REC.TRXDATE;
                TEMP_SHANAPLH:= AMS_OUT_REC.SGSHANALPH;
                TEMP_SHL1:= AMS_OUT_REC.SGSHL1;
                TEMP_SHL2 :=AMS_OUT_REC.SGSHL2;
                TEMP_SHL3 :=AMS_OUT_REC.SGSHL3;
                TEMP_SHL4 :=AMS_OUT_REC.SGSHL4;
                TEMP_VSTCT := AMS_OUT_REC.SGVSTCT;
                TEMP_ZIPCD := AMS_OUT_REC.SGZIPCD;
                TEMP_STPROV:= AMS_OUT_REC.SGSTPROV;
                TEMP_CNTRYDES:= AMS_OUT_REC.SGCNTRYDES;
                TEMP_AR1 := AMS_OUT_REC.SGAR1;
                TEMP_TELNUMB:= AMS_OUT_REC.SGTELNUMB;
                TEMP_GNNM:= AMS_OUT_REC.SGGNNM;
                TEMP_SRNM := AMS_OUT_REC.SGSRNM;
			        	TEMP_TRNDES := AMS_OUT_REC.SGTRNDES;

         l_WO_DETAILS_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'WO_DETAILS')));

         l_ukid_node := dbms_xmldom.appendChild(l_WO_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'UNIQUE_ID' )));
         l_ukid_textnode := dbms_xmldom.appendChild( l_ukid_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_ukid )));

         l_BRANCH_PLANT_node := dbms_xmldom.appendChild(l_WO_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'WO_BRANCH_PLANT' )));
         l_BRANCH_PLANT_textnode := dbms_xmldom.appendChild( l_BRANCH_PLANT_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$SERMCU )));

         l_PLXS_CASE_NUMBER_node := dbms_xmldom.appendChild(l_WO_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_CASE_NUMBER' )));
         l_PLXS_CASE_NUMBER_textnode := dbms_xmldom.appendChild( l_PLXS_CASE_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_DOCO )));

         l_WORK_ORDER_NUMBER_node := dbms_xmldom.appendChild(l_WO_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'WORK_ORDER_NUMBER' )));
         l_WORK_ORDER_NUMBER_textnode := dbms_xmldom.appendChild( l_WORK_ORDER_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_WOD )));

													 l_TRX_TYPE_node := dbms_xmldom.appendChild(l_WO_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRX_TYPE' )));
         l_TRX_TYPE_textnode := dbms_xmldom.appendChild( l_TRX_TYPE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_TRNDES )));

         l_CUSTOMER_REFERENCE1_node := dbms_xmldom.appendChild(l_WO_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE1' )));
         l_CUSTOMER_REFERENCE1_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REFERENCE1_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_RF1 )));

         l_CUSTOMER_REFERENCE2_node := dbms_xmldom.appendChild(l_WO_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE2' )));
         l_CUSTOMER_REFERENCE2_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REFERENCE2_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_RF2 )));

         l_CUSTOMER_REFERENCE3_node := dbms_xmldom.appendChild(l_WO_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE3' )));
         l_CUSTOMER_REFERENCE3_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REFERENCE3_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_RF3 )));

         l_PLXS_ITEM_NUMBER_node := dbms_xmldom.appendChild(l_WO_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_ITEM_NUMBER' )));
         l_PLXS_ITEM_NUMBER_textnode := dbms_xmldom.appendChild( l_PLXS_ITEM_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_LITM )));

         l_ITEM_DESC_node := dbms_xmldom.appendChild(l_WO_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ITEM_DESC' )));
         l_ITEM_DESC_textnode := dbms_xmldom.appendChild( l_ITEM_DESC_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_DSC1 )));

         l_CUSTOMER_ITEM_NUMBER_node := dbms_xmldom.appendChild(l_WO_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_ITEM_NUMBER' )));
         l_CUSTOMER_ITEM_NUMBER_textnode := dbms_xmldom.appendChild( l_CUSTOMER_ITEM_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$CUSPRTN )));

         l_CUSTOMER_REV_node := dbms_xmldom.appendChild(l_WO_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REV' )));
         l_CUSTOMER_REV_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REV_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_DL03 )));

         l_SECONDARY_CUSTOMER_ITEM_NUMBER_node := dbms_xmldom.appendChild(l_WO_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'SECONDARY_CUSTOMER_ITEM_NUMBER' )));
         l_SECONDARY_CUSTOMER_ITEM_NUMBER_textnode := dbms_xmldom.appendChild( l_SECONDARY_CUSTOMER_ITEM_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$CUSTLITM )));

         l_LOT_SERIAL_NUMBER_node := dbms_xmldom.appendChild(l_WO_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'LOT_SERIAL_NUMBER' )));
         l_LOT_SERIAL_NUMBER_textnode := dbms_xmldom.appendChild( l_LOT_SERIAL_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_LOTN )));

         l_QTY_node := dbms_xmldom.appendChild(l_WO_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'QTY' )));
         l_QTY_textnode := dbms_xmldom.appendChild( l_QTY_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_TRQT )));


         l_TRX_DATE_node := dbms_xmldom.appendChild(l_WO_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRX_DATE' )));
         l_TRX_DATE_textnode := dbms_xmldom.appendChild( l_TRX_DATE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_TRXDATE )));


         l_SHIP_TO_INFO_node := dbms_xmldom.appendChild(l_WO_DETAILS_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'SHIP_TO_INFO')));


         l_NAME_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'NAME' )));
         l_NAME_textnode := dbms_xmldom.appendChild( l_NAME_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_SHANAPLH )));

         l_ADDRESS1_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ADDRESS1' )));
         l_ADDRESS1_textnode := dbms_xmldom.appendChild( l_ADDRESS1_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_SHL1 )));

         l_ADDRESS2_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ADDRESS2' )));
         l_ADDRESS2_textnode := dbms_xmldom.appendChild( l_ADDRESS2_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_SHL2 )));

         l_ADDRESS3_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ADDRESS3' )));
         l_ADDRESS3_textnode := dbms_xmldom.appendChild( l_ADDRESS3_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_SHL3 )));

         l_ADDRESS4_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ADDRESS4' )));
         l_ADDRESS4_textnode := dbms_xmldom.appendChild( l_ADDRESS4_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_SHL4 )));

         l_CITY_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CITY' )));
         l_CITY_textnode := dbms_xmldom.appendChild( l_CITY_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_VSTCT )));

         l_ZIP_CODE_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ZIP_CODE' )));
         l_ZIP_CODE_textnode := dbms_xmldom.appendChild( l_ZIP_CODE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_ZIPCD )));

         l_STATE_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'STATE' )));
         l_STATE_textnode := dbms_xmldom.appendChild( l_STATE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_STPROV )));

         l_COUNTRY_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'COUNTRY' )));
         l_COUNTRY_textnode := dbms_xmldom.appendChild( l_COUNTRY_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_CNTRYDES )));

         l_AREACODE_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AREACODE' )));
         l_AREACODE_textnode := dbms_xmldom.appendChild( l_AREACODE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_AR1 )));

         l_PHONE_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PHONE' )));
         l_PHONE_textnode := dbms_xmldom.appendChild( l_PHONE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_TELNUMB )));

         l_CONTACT_FN_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CONTACT_FN' )));
         l_CONTACT_FN_textnode := dbms_xmldom.appendChild( l_CONTACT_FN_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_GNNM )));

         l_CONTACT_LN_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CONTACT_LN' )));
         l_CONTACT_LN_textnode := dbms_xmldom.appendChild( l_CONTACT_LN_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_SRNM )));



            FOR AMS_OUT_EXT_REC in
             (SELECT TRIM(nt$notetyp ) nt$notetyp
                    ,TRIM(ntgptx) ntgptx
              FROM proddta.f58INT12
              WHERE ntukid =  TEMP_UKID
              AND   ntc75dct =  RPAD(TRIM(TEMP_C75DCT),60)
               )
           LOOP
              TEMP_$notetyp := ams_out_ext_rec.nt$notetyp;
              TEMP_GPTX := ams_out_ext_rec.ntgptx;
           l_EXTENDED_DATA_node := dbms_xmldom.appendChild(l_WO_DETAILS_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'EXTENDED_DATA')));
              l_AREA_TYPE_node := dbms_xmldom.appendChild(l_EXTENDED_DATA_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AREA_TYPE' )));
              l_AREA_TYPE_textnode := dbms_xmldom.appendChild( l_AREA_TYPE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$notetyp )));

              l_AREA_DESC_node := dbms_xmldom.appendChild(l_EXTENDED_DATA_node
                                                 , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AREA_DESC' )));
               l_AREA_DESC_textnode := dbms_xmldom.appendChild( l_AREA_DESC_node
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_GPTX)));
           END LOOP;

            FOR AMS_OUT_COMP_REC in
               (SELECT TRIM(pilotn) pilotn
                       ,TRIM(picpil) picpil
                       ,TRIM(piuorg) piuorg
                       ,TRIM(pitrqt) pitrqt
                FROM proddta.f58INT13
                WHERE piukid = TEMP_UKID
                AND   pic75dct =  RPAD(TRIM(TEMP_C75DCT),60))

                LOOP
                 l_COMPONENTS_node := dbms_xmldom.appendChild(l_WO_DETAILS_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'COMPONENTS')));
                TEMP_LOTN13 := ams_out_comp_rec.pilotn;
                TEMP_CPIL := ams_out_comp_rec.picpil;
                TEMP_UORG := ams_out_comp_rec.piuorg;
                TEMP_Trqt13 := ams_out_comp_rec.pitrqt;

                  l_LOT_SERIAL_NUMBER13_node := dbms_xmldom.appendChild(l_COMPONENTS_node
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'LOT_SERIAL_NUMBER' )));
                  l_LOT_SERIAL_NUMBER13_textnode := dbms_xmldom.appendChild( l_LOT_SERIAL_NUMBER13_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_LOTN13 )));

                  l_PART_NUMBER_node := dbms_xmldom.appendChild(l_COMPONENTS_node
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PART_NUMBER' )));
                  l_PART_NUMBER_textnode := dbms_xmldom.appendChild( l_PART_NUMBER_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_CPIL)));

                  l_REQUESTED_QUANTITY_node := dbms_xmldom.appendChild(l_COMPONENTS_node
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'REQUESTED_QUANTITY' )));
                  l_REQUESTED_QUANTITY_textnode := dbms_xmldom.appendChild( l_REQUESTED_QUANTITY_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_UORG )));

                  l_ISSUED_QUANTITY_node := dbms_xmldom.appendChild(l_COMPONENTS_node
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ISSUED_QUANTITY' )));
                  l_ISSUED_QUANTITY_textnode := dbms_xmldom.appendChild( l_ISSUED_QUANTITY_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_TRQT13)));

                END LOOP;


        END LOOP;

        EXCEPTION
             WHEN OTHERS THEN

             --UPDATE PRODDTA.F58INT11 SET SG$RSP='E' WHERE sg$transid = v_TransmissionID AND sgan8 = v_Customer;
             --COMMIT;

             Temp_RetMsg :='Error: - '||SQLCODE||' -ERROR- '||substr(SQLERRM,1,2000) || ' -TransmissionID - '||NVL(v_TransmissionID, '') ||' -Customer- '||NVL(v_Customer, '');
        END; --END TRANSACTION

           l_xmltype := dbms_xmldom.getXmlType(l_domdoc);
           dbms_xmldom.freeDocument(l_domdoc);

           OUT_CLOBData := l_xmltype.getClobVal;

           OUT_RetMsg :=  Temp_RetMsg;
        END;

 PROCEDURE USP_AMS_SHIPPING_SELECT(SGAN8_IN VARCHAR2 := NULL, SGDOLLARSRCDEST_IN VARCHAR2 := NULL,OUT_CLOBData OUT NOCOPY CLOB, OUT_RetMsg OUT VARCHAR2 ) IS
          Temp_RetMsg VARCHAR2(4000):='';

          v_TransmissionID VARCHAR(150);
          v_Customer NUMBER;
          l_domdoc dbms_xmldom.DOMDocument;
          l_xmltype XMLTYPE;

          l_root_node dbms_xmldom.DOMNode;

          l_DOCUMENT_INFO_node dbms_xmldom.DOMNode;

          l_RECIPIENT_INFO_element dbms_xmldom.DOMElement;
          l_RECIPIENT_INFO_node dbms_xmldom.DOMNode;

          l_SHIPPING_DETAILS_element dbms_xmldom.DOMElement;
          l_SHIPPING_DETAILS_node dbms_xmldom.DOMNode;

          l_EXTENDED_DATA_element dbms_xmldom.DOMElement;
          l_EXTENDED_DATA_node dbms_xmldom.DOMNode;

          l_SENDER_INFO_element dbms_xmldom.DOMElement;
          l_SENDER_INFO_node dbms_xmldom.DOMNode;

          l_SHIP_TO_INFO_element dbms_xmldom.DOMElement;
          l_SHIP_TO_INFO_node dbms_xmldom.DOMNode;

          l_UKID_node dbms_xmldom.DOMNode;
          l_UKID_textnode dbms_xmldom.DOMNode;

          l_AN8_node dbms_xmldom.DOMNode;
          l_AN8_textnode dbms_xmldom.DOMNode;

          l_DOCUMENT_TYPE_node dbms_xmldom.DOMNode;
          l_DOCUMENT_TYPE_textnode dbms_xmldom.DOMNode;

          l_MODULE_node dbms_xmldom.DOMNode;
          l_MODULE_textnode dbms_xmldom.DOMNode;

          l_VERSION_node dbms_xmldom.DOMNode;
          l_VERSION_textnode dbms_xmldom.DOMNode;

          l_TEST_FLAG_node dbms_xmldom.DOMNode;
          l_TEST_FLAG_textnode dbms_xmldom.DOMNode;

          l_TRANSMISSION_DATE_node dbms_xmldom.DOMNode;
          l_TRANSMISSION_DATE_textnode dbms_xmldom.DOMNode;

          l_TRANSMISSION_ID_node dbms_xmldom.DOMNode;
          l_TRANSMISSION_ID_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_node dbms_xmldom.DOMNode;
          l_CUSTOMER_textnode dbms_xmldom.DOMNode;

          l_MPF_node dbms_xmldom.DOMNode;
          l_MPF_textnode dbms_xmldom.DOMNode;

          l_DESTINATION_ERP_node dbms_xmldom.DOMNode;
          l_DESTINATION_ERP_textnode dbms_xmldom.DOMNode;

          l_COMPANY_node dbms_xmldom.DOMNode;
          l_COMPANY_textnode dbms_xmldom.DOMNode;

          l_BRANCH_PLANT_node dbms_xmldom.DOMNode;
          l_BRANCH_PLANT_textnode dbms_xmldom.DOMNode;

          l_PLXS_CASE_NUMBER_node dbms_xmldom.DOMNode;
          l_PLXS_CASE_NUMBER_textnode dbms_xmldom.DOMNode;

          l_SHIPMENT_NUMBER_node dbms_xmldom.DOMNode;
          l_SHIPMENT_NUMBER_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_REFERENCE1_node dbms_xmldom.DOMNode;
          l_CUSTOMER_REFERENCE1_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_REFERENCE2_node dbms_xmldom.DOMNode;
          l_CUSTOMER_REFERENCE2_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_REFERENCE3_node dbms_xmldom.DOMNode;
          l_CUSTOMER_REFERENCE3_textnode dbms_xmldom.DOMNode;

          l_PLXS_ITEM_NUMBER_node dbms_xmldom.DOMNode;
          l_PLXS_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;

          l_ITEM_DESC_node dbms_xmldom.DOMNode;
          l_ITEM_DESC_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_ITEM_NUMBER_node dbms_xmldom.DOMNode;
          l_CUSTOMER_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;

          l_CUSTOMER_REV_node dbms_xmldom.DOMNode;
          l_CUSTOMER_REV_textnode dbms_xmldom.DOMNode;

          l_SECONDARY_CUSTOMER_ITEM_NUMBER_node dbms_xmldom.DOMNode;
          l_SECONDARY_CUSTOMER_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;

          l_LOT_SERIAL_NUMBER_node dbms_xmldom.DOMNode;
          l_LOT_SERIAL_NUMBER_textnode dbms_xmldom.DOMNode;

          l_QTY_node dbms_xmldom.DOMNode;
          l_QTY_textnode dbms_xmldom.DOMNode;

          l_CARRIER_node dbms_xmldom.DOMNode;
          l_CARRIER_textnode dbms_xmldom.DOMNode;

          l_CARRIER_CODE_node dbms_xmldom.DOMNode;
          l_CARRIER_CODE_textnode dbms_xmldom.DOMNode;

          l_SHIP_METHOD_node dbms_xmldom.DOMNode;
          l_SHIP_METHOD_textnode dbms_xmldom.DOMNode;

          l_SHIP_TRACKING_NUMBER_node dbms_xmldom.DOMNode;
          l_SHIP_TRACKING_NUMBER_textnode dbms_xmldom.DOMNode;

          l_SHIP_DATE_node dbms_xmldom.DOMNode;
          l_SHIP_DATE_textnode dbms_xmldom.DOMNode;

          l_RETURN_REASON_node dbms_xmldom.DOMNode;
          l_RETURN_REASON_textnode dbms_xmldom.DOMNode;

          l_RCVR_NOTE_node dbms_xmldom.DOMNode;
          l_RCVR_NOTE_textnode dbms_xmldom.DOMNode;

          l_NAME_node dbms_xmldom.DOMNode;
          l_NAME_textnode dbms_xmldom.DOMNode;

          l_ADDRESS1_node dbms_xmldom.DOMNode;
          l_ADDRESS1_textnode dbms_xmldom.DOMNode;

          l_ADDRESS2_node dbms_xmldom.DOMNode;
          l_ADDRESS2_textnode dbms_xmldom.DOMNode;

          l_ADDRESS3_node dbms_xmldom.DOMNode;
          l_ADDRESS3_textnode dbms_xmldom.DOMNode;

          l_ADDRESS4_node dbms_xmldom.DOMNode;
          l_ADDRESS4_textnode dbms_xmldom.DOMNode;

          l_CITY_node dbms_xmldom.DOMNode;
          l_CITY_textnode dbms_xmldom.DOMNode;

          l_ZIP_CODE_node dbms_xmldom.DOMNode;
          l_ZIP_CODE_textnode dbms_xmldom.DOMNode;

          l_STATE_node dbms_xmldom.DOMNode;
          l_STATE_textnode dbms_xmldom.DOMNode;

          l_COUNTRY_node dbms_xmldom.DOMNode;
          l_COUNTRY_textnode dbms_xmldom.DOMNode;

          l_AREACODE_node dbms_xmldom.DOMNode;
          l_AREACODE_textnode dbms_xmldom.DOMNode;

          l_PHONE_node dbms_xmldom.DOMNode;
          l_PHONE_textnode dbms_xmldom.DOMNode;

          l_CONTACT_FN_node dbms_xmldom.DOMNode;
          l_CONTACT_FN_textnode dbms_xmldom.DOMNode;

          l_CONTACT_LN_node dbms_xmldom.DOMNode;
          l_CONTACT_LN_textnode dbms_xmldom.DOMNode;

          l_AREA_TYPE_node dbms_xmldom.DOMNode;
          l_AREA_TYPE_textnode dbms_xmldom.DOMNode;

          l_AREA_DESC_node dbms_xmldom.DOMNode;
          l_AREA_DESC_textnode dbms_xmldom.DOMNode;

          TEMP_UKID NUMBER;
          TEMP_AN8 NUMBER;
          TEMP_C75DCT VARCHAR(60);
          TEMP_LRSSM VARCHAR(5);
          TEMP_B76VER NUMBER;
          TEMP_$TSTFLAG VARCHAR(1);
          TEMP_UPMJ VARCHAR(20);
          TEMP_UPMT VARCHAR(20);
          TEMP_ALPH VARCHAR(40);
          TEMP_$MPFNUM VARCHAR(25);
          TEMP_$transid VARCHAR(150);
          TEMP_$SRCDEST VARCHAR(100);
          TEMP_$SERMCU VARCHAR(15);
          TEMP_DOCO VARCHAR(8);
          TEMP_ANUR VARCHAR(8);
          TEMP_RF1 VARCHAR(30);
          TEMP_RF2 VARCHAR(30);
          TEMP_RF3 VARCHAR(30);
          TEMP_LITM VARCHAR(25);
          TEMP_DSC1 VARCHAR(30);
          TEMP_$CUSPRTN VARCHAR(30);
          TEMP_DL03 VARCHAR(30);
          TEMP_$CUSTLITM VARCHAR(50);
          TEMP_LOTN VARCHAR(30);
          TEMP_TRQT NUMBER;
          TEMP_SHIPDATE VARCHAR(25);
          TEMP_$CARNAM VARCHAR(40);
          TEMP_$CARCODE VARCHAR(15);
          TEMP_OTMOT VARCHAR(50);
          TEMP_$TRK VARCHAR(64);
          TEMP_SHANAPLH VARCHAR(40);
          TEMP_SHL1 VARCHAR(40);
          TEMP_SHL2 VARCHAR(40);
          TEMP_SHL3 VARCHAR(40);
          TEMP_SHL4 VARCHAR(40);
          TEMP_VSTCT VARCHAR(25);
          TEMP_ZIPCD VARCHAR(12);
          TEMP_STPROV VARCHAR(5);
          TEMP_CNTRYDES VARCHAR(5);
          TEMP_AR1 VARCHAR(6);
          TEMP_TELNUMB VARCHAR(20);
          TEMP_GNNM VARCHAR(25);
          TEMP_SRNM VARCHAR(25);
          TEMP_$GS04 VARCHAR(20);
          TEMP_DOCKDATE varchar(25);
          TEMP_$NOTETYP varchar(100);
          TEMP_GPTX VARCHAR(1500);

   BEGIN
        --Creates an exmpty XML Document
         l_domdoc := dbms_xmldom.newDOMDocument;

         --Creates a root node
         l_root_node := dbms_xmldom.makeNode(l_domdoc);

        BEGIN

          SELECT sg$transid
                ,sgan8
          INTO v_TransmissionID
          ,v_Customer
          FROM proddta.F58INT11
          WHERE ROWNUM = 1
          AND SGC75DCT = 'Shipping Details'
          AND sg$rsp = 'D'
          --AND sgukid = 4913
          AND SGAN8 IN (
                with rws as (
                  select SGAN8_IN as str from dual
                )
                  select regexp_substr (
                           str,
                           '[^|]+',
                           1,
                           level
                         ) value
                  from   rws
                  connect by level <=
                    length ( str ) - length ( replace ( str, '|' ) ) + 1
            )
          AND (SGDOLLARSRCDEST_IN IS NULL OR SG$SRCDEST = RPAD(SGDOLLARSRCDEST_IN, 50))
          ORDER BY sg$transid;

           --Update record that is being processed
            UPDATE proddta.F58INT11
            SET sg$rsp = 'B'
                ,sguser = 'BIZTALK'
                ,sgupmt = to_char(cast(SYSDATE as date),'hh24miss')
                ,sgupmj = To_Number(To_Char(To_Number(To_Char(sysdate, 'yyyy')) - 1900) || To_Char(sysdate, 'ddd'))
            WHERE sg$transid = v_TransmissionID
            AND sgan8 = v_Customer;
            COMMIT;

             FOR AMS_HEAD_OUT_REC in
                (SELECT TRIM(sgan8) sgan8
                    ,TRIM(sgc75dct) sgc75dct
                   ,TRIM(sglrssm) sglrssm
                   ,TRIM(sgb76ver) sgb76ver
                   ,TRIM(sg$tstflag)sg$tstflag
                   ,TRIM(sgupmj) sgupmj
                   ,TRIM(sgupmt) sgupmt
                   ,TRIM(sgalph) sgalph
                   ,TRIM(sg$mpfnum) sg$mpfnum
                   ,TRIM(sg$srcdest) sg$srcdest
                   ,TRIM(sg$transid) sg$transid
                 FROM proddta.F58INT11
                 WHERE sg$transid = v_TransmissionID
                  AND sgan8 = v_Customer
                  AND rownum = 1
                 )

                 LOOP


                TEMP_AN8 := AMS_HEAD_OUT_REC.sgan8;
                TEMP_C75DCT := AMS_HEAD_OUT_REC.SGC75DCT ;
                TEMP_LRSSM:= AMS_HEAD_OUT_REC.SGLRSSM ;
                TEMP_B76VER := AMS_HEAD_OUT_REC.SGB76VER;
                TEMP_$TSTFLAG := AMS_HEAD_OUT_REC.SG$TSTFLAG;
                TEMP_UPMJ:= AMS_HEAD_OUT_REC.SGUPMJ;
                TEMP_UPMT := AMS_HEAD_OUT_REC.SGUPMT;
                TEMP_ALPH:= AMS_HEAD_OUT_REC.SGALPH;
                TEMP_$MPFNUM:= AMS_HEAD_OUT_REC.SG$MPFNUM;
                TEMP_$SRCDEST:= AMS_HEAD_OUT_REC.SG$SRCDEST;
                TEMP_$transid := AMS_HEAD_OUT_REC.SG$TRANSID;




                 l_DOCUMENT_INFO_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'DOCUMENT_INFO')));

                 l_an8_node := dbms_xmldom.appendChild(l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AN8' )));
                 l_an8_textnode := dbms_xmldom.appendChild( l_an8_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_an8 )));


                 l_DOCUMENT_TYPE_node := dbms_xmldom.appendChild(l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DOCUMENT_TYPE' )));
                 l_DOCUMENT_TYPE_textnode := dbms_xmldom.appendChild( l_DOCUMENT_TYPE_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_C75DCT )));

                 l_MODULE_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'MODULE' )));
                 l_MODULE_textnode := dbms_xmldom.appendChild( l_MODULE_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_LRSSM )));

                 l_VERSION_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'VERSION' )));
                 l_VERSION_textnode := dbms_xmldom.appendChild( l_VERSION_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_B76VER )));

                 l_TEST_FLAG_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TEST_FLAG' )));
                 l_TEST_FLAG_textnode := dbms_xmldom.appendChild( l_TEST_FLAG_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$TSTFLAG)));

                 l_TRANSMISSION_DATE_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRANSMISSION_DATE' )));
                 l_TRANSMISSION_DATE_textnode := dbms_xmldom.appendChild( l_TRANSMISSION_DATE_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP),'YYYY-MM-DD"T"HH24:MI:SS"Z"') )));

                 l_TRANSMISSION_ID_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRANSMISSION_ID' )));
                 l_TRANSMISSION_ID_textnode := dbms_xmldom.appendChild( l_TRANSMISSION_ID_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,TEMP_$transid )));


                 l_RECIPIENT_INFO_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'RECIPIENT_INFO')));

                 l_CUSTOMER_node := dbms_xmldom.appendChild(l_RECIPIENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER' )));
                 l_CUSTOMER_textnode := dbms_xmldom.appendChild( l_CUSTOMER_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_ALPH )));

                 l_MPF_node := dbms_xmldom.appendChild(l_RECIPIENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'MPF' )));
                 l_MPF_textnode := dbms_xmldom.appendChild( l_MPF_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$MPFNUM)));
                 l_DESTINATION_ERP_node := dbms_xmldom.appendChild(l_RECIPIENT_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DESTINATION_ERP' )));
                 l_DESTINATION_ERP_textnode := dbms_xmldom.appendChild( l_DESTINATION_ERP_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$SRCDEST )));

                 l_SENDER_INFO_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'SENDER_INFO')));

                 l_COMPANY_node := dbms_xmldom.appendChild(l_SENDER_INFO_node
                                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'COMPANY' )));
                 l_COMPANY_textnode := dbms_xmldom.appendChild( l_COMPANY_node
                                                            , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, 'Plexus Corp.' )));




       END LOOP;

           FOR AMS_OUT_REC in
                (SELECT
                   TRIM(sgukid) sgukid
                   ,TRIM(sg$sermcu) sg$sermcu
                   ,TRIM(sgdoco) sgdoco
                   ,TRIM(sganur) sganur
                   ,TRIM(sgrf1) sgrf1
                   ,TRIM(sgrf2) sgrf2
                   ,TRIM(sgrf3) sgrf3
                   ,TRIM(sglitm) sglitm
                   ,TRIM(sgdsc1) sgdsc1
                   ,TRIM(sg$cusprtn) sg$cusprtn
                   ,TRIM(sgdl03) sgdl03
                   ,TRIM(sg$cuslitm) sg$cuslitm
                   ,TRIM(sglotn) sglotn
                   ,TRIM(sgtrqt) sgtrqt
                   ,TRIM(sg$carnam) sg$carnam
                   ,TRIM(sg$carcode) sg$carcode
                   ,TRIM(sgotmot) sgotmot
                   ,DECODE(sg$GS04,0,'0',TO_CHAR(TO_DATE(TO_CHAR(sg$GS04 + 1900000),'YYYYDDD'),'yyyy-mm-dd'))||'T'|| decode(sg54RCTT,0,'00:00:00',to_char(to_date(LPAD(TO_CHAR(sg54RCTT),6,'0') , 'hh24miss'),'hh24:mi:ss')) ||'Z'  Ship_date
                   ,TRIM(sg$trk) sg$trk
                   ,TRIM(sgshanalph) sgshanalph
                   ,TRIM(sgshl1) sgshl1
                   ,TRIM(sgshl2) sgshl2
                   ,TRIM(sgshl3) sgshl3
                   ,TRIM(sgshl4) sgshl4
                   ,TRIM(sgvstct) sgvstct
                   ,TRIM(sgzipcd) sgzipcd
                   ,TRIM(sgstprov) sgstprov
                   ,TRIM(sgcntrydes) sgcntrydes
                   ,TRIM(sgar1) sgar1
                   ,TRIM(sgtelnumb) sgtelnumb
                   ,TRIM(sggnnm) sggnnm
                   ,TRIM(sgsrnm) sgsrnm

                 FROM proddta.F58INT11
                 WHERE sg$transid = v_TransmissionID
                 AND sgan8 = v_Customer
                 )

                 LOOP
                TEMP_UKID := AMS_OUT_REC.SGUKID;
                TEMP_$SERMCU:= AMS_OUT_REC.SG$SERMCU;
                TEMP_DOCO:= AMS_OUT_REC.SGDOCO;
                TEMP_ANUR:= AMS_OUT_REC.SGANUR;
                TEMP_RF1:= AMS_OUT_REC.SGRF1;
                TEMP_RF2:= AMS_OUT_REC.SGRF2;
                TEMP_RF3:= AMS_OUT_REC.SGRF3;
                TEMP_LITM:= AMS_OUT_REC.SGLITM;
                TEMP_DSC1:= AMS_OUT_REC.SGDSC1;

                TEMP_$CUSPRTN:= AMS_OUT_REC.SG$CUSPRTN;
                TEMP_DL03:= AMS_OUT_REC.SGDL03;
                TEMP_$CUSTLITM := AMS_OUT_REC.SG$CUSLITM;
                TEMP_LOTN:= AMS_OUT_REC.SGLOTN;
                TEMP_TRQT := AMS_OUT_REC.SGTRQT;
                TEMP_SHIPDATE :=AMS_OUT_REC.SHIP_DATE;
                TEMP_$TRK := AMS_OUT_REC.SG$TRK;
                TEMP_SHANAPLH:= AMS_OUT_REC.SGSHANALPH;
                TEMP_SHL1:= AMS_OUT_REC.SGSHL1;
                TEMP_SHL2 :=AMS_OUT_REC.SGSHL2;
                TEMP_SHL3 :=AMS_OUT_REC.SGSHL3;
                TEMP_SHL4 :=AMS_OUT_REC.SGSHL4;
                TEMP_VSTCT := AMS_OUT_REC.SGVSTCT;
                TEMP_ZIPCD := AMS_OUT_REC.SGZIPCD;
                TEMP_STPROV:= AMS_OUT_REC.SGSTPROV;
                TEMP_CNTRYDES:= AMS_OUT_REC.SGCNTRYDES;
                TEMP_AR1 := AMS_OUT_REC.SGAR1;
                TEMP_TELNUMB:= AMS_OUT_REC.SGTELNUMB;
                TEMP_GNNM:= AMS_OUT_REC.SGGNNM;
                TEMP_SRNM := AMS_OUT_REC.SGSRNM;

         l_SHIPPING_DETAILS_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'SHIPPING_DETAILS')));

         l_ukid_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'UNIQUE_ID' )));
         l_ukid_textnode := dbms_xmldom.appendChild( l_ukid_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_ukid )));

         l_BRANCH_PLANT_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'SHIP_BRANCH_PLANT' )));
         l_BRANCH_PLANT_textnode := dbms_xmldom.appendChild( l_BRANCH_PLANT_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$SERMCU )));

         l_PLXS_CASE_NUMBER_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_CASE_NUMBER' )));
         l_PLXS_CASE_NUMBER_textnode := dbms_xmldom.appendChild( l_PLXS_CASE_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_DOCO )));

         l_SHIPMENT_NUMBER_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'SHIPMENT_NUMBER' )));
         l_SHIPMENT_NUMBER_textnode := dbms_xmldom.appendChild( l_SHIPMENT_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_ANUR )));


         l_CUSTOMER_REFERENCE1_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE1' )));
         l_CUSTOMER_REFERENCE1_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REFERENCE1_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_RF1 )));

         l_CUSTOMER_REFERENCE2_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE2' )));
         l_CUSTOMER_REFERENCE2_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REFERENCE2_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_RF2 )));

         l_CUSTOMER_REFERENCE3_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE3' )));
         l_CUSTOMER_REFERENCE3_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REFERENCE3_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_RF3 )));

         l_PLXS_ITEM_NUMBER_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_ITEM_NUMBER' )));
         l_PLXS_ITEM_NUMBER_textnode := dbms_xmldom.appendChild( l_PLXS_ITEM_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_LITM )));

         l_ITEM_DESC_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ITEM_DESC' )));
         l_ITEM_DESC_textnode := dbms_xmldom.appendChild( l_ITEM_DESC_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_DSC1 )));

         l_CUSTOMER_ITEM_NUMBER_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_ITEM_NUMBER' )));
         l_CUSTOMER_ITEM_NUMBER_textnode := dbms_xmldom.appendChild( l_CUSTOMER_ITEM_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$CUSPRTN )));

         l_CUSTOMER_REV_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REV' )));
         l_CUSTOMER_REV_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REV_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_DL03 )));

         l_SECONDARY_CUSTOMER_ITEM_NUMBER_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'SECONDARY_CUSTOMER_ITEM_NUMBER' )));
         l_SECONDARY_CUSTOMER_ITEM_NUMBER_textnode := dbms_xmldom.appendChild( l_SECONDARY_CUSTOMER_ITEM_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$CUSTLITM )));

         l_LOT_SERIAL_NUMBER_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'LOT_SERIAL_NUMBER' )));
         l_LOT_SERIAL_NUMBER_textnode := dbms_xmldom.appendChild( l_LOT_SERIAL_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_LOTN )));

         l_QTY_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'QTY' )));
         l_QTY_textnode := dbms_xmldom.appendChild( l_QTY_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_TRQT )));

         l_SHIP_DATE_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'SHIP_DATE' )));
         l_SHIP_DATE_textnode := dbms_xmldom.appendChild( l_SHIP_DATE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_SHIPDATE )));

         l_CARRIER_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CARRIER' )));
         l_CARRIER_textnode := dbms_xmldom.appendChild( l_CARRIER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$CARNAM )));

         l_CARRIER_CODE_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CARRIER_CODE' )));
         l_CARRIER_CODE_textnode := dbms_xmldom.appendChild( l_CARRIER_CODE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$CARCODE )));

         l_SHIP_METHOD_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'SHIP_METHOD' )));
         l_SHIP_METHOD_textnode := dbms_xmldom.appendChild( l_SHIP_METHOD_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_OTMOT )));

         l_SHIP_TRACKING_NUMBER_node := dbms_xmldom.appendChild( l_SHIPPING_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'SHIP_TRACKING_NUMBER' )));
         l_SHIP_TRACKING_NUMBER_textnode := dbms_xmldom.appendChild( l_SHIP_TRACKING_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$TRK )));

         l_SHIP_TO_INFO_node := dbms_xmldom.appendChild(l_SHIPPING_DETAILS_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'SHIP_TO_INFO')));


         l_NAME_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'NAME' )));
         l_NAME_textnode := dbms_xmldom.appendChild( l_NAME_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_SHANAPLH )));

         l_ADDRESS1_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ADDRESS1' )));
         l_ADDRESS1_textnode := dbms_xmldom.appendChild( l_ADDRESS1_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_SHL1 )));

         l_ADDRESS2_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ADDRESS2' )));
         l_ADDRESS2_textnode := dbms_xmldom.appendChild( l_ADDRESS2_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_SHL2 )));

         l_ADDRESS3_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ADDRESS3' )));
         l_ADDRESS3_textnode := dbms_xmldom.appendChild( l_ADDRESS3_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_SHL3 )));

         l_ADDRESS4_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ADDRESS4' )));
         l_ADDRESS4_textnode := dbms_xmldom.appendChild( l_ADDRESS4_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_SHL4 )));

         l_CITY_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CITY' )));
         l_CITY_textnode := dbms_xmldom.appendChild( l_CITY_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_VSTCT )));

         l_ZIP_CODE_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ZIP_CODE' )));
         l_ZIP_CODE_textnode := dbms_xmldom.appendChild( l_ZIP_CODE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_ZIPCD )));

         l_STATE_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'STATE' )));
         l_STATE_textnode := dbms_xmldom.appendChild( l_STATE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_STPROV )));

         l_COUNTRY_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'COUNTRY' )));
         l_COUNTRY_textnode := dbms_xmldom.appendChild( l_COUNTRY_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_CNTRYDES )));

         l_AREACODE_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AREACODE' )));
         l_AREACODE_textnode := dbms_xmldom.appendChild( l_AREACODE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_AR1 )));

         l_PHONE_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PHONE' )));
         l_PHONE_textnode := dbms_xmldom.appendChild( l_PHONE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_TELNUMB )));

         l_CONTACT_FN_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CONTACT_FN' )));
         l_CONTACT_FN_textnode := dbms_xmldom.appendChild( l_CONTACT_FN_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_GNNM )));

         l_CONTACT_LN_node := dbms_xmldom.appendChild(l_SHIP_TO_INFO_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CONTACT_LN' )));
         l_CONTACT_LN_textnode := dbms_xmldom.appendChild( l_CONTACT_LN_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_SRNM )));



                FOR AMS_OUT_EXT_REC in
               (SELECT TRIM(nt$notetyp ) nt$notetyp
                       ,TRIM(ntgptx) ntgptx
                FROM proddta.f58INT12
                WHERE ntukid = TEMP_UKID
                AND   ntc75dct =  RPAD(TRIM(TEMP_C75DCT),60))

                LOOP
                l_EXTENDED_DATA_node := dbms_xmldom.appendChild(l_SHIPPING_DETAILS_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'EXTENDED_DATA')));

                TEMP_$notetyp := ams_out_ext_rec.nt$notetyp;
                TEMP_GPTX := ams_out_ext_rec.ntgptx;

                  l_AREA_TYPE_node := dbms_xmldom.appendChild(l_EXTENDED_DATA_node
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AREA_TYPE' )));
                  l_AREA_TYPE_textnode := dbms_xmldom.appendChild( l_AREA_TYPE_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$notetyp )));

                  l_AREA_DESC_node := dbms_xmldom.appendChild(l_EXTENDED_DATA_node
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AREA_DESC' )));
                  l_AREA_DESC_textnode := dbms_xmldom.appendChild( l_AREA_DESC_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_GPTX)));
                END LOOP;


        END LOOP;

        EXCEPTION
             WHEN OTHERS THEN

             --UPDATE PRODDTA.F58INT11 SET SG$RSP='E' WHERE sg$transid = v_TransmissionID AND sgan8 = v_Customer;
             --COMMIT;

             Temp_RetMsg :='Error: - '||SQLCODE||' -ERROR- '||substr(SQLERRM,1,2000) || ' -TransmissionID - '||NVL(v_TransmissionID, '') ||' -Customer- '||NVL(v_Customer, '');
        END; --END TRANSACTION

       l_xmltype := dbms_xmldom.getXmlType(l_domdoc);
       dbms_xmldom.freeDocument(l_domdoc);

       OUT_CLOBData := l_xmltype.getClobVal;

       OUT_RetMsg :=  Temp_RetMsg;
 END;

         PROCEDURE USP_F58INT11_UPDATE(SG$TRANSID_IN IN VARCHAR2
                                      ,SGAN8_IN NUMBER
                                         ,SGURLNAME_IN IN VARCHAR2
                                         ,SG$RSP_IN IN VARCHAR2
                                         ,SGLONGMSG_IN IN VARCHAR2
                                         ,SGUSER_IN VARCHAR2
                                         ,SGUPMJ_IN VARCHAR2
                                         ,SGUPMT_IN VARCHAR2
                                         ,SGCREATEDT_IN VARCHAR2
                                         ,P_RETMSG_OUT OUT VARCHAR2) IS
    BEGIN
        BEGIN
            UPDATE proddta.F58INT11
            SET SGURLNAME = SGURLNAME_IN
                ,SGUSER = SGUSER_IN
                ,SGUPMJ = SGUPMJ_IN
                ,SGUPMT = SGUPMT_IN
                ,SG$RSP = SG$RSP_IN
                ,SGCREATEDT = SGCREATEDT_IN
                ,SGLONGMSG = SGLONGMSG_IN
             WHERE SG$TRANSID = RPAD(TRIM(SG$TRANSID_IN),150,' ')
             AND SGAN8 = SGAN8_IN
             AND SG$RSP = 'B';

            P_RETMSG_OUT :='Update';

        END;
    END;

	FUNCTION GET_TRANSMISSIONID_FROM_F00022
	(P_TABLENAME      IN CHAR)
	RETURN VARCHAR
	AS TRANSMISSION_ID VARCHAR(20);
	V_UNIQUE_ID NUMBER:=0;
	NEXT_ID NUMBER;
	BEGIN
	SELECT F00022.UKUKID + 1,F00022.UKUKID
				  INTO
					  V_UNIQUE_ID,NEXT_ID
				  FROM
					  PRODDTA.F00022 F00022
				  WHERE
					  F00022.UKOBNM = P_TABLENAME FOR UPDATE;

				  UPDATE
					  PRODDTA.F00022
				  SET
					  UKUKID = V_UNIQUE_ID
				  WHERE
					  F00022.UKOBNM = P_TABLENAME;

				  --COMMIT THE TRANSACTION TO UNLOCK THE ROW.
				  COMMIT;
	TRANSMISSION_ID:='SDPL' || LPAD(NEXT_ID,15,'0');

	RETURN TRANSMISSION_ID;
	END;

PROCEDURE USP_AMS_SERVICE_DETAILS_SELECT(
	ACCOUNT_NUMBER    IN VARCHAR2
  ,PRODUCT_FAMILY  IN VARCHAR2
  ,MPF  IN VARCHAR2
  ,OUT_CLOBData OUT NOCOPY CLOB
  ,OUT_RetMsg OUT VARCHAR2 ) IS

   --Declarations
      Temp_RetMsg VARCHAR2(30000):='';
      v_TransmissionID VARCHAR(20);
	  v_ISALLOWEDFLAG CHAR(1);
      v_TPDS40 CHAR(40);
      v_Total_Count NUMBER:=0;
	  v_Select_Count NUMBER:=0;
	  v_F58INT12_NLIN_Count NUMBER:=0;
	  v_F58INT13_NLIN_Count NUMBER:=0;
	  v_F58INT15_NLIN_Count NUMBER:=0;
	  V_ADDL_RECORDS_AVL CHAR(1):='N';
		v_F58INT00_Count NUMBER;


      l_domdoc dbms_xmldom.DOMDocument;
      l_xmltype XMLTYPE;

      l_root_textnode dbms_xmldom.DOMNode;

      l_SERVICE_DETAILS_INFO_textnode dbms_xmldom.DOMNode;

      l_F58INT11_textnode dbms_xmldom.DOMNode;
      l_F58INT12_textnode dbms_xmldom.DOMNode;
      l_F58INT12_Rcd_textnode dbms_xmldom.DOMNode;
      l_F58INT13_textnode dbms_xmldom.DOMNode;
      l_F58INT13_Rcd_textnode dbms_xmldom.DOMNode;
      l_F58INT15_textnode dbms_xmldom.DOMNode;
      l_F58INT15_Rcd_textnode dbms_xmldom.DOMNode;
      l_F58INT00_textnode dbms_xmldom.DOMNode;
      l_F58INT00_Rcd_textnode dbms_xmldom.DOMNode;
      l_XXPLXS_TDM_VIEW_REPORT_textnode dbms_xmldom.DOMNode;
      l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode dbms_xmldom.DOMNode;

	  ADDL_RECORDS_AVL_node dbms_xmldom.DOMNode;
	  DOCUMENT_TYPE_node dbms_xmldom.DOMNode;
		MODULE_node dbms_xmldom.DOMNode;
		VERSION_node dbms_xmldom.DOMNode;
		TEST_FLAG_node dbms_xmldom.DOMNode;
		TRANSMISSION_DATE_node dbms_xmldom.DOMNode;
		TRANSMISSION_ID_node dbms_xmldom.DOMNode;
		CUSTOMER_node dbms_xmldom.DOMNode;
		MPF_node dbms_xmldom.DOMNode;
		COMPANY_node dbms_xmldom.DOMNode;
		UNIQUE_ID_node dbms_xmldom.DOMNode;
		SERVICE_BRANCH_PLANT_node dbms_xmldom.DOMNode;
		PLXS_CASE_NUMBER_node dbms_xmldom.DOMNode;
		WORK_ORDER_NUMBER_node dbms_xmldom.DOMNode;
		TRX_TYPE_node dbms_xmldom.DOMNode;
		TRX_DATE_node dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE1_node dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE2_node dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE3_node dbms_xmldom.DOMNode;
		PLXS_ITEM_NUMBER_node dbms_xmldom.DOMNode;
		ITEM_DESC_node dbms_xmldom.DOMNode;
		CUSTOMER_ITEM_NUMBER_node dbms_xmldom.DOMNode;
		CUSTOMER_REV_node dbms_xmldom.DOMNode;
		SECONDARY_CUSTOMER_ITEM_NUMBER_node dbms_xmldom.DOMNode;
		PLXS_OUT_ITEM_NUMBER_node dbms_xmldom.DOMNode;
		CUSTOMER_OUT_ITEM_NUMBER_node dbms_xmldom.DOMNode;
		LOT_SERIAL_NUMBER_node dbms_xmldom.DOMNode;
		QTY_node dbms_xmldom.DOMNode;
		OPERATION_SEQ_node dbms_xmldom.DOMNode;
		OPERATION_CODE_node dbms_xmldom.DOMNode;
		OPERATION_DESC_node dbms_xmldom.DOMNode;
		OPERATION_RESULT_node dbms_xmldom.DOMNode;
        OPERATION_COMMENT_node dbms_xmldom.DOMNode;
		OPERATION_COMPLETION_DATE_node dbms_xmldom.DOMNode;
		COMPLETED_BY_node dbms_xmldom.DOMNode;
		AREA_TYPE_node dbms_xmldom.DOMNode;
		AREA_DESC_node dbms_xmldom.DOMNode;
		OPERATION_SEQ_13_node dbms_xmldom.DOMNode;
		PART_NUMBER_node dbms_xmldom.DOMNode;
		LOT_SERIAL_NUMBER_13_node dbms_xmldom.DOMNode;
		REQUESTED_QUANTITY_node dbms_xmldom.DOMNode;
		ISSUED_QUANTITY_node dbms_xmldom.DOMNode;
        PLXS_DEFECT_CODE_node dbms_xmldom.DOMNode;
		PLXS_DEFECT_DESC_node dbms_xmldom.DOMNode;
		DEFECT_COMMENT_node dbms_xmldom.DOMNode;
        FORM_NAME_node dbms_xmldom.DOMNode;
        DISPLAY_SEQUENCE_node dbms_xmldom.DOMNode;
        ATTRIBUTE_LABEL_node dbms_xmldom.DOMNode;
        RESPONSE_node dbms_xmldom.DOMNode;
        IS_ALLOWED_FLAG_node dbms_xmldom.DOMNode;
        FILE_TYPE_node dbms_xmldom.DOMNode;

		ADDL_RECORDS_AVL_textnode dbms_xmldom.DOMNode;
		DOCUMENT_TYPE_textnode dbms_xmldom.DOMNode;
		MODULE_textnode dbms_xmldom.DOMNode;
		VERSION_textnode dbms_xmldom.DOMNode;
		TEST_FLAG_textnode dbms_xmldom.DOMNode;
		TRANSMISSION_DATE_textnode dbms_xmldom.DOMNode;
		TRANSMISSION_ID_textnode dbms_xmldom.DOMNode;
		CUSTOMER_textnode dbms_xmldom.DOMNode;
		MPF_textnode dbms_xmldom.DOMNode;
		COMPANY_textnode dbms_xmldom.DOMNode;
		UNIQUE_ID_textnode dbms_xmldom.DOMNode;
		SERVICE_BRANCH_PLANT_textnode dbms_xmldom.DOMNode;
		PLXS_CASE_NUMBER_textnode dbms_xmldom.DOMNode;
		WORK_ORDER_NUMBER_textnode dbms_xmldom.DOMNode;
		TRX_TYPE_textnode dbms_xmldom.DOMNode;
		TRX_DATE_textnode dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE1_textnode dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE2_textnode dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE3_textnode dbms_xmldom.DOMNode;
		PLXS_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;
		ITEM_DESC_textnode dbms_xmldom.DOMNode;
		CUSTOMER_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;
		CUSTOMER_REV_textnode dbms_xmldom.DOMNode;
		SECONDARY_CUSTOMER_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;
		PLXS_OUT_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;
		CUSTOMER_OUT_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;
		LOT_SERIAL_NUMBER_textnode dbms_xmldom.DOMNode;
		QTY_textnode dbms_xmldom.DOMNode;
		OPERATION_SEQ_textnode dbms_xmldom.DOMNode;
		OPERATION_CODE_textnode dbms_xmldom.DOMNode;
		OPERATION_DESC_textnode dbms_xmldom.DOMNode;
		OPERATION_RESULT_textnode dbms_xmldom.DOMNode;
        OPERATION_COMMENT_textnode dbms_xmldom.DOMNode;
		OPERATION_COMPLETION_DATE_textnode dbms_xmldom.DOMNode;
		COMPLETED_BY_textnode dbms_xmldom.DOMNode;
		AREA_TYPE_textnode dbms_xmldom.DOMNode;
		AREA_DESC_textnode dbms_xmldom.DOMNode;
		OPERATION_SEQ_13_textnode dbms_xmldom.DOMNode;
		PART_NUMBER_textnode dbms_xmldom.DOMNode;
		LOT_SERIAL_NUMBER_13_textnode dbms_xmldom.DOMNode;
		REQUESTED_QUANTITY_textnode dbms_xmldom.DOMNode;
		ISSUED_QUANTITY_textnode dbms_xmldom.DOMNode;
        PLXS_DEFECT_CODE_textnode dbms_xmldom.DOMNode;
		PLXS_DEFECT_DESC_textnode dbms_xmldom.DOMNode;
		DEFECT_COMMENT_textnode dbms_xmldom.DOMNode;
        FORM_NAME_textnode dbms_xmldom.DOMNode;
        DISPLAY_SEQUENCE_textnode dbms_xmldom.DOMNode;
        ATTRIBUTE_LABEL_textnode dbms_xmldom.DOMNode;
        RESPONSE_textnode dbms_xmldom.DOMNode;

        IS_ALLOWED_FLAG_textnode dbms_xmldom.DOMNode;
        FILE_TYPE_textnode dbms_xmldom.DOMNode;

    TEMP_C75DCT CHAR(60);
	TEMP_LRSSM CHAR(10);
	TEMP_B76VER CHAR(10);
	TEMP_$TSTFLAG CHAR(1);
	TEMP_CREATEDT VARCHAR(30):= TO_CHAR(SYS_EXTRACT_UTC(SYSTIMESTAMP),'YYYY-MM-DD"T"HH24:MI:SS.ff3"Z"');
	TEMP_TRANSDate VARCHAR(30);
	TEMP_$TRANSID CHAR(150);
	TEMP_ALPH CHAR(40);
	TEMP_$MPFNUM CHAR(25);
	TEMP_UKID NUMBER;
	TEMP_$SERMCU CHAR(15);
	TEMP_DOCO NUMBER;
	TEMP_WOD NUMBER;
	TEMP_TRNDES CHAR(30);
	TEMP_$GS04 NUMBER;
	TEMP_RF1 CHAR(30);
	TEMP_RF2 CHAR(30);
	TEMP_RF3 CHAR(30);
	TEMP_LITM CHAR(25);
	TEMP_DSC1 CHAR(30);
	TEMP_$CUSPRTN CHAR(30);
	TEMP_DL03 CHAR(30);
	TEMP_KITL CHAR(25);
	TEMP_CITM CHAR(25);
	TEMP_LOTN CHAR(30);
	TEMP_TRQT NUMBER;
	TEMP_OPSQ NUMBER;
	TEMP_$58OC CHAR(8);
	TEMP_DSC1_15  CHAR(30);
	TEMP_DL01 CHAR(30);
	TEMP_UPMJ NUMBER;
    Temp_OprCmt VARCHAR2(512);
	Temp_OprDate VARCHAR(30);
	TEMP_UPMT NUMBER;
	TEMP_ALPH_15 CHAR(40);
	TEMP_$NOTETYP CHAR(100);
	TEMP_GPTX VARCHAR2(1500);
	TEMP_OPSQ_13 NUMBER;
	TEMP_CPIL CHAR(25);
	TEMP_LOTN_13 CHAR(30);
	TEMP_UORG NUMBER;
	TEMP_TRQT_13 NUMBER;
	TEMP_DL01_13 CHAR(30);
    TEMP_DC01 CHAR(5);
	TEMP_VCOMMENT CHAR(60);
	v_F58INT00_Select_Count NUMBER;
	v_CountF00022 NUMBER;
    TEMP_FORM_NAME VARCHAR(250);
    TEMP_DISPLAY_SEQUENCE NUMBER;
    TEMP_ATTRIBUTE_LABEL VARCHAR(300);
    TEMP_RESPONSE VARCHAR(2000);

BEGIN
  --Creates an exmpty XML Document
      l_domdoc := dbms_xmldom.newDOMDocument;

      --Creates a root node
      l_root_textnode := dbms_xmldom.makeNode(l_domdoc);
DBMS_OUTPUT.PUT_LINE('Start');
BEGIN
	  SELECT count(1) INTO v_F58INT00_Select_Count FROM PRODDTA.F58INT00 WHERE TPPNID=CAST(ACCOUNT_NUMBER as CHAR(15)) AND TP$SERMCU=CAST(PRODUCT_FAMILY as CHAR(15)) AND TP$MPFNUM=CAST(MPF as CHAR(25));
DBMS_OUTPUT.PUT_LINE('v_F58INT00_Select_Count'||v_F58INT00_Select_Count);

	  IF v_F58INT00_Select_Count>0 THEN
		BEGIN
			SELECT TPEV08, TP$COUNT08, TPDS40 INTO v_ISALLOWEDFLAG, v_F58INT00_Count, v_TPDS40 FROM PRODDTA.F58INT00 WHERE TPPNID=CAST(ACCOUNT_NUMBER as CHAR(15)) AND TP$SERMCU=CAST(PRODUCT_FAMILY as CHAR(15)) AND TP$MPFNUM=CAST(MPF as CHAR(25));
		END;
		ELSE
		BEGIN
			v_ISALLOWEDFLAG:='N';

		END;
		END IF;


DBMS_OUTPUT.PUT_LINE('v_ISALLOWEDFLAG'||v_ISALLOWEDFLAG||'v_F58INT00_Count'|| v_F58INT00_Count);
	IF (v_ISALLOWEDFLAG='Y') THEN
	BEGIN

		SELECT COUNT(1) INTO v_Total_Count
        FROM PRODDTA.F58INT11 WHERE SGPNID=CAST(ACCOUNT_NUMBER as CHAR(15)) AND SG$SERMCU=CAST(PRODUCT_FAMILY as CHAR(15)) AND SG$MPFNUM=CAST(MPF as CHAR(25))
        AND SG$RSP IN ('P', 'E') AND SGC75DCT='Service Detail' and SGLRSSM='SDM';


		SELECT count(1) INTO v_CountF00022  FROM PRODDTA.F00022 WHERE ukobnm = 'TRNSDM';
			IF (v_CountF00022>0) THEN
			BEGIN
				v_TransmissionID:= BIZTALK.PKG_AMS_OUTBOUND.GET_TRANSMISSIONID_FROM_F00022('TRNSDM');
			END;
			ELSE
			BEGIN
				DBMS_OUTPUT.put_line('Insert PRODDTA.F00022');
				INSERT INTO PRODDTA.F00022
				(UKOBNM,UKUKID)
				VALUES
				('TRNSDM',1);

				v_TransmissionID:= 'SDPL' || LPAD(1,15,'0');
			END;
			END IF;

DBMS_OUTPUT.PUT_LINE('v_TransmissionID'||v_TransmissionID);

		IF (v_Total_Count > v_F58INT00_Count) THEN
		BEGIN
			V_ADDL_RECORDS_AVL:='Y';
			v_Select_Count:=v_F58INT00_Count;
		END;
		ELSE
		BEGIN
			v_Select_Count:=v_Total_Count;
		END;
		END IF;

DBMS_OUTPUT.PUT_LINE('V_ADDL_RECORDS_AVL'||V_ADDL_RECORDS_AVL||'v_Select_Count'||v_Select_Count||'v_Total_Count'||v_Total_Count);

 FOR AMS_F58INT11_REC_UPDATE in
  (
  SELECT SGC75DCT
	,SGUKID
  FROM PRODDTA.F58INT11
  WHERE --sglrssm='SDM' and sgukid in (138, 139, 141, 142, 153, 154, 155)
  SGPNID=CAST(ACCOUNT_NUMBER as CHAR(15)) AND SG$SERMCU=CAST(PRODUCT_FAMILY as CHAR(15)) AND SG$MPFNUM=CAST(MPF as CHAR(25))
  AND SG$RSP IN ('P', 'E') AND SGC75DCT='Service Detail' and SGLRSSM='SDM'
  --AND ROWNUM <= v_Select_Count
  ORDER BY SGC75DCT, SGUKID
  FETCH FIRST v_Select_Count ROWS ONLY
  )

  LOOP
		  DBMS_OUTPUT.PUT_LINE(AMS_F58INT11_REC_UPDATE.SGC75DCT||'~~'||AMS_F58INT11_REC_UPDATE.SGUKID);
		UPDATE PRODDTA.F58INT11 A SET SG$RSP='B',SG$TRANSID=v_TransmissionID  WHERE SGC75DCT=AMS_F58INT11_REC_UPDATE.SGC75DCT AND SGUKID=AMS_F58INT11_REC_UPDATE.SGUKID;

		COMMIT;
 END LOOP;
		DBMS_OUTPUT.PUT_LINE('First update completed');

             --Create the XML structure for the Header/Non repeating sections
      l_SERVICE_DETAILS_INFO_textnode := dbms_xmldom.appendChild(l_root_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'AMS_SERVICE_DETAILS_INFO')));

      --Create Header or Non-Repeating XML nodes based on one record of the
      --TransmissionID/Customer Number
      FOR AMS_F58INT11_REC in
          (
		  SELECT SGC75DCT
,SGLRSSM
,SGB76VER
,SG$TSTFLAG
,SGCREATEDT
,SG$TRANSID
,SGALPH
,SG$MPFNUM
,SGUKID
,SG$SERMCU
,SGDOCO
,SGWOD
,SGTRNDES
,SG$GS04
,DECODE(SG$GS04,0,'0',TO_CHAR(TO_DATE(TO_CHAR(SG$GS04 + 1900000),'YYYYDDD'),'yyyy-mm-dd'))||'T'|| decode(0,0,'00:00:00',to_char(to_date(LPAD(TO_CHAR(0),6,'0') , 'hh24miss'),'hh24:mi:ss'))||'Z' TRANSDate
,SGRF1
,SGRF2
,SGRF3
,SGLITM
,SGDSC1
,SG$CUSPRTN
,SGDL03
,SGKITL
,SGCITM
,SGLOTN
,SGTRQT
		  FROM PRODDTA.F58INT11
		  WHERE SGPNID=CAST(ACCOUNT_NUMBER as CHAR(15)) AND SG$SERMCU=CAST(PRODUCT_FAMILY as CHAR(15)) AND SG$MPFNUM=CAST(MPF as CHAR(25)) AND SG$TRANSID=CAST(v_TransmissionID as CHAR(150))
          AND SGC75DCT='Service Detail' and SGLRSSM='SDM'
          AND ROWNUM <= v_Select_Count
		  ORDER BY SGC75DCT, SGUKID
		  )

          LOOP

		DBMS_OUTPUT.PUT_LINE('F58INT11 select completed');
            TEMP_C75DCT := AMS_F58INT11_REC.SGC75DCT;
			TEMP_LRSSM := AMS_F58INT11_REC.SGLRSSM;
			TEMP_B76VER := AMS_F58INT11_REC.SGB76VER;
			TEMP_$TSTFLAG := AMS_F58INT11_REC.SG$TSTFLAG;
			TEMP_TRANSDate := AMS_F58INT11_REC.TRANSDate;
			DBMS_OUTPUT.PUT_LINE('F58INT11 - 1');
			TEMP_$TRANSID := AMS_F58INT11_REC.SG$TRANSID;
			TEMP_ALPH := AMS_F58INT11_REC.SGALPH;
			TEMP_$MPFNUM := AMS_F58INT11_REC.SG$MPFNUM;
			TEMP_UKID := AMS_F58INT11_REC.SGUKID;
			TEMP_$SERMCU := AMS_F58INT11_REC.SG$SERMCU;
			DBMS_OUTPUT.PUT_LINE('F58INT11 - 2');
			TEMP_DOCO := AMS_F58INT11_REC.SGDOCO;
			TEMP_WOD := AMS_F58INT11_REC.SGWOD;
			TEMP_TRNDES := AMS_F58INT11_REC.SGTRNDES;
			TEMP_$GS04 := AMS_F58INT11_REC.SG$GS04;
			TEMP_RF1 := AMS_F58INT11_REC.SGRF1;
			DBMS_OUTPUT.PUT_LINE('F58INT11 - 3');
			TEMP_RF2 := AMS_F58INT11_REC.SGRF2;
			TEMP_RF3 := AMS_F58INT11_REC.SGRF3;
			TEMP_LITM := AMS_F58INT11_REC.SGLITM;
			TEMP_DSC1 := AMS_F58INT11_REC.SGDSC1;
			TEMP_$CUSPRTN := AMS_F58INT11_REC.SG$CUSPRTN;
			TEMP_DL03 := AMS_F58INT11_REC.SGDL03;
			DBMS_OUTPUT.PUT_LINE('F58INT11 - 4');
			TEMP_KITL := AMS_F58INT11_REC.SGKITL;
			TEMP_CITM := AMS_F58INT11_REC.SGCITM;
			TEMP_LOTN := AMS_F58INT11_REC.SGLOTN;
			TEMP_TRQT := AMS_F58INT11_REC.SGTRQT;
DBMS_OUTPUT.PUT_LINE('F58INT11 select variable assign completed');

			l_F58INT11_textnode:= dbms_xmldom.appendChild(l_SERVICE_DETAILS_INFO_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'F58INT11')));

           DOCUMENT_TYPE_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DOCUMENT_TYPE')));
			DOCUMENT_TYPE_textnode	:= dbms_xmldom.appendChild(	DOCUMENT_TYPE_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_C75DCT)) )));

			MODULE_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'MODULE')));
			MODULE_textnode	:= dbms_xmldom.appendChild(	MODULE_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_LRSSM)) )));

			VERSION_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'VERSION')));
			VERSION_textnode	:= dbms_xmldom.appendChild(	VERSION_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_B76VER))  )));

			TEST_FLAG_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TEST_FLAG')));
			TEST_FLAG_textnode	:= dbms_xmldom.appendChild(	TEST_FLAG_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$TSTFLAG)) )));

DBMS_OUTPUT.PUT_LINE('F58INT11 select xml assign test flag completed');

			TRANSMISSION_DATE_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRANSMISSION_DATE')));
			TRANSMISSION_DATE_textnode	:= dbms_xmldom.appendChild(	TRANSMISSION_DATE_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_CREATEDT )));

			TRANSMISSION_ID_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRANSMISSION_ID')));
			TRANSMISSION_ID_textnode	:= dbms_xmldom.appendChild(	TRANSMISSION_ID_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$TRANSID )))));

			CUSTOMER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER')));
			CUSTOMER_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_ALPH)) )));

			MPF_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'MPF')));
			MPF_textnode	:= dbms_xmldom.appendChild(	MPF_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$MPFNUM)) )));


DBMS_OUTPUT.PUT_LINE('F58INT11 select xml assign MPF flag completed');

			UNIQUE_ID_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'UNIQUE_ID')));
			UNIQUE_ID_textnode	:= dbms_xmldom.appendChild(	UNIQUE_ID_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_UKID )))));

			SERVICE_BRANCH_PLANT_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'SERVICE_BRANCH_PLANT')));
			SERVICE_BRANCH_PLANT_textnode	:= dbms_xmldom.appendChild(	SERVICE_BRANCH_PLANT_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$SERMCU)) )));

			PLXS_CASE_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_CASE_NUMBER')));
			PLXS_CASE_NUMBER_textnode	:= dbms_xmldom.appendChild(	PLXS_CASE_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_DOCO))  )));

			WORK_ORDER_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'WORK_ORDER_NUMBER')));
			WORK_ORDER_NUMBER_textnode	:= dbms_xmldom.appendChild(	WORK_ORDER_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_WOD))  )));

			TRX_TYPE_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRX_TYPE')));
			TRX_TYPE_textnode	:= dbms_xmldom.appendChild(	TRX_TYPE_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_TRNDES)) )));

			TRX_DATE_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRX_DATE')));
			TRX_DATE_textnode	:= dbms_xmldom.appendChild(	TRX_DATE_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_TRANSDate)) )));

			CUSTOMER_REFERENCE1_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE1')));
			CUSTOMER_REFERENCE1_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_REFERENCE1_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,  ltrim(rtrim(TEMP_RF1)))));

DBMS_OUTPUT.PUT_LINE('F58INT11 select xml assign CUSTOMER_REFERENCE1_node flag completed');
			CUSTOMER_REFERENCE2_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE2')));
			CUSTOMER_REFERENCE2_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_REFERENCE2_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_RF2)) )));

			CUSTOMER_REFERENCE3_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE3')));
			CUSTOMER_REFERENCE3_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_REFERENCE3_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_RF3))  )));

			PLXS_ITEM_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_ITEM_NUMBER')));
			PLXS_ITEM_NUMBER_textnode	:= dbms_xmldom.appendChild(	PLXS_ITEM_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_LITM)) )));

			ITEM_DESC_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ITEM_DESC')));
			ITEM_DESC_textnode	:= dbms_xmldom.appendChild(	ITEM_DESC_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_DSC1))  )));

			CUSTOMER_ITEM_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_ITEM_NUMBER')));
			CUSTOMER_ITEM_NUMBER_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_ITEM_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$CUSPRTN)) )));

			CUSTOMER_REV_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REV')));
			CUSTOMER_REV_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_REV_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DL03)) )));

			PLXS_OUT_ITEM_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_OUT_ITEM_NUMBER')));
			PLXS_OUT_ITEM_NUMBER_textnode	:= dbms_xmldom.appendChild(	PLXS_OUT_ITEM_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_KITL)) )));

			CUSTOMER_OUT_ITEM_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_OUT_ITEM_NUMBER')));
			CUSTOMER_OUT_ITEM_NUMBER_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_OUT_ITEM_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_CITM))  )));

			LOT_SERIAL_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'LOT_SERIAL_NUMBER')));
			LOT_SERIAL_NUMBER_textnode	:= dbms_xmldom.appendChild(	LOT_SERIAL_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_LOTN)) )));

			QTY_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'QTY')));
			QTY_textnode	:= dbms_xmldom.appendChild(	QTY_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_TRQT)) )));

			ADDL_RECORDS_AVL_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ADDL_RECORDS_AVL')));
			ADDL_RECORDS_AVL_textnode	:= dbms_xmldom.appendChild(	ADDL_RECORDS_AVL_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(V_ADDL_RECORDS_AVL)) )));



DBMS_OUTPUT.PUT_LINE('F58INT11 select xml assign QTY_textnode flag completed');
			l_F58INT15_textnode := dbms_xmldom.appendChild(l_F58INT11_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'F58INT15')));

			FOR AMS_F58INT15_REC IN
               (
			   SELECT SDOPSQ
					,SD$58OC
					,SDDSC1
					,SDDL01
					,DECODE(SDMUPM,0,'0',TO_CHAR(TO_DATE(TO_CHAR(SDMUPM + 1900000),'YYYYDDD'),'yyyy-mm-dd'))||'T'|| decode(SDUPMT,0,'00:00:00',to_char(to_date(LPAD(TO_CHAR(SDUPMT),6,'0') , 'hh24miss'),'hh24:mi:ss'))||'Z' as OprDate
					,SDCMMNT
                    ,SDUPMJ
					,SDUPMT
					,SDALPH
			   FROM PRODDTA.F58INT15
			   WHERE SDC75DCT=TEMP_C75DCT AND SDUKID=TEMP_UKID
			   ORDER BY SDC75DCT, SDUKID, SDNLIN
			   )

                LOOP
DBMS_OUTPUT.PUT_LINE('F58INT15 select completed');
                TEMP_OPSQ := AMS_F58INT15_REC.SDOPSQ;
                TEMP_$58OC := AMS_F58INT15_REC.SD$58OC;
                TEMP_DSC1_15 := AMS_F58INT15_REC.SDDSC1;
                TEMP_DL01 := AMS_F58INT15_REC.SDDL01;
                TEMP_UPMJ := AMS_F58INT15_REC.SDUPMJ;
                TEMP_UPMT := AMS_F58INT15_REC.SDUPMT;
                Temp_OprCmt:=	AMS_F58INT15_REC.SDCMMNT;
				Temp_OprDate:=	AMS_F58INT15_REC.OprDate;
                TEMP_ALPH_15 := AMS_F58INT15_REC.SDALPH;

					l_F58INT15_Rcd_textnode:= dbms_xmldom.appendChild(l_F58INT15_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'Record')));

				 OPERATION_SEQ_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_SEQ' )));
                  OPERATION_SEQ_textnode := dbms_xmldom.appendChild( OPERATION_SEQ_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_OPSQ/100)) )));

                  OPERATION_CODE_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_CODE' )));
                  OPERATION_CODE_textnode := dbms_xmldom.appendChild( OPERATION_CODE_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$58OC)))));

				OPERATION_DESC_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_DESC' )));
                  OPERATION_DESC_textnode := dbms_xmldom.appendChild( OPERATION_DESC_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DSC1_15)) )));

                  OPERATION_RESULT_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_RESULT' )));
                  OPERATION_RESULT_textnode := dbms_xmldom.appendChild( OPERATION_RESULT_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DL01)))));

                  OPERATION_COMMENT_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_COMMENT' )));
                  OPERATION_COMMENT_textnode := dbms_xmldom.appendChild( OPERATION_COMMENT_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(Temp_OprCmt)))));

				OPERATION_COMPLETION_DATE_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_COMPLETION_DATE' )));
                  OPERATION_COMPLETION_DATE_textnode := dbms_xmldom.appendChild( OPERATION_COMPLETION_DATE_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, Temp_OprDate )));

                  COMPLETED_BY_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'COMPLETED_BY' )));
                  COMPLETED_BY_textnode := dbms_xmldom.appendChild( COMPLETED_BY_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_ALPH_15)))));

                 l_XXPLXS_TDM_VIEW_REPORT_textnode := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'XXPLXS_TDM_VIEW_REPORT')));
                 DBMS_OUTPUT.PUT_LINE('XXPLXS_TDM_VIEW_REPORT_REC - Started | ' || to_char(TEMP_WOD) || ' | ' || TO_CHAR(TEMP_OPSQ/100) || ' | ' || to_char(TEMP_$58OC));

                  FOR XXPLXS_TDM_VIEW_REPORT_REC IN
                  (
                    SELECT FORM_NAME,
                          DISPLAY_SEQUENCE,
                          ATTRIBUTE_LABEL,
                          RESPONSE
                    FROM Xxapps.plxs_complete_v
                    WHERE work_order_number     = ltrim(rtrim(TEMP_WOD))              --SERVICE_DETAIL/WORK_ORDER_NUMBER
                        AND display_sequence    IS NOT NULL
                        AND (qa_header_id is null or (qa_header_id is not null and qa_line_id is not null))
                        AND operation_seq       = ltrim(rtrim((TEMP_OPSQ/100)))   --SERVICE_DETAIL/OPERATION_DETAIL/OPERATION_SEQ
                        AND operation_code      = ltrim(rtrim(TEMP_$58OC))        --SERVICE_DETAIL/OPERATION_DETAIL/OPERATION_CODE
                        AND attribute_type      !='LABEL'
						AND REPORTING_FLAG      ='Y'
                    ORDER BY OPERATION_SEQ,FORM_SEQUENCE,DISPLAY_SEQUENCE
                   )
                   LOOP
                        TEMP_FORM_NAME := XXPLXS_TDM_VIEW_REPORT_REC.FORM_NAME;
                        TEMP_DISPLAY_SEQUENCE := XXPLXS_TDM_VIEW_REPORT_REC.DISPLAY_SEQUENCE;
                        TEMP_ATTRIBUTE_LABEL := XXPLXS_TDM_VIEW_REPORT_REC.ATTRIBUTE_LABEL;
                        TEMP_RESPONSE := XXPLXS_TDM_VIEW_REPORT_REC.RESPONSE;
                        DBMS_OUTPUT.PUT_LINE('XXPLXS_TDM_VIEW_REPORT_REC - Loop started ' || XXPLXS_TDM_VIEW_REPORT_REC.FORM_NAME);
                        l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode:= dbms_xmldom.appendChild(l_XXPLXS_TDM_VIEW_REPORT_textnode
                                                        ,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'XXPLXS_TDM_VIEW_REPORT_Record')));

                        FORM_NAME_node := dbms_xmldom.appendChild(l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'FORM_NAME' )));
                        FORM_NAME_textnode := dbms_xmldom.appendChild( FORM_NAME_node
                                                             , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_FORM_NAME)))));

                        DISPLAY_SEQUENCE_node := dbms_xmldom.appendChild(l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DISPLAY_SEQUENCE' )));
                        DISPLAY_SEQUENCE_textnode := dbms_xmldom.appendChild( DISPLAY_SEQUENCE_node
                                                             , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DISPLAY_SEQUENCE)))));

                        ATTRIBUTE_LABEL_node := dbms_xmldom.appendChild(l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ATTRIBUTE_LABEL' )));
                        ATTRIBUTE_LABEL_textnode := dbms_xmldom.appendChild( ATTRIBUTE_LABEL_node
                                                             , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_ATTRIBUTE_LABEL)))));

                        RESPONSE_node := dbms_xmldom.appendChild(l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'RESPONSE' )));
                        RESPONSE_textnode := dbms_xmldom.appendChild( RESPONSE_node
                                                             , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_RESPONSE)))));
                   END LOOP;
                   DBMS_OUTPUT.PUT_LINE('XXPLXS_TDM_VIEW_REPORT_REC - Ended');
            END LOOP;



			l_F58INT12_textnode := dbms_xmldom.appendChild(l_F58INT11_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'F58INT12')));

			FOR AMS_F58INT12_REC IN
               (SELECT NT$NOTETYP
					,NTGPTX
                FROM PRODDTA.F58INT12
                WHERE NTUKID = TEMP_UKID
                AND   ntc75dct =  RPAD(TRIM(TEMP_C75DCT),60)
				ORDER BY NTC75DCT, NTUKID, NTNLIN)

                LOOP

DBMS_OUTPUT.PUT_LINE('F58INT12 select completed');
                TEMP_$NOTETYP := AMS_F58INT12_REC.NT$NOTETYP;
                TEMP_GPTX := AMS_F58INT12_REC.NTGPTX;

			l_F58INT12_Rcd_textnode:= dbms_xmldom.appendChild(l_F58INT12_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'Record')));
                  AREA_TYPE_node := dbms_xmldom.appendChild(l_F58INT12_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AREA_TYPE' )));
                  AREA_TYPE_textnode := dbms_xmldom.appendChild( AREA_TYPE_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$NOTETYP)) )));

                  AREA_DESC_node := dbms_xmldom.appendChild(l_F58INT12_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AREA_DESC' )));
                  AREA_DESC_textnode := dbms_xmldom.appendChild( AREA_DESC_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_GPTX)))));
            END LOOP;
			l_F58INT13_textnode := dbms_xmldom.appendChild(l_F58INT11_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'F58INT13')));

			FOR AMS_F58INT13_REC IN
               (
			   SELECT PIOPSQ
					,PICPIL
					,PILOTN
					,PIUORG
					,PITRQT
					,PIDL01
                    ,PI$58DC
					,PIVCOMMENT
			   FROM PRODDTA.F58INT13 where PIC75DCT=TEMP_C75DCT AND PIUKID=TEMP_UKID
			   ORDER BY PIC75DCT, PIUKID, PINLIN
			   )

                LOOP

DBMS_OUTPUT.PUT_LINE('F58INT13 select completed');
                TEMP_OPSQ := AMS_F58INT13_REC.PIOPSQ;
                TEMP_CPIL := AMS_F58INT13_REC.PICPIL;
                TEMP_LOTN_13 := AMS_F58INT13_REC.PILOTN;
                TEMP_UORG := AMS_F58INT13_REC.PIUORG;
                TEMP_TRQT_13 := AMS_F58INT13_REC.PITRQT;
                TEMP_DL01 := AMS_F58INT13_REC.PIDL01;
                TEMP_DC01 := AMS_F58INT13_REC.PI$58DC;
                TEMP_VCOMMENT := AMS_F58INT13_REC.PIVCOMMENT;

			l_F58INT13_Rcd_textnode:= dbms_xmldom.appendChild(l_F58INT13_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'Record')));
                  OPERATION_SEQ_13_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_SEQ' )));
                  OPERATION_SEQ_13_textnode := dbms_xmldom.appendChild( OPERATION_SEQ_13_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_OPSQ/100)) )));

                  PART_NUMBER_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PART_NUMBER' )));
                  PART_NUMBER_textnode := dbms_xmldom.appendChild( PART_NUMBER_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_CPIL)))));

					LOT_SERIAL_NUMBER_13_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'LOT_SERIAL_NUMBER' )));
                  LOT_SERIAL_NUMBER_13_textnode := dbms_xmldom.appendChild( LOT_SERIAL_NUMBER_13_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_LOTN_13)) )));

                  REQUESTED_QUANTITY_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'REQUESTED_QUANTITY' )));
                  REQUESTED_QUANTITY_textnode := dbms_xmldom.appendChild( REQUESTED_QUANTITY_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_UORG)))));

                  ISSUED_QUANTITY_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ISSUED_QUANTITY' )));
                  ISSUED_QUANTITY_textnode := dbms_xmldom.appendChild( ISSUED_QUANTITY_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_TRQT_13)))));

                  PLXS_DEFECT_CODE_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_DEFECT_CODE' )));
                  PLXS_DEFECT_CODE_textnode := dbms_xmldom.appendChild( PLXS_DEFECT_CODE_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DC01)) )));

					PLXS_DEFECT_DESC_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_DEFECT_DESC' )));
                  PLXS_DEFECT_DESC_textnode := dbms_xmldom.appendChild( PLXS_DEFECT_DESC_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DL01)) )));

                  DEFECT_COMMENT_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DEFECT_COMMENT' )));
                  DEFECT_COMMENT_textnode := dbms_xmldom.appendChild( DEFECT_COMMENT_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_VCOMMENT)))));
            END LOOP;


            --Cloud IO nodes
            l_F58INT00_textnode := dbms_xmldom.appendChild(l_F58INT11_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'F58INT00')));

            l_F58INT00_Rcd_textnode:= dbms_xmldom.appendChild(l_F58INT00_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'Record')));
                  IS_ALLOWED_FLAG_node := dbms_xmldom.appendChild(l_F58INT00_Rcd_textnode
                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'IS_ALLOWED_FLAG' )));
                  IS_ALLOWED_FLAG_textnode := dbms_xmldom.appendChild( IS_ALLOWED_FLAG_node
                                        , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(v_ISALLOWEDFLAG)) )));

                  FILE_TYPE_node := dbms_xmldom.appendChild(l_F58INT00_Rcd_textnode
                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'FILE_TYPE' )));
                  FILE_TYPE_textnode := dbms_xmldom.appendChild( FILE_TYPE_node
                                        , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(v_TPDS40)) )));


			UPDATE PRODDTA.F58INT11 SET SG$RSP='W' ,SGCREATEDT=TEMP_CREATEDT ,SGUSER = 'BIZTALK'
                ,SGUPMT = to_char(cast(SYSDATE as date),'hh24miss')
                ,SGUPMJ = To_Number(To_Char(To_Number(To_Char(sysdate, 'yyyy')) - 1900) || To_Char(sysdate, 'ddd'))
				,SGPID= 'BIZTALK'
				,SGJOBN	= 'BIZTALK'	WHERE SGC75DCT=TEMP_C75DCT AND SGUKID=TEMP_UKID ;
			COMMIT;
          END LOOP;


	END;
	ELSE
	BEGIN
		Temp_RetMsg:='Error: Customer Not configured for PULL Transactions in JDE';
	END;
	END IF;

EXCEPTION
	 WHEN OTHERS THEN

	 UPDATE PRODDTA.F58INT11 SET SG$RSP='E' WHERE SGPNID=CAST(ACCOUNT_NUMBER as CHAR(15)) AND SG$SERMCU=CAST(PRODUCT_FAMILY as CHAR(15)) AND SG$MPFNUM=CAST(MPF as CHAR(25)) AND SG$RSP IN ('B','W') AND SG$TRANSID=v_TransmissionID;
		COMMIT;
--			raise_application_error(-20001,'MessageID '|| Temp_MessageID||' An error was encountered - '||SQLCODE||' -ERROR- '||substr(SQLERRM,1,200));
		Temp_RetMsg :='Error: - '||SQLCODE||' -ERROR- '||substr(SQLERRM,1,2000);
END; --END TRANSACTION

	l_xmltype := dbms_xmldom.getXmlType(l_domdoc);
		dbms_xmldom.freeDocument(l_domdoc);

		OUT_CLOBData := l_xmltype.getClobVal;

		OUT_RetMsg :=  Temp_RetMsg;

END;

 PROCEDURE USP_AMS_SERVICE_DETAILS_STATUS_UPDATE
 (
   P_CLOBData_in  IN CLOB
  ,P_RetMsg_out	  OUT VARCHAR2
 ) AS

 Temp_MessageID VARCHAR2(500);
 P_XMLData_in XMLTYPE;
 Temp_RetMsg VARCHAR2(4000):='SUCCESS';
temp_CLOBData CLOB;
 v_UNIQUE_ID NUMBER;
 v_MPF CHAR(25);
 v_ACCOUNT_NUMBER CHAR(15):=0;
 v_PRODUCT_FAMILY CHAR(15):=0;
 v_STATUS CHAR(1):=0;
 v_MESSAGE VARCHAR2(2000);
BEGIN

  BEGIN
   select replace (P_CLOBData_in,'CHR(38)','&' || 'amp;') INTO temp_CLOBData from dual;
   select replace (temp_CLOBData,'CHR(60)','&' || 'lt;') INTO temp_CLOBData from dual;
   select replace (temp_CLOBData,'CHR(62)','&' || 'gt;') INTO temp_CLOBData from dual;

P_XMLData_in := xmltype.createxml(temp_CLOBData);

		SELECT xt."MessageID" INTO Temp_MessageID
		FROM   XMLTABLE('/CanonicalServiceDetailStatusUpdateReq'
				 PASSING (P_XMLData_in)
				 COLUMNS
				   "MessageID" PATH 'MessageID'
				 ) xt;

DBMS_OUTPUT.put_line('Fetching data for PRODDTA.F58INT11 insert');
FOR cur_SERVICE_DETAILS_STATUS IN (
		SELECT xt.*
		FROM   XMLTABLE('/CanonicalServiceDetailStatusUpdateReq/ServiceDetail'
				 PASSING (P_XMLData_in)
				 COLUMNS
				   "UNIQUE_ID" PATH 'UNIQUE_ID',
					"MPF" PATH 'MPF',
					"ACCOUNT_NUMBER" PATH 'ACCOUNT_NUMBER',
					"PRODUCT_FAMILY" PATH 'PRODUCT_FAMILY',
					"STATUS" PATH 'STATUS',
					"MESSAGE" PATH 'MESSAGE'
				 ) xt)
	LOOP
	v_UNIQUE_ID:=cur_SERVICE_DETAILS_STATUS.UNIQUE_ID;
	v_MPF:=cur_SERVICE_DETAILS_STATUS.MPF;
	v_ACCOUNT_NUMBER:=cur_SERVICE_DETAILS_STATUS.ACCOUNT_NUMBER;
	v_PRODUCT_FAMILY:=cur_SERVICE_DETAILS_STATUS.PRODUCT_FAMILY;
	v_STATUS:=cur_SERVICE_DETAILS_STATUS.STATUS;
	v_MESSAGE:=cur_SERVICE_DETAILS_STATUS.MESSAGE;

	UPDATE PRODDTA.F58INT11 SET SG$RSP=v_STATUS,SG$VALMSG=v_MESSAGE where SGUKID=v_UNIQUE_ID and SGC75DCT='Service Detail' and  SG$MPFNUM = v_MPF and
	SGPNID = v_ACCOUNT_NUMBER and SG$SERMCU = v_PRODUCT_FAMILY AND SG$RSP <> 'S';

  END LOOP;


	EXCEPTION
	 WHEN OTHERS THEN
		ROLLBACK;
		Temp_RetMsg :='MessageID '|| Temp_MessageID||' An error was encountered - '||SQLCODE||' -ERROR- '||substr(SQLERRM,1,2000);
   END;

   P_RetMsg_out :=	Temp_RetMsg;
 END USP_AMS_SERVICE_DETAILS_STATUS_UPDATE;

 PROCEDURE USP_AMS_REPROCESS_SERVICE_DETAILS_SELECT(
	ACCOUNT_NUMBER    IN VARCHAR2
  ,PRODUCT_FAMILY  IN VARCHAR2
  ,MPF  IN VARCHAR2
  ,START_DATE IN VARCHAR2
  ,REPROCESS_ERRORS IN VARCHAR2
  ,OUT_CLOBData OUT NOCOPY CLOB
  ,OUT_RetMsg OUT VARCHAR2 ) IS

   --Declarations
      Temp_RetMsg VARCHAR2(30000):='';
      v_TransmissionID VARCHAR(20);
	  v_ISALLOWEDFLAG CHAR(1);
      v_TPDS40 CHAR(40);
      v_Total_Count NUMBER:=0;
	  v_Select_Count NUMBER:=0;
	  v_F58INT12_NLIN_Count NUMBER:=0;
	  v_F58INT13_NLIN_Count NUMBER:=0;
	  v_F58INT15_NLIN_Count NUMBER:=0;
	  V_ADDL_RECORDS_AVL CHAR(1):='N';
		v_F58INT00_Count NUMBER;
		v_RepDays NUMBER;
		v_NumberOfDays NUMBER;
		v_SQL_Date DATE;

      l_domdoc dbms_xmldom.DOMDocument;
      l_xmltype XMLTYPE;

      l_root_textnode dbms_xmldom.DOMNode;

      l_SERVICE_DETAILS_INFO_textnode dbms_xmldom.DOMNode;

      l_F58INT11_textnode dbms_xmldom.DOMNode;
      l_F58INT12_textnode dbms_xmldom.DOMNode;
      l_F58INT12_Rcd_textnode dbms_xmldom.DOMNode;
      l_F58INT13_textnode dbms_xmldom.DOMNode;
      l_F58INT13_Rcd_textnode dbms_xmldom.DOMNode;
      l_F58INT15_textnode dbms_xmldom.DOMNode;
      l_F58INT15_Rcd_textnode dbms_xmldom.DOMNode;
      l_F58INT00_textnode dbms_xmldom.DOMNode;
      l_F58INT00_Rcd_textnode dbms_xmldom.DOMNode;
      l_XXPLXS_TDM_VIEW_REPORT_textnode dbms_xmldom.DOMNode;
      l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode dbms_xmldom.DOMNode;

	  ADDL_RECORDS_AVL_node dbms_xmldom.DOMNode;
	  DOCUMENT_TYPE_node dbms_xmldom.DOMNode;
		MODULE_node dbms_xmldom.DOMNode;
		VERSION_node dbms_xmldom.DOMNode;
		TEST_FLAG_node dbms_xmldom.DOMNode;
		TRANSMISSION_DATE_node dbms_xmldom.DOMNode;
		TRANSMISSION_ID_node dbms_xmldom.DOMNode;
		CUSTOMER_node dbms_xmldom.DOMNode;
		MPF_node dbms_xmldom.DOMNode;
		COMPANY_node dbms_xmldom.DOMNode;
		UNIQUE_ID_node dbms_xmldom.DOMNode;
		SERVICE_BRANCH_PLANT_node dbms_xmldom.DOMNode;
		PLXS_CASE_NUMBER_node dbms_xmldom.DOMNode;
		WORK_ORDER_NUMBER_node dbms_xmldom.DOMNode;
		TRX_TYPE_node dbms_xmldom.DOMNode;
		TRX_DATE_node dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE1_node dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE2_node dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE3_node dbms_xmldom.DOMNode;
		PLXS_ITEM_NUMBER_node dbms_xmldom.DOMNode;
		ITEM_DESC_node dbms_xmldom.DOMNode;
		CUSTOMER_ITEM_NUMBER_node dbms_xmldom.DOMNode;
		CUSTOMER_REV_node dbms_xmldom.DOMNode;
		SECONDARY_CUSTOMER_ITEM_NUMBER_node dbms_xmldom.DOMNode;
		PLXS_OUT_ITEM_NUMBER_node dbms_xmldom.DOMNode;
		CUSTOMER_OUT_ITEM_NUMBER_node dbms_xmldom.DOMNode;
		LOT_SERIAL_NUMBER_node dbms_xmldom.DOMNode;
		QTY_node dbms_xmldom.DOMNode;
		OPERATION_SEQ_node dbms_xmldom.DOMNode;
		OPERATION_CODE_node dbms_xmldom.DOMNode;
		OPERATION_DESC_node dbms_xmldom.DOMNode;
		OPERATION_RESULT_node dbms_xmldom.DOMNode;
        OPERATION_COMMENT_node dbms_xmldom.DOMNode;
		OPERATION_COMPLETION_DATE_node dbms_xmldom.DOMNode;
		COMPLETED_BY_node dbms_xmldom.DOMNode;
		AREA_TYPE_node dbms_xmldom.DOMNode;
		AREA_DESC_node dbms_xmldom.DOMNode;
		OPERATION_SEQ_13_node dbms_xmldom.DOMNode;
		PART_NUMBER_node dbms_xmldom.DOMNode;
		LOT_SERIAL_NUMBER_13_node dbms_xmldom.DOMNode;
		REQUESTED_QUANTITY_node dbms_xmldom.DOMNode;
		ISSUED_QUANTITY_node dbms_xmldom.DOMNode;
        PLXS_DEFECT_CODE_node dbms_xmldom.DOMNode;
		PLXS_DEFECT_DESC_node dbms_xmldom.DOMNode;
		DEFECT_COMMENT_node dbms_xmldom.DOMNode;
        FORM_NAME_node dbms_xmldom.DOMNode;
        DISPLAY_SEQUENCE_node dbms_xmldom.DOMNode;
        ATTRIBUTE_LABEL_node dbms_xmldom.DOMNode;
        RESPONSE_node dbms_xmldom.DOMNode;
        IS_ALLOWED_FLAG_node dbms_xmldom.DOMNode;
        FILE_TYPE_node dbms_xmldom.DOMNode;

		ADDL_RECORDS_AVL_textnode dbms_xmldom.DOMNode;
		DOCUMENT_TYPE_textnode dbms_xmldom.DOMNode;
		MODULE_textnode dbms_xmldom.DOMNode;
		VERSION_textnode dbms_xmldom.DOMNode;
		TEST_FLAG_textnode dbms_xmldom.DOMNode;
		TRANSMISSION_DATE_textnode dbms_xmldom.DOMNode;
		TRANSMISSION_ID_textnode dbms_xmldom.DOMNode;
		CUSTOMER_textnode dbms_xmldom.DOMNode;
		MPF_textnode dbms_xmldom.DOMNode;
		COMPANY_textnode dbms_xmldom.DOMNode;
		UNIQUE_ID_textnode dbms_xmldom.DOMNode;
		SERVICE_BRANCH_PLANT_textnode dbms_xmldom.DOMNode;
		PLXS_CASE_NUMBER_textnode dbms_xmldom.DOMNode;
		WORK_ORDER_NUMBER_textnode dbms_xmldom.DOMNode;
		TRX_TYPE_textnode dbms_xmldom.DOMNode;
		TRX_DATE_textnode dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE1_textnode dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE2_textnode dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE3_textnode dbms_xmldom.DOMNode;
		PLXS_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;
		ITEM_DESC_textnode dbms_xmldom.DOMNode;
		CUSTOMER_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;
		CUSTOMER_REV_textnode dbms_xmldom.DOMNode;
		SECONDARY_CUSTOMER_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;
		PLXS_OUT_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;
		CUSTOMER_OUT_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;
		LOT_SERIAL_NUMBER_textnode dbms_xmldom.DOMNode;
		QTY_textnode dbms_xmldom.DOMNode;
		OPERATION_SEQ_textnode dbms_xmldom.DOMNode;
		OPERATION_CODE_textnode dbms_xmldom.DOMNode;
		OPERATION_DESC_textnode dbms_xmldom.DOMNode;
		OPERATION_RESULT_textnode dbms_xmldom.DOMNode;
        OPERATION_COMMENT_textnode dbms_xmldom.DOMNode;
		OPERATION_COMPLETION_DATE_textnode dbms_xmldom.DOMNode;
		COMPLETED_BY_textnode dbms_xmldom.DOMNode;
		AREA_TYPE_textnode dbms_xmldom.DOMNode;
		AREA_DESC_textnode dbms_xmldom.DOMNode;
		OPERATION_SEQ_13_textnode dbms_xmldom.DOMNode;
		PART_NUMBER_textnode dbms_xmldom.DOMNode;
		LOT_SERIAL_NUMBER_13_textnode dbms_xmldom.DOMNode;
		REQUESTED_QUANTITY_textnode dbms_xmldom.DOMNode;
		ISSUED_QUANTITY_textnode dbms_xmldom.DOMNode;
        PLXS_DEFECT_CODE_textnode dbms_xmldom.DOMNode;
		PLXS_DEFECT_DESC_textnode dbms_xmldom.DOMNode;
		DEFECT_COMMENT_textnode dbms_xmldom.DOMNode;
        FORM_NAME_textnode dbms_xmldom.DOMNode;
        DISPLAY_SEQUENCE_textnode dbms_xmldom.DOMNode;
        ATTRIBUTE_LABEL_textnode dbms_xmldom.DOMNode;
        RESPONSE_textnode dbms_xmldom.DOMNode;

        IS_ALLOWED_FLAG_textnode dbms_xmldom.DOMNode;
        FILE_TYPE_textnode dbms_xmldom.DOMNode;

    TEMP_C75DCT CHAR(60);
	TEMP_LRSSM CHAR(10);
	TEMP_B76VER CHAR(10);
	TEMP_$TSTFLAG CHAR(1);
	TEMP_CREATEDT VARCHAR(30):= TO_CHAR(SYS_EXTRACT_UTC(SYSTIMESTAMP),'YYYY-MM-DD"T"HH24:MI:SS.ff3"Z"');
	TEMP_TRANSDate VARCHAR(30);
	TEMP_$TRANSID CHAR(150);
	TEMP_ALPH CHAR(40);
	TEMP_$MPFNUM CHAR(25);
	TEMP_UKID NUMBER;
	TEMP_$SERMCU CHAR(15);
	TEMP_DOCO NUMBER;
	TEMP_WOD NUMBER;
	TEMP_TRNDES CHAR(30);
	TEMP_$GS04 NUMBER;
	TEMP_RF1 CHAR(30);
	TEMP_RF2 CHAR(30);
	TEMP_RF3 CHAR(30);
	TEMP_LITM CHAR(25);
	TEMP_DSC1 CHAR(30);
	TEMP_$CUSPRTN CHAR(30);
	TEMP_DL03 CHAR(30);
	TEMP_KITL CHAR(25);
	TEMP_CITM CHAR(25);
	TEMP_LOTN CHAR(30);
	TEMP_TRQT NUMBER;
	TEMP_OPSQ NUMBER;
	TEMP_$58OC CHAR(8);
	TEMP_DSC1_15  CHAR(30);
	TEMP_DL01 CHAR(30);
	TEMP_UPMJ NUMBER;
    Temp_OprCmt VARCHAR2(512);
	Temp_OprDate VARCHAR(30);
	TEMP_UPMT NUMBER;
	TEMP_ALPH_15 CHAR(40);
	TEMP_$NOTETYP CHAR(100);
	TEMP_GPTX VARCHAR2(1500);
	TEMP_OPSQ_13 NUMBER;
	TEMP_CPIL CHAR(25);
	TEMP_LOTN_13 CHAR(30);
	TEMP_UORG NUMBER;
	TEMP_TRQT_13 NUMBER;
	TEMP_DL01_13 CHAR(30);
    TEMP_DC01 CHAR(5);
	TEMP_VCOMMENT CHAR(60);
	v_F58INT00_Select_Count NUMBER;
	v_CountF00022 NUMBER;
    TEMP_FORM_NAME VARCHAR(250);
    TEMP_DISPLAY_SEQUENCE NUMBER;
    TEMP_ATTRIBUTE_LABEL VARCHAR(300);
    TEMP_RESPONSE VARCHAR(2000);

BEGIN
  --Creates an exmpty XML Document
      l_domdoc := dbms_xmldom.newDOMDocument;

      --Creates a root node
      l_root_textnode := dbms_xmldom.makeNode(l_domdoc);
DBMS_OUTPUT.PUT_LINE('Start');
BEGIN
BEGIN
	  SELECT count(1) INTO v_F58INT00_Select_Count FROM PRODDTA.F58INT00 WHERE TPPNID=CAST(ACCOUNT_NUMBER as CHAR(15)) AND TP$SERMCU=CAST(PRODUCT_FAMILY as CHAR(15)) AND TP$MPFNUM=CAST(MPF as CHAR(25));
DBMS_OUTPUT.PUT_LINE('v_F58INT00_Select_Count '||v_F58INT00_Select_Count);

	  IF v_F58INT00_Select_Count>0 THEN
		BEGIN
			SELECT TPEV08, TP$COUNT08,TP$COUNT07, TPDS40 INTO v_ISALLOWEDFLAG, v_F58INT00_Count,v_RepDays, v_TPDS40 FROM PRODDTA.F58INT00 WHERE TPPNID=CAST(ACCOUNT_NUMBER as CHAR(15)) AND TP$SERMCU=CAST(PRODUCT_FAMILY as CHAR(15)) AND TP$MPFNUM=CAST(MPF as CHAR(25));
		END;
		ELSE
		BEGIN
			v_ISALLOWEDFLAG:='N';

		END;
		END IF;


DBMS_OUTPUT.PUT_LINE('v_ISALLOWEDFLAG '||v_ISALLOWEDFLAG||' | v_F58INT00_Count '|| v_F58INT00_Count);

	IF (v_ISALLOWEDFLAG='Y') THEN
	BEGIN

	--SELECT to_date(TRUNC(SYSDATE), 'dd-mm-yyyy')- to_date(trunc(cast( TO_UTC_TIMESTAMP_TZ(START_DATE) as date)), 'dd-mm-yyyy') INTO v_NumberOfDays FROM DUAL;
    SELECT to_date(TRUNC(SYSDATE), 'dd-mm-yyyy')- TO_DATE(PKG_AMS_OUTBOUND.UFN_ISODATE_TO_DATE(START_DATE), 'dd-mm-yyyy') INTO v_NumberOfDays FROM DUAL;
	DBMS_OUTPUT.PUT_LINE('v_NumberOfDays '||v_NumberOfDays);
	--	v_NumberOfDays := TRUNC(SYSDATE)- to_date(trunc(cast( TO_UTC_TIMESTAMP_TZ(START_DATE) as date)), 'yyyy-mm-dd');

		IF v_NumberOfDays > v_RepDays THEN
		BEGIN
			--SELECT TO_DATE(TRUNC(SYSDATE) - v_RepDays) INTO v_SQL_Date FROM DUAL;
			v_SQL_Date := TO_DATE(TRUNC(SYSDATE) - v_RepDays);
		END;
		ELSE
		BEGIN
			--SELECT TO_DATE(TRUNC(SYSDATE) ) INTO v_SQL_Date FROM DUAL;
			v_SQL_Date := TO_DATE(TRUNC(SYSDATE) - v_NumberOfDays);
		END;
		END IF;
	DBMS_OUTPUT.PUT_LINE('v_SQL_Date '||v_SQL_Date);

		IF (REPROCESS_ERRORS='S') THEN
		BEGIN
            SELECT COUNT(1) INTO v_Total_Count FROM PRODDTA.F58INT11
            WHERE SGPNID=CAST(ACCOUNT_NUMBER as CHAR(15)) AND SG$SERMCU=CAST(PRODUCT_FAMILY as CHAR(15)) AND SG$MPFNUM=CAST(MPF as CHAR(25))
            AND SGC75DCT='Service Detail' and SGLRSSM='SDM'
            AND SG$RSP = CAST(REPROCESS_ERRORS as CHAR(1)) AND SGTND != To_Number(To_Char(To_Number(To_Char(sysdate, 'yyyy')) - 1900) || To_Char(sysdate, 'ddd'))
            AND PKG_AMS_OUTBOUND.UFN_ISODATE_TO_DATE(SGCREATEDT) >= v_SQL_Date;
            --AND cast( trunc(TO_UTC_TIMESTAMP_TZ(SGCREATEDT)) as date) >= v_SQL_Date;
			--AND cast(TO_UTC_TIMESTAMP_TZ(TRUNC(NULLIF(SGCREATEDT,0))) as date) >= cast(v_SQL_Date as date);
		END;
		ELSE
		BEGIN
			SELECT COUNT(1) INTO v_Total_Count FROM PRODDTA.F58INT11
            WHERE SGPNID=CAST(ACCOUNT_NUMBER as CHAR(15)) AND SG$SERMCU=CAST(PRODUCT_FAMILY as CHAR(15)) AND SG$MPFNUM=CAST(MPF as CHAR(25))
            AND SGC75DCT='Service Detail' and SGLRSSM='SDM'
            AND SG$RSP = CAST(REPROCESS_ERRORS as CHAR(1)) AND  SGTND != To_Number(To_Char(To_Number(To_Char(sysdate, 'yyyy')) - 1900) || To_Char(sysdate, 'ddd'));
		END;
		END IF;

DBMS_OUTPUT.PUT_LINE('v_Total_Count '||v_Total_Count);

		SELECT count(1) INTO v_CountF00022  FROM PRODDTA.F00022 WHERE ukobnm = 'TRNSDM';
			IF (v_CountF00022>0) THEN
			BEGIN
				v_TransmissionID:= BIZTALK.PKG_AMS_OUTBOUND.GET_TRANSMISSIONID_FROM_F00022('TRNSDM');
			END;
			ELSE
			BEGIN
				DBMS_OUTPUT.put_line('Insert PRODDTA.F00022');
				INSERT INTO PRODDTA.F00022
				(UKOBNM,UKUKID)
				VALUES
				('TRNSDM',1);

				v_TransmissionID:= 'SDPL' || LPAD(1,15,'0');
			END;
			END IF;

DBMS_OUTPUT.PUT_LINE('v_TransmissionID '||v_TransmissionID);

		IF (v_Total_Count > v_F58INT00_Count) THEN
		BEGIN
			V_ADDL_RECORDS_AVL:='Y';
            v_Select_Count:=v_F58INT00_Count;
		END;
        ELSE
		BEGIN
			v_Select_Count:=v_Total_Count;
		END;
		END IF;

DBMS_OUTPUT.PUT_LINE('V_ADDL_RECORDS_AVL '||V_ADDL_RECORDS_AVL||' | v_Select_Count '||v_Select_Count||' | v_Total_Count '||v_Total_Count);

		IF (REPROCESS_ERRORS='S') THEN
		BEGIN
			 FOR AMS_F58INT11_REC_UPDATE_S in
			  (
			  SELECT SGC75DCT
				,SGUKID
			  FROM PRODDTA.F58INT11
			  WHERE --sglrssm='SDM' and sgukid in (138, 139, 141, 142, 153, 154, 155)
			  SGPNID=CAST(ACCOUNT_NUMBER as CHAR(15)) AND SG$SERMCU=CAST(PRODUCT_FAMILY as CHAR(15)) AND SG$MPFNUM=CAST(MPF as CHAR(25))
              AND SGC75DCT='Service Detail' and SGLRSSM='SDM'
              AND SG$RSP = CAST(REPROCESS_ERRORS as CHAR(1)) AND SGTND != To_Number(To_Char(To_Number(To_Char(sysdate, 'yyyy')) - 1900) || To_Char(sysdate, 'ddd'))
			  AND PKG_AMS_OUTBOUND.UFN_ISODATE_TO_DATE(SGCREATEDT) >= v_SQL_Date
              --AND cast( trunc(TO_UTC_TIMESTAMP_TZ(SGCREATEDT)) as date) >= v_SQL_Date
			  --AND cast(TO_UTC_TIMESTAMP_TZ(TRUNC(NULLIF(SGCREATEDT,0))) as date) >= cast(v_SQL_Date as date)
			  ORDER BY SGC75DCT, SGUKID
              FETCH FIRST v_Select_Count ROWS ONLY
			  )

			  LOOP
					  DBMS_OUTPUT.PUT_LINE(AMS_F58INT11_REC_UPDATE_S.SGC75DCT||'~~'||AMS_F58INT11_REC_UPDATE_S.SGUKID);
					UPDATE PRODDTA.F58INT11 A SET SGREPSTS='B',SG$RTRNSID=v_TransmissionID  WHERE SGC75DCT=AMS_F58INT11_REC_UPDATE_S.SGC75DCT AND SGUKID=AMS_F58INT11_REC_UPDATE_S.SGUKID;

					COMMIT;
			 END LOOP;
		END;
		ELSE
		BEGIN
			 FOR AMS_F58INT11_REC_UPDATE in
			  (
			  SELECT SGC75DCT
				,SGUKID
			  FROM PRODDTA.F58INT11
			  WHERE --sglrssm='SDM' and sgukid in (138, 139, 141, 142, 153, 154, 155)
			  SGPNID=CAST(ACCOUNT_NUMBER as CHAR(15)) AND SG$SERMCU=CAST(PRODUCT_FAMILY as CHAR(15)) AND SG$MPFNUM=CAST(MPF as CHAR(25))
              AND SGC75DCT='Service Detail' and SGLRSSM='SDM'
              AND SG$RSP = CAST(REPROCESS_ERRORS as CHAR(1)) AND SGTND != To_Number(To_Char(To_Number(To_Char(sysdate, 'yyyy')) - 1900) || To_Char(sysdate, 'ddd'))
			  ORDER BY SGC75DCT, SGUKID
              FETCH FIRST v_Select_Count ROWS ONLY
			  )

			  LOOP
					  DBMS_OUTPUT.PUT_LINE(AMS_F58INT11_REC_UPDATE.SGC75DCT||'~~'||AMS_F58INT11_REC_UPDATE.SGUKID);
					UPDATE PRODDTA.F58INT11 A SET SGREPSTS='B',SG$RTRNSID=v_TransmissionID  WHERE SGC75DCT=AMS_F58INT11_REC_UPDATE.SGC75DCT AND SGUKID=AMS_F58INT11_REC_UPDATE.SGUKID;

					COMMIT;
			 END LOOP;
		END;
		END IF;


		DBMS_OUTPUT.PUT_LINE('First update completed');

             --Create the XML structure for the Header/Non repeating sections
      l_SERVICE_DETAILS_INFO_textnode := dbms_xmldom.appendChild(l_root_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'AMS_SERVICE_DETAILS_INFO')));

      --Create Header or Non-Repeating XML nodes based on one record of the
      --TransmissionID/Customer Number
      FOR AMS_F58INT11_REC in
          (
		  SELECT SGC75DCT
			,SGLRSSM
			,SGB76VER
			,SG$TSTFLAG
			,SGCREATEDT
			,SG$RTRNSID
			,SGALPH
			,SG$MPFNUM
			,SGUKID
			,SG$SERMCU
			,SGDOCO
			,SGWOD
			,SGTRNDES
			,SG$GS04
			,DECODE(SG$GS04,0,'0',TO_CHAR(TO_DATE(TO_CHAR(SG$GS04 + 1900000),'YYYYDDD'),'yyyy-mm-dd'))||'T'|| decode(0,0,'00:00:00',to_char(to_date(LPAD(TO_CHAR(0),6,'0') , 'hh24miss'),'hh24:mi:ss'))||'Z' TRANSDate
			,SGRF1
			,SGRF2
			,SGRF3
			,SGLITM
			,SGDSC1
			,SG$CUSPRTN
			,SGDL03
			,SGKITL
			,SGCITM
			,SGLOTN
			,SGTRQT
		  FROM PRODDTA.F58INT11
		  WHERE SGPNID=CAST(ACCOUNT_NUMBER as CHAR(15)) AND SG$SERMCU=CAST(PRODUCT_FAMILY as CHAR(15)) AND SG$MPFNUM=CAST(MPF as CHAR(25))
          AND SGC75DCT='Service Detail' and SGLRSSM='SDM'
          AND SG$RTRNSID=CAST(v_TransmissionID as CHAR(150))
		  ORDER BY SGC75DCT, SGUKID
		  )

          LOOP

		DBMS_OUTPUT.PUT_LINE('F58INT11 select completed');
            TEMP_C75DCT := AMS_F58INT11_REC.SGC75DCT;
			TEMP_LRSSM := AMS_F58INT11_REC.SGLRSSM;
			TEMP_B76VER := AMS_F58INT11_REC.SGB76VER;
			TEMP_$TSTFLAG := AMS_F58INT11_REC.SG$TSTFLAG;
			TEMP_TRANSDate := AMS_F58INT11_REC.TRANSDate;
			DBMS_OUTPUT.PUT_LINE('F58INT11 - 1');
			TEMP_$TRANSID := AMS_F58INT11_REC.SG$RTRNSID;
			TEMP_ALPH := AMS_F58INT11_REC.SGALPH;
			TEMP_$MPFNUM := AMS_F58INT11_REC.SG$MPFNUM;
			TEMP_UKID := AMS_F58INT11_REC.SGUKID;
			TEMP_$SERMCU := AMS_F58INT11_REC.SG$SERMCU;
			DBMS_OUTPUT.PUT_LINE('F58INT11 - 2');
			TEMP_DOCO := AMS_F58INT11_REC.SGDOCO;
			TEMP_WOD := AMS_F58INT11_REC.SGWOD;
			TEMP_TRNDES := AMS_F58INT11_REC.SGTRNDES;
			TEMP_$GS04 := AMS_F58INT11_REC.SG$GS04;
			TEMP_RF1 := AMS_F58INT11_REC.SGRF1;
			DBMS_OUTPUT.PUT_LINE('F58INT11 - 3');
			TEMP_RF2 := AMS_F58INT11_REC.SGRF2;
			TEMP_RF3 := AMS_F58INT11_REC.SGRF3;
			TEMP_LITM := AMS_F58INT11_REC.SGLITM;
			TEMP_DSC1 := AMS_F58INT11_REC.SGDSC1;
			TEMP_$CUSPRTN := AMS_F58INT11_REC.SG$CUSPRTN;
			TEMP_DL03 := AMS_F58INT11_REC.SGDL03;
			DBMS_OUTPUT.PUT_LINE('F58INT11 - 4');
			TEMP_KITL := AMS_F58INT11_REC.SGKITL;
			TEMP_CITM := AMS_F58INT11_REC.SGCITM;
			TEMP_LOTN := AMS_F58INT11_REC.SGLOTN;
			TEMP_TRQT := AMS_F58INT11_REC.SGTRQT;
DBMS_OUTPUT.PUT_LINE('F58INT11 select variable assign completed');

			l_F58INT11_textnode:= dbms_xmldom.appendChild(l_SERVICE_DETAILS_INFO_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'F58INT11')));

           DOCUMENT_TYPE_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DOCUMENT_TYPE')));
			DOCUMENT_TYPE_textnode	:= dbms_xmldom.appendChild(	DOCUMENT_TYPE_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_C75DCT)) )));

			MODULE_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'MODULE')));
			MODULE_textnode	:= dbms_xmldom.appendChild(	MODULE_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_LRSSM)) )));

			VERSION_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'VERSION')));
			VERSION_textnode	:= dbms_xmldom.appendChild(	VERSION_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_B76VER))  )));

			TEST_FLAG_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TEST_FLAG')));
			TEST_FLAG_textnode	:= dbms_xmldom.appendChild(	TEST_FLAG_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$TSTFLAG)) )));

DBMS_OUTPUT.PUT_LINE('F58INT11 select xml assign test flag completed');

			TRANSMISSION_DATE_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRANSMISSION_DATE')));
			TRANSMISSION_DATE_textnode	:= dbms_xmldom.appendChild(	TRANSMISSION_DATE_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_CREATEDT )));

			TRANSMISSION_ID_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRANSMISSION_ID')));
			TRANSMISSION_ID_textnode	:= dbms_xmldom.appendChild(	TRANSMISSION_ID_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$TRANSID )))));

			CUSTOMER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER')));
			CUSTOMER_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_ALPH)) )));

			MPF_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'MPF')));
			MPF_textnode	:= dbms_xmldom.appendChild(	MPF_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$MPFNUM)) )));


DBMS_OUTPUT.PUT_LINE('F58INT11 select xml assign MPF flag completed');

			UNIQUE_ID_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'UNIQUE_ID')));
			UNIQUE_ID_textnode	:= dbms_xmldom.appendChild(	UNIQUE_ID_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_UKID )))));

			SERVICE_BRANCH_PLANT_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'SERVICE_BRANCH_PLANT')));
			SERVICE_BRANCH_PLANT_textnode	:= dbms_xmldom.appendChild(	SERVICE_BRANCH_PLANT_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$SERMCU)) )));

			PLXS_CASE_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_CASE_NUMBER')));
			PLXS_CASE_NUMBER_textnode	:= dbms_xmldom.appendChild(	PLXS_CASE_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_DOCO))  )));

			WORK_ORDER_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'WORK_ORDER_NUMBER')));
			WORK_ORDER_NUMBER_textnode	:= dbms_xmldom.appendChild(	WORK_ORDER_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_WOD))  )));

			TRX_TYPE_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRX_TYPE')));
			TRX_TYPE_textnode	:= dbms_xmldom.appendChild(	TRX_TYPE_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_TRNDES)) )));

			TRX_DATE_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRX_DATE')));
			TRX_DATE_textnode	:= dbms_xmldom.appendChild(	TRX_DATE_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_TRANSDate)) )));

			CUSTOMER_REFERENCE1_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE1')));
			CUSTOMER_REFERENCE1_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_REFERENCE1_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,  ltrim(rtrim(TEMP_RF1)))));

DBMS_OUTPUT.PUT_LINE('F58INT11 select xml assign CUSTOMER_REFERENCE1_node flag completed');
			CUSTOMER_REFERENCE2_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE2')));
			CUSTOMER_REFERENCE2_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_REFERENCE2_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_RF2)) )));

			CUSTOMER_REFERENCE3_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE3')));
			CUSTOMER_REFERENCE3_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_REFERENCE3_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_RF3))  )));

			PLXS_ITEM_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_ITEM_NUMBER')));
			PLXS_ITEM_NUMBER_textnode	:= dbms_xmldom.appendChild(	PLXS_ITEM_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_LITM)) )));

			ITEM_DESC_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ITEM_DESC')));
			ITEM_DESC_textnode	:= dbms_xmldom.appendChild(	ITEM_DESC_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_DSC1))  )));

			CUSTOMER_ITEM_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_ITEM_NUMBER')));
			CUSTOMER_ITEM_NUMBER_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_ITEM_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$CUSPRTN)) )));

			CUSTOMER_REV_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REV')));
			CUSTOMER_REV_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_REV_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DL03)) )));

			PLXS_OUT_ITEM_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_OUT_ITEM_NUMBER')));
			PLXS_OUT_ITEM_NUMBER_textnode	:= dbms_xmldom.appendChild(	PLXS_OUT_ITEM_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_KITL)) )));

			CUSTOMER_OUT_ITEM_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_OUT_ITEM_NUMBER')));
			CUSTOMER_OUT_ITEM_NUMBER_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_OUT_ITEM_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_CITM))  )));

			LOT_SERIAL_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'LOT_SERIAL_NUMBER')));
			LOT_SERIAL_NUMBER_textnode	:= dbms_xmldom.appendChild(	LOT_SERIAL_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_LOTN)) )));

			QTY_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'QTY')));
			QTY_textnode	:= dbms_xmldom.appendChild(	QTY_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_TRQT)) )));

			ADDL_RECORDS_AVL_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ADDL_RECORDS_AVL')));
			ADDL_RECORDS_AVL_textnode	:= dbms_xmldom.appendChild(	ADDL_RECORDS_AVL_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(V_ADDL_RECORDS_AVL)) )));



DBMS_OUTPUT.PUT_LINE('F58INT11 select xml assign QTY_textnode flag completed');
			l_F58INT15_textnode := dbms_xmldom.appendChild(l_F58INT11_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'F58INT15')));

			FOR AMS_F58INT15_REC IN
               (
			   SELECT SDOPSQ
					,SD$58OC
					,SDDSC1
					,SDDL01
					,DECODE(SDMUPM,0,'0',TO_CHAR(TO_DATE(TO_CHAR(SDMUPM + 1900000),'YYYYDDD'),'yyyy-mm-dd'))||'T'|| decode(SDUPMT,0,'00:00:00',to_char(to_date(LPAD(TO_CHAR(SDUPMT),6,'0') , 'hh24miss'),'hh24:mi:ss'))||'Z' as OprDate
					,SDCMMNT
                    ,SDUPMJ
					,SDUPMT
					,SDALPH
			   FROM PRODDTA.F58INT15
			   WHERE SDC75DCT=TEMP_C75DCT AND SDUKID=TEMP_UKID
			   ORDER BY SDC75DCT, SDUKID, SDNLIN
			   )

                LOOP
DBMS_OUTPUT.PUT_LINE('F58INT15 select completed');
                TEMP_OPSQ := AMS_F58INT15_REC.SDOPSQ;
                TEMP_$58OC := AMS_F58INT15_REC.SD$58OC;
                TEMP_DSC1_15 := AMS_F58INT15_REC.SDDSC1;
                TEMP_DL01 := AMS_F58INT15_REC.SDDL01;
                TEMP_UPMJ := AMS_F58INT15_REC.SDUPMJ;
                TEMP_UPMT := AMS_F58INT15_REC.SDUPMT;
                Temp_OprCmt:=	AMS_F58INT15_REC.SDCMMNT;
				Temp_OprDate:=	AMS_F58INT15_REC.OprDate;
                TEMP_ALPH_15 := AMS_F58INT15_REC.SDALPH;

					l_F58INT15_Rcd_textnode:= dbms_xmldom.appendChild(l_F58INT15_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'Record')));

				 OPERATION_SEQ_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_SEQ' )));
                  OPERATION_SEQ_textnode := dbms_xmldom.appendChild( OPERATION_SEQ_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_OPSQ/100)) )));

                  OPERATION_CODE_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_CODE' )));
                  OPERATION_CODE_textnode := dbms_xmldom.appendChild( OPERATION_CODE_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$58OC)))));

				OPERATION_DESC_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_DESC' )));
                  OPERATION_DESC_textnode := dbms_xmldom.appendChild( OPERATION_DESC_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DSC1_15)) )));

                  OPERATION_RESULT_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_RESULT' )));
                  OPERATION_RESULT_textnode := dbms_xmldom.appendChild( OPERATION_RESULT_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DL01)))));

                  OPERATION_COMMENT_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_COMMENT' )));
                  OPERATION_COMMENT_textnode := dbms_xmldom.appendChild( OPERATION_COMMENT_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(Temp_OprCmt)))));

				OPERATION_COMPLETION_DATE_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_COMPLETION_DATE' )));
                  OPERATION_COMPLETION_DATE_textnode := dbms_xmldom.appendChild( OPERATION_COMPLETION_DATE_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, Temp_OprDate )));

                  COMPLETED_BY_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'COMPLETED_BY' )));
                  COMPLETED_BY_textnode := dbms_xmldom.appendChild( COMPLETED_BY_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_ALPH_15)))));


                l_XXPLXS_TDM_VIEW_REPORT_textnode := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'XXPLXS_TDM_VIEW_REPORT')));
                DBMS_OUTPUT.PUT_LINE('XXPLXS_TDM_VIEW_REPORT_REC - Started | ' || to_char(TEMP_WOD) || ' | ' || TO_CHAR(TEMP_OPSQ/100) || ' | ' || to_char(TEMP_$58OC));

                  FOR XXPLXS_TDM_VIEW_REPORT_REC IN
                  (
                    SELECT FORM_NAME,
                          DISPLAY_SEQUENCE,
                          ATTRIBUTE_LABEL,
                          RESPONSE
                    FROM Xxapps.plxs_complete_v
                    WHERE work_order_number = ltrim(rtrim(TEMP_WOD))              --SERVICE_DETAIL/WORK_ORDER_NUMBER
                        AND display_sequence    IS NOT NULL
                        AND (qa_header_id is null or (qa_header_id is not null and qa_line_id is not null))
                        AND operation_seq       = ltrim(rtrim((TEMP_OPSQ/100)))   --SERVICE_DETAIL/OPERATION_DETAIL/OPERATION_SEQ
                        AND operation_code      = ltrim(rtrim(TEMP_$58OC))        --SERVICE_DETAIL/OPERATION_DETAIL/OPERATION_CODE
                        AND attribute_type      !='LABEL'
						AND REPORTING_FLAG      ='Y'
                    ORDER BY OPERATION_SEQ,FORM_SEQUENCE,DISPLAY_SEQUENCE
                   )
                   LOOP
                        TEMP_FORM_NAME := XXPLXS_TDM_VIEW_REPORT_REC.FORM_NAME;
                        TEMP_DISPLAY_SEQUENCE := XXPLXS_TDM_VIEW_REPORT_REC.DISPLAY_SEQUENCE;
                        TEMP_ATTRIBUTE_LABEL := XXPLXS_TDM_VIEW_REPORT_REC.ATTRIBUTE_LABEL;
                        TEMP_RESPONSE := XXPLXS_TDM_VIEW_REPORT_REC.RESPONSE;
                        DBMS_OUTPUT.PUT_LINE('XXPLXS_TDM_VIEW_REPORT_REC - Loop started ' || XXPLXS_TDM_VIEW_REPORT_REC.FORM_NAME);
                        l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode:= dbms_xmldom.appendChild(l_XXPLXS_TDM_VIEW_REPORT_textnode
                                                        ,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'XXPLXS_TDM_VIEW_REPORT_Record')));

                        FORM_NAME_node := dbms_xmldom.appendChild(l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'FORM_NAME' )));
                        FORM_NAME_textnode := dbms_xmldom.appendChild( FORM_NAME_node
                                                             , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_FORM_NAME)))));

                        DISPLAY_SEQUENCE_node := dbms_xmldom.appendChild(l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DISPLAY_SEQUENCE' )));
                        DISPLAY_SEQUENCE_textnode := dbms_xmldom.appendChild( DISPLAY_SEQUENCE_node
                                                             , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DISPLAY_SEQUENCE)))));

                        ATTRIBUTE_LABEL_node := dbms_xmldom.appendChild(l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ATTRIBUTE_LABEL' )));
                        ATTRIBUTE_LABEL_textnode := dbms_xmldom.appendChild( ATTRIBUTE_LABEL_node
                                                             , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_ATTRIBUTE_LABEL)))));

                        RESPONSE_node := dbms_xmldom.appendChild(l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'RESPONSE' )));
                        RESPONSE_textnode := dbms_xmldom.appendChild( RESPONSE_node
                                                             , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_RESPONSE)))));
                   END LOOP;
                                       DBMS_OUTPUT.PUT_LINE('XXPLXS_TDM_VIEW_REPORT_REC - Ended');
            END LOOP;



			l_F58INT12_textnode := dbms_xmldom.appendChild(l_F58INT11_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'F58INT12')));

			FOR AMS_F58INT12_REC IN
               (SELECT NT$NOTETYP
					,NTGPTX
                FROM PRODDTA.F58INT12
                WHERE NTUKID = TEMP_UKID
                AND   ntc75dct =  RPAD(TRIM(TEMP_C75DCT),60)
				ORDER BY NTC75DCT, NTUKID, NTNLIN)

                LOOP

DBMS_OUTPUT.PUT_LINE('F58INT12 select completed');
                TEMP_$NOTETYP := AMS_F58INT12_REC.NT$NOTETYP;
                TEMP_GPTX := AMS_F58INT12_REC.NTGPTX;

			l_F58INT12_Rcd_textnode:= dbms_xmldom.appendChild(l_F58INT12_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'Record')));
                  AREA_TYPE_node := dbms_xmldom.appendChild(l_F58INT12_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AREA_TYPE' )));
                  AREA_TYPE_textnode := dbms_xmldom.appendChild( AREA_TYPE_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$NOTETYP)) )));

                  AREA_DESC_node := dbms_xmldom.appendChild(l_F58INT12_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AREA_DESC' )));
                  AREA_DESC_textnode := dbms_xmldom.appendChild( AREA_DESC_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_GPTX)))));
            END LOOP;
			l_F58INT13_textnode := dbms_xmldom.appendChild(l_F58INT11_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'F58INT13')));
DBMS_OUTPUT.PUT_LINE('F58INT12 Frame completed');
			FOR AMS_F58INT13_REC IN
               (
			   SELECT
			   PIOPSQ
				,PICPIL
				,PILOTN
				,PIUORG
				,PITRQT
				,PIDL01
                ,PI$58DC
				,PIVCOMMENT
			   FROM PRODDTA.F58INT13 where PIC75DCT=TEMP_C75DCT AND PIUKID=TEMP_UKID
			   ORDER BY PIC75DCT, PIUKID, PINLIN
			   )

                LOOP

DBMS_OUTPUT.PUT_LINE('F58INT13 select completed');
                TEMP_OPSQ_13 := AMS_F58INT13_REC.PIOPSQ;
                TEMP_CPIL := AMS_F58INT13_REC.PICPIL;
                TEMP_LOTN_13 := AMS_F58INT13_REC.PILOTN;
                TEMP_UORG := AMS_F58INT13_REC.PIUORG;
                TEMP_TRQT_13 := AMS_F58INT13_REC.PITRQT;
                TEMP_DL01 := AMS_F58INT13_REC.PIDL01;
                TEMP_DC01 := AMS_F58INT13_REC.PI$58DC;
                TEMP_VCOMMENT := AMS_F58INT13_REC.PIVCOMMENT;

			l_F58INT13_Rcd_textnode:= dbms_xmldom.appendChild(l_F58INT13_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'Record')));
                  OPERATION_SEQ_13_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_SEQ' )));
                  OPERATION_SEQ_13_textnode := dbms_xmldom.appendChild( OPERATION_SEQ_13_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_OPSQ_13/100)) )));

                  PART_NUMBER_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PART_NUMBER' )));
                  PART_NUMBER_textnode := dbms_xmldom.appendChild( PART_NUMBER_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_CPIL)))));

					LOT_SERIAL_NUMBER_13_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'LOT_SERIAL_NUMBER' )));
                  LOT_SERIAL_NUMBER_13_textnode := dbms_xmldom.appendChild( LOT_SERIAL_NUMBER_13_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_LOTN_13)) )));

                  REQUESTED_QUANTITY_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'REQUESTED_QUANTITY' )));
                  REQUESTED_QUANTITY_textnode := dbms_xmldom.appendChild( REQUESTED_QUANTITY_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_UORG)))));

                  ISSUED_QUANTITY_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ISSUED_QUANTITY' )));
                  ISSUED_QUANTITY_textnode := dbms_xmldom.appendChild( ISSUED_QUANTITY_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_TRQT_13)))));

                  PLXS_DEFECT_CODE_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_DEFECT_CODE' )));
                  PLXS_DEFECT_CODE_textnode := dbms_xmldom.appendChild( PLXS_DEFECT_CODE_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DC01)) )));

					PLXS_DEFECT_DESC_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_DEFECT_DESC' )));
                  PLXS_DEFECT_DESC_textnode := dbms_xmldom.appendChild( PLXS_DEFECT_DESC_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DL01)) )));

                  DEFECT_COMMENT_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DEFECT_COMMENT' )));
                  DEFECT_COMMENT_textnode := dbms_xmldom.appendChild( DEFECT_COMMENT_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_VCOMMENT)))));
            END LOOP;

             --Cloud IO nodes
            l_F58INT00_textnode := dbms_xmldom.appendChild(l_F58INT11_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'F58INT00')));

            l_F58INT00_Rcd_textnode:= dbms_xmldom.appendChild(l_F58INT00_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'Record')));
                  IS_ALLOWED_FLAG_node := dbms_xmldom.appendChild(l_F58INT00_Rcd_textnode
                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'IS_ALLOWED_FLAG' )));
                  IS_ALLOWED_FLAG_textnode := dbms_xmldom.appendChild( IS_ALLOWED_FLAG_node
                                        , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(v_ISALLOWEDFLAG)) )));

                  FILE_TYPE_node := dbms_xmldom.appendChild(l_F58INT00_Rcd_textnode
                                        , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'FILE_TYPE' )));
                  FILE_TYPE_textnode := dbms_xmldom.appendChild( FILE_TYPE_node
                                        , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(v_TPDS40)) )));

			UPDATE PRODDTA.F58INT11 SET SGREPSTS='W' ,SGTND=To_Number(To_Char(To_Number(To_Char(sysdate, 'yyyy')) - 1900) || To_Char(sysdate, 'ddd')) ,SGUSER = 'BIZTALK'
                ,SGUPMT = to_char(cast(SYSDATE as date),'hh24miss')
                ,SGUPMJ = To_Number(To_Char(To_Number(To_Char(sysdate, 'yyyy')) - 1900) || To_Char(sysdate, 'ddd'))
				,SGPID= 'BIZTALK'
				,SGJOBN	= 'BIZTALK'	WHERE SGC75DCT=TEMP_C75DCT AND SGUKID=TEMP_UKID ;
			COMMIT;
          END LOOP;


	END;
	ELSE
	BEGIN
		Temp_RetMsg:='Error: Customer Not configured for PULL Transactions in JDE';
	END;
	END IF;
END;
EXCEPTION
	 WHEN OTHERS THEN

DBMS_OUTPUT.PUT_LINE('v_TransmissionID'|| v_TransmissionID);

	 UPDATE PRODDTA.F58INT11 SET SGREPSTS='E' WHERE SGPNID=CAST(ACCOUNT_NUMBER as CHAR(15)) AND SG$SERMCU=CAST(PRODUCT_FAMILY as CHAR(15)) AND SG$MPFNUM=CAST(MPF as CHAR(25)) AND SGREPSTS IN ('B','W') AND SG$RTRNSID=v_TransmissionID;
		COMMIT;
--			raise_application_error(-20001,'MessageID '|| Temp_MessageID||' An error was encountered - '||SQLCODE||' -ERROR- '||substr(SQLERRM,1,200));
		Temp_RetMsg :='Error: - '||SQLCODE||' -ERROR- '||substr(SQLERRM,1,2000);
END; --END TRANSACTION

	l_xmltype := dbms_xmldom.getXmlType(l_domdoc);
		dbms_xmldom.freeDocument(l_domdoc);

		OUT_CLOBData := l_xmltype.getClobVal;

		OUT_RetMsg :=  Temp_RetMsg;
END;

PROCEDURE GET_REPDAYS_FROM_F58INT00(ACCOUNT_NUMBER IN VARCHAR2,OUT_RepDays	OUT NUMBER) IS
     Temp_RetMsg VARCHAR2(100):='';
  BEGIN
    SELECT TP$COUNT07 INTO OUT_RepDays
    FROM PRODDTA.F58INT00
    WHERE TRIM(TPPNID)= TRIM(ACCOUNT_NUMBER);

    EXCEPTION
	 WHEN OTHERS THEN
		Temp_RetMsg:=00;
        OUT_RepDays := Temp_RetMsg;
  END;

FUNCTION UFN_F58INT11_SDM_POLL RETURN NUMBER is
  --Return a count of 1 if at least one record is waiting to Be transmitted.
    ncount NUMBER;
  BEGIN

    SELECT COUNT(*)
    INTO ncount
    FROM proddta.F58INT11
    WHERE SG$RSP IN ('D')
    AND SGC75DCT='Service Detail'
    AND SGLRSSM='SDM';

    return(ncount);
END UFN_F58INT11_SDM_POLL;

PROCEDURE USP_AMS_SERVICE_DETAILS_OUTBOUND_SELECT(
  OUT_CLOBData OUT NOCOPY CLOB
  ,OUT_RetMsg OUT VARCHAR2 ) IS

--Declarations
      Temp_RetMsg VARCHAR2(30000):='';
      v_TransmissionID VARCHAR(20);
	  v_ISALLOWEDFLAG CHAR(1);
      v_TPDS40 CHAR(40);
      v_Total_Count NUMBER:=0;
	  v_Select_Count NUMBER:=0;
	  v_F58INT12_NLIN_Count NUMBER:=0;
	  v_F58INT13_NLIN_Count NUMBER:=0;
	  v_F58INT15_NLIN_Count NUMBER:=0;
	  V_ADDL_RECORDS_AVL CHAR(1):='N';
      v_F58INT00_Count NUMBER;


      l_domdoc dbms_xmldom.DOMDocument;
      l_xmltype XMLTYPE;

      l_root_textnode dbms_xmldom.DOMNode;

      l_SERVICE_DETAILS_INFO_textnode dbms_xmldom.DOMNode;

      l_F58INT11_textnode dbms_xmldom.DOMNode;
      l_F58INT12_textnode dbms_xmldom.DOMNode;
      l_F58INT12_Rcd_textnode dbms_xmldom.DOMNode;
      l_F58INT13_textnode dbms_xmldom.DOMNode;
      l_F58INT13_Rcd_textnode dbms_xmldom.DOMNode;
      l_F58INT15_textnode dbms_xmldom.DOMNode;
      l_F58INT15_Rcd_textnode dbms_xmldom.DOMNode;
      l_F58INT00_textnode dbms_xmldom.DOMNode;
      l_F58INT00_Rcd_textnode dbms_xmldom.DOMNode;
      l_XXPLXS_TDM_VIEW_REPORT_textnode dbms_xmldom.DOMNode;
      l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode dbms_xmldom.DOMNode;

	  ADDL_RECORDS_AVL_node dbms_xmldom.DOMNode;
	  DOCUMENT_TYPE_node dbms_xmldom.DOMNode;
	  l_AN8_node dbms_xmldom.DOMNode;
		MODULE_node dbms_xmldom.DOMNode;
		VERSION_node dbms_xmldom.DOMNode;
		TEST_FLAG_node dbms_xmldom.DOMNode;
		TRANSMISSION_DATE_node dbms_xmldom.DOMNode;
		TRANSMISSION_ID_node dbms_xmldom.DOMNode;
		CUSTOMER_node dbms_xmldom.DOMNode;
		MPF_node dbms_xmldom.DOMNode;
		COMPANY_node dbms_xmldom.DOMNode;
		UNIQUE_ID_node dbms_xmldom.DOMNode;
		SERVICE_BRANCH_PLANT_node dbms_xmldom.DOMNode;
		PLXS_CASE_NUMBER_node dbms_xmldom.DOMNode;
		WORK_ORDER_NUMBER_node dbms_xmldom.DOMNode;
		TRX_TYPE_node dbms_xmldom.DOMNode;
		TRX_DATE_node dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE1_node dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE2_node dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE3_node dbms_xmldom.DOMNode;
		PLXS_ITEM_NUMBER_node dbms_xmldom.DOMNode;
		ITEM_DESC_node dbms_xmldom.DOMNode;
		CUSTOMER_ITEM_NUMBER_node dbms_xmldom.DOMNode;
		CUSTOMER_REV_node dbms_xmldom.DOMNode;
		SECONDARY_CUSTOMER_ITEM_NUMBER_node dbms_xmldom.DOMNode;
		PLXS_OUT_ITEM_NUMBER_node dbms_xmldom.DOMNode;
		CUSTOMER_OUT_ITEM_NUMBER_node dbms_xmldom.DOMNode;
		LOT_SERIAL_NUMBER_node dbms_xmldom.DOMNode;
		QTY_node dbms_xmldom.DOMNode;
		OPERATION_SEQ_node dbms_xmldom.DOMNode;
		OPERATION_CODE_node dbms_xmldom.DOMNode;
		OPERATION_DESC_node dbms_xmldom.DOMNode;
		OPERATION_RESULT_node dbms_xmldom.DOMNode;
        OPERATION_COMMENT_node dbms_xmldom.DOMNode;
		OPERATION_COMPLETION_DATE_node dbms_xmldom.DOMNode;
		COMPLETED_BY_node dbms_xmldom.DOMNode;
		AREA_TYPE_node dbms_xmldom.DOMNode;
		AREA_DESC_node dbms_xmldom.DOMNode;
		OPERATION_SEQ_13_node dbms_xmldom.DOMNode;
		PART_NUMBER_node dbms_xmldom.DOMNode;
		LOT_SERIAL_NUMBER_13_node dbms_xmldom.DOMNode;
		REQUESTED_QUANTITY_node dbms_xmldom.DOMNode;
		ISSUED_QUANTITY_node dbms_xmldom.DOMNode;
        PLXS_DEFECT_CODE_node dbms_xmldom.DOMNode;
		PLXS_DEFECT_DESC_node dbms_xmldom.DOMNode;
		DEFECT_COMMENT_node dbms_xmldom.DOMNode;
        FORM_NAME_node dbms_xmldom.DOMNode;
        DISPLAY_SEQUENCE_node dbms_xmldom.DOMNode;
        ATTRIBUTE_LABEL_node dbms_xmldom.DOMNode;
        RESPONSE_node dbms_xmldom.DOMNode;
        IS_ALLOWED_FLAG_node dbms_xmldom.DOMNode;
        FILE_TYPE_node dbms_xmldom.DOMNode;

		ADDL_RECORDS_AVL_textnode dbms_xmldom.DOMNode;
		DOCUMENT_TYPE_textnode dbms_xmldom.DOMNode;
		l_AN8_textnode dbms_xmldom.DOMNode;
		MODULE_textnode dbms_xmldom.DOMNode;
		VERSION_textnode dbms_xmldom.DOMNode;
		TEST_FLAG_textnode dbms_xmldom.DOMNode;
		TRANSMISSION_DATE_textnode dbms_xmldom.DOMNode;
		TRANSMISSION_ID_textnode dbms_xmldom.DOMNode;
		CUSTOMER_textnode dbms_xmldom.DOMNode;
		MPF_textnode dbms_xmldom.DOMNode;
		COMPANY_textnode dbms_xmldom.DOMNode;
		UNIQUE_ID_textnode dbms_xmldom.DOMNode;
		SERVICE_BRANCH_PLANT_textnode dbms_xmldom.DOMNode;
		PLXS_CASE_NUMBER_textnode dbms_xmldom.DOMNode;
		WORK_ORDER_NUMBER_textnode dbms_xmldom.DOMNode;
		TRX_TYPE_textnode dbms_xmldom.DOMNode;
		TRX_DATE_textnode dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE1_textnode dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE2_textnode dbms_xmldom.DOMNode;
		CUSTOMER_REFERENCE3_textnode dbms_xmldom.DOMNode;
		PLXS_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;
		ITEM_DESC_textnode dbms_xmldom.DOMNode;
		CUSTOMER_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;
		CUSTOMER_REV_textnode dbms_xmldom.DOMNode;
		SECONDARY_CUSTOMER_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;
		PLXS_OUT_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;
		CUSTOMER_OUT_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;
		LOT_SERIAL_NUMBER_textnode dbms_xmldom.DOMNode;
		QTY_textnode dbms_xmldom.DOMNode;
		OPERATION_SEQ_textnode dbms_xmldom.DOMNode;
		OPERATION_CODE_textnode dbms_xmldom.DOMNode;
		OPERATION_DESC_textnode dbms_xmldom.DOMNode;
		OPERATION_RESULT_textnode dbms_xmldom.DOMNode;
        OPERATION_COMMENT_textnode dbms_xmldom.DOMNode;
		OPERATION_COMPLETION_DATE_textnode dbms_xmldom.DOMNode;
		COMPLETED_BY_textnode dbms_xmldom.DOMNode;
		AREA_TYPE_textnode dbms_xmldom.DOMNode;
		AREA_DESC_textnode dbms_xmldom.DOMNode;
		OPERATION_SEQ_13_textnode dbms_xmldom.DOMNode;
		PART_NUMBER_textnode dbms_xmldom.DOMNode;
		LOT_SERIAL_NUMBER_13_textnode dbms_xmldom.DOMNode;
		REQUESTED_QUANTITY_textnode dbms_xmldom.DOMNode;
		ISSUED_QUANTITY_textnode dbms_xmldom.DOMNode;
        PLXS_DEFECT_CODE_textnode dbms_xmldom.DOMNode;
		PLXS_DEFECT_DESC_textnode dbms_xmldom.DOMNode;
		DEFECT_COMMENT_textnode dbms_xmldom.DOMNode;
        FORM_NAME_textnode dbms_xmldom.DOMNode;
        DISPLAY_SEQUENCE_textnode dbms_xmldom.DOMNode;
        ATTRIBUTE_LABEL_textnode dbms_xmldom.DOMNode;
        RESPONSE_textnode dbms_xmldom.DOMNode;

        l_DESTINATION_ERP_node dbms_xmldom.DOMNode;
        l_DESTINATION_ERP_textnode dbms_xmldom.DOMNode;

        IS_ALLOWED_FLAG_textnode dbms_xmldom.DOMNode;
        FILE_TYPE_textnode dbms_xmldom.DOMNode;

	TEMP_AN8 NUMBER;
    TEMP_C75DCT CHAR(60);
	TEMP_LRSSM CHAR(10);
	TEMP_B76VER CHAR(10);
	TEMP_$TSTFLAG CHAR(1);
	TEMP_CREATEDT VARCHAR(30):= TO_CHAR(SYS_EXTRACT_UTC(SYSTIMESTAMP),'YYYY-MM-DD"T"HH24:MI:SS.ff3"Z"');
	TEMP_TRANSDate VARCHAR(30);
	TEMP_$TRANSID CHAR(150);
	TEMP_ALPH CHAR(40);
	TEMP_$MPFNUM CHAR(25);
	TEMP_UKID NUMBER;
	TEMP_$SERMCU CHAR(15);
    TEMP_$SRCDEST VARCHAR(50);
	TEMP_DOCO NUMBER;
	TEMP_WOD NUMBER;
	TEMP_TRNDES CHAR(30);
	TEMP_$GS04 NUMBER;
	TEMP_RF1 CHAR(30);
	TEMP_RF2 CHAR(30);
	TEMP_RF3 CHAR(30);
	TEMP_LITM CHAR(25);
	TEMP_DSC1 CHAR(30);
	TEMP_$CUSPRTN CHAR(30);
	TEMP_DL03 CHAR(30);
	TEMP_KITL CHAR(25);
	TEMP_CITM CHAR(25);
	TEMP_LOTN CHAR(30);
	TEMP_TRQT NUMBER;
	TEMP_OPSQ NUMBER;
	TEMP_$58OC CHAR(8);
	TEMP_DSC1_15  CHAR(30);
	TEMP_DL01 CHAR(30);
	TEMP_UPMJ NUMBER;
    Temp_OprCmt VARCHAR2(512);
	Temp_OprDate VARCHAR(30);
	TEMP_UPMT NUMBER;
	TEMP_ALPH_15 CHAR(40);
	TEMP_$NOTETYP CHAR(100);
	TEMP_GPTX VARCHAR2(1500);
	TEMP_OPSQ_13 NUMBER;
	TEMP_CPIL CHAR(25);
	TEMP_LOTN_13 CHAR(30);
	TEMP_UORG NUMBER;
	TEMP_TRQT_13 NUMBER;
	TEMP_DL01_13 CHAR(30);
    TEMP_DC01 CHAR(5);
	TEMP_VCOMMENT CHAR(60);
	v_F58INT00_Select_Count NUMBER;
	v_CountF00022 NUMBER;
    TEMP_FORM_NAME VARCHAR(250);
    TEMP_DISPLAY_SEQUENCE NUMBER;
    TEMP_ATTRIBUTE_LABEL VARCHAR(300);
    TEMP_RESPONSE VARCHAR(2000);

    v_SGC75DCT CHAR(60);
    v_SGUKID NUMBER;
    v_SGPNID CHAR(15);
BEGIN

      --Creates an exmpty XML Document
      l_domdoc := dbms_xmldom.newDOMDocument;

      --Creates a root node
      l_root_textnode := dbms_xmldom.makeNode(l_domdoc);
      DBMS_OUTPUT.PUT_LINE('Start');

      SELECT COUNT(1) INTO v_Total_Count
      FROM PRODDTA.F58INT11
      WHERE
        ROWNUM = 1
        --SGPNID=CAST(ACCOUNT_NUMBER as CHAR(15)) AND SG$SERMCU=CAST(PRODUCT_FAMILY as CHAR(15)) AND SG$MPFNUM=CAST(MPF as CHAR(25))
        AND SG$RSP IN ('D') AND SGC75DCT='Service Detail' and SGLRSSM='SDM';

        IF (v_Total_Count > v_F58INT00_Count) THEN
		BEGIN
			V_ADDL_RECORDS_AVL:='Y';
			--v_Select_Count:=v_F58INT00_Count;
		END;
		--ELSE
		--BEGIN
			--v_Select_Count:=v_Total_Count;
		--END;
		END IF;

    BEGIN
        FOR AMS_F58INT11_REC_UPDATE in
        (
            SELECT sg$transid
                    ,SGC75DCT
                    ,SGUKID
                    ,SGPNID
              --INTO v_TransmissionID
             -- ,v_SGC75DCT
             -- ,v_SGUKID
            FROM proddta.F58INT11
            WHERE ROWNUM = 1
                AND SGC75DCT='Service Detail' AND SGLRSSM='SDM'
                AND SG$RSP IN ('D')
            ORDER BY SGC75DCT, SGUKID)
        LOOP

            DBMS_OUTPUT.PUT_LINE(AMS_F58INT11_REC_UPDATE.SGC75DCT||'~~'||AMS_F58INT11_REC_UPDATE.SGUKID);

            v_SGC75DCT := AMS_F58INT11_REC_UPDATE.SGC75DCT;
            v_SGUKID := AMS_F58INT11_REC_UPDATE.SGUKID;
            v_SGPNID := AMS_F58INT11_REC_UPDATE.SGPNID;
            --v_TransmissionID := AMS_F58INT11_REC_UPDATE.sg$transid;

            UPDATE PRODDTA.F58INT11 A
            SET SG$RSP='B'--,SG$TRANSID=v_TransmissionID
            WHERE SGC75DCT = AMS_F58INT11_REC_UPDATE.SGC75DCT AND SGUKID = AMS_F58INT11_REC_UPDATE.SGUKID;

            COMMIT;

        END LOOP;

       --Create the XML structure for the Header/Non repeating sections
      l_SERVICE_DETAILS_INFO_textnode := dbms_xmldom.appendChild(l_root_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'AMS_SERVICE_DETAILS_OUTBOUND_INFO')));

      --Create Header or Non-Repeating XML nodes based on one record of the
      --TransmissionID/Customer Number
      FOR AMS_F58INT11_REC in
      (
		  SELECT SGC75DCT
			,SGAN8
            ,SGLRSSM
            ,SGB76VER
            ,SG$TSTFLAG
            ,SGCREATEDT
            ,SG$TRANSID
            ,SGALPH
            ,SG$MPFNUM
            ,SGUKID
            ,SG$SERMCU
            ,SGDOCO
            ,SGWOD
            ,SGTRNDES
            ,SG$GS04
            ,DECODE(SG$GS04,0,'0',TO_CHAR(TO_DATE(TO_CHAR(SG$GS04 + 1900000),'YYYYDDD'),'yyyy-mm-dd'))||'T'|| decode(0,0,'00:00:00',to_char(to_date(LPAD(TO_CHAR(0),6,'0') , 'hh24miss'),'hh24:mi:ss'))||'Z' TRANSDate
            ,SGRF1
            ,SGRF2
            ,SGRF3
            ,SGLITM
            ,SGDSC1
            ,SG$CUSPRTN
            ,SGDL03
            ,SGKITL
            ,SGCITM
            ,SGLOTN
            ,SGTRQT
            ,SG$SRCDEST
		  FROM PRODDTA.F58INT11
		  WHERE
              SGC75DCT='Service Detail' AND SGLRSSM='SDM'
              --AND ROWNUM <= v_Select_Count
              AND SGC75DCT = v_SGC75DCT AND SGUKID = v_SGUKID
		  ORDER BY SGC75DCT, SGUKID
      )
      LOOP
        DBMS_OUTPUT.PUT_LINE('F58INT11 select completed');
            TEMP_C75DCT := AMS_F58INT11_REC.SGC75DCT;
			TEMP_AN8 := AMS_F58INT11_REC.SGAN8;
			TEMP_LRSSM := AMS_F58INT11_REC.SGLRSSM;
			TEMP_B76VER := AMS_F58INT11_REC.SGB76VER;
			TEMP_$TSTFLAG := AMS_F58INT11_REC.SG$TSTFLAG;
			TEMP_TRANSDate := AMS_F58INT11_REC.TRANSDate;
			TEMP_$TRANSID := AMS_F58INT11_REC.SG$TRANSID;
			TEMP_ALPH := AMS_F58INT11_REC.SGALPH;
			TEMP_$MPFNUM := AMS_F58INT11_REC.SG$MPFNUM;
			TEMP_UKID := AMS_F58INT11_REC.SGUKID;
			TEMP_$SERMCU := AMS_F58INT11_REC.SG$SERMCU;
			TEMP_DOCO := AMS_F58INT11_REC.SGDOCO;
			TEMP_WOD := AMS_F58INT11_REC.SGWOD;
			TEMP_TRNDES := AMS_F58INT11_REC.SGTRNDES;
			TEMP_$GS04 := AMS_F58INT11_REC.SG$GS04;
			TEMP_RF1 := AMS_F58INT11_REC.SGRF1;
			TEMP_RF2 := AMS_F58INT11_REC.SGRF2;
			TEMP_RF3 := AMS_F58INT11_REC.SGRF3;
			TEMP_LITM := AMS_F58INT11_REC.SGLITM;
			TEMP_DSC1 := AMS_F58INT11_REC.SGDSC1;
			TEMP_$CUSPRTN := AMS_F58INT11_REC.SG$CUSPRTN;
			TEMP_DL03 := AMS_F58INT11_REC.SGDL03;
			TEMP_KITL := AMS_F58INT11_REC.SGKITL;
			TEMP_CITM := AMS_F58INT11_REC.SGCITM;
			TEMP_LOTN := AMS_F58INT11_REC.SGLOTN;
			TEMP_TRQT := AMS_F58INT11_REC.SGTRQT;
            TEMP_$SRCDEST := AMS_F58INT11_REC.SG$SRCDEST;
DBMS_OUTPUT.PUT_LINE('F58INT11 select variable assign completed');

			l_F58INT11_textnode:= dbms_xmldom.appendChild(l_SERVICE_DETAILS_INFO_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'F58INT11')));

            l_an8_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AN8')));
			l_an8_textnode	:= dbms_xmldom.appendChild(	l_an8_node, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(temp_an8)) )));

           DOCUMENT_TYPE_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DOCUMENT_TYPE')));
			DOCUMENT_TYPE_textnode	:= dbms_xmldom.appendChild(	DOCUMENT_TYPE_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_C75DCT)) )));

			MODULE_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'MODULE')));
			MODULE_textnode	:= dbms_xmldom.appendChild(	MODULE_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_LRSSM)) )));

			VERSION_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'VERSION')));
			VERSION_textnode	:= dbms_xmldom.appendChild(	VERSION_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_B76VER))  )));

			TEST_FLAG_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TEST_FLAG')));
			TEST_FLAG_textnode	:= dbms_xmldom.appendChild(	TEST_FLAG_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$TSTFLAG)) )));

DBMS_OUTPUT.PUT_LINE('F58INT11 select xml assign test flag completed');

			TRANSMISSION_DATE_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRANSMISSION_DATE')));
			TRANSMISSION_DATE_textnode	:= dbms_xmldom.appendChild(	TRANSMISSION_DATE_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_CREATEDT )));

			TRANSMISSION_ID_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRANSMISSION_ID')));
			TRANSMISSION_ID_textnode	:= dbms_xmldom.appendChild(	TRANSMISSION_ID_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$TRANSID )))));

			CUSTOMER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER')));
			CUSTOMER_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_ALPH)) )));

			MPF_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'MPF')));
			MPF_textnode	:= dbms_xmldom.appendChild(	MPF_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$MPFNUM)) )));

            l_DESTINATION_ERP_node := dbms_xmldom.appendChild(l_F58INT11_textnode
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DESTINATION_ERP' )));
            l_DESTINATION_ERP_textnode := dbms_xmldom.appendChild( l_DESTINATION_ERP_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$SRCDEST)) )));

DBMS_OUTPUT.PUT_LINE('F58INT11 select xml assign MPF flag completed');

			UNIQUE_ID_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'UNIQUE_ID')));
			UNIQUE_ID_textnode	:= dbms_xmldom.appendChild(	UNIQUE_ID_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_UKID )))));

			SERVICE_BRANCH_PLANT_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'SERVICE_BRANCH_PLANT')));
			SERVICE_BRANCH_PLANT_textnode	:= dbms_xmldom.appendChild(	SERVICE_BRANCH_PLANT_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$SERMCU)) )));

			PLXS_CASE_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_CASE_NUMBER')));
			PLXS_CASE_NUMBER_textnode	:= dbms_xmldom.appendChild(	PLXS_CASE_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_DOCO))  )));

			WORK_ORDER_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'WORK_ORDER_NUMBER')));
			WORK_ORDER_NUMBER_textnode	:= dbms_xmldom.appendChild(	WORK_ORDER_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_WOD))  )));

			TRX_TYPE_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRX_TYPE')));
			TRX_TYPE_textnode	:= dbms_xmldom.appendChild(	TRX_TYPE_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_TRNDES)) )));

			TRX_DATE_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRX_DATE')));
			TRX_DATE_textnode	:= dbms_xmldom.appendChild(	TRX_DATE_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_TRANSDate)) )));

			CUSTOMER_REFERENCE1_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE1')));
			CUSTOMER_REFERENCE1_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_REFERENCE1_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,  ltrim(rtrim(TEMP_RF1)))));

DBMS_OUTPUT.PUT_LINE('F58INT11 select xml assign CUSTOMER_REFERENCE1_node flag completed');
			CUSTOMER_REFERENCE2_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE2')));
			CUSTOMER_REFERENCE2_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_REFERENCE2_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_RF2)) )));

			CUSTOMER_REFERENCE3_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE3')));
			CUSTOMER_REFERENCE3_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_REFERENCE3_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_RF3))  )));

			PLXS_ITEM_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_ITEM_NUMBER')));
			PLXS_ITEM_NUMBER_textnode	:= dbms_xmldom.appendChild(	PLXS_ITEM_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_LITM)) )));

			ITEM_DESC_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ITEM_DESC')));
			ITEM_DESC_textnode	:= dbms_xmldom.appendChild(	ITEM_DESC_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_DSC1))  )));

			CUSTOMER_ITEM_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_ITEM_NUMBER')));
			CUSTOMER_ITEM_NUMBER_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_ITEM_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$CUSPRTN)) )));

			CUSTOMER_REV_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REV')));
			CUSTOMER_REV_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_REV_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DL03)) )));

			PLXS_OUT_ITEM_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_OUT_ITEM_NUMBER')));
			PLXS_OUT_ITEM_NUMBER_textnode	:= dbms_xmldom.appendChild(	PLXS_OUT_ITEM_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_KITL)) )));

			CUSTOMER_OUT_ITEM_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_OUT_ITEM_NUMBER')));
			CUSTOMER_OUT_ITEM_NUMBER_textnode	:= dbms_xmldom.appendChild(	CUSTOMER_OUT_ITEM_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc,ltrim(rtrim(TEMP_CITM))  )));

			LOT_SERIAL_NUMBER_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'LOT_SERIAL_NUMBER')));
			LOT_SERIAL_NUMBER_textnode	:= dbms_xmldom.appendChild(	LOT_SERIAL_NUMBER_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_LOTN)) )));

			QTY_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'QTY')));
			QTY_textnode	:= dbms_xmldom.appendChild(	QTY_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_TRQT)) )));

			ADDL_RECORDS_AVL_node	:= dbms_xmldom.appendChild(l_F58INT11_textnode
															  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ADDL_RECORDS_AVL')));
			ADDL_RECORDS_AVL_textnode	:= dbms_xmldom.appendChild(	ADDL_RECORDS_AVL_node	, dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(V_ADDL_RECORDS_AVL)) )));

            DBMS_OUTPUT.PUT_LINE('F58INT11 select xml assign QTY_textnode flag completed');
			l_F58INT15_textnode := dbms_xmldom.appendChild(l_F58INT11_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'F58INT15')));

			FOR AMS_F58INT15_REC IN
            (
			   SELECT SDOPSQ
					,SD$58OC
					,SDDSC1
					,SDDL01
					,DECODE(SDMUPM,0,'0',TO_CHAR(TO_DATE(TO_CHAR(SDMUPM + 1900000),'YYYYDDD'),'yyyy-mm-dd'))||'T'|| decode(SDUPMT,0,'00:00:00',to_char(to_date(LPAD(TO_CHAR(SDUPMT),6,'0') , 'hh24miss'),'hh24:mi:ss'))||'Z' as OprDate
					,SDCMMNT
                    ,SDUPMJ
					,SDUPMT
					,SDALPH
			   FROM PRODDTA.F58INT15
			   WHERE SDC75DCT=TEMP_C75DCT AND SDUKID=TEMP_UKID
			   ORDER BY SDC75DCT, SDUKID, SDNLIN
			 )
             LOOP
                DBMS_OUTPUT.PUT_LINE('F58INT15 select completed');
                TEMP_OPSQ := AMS_F58INT15_REC.SDOPSQ;
                TEMP_$58OC := AMS_F58INT15_REC.SD$58OC;
                TEMP_DSC1_15 := AMS_F58INT15_REC.SDDSC1;
                TEMP_DL01 := AMS_F58INT15_REC.SDDL01;
                TEMP_UPMJ := AMS_F58INT15_REC.SDUPMJ;
                TEMP_UPMT := AMS_F58INT15_REC.SDUPMT;
                Temp_OprCmt:=	AMS_F58INT15_REC.SDCMMNT;
				Temp_OprDate:=	AMS_F58INT15_REC.OprDate;
                TEMP_ALPH_15 := AMS_F58INT15_REC.SDALPH;

                  l_F58INT15_Rcd_textnode:= dbms_xmldom.appendChild(l_F58INT15_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'Record')));

				  OPERATION_SEQ_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_SEQ' )));
                  OPERATION_SEQ_textnode := dbms_xmldom.appendChild( OPERATION_SEQ_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_OPSQ/100)) )));

                  OPERATION_CODE_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_CODE' )));
                  OPERATION_CODE_textnode := dbms_xmldom.appendChild( OPERATION_CODE_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$58OC)))));

				  OPERATION_DESC_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_DESC' )));
                  OPERATION_DESC_textnode := dbms_xmldom.appendChild( OPERATION_DESC_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DSC1_15)) )));

                  OPERATION_RESULT_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_RESULT' )));
                  OPERATION_RESULT_textnode := dbms_xmldom.appendChild( OPERATION_RESULT_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DL01)))));

                  OPERATION_COMMENT_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_COMMENT' )));
                  OPERATION_COMMENT_textnode := dbms_xmldom.appendChild( OPERATION_COMMENT_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(Temp_OprCmt)))));

				  OPERATION_COMPLETION_DATE_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_COMPLETION_DATE' )));
                  OPERATION_COMPLETION_DATE_textnode := dbms_xmldom.appendChild( OPERATION_COMPLETION_DATE_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, Temp_OprDate )));

                  COMPLETED_BY_node := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'COMPLETED_BY' )));
                  COMPLETED_BY_textnode := dbms_xmldom.appendChild( COMPLETED_BY_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_ALPH_15)))));

                 l_XXPLXS_TDM_VIEW_REPORT_textnode := dbms_xmldom.appendChild(l_F58INT15_Rcd_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'XXPLXS_TDM_VIEW_REPORT')));
                 DBMS_OUTPUT.PUT_LINE('XXPLXS_TDM_VIEW_REPORT_REC - Started | ' || to_char(TEMP_WOD) || ' | ' || TO_CHAR(TEMP_OPSQ/100) || ' | ' || to_char(TEMP_$58OC));


                 FOR XXPLXS_TDM_VIEW_REPORT_REC IN
                  (
                    SELECT FORM_NAME,
                          DISPLAY_SEQUENCE,
                          ATTRIBUTE_LABEL,
                          RESPONSE
                    FROM Xxapps.plxs_complete_v
                    WHERE work_order_number     = ltrim(rtrim(TEMP_WOD))              --SERVICE_DETAIL/WORK_ORDER_NUMBER
                        AND display_sequence    IS NOT NULL
                        AND (qa_header_id is null or (qa_header_id is not null and qa_line_id is not null))
                        AND operation_seq       = ltrim(rtrim((TEMP_OPSQ/100)))   --SERVICE_DETAIL/OPERATION_DETAIL/OPERATION_SEQ
                        AND operation_code      = ltrim(rtrim(TEMP_$58OC))        --SERVICE_DETAIL/OPERATION_DETAIL/OPERATION_CODE
                        AND attribute_type      !='LABEL'
						AND REPORTING_FLAG = 'Y'
                    ORDER BY OPERATION_SEQ,FORM_SEQUENCE,DISPLAY_SEQUENCE
                   )
                   LOOP
                        TEMP_FORM_NAME := XXPLXS_TDM_VIEW_REPORT_REC.FORM_NAME;
                        TEMP_DISPLAY_SEQUENCE := XXPLXS_TDM_VIEW_REPORT_REC.DISPLAY_SEQUENCE;
                        TEMP_ATTRIBUTE_LABEL := XXPLXS_TDM_VIEW_REPORT_REC.ATTRIBUTE_LABEL;
                        TEMP_RESPONSE := XXPLXS_TDM_VIEW_REPORT_REC.RESPONSE;

                        DBMS_OUTPUT.PUT_LINE('XXPLXS_TDM_VIEW_REPORT_REC - Loop started ' || XXPLXS_TDM_VIEW_REPORT_REC.FORM_NAME);
                        l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode:= dbms_xmldom.appendChild(l_XXPLXS_TDM_VIEW_REPORT_textnode
                                                        ,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'XXPLXS_TDM_VIEW_REPORT_Record')));

                        FORM_NAME_node := dbms_xmldom.appendChild(l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'FORM_NAME' )));
                        FORM_NAME_textnode := dbms_xmldom.appendChild( FORM_NAME_node
                                                             , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_FORM_NAME)))));

                        DISPLAY_SEQUENCE_node := dbms_xmldom.appendChild(l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DISPLAY_SEQUENCE' )));
                        DISPLAY_SEQUENCE_textnode := dbms_xmldom.appendChild( DISPLAY_SEQUENCE_node
                                                             , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DISPLAY_SEQUENCE)))));

                        ATTRIBUTE_LABEL_node := dbms_xmldom.appendChild(l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ATTRIBUTE_LABEL' )));
                        ATTRIBUTE_LABEL_textnode := dbms_xmldom.appendChild( ATTRIBUTE_LABEL_node
                                                             , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_ATTRIBUTE_LABEL)))));

                        RESPONSE_node := dbms_xmldom.appendChild(l_XXPLXS_TDM_VIEW_REPORT_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'RESPONSE' )));
                        RESPONSE_textnode := dbms_xmldom.appendChild( RESPONSE_node
                                                             , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_RESPONSE)))));

                   END LOOP;
                   DBMS_OUTPUT.PUT_LINE('XXPLXS_TDM_VIEW_REPORT_REC - Ended');

             END LOOP;

             l_F58INT12_textnode := dbms_xmldom.appendChild(l_F58INT11_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'F58INT12')));

			FOR AMS_F58INT12_REC IN
            (
                SELECT NT$NOTETYP
                    ,NTGPTX
                FROM PRODDTA.F58INT12
                WHERE NTUKID = TEMP_UKID
                AND   ntc75dct =  RPAD(TRIM(TEMP_C75DCT),60)
                ORDER BY NTC75DCT, NTUKID, NTNLIN
            )
            LOOP

                DBMS_OUTPUT.PUT_LINE('F58INT12 select completed');
                TEMP_$NOTETYP := AMS_F58INT12_REC.NT$NOTETYP;
                TEMP_GPTX := AMS_F58INT12_REC.NTGPTX;

                l_F58INT12_Rcd_textnode:= dbms_xmldom.appendChild(l_F58INT12_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'Record')));
                AREA_TYPE_node := dbms_xmldom.appendChild(l_F58INT12_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AREA_TYPE' )));
                AREA_TYPE_textnode := dbms_xmldom.appendChild( AREA_TYPE_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_$NOTETYP)) )));

                AREA_DESC_node := dbms_xmldom.appendChild(l_F58INT12_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AREA_DESC' )));
                AREA_DESC_textnode := dbms_xmldom.appendChild( AREA_DESC_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_GPTX)))));
            END LOOP;
			l_F58INT13_textnode := dbms_xmldom.appendChild(l_F58INT11_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'F58INT13')));

            FOR AMS_F58INT13_REC IN
            (
			   SELECT PIOPSQ
					,PICPIL
					,PILOTN
					,PIUORG
					,PITRQT
					,PIDL01
                    ,PI$58DC
					,PIVCOMMENT
			   FROM PRODDTA.F58INT13 where PIC75DCT=TEMP_C75DCT AND PIUKID=TEMP_UKID
			   ORDER BY PIC75DCT, PIUKID, PINLIN
           )
           LOOP

                DBMS_OUTPUT.PUT_LINE('F58INT13 select completed');
                TEMP_OPSQ := AMS_F58INT13_REC.PIOPSQ;
                TEMP_CPIL := AMS_F58INT13_REC.PICPIL;
                TEMP_LOTN_13 := AMS_F58INT13_REC.PILOTN;
                TEMP_UORG := AMS_F58INT13_REC.PIUORG;
                TEMP_TRQT_13 := AMS_F58INT13_REC.PITRQT;
                TEMP_DL01 := AMS_F58INT13_REC.PIDL01;
                TEMP_DC01 := AMS_F58INT13_REC.PI$58DC;
                TEMP_VCOMMENT := AMS_F58INT13_REC.PIVCOMMENT;

                l_F58INT13_Rcd_textnode:= dbms_xmldom.appendChild(l_F58INT13_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'Record')));
                OPERATION_SEQ_13_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'OPERATION_SEQ' )));
                OPERATION_SEQ_13_textnode := dbms_xmldom.appendChild( OPERATION_SEQ_13_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_OPSQ/100)) )));

                PART_NUMBER_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PART_NUMBER' )));
                PART_NUMBER_textnode := dbms_xmldom.appendChild( PART_NUMBER_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_CPIL)))));

				LOT_SERIAL_NUMBER_13_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'LOT_SERIAL_NUMBER' )));
                LOT_SERIAL_NUMBER_13_textnode := dbms_xmldom.appendChild( LOT_SERIAL_NUMBER_13_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_LOTN_13)) )));

                REQUESTED_QUANTITY_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'REQUESTED_QUANTITY' )));
                REQUESTED_QUANTITY_textnode := dbms_xmldom.appendChild( REQUESTED_QUANTITY_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_UORG)))));

                ISSUED_QUANTITY_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ISSUED_QUANTITY' )));
                ISSUED_QUANTITY_textnode := dbms_xmldom.appendChild( ISSUED_QUANTITY_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_TRQT_13)))));

                PLXS_DEFECT_CODE_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_DEFECT_CODE' )));
                PLXS_DEFECT_CODE_textnode := dbms_xmldom.appendChild( PLXS_DEFECT_CODE_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DC01)) )));

                PLXS_DEFECT_DESC_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_DEFECT_DESC' )));
                PLXS_DEFECT_DESC_textnode := dbms_xmldom.appendChild( PLXS_DEFECT_DESC_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_DL01)) )));

                DEFECT_COMMENT_node := dbms_xmldom.appendChild(l_F58INT13_Rcd_textnode
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DEFECT_COMMENT' )));
                DEFECT_COMMENT_textnode := dbms_xmldom.appendChild( DEFECT_COMMENT_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(TEMP_VCOMMENT)))));
            END LOOP;

            UPDATE PRODDTA.F58INT11 SET SG$RSP='B' ,SGCREATEDT=TEMP_CREATEDT ,SGUSER = 'BIZTALK'
                ,SGUPMT = to_char(cast(SYSDATE as date),'hh24miss')
                ,SGUPMJ = To_Number(To_Char(To_Number(To_Char(sysdate, 'yyyy')) - 1900) || To_Char(sysdate, 'ddd'))
				,SGPID= 'BIZTALK'
				,SGJOBN	= 'BIZTALK'	WHERE SGC75DCT=TEMP_C75DCT AND SGUKID=TEMP_UKID ;
			COMMIT;
      END LOOP;


      SELECT TPEV08, TP$COUNT08, TPDS40 INTO v_ISALLOWEDFLAG, v_F58INT00_Count, v_TPDS40
      FROM PRODDTA.F58INT00
      WHERE
        TPPNID = v_SGPNID
        AND TP$SERMCU = TEMP_$SERMCU
        AND TP$MPFNUM = TEMP_$MPFNUM;

        --Cloud IO nodes
        l_F58INT00_textnode := dbms_xmldom.appendChild(l_F58INT11_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'F58INT00')));

        l_F58INT00_Rcd_textnode:= dbms_xmldom.appendChild(l_F58INT00_textnode,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'Record')));
        IS_ALLOWED_FLAG_node := dbms_xmldom.appendChild(l_F58INT00_Rcd_textnode
                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'IS_ALLOWED_FLAG' )));
        IS_ALLOWED_FLAG_textnode := dbms_xmldom.appendChild( IS_ALLOWED_FLAG_node
                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(v_ISALLOWEDFLAG)) )));

        FILE_TYPE_node := dbms_xmldom.appendChild(l_F58INT00_Rcd_textnode
                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'FILE_TYPE' )));
        FILE_TYPE_textnode := dbms_xmldom.appendChild( FILE_TYPE_node
                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, ltrim(rtrim(v_TPDS40)) )));

    EXCEPTION
             WHEN OTHERS THEN

             --UPDATE PRODDTA.F58INT11 SET SG$RSP='E' WHERE sg$transid = v_TransmissionID AND sgan8 = v_Customer;
             --COMMIT;

             Temp_RetMsg :='Error: - '||SQLCODE||' -ERROR- '||substr(SQLERRM,1,2000) || ' -TransmissionID - '||NVL(v_TransmissionID, '');
    END; --END TRANSACTION


	l_xmltype := dbms_xmldom.getXmlType(l_domdoc);
    dbms_xmldom.freeDocument(l_domdoc);

    OUT_CLOBData := l_xmltype.getClobVal;

    OUT_RetMsg := Temp_RetMsg;

END USP_AMS_SERVICE_DETAILS_OUTBOUND_SELECT;

PROCEDURE USP_F58INT11_BATCHUPDATE(SG$TRANSID_IN IN VARCHAR2
                                      ,SGAN8_IN NUMBER
                                     ,SGURLNAME_IN IN VARCHAR2
                                     ,SG$RSP_IN IN VARCHAR2
                                     ,SGLONGMSG_IN IN VARCHAR2
                                     ,SGUSER_IN IN VARCHAR2
                                     ,SGUPMJ_IN IN VARCHAR2
                                     ,SGUPMT_IN IN VARCHAR2
                                     ,SGCREATEDT_IN IN VARCHAR2
                                     ,API_RESPONSEDATA_IN IN CLOB
                                     ,P_RETMSG_OUT OUT VARCHAR2) AS
    P_XMLData_in XMLTYPE;
    temp_CLOBData CLOB;
    V_SG$RSP VARCHAR2(1);
BEGIN
      BEGIN -- TRANSACTION

       select replace (API_RESPONSEDATA_IN,'CHR(38)','&' || 'amp;') INTO temp_CLOBData from dual;
       select replace (temp_CLOBData,'CHR(60)','&' || 'lt;') INTO temp_CLOBData from dual;
       select replace (temp_CLOBData,'CHR(62)','&' || 'gt;') INTO temp_CLOBData from dual;


        IF LENGTH(TRIM(API_RESPONSEDATA_IN)) =0 THEN
            UPDATE proddta.F58INT11
            SET SGURLNAME = SGURLNAME_IN
                ,SGUSER = SGUSER_IN
                ,SGUPMJ = SGUPMJ_IN
                ,SGUPMT = SGUPMT_IN
                --,SG$RSP = SG$RSP_IN
                ,SG$RSP = 'E'
                ,SGCREATEDT = SGCREATEDT_IN
                ,SGLONGMSG = SGLONGMSG_IN
             WHERE SG$TRANSID = RPAD(TRIM(SG$TRANSID_IN),150,' ')
             AND SGAN8 = SGAN8_IN
             AND SG$RSP = 'B';
        ELSE
                --Converting the CLOB to XML
               P_XMLData_in := xmltype.createxml(temp_CLOBData);
                      FOR cur_InRec IN (
                    SELECT xt.*
                    FROM   XMLTABLE('/JSON_API_AMSBatchResponse/AMSJsonMsgBatchResponse/DETAILS'
                             PASSING (P_XMLData_in)
                             COLUMNS
                                "UNIQUE_ID" PATH 'UNIQUE_ID',
                                "MESSAGE_STATUS" PATH 'MESSAGE_STATUS',
                                "MESSAGE_DESCRIPTION" PATH 'MESSAGE_DESCRIPTION'
                             ) xt
                )
               LOOP

                --RSP Flag Calculation
                IF UPPER(TRIM(cur_InRec."MESSAGE_STATUS")) = 'SUCCESS' THEN
                    V_SG$RSP := 'S';
                ELSIF UPPER(TRIM(cur_InRec."MESSAGE_STATUS")) = 'REJECTED' OR UPPER(TRIM(cur_InRec."MESSAGE_STATUS")) = 'REJECT' THEN
                    V_SG$RSP := 'R';
                ELSE
                     V_SG$RSP := 'E';
                END IF;

                IF LENGTH(cur_InRec."UNIQUE_ID") > 0 THEN

                  UPDATE proddta.F58INT11
                    SET SGURLNAME = SGURLNAME_IN
                        ,SGUSER = SGUSER_IN
                        ,SGUPMJ = SGUPMJ_IN
                        ,SGUPMT = SGUPMT_IN
                        ,SG$RSP = V_SG$RSP
                        ,SGCREATEDT = SGCREATEDT_IN
                        ,SGLONGMSG = cur_InRec."MESSAGE_DESCRIPTION"
                     WHERE SG$TRANSID = RPAD(TRIM(SG$TRANSID_IN),150,' ')
                     AND SGUKID = cur_InRec."UNIQUE_ID"
                     AND SGAN8 = SGAN8_IN
                     AND SG$RSP = 'B';

                 ELSE

                   UPDATE proddta.F58INT11
                    SET SGURLNAME = SGURLNAME_IN
                        ,SGUSER = SGUSER_IN
                        ,SGUPMJ = SGUPMJ_IN
                        ,SGUPMT = SGUPMT_IN
                        ,SG$RSP = V_SG$RSP
                        ,SGCREATEDT = SGCREATEDT_IN
                        ,SGLONGMSG = cur_InRec."MESSAGE_DESCRIPTION"
                     WHERE SG$TRANSID = RPAD(TRIM(SG$TRANSID_IN),150,' ')
                     AND SGAN8 = SGAN8_IN
                     AND SG$RSP = 'B';

                 END IF;

            END LOOP;

        END IF;

        --P_RETMSG_OUT := ('Update.  xml:' || temp_CLOBData);

        P_RETMSG_OUT := 'Update';
    END;

END;

FUNCTION UFN_F58INT11_ACKNOWLEDGEMENT_POLL_MultiplePoll(
                                        SGAN8_IN varchar := NULL
                                    ) RETURN NUMBER is
  --Return a count of 1 if at least one record is waiting to Be transmitted.
    ncount NUMBER;
  BEGIN

    SELECT COUNT(*)
    INTO ncount
    FROM proddta.F58INT11
    WHERE SG$RSP = 'D'
    AND SGC75DCT = 'Case Acknowledgement'
    AND SGAN8 IN (
            with rws as (
              select SGAN8_IN as str from dual
            )
              select regexp_substr (
                       str,
                       '[^|]+',
                       1,
                       level
                     ) value
              from   rws
              connect by level <=
                length ( str ) - length ( replace ( str, '|' ) ) + 1
    );

    return(ncount);
  end UFN_F58INT11_ACKNOWLEDGEMENT_POLL_MultiplePoll;

PROCEDURE USP_AMS_ACKNOWLEDGEMENT_SELECT_MultiplePolling(
                                        SGAN8_IN VARCHAR2
                                        ,OUT_CLOBData OUT NOCOPY CLOB
                                        ,OUT_RetMsg OUT VARCHAR2 ) IS
      --Declarations
      Temp_RetMsg VARCHAR2(4000):='';
      v_TransmissionID VARCHAR(150);
      v_Customer NUMBER;

      l_domdoc dbms_xmldom.DOMDocument;
      l_xmltype XMLTYPE;

      l_root_node dbms_xmldom.DOMNode;

      l_DOCUMENT_INFO_node dbms_xmldom.DOMNode;

      l_EXTENDED_DATA_node dbms_xmldom.DOMNode;

      l_RECIPIENT_INFO_element dbms_xmldom.DOMElement;
      l_RECIPIENT_INFO_node dbms_xmldom.DOMNode;

      l_CASE_ACKN_DETAILS_element dbms_xmldom.DOMElement;
      l_CASE_ACKN_DETAILS_node dbms_xmldom.DOMNode;

      l_SENDER_INFO_element dbms_xmldom.DOMElement;
      l_SENDER_INFO_node dbms_xmldom.DOMNode;

      l_UKID_node dbms_xmldom.DOMNode;
      l_UKID_textnode dbms_xmldom.DOMNode;

      l_AN8_node dbms_xmldom.DOMNode;
      l_AN8_textnode dbms_xmldom.DOMNode;

      l_DOCUMENT_TYPE_node dbms_xmldom.DOMNode;
      l_DOCUMENT_TYPE_textnode dbms_xmldom.DOMNode;

      l_MODULE_node dbms_xmldom.DOMNode;
      l_MODULE_textnode dbms_xmldom.DOMNode;

      l_VERSION_node dbms_xmldom.DOMNode;
      l_VERSION_textnode dbms_xmldom.DOMNode;

      l_TEST_FLAG_node dbms_xmldom.DOMNode;
      l_TEST_FLAG_textnode dbms_xmldom.DOMNode;

      l_TRANSMISSION_DATE_node dbms_xmldom.DOMNode;
      l_TRANSMISSION_DATE_textnode dbms_xmldom.DOMNode;

      l_TRANSMISSION_ID_node dbms_xmldom.DOMNode;
      l_TRANSMISSION_ID_textnode dbms_xmldom.DOMNode;

      l_CUSTOMER_node dbms_xmldom.DOMNode;
      l_CUSTOMER_textnode dbms_xmldom.DOMNode;

      l_MPF_node dbms_xmldom.DOMNode;
      l_MPF_textnode dbms_xmldom.DOMNode;

      l_DESTINATION_ERP_node dbms_xmldom.DOMNode;
      l_DESTINATION_ERP_textnode dbms_xmldom.DOMNode;

      l_COMPANY_node dbms_xmldom.DOMNode;
      l_COMPANY_textnode dbms_xmldom.DOMNode;

      l_ACKN_BRANCH_PLANT_node dbms_xmldom.DOMNode;
      l_ACKN_BRANCH_PLANT_textnode dbms_xmldom.DOMNode;

      l_PLXS_CASE_NUMBER_node dbms_xmldom.DOMNode;
      l_PLXS_CASE_NUMBER_textnode dbms_xmldom.DOMNode;

      l_CUSTOMER_REFERENCE1_node dbms_xmldom.DOMNode;
      l_CUSTOMER_REFERENCE1_textnode dbms_xmldom.DOMNode;

      l_CUSTOMER_REFERENCE2_node dbms_xmldom.DOMNode;
      l_CUSTOMER_REFERENCE2_textnode dbms_xmldom.DOMNode;

      l_CUSTOMER_REFERENCE3_node dbms_xmldom.DOMNode;
      l_CUSTOMER_REFERENCE3_textnode dbms_xmldom.DOMNode;

      l_PLXS_ITEM_NUMBER_node dbms_xmldom.DOMNode;
      l_PLXS_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;

      l_ITEM_DESC_node dbms_xmldom.DOMNode;
      l_ITEM_DESC_textnode dbms_xmldom.DOMNode;

      l_CUSTOMER_ITEM_NUMBER_node dbms_xmldom.DOMNode;
      l_CUSTOMER_ITEM_NUMBER_textnode dbms_xmldom.DOMNode;

      l_CUSTOMER_REV_node dbms_xmldom.DOMNode;
      l_CUSTOMER_REV_textnode dbms_xmldom.DOMNode;

      l_LOT_SERIAL_NUMBER_node dbms_xmldom.DOMNode;
      l_LOT_SERIAL_NUMBER_textnode dbms_xmldom.DOMNode;

      l_QTY_node dbms_xmldom.DOMNode;
      l_QTY_textnode dbms_xmldom.DOMNode;

      l_AREA_TYPE_node dbms_xmldom.DOMNode;
      l_AREA_TYPE_textnode dbms_xmldom.DOMNode;

      l_AREA_DESC_node dbms_xmldom.DOMNode;
      l_AREA_DESC_textnode dbms_xmldom.DOMNode;

      l_STATUS_node dbms_xmldom.DOMNode;
      l_STATUS_textnode dbms_xmldom.DOMNode;

      l_ERROR_MESSAGE_node dbms_xmldom.DOMNode;
      l_ERROR_MESSAGE_textnode dbms_xmldom.DOMNode;

      TEMP_UKID NUMBER;
      TEMP_AN8 NUMBER;
      TEMP_$TRANSID VARCHAR(150);
      TEMP_C75DCT VARCHAR(60);
      TEMP_LRSSM VARCHAR(5);
      TEMP_B76VER NUMBER;
      TEMP_$TSTFLAG VARCHAR(1);
      TEMP_UPMJ VARCHAR(20);
      TEMP_UPMT VARCHAR(20);
      TEMP_ALPH VARCHAR(40);
      TEMP_$MPFNUM VARCHAR(25);
      TEMP_$SRCDEST VARCHAR(50);
      TEMP_$SERMCU VARCHAR(15);
      TEMP_DOCO VARCHAR(8);
      TEMP_RF1 VARCHAR(30);
      TEMP_RF2 VARCHAR(30);
      TEMP_RF3 VARCHAR(30);
      TEMP_LITM VARCHAR(25);
      TEMP_DSC1 VARCHAR(30);
      TEMP_$CUSPRTN VARCHAR(30);
      TEMP_DL03 VARCHAR(30);
      TEMP_LOTN VARCHAR(30);
      TEMP_TRQT NUMBER;
      TEMP_$NOTETYP VARCHAR(100);
      TEMP_GPTX VARCHAR(1500);
      TEMP_STTUS VARCHAR(10);
      TEMP_$VALMSG VARCHAR(2000);

   BEGIN
      --Creates an exmpty XML Document
      l_domdoc := dbms_xmldom.newDOMDocument;

      --Creates a root node
      l_root_node := dbms_xmldom.makeNode(l_domdoc);

      BEGIN

          -- Find first record to be sent
          SELECT sg$transid
                ,sgan8
          INTO v_TransmissionID
          ,v_Customer
          FROM proddta.F58INT11
          WHERE ROWNUM = 1
          AND SGC75DCT = 'Case Acknowledgement'
          AND sg$rsp = 'D'
          AND SGAN8 IN (
                with rws as (
                  select SGAN8_IN as str from dual
                )
                  select regexp_substr (
                           str,
                           '[^|]+',
                           1,
                           level
                         ) value
                  from   rws
                  connect by level <=
                    length ( str ) - length ( replace ( str, '|' ) ) + 1
            )
          --AND sg$transid = 'ACK000000000000234'
          ORDER BY sg$transid;


          --Update record that is being processed
            UPDATE proddta.F58INT11
            SET sg$rsp = 'B'
                ,sguser = 'BIZTALK'
                ,sgupmt = to_char(cast(SYSDATE as date),'hh24miss')
                ,sgupmj = To_Number(To_Char(To_Number(To_Char(sysdate, 'yyyy')) - 1900) || To_Char(sysdate, 'ddd'))
            WHERE sg$transid = v_TransmissionID
            AND sgan8 = v_Customer;
          COMMIT;

          --Create Header or Non-Repeating XML nodes based on one record of the
          --TransmissionID/Customer Number
          FOR AMS_HEADER_REC in
              (SELECT TRIM(sgukid) sgukid
                      ,SGAN8
                      ,TRIM(sg$transid) sg$transid
                      ,TRIM(sgc75dct) sgc75dct
                      ,TRIM(sglrssm) sglrssm
                      ,TRIM(sgb76ver) sgb76ver
                      ,TRIM(sg$tstflag)sg$tstflag
                      ,TRIM(sgupmj) sgupmj
                      ,TRIM(sgupmt) sgupmt
                      ,TRIM(sgalph) sgalph
                      ,TRIM(sg$mpfnum) sg$mpfnum
                      ,TRIM(sg$srcdest) sg$srcdest
               FROM proddta.F58INT11
               WHERE sg$transid = v_TransmissionID
               AND sgan8 = v_Customer
               AND ROWNUM = 1)

              LOOP
                TEMP_UKID := AMS_HEADER_REC.SGUKID;
                TEMP_AN8 := AMS_HEADER_REC.SGAN8;
                TEMP_$TRANSID := AMS_HEADER_REC.SG$TRANSID;
                TEMP_C75DCT := AMS_HEADER_REC.SGC75DCT ;
                TEMP_LRSSM:= AMS_HEADER_REC.SGLRSSM ;
                TEMP_B76VER := AMS_HEADER_REC.SGB76VER;
                TEMP_$TSTFLAG := AMS_HEADER_REC.SG$TSTFLAG;
                TEMP_UPMJ:= AMS_HEADER_REC.SGUPMJ;
                TEMP_UPMT := AMS_HEADER_REC.SGUPMT;
                TEMP_ALPH:= AMS_HEADER_REC.SGALPH;
                TEMP_$MPFNUM:= AMS_HEADER_REC.SG$MPFNUM;
                TEMP_$SRCDEST := ams_header_rec.sg$srcdest;

                 --Create the XML structure for the Header/Non repeating sections
                l_DOCUMENT_INFO_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'DOCUMENT_INFO')));

                l_an8_node := dbms_xmldom.appendChild(l_DOCUMENT_INFO_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AN8' )));
                l_an8_textnode := dbms_xmldom.appendChild( l_an8_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_an8 )));

                l_DOCUMENT_TYPE_node := dbms_xmldom.appendChild(l_DOCUMENT_INFO_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DOCUMENT_TYPE' )));
                l_DOCUMENT_TYPE_textnode := dbms_xmldom.appendChild( l_DOCUMENT_TYPE_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_C75DCT )));

                l_MODULE_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'MODULE' )));
                l_MODULE_textnode := dbms_xmldom.appendChild( l_MODULE_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_LRSSM )));

                l_VERSION_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'VERSION' )));
                l_VERSION_textnode := dbms_xmldom.appendChild( l_VERSION_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_B76VER )));

                l_TEST_FLAG_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                       , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TEST_FLAG' )));
                l_TEST_FLAG_textnode := dbms_xmldom.appendChild( l_TEST_FLAG_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$TSTFLAG)));

                l_TRANSMISSION_DATE_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRANSMISSION_DATE' )));
                l_TRANSMISSION_DATE_textnode := dbms_xmldom.appendChild( l_TRANSMISSION_DATE_node
                                                                , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, to_char(SYS_EXTRACT_UTC(SYSTIMESTAMP),'YYYY-MM-DD"T"HH24:MI:SS.ff3"Z"') )));

                l_TRANSMISSION_ID_node := dbms_xmldom.appendChild( l_DOCUMENT_INFO_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'TRANSMISSION_ID' )));
                l_TRANSMISSION_ID_textnode := dbms_xmldom.appendChild( l_TRANSMISSION_ID_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$TRANSID)));

                l_RECIPIENT_INFO_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'RECIPIENT_INFO')));

                l_CUSTOMER_node := dbms_xmldom.appendChild(l_RECIPIENT_INFO_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER' )));
                l_CUSTOMER_textnode := dbms_xmldom.appendChild( l_CUSTOMER_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_ALPH )));

                l_MPF_node := dbms_xmldom.appendChild(l_RECIPIENT_INFO_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'MPF' )));
                l_MPF_textnode := dbms_xmldom.appendChild( l_MPF_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$MPFNUM)));
                l_DESTINATION_ERP_node := dbms_xmldom.appendChild(l_RECIPIENT_INFO_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'DESTINATION_ERP' )));
                l_DESTINATION_ERP_textnode := dbms_xmldom.appendChild( l_DESTINATION_ERP_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$SRCDEST )));

                l_SENDER_INFO_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'SENDER_INFO')));

                l_COMPANY_node := dbms_xmldom.appendChild(l_SENDER_INFO_node
                                                       , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'COMPANY' )));
                l_COMPANY_textnode := dbms_xmldom.appendChild( l_COMPANY_node
                                                          , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, 'Plexus Corp.' )));
              end loop;

             --Create Detail or repeating section of the XML based on TransmissionID and Customer
           FOR AMS_OUT_REC in
               (SELECT TRIM(sgukid) sgukid
                       ,TRIM(sg$sermcu) sg$sermcu
                       ,TRIM(sgdoco) sgdoco
                       ,TRIM(sgrf1) sgrf1
                       ,TRIM(sgrf2) sgrf2
                       ,TRIM(sgrf3) sgrf3
                       ,TRIM(sglitm) sglitm
                       ,TRIM(sgdsc1) sgdsc1
                       ,TRIM(sg$cusprtn) sg$cusprtn
                       ,TRIM(sgdl03) sgdl03
                       ,TRIM(sg$cuslitm) sg$cuslitm
                       ,TRIM(sglotn) sglotn
                       ,TRIM(sgtrqt) sgtrqt
                       ,TRIM(sg$gs04) sg$gs04
                       ,TRIM(sgsttus) sgsttus
                       ,TRIM(sg$valmsg) sg$valmsg

                FROM proddta.F58INT11
                WHERE sg$transid = v_TransmissionID
                AND sgan8 = v_Customer)

                LOOP

                TEMP_UKID := AMS_OUT_REC.SGUKID;
                TEMP_$SERMCU:= AMS_OUT_REC.SG$SERMCU;
                TEMP_DOCO:= AMS_OUT_REC.SGDOCO;
                TEMP_RF1:= AMS_OUT_REC.SGRF1;
                TEMP_RF2:= AMS_OUT_REC.SGRF2;
                TEMP_RF3:= AMS_OUT_REC.SGRF3;
                TEMP_LITM:= AMS_OUT_REC.SGLITM;
                TEMP_DSC1:= AMS_OUT_REC.SGDSC1;
                TEMP_$CUSPRTN:= AMS_OUT_REC.SG$CUSPRTN;
                TEMP_DL03:= AMS_OUT_REC.SGDL03;
                TEMP_LOTN:= AMS_OUT_REC.SGLOTN;
                TEMP_TRQT := AMS_OUT_REC.SGTRQT;
                TEMP_STTUS := AMS_OUT_REC.Sgsttus;
                TEMP_$VALMSG := AMS_OUT_REC.Sg$valmsg;

                l_CASE_ACKN_DETAILS_node := dbms_xmldom.appendChild(l_root_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'CASE_ACKN_DETAILS')));

                l_ukid_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'UNIQUE_ID' )));
                l_ukid_textnode := dbms_xmldom.appendChild( l_ukid_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_ukid )));

                l_ACKN_BRANCH_PLANT_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ACKN_BRANCH_PLANT' )));
                l_ACKN_BRANCH_PLANT_textnode := dbms_xmldom.appendChild( l_ACKN_BRANCH_PLANT_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$SERMCU )));

                l_PLXS_CASE_NUMBER_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_CASE_NUMBER' )));
                l_PLXS_CASE_NUMBER_textnode := dbms_xmldom.appendChild( l_PLXS_CASE_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_DOCO )));

                l_CUSTOMER_REFERENCE1_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE1' )));
                l_CUSTOMER_REFERENCE1_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REFERENCE1_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_RF1 )));

                l_CUSTOMER_REFERENCE2_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE2' )));
                l_CUSTOMER_REFERENCE2_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REFERENCE2_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_RF2 )));

                l_CUSTOMER_REFERENCE3_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REFERENCE3' )));
                l_CUSTOMER_REFERENCE3_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REFERENCE3_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_RF3 )));

                l_PLXS_ITEM_NUMBER_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'PLXS_ITEM_NUMBER' )));
                l_PLXS_ITEM_NUMBER_textnode := dbms_xmldom.appendChild( l_PLXS_ITEM_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_LITM )));

                l_ITEM_DESC_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ITEM_DESC' )));
                l_ITEM_DESC_textnode := dbms_xmldom.appendChild( l_ITEM_DESC_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_DSC1 )));

                l_CUSTOMER_ITEM_NUMBER_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_ITEM_NUMBER' )));
                l_CUSTOMER_ITEM_NUMBER_textnode := dbms_xmldom.appendChild( l_CUSTOMER_ITEM_NUMBER_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_$CUSPRTN )));

                l_CUSTOMER_REV_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'CUSTOMER_REV' )));
                l_CUSTOMER_REV_textnode := dbms_xmldom.appendChild( l_CUSTOMER_REV_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_DL03 )));

                l_LOT_SERIAL_NUMBER_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'LOT_SERIAL_NUMBER' )));
                l_LOT_SERIAL_NUMBER_textnode := dbms_xmldom.appendChild( l_LOT_SERIAL_NUMBER_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, temp_LOTN )));

                l_QTY_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'QTY' )));
                l_QTY_textnode := dbms_xmldom.appendChild( l_QTY_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_TRQT )));

                l_EXTENDED_DATA_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node,dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc,'EXTENDED_DATA')));

                FOR AMS_OUT_EXT_REC in
               (SELECT TRIM(nt$notetyp ) nt$notetyp
                       ,TRIM(ntgptx) ntgptx
                FROM proddta.f58INT12
                WHERE ntukid = TEMP_UKID
                AND   ntc75dct =  RPAD(TRIM(TEMP_C75DCT),60)
                    )
                LOOP
                TEMP_$notetyp := ams_out_ext_rec.nt$notetyp;
                TEMP_GPTX := ams_out_ext_rec.ntgptx;

                  l_AREA_TYPE_node := dbms_xmldom.appendChild(l_EXTENDED_DATA_node
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AREA_TYPE' )));
                  l_AREA_TYPE_textnode := dbms_xmldom.appendChild( l_AREA_TYPE_node
                                                      , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$notetyp )));

                  l_AREA_DESC_node := dbms_xmldom.appendChild(l_EXTENDED_DATA_node
                                                  , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'AREA_DESC' )));
                  l_AREA_DESC_textnode := dbms_xmldom.appendChild( l_AREA_DESC_node
                                                     , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_GPTX)));
                END LOOP;

                l_STATUS_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'STATUS' )));
                l_STATUS_textnode := dbms_xmldom.appendChild( l_STATUS_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_STTUS )));

                l_ERROR_MESSAGE_node := dbms_xmldom.appendChild(l_CASE_ACKN_DETAILS_node
                                                , dbms_xmldom.makeNode(dbms_xmldom.createElement(l_domdoc, 'ERROR_MESSAGE' )));
                l_ERROR_MESSAGE_textnode := dbms_xmldom.appendChild( l_ERROR_MESSAGE_node
                                                    , dbms_xmldom.makeNode(dbms_xmldom.createTextNode(l_domdoc, TEMP_$VALMSG )));

            END LOOP;

        EXCEPTION
             WHEN OTHERS THEN

             --UPDATE PRODDTA.F58INT11 SET SG$RSP='E' WHERE sg$transid = v_TransmissionID AND sgan8 = v_Customer;
             --COMMIT;

             Temp_RetMsg :='Error: - '||SQLCODE||' -ERROR- '||substr(SQLERRM,1,2000) || ' -TransmissionID - '||NVL(v_TransmissionID, '') ||' -Customer- '||NVL(v_Customer, '');
        END; --END TRANSACTION

        l_xmltype := dbms_xmldom.getXmlType(l_domdoc);
        dbms_xmldom.freeDocument(l_domdoc);

        OUT_CLOBData := l_xmltype.getClobVal;

        OUT_RetMsg :=  Temp_RetMsg;

    END;

end PKG_AMS_OUTBOUND;


1 row selected.

