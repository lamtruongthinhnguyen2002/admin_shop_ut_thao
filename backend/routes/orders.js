const express = require('express');
const router = express.Router();

// Lấy toàn bộ đơn hàng
router.get('/', async (req, res) => {
    try {
        res.json({ success: true, data: [] });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// Tạo đơn hàng mới
router.post('/', async (req, res) => {
    try {
        res.json({ success: true, message: 'Tạo đơn hàng thành công' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

module.exports = router;