const express = require('express');
const cors    = require('cors');
const { Pool } = require('pg');
const QRCode  = require('qrcode');
const { v4: uuidv4 } = require('uuid');
const jwt     = require('jsonwebtoken'); // Đã thêm thư viện tạo mã token xác thực

const app  = express();
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

app.use(cors());
app.use(express.json());

// Khóa bí mật dùng để ký và xác thực token JWT
const JWT_SECRET = 'SUPER_SECRET_KEY_SHOP_UT_THAO';

// ═══════════════════════════════════════════════
// AUTHENTICATION (MỚI BỔ SUNG)
// ═══════════════════════════════════════════════

app.post('/api/auth/login', async (req, res) => {
  const { username, password } = req.body;

  try {
    // Kiểm tra tài khoản admin (Bạn có thể sửa lại thông tin này cho phù hợp)
    if (username === 'admin' && password === 'admin123') {
      // Tạo token JWT có thời hạn sử dụng là 24 giờ
      const token = jwt.sign({ username }, JWT_SECRET, { expiresIn: '24h' });
      
      return res.json({
        success: true,
        message: 'Đăng nhập thành công',
        token: token
      });
    }

    return res.status(401).json({ 
      success: false, 
      message: 'Tài khoản hoặc mật khẩu không chính xác' 
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
});

// ═══════════════════════════════════════════════
// PRODUCTS (GIỮ NGUYÊN)
// ═══════════════════════════════════════════════

// Lấy tất cả sản phẩm
app.get('/api/products', async (req, res) => {
  const { rows } = await pool.query(
    'SELECT * FROM products WHERE is_unavailable = FALSE ORDER BY created_at DESC'
  );
  res.json(rows);
});

// Thêm sản phẩm mới → tự động tạo mã QR
app.post('/api/products', async (req, res) => {
  const { name, description, price, quantity, image_url } = req.body;
  const id = uuidv4();
  
  // Mã QR chứa URL tới trang thông tin sản phẩm
  const qrData = `${process.env.APP_URL}/product/${id}`;
  const qrCode = await QRCode.toDataURL(qrData);

  const { rows } = await pool.query(
    `INSERT INTO products (id, name, description, price, quantity, image_url, qr_code)
     VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING *`,
    [id, name, description, price, quantity, image_url, qrData]
  );
  
  res.status(201).json({ ...rows[0], qr_image: qrCode });
});

// Cập nhật sản phẩm
app.put('/api/products/:id', async (req, res) => {
  const { name, description, price, quantity, image_url,
          is_out_of_stock, is_unavailable } = req.body;
  const { rows } = await pool.query(
    `UPDATE products SET
       name=$2, description=$3, price=$4, quantity=$5,
       image_url=$6, is_out_of_stock=$7, is_unavailable=$8,
       updated_at=NOW()
     WHERE id=$1 RETURNING *`,
    [req.params.id, name, description, price, quantity,
     image_url, is_out_of_stock, is_unavailable]
  );
  res.json(rows[0]);
});

// Lấy thông tin sản phẩm (khi quét QR trên mobile)
app.get('/api/products/:id', async (req, res) => {
  const { rows } = await pool.query(
    'SELECT * FROM products WHERE id=$1 AND is_unavailable=FALSE',
    [req.params.id]
  );
  if (!rows[0]) return res.status(404).json({ error: 'Không tìm thấy sản phẩm' });
  res.json(rows[0]);
});

// Lấy ảnh QR để xuất PDF
app.get('/api/products/:id/qr', async (req, res) => {
  const { rows } = await pool.query(
    'SELECT id, name, qr_code FROM products WHERE id=$1', [req.params.id]
  );
  if (!rows[0]) return res.status(404).json({ error: 'Not found' });
  
  const qrImageBase64 = await QRCode.toDataURL(rows[0].qr_code, { width: 400 });
  res.json({ qr_url: qrImageBase64, product_name: rows[0].name });
});

// ═══════════════════════════════════════════════
// ORDERS (GIỮ NGUYÊN)
// ═══════════════════════════════════════════════

// Lấy tất cả đơn hàng
app.get('/api/orders', async (req, res) => {
  const { rows } = await pool.query(
    'SELECT * FROM orders ORDER BY created_at DESC'
  );
  res.json(rows);
});

// Tạo đơn hàng mới (từ mobile sau khi quét QR)
app.post('/api/orders', async (req, res) => {
  const { product_id, product_name, quantity,
          amount_due, discount, amount_paid } = req.body;

  // Tính toán server-side để đảm bảo chính xác
  const debt = Math.max(0, amount_paid - amount_due);
  const total_revenue = amount_paid - discount;

  const { rows } = await pool.query(
    `INSERT INTO orders
       (product_id, product_name, quantity, amount_due,
        discount, amount_paid, debt, total_revenue)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING *`,
    [product_id, product_name, quantity, amount_due,
     discount, amount_paid, debt, total_revenue]
  );

  // Cập nhật số lượng bán ra trong bảng products
  await pool.query(
    'UPDATE products SET quantity = quantity + $1 WHERE id = $2',
    [quantity, product_id]
  );

  res.status(201).json(rows[0]);
});

// ═══════════════════════════════════════════════
// DEBTS (GIỮ NGUYÊN)
// ═══════════════════════════════════════════════

// Lấy tất cả công nợ
app.get('/api/debts', async (req, res) => {
  const { rows } = await pool.query(
    'SELECT * FROM debts ORDER BY created_at DESC'
  );
  res.json(rows);
});

// Tạo công nợ (trích xuất từ đơn hàng)
app.post('/api/debts', async (req, res) => {
  const { order_id, name, debt_amount, amount_paid, discount } = req.body;
  
  // total_revenue công nợ = debt_amount - amount_paid - discount
  const total_revenue = debt_amount - amount_paid - discount;

  const { rows } = await pool.query(
    `INSERT INTO debts (order_id, name, debt_amount, amount_paid, discount, total_revenue)
     VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [order_id, name, debt_amount, amount_paid, discount, total_revenue]
  );
  res.status(201).json(rows[0]);
});

// Cập nhật công nợ (khách trả thêm)
app.put('/api/debts/:id', async (req, res) => {
  const { name, amount_paid, discount } = req.body;
  const { rows: [debt] } = await pool.query(
    'SELECT debt_amount FROM debts WHERE id=$1', [req.params.id]
  );
  
  const total_revenue = debt.debt_amount - amount_paid - discount;
  const { rows } = await pool.query(
    `UPDATE debts SET name=$2, amount_paid=$3, discount=$4,
       total_revenue=$5, updated_at=NOW()
     WHERE id=$1 RETURNING *`,
    [req.params.id, name, amount_paid, discount, total_revenue]
  );
  res.json(rows[0]);
});

// ═══════════════════════════════════════════════
// DASHBOARD STATS (GIỮ NGUYÊN)
// ═══════════════════════════════════════════════

app.get('/api/dashboard/stats', async (req, res) => {
  const [revenue, orders, debt, products, revenueByDay] = await Promise.all([
    pool.query('SELECT COALESCE(SUM(total_revenue),0) AS total FROM orders'),
    pool.query('SELECT COUNT(*) AS total FROM orders'),
    pool.query('SELECT COALESCE(SUM(debt),0) AS total FROM orders'),
    pool.query('SELECT COUNT(*) AS total FROM products WHERE is_unavailable=FALSE'),
    pool.query(`
      SELECT DATE(created_at) AS date, SUM(total_revenue) AS revenue
      FROM orders
      WHERE created_at >= NOW() - INTERVAL '30 days'
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    `),
  ]);

  res.json({
    total_revenue:  parseFloat(revenue.rows[0].total),
    total_orders:   parseInt(orders.rows[0].total),
    total_debt:     parseFloat(debt.rows[0].total),
    total_products: parseInt(products.rows[0].total),
    revenue_by_day: revenueByDay.rows,
  });
});

app.listen(3000, () => console.log('🚀 Server chạy tại http://localhost:3000'));