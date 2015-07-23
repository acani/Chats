\c chats

CREATE TABLE keys (
    phone char(10) PRIMARY KEY,
    key uuid NOT NULL DEFAULT uuid_generate_v4(),
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
