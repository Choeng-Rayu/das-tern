import 'package:flutter_test/flutter_test.dart';
import 'package:das_tern_mcp/domain/models/user_models.dart';

void main() {
  group('CurrentUser', () {
    final json = {
      'id': 'u1',
      'firstName': 'John',
      'lastName': 'Doe',
      'email': 'john@example.com',
      'phone': '+85512345678',
      'role': 'PATIENT',
      'dateOfBirth': '1990-01-15T00:00:00.000Z',
      'gender': 'MALE',
      'profileImage': 'https://img.example.com/avatar.jpg',
    };

    test('fromJson parses all fields', () {
      final user = CurrentUser.fromJson(json);
      expect(user.id, 'u1');
      expect(user.firstName, 'John');
      expect(user.lastName, 'Doe');
      expect(user.email, 'john@example.com');
      expect(user.phone, '+85512345678');
      expect(user.role, UserRole.patient);
      expect(user.dateOfBirth, isNotNull);
      expect(user.gender, Gender.male);
      expect(user.profileImage, 'https://img.example.com/avatar.jpg');
    });

    test('fromJson handles missing optional fields', () {
      final user = CurrentUser.fromJson({
        'id': 'u2',
        'firstName': 'Jane',
        'role': 'DOCTOR',
      });
      expect(user.id, 'u2');
      expect(user.lastName, isNull);
      expect(user.email, isNull);
      expect(user.role, UserRole.doctor);
      expect(user.gender, isNull);
    });

    test('fromJson accepts phoneNumber alias', () {
      final user = CurrentUser.fromJson({
        'id': 'u3',
        'firstName': 'A',
        'role': 'PATIENT',
        'phoneNumber': '+85512345678',
      });
      expect(user.phone, '+85512345678');
    });

    test('fromJson accepts profilePictureUrl alias', () {
      final user = CurrentUser.fromJson({
        'id': 'u4',
        'firstName': 'B',
        'role': 'PATIENT',
        'profilePictureUrl': 'https://img.example.com/pic.jpg',
      });
      expect(user.profileImage, 'https://img.example.com/pic.jpg');
    });

    test('displayName combines first and last', () {
      final user = CurrentUser.fromJson(json);
      expect(user.displayName, 'John Doe');
    });

    test('displayName returns firstName when lastName is empty', () {
      final user = CurrentUser.fromJson({
        'id': 'u3',
        'firstName': 'Solo',
        'lastName': '',
        'role': 'PATIENT',
      });
      expect(user.displayName, 'Solo');
    });

    test('initials returns first letters', () {
      final user = CurrentUser.fromJson(json);
      expect(user.initials, 'JD');
    });

    test('toJson roundtrips correctly', () {
      final user = CurrentUser.fromJson(json);
      final output = user.toJson();
      expect(output['id'], 'u1');
      expect(output['firstName'], 'John');
      expect(output['role'], 'PATIENT');
      expect(output['gender'], 'MALE');
    });

    test('copyWith creates modified copy', () {
      final user = CurrentUser.fromJson(json);
      final updated = user.copyWith(firstName: 'Jane', email: 'jane@test.com');
      expect(updated.firstName, 'Jane');
      expect(updated.email, 'jane@test.com');
      expect(updated.id, 'u1'); // unchanged
      expect(updated.lastName, 'Doe'); // unchanged
    });

    test('equality works by fields', () {
      final a = CurrentUser.fromJson(json);
      final b = CurrentUser.fromJson(json);
      expect(a, equals(b));
    });
  });

  group('UserProfileUpdate', () {
    test('toJson omits null fields', () {
      const update = UserProfileUpdate(firstName: 'New', lastName: 'Name');
      final map = update.toJson();
      expect(map, {'firstName': 'New', 'lastName': 'Name'});
      expect(map.containsKey('email'), false);
      expect(map.containsKey('phone'), false);
    });

    test('isEmpty returns true when all null', () {
      const update = UserProfileUpdate();
      expect(update.isEmpty, true);
    });

    test('isEmpty returns false when any field set', () {
      const update = UserProfileUpdate(firstName: 'X');
      expect(update.isEmpty, false);
    });

    test('toJson includes dateOfBirth as ISO string', () {
      final update = UserProfileUpdate(dateOfBirth: DateTime(1990, 6, 15));
      final map = update.toJson();
      expect(map['dateOfBirth'], contains('1990-06-15'));
    });

    test('toJson includes gender value', () {
      const update = UserProfileUpdate(gender: Gender.female);
      expect(update.toJson()['gender'], 'FEMALE');
    });
  });

  group('AuthViewState', () {
    test('default state is unknown and not authenticated', () {
      const state = AuthViewState();
      expect(state.status, AuthStatus.unknown);
      expect(state.isAuthenticated, false);
      expect(state.currentUser, isNull);
    });

    test('copyWith updates fields', () {
      const state = AuthViewState();
      final updated = state.copyWith(
        status: AuthStatus.authenticated,
        currentUser: const CurrentUser(
          id: 'x',
          firstName: 'X',
          role: UserRole.patient,
        ),
      );
      expect(updated.isAuthenticated, true);
      expect(updated.currentUser?.id, 'x');
    });

    test('copyWith clearUser removes user', () {
      final state = AuthViewState(
        status: AuthStatus.authenticated,
        currentUser: const CurrentUser(
          id: 'x',
          firstName: 'X',
          role: UserRole.patient,
        ),
      );
      final cleared = state.copyWith(clearUser: true);
      expect(cleared.currentUser, isNull);
    });
  });

  group('UserRole', () {
    test('fromString parses case-insensitively', () {
      expect(UserRole.fromString('patient'), UserRole.patient);
      expect(UserRole.fromString('DOCTOR'), UserRole.doctor);
      expect(UserRole.fromString('Family'), UserRole.family);
    });

    test('fromString defaults to patient for unknown', () {
      expect(UserRole.fromString('ADMIN'), UserRole.patient);
    });
  });

  group('Gender', () {
    test('fromString parses correctly', () {
      expect(Gender.fromString('MALE'), Gender.male);
      expect(Gender.fromString('female'), Gender.female);
      expect(Gender.fromString('OTHER'), Gender.other);
    });
  });
}
