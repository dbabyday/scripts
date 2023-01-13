
########################################################################################
#
# cnotshookcount.ps1
#
# Purpose: Query GSF transactional databases to get quantity of "unshook" containers.
#          This is an indication of how far behind the shipping staging ssis jobs are.
#
# Note: SSIS jobs are on co-db-032
#           PackageGsfToJdeShippingStaging_AMER
#           PackageGsfToJdeShippingStagingBase_APAC
#           PackageGsfToJdeShippingStagingBase_XIAM
#
########################################################################################



$amer_instance="gcc-sql-pd-023\oltp01"
$amer_db="gsf2_amer_prod"

$apac_instance="ACC-SQL-PD-001"
$apac_db="gsf2_apac_prod"

$xiam_instance="XIA-SQL-PD-011\OLTP01"
$xiam_db="gsf2_xiam_prod"

$query="
set nocount on;
select     left(@@servername,25) as ServerName
         , left(db_name(),15)    as DbName
         , count(*)              as NotShookCount
from       ProductionControl.HandshakeHeader as hh 
inner join ProductionControl.HandshakeDetail as hd on hh.HandshakeHeaderId=hd.HandShakeHeaderId 
inner join ProductionControl.ContainerDetail as cd on cd.ContainerHeaderId=hd.ContainerHeaderId and cd.DateEffectiveOut>'9999'
inner join dbo.utf_LocalizedReferenceBySelector('en-US','ContainerStatus')as cs on cd.ReferenceIdContainerStatus=cs.ReferenceId
inner join dbo.utf_LocalizedReferenceBySelector('en-US','ContainerState')as cstate on cd.ReferenceIdContainerState=cstate.ReferenceId
where      cstate.Value <> 'OOBA'
           and cs.Value <>'Cancelled'
           and (hh.DateJdeTransferStart is null  or hh.DateJdeTransferEnd is null)
           and hd.DateEffectiveOut>'9999'"

Write-Host ""
sqlcmd -S $amer_instance -d $amer_db -Q $query
Write-Host ""
sqlcmd -S $apac_instance -d $apac_db -Q $query
Write-Host ""
sqlcmd -S $xiam_instance -d $xiam_db -Q $query
Write-Host ""

