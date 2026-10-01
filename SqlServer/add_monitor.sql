/*

https://github.com/dbabyday
Warranty: The software is provided "AS IS", without warranty of any kind

Name: add_monitor.sql
Description: monitor the Automatic Database Deployment (ADD) progress

run on ssis servers

*/

use CentralAdmin

-- List the scripts to be executed and where
select
	  r.Code
	--, r.ReleaseId
	, r.DatePlanned
	, s.ScriptName
	--, fc.FolderName
	, sc.ServerName
from
	Deployment.Release r
join
	Deployment.Script s on s.ReleaseId=r.ReleaseId
join
	Deployment.FolderServerMapping fsm on fsm.FolderServerMappingId=s.FolderServerMappingId
join
	Deployment.FolderConfiguration fc on fc.FolderConfigurationId=fsm.FolderConfigurationId
join
	Deployment.ServerConfiguration sc on sc.ServerConfigurationId=fsm.ServerConfigurationId
where
	r.DatePlanned > getdate()-1
order by
	  s.ScriptName
	, sc.ServerName;


-- get the script execution audit
select
	  r.Code
	--, r.ReleaseId
	, r.DatePlanned
	, sa.DateExecuted
	, s.ScriptName
	, sa.IsSuccess
	, sa.ErrorMessage
from
	Deployment.Release r
join
	Deployment.Script s on s.ReleaseId=r.ReleaseId
join
	Deployment.ScriptAudit sa on sa.ScriptId=s.ScriptId
where
	r.DatePlanned > getdate()-1
order by
	  sa.DateExecuted
	, s.ScriptId;


-- get the release audit
select
	  r.Code
	--, r.ReleaseId
	, r.DatePlanned
	, ra.DateExecuted
	, ra.Message
from
	Deployment.Release r
join
	Deployment.ReleaseAudit ra on ra.ReleaseId=r.ReleaseId
where
	r.DatePlanned > getdate()-1
order by
	  ra.DateExecuted
	, ra.AuditId;