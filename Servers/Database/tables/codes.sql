\c chats

CREATE TABLE codes (
    phone char(10) PRIMARY KEY,
    code smallint NOT NULL DEFAULT trunc(random()*9999), -- 0...9999
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
