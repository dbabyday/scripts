
  CREATE OR REPLACE EDITIONABLE TRIGGER "PRODDTA"."LOFTWARE_CONNECTOR_F5542060" BEFORE
INSERT
OR UPDATE OF "ML$SBKML", "ML$SBOXN", "ML$TBOXS", "ML$TRK", "MLADD1", "MLADD2", "MLADD3", "MLADD4", "MLADD5", "MLADD6", "MLADDJ", "MLADDS", "MLADDZ", "MLALPH", "MLBKML", "MLCOUN", "MLCRRT", "MLCRTE", "MLCTR", "MLCTR2", "MLCTY1", "MLDATE01", "MLDATE02", "MLDCTO", "MLDOCO", "MLDS80", "MLGPSP", "MLIA01", "MLIA02", "MLJOBPRNTR", "MLKCOO", "MLMCU", "MLMLNM", "MLPID", "MLPRP4", "MLPSN", "MLSHL1", "MLSHL2", "MLSHL3", "MLSHL4", "MLSHL5", "MLSHL6", "MLSHZP", "MLTMPL", "MLUAMT01", "MLUAMT02", "MLUDF1", "MLUDF2", "MLUKID", "MLUPMJ", "MLUPMT", "MLUSER", "MLVR01", "MLVR02", "MLVSTCN", "MLVSTCT", "MLVSTST" ON "PRODDTA"."F5542060" FOR EACH ROW   WHEN (new.MLGPSP = 'N') DECLARE
/*--------------------------------------------------------------------------*/
/* -- Update History -- */
/*--------------------------------------------------------------------------*/
/* LP Khor APR 08, 2006 Create new Trigger Script                           */
/*--------------------------------------------------------------------------*/
/* -- Working Parameters -- */
g_crlf char(2) default chr(13)||chr(10);
g_jde_area varchar2(10) := 'PY';   -- This parameter will be used in the directory path in locating the label template.  PD = PRODDTA, PY = PRODDTA or DV for TRNDTA.
g_loftware_server varchar2(100) := 'DOES NOT MATTER';  -- This parameter was intended to verify the server associated with the printer in the f5598001 table. This methodology will not work with multiple LPS servers now being used.  The parameter is still passed to the stored procedure, but no longer used for validation.  tgallen 12/07/04. ***/
/* -- Email Parameters -- */
  g_sender_email    varchar2(500)  := 'lp.khor@plexus.com';
  g_from            varchar2(500)  := 'Loftware Connector F5542060 - ' || g_jde_area;
  g_to              loftware.smtp_mail.array := loftware.smtp_mail.array( 'notify_loftware_ps@plexus.com' );
  g_cc              loftware.smtp_mail.array default loftware.smtp_mail.array('ann.melewski@plexus.com');
  g_bcc             loftware.smtp_mail.array default loftware.smtp_mail.array();
  g_subject         varchar2(255) := ' - Error encountered with Loftware Print Job';
/* -- Loftware Status Parameters -- */
v_statustype varchar2(100);
v_printerstatus varchar2(1000);
v_jobstatus varchar2(1000);
v_lpsprinter varchar2(100);
v_lpsserverid varchar2(100);
v_lpsserveraddress varchar2(100);
v_xml varchar2(4000);
BEGIN
  LOFTWARE.LOFTWARE_MAIL_LABEL.GET_MAILING_DATA
  (
  :new.MLALPH,
  :new.MLADD1,
  :new.MLADD2,
  :new.MLADD3,
  :new.MLADD4,
  :new.MLADD5,
  :new.MLADD6,
  :new.MLCTY1,
  :new.MLADDS,
  :new.MLADDZ,
  :new.MLMLNM,
  :new.MLDOCO,
  :new.MLSHL1,
  :new.MLSHL2,
  :new.MLSHL3,
  :new.MLSHL4,
  :new.MLSHL5,
  :new.MLSHL6,
  :new.MLVSTCT,
  :new.MLSHZP,
  :new.MLVSTST,
  :new.MLDS80,
  :new.MLADDJ,
  :new.MLUDF1,
  :new.MLUDF2,
  g_loftware_server,
  g_jde_area,
  :new.ML$TRK,
  :new.MLPSN,
  :new.ML$SBOXN,
  :new.ML$TBOXS,
  :new.MLVR01,
  :new.MLMCU,
  :new.MLTMPL,
  :new.MLJOBPRNTR,
  v_statustype,
  v_printerstatus,
  v_jobstatus,
  v_lpsprinter,
  v_lpsserverid,
  v_lpsserveraddress,
  v_xml
  );
  if to_char(v_statustype) = 0 then
    :new.MLGPSP := 'Y';
  elsif to_char(v_statustype) = '-1' then
    --*** -1 indicates the Loftware server (co-ap-955) is not to process job.
    --*** Do nothing --
    return;
  else
    --*** Any error not handled at the LPS must be handled at the DB level.
    --*** Most common errors handled here concerning the SML label are...
    --*** sljobprntr = null, sltmpl = null
    --*** Handle error by updating slgpsp = 'E', writing to log table and email. troy.allen
    LOFTWARE.LOFTWARE_SHIP_LABEL.WRITE_ERROR_LOG
    (:new.MLPSN,
    :new.MLMCU,
    :new.MLTMPL,
    :new.MLJOBPRNTR,
    :new.MLDOCO,
    :new.MLUSER,
    v_statustype,
    v_printerstatus,
    v_jobstatus
    );
    if instr(upper(v_jobstatus), 'COMMUNICATION TIMEOUT') > 0 then
    :new.MLGPSP := 'Y';
    else
    :new.MLGPSP := 'E';
    end if;
    begin
    v_xml := replace(v_xml, '<variable', g_crlf || '<variable');
    v_xml := replace(v_xml, '<!DOCTYPE', g_crlf || '<!DOCTYPE');
    v_xml := replace(v_xml, '<label', g_crlf || '<label');
    LOFTWARE.SMTP_MAIL.SEND
    (p_sender_email => g_sender_email,
    p_from => g_from,
    p_to => g_to,
    p_cc => g_cc,
    p_bcc => g_bcc,
    p_subject => rtrim(:new.MLPSN) || g_subject,
    p_body => 'Pick Slip Number (MLPSN): ' || rtrim(:new.MLPSN)
    || g_crlf || 'Template (MLTMPL): ' || :new.MLTMPL
    || g_crlf || 'Printer (MLJOBPRNTR): ' || :new.MLJOBPRNTR
    || g_crlf || 'Document Nbr (MLDOCO): ' || :new.MLDOCO
    || g_crlf || 'Printed By (MLUSER): ' || :new.MLUSER
    || g_crlf || 'Printed flag (MLGPSP): ' || :new.MLGPSP
    || g_crlf || 'LPS Server ID: ' || v_lpsserverid
    || g_crlf || 'LPS Server Address: ' || v_lpsserveraddress
    || g_crlf || 'LPS Printer: ' || v_lpsprinter
    || g_crlf || 'Job Status Type: ' || v_statustype
    || g_crlf || 'Job Printer Status: ' || v_printerstatus
    || g_crlf || 'Job Status: ' || v_jobstatus
    || g_crlf || ' '
    || g_crlf || 'XML String: '
    || g_crlf || v_xml
    );
    exception
      when others then
        null;
    end;
  end if;
  exception
    when no_data_found then
      null; /* Do nothing for now. */
    when too_many_rows then
      null; /* Do nothing for now. */
    /*when others then
      null; Do nothing for now. */
END;

ALTER TRIGGER "PRODDTA"."LOFTWARE_CONNECTOR_F5542060" ENABLE

