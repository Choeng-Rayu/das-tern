// Internationalization (i18n) utilities for Khmer and English

export type Language = 'khmer' | 'english'

export const translations = {
  // Authentication messages
  auth: {
    invalidCredentials: {
      khmer: 'ឈ្មោះ​អ្នក​ប្រើ ឬ​ពាក្យ​សម្ងាត់​មិន​ត្រឹមត្រូវ',
      english: 'Invalid username or password',
    },
    accountLocked: {
      khmer: 'គណនី​របស់​អ្នក​ត្រូវ​បាន​ចាក់​សោ។ សូម​ព្យាយាម​ម្តង​ទៀត​នៅ​ពេល​ក្រោយ',
      english: 'Your account is locked. Please try again later.',
    },
    accountPendingVerification: {
      khmer: 'គណនី​របស់​អ្នក​កំពុង​រង់ចាំ​ការ​ផ្ទៀងផ្ទាត់',
      english: 'Your account is pending verification.',
    },
    accountRejected: {
      khmer: 'គណនី​របស់​អ្នក​ត្រូវ​បាន​បដិសេធ',
      english: 'Your account has been rejected.',
    },
    loginSuccess: {
      khmer: 'ចូល​ប្រើ​ប្រាស់​ដោយ​ជោគជ័យ',
      english: 'Login successful',
    },
    logoutSuccess: {
      khmer: 'ចាកចេញ​ដោយ​ជោគជ័យ',
      english: 'Logout successful',
    },
  },

  // Validation messages
  validation: {
    required: {
      khmer: 'វាល​នេះ​ត្រូវ​បាន​ទាមទារ',
      english: 'This field is required',
    },
    invalidEmail: {
      khmer: 'អ៊ីមែល​មិន​ត្រឹមត្រូវ',
      english: 'Invalid email address',
    },
    invalidPhone: {
      khmer: 'លេខ​ទូរស័ព្ទ​មិន​ត្រឹមត្រូវ',
      english: 'Invalid phone number',
    },
    passwordTooShort: {
      khmer: 'ពាក្យ​សម្ងាត់​ត្រូវ​តែ​មាន​យ៉ាង​ហោច​ណាស់ ៦ តួអក្សរ',
      english: 'Password must be at least 6 characters',
    },
    pinCodeInvalid: {
      khmer: 'លេខ​កូដ PIN ត្រូវ​តែ​មាន ៤ ខ្ទង់',
      english: 'PIN code must be 4 digits',
    },
    ageTooYoung: {
      khmer: 'អ្នក​ត្រូវ​តែ​មាន​អាយុ​យ៉ាង​ហោច​ណាស់ ១៣ ឆ្នាំ',
      english: 'You must be at least 13 years old',
    },
  },

  // Error messages
  errors: {
    serverError: {
      khmer: 'មាន​បញ្ហា​ក្នុង​ម៉ាស៊ីន​មេ។ សូម​ព្យាយាម​ម្តង​ទៀត',
      english: 'Server error. Please try again.',
    },
    notFound: {
      khmer: 'រក​មិន​ឃើញ',
      english: 'Not found',
    },
    unauthorized: {
      khmer: 'អ្នក​មិន​មាន​សិទ្ធិ​ចូល​ប្រើ',
      english: 'Unauthorized access',
    },
    forbidden: {
      khmer: 'ហាម​ឃាត់',
      english: 'Forbidden',
    },
    rateLimitExceeded: {
      khmer: 'អ្នក​បាន​ធ្វើ​សំណើ​ច្រើន​ពេក។ សូម​ព្យាយាម​ម្តង​ទៀត​នៅ​ពេល​ក្រោយ',
      english: 'Too many requests. Please try again later.',
    },
    quotaExceeded: {
      khmer: 'អ្នក​បាន​លើស​កម្រិត​ផ្ទុក​របស់​អ្នក',
      english: 'You have exceeded your storage quota',
    },
  },

  // Success messages
  success: {
    created: {
      khmer: 'បាន​បង្កើត​ដោយ​ជោគជ័យ',
      english: 'Created successfully',
    },
    updated: {
      khmer: 'បាន​ធ្វើ​បច្ចុប្បន្នភាព​ដោយ​ជោគជ័យ',
      english: 'Updated successfully',
    },
    deleted: {
      khmer: 'បាន​លុប​ដោយ​ជោគជ័យ',
      english: 'Deleted successfully',
    },
  },

  // Prescription messages
  prescription: {
    created: {
      khmer: 'បាន​បង្កើត​វេជ្ជបញ្ជា​ដោយ​ជោគជ័យ',
      english: 'Prescription created successfully',
    },
    updated: {
      khmer: 'បាន​ធ្វើ​បច្ចុប្បន្នភាព​វេជ្ជបញ្ជា​ដោយ​ជោគជ័យ',
      english: 'Prescription updated successfully',
    },
    urgentUpdate: {
      khmer: 'វេជ្ជបញ្ជា​បាន​ធ្វើ​បច្ចុប្បន្នភាព​ជា​បន្ទាន់',
      english: 'Prescription updated urgently',
    },
  },

  // Connection messages
  connection: {
    requestSent: {
      khmer: 'បាន​ផ្ញើ​សំណើ​តភ្ជាប់​ដោយ​ជោគជ័យ',
      english: 'Connection request sent successfully',
    },
    accepted: {
      khmer: 'បាន​ទទួល​យក​ការ​តភ្ជាប់',
      english: 'Connection accepted',
    },
    revoked: {
      khmer: 'បាន​លុប​ចោល​ការ​តភ្ជាប់',
      english: 'Connection revoked',
    },
  },

  // Dose messages
  dose: {
    taken: {
      khmer: 'បាន​កត់​ត្រា​ថា​បាន​ញ៉ាំ​ថ្នាំ',
      english: 'Dose marked as taken',
    },
    skipped: {
      khmer: 'បាន​រំលង​ថ្នាំ',
      english: 'Dose skipped',
    },
    missed: {
      khmer: 'បាន​ខកខាន​ថ្នាំ',
      english: 'Dose missed',
    },
  },

  // Notification messages
  notification: {
    missedDose: {
      khmer: 'អ្នក​បាន​ខកខាន​ថ្នាំ',
      english: 'You missed a dose',
    },
    prescriptionUpdate: {
      khmer: 'វេជ្ជបញ្ជា​របស់​អ្នក​ត្រូវ​បាន​ធ្វើ​បច្ចុប្បន្នភាព',
      english: 'Your prescription has been updated',
    },
    connectionRequest: {
      khmer: 'អ្នក​មាន​សំណើ​តភ្ជាប់​ថ្មី',
      english: 'You have a new connection request',
    },
  },
}

export function translate(
  key: string,
  language: Language = 'english'
): string {
  const keys = key.split('.')
  let value: any = translations

  for (const k of keys) {
    value = value?.[k]
  }

  if (typeof value === 'object' && value !== null) {
    return value[language] || value.english || key
  }

  return key
}

export function getLanguageFromHeader(acceptLanguage?: string): Language {
  if (!acceptLanguage) return 'english'
  
  const lang = acceptLanguage.toLowerCase()
  if (lang.includes('km') || lang.includes('khmer')) {
    return 'khmer'
  }
  
  return 'english'
}
