\c chats

CREATE TABLE users (
    id bigserial PRIMARY KEY,
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    phone char(10) NOT NULL UNIQUE,
    picture_id uuid,
    first_name varchar(50) NOT NULL CHECK (first_name <> ''),
    last_name varchar(50) NOT NULL CHECK (last_name <> ''),
    email varchar(254) NOT NULL
);
