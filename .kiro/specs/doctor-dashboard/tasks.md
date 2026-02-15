# Implementation Plan: Doctor Dashboard

## Overview

This implementation plan breaks down the Doctor Dashboard feature into discrete, incremental coding tasks. The dashboard enables doctors to monitor patient medication adherence, create and send prescriptions, manage secure doctor-patient connections, and intervene early when adherence drops. The implementation builds on the existing DasTern backend infrastructure (Next.js, PostgreSQL, Prisma, Redis) and follows a test-driven approach with both unit tests and property-based tests.

## Tasks

- [ ] 1. Set up database schema and migrations for Doctor Dashboard
  - Add DoctorNote model to Prisma schema
  - Create migration for doctor_notes table with indexes
  - Update User model relations to include doctor notes
  - Run migration and verify schema changes
  - _Requirements: 8.1, 8.2, 8.3_

- [ ] 2. Implement Connection Service enhancements
  - [ ] 2.1 Add getAcceptedConnections method to ConnectionService
    - Query connections where recipientId is doctorId and status is ACCEPTED
    - Return array of Connection objects
    - _Requirements: 1.2, 2.1_
  
  - [ ] 2.2 Add getPendingConnectionRequests method
    - Query connections where recipientId is doctorId and status is PENDING
    - Include patient details in response
    - _Requirements: 1.2_
  
  - [ ] 2.3 Add acceptConnection method with audit logging
    - Update connection status to ACCEPTED
    - Set acceptedAt timestamp
    - Create audit log entry
    - _Requirements: 1.3, 1.6_
  
  - [ ] 2.4 Add rejectConnection method with notification
    - Update connection status to REVOKED
    - Send notification to patient
    - Create audit log entry
    - _Requirements: 1.4, 1.6_
  
  - [ ] 2.5 Add disconnectFromPatient method
    - Update connection status to REVOKED
    - Set revokedAt timestamp
    - Send notification to patient
    - Create audit log entry
    - _Requirements: 1.5, 1.6, 9.3_
  
  - [ ]* 2.6 Write property test for connection state transitions
    - **Property 1: Connection State Transitions**
    - **Validates: Requirements 1.1, 1.3, 1.4, 1.5, 1.6**
  
  - [ ]* 2.7 Write property test for pending connection filtering
    - **Property 3: Pending Connection Filtering**
    - **Validates: Requirements 1.2**

- [ ] 3. Implement AdherenceService
  - [ ] 3.1 Create AdherenceService class with calculateAdherence method
    - Query DoseEvent table for date range
    - Count doses by status (TAKEN_ON_TIME, TAKEN_LATE, MISSED)
    - Calculate percentage: (takenOnTime + takenLate) / total * 100
    - Cache result in Redis with 5-minute TTL
    - _Requirements: 7.1, 7.2, 7.3_
  
  - [ ] 3.2 Add getAdherenceTimeline method
    - Generate N daily data points
    - Call calculateAdherence for each day
    - Return array of AdherenceDataPoint objects
    - _Requirements: 4.4_
  
  - [ ] 3.3 Add detectMissedDoses method
    - Query missed doses in last 3 days
    - Detect consecutive missed doses
    - Generate WARNING alert for 2 consecutive misses
    - Generate CRITICAL alert for 3+ consecutive misses
    - _Requirements: 7.5, 7.6_
  
  - [ ] 3.4 Add getBatchAdherence method
    - Calculate adherence for multiple patients in parallel
    - Use Promise.all for concurrent execution
    - _Requirements: 2.2_
  
  - [ ] 3.5 Add getAdherenceLevel helper function
    - Return GREEN for adherence >= 90%
    - Return YELLOW for adherence 70-89%
    - Return RED for adherence < 70%
    - _Requirements: 7.7, 7.8, 7.9_
  
  - [ ]* 3.6 Write property test for adherence calculation correctness
    - **Property 8: Adherence Calculation Correctness**
    - **Validates: Requirements 7.1**
  
  - [ ]* 3.7 Write property test for adherence indicator mapping
    - **Property 9: Adherence Indicator Mapping**
    - **Validates: Requirements 7.7, 7.8, 7.9**
  
  - [ ]* 3.8 Write property test for missed dose alert generation
    - **Property 10: Missed Dose Alert Generation**
    - **Validates: Requirements 7.5, 7.6**
  
  - [ ]* 3.9 Write property test for adherence timeline completeness
    - **Property 11: Adherence Timeline Completeness**
    - **Validates: Requirements 4.4**

- [ ] 4. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 5. Implement DoctorService
  - [ ] 5.1 Create DoctorService class with getDashboardOverview method
    - Get all accepted connections for doctor
    - Calculate total patients count
    - Get batch adherence data
    - Count patients with adherence < 70%
    - Get today's alerts
    - Get recent activity (last 10 events)
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  
  - [ ] 5.2 Add getPatientList method with filtering and sorting
    - Get accepted connections
    - Fetch patient data with active prescriptions
    - Calculate adherence for each patient
    - Apply adherence filter (GREEN/YELLOW/RED)
    - Apply active prescription filter
    - Apply last active filter
    - Sort by specified column
    - Implement pagination (20 per page)
    - Cache result in Redis with 5-minute TTL
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 12.4_
  
  - [ ] 5.3 Add getPatientDetails method
    - Verify connection and permission using ConnectionService
    - Fetch patient data with active prescriptions
    - Get adherence timeline (30 days)
    - Get doctor notes for patient
    - Extract medicines from prescriptions
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_
  
  - [ ] 5.4 Add calculateAge helper function
    - Calculate age from date of birth
    - Handle month and day differences correctly
    - _Requirements: 3.1, 4.1_
  
  - [ ]* 5.5 Write property test for dashboard metrics accuracy
    - **Property 4: Dashboard Metrics Accuracy**
    - **Validates: Requirements 2.1, 2.2**
  
  - [ ]* 5.6 Write property test for patient list filtering
    - **Property 5: Patient List Filtering**
    - **Validates: Requirements 3.2**
  
  - [ ]* 5.7 Write property test for patient list data completeness
    - **Property 6: Patient List Data Completeness**
    - **Validates: Requirements 3.1**
  
  - [ ]* 5.8 Write property test for patient list sorting
    - **Property 7: Patient List Sorting**
    - **Validates: Requirements 3.5**
  
  - [ ]* 5.9 Write property test for pagination correctness
    - **Property 24: Pagination Correctness**
    - **Validates: Requirements 12.4**

- [ ] 6. Implement DoctorNotesService
  - [ ] 6.1 Create DoctorNotesService class with createNote method
    - Verify active connection exists
    - Create doctor note with doctorId, patientId, content
    - Auto-generate createdAt timestamp
    - Create audit log entry
    - _Requirements: 8.1, 8.2_
  
  - [ ] 6.2 Add getNotes method
    - Query notes where doctorId and patientId match
    - Order by createdAt descending
    - _Requirements: 8.4, 4.5_
  
  - [ ] 6.3 Add updateNote method
    - Verify note ownership (doctorId matches)
    - Update note content
    - Update updatedAt timestamp
    - Create audit log entry
    - _Requirements: 8.3_
  
  - [ ]* 6.4 Write property test for doctor notes access control
    - **Property 16: Doctor Notes Access Control**
    - **Validates: Requirements 8.4**
  
  - [ ]* 6.5 Write property test for doctor notes timestamping
    - **Property 17: Doctor Notes Timestamping**
    - **Validates: Requirements 8.2, 8.3**
  
  - [ ]* 6.6 Write unit tests for note validation
    - Test empty content rejection
    - Test missing patientId rejection
    - Test unauthorized access
    - _Requirements: 8.1, 8.4, 8.5_

- [ ] 7. Enhance PrescriptionService for doctor dashboard
  - [ ] 7.1 Add createPrescriptionForPatient method
    - Validate connection and permission
    - Validate required fields (title, diagnosis, startDate, medications)
    - Create prescription with status PENDING
    - Create medications
    - Create initial version
    - Send notification to patient
    - Create audit log entry
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 9.1_
  
  - [ ] 7.2 Add getPrescriptionsForDoctor method
    - Query prescriptions where doctorId matches
    - Filter by patientId if provided
    - Filter by status if provided
    - Implement pagination
    - _Requirements: 5.5_
  
  - [ ] 7.3 Add updatePrescription method with urgent reason validation
    - Check if prescription status is ACTIVE
    - If ACTIVE, require urgentReason field
    - If not ACTIVE, allow edit without urgentReason
    - Create new version
    - Create audit log entry
    - _Requirements: 6.3, 10.2_
  
  - [ ]* 7.4 Write property test for prescription creation validation
    - **Property 12: Prescription Creation Validation**
    - **Validates: Requirements 5.1, 5.2**
  
  - [ ]* 7.5 Write property test for prescription initial state
    - **Property 13: Prescription Initial State**
    - **Validates: Requirements 5.3, 5.4, 6.1**
  
  - [ ]* 7.6 Write property test for active prescription immutability
    - **Property 15: Active Prescription Immutability**
    - **Validates: Requirements 6.3, 10.2**

- [ ] 8. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Implement Doctor Dashboard API endpoints
  - [ ] 9.1 Create GET /api/doctor/dashboard endpoint
    - Verify JWT token and doctor role
    - Call DoctorService.getDashboardOverview
    - Return dashboard metrics
    - Handle errors with proper status codes
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  
  - [ ] 9.2 Create GET /api/doctor/patients endpoint
    - Verify JWT token and doctor role
    - Parse query parameters (filters, sorting, pagination)
    - Call DoctorService.getPatientList
    - Return patient list with pagination metadata
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_
  
  - [ ] 9.3 Create GET /api/doctor/patients/:patientId/details endpoint
    - Verify JWT token and doctor role
    - Call DoctorService.getPatientDetails
    - Return patient details with adherence timeline
    - Handle connection validation errors
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_
  
  - [ ] 9.4 Create GET /api/doctor/patients/:patientId/adherence endpoint
    - Verify JWT token and doctor role
    - Parse date range from query parameters
    - Call AdherenceService methods
    - Return adherence data with alerts
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

- [ ] 10. Implement Connection Management API endpoints
  - [ ] 10.1 Create GET /api/doctor/connections/pending endpoint
    - Verify JWT token and doctor role
    - Call ConnectionService.getPendingConnectionRequests
    - Return pending requests with patient details
    - _Requirements: 1.2_
  
  - [ ] 10.2 Create POST /api/doctor/connections/:connectionId/accept endpoint
    - Verify JWT token and doctor role
    - Parse permissionLevel from body
    - Call ConnectionService.acceptConnection
    - Return updated connection
    - _Requirements: 1.3, 1.6_
  
  - [ ] 10.3 Create POST /api/doctor/connections/:connectionId/reject endpoint
    - Verify JWT token and doctor role
    - Parse reason from body
    - Call ConnectionService.rejectConnection
    - Return success message
    - _Requirements: 1.4, 1.6_
  
  - [ ] 10.4 Create POST /api/doctor/connections/:connectionId/disconnect endpoint
    - Verify JWT token and doctor role
    - Require reason in body
    - Call ConnectionService.disconnectFromPatient
    - Return success message
    - _Requirements: 1.5, 1.6, 9.3_
  
  - [ ]* 10.5 Write property test for connection-based access control
    - **Property 2: Connection-Based Access Control**
    - **Validates: Requirements 10.1**

- [ ] 11. Implement Prescription Management API endpoints
  - [ ] 11.1 Create POST /api/doctor/prescriptions endpoint
    - Verify JWT token and doctor role
    - Validate request body with Zod schema
    - Call PrescriptionService.createPrescriptionForPatient
    - Return created prescription
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_
  
  - [ ] 11.2 Create GET /api/doctor/prescriptions endpoint
    - Verify JWT token and doctor role
    - Parse query parameters
    - Call PrescriptionService.getPrescriptionsForDoctor
    - Return prescriptions with pagination
    - _Requirements: 5.5_
  
  - [ ] 11.3 Create GET /api/doctor/prescriptions/:prescriptionId endpoint
    - Verify JWT token and doctor role
    - Call PrescriptionService.getPrescriptionById
    - Verify doctor has access to patient
    - Return prescription details
    - _Requirements: 5.5_
  
  - [ ] 11.4 Create PATCH /api/doctor/prescriptions/:prescriptionId endpoint
    - Verify JWT token and doctor role
    - Validate urgentReason if prescription is ACTIVE
    - Call PrescriptionService.updatePrescription
    - Return updated prescription
    - _Requirements: 6.3, 10.2_
  
  - [ ]* 11.5 Write property test for notification generation on prescription send
    - **Property 19: Notification Generation on Prescription Send**
    - **Validates: Requirements 9.1**

- [ ] 12. Implement Doctor Notes API endpoints
  - [ ] 12.1 Create POST /api/doctor/notes endpoint
    - Verify JWT token and doctor role
    - Validate request body (patientId, content required)
    - Call DoctorNotesService.createNote
    - Return created note
    - _Requirements: 8.1, 8.2_
  
  - [ ] 12.2 Create GET /api/doctor/notes endpoint
    - Verify JWT token and doctor role
    - Require patientId query parameter
    - Call DoctorNotesService.getNotes
    - Return notes array
    - _Requirements: 8.4, 4.5_
  
  - [ ] 12.3 Create PATCH /api/doctor/notes/:noteId endpoint
    - Verify JWT token and doctor role
    - Validate note ownership
    - Call DoctorNotesService.updateNote
    - Return updated note
    - _Requirements: 8.3_
  
  - [ ]* 12.4 Write property test for patient note access restriction
    - **Property 18: Patient Note Access Restriction**
    - **Validates: Requirements 8.5**

- [ ] 13. Implement access control and authorization middleware
  - [ ] 13.1 Create requireDoctorRole middleware
    - Verify user role is DOCTOR
    - Return 403 if not doctor
    - Log access violation in audit trail
    - _Requirements: 10.1, 10.5_
  
  - [ ] 13.2 Create requirePatientConnection middleware
    - Extract patientId from request params or body
    - Verify ACCEPTED connection exists
    - Return 403 if no connection
    - Log access violation in audit trail
    - _Requirements: 10.1, 10.5_
  
  - [ ] 13.3 Create preventDoctorPatientActions middleware
    - Block doctors from marking doses as taken
    - Block doctors from accessing family-only data
    - Return 403 with appropriate error message
    - Log access violation in audit trail
    - _Requirements: 10.3, 10.4, 10.5_
  
  - [ ]* 13.4 Write property test for role-based action restrictions
    - **Property 21: Role-Based Action Restrictions**
    - **Validates: Requirements 10.3**
  
  - [ ]* 13.5 Write property test for access control violation logging
    - **Property 25: Access Control Violation Logging**
    - **Validates: Requirements 10.5**

- [ ] 14. Implement audit logging enhancements
  - [ ] 14.1 Add logConnectionAction method to AuditService
    - Create audit log entry for connection actions
    - Include actorId, actionType, connectionId, details
    - Ensure immutability (no update/delete methods)
    - _Requirements: 1.6, 11.1, 11.4_
  
  - [ ] 14.2 Add logPrescriptionAction method to AuditService
    - Create audit log entry for prescription actions
    - Include complete prescription data in details
    - _Requirements: 5.4, 11.2_
  
  - [ ] 14.3 Add logNoteAction method to AuditService
    - Create audit log entry for note actions
    - Include note ID and content hash
    - _Requirements: 11.3_
  
  - [ ]* 14.4 Write property test for comprehensive audit logging
    - **Property 23: Comprehensive Audit Logging**
    - **Validates: Requirements 1.6, 5.4, 6.5, 11.1, 11.2, 11.3, 11.4**
  
  - [ ]* 14.5 Write property test for audit trail immutability
    - **Property 22: Audit Trail Immutability**
    - **Validates: Requirements 11.5**

- [ ] 15. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 16. Implement notification enhancements
  - [ ] 16.1 Add sendPrescriptionNotification method
    - Generate notification for prescription sent
    - Include prescription details in notification data
    - _Requirements: 9.1_
  
  - [ ] 16.2 Add sendLowAdherenceNotification method
    - Generate notification when adherence drops below 70%
    - Include encouragement message
    - _Requirements: 9.2_
  
  - [ ] 16.3 Add sendDisconnectionNotification method
    - Generate notification for disconnection
    - Include disconnection reason
    - _Requirements: 9.3_
  
  - [ ]* 16.4 Write property test for notification generation on disconnection
    - **Property 20: Notification Generation on Disconnection**
    - **Validates: Requirements 9.3**

- [ ] 17. Implement caching strategy
  - [ ] 17.1 Add Redis caching to getDashboardOverview
    - Cache dashboard metrics with 5-minute TTL
    - Invalidate cache on connection changes
    - _Requirements: 12.5_
  
  - [ ] 17.2 Add Redis caching to getPatientList
    - Cache patient list with filter key
    - Cache for 5 minutes
    - Invalidate on adherence updates
    - _Requirements: 12.5_
  
  - [ ] 17.3 Add Redis caching to calculateAdherence
    - Cache adherence calculations
    - Use patientId and date range as key
    - Cache for 5 minutes
    - _Requirements: 12.5_

- [ ] 18. Integration testing and wiring
  - [ ] 18.1 Wire all API endpoints to services
    - Connect dashboard endpoints to DoctorService
    - Connect connection endpoints to ConnectionService
    - Connect prescription endpoints to PrescriptionService
    - Connect notes endpoints to DoctorNotesService
    - _Requirements: All_
  
  - [ ] 18.2 Add error handling middleware to all endpoints
    - Handle validation errors (400)
    - Handle authentication errors (401)
    - Handle authorization errors (403)
    - Handle not found errors (404)
    - Handle server errors (500)
    - _Requirements: All_
  
  - [ ]* 18.3 Write integration tests for connection flow
    - Test request → accept → access patient data
    - Test request → reject → no access
    - Test accept → disconnect → no access
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_
  
  - [ ]* 18.4 Write integration tests for prescription flow
    - Test create → send → patient confirms → active
    - Test create → send → patient rejects → can edit
    - Test active → urgent update → version created
    - _Requirements: 5.1, 5.2, 5.3, 6.1, 6.2, 6.3_
  
  - [ ]* 18.5 Write integration tests for adherence monitoring
    - Test patient marks doses → adherence updates
    - Test missed doses → alerts generated
    - Test adherence drop → notification sent
    - _Requirements: 7.1, 7.2, 7.5, 7.6, 9.2_

- [ ] 19. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation at key milestones
- Property tests validate universal correctness properties (minimum 100 iterations each)
- Unit tests validate specific examples and edge cases
- Integration tests validate end-to-end flows
- All services reuse existing backend infrastructure (Next.js, Prisma, Redis)
- TypeScript is used throughout for type safety
- All medical actions are logged in audit trail for compliance



done