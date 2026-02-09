import { PrismaClient } from '@prisma/client'
import bcrypt from 'bcryptjs'

const prisma = new PrismaClient()

async function main() {
  console.log('🌱 Starting database seed...')

  // Clear existing data (development only)
  console.log('🗑️  Clearing existing data...')
  await prisma.doseEvent.deleteMany()
  await prisma.medication.deleteMany()
  await prisma.prescriptionVersion.deleteMany()
  await prisma.prescription.deleteMany()
  await prisma.notification.deleteMany()
  await prisma.auditLog.deleteMany()
  await prisma.familyMember.deleteMany()
  await prisma.subscription.deleteMany()
  await prisma.mealTimePreference.deleteMany()
  await prisma.connection.deleteMany()
  await prisma.user.deleteMany()

  console.log('✅ Existing data cleared')

  // Hash passwords (all test users use 'password123')
  const passwordHash = await bcrypt.hash('password123', 10)
  const pinCodeHash = await bcrypt.hash('1234', 10)

  // ============================================
  // CREATE TEST USERS
  // ============================================
  console.log('👤 Creating test users...')

  // PATIENTS (at least 3)
  const patient1 = await prisma.user.create({
    data: {
      role: 'PATIENT',
      firstName: 'Sokha',
      lastName: 'Chan',
      fullName: 'Sokha Chan',
      phoneNumber: '+85512345678',
      email: 'sokha.chan@example.com',
      passwordHash,
      pinCodeHash,
      gender: 'MALE',
      dateOfBirth: new Date('1990-05-15'),
      idCardNumber: 'ID001234567',
      language: 'KHMER',
      theme: 'LIGHT',
      accountStatus: 'ACTIVE',
    },
  })

  const patient2 = await prisma.user.create({
    data: {
      role: 'PATIENT',
      firstName: 'Sreymom',
      lastName: 'Pich',
      fullName: 'Sreymom Pich',
      phoneNumber: '+85512345679',
      email: 'sreymom.pich@example.com',
      passwordHash,
      pinCodeHash,
      gender: 'FEMALE',
      dateOfBirth: new Date('1985-08-20'),
      idCardNumber: 'ID001234568',
      language: 'KHMER',
      theme: 'DARK',
      accountStatus: 'ACTIVE',
    },
  })

  const patient3 = await prisma.user.create({
    data: {
      role: 'PATIENT',
      firstName: 'Bopha',
      lastName: 'Lim',
      fullName: 'Bopha Lim',
      phoneNumber: '+85512345682',
      email: 'bopha.lim@example.com',
      passwordHash,
      pinCodeHash,
      gender: 'FEMALE',
      dateOfBirth: new Date('1995-12-03'),
      idCardNumber: 'ID001234569',
      language: 'ENGLISH',
      theme: 'LIGHT',
      accountStatus: 'ACTIVE',
    },
  })

  const patient4 = await prisma.user.create({
    data: {
      role: 'PATIENT',
      firstName: 'Virak',
      lastName: 'Heng',
      fullName: 'Virak Heng',
      phoneNumber: '+85512345683',
      email: 'virak.heng@example.com',
      passwordHash,
      pinCodeHash,
      gender: 'MALE',
      dateOfBirth: new Date('1978-07-22'),
      idCardNumber: 'ID001234570',
      language: 'KHMER',
      theme: 'LIGHT',
      accountStatus: 'ACTIVE',
    },
  })

  // DOCTORS (at least 3 with different specialties)
  const doctor1 = await prisma.user.create({
    data: {
      role: 'DOCTOR',
      fullName: 'Dr. Vanna Sok',
      phoneNumber: '+85512345680',
      email: 'vanna.sok@hospital.com',
      passwordHash,
      gender: 'MALE',
      dateOfBirth: new Date('1975-03-10'),
      language: 'ENGLISH',
      theme: 'LIGHT',
      hospitalClinic: 'Calmette Hospital',
      specialty: 'Internal Medicine',
      licenseNumber: 'DOC-2024-001',
      accountStatus: 'VERIFIED',
    },
  })

  const doctor2 = await prisma.user.create({
    data: {
      role: 'DOCTOR',
      fullName: 'Dr. Sophea Meas',
      phoneNumber: '+85512345684',
      email: 'sophea.meas@hospital.com',
      passwordHash,
      gender: 'FEMALE',
      dateOfBirth: new Date('1980-09-15'),
      language: 'KHMER',
      theme: 'LIGHT',
      hospitalClinic: 'Khmer-Soviet Friendship Hospital',
      specialty: 'Cardiology',
      licenseNumber: 'DOC-2024-002',
      accountStatus: 'VERIFIED',
    },
  })

  const doctor3 = await prisma.user.create({
    data: {
      role: 'DOCTOR',
      fullName: 'Dr. Ratana Chea',
      phoneNumber: '+85512345685',
      email: 'ratana.chea@hospital.com',
      passwordHash,
      gender: 'FEMALE',
      dateOfBirth: new Date('1982-04-28'),
      language: 'ENGLISH',
      theme: 'DARK',
      hospitalClinic: 'Royal Phnom Penh Hospital',
      specialty: 'Endocrinology',
      licenseNumber: 'DOC-2024-003',
      accountStatus: 'VERIFIED',
    },
  })

  const doctor4 = await prisma.user.create({
    data: {
      role: 'DOCTOR',
      fullName: 'Dr. Kosal Rath',
      phoneNumber: '+85512345686',
      email: 'kosal.rath@hospital.com',
      passwordHash,
      gender: 'MALE',
      dateOfBirth: new Date('1978-11-05'),
      language: 'KHMER',
      theme: 'LIGHT',
      hospitalClinic: 'Sunrise Japan Hospital',
      specialty: 'General Practice',
      licenseNumber: 'DOC-2024-004',
      accountStatus: 'VERIFIED',
    },
  })

  // FAMILY MEMBERS (at least 3)
  const familyMember1 = await prisma.user.create({
    data: {
      role: 'FAMILY_MEMBER',
      firstName: 'Dara',
      lastName: 'Chan',
      fullName: 'Dara Chan',
      phoneNumber: '+85512345681',
      email: 'dara.chan@example.com',
      passwordHash,
      gender: 'MALE',
      dateOfBirth: new Date('1988-11-25'),
      language: 'KHMER',
      theme: 'LIGHT',
      accountStatus: 'ACTIVE',
    },
  })

  const familyMember2 = await prisma.user.create({
    data: {
      role: 'FAMILY_MEMBER',
      firstName: 'Chenda',
      lastName: 'Pich',
      fullName: 'Chenda Pich',
      phoneNumber: '+85512345687',
      email: 'chenda.pich@example.com',
      passwordHash,
      gender: 'FEMALE',
      dateOfBirth: new Date('1992-06-18'),
      language: 'KHMER',
      theme: 'LIGHT',
      accountStatus: 'ACTIVE',
    },
  })

  const familyMember3 = await prisma.user.create({
    data: {
      role: 'FAMILY_MEMBER',
      firstName: 'Samnang',
      lastName: 'Lim',
      fullName: 'Samnang Lim',
      phoneNumber: '+85512345688',
      email: 'samnang.lim@example.com',
      passwordHash,
      gender: 'MALE',
      dateOfBirth: new Date('1993-02-14'),
      language: 'ENGLISH',
      theme: 'DARK',
      accountStatus: 'ACTIVE',
    },
  })

  console.log('✅ Created 11 test users (4 patients, 4 doctors, 3 family members)')

  // ============================================
  // CREATE SUBSCRIPTIONS
  // ============================================
  console.log('💳 Creating subscriptions...')

  await prisma.subscription.create({
    data: {
      userId: patient1.id,
      tier: 'FREEMIUM',
      storageQuota: 5368709120, // 5GB
      storageUsed: 1073741824, // 1GB used
    },
  })

  await prisma.subscription.create({
    data: {
      userId: patient2.id,
      tier: 'PREMIUM',
      storageQuota: 21474836480, // 20GB
      storageUsed: 5368709120, // 5GB used
    },
  })

  await prisma.subscription.create({
    data: {
      userId: patient3.id,
      tier: 'FAMILY_PREMIUM',
      storageQuota: 21474836480, // 20GB
      storageUsed: 2147483648, // 2GB used
    },
  })

  await prisma.subscription.create({
    data: {
      userId: patient4.id,
      tier: 'FREEMIUM',
      storageQuota: 5368709120, // 5GB
      storageUsed: 536870912, // 0.5GB used
    },
  })

  console.log('✅ Created 4 subscriptions (2 FREEMIUM, 1 PREMIUM, 1 FAMILY_PREMIUM)')

  // ============================================
  // CREATE MEAL TIME PREFERENCES
  // ============================================
  console.log('🍽️  Creating meal time preferences...')

  await prisma.mealTimePreference.create({
    data: {
      userId: patient1.id,
      morningMeal: '7-8AM',
      afternoonMeal: '12-1PM',
      nightMeal: '6-7PM',
    },
  })

  await prisma.mealTimePreference.create({
    data: {
      userId: patient2.id,
      morningMeal: '6-7AM',
      afternoonMeal: '1-2PM',
      nightMeal: '7-8PM',
    },
  })

  await prisma.mealTimePreference.create({
    data: {
      userId: patient3.id,
      morningMeal: '8-9AM',
      afternoonMeal: '12-1PM',
      nightMeal: '8-9PM',
    },
  })

  await prisma.mealTimePreference.create({
    data: {
      userId: patient4.id,
      morningMeal: '7-8AM',
      afternoonMeal: '12-1PM',
      nightMeal: '6-7PM',
    },
  })

  console.log('✅ Created 4 meal time preferences')

  // ============================================
  // CREATE CONNECTIONS
  // ============================================
  console.log('🔗 Creating connections...')

  // Doctor-Patient connections with different permission levels
  const connection1 = await prisma.connection.create({
    data: {
      initiatorId: doctor1.id,
      recipientId: patient1.id,
      status: 'ACCEPTED',
      permissionLevel: 'ALLOWED',
      requestedAt: new Date('2025-01-15T10:00:00+07:00'),
      acceptedAt: new Date('2025-01-15T11:30:00+07:00'),
    },
  })

  const connection2 = await prisma.connection.create({
    data: {
      initiatorId: doctor2.id,
      recipientId: patient2.id,
      status: 'ACCEPTED',
      permissionLevel: 'SELECTED',
      requestedAt: new Date('2025-01-20T09:00:00+07:00'),
      acceptedAt: new Date('2025-01-20T14:00:00+07:00'),
    },
  })

  const connection3 = await prisma.connection.create({
    data: {
      initiatorId: doctor3.id,
      recipientId: patient3.id,
      status: 'ACCEPTED',
      permissionLevel: 'REQUEST',
      requestedAt: new Date('2025-02-01T08:00:00+07:00'),
      acceptedAt: new Date('2025-02-01T10:00:00+07:00'),
    },
  })

  const connection4 = await prisma.connection.create({
    data: {
      initiatorId: doctor4.id,
      recipientId: patient4.id,
      status: 'ACCEPTED',
      permissionLevel: 'ALLOWED',
      requestedAt: new Date('2025-02-05T13:00:00+07:00'),
      acceptedAt: new Date('2025-02-05T15:00:00+07:00'),
    },
  })

  // Pending connection
  const connection5 = await prisma.connection.create({
    data: {
      initiatorId: doctor1.id,
      recipientId: patient3.id,
      status: 'PENDING',
      permissionLevel: 'ALLOWED',
      requestedAt: new Date('2025-02-08T10:00:00+07:00'),
    },
  })

  // Family-Patient connections
  const connection6 = await prisma.connection.create({
    data: {
      initiatorId: familyMember1.id,
      recipientId: patient1.id,
      status: 'ACCEPTED',
      permissionLevel: 'ALLOWED',
      requestedAt: new Date('2025-01-10T08:00:00+07:00'),
      acceptedAt: new Date('2025-01-10T09:00:00+07:00'),
    },
  })

  const connection7 = await prisma.connection.create({
    data: {
      initiatorId: familyMember2.id,
      recipientId: patient2.id,
      status: 'ACCEPTED',
      permissionLevel: 'ALLOWED',
      requestedAt: new Date('2025-01-18T07:00:00+07:00'),
      acceptedAt: new Date('2025-01-18T08:00:00+07:00'),
    },
  })

  const connection8 = await prisma.connection.create({
    data: {
      initiatorId: familyMember3.id,
      recipientId: patient3.id,
      status: 'ACCEPTED',
      permissionLevel: 'SELECTED',
      requestedAt: new Date('2025-02-03T11:00:00+07:00'),
      acceptedAt: new Date('2025-02-03T12:00:00+07:00'),
    },
  })

  console.log('✅ Created 8 connections (4 doctor-patient, 3 family-patient, 1 pending)')

  // ============================================
  // CREATE PRESCRIPTIONS
  // ============================================
  console.log('💊 Creating prescriptions...')

  // Active prescription for patient1
  const prescription1 = await prisma.prescription.create({
    data: {
      patientId: patient1.id,
      doctorId: doctor1.id,
      patientName: patient1.fullName!,
      patientGender: patient1.gender!,
      patientAge: 34,
      symptoms: 'ឈឺក្បាល និង សម្ពាធឈាមខ្ពស់ (Headache and Hypertension)',
      status: 'ACTIVE',
      currentVersion: 1,
      isUrgent: false,
      createdAt: new Date('2025-01-16T09:00:00+07:00'),
    },
  })

  // Active prescription for patient2 with version history
  const prescription2 = await prisma.prescription.create({
    data: {
      patientId: patient2.id,
      doctorId: doctor2.id,
      patientName: patient2.fullName!,
      patientGender: patient2.gender!,
      patientAge: 39,
      symptoms: 'ជំងឺទឹកនោមផ្អែម និង ឈឺជង្គង់ (Diabetes and Knee Pain)',
      status: 'ACTIVE',
      currentVersion: 2,
      isUrgent: false,
      createdAt: new Date('2025-01-21T10:00:00+07:00'),
    },
  })

  // Draft prescription for patient3
  const prescription3 = await prisma.prescription.create({
    data: {
      patientId: patient3.id,
      doctorId: doctor3.id,
      patientName: patient3.fullName!,
      patientGender: patient3.gender!,
      patientAge: 29,
      symptoms: 'ហត់នឿយ និង គ្មានថាមពល (Fatigue and Low Energy)',
      status: 'DRAFT',
      currentVersion: 1,
      isUrgent: false,
      createdAt: new Date('2025-02-07T14:00:00+07:00'),
    },
  })

  // Urgent prescription for patient4
  const prescription4 = await prisma.prescription.create({
    data: {
      patientId: patient4.id,
      doctorId: doctor4.id,
      patientName: patient4.fullName!,
      patientGender: patient4.gender!,
      patientAge: 46,
      symptoms: 'ឈឺទ្រូង និង លំបាកដកដង្ហើម (Chest Pain and Breathing Difficulty)',
      status: 'ACTIVE',
      currentVersion: 1,
      isUrgent: true,
      urgentReason: 'Patient experiencing acute chest pain, immediate medication required',
      createdAt: new Date('2025-02-08T08:00:00+07:00'),
    },
  })

  // Paused prescription for patient1
  const prescription5 = await prisma.prescription.create({
    data: {
      patientId: patient1.id,
      doctorId: doctor1.id,
      patientName: patient1.fullName!,
      patientGender: patient1.gender!,
      patientAge: 34,
      symptoms: 'ឈឺពោះ (Stomach Pain)',
      status: 'PAUSED',
      currentVersion: 1,
      isUrgent: false,
      createdAt: new Date('2025-01-05T11:00:00+07:00'),
    },
  })

  console.log('✅ Created 5 prescriptions (3 active, 1 draft, 1 paused)')

  // ============================================
  // CREATE MEDICATIONS
  // ============================================
  console.log('💊 Creating medications...')

  // Medications for prescription1 (patient1 - Hypertension)
  const med1_1 = await prisma.medication.create({
    data: {
      prescriptionId: prescription1.id,
      rowNumber: 1,
      medicineName: 'Amlodipine',
      medicineNameKhmer: 'អាមឡូឌីពីន',
      morningDosage: { amount: '5mg', beforeMeal: false },
      frequency: '1ដង/១ថ្ងៃ',
      timing: 'បន្ទាប់ពីអាហារ',
      imageUrl: 'https://example.com/images/amlodipine.jpg',
    },
  })

  const med1_2 = await prisma.medication.create({
    data: {
      prescriptionId: prescription1.id,
      rowNumber: 2,
      medicineName: 'Paracetamol',
      medicineNameKhmer: 'ប៉ារ៉ាសេតាម៉ុល',
      morningDosage: { amount: '500mg', beforeMeal: false },
      nightDosage: { amount: '500mg', beforeMeal: false },
      frequency: '2ដង/១ថ្ងៃ',
      timing: 'បន្ទាប់ពីអាហារ',
      imageUrl: 'https://example.com/images/paracetamol.jpg',
    },
  })

  // Medications for prescription2 (patient2 - Diabetes)
  const med2_1 = await prisma.medication.create({
    data: {
      prescriptionId: prescription2.id,
      rowNumber: 1,
      medicineName: 'Metformin',
      medicineNameKhmer: 'មេតហ្វរមីន',
      morningDosage: { amount: '500mg', beforeMeal: true },
      nightDosage: { amount: '500mg', beforeMeal: true },
      frequency: '2ដង/១ថ្ងៃ',
      timing: 'មុនអាហារ',
      imageUrl: 'https://example.com/images/metformin.jpg',
    },
  })

  const med2_2 = await prisma.medication.create({
    data: {
      prescriptionId: prescription2.id,
      rowNumber: 2,
      medicineName: 'Ibuprofen',
      medicineNameKhmer: 'អ៊ីប៊ូប្រូហ្វេន',
      daytimeDosage: { amount: '400mg', beforeMeal: false },
      nightDosage: { amount: '400mg', beforeMeal: false },
      frequency: '2ដង/១ថ្ងៃ',
      timing: 'បន្ទាប់ពីអាហារ',
    },
  })

  const med2_3 = await prisma.medication.create({
    data: {
      prescriptionId: prescription2.id,
      rowNumber: 3,
      medicineName: 'Vitamin D',
      medicineNameKhmer: 'វីតាមីន ឌី',
      morningDosage: { amount: '1000IU', beforeMeal: false },
      frequency: '1ដង/១ថ្ងៃ',
      timing: 'បន្ទាប់ពីអាហារ',
    },
  })

  // Medications for prescription3 (patient3 - Draft)
  const med3_1 = await prisma.medication.create({
    data: {
      prescriptionId: prescription3.id,
      rowNumber: 1,
      medicineName: 'Multivitamin',
      medicineNameKhmer: 'វីតាមីនច្រើនប្រភេទ',
      morningDosage: { amount: '1 tablet', beforeMeal: false },
      frequency: '1ដង/១ថ្ងៃ',
      timing: 'បន្ទាប់ពីអាហារ',
    },
  })

  // Medications for prescription4 (patient4 - Urgent)
  const med4_1 = await prisma.medication.create({
    data: {
      prescriptionId: prescription4.id,
      rowNumber: 1,
      medicineName: 'Aspirin',
      medicineNameKhmer: 'អាស្ពីរីន',
      morningDosage: { amount: '100mg', beforeMeal: false },
      frequency: '1ដង/១ថ្ងៃ',
      timing: 'បន្ទាប់ពីអាហារ',
    },
  })

  const med4_2 = await prisma.medication.create({
    data: {
      prescriptionId: prescription4.id,
      rowNumber: 2,
      medicineName: 'Atorvastatin',
      medicineNameKhmer: 'អាតូវ៉ាស្តាទីន',
      nightDosage: { amount: '20mg', beforeMeal: false },
      frequency: '1ដង/១ថ្ងៃ',
      timing: 'បន្ទាប់ពីអាហារ',
    },
  })

  const med4_3 = await prisma.medication.create({
    data: {
      prescriptionId: prescription4.id,
      rowNumber: 3,
      medicineName: 'Nitroglycerin',
      medicineNameKhmer: 'នីត្រូគ្លីសេរីន',
      morningDosage: { amount: '0.4mg', beforeMeal: false },
      daytimeDosage: { amount: '0.4mg', beforeMeal: false },
      nightDosage: { amount: '0.4mg', beforeMeal: false },
      frequency: 'តាមតម្រូវការ (PRN)',
      timing: 'តាមតម្រូវការ',
    },
  })

  // Medications for prescription5 (patient1 - Paused)
  const med5_1 = await prisma.medication.create({
    data: {
      prescriptionId: prescription5.id,
      rowNumber: 1,
      medicineName: 'Omeprazole',
      medicineNameKhmer: 'អូមេប្រាហ្សូល',
      morningDosage: { amount: '20mg', beforeMeal: true },
      frequency: '1ដង/១ថ្ងៃ',
      timing: 'មុនអាហារ',
    },
  })

  console.log('✅ Created 11 medications across 5 prescriptions')

  // ============================================
  // CREATE PRESCRIPTION VERSIONS
  // ============================================
  console.log('📝 Creating prescription versions...')

  // Version 1 for prescription1
  await prisma.prescriptionVersion.create({
    data: {
      prescriptionId: prescription1.id,
      versionNumber: 1,
      authorId: doctor1.id,
      changeReason: 'Initial prescription for hypertension management',
      medicationsSnapshot: [
        {
          rowNumber: 1,
          medicineName: 'Amlodipine',
          medicineNameKhmer: 'អាមឡូឌីពីន',
          morningDosage: { amount: '5mg', beforeMeal: false },
          frequency: '1ដង/១ថ្ងៃ',
          timing: 'បន្ទាប់ពីអាហារ',
        },
        {
          rowNumber: 2,
          medicineName: 'Paracetamol',
          medicineNameKhmer: 'ប៉ារ៉ាសេតាម៉ុល',
          morningDosage: { amount: '500mg', beforeMeal: false },
          nightDosage: { amount: '500mg', beforeMeal: false },
          frequency: '2ដង/១ថ្ងៃ',
          timing: 'បន្ទាប់ពីអាហារ',
        },
      ],
      createdAt: new Date('2025-01-16T09:00:00+07:00'),
    },
  })

  // Version 1 for prescription2
  await prisma.prescriptionVersion.create({
    data: {
      prescriptionId: prescription2.id,
      versionNumber: 1,
      authorId: doctor2.id,
      changeReason: 'Initial prescription for diabetes management',
      medicationsSnapshot: [
        {
          rowNumber: 1,
          medicineName: 'Metformin',
          medicineNameKhmer: 'មេតហ្វរមីន',
          morningDosage: { amount: '500mg', beforeMeal: true },
          nightDosage: { amount: '500mg', beforeMeal: true },
          frequency: '2ដង/១ថ្ងៃ',
          timing: 'មុនអាហារ',
        },
      ],
      createdAt: new Date('2025-01-21T10:00:00+07:00'),
    },
  })

  // Version 2 for prescription2 (updated)
  await prisma.prescriptionVersion.create({
    data: {
      prescriptionId: prescription2.id,
      versionNumber: 2,
      authorId: doctor2.id,
      changeReason: 'Added pain medication and vitamin supplement based on patient feedback',
      medicationsSnapshot: [
        {
          rowNumber: 1,
          medicineName: 'Metformin',
          medicineNameKhmer: 'មេតហ្វរមីន',
          morningDosage: { amount: '500mg', beforeMeal: true },
          nightDosage: { amount: '500mg', beforeMeal: true },
          frequency: '2ដង/១ថ្ងៃ',
          timing: 'មុនអាហារ',
        },
        {
          rowNumber: 2,
          medicineName: 'Ibuprofen',
          medicineNameKhmer: 'អ៊ីប៊ូប្រូហ្វេន',
          daytimeDosage: { amount: '400mg', beforeMeal: false },
          nightDosage: { amount: '400mg', beforeMeal: false },
          frequency: '2ដង/១ថ្ងៃ',
          timing: 'បន្ទាប់ពីអាហារ',
        },
        {
          rowNumber: 3,
          medicineName: 'Vitamin D',
          medicineNameKhmer: 'វីតាមីន ឌី',
          morningDosage: { amount: '1000IU', beforeMeal: false },
          frequency: '1ដង/១ថ្ងៃ',
          timing: 'បន្ទាប់ពីអាហារ',
        },
      ],
      createdAt: new Date('2025-01-28T11:00:00+07:00'),
    },
  })

  // Version 1 for prescription4 (urgent)
  await prisma.prescriptionVersion.create({
    data: {
      prescriptionId: prescription4.id,
      versionNumber: 1,
      authorId: doctor4.id,
      changeReason: 'Urgent prescription for acute chest pain management',
      medicationsSnapshot: [
        {
          rowNumber: 1,
          medicineName: 'Aspirin',
          medicineNameKhmer: 'អាស្ពីរីន',
          morningDosage: { amount: '100mg', beforeMeal: false },
          frequency: '1ដង/១ថ្ងៃ',
          timing: 'បន្ទាប់ពីអាហារ',
        },
        {
          rowNumber: 2,
          medicineName: 'Atorvastatin',
          medicineNameKhmer: 'អាតូវ៉ាស្តាទីន',
          nightDosage: { amount: '20mg', beforeMeal: false },
          frequency: '1ដង/១ថ្ងៃ',
          timing: 'បន្ទាប់ពីអាហារ',
        },
        {
          rowNumber: 3,
          medicineName: 'Nitroglycerin',
          medicineNameKhmer: 'នីត្រូគ្លីសេរីន',
          morningDosage: { amount: '0.4mg', beforeMeal: false },
          daytimeDosage: { amount: '0.4mg', beforeMeal: false },
          nightDosage: { amount: '0.4mg', beforeMeal: false },
          frequency: 'តាមតម្រូវការ (PRN)',
          timing: 'តាមតម្រូវការ',
        },
      ],
      createdAt: new Date('2025-02-08T08:00:00+07:00'),
    },
  })

  console.log('✅ Created 4 prescription versions')

  // ============================================
  // CREATE DOSE EVENTS
  // ============================================
  console.log('📅 Creating dose events...')

  // Helper function to create dates in Cambodia timezone
  const createCambodiaDate = (dateStr: string, hour: number, minute: number = 0) => {
    const date = new Date(dateStr)
    date.setHours(hour, minute, 0, 0)
    return date
  }

  // Dose events for prescription1 (patient1) - Today and recent days
  const today = new Date()
  const yesterday = new Date(today)
  yesterday.setDate(yesterday.getDate() - 1)
  const twoDaysAgo = new Date(today)
  twoDaysAgo.setDate(twoDaysAgo.getDate() - 2)

  // Today's doses
  await prisma.doseEvent.create({
    data: {
      prescriptionId: prescription1.id,
      medicationId: med1_1.id,
      patientId: patient1.id,
      scheduledTime: createCambodiaDate(today.toISOString(), 7, 30),
      timePeriod: 'DAYTIME',
      reminderTime: '07:30',
      status: 'TAKEN_ON_TIME',
      takenAt: createCambodiaDate(today.toISOString(), 7, 35),
    },
  })

  await prisma.doseEvent.create({
    data: {
      prescriptionId: prescription1.id,
      medicationId: med1_2.id,
      patientId: patient1.id,
      scheduledTime: createCambodiaDate(today.toISOString(), 7, 30),
      timePeriod: 'DAYTIME',
      reminderTime: '07:30',
      status: 'DUE',
    },
  })

  await prisma.doseEvent.create({
    data: {
      prescriptionId: prescription1.id,
      medicationId: med1_2.id,
      patientId: patient1.id,
      scheduledTime: createCambodiaDate(today.toISOString(), 19, 0),
      timePeriod: 'NIGHT',
      reminderTime: '19:00',
      status: 'DUE',
    },
  })

  // Yesterday's doses
  await prisma.doseEvent.create({
    data: {
      prescriptionId: prescription1.id,
      medicationId: med1_1.id,
      patientId: patient1.id,
      scheduledTime: createCambodiaDate(yesterday.toISOString(), 7, 30),
      timePeriod: 'DAYTIME',
      reminderTime: '07:30',
      status: 'TAKEN_LATE',
      takenAt: createCambodiaDate(yesterday.toISOString(), 9, 15),
    },
  })

  await prisma.doseEvent.create({
    data: {
      prescriptionId: prescription1.id,
      medicationId: med1_2.id,
      patientId: patient1.id,
      scheduledTime: createCambodiaDate(yesterday.toISOString(), 7, 30),
      timePeriod: 'DAYTIME',
      reminderTime: '07:30',
      status: 'MISSED',
    },
  })

  await prisma.doseEvent.create({
    data: {
      prescriptionId: prescription1.id,
      medicationId: med1_2.id,
      patientId: patient1.id,
      scheduledTime: createCambodiaDate(yesterday.toISOString(), 19, 0),
      timePeriod: 'NIGHT',
      reminderTime: '19:00',
      status: 'SKIPPED',
      skipReason: 'Felt nauseous after dinner',
    },
  })

  // Dose events for prescription2 (patient2)
  await prisma.doseEvent.create({
    data: {
      prescriptionId: prescription2.id,
      medicationId: med2_1.id,
      patientId: patient2.id,
      scheduledTime: createCambodiaDate(today.toISOString(), 6, 30),
      timePeriod: 'DAYTIME',
      reminderTime: '06:30',
      status: 'TAKEN_ON_TIME',
      takenAt: createCambodiaDate(today.toISOString(), 6, 28),
    },
  })

  await prisma.doseEvent.create({
    data: {
      prescriptionId: prescription2.id,
      medicationId: med2_1.id,
      patientId: patient2.id,
      scheduledTime: createCambodiaDate(today.toISOString(), 19, 30),
      timePeriod: 'NIGHT',
      reminderTime: '19:30',
      status: 'DUE',
    },
  })

  await prisma.doseEvent.create({
    data: {
      prescriptionId: prescription2.id,
      medicationId: med2_2.id,
      patientId: patient2.id,
      scheduledTime: createCambodiaDate(today.toISOString(), 13, 0),
      timePeriod: 'DAYTIME',
      reminderTime: '13:00',
      status: 'TAKEN_ON_TIME',
      takenAt: createCambodiaDate(today.toISOString(), 13, 5),
    },
  })

  await prisma.doseEvent.create({
    data: {
      prescriptionId: prescription2.id,
      medicationId: med2_2.id,
      patientId: patient2.id,
      scheduledTime: createCambodiaDate(today.toISOString(), 20, 0),
      timePeriod: 'NIGHT',
      reminderTime: '20:00',
      status: 'DUE',
    },
  })

  // Dose events for prescription4 (patient4 - urgent)
  await prisma.doseEvent.create({
    data: {
      prescriptionId: prescription4.id,
      medicationId: med4_1.id,
      patientId: patient4.id,
      scheduledTime: createCambodiaDate(today.toISOString(), 7, 0),
      timePeriod: 'DAYTIME',
      reminderTime: '07:00',
      status: 'TAKEN_ON_TIME',
      takenAt: createCambodiaDate(today.toISOString(), 7, 10),
    },
  })

  await prisma.doseEvent.create({
    data: {
      prescriptionId: prescription4.id,
      medicationId: med4_2.id,
      patientId: patient4.id,
      scheduledTime: createCambodiaDate(today.toISOString(), 19, 0),
      timePeriod: 'NIGHT',
      reminderTime: '19:00',
      status: 'DUE',
    },
  })

  // Offline sync dose event
  await prisma.doseEvent.create({
    data: {
      prescriptionId: prescription1.id,
      medicationId: med1_1.id,
      patientId: patient1.id,
      scheduledTime: createCambodiaDate(twoDaysAgo.toISOString(), 7, 30),
      timePeriod: 'DAYTIME',
      reminderTime: '07:30',
      status: 'TAKEN_ON_TIME',
      takenAt: createCambodiaDate(twoDaysAgo.toISOString(), 7, 40),
      wasOffline: true,
    },
  })

  console.log('✅ Created 15 dose events (some taken, some missed, some skipped, some due)')

  // ============================================
  // CREATE NOTIFICATIONS
  // ============================================
  console.log('🔔 Creating notifications...')

  // Connection request notifications
  await prisma.notification.create({
    data: {
      recipientId: patient3.id,
      type: 'CONNECTION_REQUEST',
      title: 'New Connection Request',
      message: 'Dr. Vanna Sok wants to connect with you',
      data: { connectionId: connection5.id, doctorName: 'Dr. Vanna Sok' },
      isRead: false,
      createdAt: new Date('2025-02-08T10:05:00+07:00'),
    },
  })

  // Prescription update notifications
  await prisma.notification.create({
    data: {
      recipientId: patient1.id,
      type: 'PRESCRIPTION_UPDATE',
      title: 'New Prescription',
      message: 'Dr. Vanna Sok has created a new prescription for you',
      data: { prescriptionId: prescription1.id, doctorName: 'Dr. Vanna Sok' },
      isRead: true,
      readAt: new Date('2025-01-16T10:00:00+07:00'),
      createdAt: new Date('2025-01-16T09:05:00+07:00'),
    },
  })

  await prisma.notification.create({
    data: {
      recipientId: patient2.id,
      type: 'PRESCRIPTION_UPDATE',
      title: 'Prescription Updated',
      message: 'Dr. Sophea Meas has updated your prescription',
      data: { prescriptionId: prescription2.id, doctorName: 'Dr. Sophea Meas', versionNumber: 2 },
      isRead: true,
      readAt: new Date('2025-01-28T12:00:00+07:00'),
      createdAt: new Date('2025-01-28T11:05:00+07:00'),
    },
  })

  // Urgent prescription notification
  await prisma.notification.create({
    data: {
      recipientId: patient4.id,
      type: 'URGENT_PRESCRIPTION_CHANGE',
      title: 'Urgent Prescription',
      message: 'Dr. Kosal Rath has created an urgent prescription for you. Please review immediately.',
      data: { 
        prescriptionId: prescription4.id, 
        doctorName: 'Dr. Kosal Rath',
        urgentReason: 'Patient experiencing acute chest pain, immediate medication required'
      },
      isRead: true,
      readAt: new Date('2025-02-08T08:15:00+07:00'),
      createdAt: new Date('2025-02-08T08:05:00+07:00'),
    },
  })

  // Missed dose alerts to family members
  await prisma.notification.create({
    data: {
      recipientId: familyMember1.id,
      type: 'MISSED_DOSE_ALERT',
      title: 'Missed Dose Alert',
      message: 'Sokha Chan missed a dose of Paracetamol scheduled for yesterday morning',
      data: { 
        patientId: patient1.id,
        patientName: 'Sokha Chan',
        medicationName: 'Paracetamol',
        scheduledTime: yesterday.toISOString()
      },
      isRead: false,
      createdAt: new Date(),
    },
  })

  await prisma.notification.create({
    data: {
      recipientId: familyMember2.id,
      type: 'FAMILY_ALERT',
      title: 'Family Member Alert',
      message: 'Sreymom Pich has been taking medications regularly. Great progress!',
      data: { 
        patientId: patient2.id,
        patientName: 'Sreymom Pich',
        adherenceRate: 95
      },
      isRead: false,
      createdAt: new Date(),
    },
  })

  // Connection accepted notifications
  await prisma.notification.create({
    data: {
      recipientId: doctor1.id,
      type: 'CONNECTION_REQUEST',
      title: 'Connection Accepted',
      message: 'Sokha Chan has accepted your connection request',
      data: { connectionId: connection1.id, patientName: 'Sokha Chan' },
      isRead: true,
      readAt: new Date('2025-01-15T12:00:00+07:00'),
      createdAt: new Date('2025-01-15T11:35:00+07:00'),
    },
  })

  await prisma.notification.create({
    data: {
      recipientId: patient1.id,
      type: 'CONNECTION_REQUEST',
      title: 'Connection Request Accepted',
      message: 'You are now connected with Dara Chan',
      data: { connectionId: connection6.id, familyMemberName: 'Dara Chan' },
      isRead: true,
      readAt: new Date('2025-01-10T09:30:00+07:00'),
      createdAt: new Date('2025-01-10T09:05:00+07:00'),
    },
  })

  console.log('✅ Created 8 notifications (connection requests, prescription updates, missed dose alerts)')

  // ============================================
  // CREATE AUDIT LOGS
  // ============================================
  console.log('📋 Creating audit logs...')

  // Connection audit logs
  await prisma.auditLog.create({
    data: {
      actorId: doctor1.id,
      actorRole: 'DOCTOR',
      actionType: 'CONNECTION_REQUEST',
      resourceType: 'Connection',
      resourceId: connection1.id,
      details: { 
        initiatorId: doctor1.id, 
        recipientId: patient1.id,
        initiatorName: 'Dr. Vanna Sok',
        recipientName: 'Sokha Chan'
      },
      ipAddress: '203.144.95.10',
      createdAt: new Date('2025-01-15T10:00:00+07:00'),
    },
  })

  await prisma.auditLog.create({
    data: {
      actorId: patient1.id,
      actorRole: 'PATIENT',
      actionType: 'CONNECTION_ACCEPT',
      resourceType: 'Connection',
      resourceId: connection1.id,
      details: { 
        connectionId: connection1.id,
        doctorId: doctor1.id,
        permissionLevel: 'ALLOWED'
      },
      ipAddress: '203.144.95.15',
      createdAt: new Date('2025-01-15T11:30:00+07:00'),
    },
  })

  await prisma.auditLog.create({
    data: {
      actorId: familyMember1.id,
      actorRole: 'FAMILY_MEMBER',
      actionType: 'CONNECTION_REQUEST',
      resourceType: 'Connection',
      resourceId: connection6.id,
      details: { 
        initiatorId: familyMember1.id, 
        recipientId: patient1.id,
        initiatorName: 'Dara Chan',
        recipientName: 'Sokha Chan'
      },
      ipAddress: '203.144.95.20',
      createdAt: new Date('2025-01-10T08:00:00+07:00'),
    },
  })

  // Prescription audit logs
  await prisma.auditLog.create({
    data: {
      actorId: doctor1.id,
      actorRole: 'DOCTOR',
      actionType: 'PRESCRIPTION_CREATE',
      resourceType: 'Prescription',
      resourceId: prescription1.id,
      details: { 
        patientId: patient1.id,
        patientName: 'Sokha Chan',
        medicationCount: 2,
        symptoms: 'ឈឺក្បាល និង សម្ពាធឈាមខ្ពស់'
      },
      ipAddress: '203.144.95.10',
      createdAt: new Date('2025-01-16T09:00:00+07:00'),
    },
  })

  await prisma.auditLog.create({
    data: {
      actorId: doctor2.id,
      actorRole: 'DOCTOR',
      actionType: 'PRESCRIPTION_UPDATE',
      resourceType: 'Prescription',
      resourceId: prescription2.id,
      details: { 
        patientId: patient2.id,
        patientName: 'Sreymom Pich',
        versionNumber: 2,
        changeReason: 'Added pain medication and vitamin supplement based on patient feedback',
        medicationCount: 3
      },
      ipAddress: '203.144.95.25',
      createdAt: new Date('2025-01-28T11:00:00+07:00'),
    },
  })

  await prisma.auditLog.create({
    data: {
      actorId: patient1.id,
      actorRole: 'PATIENT',
      actionType: 'PRESCRIPTION_CONFIRM',
      resourceType: 'Prescription',
      resourceId: prescription1.id,
      details: { 
        prescriptionId: prescription1.id,
        doctorId: doctor1.id,
        confirmedAt: new Date('2025-01-16T10:00:00+07:00')
      },
      ipAddress: '203.144.95.15',
      createdAt: new Date('2025-01-16T10:00:00+07:00'),
    },
  })

  // Dose event audit logs
  await prisma.auditLog.create({
    data: {
      actorId: patient1.id,
      actorRole: 'PATIENT',
      actionType: 'DOSE_TAKEN',
      resourceType: 'DoseEvent',
      details: { 
        medicationName: 'Amlodipine',
        medicationNameKhmer: 'អាមឡូឌីពីន',
        scheduledTime: createCambodiaDate(today.toISOString(), 7, 30),
        takenAt: createCambodiaDate(today.toISOString(), 7, 35),
        onTime: true
      },
      ipAddress: '203.144.95.15',
      createdAt: new Date(),
    },
  })

  await prisma.auditLog.create({
    data: {
      actorId: patient1.id,
      actorRole: 'PATIENT',
      actionType: 'DOSE_SKIPPED',
      resourceType: 'DoseEvent',
      details: { 
        medicationName: 'Paracetamol',
        medicationNameKhmer: 'ប៉ារ៉ាសេតាម៉ុល',
        scheduledTime: createCambodiaDate(yesterday.toISOString(), 19, 0),
        skipReason: 'Felt nauseous after dinner'
      },
      ipAddress: '203.144.95.15',
      createdAt: yesterday,
    },
  })

  await prisma.auditLog.create({
    data: {
      actorId: null,
      actorRole: null,
      actionType: 'DOSE_MISSED',
      resourceType: 'DoseEvent',
      details: { 
        patientId: patient1.id,
        patientName: 'Sokha Chan',
        medicationName: 'Paracetamol',
        medicationNameKhmer: 'ប៉ារ៉ាសេតាម៉ុល',
        scheduledTime: createCambodiaDate(yesterday.toISOString(), 7, 30),
        detectedAt: new Date()
      },
      ipAddress: 'system',
      createdAt: yesterday,
    },
  })

  // Permission change audit log
  await prisma.auditLog.create({
    data: {
      actorId: patient2.id,
      actorRole: 'PATIENT',
      actionType: 'PERMISSION_CHANGE',
      resourceType: 'Connection',
      resourceId: connection2.id,
      details: { 
        connectionId: connection2.id,
        doctorId: doctor2.id,
        oldPermissionLevel: 'ALLOWED',
        newPermissionLevel: 'SELECTED'
      },
      ipAddress: '203.144.95.30',
      createdAt: new Date('2025-01-22T14:00:00+07:00'),
    },
  })

  // Data access audit log
  await prisma.auditLog.create({
    data: {
      actorId: doctor1.id,
      actorRole: 'DOCTOR',
      actionType: 'DATA_ACCESS',
      resourceType: 'Prescription',
      resourceId: prescription1.id,
      details: { 
        patientId: patient1.id,
        patientName: 'Sokha Chan',
        accessType: 'VIEW_PRESCRIPTION',
        permissionLevel: 'ALLOWED'
      },
      ipAddress: '203.144.95.10',
      createdAt: new Date('2025-02-07T15:00:00+07:00'),
    },
  })

  // Notification sent audit logs
  await prisma.auditLog.create({
    data: {
      actorId: null,
      actorRole: null,
      actionType: 'NOTIFICATION_SENT',
      resourceType: 'Notification',
      details: { 
        recipientId: familyMember1.id,
        recipientName: 'Dara Chan',
        notificationType: 'MISSED_DOSE_ALERT',
        patientId: patient1.id,
        patientName: 'Sokha Chan'
      },
      ipAddress: 'system',
      createdAt: new Date(),
    },
  })

  // Subscription change audit log
  await prisma.auditLog.create({
    data: {
      actorId: patient2.id,
      actorRole: 'PATIENT',
      actionType: 'SUBSCRIPTION_CHANGE',
      resourceType: 'Subscription',
      details: { 
        userId: patient2.id,
        oldTier: 'FREEMIUM',
        newTier: 'PREMIUM',
        storageQuotaIncrease: '15GB'
      },
      ipAddress: '203.144.95.30',
      createdAt: new Date('2025-01-25T16:00:00+07:00'),
    },
  })

  console.log('✅ Created 13 audit logs (connections, prescriptions, doses, permissions, data access, notifications)')

  // ============================================
  // SUMMARY
  // ============================================
  console.log('\n🎉 Database seeding completed successfully!')
  console.log('\n📊 Summary:')
  console.log('  - Users: 11 (4 patients, 4 doctors, 3 family members)')
  console.log('  - Subscriptions: 4 (2 FREEMIUM, 1 PREMIUM, 1 FAMILY_PREMIUM)')
  console.log('  - Meal Time Preferences: 4')
  console.log('  - Connections: 8 (4 doctor-patient, 3 family-patient, 1 pending)')
  console.log('  - Prescriptions: 5 (3 active, 1 draft, 1 paused, 1 urgent)')
  console.log('  - Medications: 11 (with Khmer names and various dosage schedules)')
  console.log('  - Prescription Versions: 4 (including version history)')
  console.log('  - Dose Events: 15 (taken, missed, skipped, due, offline sync)')
  console.log('  - Notifications: 8 (various types)')
  console.log('  - Audit Logs: 13 (comprehensive action tracking)')
  console.log('\n✅ Test data is ready for development and testing!')
  console.log('\n🔑 Login credentials:')
  console.log('  - All users: password = "password123", PIN = "1234"')
  console.log('  - Patient 1: +85512345678 (sokha.chan@example.com)')
  console.log('  - Patient 2: +85512345679 (sreymom.pich@example.com)')
  console.log('  - Doctor 1: +85512345680 (vanna.sok@hospital.com)')
  console.log('  - Family 1: +85512345681 (dara.chan@example.com)')
}

main()
  .catch((e) => {
    console.error('❌ Error seeding database:', e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
