// backend/server.js
require('dotenv').config();
const express  = require('express');
const cors     = require('cors');
const { Pool } = require('pg');
const QRCode   = require('qrcode');
const { v4: uuidv4 } = require('uuid');
const { authenticate, requireAdmin } = require('./middleware/auth');

const app  = express();
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

// ── Middleware ────────────────────────────────────────────
app.use(cors({
  origin: ['http://localhost:50328', 'http://localhost:8080', '*'],
  methods: ['GET','POST','PUT','DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json());

// ── Routes ────────────────────────────────────────────────

// Auth (public – không cần token)
app.use('/api/auth', require('./routes/auth'));

// Products
app.use('/api/product', require('./routes/product'));

// Orders
app.use('/api/orders', require('./routes/orders'));

// Debts
app.use('/api/debts', require('./routes/debts'));

// ── Dashboard Stats ──────────────────────────────────────
app.get('/api/dashboard/stats', authenticate, async (req, res) => {
  try {
    const [revenue, orders, debt, products, revenueByDay] = await Promise.all([
      pool.query('SELECT COALESCE(SUM(total_revenue),0) AS total FROM orders'),
      pool.query('SELECT COUNT(*) AS total FROM orders'),
      pool.query('SELECT COALESCE(SUM(debt),0) AS total FROM orders'),
      pool.query('SELECT COUNT(*) AS total FROM products WHERE is_unavailable = FALSE'),
      pool.query(`
        SELECT DATE(created_at) AS date,
               SUM(total_revenue)::float AS revenue
        FROM orders
        WHERE created_at >= NOW() - INTERVAL '30 days'
        GROUP BY DATE(created_at)
        ORDER BY date ASC
      `),
    ]);

    res.json({
      total_revenue:   parseFloat(revenue.rows[0].total),
      total_orders:    parseInt(orders.rows[0].total),
      total_debt:      parseFloat(debt.rows[0].total),
      total_products:  parseInt(products.rows[0].total),
      revenue_by_day:  revenueByDay.rows,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Lỗi server' });
  }
});

// ── Health check ─────────────────────────────────────────
app.get('/api/health', (req, res) =>
  res.json({ status: 'ok', time: new Date().toISOString() }));

// ── Start ─────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server chạy tại http://localhost:${PORT}`);
  console.log(`📋 Tài khoản mặc định: admin / admin123`);
});