SELECT u.*, s.ts
FROM {{ ref("user_session_channel_cleaned") }} u JOIN {{ ref("session_timestamp_cleaned") }} s
ON u.sessionId = s.sessionId
