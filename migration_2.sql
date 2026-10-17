USE borrowcircle;
-- Run ONCE on an existing database (after migration.sql).
ALTER TABLE users ADD COLUMN email_verified TINYINT(1) NOT NULL DEFAULT 0 AFTER role,
                  ADD COLUMN is_suspended   TINYINT(1) NOT NULL DEFAULT 0 AFTER email_verified;
UPDATE users SET email_verified=1;  -- accounts that already exist predate verification

ALTER TABLE reports
  ADD COLUMN reported_user_id INT UNSIGNED NULL AFTER reporter_id,
  ADD COLUMN loan_id          INT UNSIGNED NULL AFTER item_id,
  ADD COLUMN reviewed_by      INT UNSIGNED NULL,
  ADD COLUMN resolved_at      DATETIME NULL,
  ADD COLUMN resolution_note  VARCHAR(300) NULL,
  ADD FOREIGN KEY (reported_user_id) REFERENCES users(id) ON DELETE SET NULL,
  ADD FOREIGN KEY (loan_id)          REFERENCES loans(id) ON DELETE SET NULL,
  ADD FOREIGN KEY (reviewed_by)      REFERENCES users(id) ON DELETE SET NULL;

CREATE TABLE loan_events (
  id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  loan_id     INT UNSIGNED NOT NULL,
  from_status ENUM('requested','approved','collected','returned','declined','cancelled') NULL,
  to_status   ENUM('requested','approved','collected','returned','declined','cancelled') NOT NULL,
  actor_id    INT UNSIGNED NULL,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (loan_id)  REFERENCES loans(id) ON DELETE CASCADE,
  FOREIGN KEY (actor_id) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_events_loan (loan_id, id)
) ENGINE=InnoDB;

CREATE TABLE auth_tokens (
  id         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id    INT UNSIGNED NOT NULL,
  kind       ENUM('verify','reset') NOT NULL,
  token_hash CHAR(64) NOT NULL UNIQUE,      -- SHA-256; the raw token is only in the email
  expires_at DATETIME NOT NULL,
  used_at    DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Give existing loans a starting history entry.
INSERT INTO loan_events (loan_id,from_status,to_status,actor_id,created_at)
  SELECT id,NULL,status,borrower_id,created_at FROM loans;
