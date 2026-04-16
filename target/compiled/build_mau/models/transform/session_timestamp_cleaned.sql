SELECT sessionId, ts
FROM USER_DB_FLAMINGO.RAW.session_timestamp
WHERE sessionId IS NOT NULL
