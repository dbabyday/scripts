/*

    SQL Monitor Alert
    Metric Name: Untransfered GSF Containers
    Description: This alert monitors the untransfered containers count
    Alert threshold: 40
    Alert title: Over_40_UnShook_Containers

*/
IF LOWER(@@SERVERNAME) != N'co-db-051\oltp01' 
BEGIN
    RAISERROR('wrong server - setting NOEXEC ON',16,1) WITH NOWAIT;
    SET NOEXEC ON;
END

select 
	COUNT(*) as [NotShookCount]
from
	GSF2_AMER_PROD.ProductionControl.HandshakeHeader as hh 
	inner join GSF2_AMER_PROD.ProductionControl.HandshakeDetail as hd on hh.HandshakeHeaderId=hd.HandShakeHeaderId 
	inner join GSF2_AMER_PROD.ProductionControl.ContainerDetail as cd on cd.ContainerHeaderId=hd.ContainerHeaderId and cd.DateEffectiveOut>'9999'
	inner join GSF2_AMER_PROD.dbo.utf_LocalizedReferenceBySelector('en-US','ContainerStatus')as cs on cd.ReferenceIdContainerStatus=cs.ReferenceId
	inner join GSF2_AMER_PROD.dbo.utf_LocalizedReferenceBySelector('en-US','ContainerState')as cstate on cd.ReferenceIdContainerState=cstate.ReferenceId
where
	1=1
	and cstate.Value <> 'OOBA'
	and cs.Value <>'Cancelled'
	and (hh.DateJdeTransferStart is null  or hh.DateJdeTransferEnd is null)
	and hd.DateEffectiveOut>'9999';