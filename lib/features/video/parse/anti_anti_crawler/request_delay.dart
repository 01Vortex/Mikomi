import 'dart:math';

class RequestDelay {
  const RequestDelay();

  Duration nextDelay() {
    final random = Random();
    final millis = 180 + random.nextInt(220);
    return Duration(milliseconds: millis);
  }
}
