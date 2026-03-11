import 'package:flutter/foundation.dart';

enum CommandStatus { idle, running, completed, failed }

class Command0 extends ChangeNotifier {
  Command0(this._action);

  final Future<void> Function() _action;

  CommandStatus _status = CommandStatus.idle;
  CommandStatus get status => _status;

  Object? _error;
  Object? get error => _error;

  bool get isRunning => _status == CommandStatus.running;

  Future<void> execute() async {
    _status = CommandStatus.running;
    _error = null;
    notifyListeners();

    try {
      await _action();
      _status = CommandStatus.completed;
    } catch (e) {
      _error = e;
      _status = CommandStatus.failed;
    }

    notifyListeners();
  }
}
