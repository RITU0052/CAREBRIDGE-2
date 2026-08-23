-- CareBridge AI Database Schema
-- Core MVP tables: Users, Parent Profiles, Child-Parent Links, Medicines, Medicine Logs

CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('child', 'parent', 'doctor', 'caregiver', 'admin')),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Links a "child" (caregiver) user to a "parent" (monitored) user profile
CREATE TABLE IF NOT EXISTS parent_profiles (
    parent_profile_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE, -- the parent's own user account
    child_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,        -- the child/caregiver managing them
    age INTEGER,
    blood_group VARCHAR(5),
    medical_history TEXT,
    doctor_id INTEGER REFERENCES users(user_id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS medicines (
    medicine_id SERIAL PRIMARY KEY,
    parent_profile_id INTEGER NOT NULL REFERENCES parent_profiles(parent_profile_id) ON DELETE CASCADE,
    medicine_name VARCHAR(150) NOT NULL,
    dose VARCHAR(50),
    time_of_day VARCHAR(20), -- e.g. 'Morning', 'Afternoon', 'Night' or '08:00'
    created_at TIMESTAMP DEFAULT NOW()
);

-- One row per day per medicine, tracks whether it was taken
CREATE TABLE IF NOT EXISTS medicine_logs (
    log_id SERIAL PRIMARY KEY,
    medicine_id INTEGER NOT NULL REFERENCES medicines(medicine_id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'taken', 'skipped')),
    log_date DATE NOT NULL DEFAULT CURRENT_DATE,
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(medicine_id, log_date)
);

CREATE INDEX IF NOT EXISTS idx_parent_profiles_child ON parent_profiles(child_id);
CREATE INDEX IF NOT EXISTS idx_medicines_parent ON medicines(parent_profile_id);
CREATE INDEX IF NOT EXISTS idx_medicine_logs_medicine ON medicine_logs(medicine_id);
