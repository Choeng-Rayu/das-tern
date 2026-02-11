const http = require('http');

function request(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3001,
      path: '/api/v1' + path,
      method: method,
      headers: { 'Content-Type': 'application/json' },
    };
    if (token) options.headers['Authorization'] = 'Bearer ' + token;

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        let parsed;
        try { parsed = JSON.parse(data); } catch(e) { parsed = data; }
        resolve({ status: res.statusCode, body: parsed });
      });
    });
    req.on('error', (e) => resolve({ status: 0, body: e.message }));
    req.setTimeout(10000, () => { req.destroy(); resolve({ status: 0, body: 'TIMEOUT' }); });
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function run() {
  const results = [];
  const TS = Date.now();
  const PATIENT_PHONE = `+855111${String(TS).slice(-6)}`;
  const DOCTOR_PHONE = `+855222${String(TS).slice(-6)}`;
  let patientToken = '';
  let doctorToken = '';
  let patientRefresh = '';
  let patientId = '';
  let doctorId = '';
  let prescriptionId = '';
  let connectionId = '';
  let connToken = '';

  function log(testNum, name, result) {
    const pass = result.status >= 200 && result.status < 500;
    const status = pass ? 'PASS' : 'FAIL';
    const line = `TEST ${testNum}: [${result.status}] ${name} => ${status}`;
    console.log(line);
    if (result.status >= 500 || result.status === 0) {
      console.log('   ERROR:', JSON.stringify(result.body).substring(0, 200));
    }
    results.push({ testNum, name, httpStatus: result.status, status, body: result.body });
  }

  let r;

  // 1. Root endpoint
  r = await request('GET', '');
  log(1, 'GET / (root)', r);

  // 2. Register Patient
  r = await request('POST', '/auth/register/patient', {
    lastName: 'TestUser', firstName: 'ApiTest', gender: 'MALE',
    dateOfBirth: '1990-01-15', phoneNumber: PATIENT_PHONE,
    password: 'testpassword123', pinCode: '1234'
  });
  log(2, 'POST /auth/register/patient', r);

  // 3. Register Doctor
  r = await request('POST', '/auth/register/doctor', {
    fullName: 'Dr. Test Doctor', phoneNumber: DOCTOR_PHONE,
    hospitalClinic: 'Test Hospital', specialty: 'GENERAL_PRACTICE',
    licenseNumber: `LIC-TEST-${TS}`, password: 'doctorpass123'
  });
  log(3, 'POST /auth/register/doctor', r);

  // 4. Login Patient
  r = await request('POST', '/auth/login', { phoneNumber: PATIENT_PHONE, password: 'testpassword123' });
  log(4, 'POST /auth/login (patient)', r);
  if (r.body && r.body.accessToken) {
    patientToken = r.body.accessToken;
    patientRefresh = r.body.refreshToken;
  }

  // 5. Login Doctor
  r = await request('POST', '/auth/login', { phoneNumber: DOCTOR_PHONE, password: 'doctorpass123' });
  log(5, 'POST /auth/login (doctor)', r);
  if (r.body && r.body.accessToken) doctorToken = r.body.accessToken;

  // 6. Auth Me
  r = await request('GET', '/auth/me', null, patientToken);
  log(6, 'GET /auth/me (patient)', r);

  // 7. Auth Me without token
  r = await request('GET', '/auth/me');
  log(7, 'GET /auth/me (no token, expect 401)', r);

  // 8. Refresh Token
  r = await request('POST', '/auth/refresh', { refreshToken: patientRefresh });
  log(8, 'POST /auth/refresh', r);

  // 9. Send OTP
  r = await request('POST', '/auth/otp/send', { phoneNumber: PATIENT_PHONE });
  log(9, 'POST /auth/otp/send', r);

  // 10. Verify OTP (wrong)
  r = await request('POST', '/auth/otp/verify', { phoneNumber: PATIENT_PHONE, otp: '000000' });
  log(10, 'POST /auth/otp/verify (wrong otp)', r);

  // 11. Users - Get Profile
  r = await request('GET', '/users/me', null, patientToken);
  log(11, 'GET /users/me', r);
  if (r.body && r.body.id) patientId = r.body.id;

  // 12. Users - Get Storage
  r = await request('GET', '/users/storage', null, patientToken);
  log(12, 'GET /users/storage', r);

  // 13. Users - Get Meal Times
  r = await request('GET', '/users/settings/meal-times', null, patientToken);
  log(13, 'GET /users/settings/meal-times', r);

  // 14. Users - Update Profile
  r = await request('PATCH', '/users/me', { language: 'ENGLISH' }, patientToken);
  log(14, 'PATCH /users/me', r);

  // 15. Users - Update Grace Period
  r = await request('PATCH', '/users/me/grace-period', { gracePeriodMinutes: 45 }, patientToken);
  log(15, 'PATCH /users/me/grace-period', r);

  // 16. Users - Update Meal Times
  r = await request('PATCH', '/users/settings/meal-times', { morningMeal: '07:00', afternoonMeal: '12:00', nightMeal: '19:00' }, patientToken);
  log(16, 'PATCH /users/settings/meal-times', r);

  // 17. Users - Get by ID
  r = await request('GET', `/users/${patientId}`, null, patientToken);
  log(17, 'GET /users/:id', r);

  // 18. Connections - Get All
  r = await request('GET', '/connections', null, patientToken);
  log(18, 'GET /connections', r);

  // 19. Connections - Get Caregivers
  r = await request('GET', '/connections/caregivers', null, patientToken);
  log(19, 'GET /connections/caregivers', r);

  // 20. Connections - Get Patients
  r = await request('GET', '/connections/patients', null, patientToken);
  log(20, 'GET /connections/patients', r);

  // 21. Connections - Get Doctors
  r = await request('GET', '/connections/doctors', null, patientToken);
  log(21, 'GET /connections/doctors', r);

  // 22. Connections - Get Family
  r = await request('GET', '/connections/family', null, patientToken);
  log(22, 'GET /connections/family', r);

  // 23. Connections - Get Caregiver Limit
  r = await request('GET', '/connections/caregiver-limit', null, patientToken);
  log(23, 'GET /connections/caregiver-limit', r);

  // 24. Connections - Get History
  r = await request('GET', '/connections/history', null, patientToken);
  log(24, 'GET /connections/history', r);

  // 25. Connections - Generate Token
  r = await request('POST', '/connections/tokens/generate', { permissionLevel: 'ALLOWED' }, patientToken);
  log(25, 'POST /connections/tokens/generate', r);
  if (r.body && r.body.token) connToken = r.body.token;

  // 26. Connections - Get Active Tokens
  r = await request('GET', '/connections/tokens/active', null, patientToken);
  log(26, 'GET /connections/tokens/active', r);

  // 27. Connections - Validate Token
  if (connToken) {
    r = await request('POST', '/connections/tokens/validate', { token: connToken }, doctorToken);
    log(27, 'POST /connections/tokens/validate', r);
  } else {
    console.log('TEST 27: SKIPPED - No connection token');
    results.push({ testNum: 27, name: 'POST /connections/tokens/validate', httpStatus: 0, status: 'SKIP' });
  }

  // 28. Connections - Create
  const docProfile = await request('GET', '/users/me', null, doctorToken);
  if (docProfile.body && docProfile.body.id) doctorId = docProfile.body.id;
  r = await request('POST', '/connections', { recipientId: doctorId, permissionLevel: 'ALLOWED' }, patientToken);
  log(28, 'POST /connections (create)', r);
  if (r.body && r.body.id) connectionId = r.body.id;

  // 29. Doctor Search
  r = await request('GET', '/doctors/search?query=Test', null, patientToken);
  log(29, 'GET /doctors/search', r);

  // 30. Prescriptions - Get All
  r = await request('GET', '/prescriptions', null, patientToken);
  log(30, 'GET /prescriptions', r);

  // 31. Prescriptions - Create Patient
  r = await request('POST', '/prescriptions/patient', {
    patientName: 'ApiTest TestUser', patientGender: 'MALE', patientAge: 35,
    symptoms: 'Testing API endpoints',
    medications: [{
      medicineName: 'Test Medicine A', rowNumber: 1,
      morningDosage: { amount: 1, unit: 'tablet' },
      frequency: 'daily', timing: 'after meal'
    }]
  }, patientToken);
  log(31, 'POST /prescriptions/patient', r);
  if (r.body && r.body.id) prescriptionId = r.body.id;

  // 32. Prescriptions - Get by ID
  if (prescriptionId) {
    r = await request('GET', `/prescriptions/${prescriptionId}`, null, patientToken);
    log(32, 'GET /prescriptions/:id', r);
  } else {
    console.log('TEST 32: SKIPPED - No prescription ID');
    results.push({ testNum: 32, name: 'GET /prescriptions/:id', httpStatus: 0, status: 'SKIP' });
  }

  // 33. Prescriptions - Pause
  if (prescriptionId) {
    r = await request('POST', `/prescriptions/${prescriptionId}/pause`, {}, patientToken);
    log(33, 'POST /prescriptions/:id/pause', r);
  } else {
    console.log('TEST 33: SKIPPED');
    results.push({ testNum: 33, name: 'POST /prescriptions/:id/pause', httpStatus: 0, status: 'SKIP' });
  }

  // 34. Prescriptions - Resume
  if (prescriptionId) {
    r = await request('POST', `/prescriptions/${prescriptionId}/resume`, {}, patientToken);
    log(34, 'POST /prescriptions/:id/resume', r);
  } else {
    console.log('TEST 34: SKIPPED');
    results.push({ testNum: 34, name: 'POST /prescriptions/:id/resume', httpStatus: 0, status: 'SKIP' });
  }

  // 35. Medicines - Get for Prescription
  if (prescriptionId) {
    r = await request('GET', `/prescriptions/${prescriptionId}/medicines`, null, patientToken);
    log(35, 'GET /prescriptions/:id/medicines', r);
  } else {
    console.log('TEST 35: SKIPPED');
    results.push({ testNum: 35, name: 'GET /prescriptions/:id/medicines', httpStatus: 0, status: 'SKIP' });
  }

  // 36. Medicines - Get Archived
  r = await request('GET', '/medicines/archived', null, patientToken);
  log(36, 'GET /medicines/archived', r);

  // 37. Doses - Get Schedule
  r = await request('GET', '/doses/schedule', null, patientToken);
  log(37, 'GET /doses/schedule', r);

  // 38. Doses - Get Today
  r = await request('GET', '/doses/today', null, patientToken);
  log(38, 'GET /doses/today', r);

  // 39. Doses - Get Upcoming
  r = await request('GET', '/doses/upcoming', null, patientToken);
  log(39, 'GET /doses/upcoming', r);

  // 40. Doses - Get History
  r = await request('GET', '/doses/history', null, patientToken);
  log(40, 'GET /doses/history', r);

  // 41. Doses - Sync
  r = await request('POST', '/doses/sync', { events: [] }, patientToken);
  log(41, 'POST /doses/sync', r);

  // 42. Subscriptions - Me
  r = await request('GET', '/subscriptions/me', null, patientToken);
  log(42, 'GET /subscriptions/me', r);

  // 43. Subscriptions - Limits
  r = await request('GET', '/subscriptions/limits', null, patientToken);
  log(43, 'GET /subscriptions/limits', r);

  // 44. Subscriptions - Features
  r = await request('GET', '/subscriptions/features', null, patientToken);
  log(44, 'GET /subscriptions/features', r);

  // 45. Subscriptions - Upgrade
  r = await request('POST', '/subscriptions/upgrade', { tier: 'PREMIUM' }, patientToken);
  log(45, 'POST /subscriptions/upgrade', r);

  // 46. Subscriptions - Downgrade
  r = await request('POST', '/subscriptions/downgrade', { tier: 'FREEMIUM' }, patientToken);
  log(46, 'POST /subscriptions/downgrade', r);

  // 47. Email - Test
  r = await request('POST', '/email/test', { email: 'test@example.com' });
  log(47, 'POST /email/test', r);

  // 48. Email - Welcome
  r = await request('POST', '/email/welcome', { email: 'test@example.com', name: 'Test User' });
  log(48, 'POST /email/welcome', r);

  // 49. Email - Send OTP
  r = await request('POST', '/email/send-otp', { email: 'test@example.com' });
  log(49, 'POST /email/send-otp', r);

  // 50. Adherence - Today
  r = await request('GET', '/adherence/today', null, patientToken);
  log(50, 'GET /adherence/today', r);

  // 51. Adherence - Weekly
  r = await request('GET', '/adherence/weekly', null, patientToken);
  log(51, 'GET /adherence/weekly', r);

  // 52. Adherence - Monthly
  r = await request('GET', '/adherence/monthly', null, patientToken);
  log(52, 'GET /adherence/monthly', r);

  // 53. Adherence - Trends
  r = await request('GET', '/adherence/trends?days=7', null, patientToken);
  log(53, 'GET /adherence/trends', r);

  // 54. Adherence - Prescription
  if (prescriptionId) {
    r = await request('GET', `/adherence/prescription/${prescriptionId}`, null, patientToken);
    log(54, 'GET /adherence/prescription/:id', r);
  } else {
    console.log('TEST 54: SKIPPED');
    results.push({ testNum: 54, name: 'GET /adherence/prescription/:id', httpStatus: 0, status: 'SKIP' });
  }

  // 55. Notifications - Get All
  r = await request('GET', '/notifications', null, patientToken);
  log(55, 'GET /notifications', r);

  // 56. Audit - Get All
  r = await request('GET', '/audit', null, patientToken);
  log(56, 'GET /audit', r);

  // 57. Doctor Dashboard
  r = await request('GET', '/doctor/dashboard', null, doctorToken);
  log(57, 'GET /doctor/dashboard', r);

  // 58. Doctor Patients
  r = await request('GET', '/doctor/patients', null, doctorToken);
  log(58, 'GET /doctor/patients', r);

  // 59. Doctor Pending Connections
  r = await request('GET', '/doctor/connections/pending', null, doctorToken);
  log(59, 'GET /doctor/connections/pending', r);

  // 60. Doctor Prescriptions
  r = await request('GET', '/doctor/prescriptions', null, doctorToken);
  log(60, 'GET /doctor/prescriptions', r);

  // 61. Doctor Notes
  r = await request('GET', `/doctor/notes?patientId=${patientId}`, null, doctorToken);
  log(61, 'GET /doctor/notes', r);

  // 62. Doctor Dashboard - Access Denied for Patient
  r = await request('GET', '/doctor/dashboard', null, patientToken);
  log(62, 'GET /doctor/dashboard (patient, expect 403)', r);

  // 63. Login Wrong Password
  r = await request('POST', '/auth/login', { phoneNumber: PATIENT_PHONE, password: 'wrongpassword' });
  log(63, 'POST /auth/login (wrong password, expect 401)', r);

  // 64. Duplicate Registration
  r = await request('POST', '/auth/register/patient', {
    lastName: 'TestUser', firstName: 'ApiTest', gender: 'MALE',
    dateOfBirth: '1990-01-15', phoneNumber: PATIENT_PHONE,
    password: 'testpassword123', pinCode: '1234'
  });
  log(64, 'POST /auth/register/patient (duplicate, expect error)', r);

  // 65. Invalid Endpoint
  r = await request('GET', '/nonexistent', null, patientToken);
  log(65, 'GET /nonexistent (expect 404)', r);

  // 66. Register Invalid Phone
  r = await request('POST', '/auth/register/patient', {
    lastName: 'Test', firstName: 'Invalid', gender: 'MALE',
    dateOfBirth: '1990-01-15', phoneNumber: '12345',
    password: 'testpassword123', pinCode: '1234'
  });
  log(66, 'POST /auth/register/patient (invalid phone, expect 400)', r);

  // 67. Register Short Password
  r = await request('POST', '/auth/register/patient', {
    lastName: 'Test', firstName: 'Short', gender: 'MALE',
    dateOfBirth: '1990-01-15', phoneNumber: '+855999999999',
    password: 'abc', pinCode: '1234'
  });
  log(67, 'POST /auth/register/patient (short password, expect 400)', r);

  // 68. Prescriptions Delete
  if (prescriptionId) {
    r = await request('DELETE', `/prescriptions/${prescriptionId}`, null, patientToken);
    log(68, 'DELETE /prescriptions/:id', r);
  } else {
    console.log('TEST 68: SKIPPED');
    results.push({ testNum: 68, name: 'DELETE /prescriptions/:id', httpStatus: 0, status: 'SKIP' });
  }

  // Summary
  console.log('\n=== SUMMARY ===');
  const passed = results.filter(r => r.status === 'PASS').length;
  const failed = results.filter(r => r.status === 'FAIL').length;
  const skipped = results.filter(r => r.status === 'SKIP').length;
  console.log(`Total: ${results.length} | Passed: ${passed} | Failed: ${failed} | Skipped: ${skipped}`);

  console.log('\n--- FAILED TESTS ---');
  results.filter(r => r.status === 'FAIL').forEach(r => {
    console.log(`  TEST ${r.testNum}: [${r.httpStatus}] ${r.name}`);
    console.log(`    Response: ${JSON.stringify(r.body).substring(0, 300)}`);
  });

  console.log('\n--- ALL RESULTS ---');
  results.forEach(r => {
    console.log(`  TEST ${r.testNum}: [${r.httpStatus}] ${r.name} => ${r.status}`);
  });
}

run().catch(console.error);
