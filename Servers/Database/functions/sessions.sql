\c chats

-- Authenticate: Get session_id with user_id
CREATE FUNCTION sessions_get(bigint, OUT id char(32)) RETURNS SETOF char(32) AS
$$
    SELECT strip_hyphens(id) FROM sessions WHERE user_id = $1;
$$
LANGUAGE SQL;

-- Log in: Get/create session ID with phone & code
-- Reuse one session per user across multiple devices.
CREATE FUNCTION sessions_post(char(10), smallint) RETURNS TABLE(u bigint, s char(32)) AS
$$
    WITH d AS (
        -- Verify code and then delete
        DELETE FROM codes
        WHERE phone = $1
        AND code = $2
        RETURNING created_at
    ), p AS (
        -- Get user_id with phone
        SELECT id
        FROM users, d
        WHERE EXISTS (SELECT 1 FROM d)
        AND age(now(), d.created_at) < '3 minutes'
        AND phone = $1
    ), g AS (
        -- Get session_id with user_id
        SELECT user_id, strip_hyphens(s.id) as r
        FROM sessions s, p
        WHERE s.user_id = p.id
    ), i AS (
        -- Create session_id if not exists
        INSERT INTO sessions
        SELECT id
        FROM p
        WHERE NOT EXISTS (SELECT 1 FROM g)
        RETURNING user_id, strip_hyphens(id) as r
    )
    SELECT user_id, r FROM g UNION ALL SELECT user_id, r FROM i;
$$
LANGUAGE SQL;

-- Log out: Delete session with user_id & session_id
CREATE FUNCTION sessions_delete(bigint, uuid) RETURNS SETOF boolean AS
$$
    DELETE FROM sessions
    WHERE user_id = $1
    AND id = $2
    RETURNING TRUE;
$$
LANGUAGE SQL;
