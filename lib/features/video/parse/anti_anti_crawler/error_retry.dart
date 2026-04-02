class ErrorRetry {
  final int maxRetryCount;

  const ErrorRetry({this.maxRetryCount = 2});

  bool shouldRetry(int currentRetry) {
    return currentRetry < maxRetryCount;
  }
}
