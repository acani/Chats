-- Create login code with email
CREATE FUNCTION login_post(varchar(254)) RETURNS SETOF smallint AS
$$
    WITH s AS (
        -- Check if user with email already exists
        SELECT 1
        FROM users
        WHERE lower(email) = lower($1)
    ), u AS (
        -- Update login code if exists
        UPDATE login
        SET code = DEFAULT, created_at = DEFAULT
        WHERE EXISTS (SELECT 1 FROM s)
        AND lower(email) = lower($1)
        RETURNING code
    ), i AS (
        -- Else, insert login code
        INSERT INTO login
        SELECT $1
        WHERE EXISTS (SELECT 1 FROM s)
        AND NOT EXISTS (SELECT 1 FROM u)
        RETURNING code
    )
    -- Return login code
    SELECT code FROM u UNION ALL SELECT code FROM i;
$$
LANGUAGE SQL;
