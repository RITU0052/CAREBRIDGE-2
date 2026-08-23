const pool = require('../config/db');

const UserModel = {
  async create({ name, email, phone, hashedPassword, role }) {
    const result = await pool.query(
      `INSERT INTO users (name, email, phone, password, role)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING user_id, name, email, phone, role, created_at`,
      [name, email, phone, hashedPassword, role]
    );
    return result.rows[0];
  },

  async findByEmail(email) {
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    return result.rows[0];
  },

  async findById(user_id) {
    const result = await pool.query(
      'SELECT user_id, name, email, phone, role, created_at FROM users WHERE user_id = $1',
      [user_id]
    );
    return result.rows[0];
  },
};

module.exports = UserModel;
