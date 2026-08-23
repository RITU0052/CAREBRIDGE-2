import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static String customUrl = '';

  static String get baseUrl {
    if (customUrl.isNotEmpty) return customUrl;
    if (kIsWeb) return 'http://localhost:8000/api';
    if (defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.macOS || 
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://localhost:8000/api';
    }
    return 'http://10.0.2.2:8000/api';
  }
}


class ApiService {
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    return {
      'Content-Type': 'application/json',
    };
  }

  // --- Auth ---

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['access_token'] != null) {
        await saveToken(data['access_token']);
      }
      return data;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Login failed');
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? childEmail,
    String? specialty,
    String? qualifications,
    int? experienceYears,
    double? consultationFee,
    String? location,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (childEmail != null && childEmail.isNotEmpty) 'child_email': childEmail,
      if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
      if (qualifications != null && qualifications.isNotEmpty) 'qualifications': qualifications,
      if (experienceYears != null) 'experience_years': experienceYears,
      if (consultationFee != null) 'consultation_fee': consultationFee,
      if (location != null && location.isNotEmpty) 'location': location,
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Registration failed');
    }
  }

  Future<Map<String, dynamic>> connectFamilyByCode(String code) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/family/connect'),
      headers: await _getHeaders(),
      body: jsonEncode({'family_code': code}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to connect family member');
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/me'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch user profile');
  }

  Future<Map<String, dynamic>> updateProfile({String? name, String? phone, String? bio}) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/auth/me'),
      headers: await _getHeaders(),
      body: jsonEncode({
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (bio != null) 'bio': bio,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to update profile');
  }

  // --- Doctors & Slots ---

  Future<List<dynamic>> getDoctors({
    String? search,
    String? specialty,
    String? location,
    String? consultationType,
    String? sortBy,
    bool includePending = false,
  }) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (specialty != null && specialty.isNotEmpty) queryParams['specialty'] = specialty;
    if (location != null && location.isNotEmpty) queryParams['location'] = location;
    if (consultationType != null && consultationType.isNotEmpty) queryParams['consultation_type'] = consultationType;
    if (sortBy != null && sortBy.isNotEmpty) queryParams['sort_by'] = sortBy;
    if (includePending) queryParams['include_pending'] = 'true';

    final uri = Uri.parse('${ApiConfig.baseUrl}/doctors').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> getDoctorById(String doctorId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/doctors/$doctorId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Doctor not found');
  }

  Future<List<String>> getAvailableSlots(String doctorId, String date) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/doctors/$doctorId/slots?date=$date'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['available_slots'] ?? []);
    }
    return [];
  }

  Future<List<dynamic>> getDoctorReviews(String doctorId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/doctors/$doctorId/reviews'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> getDoctorProfileMe() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/doctors/me'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch doctor profile');
  }

  Future<Map<String, dynamic>> updateDoctorProfileMe({
    String? qualifications,
    String? specialty,
    String? profession,
    String? phone,
    String? email,
    String? location,
    double? fee,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/doctors/me'),
      headers: await _getHeaders(),
      body: jsonEncode({
        if (qualifications != null) 'qualifications': qualifications,
        if (specialty != null) 'specialty': specialty,
        if (profession != null) 'profession': profession,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (location != null) 'location': location,
        if (fee != null) 'consultation_fee': fee,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to update doctor profile');
  }

  Future<List<dynamic>> getDoctorScheduleMe() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/doctors/me/appointments'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<List<dynamic>> getDoctorMyAppointments() async {
    return getDoctorScheduleMe();
  }

  // --- Appointments ---

  Future<Map<String, dynamic>> bookAppointment({
    required String doctorId,
    required String appointmentDate,
    required String timeSlot,
    required String patientName,
    String? appointmentType = "In-person",
    String? patientPhone,
    String? patientNotes,
    String? serviceId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/appointments'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'doctor_id': doctorId,
        'appointment_date': appointmentDate,
        'time_slot': timeSlot,
        'appointment_type': appointmentType ?? "In-person",
        'patient_name': patientName,
        'patient_phone': patientPhone,
        'patient_notes': patientNotes,
        'service_id': serviceId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Booking failed');
    }
  }

  Future<Map<String, dynamic>> rescheduleAppointment({
    required String appointmentId,
    required String newDate,
    required String newTimeSlot,
    String? reason,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/appointments/$appointmentId/reschedule'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'new_date': newDate,
        'new_time_slot': newTimeSlot,
        'reason': reason,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Reschedule failed');
    }
  }

  Future<Map<String, dynamic>> setAppointmentReminder({
    required String appointmentId,
    required int minutesBefore,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/appointments/$appointmentId/reminder'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'reminder_time_minutes': minutesBefore,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to set reminder');
    }
  }

  Future<List<dynamic>> getMyAppointments() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/appointments/my'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> cancelAppointment(String appointmentId) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/appointments/$appointmentId/cancel'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to cancel appointment');
  }

  // --- Services ---

  Future<List<dynamic>> getServices() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/services'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // --- Admin ---

  Future<Map<String, dynamic>> getAdminStats() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/stats'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load admin stats');
  }

  Future<List<dynamic>> getAdminUsers({String? search, String? role}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (role != null && role.isNotEmpty) queryParams['role'] = role;

    final uri = Uri.parse('${ApiConfig.baseUrl}/admin/users').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<void> verifyDoctor(String doctorId, bool isVerified) async {
    final statusStr = isVerified ? 'verified' : 'rejected';
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/admin/doctors/$doctorId/verify'),
      headers: await _getHeaders(),
      body: jsonEncode({'status': statusStr}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update doctor verification');
    }
  }

  Future<Map<String, dynamic>> createAdminUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/users'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to create user');
    }
  }

  Future<void> deleteAdminUser(String userId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to delete user');
    }
  }

  Future<void> changeUserPassword(String userId, String newPassword) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/change-password'),
      headers: await _getHeaders(),
      body: jsonEncode({'new_password': newPassword}),
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to change user password');
    }
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId/role?role=$newRole'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update user role');
    }
  }

  Future<List<dynamic>> getAdminAppointments({String? statusFilter}) async {
    final url = statusFilter != null && statusFilter.isNotEmpty
        ? '${ApiConfig.baseUrl}/appointments/admin?status_filter=$statusFilter'
        : '${ApiConfig.baseUrl}/appointments/admin';
    final response = await http.get(Uri.parse(url), headers: await _getHeaders());
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> createDoctor(Map<String, dynamic> doctorData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/doctors'),
      headers: await _getHeaders(),
      body: jsonEncode(doctorData),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create doctor');
  }

  // --- Medicines ---

  Future<List<dynamic>> getMedicines(String parentId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/medicines/$parentId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> addMedicine({
    required String name,
    required String dose,
    String? doseUnit = 'tablet',
    required String timeOfDay,
    String? foodInstruction = 'After Food',
    String? diseaseCondition,
    String? frequency = 'Once a day',
    String? duration = '30 Days',
    String? startDate,
    String? endDate,
    String? parentId,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/medicines'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'medicine_name': name,
        'dose': dose,
        'dose_unit': doseUnit ?? 'tablet',
        'time_of_day': timeOfDay,
        'food_instruction': foodInstruction ?? 'After Food',
        'disease_condition': diseaseCondition,
        'frequency': frequency ?? 'Once a day',
        'duration': duration ?? '30 Days',
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
        if (parentId != null) 'parent_id': parentId,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to add medicine');
    }
  }

  Future<void> updateMedicineStatus(String medicineId, String status) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/medicines/status'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'medicine_id': medicineId,
        'status': status,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update medicine status');
    }
  }

  Future<void> markMedicineTaken(String medicineId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/medicines/$medicineId/taken'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark medicine as taken');
    }
  }

  Future<void> markMedicineSkipped(String medicineId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/medicines/$medicineId/skip'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark medicine as skipped');
    }
  }

  Future<void> markMedicineSnoozed(String medicineId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/medicines/$medicineId/snooze'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark medicine as snoozed');
    }
  }

  Future<void> deleteMedicine(String medicineId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/medicines/$medicineId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete medicine');
    }
  }

  Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/notifications'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // --- Medical Reports ---

  Future<List<dynamic>> getReports(String parentId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/reports/$parentId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch reports: ${response.statusCode}');
  }

  Future<void> uploadReport(String? filePath, String title, {List<int>? bytes, String? filename, String? reportType, String? notes}) async {
    final token = await getToken();
    var request = http.MultipartRequest('POST', Uri.parse('${ApiConfig.baseUrl}/reports/upload'));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields['title'] = title;
    if (reportType != null) request.fields['report_type'] = reportType;
    if (notes != null) request.fields['notes'] = notes;
    
    if (bytes != null && filename != null) {
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    } else if (filePath != null && filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    } else {
      throw Exception('No file provided for upload');
    }
    
    var response = await request.send();
    if (response.statusCode != 200) {
      final respStr = await response.stream.bytesToString();
      throw Exception('Failed to upload report (${response.statusCode}): $respStr');
    }
  }

  Future<void> deleteReport(String reportId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/reports/$reportId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete report');
    }
  }

  // --- AI Report Summarizer ---

  Future<Map<String, dynamic>> summarizeReportAI(String reportId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/reports/$reportId/summarize'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to generate AI summary');
    }
  }

  // --- Health Metrics & SOS ---

  Future<void> addHealthMetric({
    String? sys,
    String? dia,
    String? hr,
    double? waterIntake,
    double? waterTarget = 2.5,
    int? stepsTarget = 8000,
    int? stepsActual,
    String? dataSource = 'manual',
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/health/metrics'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'blood_pressure_sys': sys,
        'blood_pressure_dia': dia,
        'heart_rate': hr,
        'water_intake_l': waterIntake,
        'water_target_l': waterTarget,
        'steps_target': stepsTarget,
        'steps_actual': stepsActual,
        'data_source': dataSource,
        'notes': notes,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to add health metric');
    }
  }

  Future<List<dynamic>> getHealthMetrics(String parentId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/health/metrics/$parentId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  // --- Emergency Contacts & Doctor Contacts ---

  Future<List<dynamic>> getEmergencyContacts() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/sos/contacts'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> addEmergencyContact({
    required String name,
    required String phone,
    String? relationship,
    String? email,
    bool isPrimary = false,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/sos/contacts'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'relationship': relationship ?? 'Family',
        if (email != null && email.isNotEmpty) 'email': email,
        'is_primary': isPrimary,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to add emergency contact');
    }
  }

  Future<Map<String, dynamic>> updateEmergencyContact({
    required String contactId,
    required String name,
    required String phone,
    String? relationship,
    String? email,
    bool isPrimary = false,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/sos/contacts/$contactId'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'relationship': relationship ?? 'Family',
        if (email != null && email.isNotEmpty) 'email': email,
        'is_primary': isPrimary,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to update contact');
    }
  }

  Future<void> deleteEmergencyContact(String contactId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/sos/contacts/$contactId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete emergency contact');
    }
  }

  // --- Saved Doctor Contacts ---

  Future<List<dynamic>> getDoctorContacts() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/sos/doctor-contact'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> addDoctorContact({
    required String doctorName,
    required String doctorPhone,
    String? doctorEmail,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/sos/doctor-contact'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'doctor_name': doctorName,
        'doctor_phone': doctorPhone,
        if (doctorEmail != null) 'doctor_email': doctorEmail,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to save doctor contact');
    }
  }

  Future<void> deleteDoctorContact(String id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/sos/doctor-contact/$id'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete doctor contact');
    }
  }

  // --- Emergency Message AI Assistant ---

  Future<Map<String, dynamic>> sendEmergencyAIAssistant(String prompt, {String language = 'hi'}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/sos/ai-assistant'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'prompt': prompt,
        'language': language,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Emergency Assistant failed');
    }
  }

  // --- Nearby Hospitals ---

  Future<Map<String, dynamic>> getNearbyHospitals(double lat, double lng) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/hospitals/nearby?lat=$lat&lng=$lng&radius=2000'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch nearby hospitals');
  }

  // --- SOS Triggers & Active Alerts ---

  Future<void> triggerSOS({String? lat, String? lng}) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/sos/trigger'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'location_lat': lat ?? '37.7749',
        'location_lng': lng ?? '-122.4194',
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to trigger SOS');
    }
  }

  Future<List<dynamic>> getActiveSOS() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/sos/active'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<void> resolveSOS(String alertId) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/sos/$alertId/resolve'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to resolve SOS');
    }
  }

  Future<Map<String, dynamic>> getFamilyCode() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/family/code'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch family code');
  }

  // --- Email Account Linking ---

  Future<Map<String, dynamic>> inviteFamilyByEmail(String recipientEmail) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/family/invite-email'),
      headers: await _getHeaders(),
      body: jsonEncode({'recipient_email': recipientEmail}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to send family invitation email');
    }
  }

  Future<Map<String, dynamic>> acceptFamilyEmailInvite(String invitationCode) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/family/accept-email-invite'),
      headers: await _getHeaders(),
      body: jsonEncode({'invitation_code': invitationCode}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to accept family invitation code');
    }
  }

  Future<Map<String, dynamic>> getPendingFamilyInvitations() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/family/invitations'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'sent': [], 'received': []};
  }

  // --- Email Verification ---

  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/verify-email'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'email': email,
        'code': code,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Email verification failed');
    }
  }

  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/resend-verification'),
      headers: await _getHeaders(),
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to resend verification code');
    }
  }


  // --- Password Reset ---

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password'),
      headers: await _getHeaders(),
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to send reset email');
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String code, String newPassword) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/reset-password'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'email': email,
        'code': code,
        'new_password': newPassword,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Password reset failed');
    }
  }

  // --- Admin API Methods ---

  Future<Map<String, dynamic>> adminGetStats() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/stats'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to fetch admin stats');
  }

  Future<List<dynamic>> adminGetUsers({String? search, String? role}) async {
    String url = '${ApiConfig.baseUrl}/admin/users';
    List<String> params = [];
    if (search != null && search.isNotEmpty) params.add('search=$search');
    if (role != null && role.isNotEmpty) params.add('role=$role');
    if (params.isNotEmpty) url += '?${params.join("&")}';

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  Future<Map<String, dynamic>> adminCreateUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/users'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        if (phone != null) 'phone': phone,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to create user');
    }
  }

  Future<void> adminDeleteUser(String userId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$userId'),
      headers: await _getHeaders(),
    );
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to delete user');
    }
  }

  Future<Map<String, dynamic>> adminVerifyDoctor(String doctorId, String status) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/admin/doctors/$doctorId/verify'),
      headers: await _getHeaders(),
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to verify doctor');
    }
  }



  Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/change-password'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? 'Failed to change password');
    }
  }
}

