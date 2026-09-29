
select
	  sort_order
	, which_one
	, desired_state_desc
	, stale_query_threshold_days
	, flush_interval_seconds
	, max_storage_size_mb
	, interval_length_minutes
	, query_capture_mode_desc
	, size_based_cleanup_mode_desc
	, max_plans_per_query
from
	(values (
		  1
		, 'expected'
		, 'READ_WRITE'
		, 30
		, 900
		, 2000
		, 60
		, 'AUTO'
		, 'AUTO'
		, 200
	)) as expected (
		  sort_order
		, which_one
		, desired_state_desc
		, stale_query_threshold_days
		, flush_interval_seconds
		, max_storage_size_mb
		, interval_length_minutes
		, query_capture_mode_desc
		, size_based_cleanup_mode_desc
		, max_plans_per_query
	)
union all
select
	  2 as sort_order
	, DB_NAME() which_one
	, desired_state_desc
	, stale_query_threshold_days
	, flush_interval_seconds
	, max_storage_size_mb
	, interval_length_minutes
	, query_capture_mode_desc
	, size_based_cleanup_mode_desc
	, max_plans_per_query
from
	sys.database_query_store_options
order by
	sort_order;