// backend/middleware/auth.js
const jwt = require('jsonwebtoken');
const JWT_SECRET = process.env.JWT_SECRET || 'shop_mgmt_secret_2024';

/**
 * Middleware xác thực JWT
 * Gắn req.user = { id, username, role } nếu token hợp lệ
 */
function authenticate(req, res, next) {
  try {
    const authHeader = req.headers['authorization'];

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Yêu cầu đăng nhập' });
    }

    const token   = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, JWT_SECRET);
    req.user      = decoded;
    return next();
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ message: 'Phiên đăng nhập đã hết hạn' });
    }
    return res.status(401).json({ message: 'Token không hợp lệ' });
  }
}

/**
 * Middleware chỉ cho phép admin
 */
function requireAdmin(req, res, next) {
  if (req.user?.role !== 'admin') {
    return res.status(403).json({ message: 'Không có quyền thực hiện thao tác này' });
  }
  return next();
}

module.exports = { authenticate, requireAdmin };