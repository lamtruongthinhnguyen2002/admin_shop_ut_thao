const express = require('express');
const router = express.Router();

// Lấy danh sách công nợ khách hàng
router.get('/', async (req, res) => {
    try {
        res.json({ success: true, data: [] });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

// Cập nhật trạng thái trả nợ
router.put('/:id', async (req, res) => {
    const { id } = req.params;
    try {
        res.json({ success: true, message: `Cập nhật công nợ ${id} thành công` });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
});

module.exports = router;