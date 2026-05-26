-- Bảng sản phẩm
CREATE TABLE products (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          VARCHAR(100)  NOT NULL,
  description   TEXT,
  price         DECIMAL(15,0) NOT NULL,
  quantity      INTEGER       DEFAULT 0,
  image_url     TEXT,
  qr_code       TEXT,            -- Lưu data encode vào QR (URL product)
  is_out_of_stock   BOOLEAN DEFAULT FALSE,
  is_unavailable    BOOLEAN DEFAULT FALSE,
  created_at    TIMESTAMPTZ   DEFAULT NOW(),
  updated_at    TIMESTAMPTZ   DEFAULT NOW()
);

-- Bảng đơn hàng
CREATE TABLE orders (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id    UUID REFERENCES products(id),
  product_name  VARCHAR(100) NOT NULL,
  quantity      INTEGER      NOT NULL DEFAULT 1,
  amount_due    DECIMAL(15,0) NOT NULL,   -- Giá × số lượng
  discount      DECIMAL(15,0) DEFAULT 0,
  amount_paid   DECIMAL(15,0) NOT NULL,
  debt          DECIMAL(15,0) DEFAULT 0,  -- = 0 nếu âm
  total_revenue DECIMAL(15,0) NOT NULL,
  created_at    TIMESTAMPTZ   DEFAULT NOW()
);

-- Bảng công nợ
CREATE TABLE debts (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id      UUID REFERENCES orders(id),  -- Trích từ đơn hàng
  name          VARCHAR(100) NOT NULL,        -- User nhập tay
  debt_amount   DECIMAL(15,0) NOT NULL,       -- Từ cột công nợ của orders
  amount_paid   DECIMAL(15,0) DEFAULT 0,
  discount      DECIMAL(15,0) DEFAULT 0,
  total_revenue DECIMAL(15,0) DEFAULT 0,
  created_at    TIMESTAMPTZ   DEFAULT NOW(),
  updated_at    TIMESTAMPTZ   DEFAULT NOW()
);