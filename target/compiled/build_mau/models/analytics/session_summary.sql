with __dbt__cte__user_session_channel_cleaned as (
SELECT userId, sessionId, channel
FROM USER_DB_FLAMINGO.RAW.user_session_channel
WHERE sessionId IS NOT NULL
),  __dbt__cte__session_timestamp_cleaned as (
SELECT sessionId, ts
FROM USER_DB_FLAMINGO.RAW.session_timestamp
WHERE sessionId IS NOT NULL
) SELECT u.*, s.ts
FROM __dbt__cte__user_session_channel_cleaned u JOIN __dbt__cte__session_timestamp_cleaned s
ON u.sessionId = s.sessionId
