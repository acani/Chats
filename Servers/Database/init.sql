DROP DATABASE IF EXISTS acani_chats_:env;
CREATE DATABASE acani_chats_:env;

\c acani_chats_:env

CREATE EXTENSION "uuid-ossp";
