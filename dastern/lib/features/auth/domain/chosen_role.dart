/// The two account roles in v2 (ADDENDUM-001: FAMILY_MEMBER removed).
enum ChosenRole {
  patient('PATIENT'),
  doctor('DOCTOR');

  const ChosenRole(this.code);
  final String code;

  static ChosenRole? fromCode(String? code) => switch (code) {
        'PATIENT' => ChosenRole.patient,
        'DOCTOR' => ChosenRole.doctor,
        _ => null,
      };
}
