# Health Loading Indicator System - Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    DasTern App - Loading System                          │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                           APPLICATION LAYER                              │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────────┐     │
│  │  Patient Home   │  │  Prescription    │  │  Doctor Dashboard  │     │
│  │     Screen      │  │      Form        │  │      Screen        │     │
│  └────────┬────────┘  └────────┬─────────┘  └─────────┬──────────┘     │
│           │                    │                       │                 │
│           └────────────────────┼───────────────────────┘                 │
│                                │                                         │
└────────────────────────────────┼─────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          SERVICE LAYER                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │            LoadingOverlayService (Singleton)                      │  │
│  ├───────────────────────────────────────────────────────────────────┤  │
│  │  + show(context, variant, message)                                │  │
│  │  + hide()                                                         │  │
│  │  + showWhile(future, variant, message)                           │  │
│  │  + showForDuration(duration, variant, message)                   │  │
│  │  - _overlayEntry: OverlayEntry?                                  │  │
│  │  - _isShowing: bool                                              │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                │                                         │
└────────────────────────────────┼─────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          WIDGET LAYER                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │              HealthLoadingIndicator Widget                        │  │
│  ├───────────────────────────────────────────────────────────────────┤  │
│  │  Properties:                                                      │  │
│  │  • variant: HealthLoadingVariant                                 │  │
│  │  • size: HealthLoadingSize                                       │  │
│  │  • color: Color?                                                 │  │
│  │  • message: String?                                              │  │
│  │  • isFullscreen: bool                                            │  │
│  │                                                                   │  │
│  │  Named Constructors:                                             │  │
│  │  • HealthLoadingIndicator()          - Default                  │  │
│  │  • HealthLoadingIndicator.fullscreen() - Fullscreen overlay     │  │
│  │  • HealthLoadingIndicator.inline()    - Small inline            │  │
│  └───────────────────────────┬───────────────────────────────────────┘  │
│                               │                                          │
│                               ▼                                          │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                    Animation Variants                             │  │
│  ├───────────────────────────────────────────────────────────────────┤  │
│  │                                                                   │  │
│  │  ┌──────────────────┐  ┌──────────────────┐                     │  │
│  │  │   Heartbeat      │  │      Pills       │                     │  │
│  │  │   1200ms         │  │     2000ms       │                     │  │
│  │  ├──────────────────┤  ├──────────────────┤                     │  │
│  │  │ • ECG wave       │  │ • 3 pills orbit  │                     │  │
│  │  │ • Pulse rings    │  │ • Medical cross  │                     │  │
│  │  │ • Heart icon     │  │ • Color variety  │                     │  │
│  │  └──────────────────┘  └──────────────────┘                     │  │
│  │                                                                   │  │
│  │  ┌──────────────────┐  ┌──────────────────┐                     │  │
│  │  │  Medical Cross   │  │  Progress Ring   │                     │  │
│  │  │    1500ms        │  │     1800ms       │                     │  │
│  │  ├──────────────────┤  ├──────────────────┤                     │  │
│  │  │ • Pulse glow     │  │ • Circular bar   │                     │  │
│  │  │ • Shimmer        │  │ • Medical bag    │                     │  │
│  │  │ • 8 particles    │  │ • Trail effect   │                     │  │
│  │  └──────────────────┘  └──────────────────┘                     │  │
│  │                                                                   │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                       CUSTOM PAINTER LAYER                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐      │
│  │  Heartbeat       │  │     Pills        │  │  MedicalCross    │      │
│  │   Painter        │  │    Painter       │  │     Painter      │      │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘      │
│                                                                           │
│  ┌──────────────────┐                                                    │
│  │  ProgressRing    │                                                    │
│  │    Painter       │                                                    │
│  └──────────────────┘                                                    │
│                                                                           │
│  Each painter implements:                                                │
│  • paint(Canvas canvas, Size size)                                      │
│  • shouldRepaint(oldDelegate)                                           │
│  • Animation-driven rendering                                           │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         THEME & DESIGN TOKENS                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐                  │
│  │  AppColors   │  │  AppSpacing  │  │ AppTypography│                  │
│  ├──────────────┤  ├──────────────┤  ├──────────────┤                  │
│  │ primaryBlue  │  │ xs: 4.0      │  │ h1: 24px     │                  │
│  │ successGreen │  │ sm: 8.0      │  │ h2: 18px     │                  │
│  │ darkPrimary  │  │ md: 16.0     │  │ body: 14px   │                  │
│  │ ...          │  │ lg: 24.0     │  │ ...          │                  │
│  └──────────────┘  └──────────────┘  └──────────────┘                  │
│                                                                           │
│  ┌────────────────────────────────────────────────────────────────┐     │
│  │                    Localization (l10n)                         │     │
│  ├────────────────────────────────────────────────────────────────┤     │
│  │  • app_en.arb (English - 38 strings)                          │     │
│  │  • app_km.arb (Khmer - 38 strings)                            │     │
│  │  • loadingMedications, loadingProcessing, etc.                │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────┐
│                           USAGE FLOW DIAGRAM                             │
└─────────────────────────────────────────────────────────────────────────┘

    User Action (e.g., Submit Form)
            │
            ▼
    ┌───────────────────────┐
    │ Call Service Method   │
    │ LoadingOverlayService │
    │   .show(context)      │
    └───────────┬───────────┘
                │
                ▼
    ┌───────────────────────┐
    │  Create OverlayEntry  │
    │  with Loading Widget  │
    └───────────┬───────────┘
                │
                ▼
    ┌───────────────────────┐
    │ Insert into Overlay   │
    │ Barrier blocks input  │
    └───────────┬───────────┘
                │
                ▼
    ┌───────────────────────┐
    │  Widget animates      │
    │  using CustomPainter  │
    └───────────┬───────────┘
                │
                ▼
    ┌───────────────────────┐
    │  Async operation      │
    │  executes             │
    └───────────┬───────────┘
                │
                ▼
    ┌───────────────────────┐
    │ Call .hide()          │
    │ Remove overlay entry  │
    └───────────┬───────────┘
                │
                ▼
    ┌───────────────────────┐
    │  Show result/feedback │
    │  (SnackBar, etc.)     │
    └───────────────────────┘


┌─────────────────────────────────────────────────────────────────────────┐
│                      COMPONENT RELATIONSHIPS                             │
└─────────────────────────────────────────────────────────────────────────┘

                    ┌─────────────────────┐
                    │   Demo Screen       │
                    │  (Interactive UI)   │
                    └──────────┬──────────┘
                               │
                               │ uses
                               │
                ┌──────────────┼──────────────┐
                │              │              │
                ▼              ▼              ▼
    ┌──────────────────┐  ┌────────┐  ┌──────────────┐
    │  Loading Widget  │  │Service │  │  Examples    │
    │                  │◄─┤        │  │  (Reference) │
    └──────────────────┘  └────────┘  └──────────────┘
            │                  │
            │ contains         │ manages
            │                  │
            ▼                  ▼
    ┌──────────────────┐  ┌────────────────┐
    │  Custom Painters │  │ Overlay Entry  │
    │  (4 variants)    │  │ (_overlayEntry)│
    └──────────────────┘  └────────────────┘
            │
            │ uses
            │
            ▼
    ┌──────────────────┐
    │  Design Tokens   │
    │  (Colors, etc.)  │
    └──────────────────┘
```

## Data Flow

### Show Loading Flow
```
User/System → LoadingOverlayService.show()
                ↓
          Create _LoadingOverlay widget
                ↓
          Wrap in OverlayEntry
                ↓
          Insert into Overlay stack
                ↓
          HealthLoadingIndicator renders
                ↓
          CustomPainter draws animation
                ↓
          AnimationController repeats
```

### Hide Loading Flow
```
User/System → LoadingOverlayService.hide()
                ↓
          Remove OverlayEntry
                ↓
          Dispose widget
                ↓
          Clean up resources
```

## Size Hierarchy

```
Small (32px)    ──►  Buttons, List Items, Inline
   │
   ▼
Medium (64px)   ──►  Cards, Forms, Default
   │
   ▼
Large (96px)    ──►  Fullscreen, Modal Dialogs
   │
   ▼
XLarge (128px)  ──►  Splash, Critical Operations
```

## Animation Timing

```
Timeline:   0ms ─────────────► 2000ms
            │                     │
Heartbeat:  ├──► 1200ms          │
Pills:      │                    ├──► 2000ms
MedCross:   ├──► 1500ms          │
Progress:   ├──► 1800ms          │
```

## Theme Integration

```
Light Mode:
  Background: white.withOpacity(0.85)
  Primary: AppColors.primaryBlue (#5575E8)
  Text: AppColors.textPrimary

Dark Mode:
  Background: black.withOpacity(0.7)
  Primary: AppColors.darkPrimary (#5C7CFF)
  Text: AppColors.textOnDark
```
