const express = require('express');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/authRoutes');
const parentRoutes = require('./routes/parentRoutes');
const medicineRoutes = require('./routes/medicineRoutes');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', service: 'CareBridge AI backend' });
});

app.use('/api/auth', authRoutes);
app.use('/api/parent', parentRoutes);
app.use('/api/medicine', medicineRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`CareBridge backend running on http://localhost:${PORT}`);
});
