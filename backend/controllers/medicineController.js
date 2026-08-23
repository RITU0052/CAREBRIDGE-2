const MedicineModel = require('../models/medicineModel');
const ParentProfileModel = require('../models/parentProfileModel');

// Helper: confirms the logged-in user is allowed to act on this parent_profile_id.
// A 'child' must be linked as the caregiver; a 'parent' must own the profile themselves.
async function canAccessProfile(user, parent_profile_id) {
  const profile = await ParentProfileModel.findById(parent_profile_id);
  if (!profile) return false;
  if (user.role === 'parent') return profile.user_id === user.user_id;
  if (user.role === 'child') return profile.child_id === user.user_id;
  return false;
}

// POST /api/medicine  { parent_profile_id, medicine_name, dose, time_of_day }
// Typically added by the child (caregiver) on behalf of a parent
async function addMedicine(req, res) {
  try {
    const { parent_profile_id, medicine_name, dose, time_of_day } = req.body;
    if (!parent_profile_id || !medicine_name) {
      return res.status(400).json({ error: 'parent_profile_id and medicine_name are required' });
    }

    const allowed = await canAccessProfile(req.user, parent_profile_id);
    if (!allowed) return res.status(403).json({ error: 'Not authorized for this profile' });

    const medicine = await MedicineModel.create({ parent_profile_id, medicine_name, dose, time_of_day });
    res.status(201).json({ message: 'Medicine added', medicine });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error adding medicine' });
  }
}

// GET /api/medicine/:parent_profile_id  -> today's list + status
async function getMedicines(req, res) {
  try {
    const { parent_profile_id } = req.params;

    const allowed = await canAccessProfile(req.user, parent_profile_id);
    if (!allowed) return res.status(403).json({ error: 'Not authorized for this profile' });

    const medicines = await MedicineModel.getTodayStatusForParent(parent_profile_id);
    res.json({ medicines });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error fetching medicines' });
  }
}

// PUT /api/medicine/status  { medicine_id, status: 'taken' | 'skipped' }
// Typically called by the parent tapping "Taken" or "Skipped"
async function updateStatus(req, res) {
  try {
    const { medicine_id, status } = req.body;
    if (!medicine_id || !['taken', 'skipped', 'pending'].includes(status)) {
      return res.status(400).json({ error: "medicine_id and a valid status ('taken'/'skipped') are required" });
    }

    const medicine = await MedicineModel.findById(medicine_id);
    if (!medicine) return res.status(404).json({ error: 'Medicine not found' });

    const allowed = await canAccessProfile(req.user, medicine.parent_profile_id);
    if (!allowed) return res.status(403).json({ error: 'Not authorized for this profile' });

    const log = await MedicineModel.upsertTodayLog(medicine_id, status);
    res.json({ message: 'Status updated', log });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error updating status' });
  }
}

module.exports = { addMedicine, getMedicines, updateStatus };
