/// A utility method that converts a full string into a stream of smaller text chunks,
/// emitted at specified time intervals. Helpful for simulating LLM streams.
Stream<String> streamTextInChunks(
  String text, {
  required int chunkSize,
  required Duration interval,
}) async* {
  int totalLength = text.length;
  int numChunks = (totalLength / chunkSize).ceil();

  for (int i = 0; i < numChunks; i++) {
    int start = i * chunkSize;
    int end = (start + chunkSize < totalLength) ? start + chunkSize : totalLength;
    yield text.substring(start, end);
    await Future.delayed(interval);
  }
}

/// Alias for singular naming compatibility
Stream<String> streamTextInChunk(
  String text, {
  required int chunkSize,
  required Duration interval,
}) =>
    streamTextInChunks(text, chunkSize: chunkSize, interval: interval);
