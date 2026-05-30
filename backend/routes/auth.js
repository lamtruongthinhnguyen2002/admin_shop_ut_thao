const express    = require('express');
const bcrypt     = require('bcryptjs');
const jwt        = require('jsonwebtoken');
const { Pool }   = require('pg');
const { authenticate } = require('../middleware/auth');

const router     = express.Router();
const pool       = new Pool({ connectionString: process.env.DATABASE_URL });
const JWT_SECRET = process.env.JWT_SECRET || 'shop_mgmt_secret_2024';

// ── POST /api/auth/login ──────────────────────────────────
router.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password)
      return res.status(400).json({ message: 'Vui lòng nhập đầy đủ thông tin' });

    const { rows } = await pool.query(
      'SELECT * FROM users WHERE username=$1 AND is_active=TRUE', [username.trim()]);
    if (!rows[0])
      return res.status(401).json({ message: 'Sai tên đăng nhập hoặc mật khẩu' });

    const isValid = await bcrypt.compare(password, rows[0].password_hash);
    if (!isValid)
      return res.status(401).json({ message: 'Sai tên đăng nhập hoặc mật khẩu' });

    await pool.query('UPDATE users SET last_login=NOW() WHERE id=$1', [rows[0].id]);

    const token = jwt.sign(
      { id: rows[0].id, username: rows[0].username, role: rows[0].role },
      JWT_SECRET, { expiresIn: '8h' } // Slide 5: token expire sau 8h
    );

    return res.json({
      token,
      user: {
        id:        rows[0].id,
        username:  rows[0].username,
        role:      rows[0].role,
        full_name: rows[0].full_name,
      },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Lỗi server' });
  }
});

// ── GET /api/auth/me ──────────────────────────────────────
router.get('/me', authenticate, async (req, res) => {
  try {
    const { rows } = await pool.query(
      'SELECT id, username, role, full_name FROM users WHERE id=$1',
      [req.user.id]);
    if (!rows[0]) return res.status(404).json({ message: 'Không tìm thấy user' });
    return res.json(rows[0]);
  } catch (err) {
    return res.status(500).json({ message: 'Lỗi server' });
  }
});

// ── PUT /api/auth/profile – Đổi username/password/fullName ─
// FIX SLIDE 3: Backend xử lý đổi thông tin, lần sau login dùng thông tin mới
router.put('/profile', authenticate, async (req, res) => {
  try {
    const { full_name, new_username, current_password, new_password } = req.body;
    const userId = req.user.id;

    // Lấy user hiện tại
    const { rows: [user] } = await pool.query(
      'SELECT * FROM users WHERE id=$1', [userId]);
    if (!user) return res.status(404).json({ message: 'Không tìm thấy user' });

    // Kiểm tra username mới không bị trùng
    if (new_username && new_username !== user.username) {
      const { rows: exist } = await pool.query(
        'SELECT id FROM users WHERE username=$1 AND id!=$2',
        [new_username.trim(), userId]);
      if (exist.length > 0) {
        return res.status(400).json({ message: 'Username đã tồn tại, vui lòng chọn tên khác' });
      }
    }

    // Nếu muốn đổi mật khẩu → verify mật khẩu hiện tại
    let newHash = null;
    if (new_password) {
      if (!current_password) {
        return res.status(400).json({ message: 'Vui lòng nhập mật khẩu hiện tại' });
      }
      const isValid = await bcrypt.compare(current_password, user.password_hash);
      if (!isValid) {
        return res.status(400).json({ message: 'Mật khẩu hiện tại không đúng' });
      }
      if (new_password.length < 6) {
        return res.status(400).json({ message: 'Mật khẩu mới tối thiểu 6 ký tự' });
      }
      newHash = await bcrypt.hash(new_password, 10);
    }

    // Update DB
    const { rows: [updated] } = await pool.query(
      `UPDATE users
       SET full_name      = COALESCE($2, full_name),
           username       = COALESCE($3, username),
           password_hash  = COALESCE($4, password_hash),
           updated_at     = NOW()
       WHERE id=$1
       RETURNING id, username, role, full_name`,
      [
        userId,
        full_name   || null,
        new_username ? new_username.trim() : null,
        newHash,
      ]
    );

    // Cấp token mới với username đã update
    const newToken = jwt.sign(
      { id: updated.id, username: updated.username, role: updated.role },
      JWT_SECRET, { expiresIn: '8h' }
    );

    return res.json({
      message: 'Cập nhật thành công',
      token: newToken,
      user:  updated,
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ message: 'Lỗi server' });
  }
});

// ── POST /api/auth/logout ─────────────────────────────────
router.post('/logout', (req, res) =>
  res.json({ message: 'Đăng xuất thành công' }));

module.exports = router;