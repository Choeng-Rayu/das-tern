# Requirements Document: Manual Prescription and Medication Creation

## Introduction

The Manual Prescription and Medication Creation feature enables patients using the Das Tern medication management platform to create prescription and medication records through a simple form-based interface. The system provides a streamlined manual entry experience with bilingual support (Khmer and English) and theme customization (light and dark mode). This foundational implementation establishes the core data models and user workflows that can be enhanced with image capture and OCR capabilities in future releases.

## Glossary

- **Prescription**: A medical document record containing information about prescribed medications, including prescriber details and prescription date
- **Medication**: A specific medicine entry within a prescription, including name, dosage, frequency, timing, and duration
- **Mobile_App**: The Flutter-based Das Tern mobile application (das_tern_mcp)
- **Backend_API**: The NestJS TypeScript backend service that processes and stores prescription and medication data
- **Local_Cache**: The offline storage mechanism in the mobile app for prescription and medication data when network is unavailable
- **Medication_Form**: The user interface for creating or editing medication entries in the system
- **Prescription_Form**: The user interface for creating or editing prescription records in the system
- **Dosage**: The amount of medication to be taken (e.g., "500mg", "2 tablets")
- **Frequency**: How often the medication should be taken (e.g., "3 times daily", "twice a day")
- **Timing**: When the medication should be taken (e.g., "after meals", "before bed")

## Requirements

### Requirement 1: Prescription Creation

**User Story:** As a patient, I want to create a prescription record, so that I can organize my medications under their respective prescriptions.

#### Acceptance Criteria

1. WHEN a patient initiates prescription creation, THE Mobile_App SHALL display the Prescription_Form with fields for prescriber name, prescription date, and notes
2. WHEN entering prescriber information, THE Mobile_App SHALL provide auto-complete suggestions based on previously entered prescribers
3. WHEN selecting a prescription date, THE Mobile_App SHALL provide a date picker with the current date as default
4. THE Mobile_App SHALL validate that the prescription date is not in the future
5. WHEN the patient submits the Prescription_Form, THE Mobile_App SHALL create a prescription record and proceed to medication entry

### Requirement 2: Medication Entry

**User Story:** As a patient, I want to add medication details to my prescription, so that I can track what medicines I need to take.

#### Acceptance Criteria

1. WHEN a prescription is created, THE Mobile_App SHALL display the Medication_Form with fields for medication name, dosage, frequency, timing, duration, and notes
2. THE Mobile_App SHALL provide input fields that accept text in both Khmer and English
3. WHEN entering medication name, THE Mobile_App SHALL provide auto-complete suggestions from a local medication database
4. WHEN entering dosage, THE Mobile_App SHALL accept free-form text (e.g., "500mg", "2 tablets", "1 teaspoon")
5. WHEN entering frequency, THE Mobile_App SHALL provide common options (once daily, twice daily, three times daily, as needed) and allow custom input

### Requirement 3: Bilingual Input Support

**User Story:** As a patient, I want to enter medication information in either Khmer or English, so that I can use the language that matches my prescription.

#### Acceptance Criteria

1. WHEN the Medication_Form is displayed, THE Mobile_App SHALL show field labels in the user's selected interface language
2. THE Mobile_App SHALL accept input in both Khmer and English scripts for all text fields
3. WHEN entering medication names, THE Mobile_App SHALL provide auto-complete suggestions in both Khmer and English
4. THE Mobile_App SHALL store medication data in the entered language without translation
5. WHEN displaying medication lists, THE Mobile_App SHALL show medication names in the language they were entered

### Requirement 4: Form Validation and Submission

**User Story:** As a patient, I want the app to validate my medication entries, so that I can ensure all required information is complete before saving.

#### Acceptance Criteria

1. WHEN the patient fills the Medication_Form, THE Mobile_App SHALL validate required fields (medication name, dosage, frequency) in real-time
2. WHEN a required field is empty, THE Mobile_App SHALL display an error message in the selected language
3. WHEN the patient submits the form, THE Mobile_App SHALL perform final validation of all required fields
4. IF validation fails, THEN THE Mobile_App SHALL highlight invalid fields and prevent submission
5. WHEN all required fields are valid and the patient confirms, THE Mobile_App SHALL create a medication record linked to the prescription

### Requirement 5: Multiple Medication Entry

**User Story:** As a patient, I want to add multiple medications to a single prescription, so that I can efficiently manage prescriptions with several medications.

#### Acceptance Criteria

1. WHEN a medication is successfully saved, THE Mobile_App SHALL offer an option to add another medication to the same prescription
2. WHEN adding another medication, THE Mobile_App SHALL display a new empty Medication_Form
3. THE Mobile_App SHALL associate all medications with the same prescription record
4. WHEN the patient finishes adding medications, THE Mobile_App SHALL display a summary view of all medications in that prescription
5. THE Mobile_App SHALL allow the patient to edit or delete any medication from the summary view

### Requirement 6: Offline Support

**User Story:** As a patient, I want to create prescriptions and medications even when I don't have internet connection, so that I can add medications anytime and sync later.

#### Acceptance Criteria

1. WHEN the Mobile_App is offline, THE Mobile_App SHALL allow full prescription and medication creation functionality
2. WHEN a prescription or medication is created offline, THE Mobile_App SHALL store the data in Local_Cache
3. WHEN the device regains network connectivity, THE Mobile_App SHALL automatically sync cached prescription and medication data to the Backend_API
4. WHEN syncing, THE Mobile_App SHALL handle conflicts by preferring local changes over server data
5. IF sync fails for any cached item, THEN THE Mobile_App SHALL retry with exponential backoff and notify the patient of pending syncs

### Requirement 7: Data Persistence

**User Story:** As a patient, I want my prescription and medication data stored securely, so that I can access them from any device and they are backed up safely.

#### Acceptance Criteria

1. WHEN a prescription is created, THE Backend_API SHALL store the prescription record in the PostgreSQL database with a unique identifier
2. WHEN a medication is created, THE Backend_API SHALL store the medication record linked to its prescription via foreign key
3. THE Backend_API SHALL enforce referential integrity between prescriptions and medications
4. WHEN a patient views their prescriptions, THE Backend_API SHALL return all prescriptions with their associated medications
5. THE Backend_API SHALL support pagination for prescription lists to handle large datasets efficiently

### Requirement 8: Data Privacy and Security

**User Story:** As a patient, I want my prescription and medication data handled securely, so that my sensitive medical information remains private.

#### Acceptance Criteria

1. WHEN storing prescription and medication data locally, THE Mobile_App SHALL encrypt the data using device-level encryption
2. WHEN transmitting prescription and medication data to the Backend_API, THE Mobile_App SHALL use HTTPS with TLS 1.3 or higher
3. THE Backend_API SHALL enforce authentication and authorization before allowing prescription and medication creation or access
4. THE Backend_API SHALL ensure patients can only access their own prescription and medication records
5. THE Backend_API SHALL log all access to prescription and medication data for audit purposes

### Requirement 9: Language Switching

**User Story:** As a patient, I want to switch between Khmer and English interface languages, so that I can use the app in my preferred language.

#### Acceptance Criteria

1. WHEN a patient opens the app, THE Mobile_App SHALL display the interface in the previously selected language or system default
2. THE Mobile_App SHALL provide a language selector accessible from the settings or main menu
3. WHEN a patient selects a language (Khmer or English), THE Mobile_App SHALL immediately update all UI text, labels, and messages
4. WHEN the language is changed, THE Mobile_App SHALL persist the language preference locally
5. THE Mobile_App SHALL apply the selected language to all prescription and medication forms, lists, and error messages

### Requirement 10: Theme Support (Light and Dark Mode)

**User Story:** As a patient, I want to switch between light and dark themes, so that I can use the app comfortably in different lighting conditions.

#### Acceptance Criteria

1. WHEN a patient opens the app, THE Mobile_App SHALL display the interface in the previously selected theme or system default
2. THE Mobile_App SHALL provide a theme selector with options for Light Mode, Dark Mode, and System Default
3. WHEN a patient selects a theme, THE Mobile_App SHALL immediately update all UI components, colors, and contrast ratios
4. WHEN the theme is changed, THE Mobile_App SHALL persist the theme preference locally
5. WHEN System Default is selected, THE Mobile_App SHALL automatically switch between light and dark themes based on device settings

### Requirement 11: Prescription and Medication Listing

**User Story:** As a patient, I want to view all my prescriptions and medications, so that I can review my medication history.

#### Acceptance Criteria

1. WHEN a patient navigates to the prescriptions list, THE Mobile_App SHALL display all prescriptions ordered by date (most recent first)
2. WHEN displaying a prescription in the list, THE Mobile_App SHALL show the prescriber name, prescription date, and medication count
3. WHEN a patient taps on a prescription, THE Mobile_App SHALL display the prescription details with all associated medications
4. WHEN displaying medications, THE Mobile_App SHALL show medication name, dosage, frequency, and timing
5. THE Mobile_App SHALL provide search and filter capabilities for prescriptions and medications


### Requirement 12: Prescription and Medication Editing

**User Story:** As a patient, I want to edit my prescriptions and medications, so that I can correct mistakes or update information.

#### Acceptance Criteria

1. WHEN viewing a prescription, THE Mobile_App SHALL provide an edit option that opens the Prescription_Form with existing data
2. WHEN viewing a medication, THE Mobile_App SHALL provide an edit option that opens the Medication_Form with existing data
3. WHEN editing a prescription or medication, THE Mobile_App SHALL validate all fields using the same rules as creation
4. WHEN the patient saves changes, THE Mobile_App SHALL update the record in the database
5. THE Mobile_App SHALL sync edited records to the Backend_API when online

### Requirement 13: Prescription and Medication Deletion

**User Story:** As a patient, I want to delete prescriptions and medications, so that I can remove incorrect or outdated entries.

#### Acceptance Criteria

1. WHEN viewing a prescription, THE Mobile_App SHALL provide a delete option with confirmation dialog
2. WHEN a prescription is deleted, THE Mobile_App SHALL also delete all associated medications
3. WHEN viewing a medication, THE Mobile_App SHALL provide a delete option with confirmation dialog
4. WHEN a medication is deleted, THE Mobile_App SHALL remove only that medication while keeping the prescription
5. THE Mobile_App SHALL sync deletions to the Backend_API when online
