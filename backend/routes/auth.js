const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');

// Key bí mật để mã hóa token (Trong thực tế nên để ở file .env)
const JWT_SECRET = 'SUPER_SECRET_KEY_SHOP_UT_THAO'; 

router.post('/login', async (req, res) => {
    const { username, password } = req.body;

    try {
        // Giả định tài khoản admin cố định (hoặc bạn truy vấn từ database)
        if (username === 'admin' && password === 'admin123') {
            // Tạo mã token JWT có thời hạn sống của session (ví dụ: 1 ngày)
            const token = jwt.sign({ username }, JWT_SECRET, { expiresIn: '24h' });
            
            return res.json({
                success: true,
                message: 'Đăng nhập thành công',
                token: token
            });
        }

        return res.status(401).json({ success: false, message: 'Tài khoản hoặc mật khẩu không chính xác' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

module.exports = router;