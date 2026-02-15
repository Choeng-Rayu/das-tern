/// Country data for Telegram-style phone input.
class Country {
  final String name;
  final String nameKm;
  final String code;
  final String dialCode;
  final String flag;
  final String exampleNumber;
  final RegExp validationPattern;

  const Country({
    required this.name,
    required this.nameKm,
    required this.code,
    required this.dialCode,
    required this.flag,
    required this.exampleNumber,
    required this.validationPattern,
  });

  String get displayDialCode => '+$dialCode';

  static final List<Country> all = [
    Country(
      name: 'Cambodia',
      nameKm: 'កម្ពុជា',
      code: 'KH',
      dialCode: '855',
      flag: '🇰🇭',
      exampleNumber: '12 345 678',
      validationPattern: RegExp(r'^\d{8,9}$'),
    ),
    Country(
      name: 'Thailand',
      nameKm: 'ថៃ',
      code: 'TH',
      dialCode: '66',
      flag: '🇹🇭',
      exampleNumber: '81 234 5678',
      validationPattern: RegExp(r'^\d{9,10}$'),
    ),
    Country(
      name: 'Vietnam',
      nameKm: 'វៀតណាម',
      code: 'VN',
      dialCode: '84',
      flag: '🇻🇳',
      exampleNumber: '91 234 56 78',
      validationPattern: RegExp(r'^\d{9,10}$'),
    ),
    Country(
      name: 'Laos',
      nameKm: 'ឡាវ',
      code: 'LA',
      dialCode: '856',
      flag: '🇱🇦',
      exampleNumber: '20 12 345 678',
      validationPattern: RegExp(r'^\d{8,10}$'),
    ),
    Country(
      name: 'Malaysia',
      nameKm: 'ម៉ាឡេស៊ី',
      code: 'MY',
      dialCode: '60',
      flag: '🇲🇾',
      exampleNumber: '12 345 6789',
      validationPattern: RegExp(r'^\d{9,10}$'),
    ),
    Country(
      name: 'United States',
      nameKm: 'សហរដ្ឋអាមេរិក',
      code: 'US',
      dialCode: '1',
      flag: '🇺🇸',
      exampleNumber: '201 555 0123',
      validationPattern: RegExp(r'^\d{10}$'),
    ),
    Country(
      name: 'United Kingdom',
      nameKm: 'ចក្រភពអង់គ្លេស',
      code: 'GB',
      dialCode: '44',
      flag: '🇬🇧',
      exampleNumber: '7911 123456',
      validationPattern: RegExp(r'^\d{10,11}$'),
    ),
    Country(
      name: 'South Korea',
      nameKm: 'កូរ៉េខាងត្បូង',
      code: 'KR',
      dialCode: '82',
      flag: '🇰🇷',
      exampleNumber: '10 1234 5678',
      validationPattern: RegExp(r'^\d{9,11}$'),
    ),
    Country(
      name: 'Japan',
      nameKm: 'ជប៉ុន',
      code: 'JP',
      dialCode: '81',
      flag: '🇯🇵',
      exampleNumber: '90 1234 5678',
      validationPattern: RegExp(r'^\d{9,11}$'),
    ),
    Country(
      name: 'China',
      nameKm: 'ចិន',
      code: 'CN',
      dialCode: '86',
      flag: '🇨🇳',
      exampleNumber: '131 2345 6789',
      validationPattern: RegExp(r'^\d{11}$'),
    ),
  ];

  /// Default country (Cambodia).
  static Country get defaultCountry => all.first;

  /// Find country by dial code (without +).
  static Country? findByDialCode(String dialCode) {
    try {
      return all.firstWhere((c) => c.dialCode == dialCode);
    } catch (_) {
      return null;
    }
  }

  /// Auto-detect country from pasted phone number starting with +.
  static Country? detectFromNumber(String number) {
    if (!number.startsWith('+')) return null;
    final digits = number.substring(1).replaceAll(RegExp(r'\D'), '');
    // Try longest dial codes first (3 digits, then 2, then 1)
    for (final len in [3, 2, 1]) {
      if (digits.length >= len) {
        final candidate = digits.substring(0, len);
        final country = findByDialCode(candidate);
        if (country != null) return country;
      }
    }
    return null;
  }
}
