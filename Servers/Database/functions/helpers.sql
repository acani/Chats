-- Strip hyphens ('-') from uuid
CREATE FUNCTION strip_hyphens(uuid) RETURNS char(32) AS
$$
    SELECT replace($1::text, '-', '');
$$
LANGUAGE SQL IMMUTABLE;
