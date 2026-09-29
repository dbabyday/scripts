USE Operational_Reporting_PROD;



SELECT TOP(100)
	  ua.UserName
	, ua.ActiveDirectoryUserName
	, rn.Value AS ReportName
	, ra.ReportParameter
	, ra.ReportStatus
	, ra.IsActive
	, TODATETIMEOFFSET(ra.DateCreated, '-00:00') AT TIME ZONE 'Central Standard Time' AS DateCreated
	, TODATETIMEOFFSET(ra.DateModified, '-00:00') AT TIME ZONE 'Central Standard Time' AS DateModified
	, TODATETIMEOFFSET(ra.DateTimeJobStart, '-00:00') AT TIME ZONE 'Central Standard Time' AS DateTimeJobStart
	, TODATETIMEOFFSET(ra.DateTimeJobEnd, '-00:00') AT TIME ZONE 'Central Standard Time' AS DateTimeJobEnd
	, CentralAdmin.dbo.GetTimeDifferenceFormatted(ra.DateCreated,ra.DateModified) AS RunTime
	, CentralAdmin.dbo.GetTimeDifferenceFormatted(ra.DateTimeJobStart,ra.DateTimeJobEnd) AS JobRunTime
	--, CentralAdmin.dbo.GetTimeDifferenceFormatted(ra.DateCreated,GETUTCDATE()) AS TimeSinceRequest
	--, CentralAdmin.dbo.GetTimeDifferenceFormatted(ra.DateModified,GETUTCDATE()) AS TimeSinceModified
	--, DATEDIFF(HOUR,ra.DateCreated,ra.DateModified) as HoursRunTime
	--, DATEDIFF(HOUR,ra.DateTimeJobStart,ra.DateTimeJobEnd) as HoursJobRunTime
FROM
	Report.Adapter AS ra
INNER JOIN
	dbo.utf_SMTLocalizedReferenceBySelector('en-US','ReportName') AS rn ON rn.ReferenceId=ra.ReferenceIdReportName
INNER JOIN
	GlobalReference.syn_UserAccount AS ua ON ua.UserAccountId=ra.UserAccountIdCreatedBy
--WHERE
	--DATEDIFF(MINUTE,ra.DateTimeJobStart,ra.DateTimeJobEnd) > 60  /* JobRunTime */
	--ra.IsActive = 1   /* 1 => running, 0 => old reports */
	--ra.ReportStatus = 'Error'
ORDER BY
	ra.DateCreated DESC;

