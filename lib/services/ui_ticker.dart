import 'dart:async';

/// بسيط لإعادة البناء الدوري للـ UI
class UiTicker {
  Timer? _timer;

  /// start calling [onTick] every [interval]
  void start(
    void Function() onTick, {
    Duration interval = const Duration(seconds: 1),
  }) {
    stop();
    _timer = Timer.periodic(interval, (_) => onTick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();
}
