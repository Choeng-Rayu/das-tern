import 'package:flutter/foundation.dart';

enum CommandStatus { idle, running, completed, failed }

/// A command that wraps an async action with no arguments.
class Command0 extends ChangeNotifier {
  Command0(this._action);

  final Future<void> Function() _action;

  CommandStatus _status = CommandStatus.idle;
  CommandStatus get status => _status;

  Object? _error;
  Object? get error => _error;

  bool get isRunning => _status == CommandStatus.running;
  bool get isCompleted => _status == CommandStatus.completed;
  bool get isFailed => _status == CommandStatus.failed;

  Future<void> execute() async {
    if (_status == CommandStatus.running) return;

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

/// A command that wraps an async action with one argument.
class Command1<R, A> extends ChangeNotifier {
  Command1(this._action);

  final Future<R> Function(A) _action;

  CommandStatus _status = CommandStatus.idle;
  CommandStatus get status => _status;

  Object? _error;
  Object? get error => _error;

  R? _result;
  R? get result => _result;

  bool get isRunning => _status == CommandStatus.running;
  bool get isCompleted => _status == CommandStatus.completed;
  bool get isFailed => _status == CommandStatus.failed;

  Future<void> execute(A argument) async {
    if (_status == CommandStatus.running) return;

    _status = CommandStatus.running;
    _error = null;
    notifyListeners();

    try {
      _result = await _action(argument);
      _status = CommandStatus.completed;
    } catch (e) {
      _error = e;
      _status = CommandStatus.failed;
    }

    notifyListeners();
  }
}
