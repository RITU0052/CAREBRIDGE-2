const pool = require('../config/db');

const MedicineModel = {
  async create({ parent_profile_id, medicine_name, dose, time_of_day }) {
    const result = await pool.query(
      `INSERT INTO medicines (parent_profile_id, medicine_name, dose, time_of_day)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [parent_profile_id, medicine_name, dose, time_of_day]
    );
    return result.rows[0];
  },

  async findByParentProfileId(parent_profile_id) {
    const result = await pool.query(
      'SELECT * FROM medicines WHERE parent_profile_id = $1 ORDER BY created_at DESC',
      [parent_profile_id]
    );
    return result.rows;
  },

  async findById(medicine_id) {
    const result = await pool.query('SELECT * FROM medicines WHERE medicine_id = $1', [medicine_id]);
    return result.rows[0];
  },

  // Gets today's log status for every medicine belonging to a parent profile,
  // creating a 'pending' log row if one doesn't exist yet for today.
  async getTodayStatusForParent(parent_profile_id) {
    const result = await pool.query(
      `SELECT m.medicine_id, m.medicine_name, m.dose, m.time_of_day,
              COALESCE(ml.status, 'pending') AS status
       FROM medicines m
       LEFT JOIN medicine_logs ml
         ON ml.medicine_id = m.medicine_id AND ml.log_date = CURRENT_DATE
       WHERE m.parent_profile_id = $1
       ORDER BY m.created_at`,
      [parent_profile_id]
    );
    return result.rows;
  },

  async upsertTodayLog(medicine_id, status) {
    const result = await pool.query(
      `INSERT INTO medicine_logs (medicine_id, status, log_date)
       VALUES ($1, $2, CURRENT_DATE)
       ON CONFLICT (medicine_id, log_date)
       DO UPDATE SET status = $2, updated_at = NOW()
       RETURNING *`,
      [medicine_id, status]
    );
    return result.rows[0];
  },
};

module.exports = MedicineModel;
