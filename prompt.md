# DAS TERN Project - AI Agent Implementation Guide

## Project Overview
This is a comprehensive guide for implementing the DAS TERN healthcare application. The project involves medication management, doctor-patient interactions, prescription handling, and family connections.

---

## 📋 CORE REQUIREMENT
**BEFORE IMPLEMENTING ANY TASK**: Always read the relevant documentation in the `docs` folder that relates to your current task. The docs contain flows, requirements, user stories, UI specifications, and folder structures.

---

## PHASE 1: Documentation Synchronization with Figma

### Phase 1.1: Figma Data Extraction
**Objective**: Extract all design data from Figma MCP server and understand the UI structure.

**Steps**:
1. Connect to Figma MCP server using the configuration in `docs/mcp_server/figma_mcp_config.json`
2. Extract all design components, pages, and flows from Figma
3. Document the complete UI structure found in Figma
4. Create a mapping document showing:
   - All screens/pages in Figma
   - All components in Figma
   - Flow diagrams in Figma
   - Design tokens (colors, typography, spacing)

**Output**: `figma_design_inventory.md` containing all extracted information

---

### Phase 1.2: UI Documentation Update - Authentication
**Obication UI documentation to match Figma designs.

**Target Files*das_tern/ui_designs/auth_ui/login_page_ui/user_login_ui.md`
- `docs/about_das_tern/ui_designs/auth_ui/register_page_ui/doctor_register_ui.md`
- `docs/about_das_tern/ui_designs/ge_ui/patient_register_ui.md`
- `docs/about_das_tern/ui_designs/auth_ui/recovery_account_ui/reount_ui.md`

**Required Actions for Each File**:
1. Read the current documentation
2. Compare with Figma design data
3. Update with user stories in this format:
   ```markdown
   ## UseStory Name]
   
   **As a** [user type]
   **I want** [goal]
   **So that** [benefit]
   
   ### Acceptance Criteria
   - [ ] Criterion 1
   - [ ] Criterion 2
   
   ### UI Components
   - Component 1: [Description, properties, behavior]
   - Component 2: [Description, properties, behavior]
   
   ### Interactions
   - Interaction 1: [User action → System response]
   
   ### Visual Specifications
   - Layout: [Description]
   - Colors: [From Figma]
   - Typography: [From Figma]
   - Spacing: [From Figma]
   
   ### Flow Integration
   - Previous screen: [Link]
   - Next screen: [Link]
   - Alternative paths: [Links]
   ```

---

### Phase 1.3: UI Documentation Update - Doctor Dashboard
**Objective**: Update doctor dashboard UI documentation to match Figma designs.

**Target Files**:
- `docs/about_das_tern/ui_designs/doctor_dashboard_ui/README.md`

**Required Actions**:
1. Read `docs/about_das_tern/flows/doctor_send_prescriptoin_to_patient_flow/README.md`
2. Extract all doctor dashboard screens from Figma
3. Document each screen/view with user stories:
   - Dashboard overview
   - Patient list view
   - Prescription creation interface
   - Prescription history
   - Patient profile view
   - Notification center
4. Map each UI element to business logic from `docs/about_das_tern/business_logic/README.md`
5. Cross-reference with prescription flow documentation

**Output Format**:
```markdown
# Doctor Dashboard UI Documentation

## Overview
[General description of doctor dashboard purpose and structure]

## User Stories

### US-DD-001: View Patient List
**As a** doctor
**I want** to see a list of all my patients
**So that** I can quickly access patient information

[Continue with full documentation per template above]

## Screen Inventory
1. Dashboard Home
2. Patient List
3. [etc.]

## Component Library
[List all reusable components used in doctor dashboard]

## Integration Points
[How this dashboard connects to other parts of the system]
```

---

### Phase 1.4: UI Documentation Update - Patient Dashboard
**Objective**: Update patient dashboard UI documentation to match Figma designs.

**Target Files**:
- `docs/about_das_tern/ui_designs/patient_dashboard_ui/README.md`

**Required Actions**:
1. Read related flow documentation:
   - `docs/about_das_tern/flows/create_medication_flow/README.md`
   - `docs/about_das_tern/flows/reminder_flow/README.md`
   - `docs/about_das_tern/flows/family_connection_flow/README.md`
2. Extract all patient dashboard screens from Figma
3. Document each screen/view with user stories:
   - Dashboard overview
   - Medication list
   - Medication detail view
   - Reminder management
   - Family connections view
   - Prescription inbox
   - Health tracking
4. Map UI to business logic and flows

**Output Format**: Same as Phase 1.3 but for patient context

---

### Phase 1.5: UI Documentation Update - Shared Components
**Objective**: Update header and footer UI documentation.

**Target Files**:
- `docs/about_das_tern/ui_designs/header_ui/header_requirement_ui.md`
- `docs/about_das_tern/ui_designs/footer_ui/footer_requirement_ui.md`

**Required Actions**:
1. Extract header and footer designs from Figma
2. Document variants (authenticated vs. unauthenticated, doctor vs. patient)
3. Specify all navigation elements
4. Document responsive behavior
5. List all interactive elements and their actions

---

### Phase 1.6: Flow Documentation Validation
**Objective**: Ensure all flow documentation matches Figma flows.

**Target Files**:
- `docs/about_das_tern/flows/README.md`
- `docs/about_das_tern/flows/create_medication_flow/README.md`
- `docs/about_das_tern/flows/doctor_send_prescriptoin_to_patient_flow/README.md`
- `docs/about_das_tern/flows/family_connection_flow/README.md`
- `docs/about_das_tern/flows/reminder_flow/README.md`

**Required Actions for Each Flow**:
1. Read the existing flow documentation
2. Compare with Figma flow diagrams
3. Update flow documentation with:
   ```markdown
   # [Flow Name]
   
   ## Flow Overview
   [Description of what this flow accomplishes]
   
   ## Actors
   - Actor 1: [Description]
   - Actor 2: [Description]
   
   ## Preconditions
   - Precondition 1
   - Precondition 2
   
   ## Flow Steps
   
   ### Step 1: [Step Name]
   **Screen**: [Link to UI documentation]
   **User Action**: [What user does]
   **System Response**: [What system does]
   **Data**: [Data involved]
   **Validation**: [Any validation rules]
   **Next Step**: Step 2 OR [alternative paths]
   
   [Repeat for all steps]
   
   ## Success Criteria
   - [ ] Criterion 1
   - [ ] Criterion 2
   
   ## Error Scenarios
   - Error 1: [Description and handling]
   - Error 2: [Description and handling]
   
   ## Related Documentation
   - Business Logic: [Link]
   - UI Screens: [Links]
   - API Endpoints: [Links if applicable]
   ```

---

### Phase 1.7: Phase 1 Validation & Report
**Objective**: Validate all documentation updates are complete and consistent.

**Actions**:
1. Create a checklist of all updated documents
2. Verify cross-references between documents are accurate
3. Ensure all Figma designs are documented
4. Generate a comprehensive report

**Output**: `phase_1_completion_report.md`

---

## PHASE 2: Agent Rules and Implementation Guidelines

### Phase 2.1: Understand Project Architecture
**Objective**: Thoroughly understand the system architecture before writing agent rules.

**Required Reading**:
1. Read `docs/architectures/README.md` completely
2. Understand:
   - System components and their relationships
   - Technology stack
   - Data flow
   - API structure
   - Database schema
   - Security architecture
   - Deployment architecture

**Output**: Create `architecture_summary.md` with key points

---

### Phase 2.2: Define Agent Capabilities and Boundaries
**Objective**: Establish what the AI agent can and cannot do.

**Target File**: `docs/agent_rules/README.md`

**Required Content**:

```markdown
# AI Agent Rules for DAS TERN Project

## Agent Purpose
This AI agent assists in the development and maintenance of the DAS TERN healthcare application by following strict rules and accessing specific tools.

---

## CORE PRINCIPLES

### Principle 1: Documentation-First Approach
**MANDATORY**: Before implementing any feature or task, the agent MUST:
1. Read ALL relevant documentation in `docs/about_das_tern/`
2. Understand the business logic in `docs/about_das_tern/business_logic/README.md`
3. Review related flows in `docs/about_das_tern/flows/`
4. Check UI specifications in `docs/about_das_tern/ui_designs/`
5. Verify architecture constraints in `docs/architectures/README.md`

### Principle 2: Never Assume
- Always refer to documentation rather than making assumptions
- If documentation is unclear, request clarification
- Do not implement features not specified in documentation

### Principle 3: Consistency
- Follow existing patterns in the codebase
- Maintain consistency with documented flows and UI
- Use established naming conventions

### Principle 4: Quality Over Speed
- Write clean, maintainable code
- Include proper error handling
- Add comments for complex logic
- Write tests for new functionality

---

## AGENT CAPABILITIES

### 1. Code Implementation
**What Agent Can Do**:
- Implement UI components based on `docs/about_das_tern/ui_designs/`
- Create business logic based on `docs/about_das_tern/business_logic/`
- Implement flows as documented in `docs/about_das_tern/flows/`
- Write unit tests and integration tests
- Refactor existing code for better maintainability

**What Agent Cannot Do**:
- Change core architecture without approval
- Implement features not in documentation
- Skip documentation review
- Bypass security requirements

### 2. Documentation Management
**What Agent Can Do**:
- Update documentation to reflect implementation
- Create technical documentation for new components
- Generate API documentation
- Create developer guides

**What Agent Cannot Do**:
- Delete existing documentation without approval
- Change business requirements
- Modify flow specifications without validation

### 3. Testing
**What Agent Can Do**:
- Write unit tests for components
- Create integration tests for flows
- Perform basic validation testing
- Generate test reports

### 4. Code Review Support
**What Agent Can Do**:
- Review code for adherence to documented requirements
- Check code quality and standards
- Identify potential bugs
- Suggest improvements

---

## AVAILABLE TOOLS

### Tool 1: File System Access
**Purpose**: Read and write project files
**Usage Rules**:
- Always check if file exists before reading
- Never overwrite files without backup
- Use appropriate file paths based on project structure

### Tool 2: Documentation Reader
**Purpose**: Access and parse project documentation
**Usage Rules**:
- MANDATORY to use before starting any task
- Cache frequently accessed docs
- Always check for updates

### Tool 3: Code Generator
**Purpose**: Generate code based on specifications
**Usage Rules**:
- Must have complete specification from docs
- Follow project code style
- Include necessary imports and dependencies

### Tool 4: MCP Server Connector
**Purpose**: Connect to Figma and other MCP servers
**Usage Rules**:
- Use configuration from `docs/mcp_server/`
- Validate connection before use
- Handle connection errors gracefully

### Tool 5: Test Runner
**Purpose**: Execute tests and report results
**Usage Rules**:
- Run tests after implementation
- Generate coverage reports
- Log all test failures

---

## TASK EXECUTION WORKFLOW

### Step 1: Task Receipt
1. Receive task description
2. Identify task type (UI, business logic, flow, etc.)
3. List all potentially relevant documentation

### Step 2: Documentation Review
1. Read `docs/about_das_tern/README.md` for context
2. Read specific documentation related to task:
   - For UI tasks: Read relevant files in `ui_designs/`
   - For flow tasks: Read relevant files in `flows/`
   - For business logic: Read `business_logic/README.md`
3. Read `docs/architectures/README.md` for architectural constraints
4. Create a summary of requirements

### Step 3: Planning
1. Break down task into subtasks
2. Identify dependencies
3. Determine required tools
4. Estimate effort
5. Create implementation plan

### Step 4: Implementation
1. Set up necessary files/folders
2. Implement according to plan
3. Follow coding standards
4. Add inline documentation
5. Handle errors appropriately

### Step 5: Testing
1. Write tests if needed
2. Run existing tests
3. Validate against requirements
4. Test edge cases

### Step 6: Documentation Update
1. Update relevant documentation if implementation differs from spec
2. Add technical documentation
3. Update README files if needed

### Step 7: Review & Report
1. Self-review code
2. Check against all requirements
3. Generate completion report
4. List any deviations from spec

---

## TASK-SPECIFIC RULES

### UI Component Implementation

**Pre-Implementation Checklist**:
- [ ] Read UI specification from `docs/about_das_tern/ui_designs/`
- [ ] Verify Figma design sync
- [ ] Check for existing similar components
- [ ] Review design tokens and style guide
- [ ] Understand component's role in user flow

**Implementation Rules**:
1. Use exact specifications from documentation
2. Implement responsive behavior as specified
3. Include all accessibility features
4. Handle all interaction states (hover, active, disabled, etc.)
5. Implement proper error states
6. Add loading states where applicable

**Post-Implementation Checklist**:
- [ ] Component matches Figma design
- [ ] All user stories satisfied
- [ ] Accessibility requirements met
- [ ] Responsive on all specified breakpoints
- [ ] Error handling implemented
- [ ] Tests written and passing

### Flow Implementation

**Pre-Implementation Checklist**:
- [ ] Read complete flow documentation from `docs/about_das_tern/flows/`
- [ ] Understand all actors involved
- [ ] Map all flow steps
- [ ] Identify all decision points
- [ ] Review error scenarios
- [ ] Check integration points with other flows

**Implementation Rules**:
1. Implement each step exactly as documented
2. Handle all error scenarios
3. Validate data at each step
4. Maintain flow state correctly
5. Implement proper navigation
6. Log important flow events
7. Handle concurrent users appropriately

**Post-Implementation Checklist**:
- [ ] All flow steps implemented
- [ ] All decision branches working
- [ ] Error scenarios handled
- [ ] State management correct
- [ ] Navigation working
- [ ] Integration points tested

### Business Logic Implementation

**Pre-Implementation Checklist**:
- [ ] Read `docs/about_das_tern/business_logic/README.md`
- [ ] Understand all business rules
- [ ] Identify affected entities
- [ ] Review validation requirements
- [ ] Check authorization rules

**Implementation Rules**:
1. Implement all business rules exactly
2. Add comprehensive validation
3. Handle edge cases
4. Implement proper error handling
5. Log business events
6. Ensure data integrity
7. Follow transaction requirements

**Post-Implementation Checklist**:
- [ ] All business rules implemented
- [ ] Validation complete
- [ ] Edge cases handled
- [ ] Tests cover all scenarios
- [ ] Data integrity maintained

---

## ERROR HANDLING RULES

### Documentation Not Found
**If Required Documentation Missing**:
1. STOP implementation
2. Report which documentation is missing
3. Request documentation creation or clarification
4. Do NOT proceed with assumptions

### Conflicting Information
**If Documentation Conflicts**:
1. STOP implementation
2. Document the conflict clearly
3. Request resolution
4. Do NOT choose one arbitrarily

### Unclear Requirements
**If Requirements Ambiguous**:
1. Document ambiguity
2. List possible interpretations
3. Request clarification
4. Do NOT implement without clarification

---

## QUALITY STANDARDS

### Code Quality
- Follow project style guide
- Maximum function length: 50 lines
- Maximum file length: 500 lines
- Cyclomatic complexity: < 10
- Code coverage: > 80%

### Documentation Quality
- All public functions documented
- Complex logic explained
- Examples provided where helpful
- Links to related documentation

### Testing Quality
- Unit tests for all business logic
- Integration tests for all flows
- Edge cases covered
- Error scenarios tested

---

## REPORTING FORMAT

### Daily Progress Report
```markdown
# Daily Progress Report - [Date]

## Tasks Completed
- Task 1: [Description] - Status: ✅
- Task 2: [Description] - Status: ✅

## Tasks In Progress
- Task 3: [Description] - Status: 🔄 - Progress: 60%

## Blockers
- Blocker 1: [Description] - Impact: High - Needs: [What's needed]

## Documentation Read Today
- Document 1: [Path]
- Document 2: [Path]

## Code Statistics
- Files Created: X
- Files Modified: Y
- Tests Added: Z
- Test Coverage: X%

## Tomorrow's Plan
- Task 1: [Description]
- Task 2: [Description]
```

### Task Completion Report
```markdown
# Task Completion Report - [Task Name]

## Task Summary
[Brief description]

## Documentation Reviewed
- [List all documentation files read]

## Implementation Details
[What was implemented]

## Files Changed
- Created: [List]
- Modified: [List]
- Deleted: [List]

## Tests
- Tests Added: X
- All Tests Passing: Yes/No
- Coverage: X%

## Adherence to Requirements
- [Requirement 1]: ✅ Met
- [Requirement 2]: ✅ Met
- [Requirement 3]: ⚠️ Partial - [Explanation]

## Deviations from Spec
[Any differences from documented requirements and why]

## Next Steps
[What should be done next]
```

---

## EXAMPLE TASK EXECUTION

### Example: Implementing Doctor Login UI

#### Step 1: Task Receipt
**Task**: Implement the doctor login UI

#### Step 2: Documentation Review
**Documents to Read**:
1. `docs/about_das_tern/ui_designs/auth_ui/README.md`
2. `docs/about_das_tern/ui_designs/auth_ui/login_page_ui/user_login_ui.md`
3. `docs/about_das_tern/business_logic/README.md` (authentication section)
4. `docs/architectures/README.md` (authentication architecture)

**Summary Created**:
- Login form requires: email, password fields
- "Remember me" checkbox required
- "Forgot password" link required
- Social login options: Google, Facebook
- Error messages for invalid credentials
- Loading state during authentication
- Redirect to doctor dashboard on success
- Validation: email format, password min 8 chars

#### Step 3: Planning
**Subtasks**:
1. Create LoginForm component
2. Implement form validation
3. Create authentication service integration
4. Implement error handling UI
5. Add loading states
6. Implement navigation logic
7. Write tests

**Dependencies**:
- Design tokens from style guide
- Authentication API endpoint
- Navigation routing setup

#### Step 4: Implementation
[Agent implements component according to specifications]

#### Step 5: Testing
[Agent writes and runs tests]

#### Step 6: Documentation Update
[Agent updates technical docs if needed]

#### Step 7: Review & Report
[Agent generates completion report]

---

## MAINTENANCE MODE RULES

### When Reviewing Existing Code
1. Check if code matches current documentation
2. If mismatch found, determine which is correct
3. Update code or documentation to match
4. Never leave mismatches unresolved

### When Documentation Changes
1. Identify all affected code
2. Update code to match new documentation
3. Run all affected tests
4. Update related documentation

---

## SECURITY RULES

### Never Implement
- Hardcoded credentials
- Unencrypted sensitive data
- SQL injection vulnerabilities
- XSS vulnerabilities
- Insecure direct object references

### Always Implement
- Input validation
- Output encoding
- Authentication checks
- Authorization checks
- Secure communication (HTTPS)
- Error handling without information disclosure

---

## PERFORMANCE RULES

### Always Consider
- Database query optimization
- Caching strategies
- Lazy loading where appropriate
- Code splitting for large applications
- Image optimization

### Never Do
- N+1 queries
- Synchronous operations that block UI
- Large bundle sizes without code splitting
- Missing loading indicators

---

## COLLABORATION RULES

### With Human Developers
- Provide clear progress updates
- Ask for clarification when needed
- Respect human decisions on architecture
- Provide reasoning for suggestions

### With Other Agents
- Share context through documentation
- Avoid duplicate work
- Report completion status clearly

---

## CONTINUOUS IMPROVEMENT

### Learn from Feedback
- Track which implementations needed revision
- Identify common documentation gaps
- Suggest documentation improvements
- Update rules based on lessons learned

---

## ESCALATION RULES

### Escalate When
- Documentation conflicts cannot be resolved
- Security concerns identified
- Architecture changes needed
- Task complexity exceeds agent capability
- External dependencies blocking progress

### Escalation Format
```markdown
# Escalation Required

## Issue
[Clear description of the problem]

## Context
- Task: [Task name]
- Documentation Reviewed: [List]
- Attempted Solutions: [List]

## Impact
- Severity: High/Medium/Low
- Blocks: [What is blocked]

## Recommendation
[Suggested resolution if any]

## Required Decision
[What decision is needed from human]
```

---

## APPENDIX

### Common File Paths Reference
- UI Documentation: `docs/about_das_tern/ui_designs/`
- Flow Documentation: `docs/about_das_tern/flows/`
- Business Logic: `docs/about_das_tern/business_logic/README.md`
- Architecture: `docs/architectures/README.md`
- Agent Rules: `docs/agent_rules/README.md`

### Quick Reference Checklist
Before ANY implementation:
- [ ] Read relevant UI docs
- [ ] Read relevant flow docs
- [ ] Read business logic docs
- [ ] Read architecture docs
- [ ] Understand all requirements
- [ ] Create implementation plan
- [ ] Identify all tools needed

---

*Last Updated: [Date]*
*Version: 2.0*
```

---

### Phase 2.3: Define Task Categories and Templates
**Objective**: Create standard templates for common task types.

**Actions**:
1. Identify all task types in the project
2. Create template for each task type
3. Define required documentation for each task type
4. Create checklists for each task type

**Output**: Add task templates section to agent rules

---

### Phase 2.4: Tool Integration Documentation
**Objective**: Document how agent uses each available tool.

**Actions**:
1. List all tools available to agent
2. Document usage patterns for each tool
3. Create examples for common tool combinations
4. Document error handling for each tool

---

### Phase 2.5: Create Implementation Examples
**Objective**: Provide concrete examples of task execution.

**Actions**:
1. Create 3-5 complete examples of different task types
2. Show step-by-step execution
3. Include decision points and reasoning
4. Show documentation references used

---

### Phase 2.6: Phase 2 Validation
**Objective**: Test agent rules with sample tasks.

**Actions**:
1. Select 3 representative tasks
2. Execute using defined agent rules
3. Identify gaps or ambiguities
4. Refine rules based on findings

**Output**: `phase_2_completion_report.md`

---

## PHASE 3: Integration and Testing

### Phase 3.1: End-to-End Flow Testing
**Objective**: Ensure all documented flows work correctly.

**Required Reading Before Each Flow Test**:
- Flow documentation from `docs/about_das_tern/flows/`
- Related UI documentation
- Related business logic documentation

**Actions for Each Flow**:
1. Create test plan based on flow documentation
2. Implement automated tests
3. Execute tests
4. Document results
5. Fix any issues
6. Update documentation if needed

---

### Phase 3.2: UI Consistency Validation
**Objective**: Ensure all UI matches Figma and documentation.

**Actions**:
1. Visual regression testing setup
2. Compare implemented UI with Figma
3. Verify all user stories are satisfied
4. Document any deviations
5. Create remediation plan

---

### Phase 3.3: Documentation Completeness Audit
**Objective**: Ensure all documentation is complete and up-to-date.

**Actions**:
1. Audit all documentation files
2. Identify gaps
3. Verify accuracy against implementation
4. Update outdated information
5. Create index of all documentation

---

## PHASE 4: Deployment Preparation

### Phase 4.1: Deployment Documentation
**Actions**:
1. Read `docs/architectures/README.md` for deployment architecture
2. Create deployment guide
3. Document environment configurations
4. Create rollback procedures

---

### Phase 4.2: Final Validation
**Actions**:
1. Complete smoke testing
2. Performance testing
3. Security audit
4. Accessibility audit
5. Final documentation review

---

## SUCCESS CRITERIA

### Phase 1 Complete When:
- [ ] All Figma designs extracted and documented
- [ ] All UI documentation matches Figma
- [ ] All flow documentation validated
- [ ] All cross-references accurate
- [ ] Completion report generated

### Phase 2 Complete When:
- [ ] Agent rules fully documented
- [ ] All task templates created
- [ ] Tool integration documented
- [ ] Examples provided
- [ ] Rules tested with sample tasks

### Phase 3 Complete When:
- [ ] All flows tested end-to-end
- [ ] UI matches Figma and documentation
- [ ] All documentation complete and accurate
- [ ] Test coverage > 80%

### Phase 4 Complete When:
- [ ] Deployment documentation complete
- [ ] All validations passed
- [ ] Production-ready

---

## NOTES FOR AGENT

### Remember:
1. **ALWAYS** read documentation before implementing
2. **NEVER** assume or guess when documentation exists
3. **ALWAYS** update documentation when you learn new information
4. **NEVER** skip testing
5. **ALWAYS** follow the established patterns
6. **NEVER** implement features not in documentation
7. **ALWAYS** ask for clarification when unclear
8. **NEVER** leave code without proper error handling

### Your Goal:
Build a high-quality, maintainable application that exactly matches the specifications in the documentation, with every decision traceable back to documented requirements.