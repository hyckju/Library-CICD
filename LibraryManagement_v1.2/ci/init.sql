CREATE TABLE IF NOT EXISTS users (
    user_id  VARCHAR(64)  PRIMARY KEY,
    password VARCHAR(128) NOT NULL,
    type     VARCHAR(16)  NOT NULL
);

CREATE TABLE IF NOT EXISTS books (
    book_id      INT          PRIMARY KEY,
    title        VARCHAR(255) NOT NULL,
    author       VARCHAR(255) NOT NULL,
    is_available BOOLEAN      NOT NULL DEFAULT TRUE,
    member_id    VARCHAR(64),
    FOREIGN KEY (member_id) REFERENCES users(user_id) ON DELETE SET NULL
);

INSERT INTO users (user_id, password, type) VALUES ('admin', '1111', 'ADMIN')
    ON DUPLICATE KEY UPDATE password = VALUES(password), type = VALUES(type);
INSERT INTO users (user_id, password, type) VALUES ('user', '2222', 'USER')
    ON DUPLICATE KEY UPDATE password = VALUES(password), type = VALUES(type);
