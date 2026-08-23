const express = require('express');
const router = express.Router();
const { getMyParents, getMyDashboard } = require('../controllers/parentController');
const { authenticate, authorize } = require('../middleware/auth');

router.get('/my-parents', authenticate, authorize('child'), getMyParents);
router.get('/dashboard', authenticate, authorize('parent'), getMyDashboard);

module.exports = router;
