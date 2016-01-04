CREATE TABLE email (
    email varchar(254) NOT NULL,
    user_id bigint UNIQUE NOT NULL REFERENCES users ON DELETE CASCADE,
    code smallint NOT NULL DEFAULT trunc(random()*9999), -- 0...9999
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE UNIQUE INDEX on email (lower(email));
