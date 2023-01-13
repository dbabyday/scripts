/*

When a subscription looks okay, but not pulling pending commands from distribution database

-- 1. Refresh subscriptions
	-- Where: At the publisher on the publication database

	-- acc-sql-pd-001
	Use GSF2_APAC_PROD;
	execute sp_refreshsubscriptions @publication='pub_GSF2_APAC_PROD';

-- 2. Check subscriptions status
	-- Where: At the distributor in the distribution database
	-- dbo.MSsubscriptions

-- 3. Update article subscription status if not 'Active'


-- 4. Restart the distribution job on the subscriber 
	-- gcc-sql-pd-019
*/



-- 2. Check subscriptions status
-- Where: At the distributor in the distribution database

-- gcc-sql-pd-007
-- acc-sql-pd-007
-- xia-sql-pd-007

use Gsfdistribution_PROD;

select   sp.name publisher
       , sub.publisher_db
	   , @@servername distributor
	   , db_name() distributor_db
	   , ss.name subscriber
	   , sub.subscriber_db
	   , art.article
	   , art.source_owner+N'.'+art.source_object source_object
	   --, art.destination_object
	   , case sub.subscription_type when 0 then 'Push'
	                                when 1 then 'Pull'
									when 2 then 'Anonymous'
									else 'Unknown...check Microsoft documentation on MSsubscriptions'
	     end subscription_type
	   , case sub.sync_type when 1 then 'Automatic'
	                        when 2 then 'No synchronization'
							else 'Unknown...check Microsoft documentation on MSsubscriptions'
		 end sync_type
	   , case sub.status when 0 then 'Inactive'
	                     when 1 then 'Subscribed'
						 when 2 then 'Active'
						 else 'Unknown...check Microsoft documentation on MSsubscriptions'
	     end status
from     dbo.MSsubscriptions sub
join     dbo.MSarticles      art on art.publisher_id=sub.publisher_id and art.publication_id=sub.publication_id and art.article_id=sub.article_id
join     sys.servers         sp  on sp.server_id=sub.publisher_id
join     sys.servers         ss  on ss.server_id=sub.subscriber_id
--where    sub.status<>2
order by sp.name
       , sub.publisher_db
	   , ss.name
	   , sub.subscriber_db
	   , art.source_owner
	   , art.source_object;