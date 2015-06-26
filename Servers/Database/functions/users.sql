\c chats

-- Get all users
CREATE FUNCTION users_get() RETURNS TABLE(u bigint, p char(32), f varchar(50), l varchar(50)) AS
$$
    SELECT id, strip_hyphens(picture_id), first_name, last_name
    FROM users
    LIMIT 20;
$$
LANGUAGE SQL STABLE;

-- Sign up: Create user & session with phone, key, first_name, last_name, and email
CREATE FUNCTION users_post(char(10), uuid, varchar(50), varchar(50), varchar(254)) RETURNS SETOF bigint AS
$$
    WITH d AS (
        -- Delete matching phone & key
        DELETE FROM keys
        WHERE phone = $1
        AND key = $2
        RETURNING key
    ), u AS (
        -- Create user with phone, first_name, and last_name
        INSERT INTO users (phone, first_name, last_name, email)
        SELECT $1, $3, $4, $5
        FROM d
        RETURNING id
    )
    -- Create session with user_id & id
    INSERT INTO sessions
    SELECT id, key FROM u, d
    RETURNING user_id;
$$
LANGUAGE SQL;
