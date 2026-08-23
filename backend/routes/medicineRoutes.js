const express = require('express');
const router = express.Router();
const { addMedicine, getMedicines, updateStatus } = require('../controllers/medicineController');
const { authenticate } = require('../middleware/auth');

router.post('/', authenticate, addMedicine);
router.get('/:parent_profile_id', authenticate, getMedicines);
router.put('/status', authenticate, updateStatus);

module.exports = router;
