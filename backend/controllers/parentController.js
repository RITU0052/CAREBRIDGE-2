const ParentProfileModel = require('../models/parentProfileModel');
const MedicineModel = require('../models/medicineModel');

// GET /api/parent/my-parents  (called by a 'child' user)
// Returns all parent profiles linked to the logged-in child, with today's medicine summary
async function getMyParents(req, res) {
  try {
    const parents = await ParentProfileModel.findByChildId(req.user.user_id);

    const parentsWithMeds = await Promise.all(
      parents.map(async (p) => {
        const meds = await MedicineModel.getTodayStatusForParent(p.parent_profile_id);
        const total = meds.length;
        const taken = meds.filter((m) => m.status === 'taken').length;
        return {
          parent_profile_id: p.parent_profile_id,
          name: p.name,
          email: p.email,
          phone: p.phone,
          age: p.age,
          blood_group: p.blood_group,
          medical_history: p.medical_history,
          medicine_summary: `${taken}/${total} taken today`,
          medicines_today: meds,
        };
      })
    );

    res.json({ parents: parentsWithMeds });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error fetching parents' });
  }
}

// GET /api/parent/dashboard  (called by a 'parent' user, their own simple dashboard)
async function getMyDashboard(req, res) {
  try {
    const profile = await ParentProfileModel.findByUserId(req.user.user_id);
    if (!profile) return res.status(404).json({ error: 'Parent profile not found' });

    const meds = await MedicineModel.getTodayStatusForParent(profile.parent_profile_id);
    res.json({ profile, medicines_today: meds });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error fetching dashboard' });
  }
}

module.exports = { getMyParents, getMyDashboard };
