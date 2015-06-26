\c chats

-- Enter phone: Create code
CREATE FUNCTION codes_post(char(10)) RETURNS TABLE(e boolean, c smallint) AS
$$
    WITH u AS (
        -- Update code if there's one
        UPDATE codes c
        SET code = DEFAULT, created_at = DEFAULT
        WHERE phone = $1
        RETURNING code
    ), i AS (
        -- Else, insert code
        INSERT INTO codes
        SELECT $1
        WHERE NOT EXISTS (SELECT 1 FROM u)
        RETURNING code
    ), c AS (
        -- Get the code
        SELECT code FROM u UNION ALL SELECT code FROM i
    )
    SELECT (SELECT TRUE FROM users WHERE phone = $1), code FROM c;
$$
LANGUAGE SQL;
