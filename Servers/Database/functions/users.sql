-- Get all users
CREATE FUNCTION users_get() RETURNS TABLE(u bigint, f varchar(50), l varchar(50)) AS
$$
    SELECT id, first_name, last_name
    FROM users
    LIMIT 20;
$$
LANGUAGE SQL STABLE;

-- Sign up: Create user & session with email & code
CREATE FUNCTION users_post(varchar(254), smallint) RETURNS TABLE(u bigint, s char(32)) AS
$$
    WITH d AS (
        -- Delete matching email & code
        DELETE FROM signup
        WHERE email = $1
        AND code = $2
        RETURNING first_name, last_name, created_at
    ), s AS (
        -- Confirm that code is still fresh
        SELECT 1
        FROM d
        WHERE age(now(), d.created_at) < '10 minutes'
    ), u AS (
        -- Create user with first_name, last_name, and email
        INSERT INTO users (first_name, last_name, email)
        SELECT first_name, last_name, $1
        FROM d
        WHERE EXISTS (SELECT 1 FROM s)
        RETURNING id
    )
    -- Create session with user_id
    INSERT INTO sessions
    SELECT id FROM u
    WHERE EXISTS (SELECT 1 FROM u)
    RETURNING user_id, strip_hyphens(id);
$$
LANGUAGE SQL;
