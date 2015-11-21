CREATE TABLE sessions (
    user_id bigint PRIMARY KEY REFERENCES users ON DELETE CASCADE,
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
);
