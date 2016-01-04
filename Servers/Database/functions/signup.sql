-- Create signup code with first_name, last_name, and email
CREATE FUNCTION signup_post(varchar(50), varchar(50), varchar(254)) RETURNS SETOF smallint AS
$$
    WITH s AS (
        -- Check if user with email already exists
        SELECT 1
        FROM users
        WHERE lower(email) = lower($3)
    ), u AS (
        -- Update signup code if exists
        UPDATE signup
        SET first_name = $1, last_name = $2, code = DEFAULT, created_at = DEFAULT
        WHERE NOT EXISTS (SELECT 1 FROM s)
        AND lower(email) = lower($3)
        RETURNING code
    ), i AS (
        -- Else, insert signup code
        INSERT INTO signup
        SELECT $1, $2, $3
        WHERE NOT EXISTS (SELECT 1 FROM s)
        AND NOT EXISTS (SELECT 1 FROM u)
        RETURNING code
    )
    -- Return signup code
    SELECT code FROM u UNION ALL SELECT code FROM i;
$$
LANGUAGE SQL;
