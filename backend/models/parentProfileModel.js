const pool = require('../config/db');

const ParentProfileModel = {
  async create({ user_id, child_id, age, blood_group, medical_history }) {
    const result = await pool.query(
      `INSERT INTO parent_profiles (user_id, child_id, age, blood_group, medical_history)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [user_id, child_id, age, blood_group, medical_history]
    );
    return result.rows[0];
  },

  // All parent profiles linked to a given child (caregiver) account
  async findByChildId(child_id) {
    const result = await pool.query(
      `SELECT pp.*, u.name, u.email, u.phone
       FROM parent_profiles pp
       JOIN users u ON u.user_id = pp.user_id
       WHERE pp.child_id = $1`,
      [child_id]
    );
    return result.rows;
  },

  async findByUserId(user_id) {
    const result = await pool.query(
      'SELECT * FROM parent_profiles WHERE user_id = $1',
      [user_id]
    );
    return result.rows[0];
  },

  async findById(parent_profile_id) {
    const result = await pool.query(
      'SELECT * FROM parent_profiles WHERE parent_profile_id = $1',
      [parent_profile_id]
    );
    return result.rows[0];
  },

  // Confirms a given child account is actually allowed to view this parent profile
  async isLinkedToChild(parent_profile_id, child_id) {
    const result = await pool.query(
      'SELECT 1 FROM parent_profiles WHERE parent_profile_id = $1 AND child_id = $2',
      [parent_profile_id, child_id]
    );
    return result.rowCount > 0;
  },
};

module.exports = ParentProfileModel;
