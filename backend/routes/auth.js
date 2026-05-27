// backend/routes/auth.js
const express = require('express');
const bcrypt  = require('bcryptjs');
const jwt     = require('jsonwebtoken');
const { Pool } = require('pg');

const router = express.Router();
const pool   = new Pool({ connectionString: process.env.DATABASE_URL });
const JWT_SECRET = process.env.JWT_SECRET || 'shop_mgmt_secret_2024';
const JWT_EXPIRES = '7d';

// ── POST /api/auth/login ──────────────────────────────────
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ message: 'Vui lòng nhập đầy đủ thông tin' });
    }

    // Tìm user trong DB
    const { rows } = await pool.query(
      'SELECT * FROM users WHERE username = $1 AND is_active = TRUE',
      [username.trim()]
    );

    if (rows.length === 0) {
      return res.status(401).json({ message: 'Sai tên đăng nhập hoặc mật khẩu' });
    }

    const user = rows[0];

    // Kiểm tra password
    const isValid = await bcrypt.compare(password, user.password_hash);
    if (!isValid) {
      return res.status(401).json({ message: 'Sai tên đăng nhập hoặc mật khẩu' });
    }

    // Cập nhật lần đăng nhập cuối
    await pool.query(
      'UPDATE users SET last_login = NOW() WHERE id = $1',
      [user.id]
    );

    // Tạo JWT
    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES }
    );

    return res.json({
      token,
      user: {
        id:        user.id,
        username:  user.username,
        role:      user.role,
        full_name: user.full_name,
      },
    });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ message: 'Lỗi server' });
  }
});

// ── GET /api/auth/me – verify token ──────────────────────
router.get('/me', async (req, res) => {
  try {
    const authHeader = req.headers['authorization'];
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const token   = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, JWT_SECRET);

    const { rows } = await pool.query(
      'SELECT id, username, role, full_name FROM users WHERE id = $1',
      [decoded.id]
    );

    if (!rows[0]) return res.status(404).json({ message: 'User không tồn tại' });
    return res.json(rows[0]);
  } catch (err) {
    return res.status(401).json({ message: 'Token không hợp lệ' });
  }
});

// ── POST /api/auth/logout – (stateless JWT: client xóa token) ─
router.post('/logout', (req, res) => {
  return res.json({ message: 'Đăng xuất thành công' });
});

module.exports = router;