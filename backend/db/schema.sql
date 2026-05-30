-- ── Users ─────────────────────────────────────────────────
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username      VARCHAR(50)  UNIQUE NOT NULL,
  password_hash TEXT         NOT NULL,
  role          VARCHAR(20)  DEFAULT 'staff', -- 'admin' | 'staff'
  full_name     VARCHAR(100),
  is_active     BOOLEAN      DEFAULT TRUE,
  last_login    TIMESTAMPTZ,
  created_at    TIMESTAMPTZ  DEFAULT NOW(),
  updated_at    TIMESTAMPTZ  DEFAULT NOW()
);

-- Tạo admin mặc định (password: admin123)
INSERT INTO users (username, password_hash, role, full_name)
VALUES ('admin',
  '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
  'admin', 'Quản Trị Viên')
ON CONFLICT (username) DO NOTHING;

-- ── Products ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name             VARCHAR(100) NOT NULL,
  description      TEXT,
  price            DECIMAL(15,0) NOT NULL,
  quantity         INTEGER DEFAULT 0,
  image_url        TEXT,
  qr_code          TEXT,
  is_out_of_stock  BOOLEAN DEFAULT FALSE,
  is_unavailable   BOOLEAN DEFAULT FALSE,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ── Orders ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id    UUID REFERENCES products(id),
  product_name  VARCHAR(100) NOT NULL,
  quantity      INTEGER NOT NULL DEFAULT 1,
  amount_due    DECIMAL(15,0) NOT NULL,
  discount      DECIMAL(15,0) DEFAULT 0,
  amount_paid   DECIMAL(15,0) NOT NULL,
  debt          DECIMAL(15,0) DEFAULT 0,
  total_revenue DECIMAL(15,0) NOT NULL,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ── Debts ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS debts (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id      UUID REFERENCES orders(id),
  name          VARCHAR(100) NOT NULL,
  debt_amount   DECIMAL(15,0) NOT NULL,
  amount_paid   DECIMAL(15,0) DEFAULT 0,
  discount      DECIMAL(15,0) DEFAULT 0,
  total_revenue DECIMAL(15,0) DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);