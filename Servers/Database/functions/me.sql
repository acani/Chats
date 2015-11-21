-- Get user with user_id & session_id
CREATE FUNCTION me_get(bigint, uuid) RETURNS TABLE(u bigint, f varchar(50), l varchar(50), e varchar(254)) AS
$$
    SELECT u.id, first_name, last_name, email
    FROM users u, sessions s
    WHERE u.id = $1
    AND s.user_id = u.id
    AND s.id = $2;
$$
LANGUAGE SQL;

-- Patch user first_name & last_name with user_id & session_id
CREATE FUNCTION me_patch(bigint, uuid, varchar(50), varchar(50)) RETURNS SETOF boolean AS
$$
    WITH s AS (
        -- Authenticate user
        SELECT 1
        FROM sessions
        WHERE user_id = $1
        AND id = $2
    ), u AS (
        UPDATE users
        SET first_name = COALESCE($3, first_name),
            last_name = COALESCE($4, last_name)
        WHERE EXISTS (SELECT 1 FROM s)
        AND id = $1
        -- Avoid an empty UPDATE
        -- http://stackoverflow.com/questions/13305878/dont-update-column-if-update-value-is-null
        AND ($3 IS NOT NULL AND $3 IS DISTINCT FROM first_name OR
             $4 IS NOT NULL AND $4 IS DISTINCT FROM last_name)
        RETURNING 1
    )
    SELECT TRUE WHERE EXISTS (SELECT 1 FROM s)
$$
LANGUAGE SQL;

-- -- Change email with user_id, session_id, and email
-- CREATE FUNCTION email_set(bigint, uuid, text) RETURNS SETOF boolean AS
-- $$
--     WITH s AS (
--         SELECT 1
--         FROM sessions
--         WHERE user_id = $1
--         AND id = $2
--     ), u AS (
--         UPDATE users
--         SET email = $3
--         WHERE EXISTS (SELECT 1 FROM s)
--         AND id = $1
--         AND NOT EXISTS (SELECT 1 FROM users WHERE lower(email) = lower($3) AND id != $1)
--         RETURNING 1
--     )
--     SELECT EXISTS (SELECT 1 FROM u) WHERE EXISTS (SELECT 1 FROM s)
-- $$
-- LANGUAGE SQL;

-- Delete user & related session with user_id & session_id
CREATE FUNCTION me_delete(bigint, uuid) RETURNS SETOF boolean AS
$$
    DELETE FROM users u
    USING sessions s
    WHERE u.id = $1
    AND u.id = s.user_id
    AND s.id = $2
    RETURNING TRUE;
$$
LANGUAGE SQL;
