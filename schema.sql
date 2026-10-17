-- BorrowCircle schema. Requires MySQL 8.0.16+ (CHECK constraints are enforced).
-- Run: mysql -u root -p < schema.sql

CREATE DATABASE IF NOT EXISTS borrowcircle
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE borrowcircle;

CREATE TABLE users (
  id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name          VARCHAR(80)  NOT NULL,
  email         VARCHAR(190) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  neighbourhood VARCHAR(80)  NOT NULL,          -- area only, never a home address
  role          ENUM('member','admin') NOT NULL DEFAULT 'member',
  email_verified TINYINT(1) NOT NULL DEFAULT 0,
  is_suspended   TINYINT(1) NOT NULL DEFAULT 0,
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE categories (
  id   TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(40) NOT NULL UNIQUE
) ENGINE=InnoDB;

CREATE TABLE items (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  owner_id     INT UNSIGNED NOT NULL,
  category_id  TINYINT UNSIGNED NOT NULL,
  title        VARCHAR(80)  NOT NULL,
  description  VARCHAR(300) NOT NULL DEFAULT '',
  pickup_area  VARCHAR(80)  NOT NULL,           -- neighbourhood or public pickup point
  est_price    DECIMAL(10,2) NOT NULL DEFAULT 0, -- owner's new-price estimate, used for impact estimate
  price_per_day DECIMAL(10,2) NOT NULL DEFAULT 0, -- rent charged per day
  image_url    VARCHAR(500) NULL,
  is_active    TINYINT(1) NOT NULL DEFAULT 1,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (owner_id)    REFERENCES users(id)      ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(id),
  INDEX idx_items_search (is_active, category_id),
  FULLTEXT KEY ft_items (title, description)
) ENGINE=InnoDB;

CREATE TABLE loans (
  id           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  item_id      INT UNSIGNED NOT NULL,
  borrower_id  INT UNSIGNED NOT NULL,
  start_date   DATE NOT NULL,
  end_date     DATE NOT NULL,
  status       ENUM('requested','approved','collected','returned','declined','cancelled')
               NOT NULL DEFAULT 'requested',
  price_per_day DECIMAL(10,2) NOT NULL DEFAULT 0, -- snapshot at request time
  total_price   DECIMAL(10,2) NOT NULL DEFAULT 0, -- price_per_day x days
  collected_at DATETIME NULL,
  returned_at  DATETIME NULL,
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (item_id)     REFERENCES items(id) ON DELETE CASCADE,
  FOREIGN KEY (borrower_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_dates CHECK (end_date >= start_date),
  INDEX idx_loans_item (item_id, status, start_date, end_date),
  INDEX idx_loans_borrower (borrower_id, status)
) ENGINE=InnoDB;

CREATE TABLE reports (
  id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  reporter_id      INT UNSIGNED NOT NULL,
  reported_user_id INT UNSIGNED NULL,
  item_id          INT UNSIGNED NULL,
  loan_id          INT UNSIGNED NULL,
  reason           VARCHAR(300) NOT NULL,
  status           ENUM('open','reviewed','dismissed') NOT NULL DEFAULT 'open',
  reviewed_by      INT UNSIGNED NULL,
  resolved_at      DATETIME NULL,
  resolution_note  VARCHAR(300) NULL,
  ai_severity      ENUM('low','medium','high') NULL,  -- AI triage (advisory)
  ai_summary       VARCHAR(300) NULL,
  ai_action        VARCHAR(300) NULL,
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (reporter_id)      REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (reported_user_id) REFERENCES users(id) ON DELETE SET NULL,
  FOREIGN KEY (item_id)          REFERENCES items(id) ON DELETE SET NULL,
  FOREIGN KEY (loan_id)          REFERENCES loans(id) ON DELETE SET NULL,
  FOREIGN KEY (reviewed_by)      REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

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

-- AI-checked listing drafts. POST /api/items only accepts a draft_id from here,
-- so a listing cannot be created without the AI analysing the photo first.
CREATE TABLE ai_drafts (
  id         CHAR(32) PRIMARY KEY,
  user_id    INT UNSIGNED NOT NULL,
  draft      JSON NOT NULL,
  image_url  VARCHAR(500) NULL,
  used_at    DATETIME NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

INSERT INTO categories (name) VALUES
 ('Tools'),('Travel'),('Kitchen'),('Study'),('Home'),('Party'),('Sewing');
