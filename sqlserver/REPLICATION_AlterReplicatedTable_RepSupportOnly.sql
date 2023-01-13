


USE MaxDb;

-- CTASK047760
EXECUTE sys.sp_dropsubscription @publication = N'pub_Maxdb'
                              , @article     = N'Sites'
                              , @subscriber  = N'all';

-- CTASK047760
EXECUTE sys.sp_droparticle @publication = N'pub_Maxdb',
                           @article = N'Sites';


/****** MAKE TABLE CHANGES ******/


-- CTASK047760
EXECUTE sys.sp_addarticle @publication                   = N'pub_Maxdb'
                        , @article                       = N'Sites'
                        , @source_owner                  = N'dbo'
                        , @source_object                 = N'Sites'
                        , @type                          = N'logbased'
                        , @description                   = N''
                        , @creation_script               = N''
                        , @pre_creation_cmd              = N'none'
                        , @schema_option                 = 0x000000010203008F
                        , @identityrangemanagementoption = N'none'
                        , @destination_table             = N'Sites'
                        , @destination_owner             = N'dbo'
                        , @status                        = 24
                        , @vertical_partition            = N'false'
                        , @ins_cmd                       = N'CALL [dbo].[sp_MSins_dboSites]'
                        , @del_cmd                       = N'CALL [dbo].[sp_MSdel_dboSites]'
                        , @upd_cmd                       = N'SCALL [dbo].[sp_MSupd_dboSites]';

-- CTASK047760
EXECUTE sys.sp_refreshsubscriptions @publication = N'pub_Maxdb';





