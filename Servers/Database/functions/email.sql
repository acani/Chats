-- Create email code with user_id, session_id, and email
CREATE FUNCTION email_post(bigint, uuid, varchar(254)) RETURNS SETOF smallint AS
$$
    WITH a AS (
        -- Authenticate user
        SELECT 1
        FROM sessions
        WHERE user_id = $1
        AND id = $2
    ), s AS (
        -- Check if user with email already exists
        SELECT (CASE WHEN id = $1 THEN -1 ELSE -2 END)::smallint as e
        FROM users
        WHERE EXISTS (SELECT 1 FROM a)
        AND lower(email) = lower($3)
    ), u AS (
        -- Update email code if exists
        UPDATE email
        SET email = $3, code = DEFAULT, created_at = DEFAULT
        WHERE EXISTS (SELECT 1 FROM a)
        AND NOT EXISTS (SELECT 1 FROM s)
        AND user_id = $1
        RETURNING code
    ), i AS (
        -- Else, insert email code
        INSERT INTO email
        SELECT $3, $1
        WHERE EXISTS (SELECT 1 FROM a)
        AND NOT EXISTS (SELECT 1 FROM s)
        AND NOT EXISTS (SELECT 1 FROM u)
        RETURNING code
    )
    -- Return email code
    SELECT code FROM u UNION ALL SELECT code FROM i UNION ALL SELECT e FROM s;
$$
LANGUAGE SQL;

-- Update email with email & code
CREATE FUNCTION email_put(varchar(254), smallint) RETURNS SETOF varchar(254) AS
$$
    WITH d AS (
        -- Verify email code and then delete
        DELETE FROM email
        WHERE email = $1
        AND code = $2
        RETURNING user_id, created_at
    )
    -- Update user's email
    UPDATE users AS u
    SET email = $1
    FROM d, users AS old
    WHERE age(now(), d.created_at) < '10 minutes'
    AND u.id = old.id
    AND u.id = d.user_id
    RETURNING old.email;
$$
LANGUAGE SQL;
