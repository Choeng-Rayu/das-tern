---
applyTo: '**'
---
AI AGENT RULES – DASTERN ARCHITECTURE & WORKFLOW


Architecture Overview
=====================

System Components:

1. backend (NestJS)
   - Main business logic
   - Handles authentication, medication, users, payment processing
   - Communicates with Bakong Service
   - Connects to PostgreSQL and Redis (via Docker)

2. bakong_service (Separate VPS)
   - Handles Bakong payment integration
   - Receives encrypted payload from backend
   - Generates QR code via Bakong API
   - Receives payment notification from Bakong
   - Sends payment success callback to main backend
   - Does NOT connect to the main PostgreSQL/Redis Docker
   - Stores only minimal payment-related data

3. frontend: das_tern_mcp (Flutter)
   - Mobile application
   - Implement flutter must support english and khmer language so please check the /home/rayu/das-tern/das_tern_mcp/lib/l10n folder for the existing localization files and follow the pattern for adding new strings.
   - Communicates only with backend (NOT directly with bakong_service)
   - **Code Quality Rule**: Always run `flutter analyze` and fix ALL issues until ZERO issues before testing. After implementation, test to find new issues and fix them.
   - **Widget Design Principle**: All widgets must be designed for scalability and reusability. Create base widgets with maximum configurability, then specialized widgets that extend or compose them.
   - **Widget Thinking**: Before implementation, analyze existing widgets, plan parameters for all use cases, and ensure theme integration.

4. Database
   - PostgreSQL (Docker only)
   - Redis (Docker only)
   - Docker is used ONLY for Postgres and Redis


System Flow
===========

Payment Flow:

1. Flutter app sends payment request to backend (NestJS).
2. Backend encrypts payload and sends request to bakong_service.
3. bakong_service calls Bakong API and generates QR code.
4. bakong_service returns QR code response to backend.
5. Backend sends QR code to Flutter app.
6. User pays via Bakong.
7. Bakong sends payment notification to bakong_service.
8. bakong_service validates and notifies backend.
9. Backend updates payment status in PostgreSQL.
10. Backend confirms successful payment to frontend.

Important:
- Flutter NEVER talks directly to bakong_service.
- bakong_service NEVER connects to main database Docker.
- Only backend updates main database.


Agent Execution Rules
=====================

1. Sub-Agent Task Delegation
----------------------------

The main agent MUST delegate tasks to sub-agents.

Example: "Create Medication Feature"

- Sub-agent 1: Implement backend (NestJS)
- Sub-agent 2: Implement frontend (Flutter)
- Sub-agent 3: Verify API contract and integration between backend and frontend

The main agent coordinates, but does NOT implement everything alone.


2. Frontend UI Validation Rule
-------------------------------

When implementing or modifying Flutter UI:

- MUST use sub-agent with MCP server
- MUST check Figma design before implementing
- UI must match Figma structure, spacing, naming, and components


3. Flutter Code Quality & Testing Rule
--------------------------------------

**CRITICAL**: When implementing Flutter code:

**A. Pre-Testing Analysis:**
- MUST run `flutter analyze` before ANY testing
- MUST fix ALL issues until ZERO issues remain
- NO testing is allowed with analysis issues present

**B. Implementation Testing Cycle:**
1. **Implement Feature**: Write the required code
2. **Run Analysis**: Execute `flutter analyze`
3. **Fix Issues**: Address ALL analysis issues
4. **Verify Zero Issues**: Confirm `flutter analyze` shows 0 issues
5. **Test Implementation**: Run tests to verify functionality
6. **Find New Issues**: Testing may reveal new issues
7. **Fix New Issues**: Address issues found during testing
8. **Repeat Analysis**: Run `flutter analyze` again after fixes
9. **Final Verification**: Ensure ZERO issues before completion

**C. Required Commands:**
```bash
# Before testing - MUST have 0 issues
flutter analyze

# After fixing issues - verify 0 issues
flutter analyze --no-fatal-infos

# Test implementation
flutter test
```

**D. Prohibited Actions:**
- ❌ Never test with existing `flutter analyze` issues
- ❌ Never skip analysis after implementation
- ❌ Never consider implementation complete with analysis issues
- ❌ Never ignore issues found during testing

**E. Acceptance Criteria:**
- [ ] `flutter analyze` shows 0 issues before testing
- [ ] All tests pass after implementation
- [ ] `flutter analyze` shows 0 issues after testing fixes
- [ ] No new analysis issues introduced


4. Widget Scalability & Reusability Rule
-----------------------------------------

When implementing Flutter widgets:

**A. Widget Design Principles:**
- Every widget MUST be designed for scalability and reusability
- Base widgets should be generic and configurable through parameters
- Specialized widgets should extend or compose base widgets
- Avoid creating one-off widgets for unique use cases

**B. Button Widget Example Pattern:**
```
// Base button widget - highly configurable
class BaseButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonStyle? style;
  final Widget? icon;
  final EdgeInsets? padding;
  // ... other configurable parameters
  
  // Use this base widget for all buttons
}

// Specialized buttons extend or compose base widget
class PrimaryButton extends BaseButton {
  // Custom styling for primary actions
}

class SecondaryButton extends BaseButton {
  // Custom styling for secondary actions
}

class IconButton extends BaseButton {
  // Button with icon only
}
```

**C. Widget Implementation Requirements:**
1. **Parameter Analysis**: Before creating a widget, analyze all potential use cases and required parameters
2. **Default Values**: Provide sensible defaults for all optional parameters
3. **Composition Over Inheritance**: Prefer composition for complex widgets
4. **Theme Integration**: Use app theme colors, spacing, and typography consistently
5. **Localization Support**: All text must support English and Khmer via AppLocalizations
6. **Accessibility**: Include semantic labels and proper contrast ratios
7. **Scalability First**: Design widgets to handle future requirements without breaking changes

**D. Widget File Organization:**
- Common reusable widgets → `/lib/ui/widgets/common_widgets.dart`
- Feature-specific widgets → `/lib/ui/widgets/[feature_name]_widgets.dart`
- Complex widget compositions → Separate files with clear naming
- Widget examples and patterns → `/home/rayu/das-tern/.github/instructions/widget_scalability_example.md`


5. Todo List Requirement
-------------------------

Before implementing any feature:

- MUST create a detailed step-by-step Todo list
- Todo list must separate:
  - Backend tasks
  - Frontend tasks
  - Integration tasks
  - Testing tasks

No direct implementation without structured Todo plan.


6. Sensitive Value Change Rule
-------------------------------

When changing any sensitive value:

Examples:
- .env variables
- Database schema
- API route paths
- DTO fields
- Encryption keys
- Redis keys
- Payment status enums

The agent MUST:

- Identify all related fields affected
- Update backend logic
- Update frontend API calls if needed
- Update validation DTOs
- Update database schema if required
- Update documentation
- Restart required services (if environment/database related)

No partial update is allowed.


7. Backend Responsibility Rule
------------------------------

- Only backend (NestJS) can modify PostgreSQL.
- bakong_service must NOT modify main database.
- Payment confirmation must always be verified by backend before updating status.


8. Separation of Concerns Rule
------------------------------

- Flutter → UI only
- Backend → Business logic + Database
- bakong_service → Payment gateway communication only
- Docker → Only PostgreSQL and Redis


9. Widget Thinking Before Implementation Rule
---------------------------------------------

**CRITICAL**: Before implementing any Flutter widget:

**A. Analysis Phase:**
1. **Existing Widget Check**: Search for existing widgets that can be reused or extended
2. **Use Case Analysis**: Document all potential use cases for the widget
3. **Parameter Planning**: List all configurable parameters needed for scalability
4. **Theme Integration**: Plan how the widget will use app theme (colors, spacing, typography)

**B. Implementation Strategy:**
1. **Base Widget First**: Always create a base widget with maximum configurability
2. **Specialized Widgets**: Create specialized widgets that extend or compose the base widget
3. **Default Values**: Provide sensible defaults for all optional parameters
4. **Localization Ready**: Ensure all text parameters support AppLocalizations

**C. Example Workflow for Button Implementation:**
```
1. Analyze: Need buttons for primary actions, secondary actions, icon buttons, loading states
2. Design: Create BaseButton with text, onPressed, isLoading, style, icon, padding, etc.
3. Implement: 
   - BaseButton (highly configurable)
   - PrimaryButton extends BaseButton with primary styling
   - SecondaryButton extends BaseButton with secondary styling
   - IconButton composes BaseButton with icon-only configuration
4. Test: Verify all button types work with different states and configurations
```

**D. Prohibited Actions:**
- ❌ Never create one-off widgets for unique use cases
- ❌ Never hardcode values that should be parameters
- ❌ Never skip localization support for text
- ❌ Never implement without checking existing widget patterns


Expected Agent Behavior
=======================

- Always think in system architecture, not isolated features.
- Never break separation of concerns.
- Always validate backend ↔ frontend contract.
- Always validate encryption and payment flow consistency.
- Always work with structured delegation and clear task boundaries.
- **Always think about widget reusability and scalability before implementation.**

End of Rules
============

**E. Agent Thinking Process for Widget Implementation:**

When the agent is asked to implement frontend widgets, it MUST follow this thinking process:

1. **Analysis Phase (Think First):**
   - "What are all the possible use cases for this widget?"
   - "What existing widgets can I reuse or extend?"
   - "What parameters will make this widget scalable for future needs?"
   - "How will this widget integrate with the app theme and localization?"

2. **Design Phase (Plan Before Code):**
   - Create a base widget with maximum configurability
   - Plan specialized widgets for common use cases
   - Design theme integration points
   - Plan localization support

3. **Implementation Phase (Code with Scalability):**
   - Implement base widget first
   - Create specialized widgets that extend/compose the base
   - Add comprehensive parameter documentation
   - Include usage examples

4. **Validation Phase (Verify Scalability):**
   - Test with different parameter combinations
   - Verify theme integration works
   - Check localization support
   - Ensure accessibility compliance

**CRITICAL RULE:** The agent must THINK about widget scalability BEFORE writing any code. No implementation should start without completing the analysis and design phases.
