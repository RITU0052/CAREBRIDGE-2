const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();
const UserModel = require('../models/userModel');
const ParentProfileModel = require('../models/parentProfileModel');

function generateToken(user) {
  return jwt.sign(
    { user_id: user.user_id, role: user.role, name: user.name },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
}

// POST /api/auth/register
// Registers a user as either 'child' (caregiver) or 'parent' (monitored person).
// If registering as 'parent', an optional child_email can link them to an existing child account.
async function register(req, res) {
  try {
    const { name, email, phone, password, role, age, blood_group, medical_history, child_email } = req.body;

    if (!name || !email || !password || !role) {
      return res.status(400).json({ error: 'name, email, password and role are required' });
    }
    if (!['child', 'parent'].includes(role)) {
      return res.status(400).json({ error: "role must be 'child' or 'parent'" });
    }

    const existing = await UserModel.findByEmail(email);
    if (existing) {
      return res.status(409).json({ error: 'An account with this email already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await UserModel.create({ name, email, phone, hashedPassword, role });

    // If this is a parent account, create their monitored profile
    if (role === 'parent') {
      let child_id = null;
      if (child_email) {
        const childUser = await UserModel.findByEmail(child_email);
        if (childUser && childUser.role === 'child') {
          child_id = childUser.user_id;
        }
      }
      await ParentProfileModel.create({
        user_id: user.user_id,
        child_id,
        age: age || null,
        blood_group: blood_group || null,
        medical_history: medical_history || null,
      });
    }

    const token = generateToken(user);
    res.status(201).json({ message: 'Registration successful', token, user });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error during registration' });
  }
}

// POST /api/auth/login
async function login(req, res) {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'email and password are required' });
    }

    const user = await UserModel.findByEmail(email);
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = generateToken(user);
    const { password: _pw, ...safeUser } = user;
    res.json({ message: 'Login successful', token, user: safeUser });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error during login' });
  }
}

// GET /api/auth/me
async function me(req, res) {
  try {
    const user = await UserModel.findById(req.user.user_id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json({ user });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
}

module.exports = { register, login, me };
