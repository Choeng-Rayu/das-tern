import 'package:das_tern/core/utils/command.dart';
import 'package:das_tern/data/models/enums.dart';
import 'package:das_tern/data/models/user.dart';
import 'package:das_tern/data/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';

class FamilyViewModel extends ChangeNotifier {
  FamilyViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository {
    load = Command0(_load);
  }

  final AuthRepository _authRepository;

  late final Command0 load;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  User? _currentUser;
  User? get currentUser => _currentUser;

  final List<User> _familyMembers = const <User>[
    User(
      id: 'fam-1',
      name: 'Sok Lina',
      email: 'lina@example.com',
      role: UserRole.familyMember,
    ),
    User(
      id: 'fam-2',
      name: 'Sok Visal',
      email: 'visal@example.com',
      role: UserRole.familyMember,
    ),
  ];
  List<User> get familyMembers => _familyMembers;

  Future<void> _load() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await _authRepository.getCurrentUser();

    _isLoading = false;
    notifyListeners();
  }
}
