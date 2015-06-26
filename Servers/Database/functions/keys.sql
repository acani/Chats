\c chats

-- Update/create key with phone & code
CREATE FUNCTION keys_post(char(10), smallint) RETURNS SETOF char(32) AS
$$
    WITH d AS (
        -- Delete matching phone & code
        DELETE FROM codes
        WHERE phone = $1
        AND code = $2
        RETURNING created_at
    ), t AS (
        -- Confirm that code is still fresh
        SELECT 1
        FROM d
        WHERE age(now(), d.created_at) < '3 minutes'
    ), u AS (
        -- If phone exists, update its key
        UPDATE keys
        SET key = DEFAULT, created_at = DEFAULT
        WHERE EXISTS (SELECT 1 FROM t)
        AND phone = $1
        RETURNING strip_hyphens(key) as k
    ), i AS (
        -- Else, create key with phone
        INSERT INTO keys
        SELECT $1
        FROM t
        WHERE NOT EXISTS (SELECT 1 FROM u)
        RETURNING strip_hyphens(key) as k
    )
    SELECT k FROM u UNION ALL SELECT k FROM i;
$$
LANGUAGE SQL;
