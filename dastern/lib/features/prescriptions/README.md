# Feature: prescriptions

> Spec: [`.kiro/specs-v2-flutter-supabase/03-prescription-medication/`](../../../../.kiro/specs-v2-flutter-supabase/03-prescription-medication/)

Patient-side prescription + medication CRUD, versioning, urgent-apply flow.
Lifecycle: `Draft → Active → Paused → Inactive`.

## Folder layout (when implemented)

```
prescriptions/
├── data/
│   ├── prescription_repository.dart
│   └── prescription_repository_impl.dart
├── domain/
│   ├── prescription.dart              # freezed
│   ├── medication.dart                # freezed
│   └── prescription_lifecycle.dart    # already in shared/widgets/badges
└── presentation/
    ├── prescriptions_list_page.dart
    ├── prescription_detail_page.dart
    ├── create_prescription_page.dart
    └── widgets/
```
