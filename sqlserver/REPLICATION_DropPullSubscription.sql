
/*

    DROP PULL SUBSCRIPTION

    Ctrl + Shift + m  ----> enter the template parameter values

*/


:CONNECT <Subscriber, SYSNAME, CO-DB-010>
GO

USE [<Subscription DB, SYSNAME, MaxDB>];
EXECUTE sys.sp_droppullsubscription @publisher    = <Publisher, SYSNAME, CO-DB-034>,
                                    @publisher_db = <Publisher DB, SYSNAME, MaxDB>,
                                    @publication  = <Publication, SYSNAME, pub_Maxdb>;
GO



:CONNECT <Publisher, SYSNAME, CO-DB-034>
GO

USE [<Publisher DB, SYSNAME, MaxDB>];
EXECUTE sys.sp_dropsubscription @publication = <Publication, SYSNAME, pub_Maxdb>,
                                @article     = N'all',
                                @subscriber  = <Subscriber, SYSNAME, CO-DB-010>;
GO



