const express = require('express');
const router = express.Router();
// Giả định bạn có một kết nối database cấu hình từ trước ở file db chính
// const db = require('../db'); 

// Lấy danh sách sản phẩm
router.get('/', async (req, res) => {
    try {
        // const [products] = await db.query('SELECT * FROM products');
        res.json({ success: true, data: [] }); 
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// Thêm sản phẩm mới
router.post('/', async (req, res) => {
    const { name, price, stock } = req.body;
    try {
        res.json({ success: true, message: 'Thêm sản phẩm thành công' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

module.exports = router;