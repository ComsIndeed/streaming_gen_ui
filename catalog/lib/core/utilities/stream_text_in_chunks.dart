import 'package:flutter/foundation.dart';

enum StreamingMode { streaming, noWidgetStreaming, noStreaming }

final currentStreamingMode = ValueNotifier<StreamingMode>(
  StreamingMode.streaming,
);
final showDevOptionsNotifier = ValueNotifier<bool>(false);
Stream<String> transformNoWidgetStreaming(Stream<String> source) async* {
  final buffer = StringBuffer();
  bool insideTag = false;
  int yieldedIndex = 0;
  int tagStartIndex = -1;

  await for (final chunk in source) {
    buffer.write(chunk);

    while (true) {
      final currentStr = buffer.toString();

      if (!insideTag) {
        // Look for "<interface" starting from yieldedIndex
        final idx = currentStr.indexOf('<interface', yieldedIndex);
        if (idx != -1) {
          // Found the start of a tag!
          // 1. Yield any text before the tag
          if (idx > yieldedIndex) {
            yield currentStr.substring(yieldedIndex, idx);
          }
          // 2. Transition state
          insideTag = true;
          tagStartIndex = idx;
          yieldedIndex = idx;
        } else {
          // No "<interface" found.
          // Check for a partial prefix of "<interface" at the end of the string
          int partialLen = 0;
          final searchStr = "<interface";
          for (int len = searchStr.length - 1; len > 0; len--) {
            final prefix = searchStr.substring(0, len);
            if (currentStr.endsWith(prefix)) {
              partialLen = len;
              break;
            }
          }

          final safeEnd = currentStr.length - partialLen;
          if (safeEnd > yieldedIndex) {
            yield currentStr.substring(yieldedIndex, safeEnd);
            yieldedIndex = safeEnd;
          }
          break; // Need more chunks
        }
      } else {
        // We are inside the tag, look for "</interface>" starting from tagStartIndex
        final idx = currentStr.indexOf('</interface>', tagStartIndex);
        if (idx != -1) {
          final endIdx = idx + '</interface>'.length;
          // Yield the entire tag block as a single chunk!
          yield currentStr.substring(tagStartIndex, endIdx);

          // Transition state
          insideTag = false;
          tagStartIndex = -1;
          yieldedIndex = endIdx;
          // Continue loop to process any text/tags after this one
        } else {
          // Tag is not closed yet, buffer and wait for more chunks
          break;
        }
      }
    }
  }

  // After stream finishes, if there is anything left unyielded (e.g. unclosed tag or trailing text), yield it
  final remaining = buffer.toString();
  if (yieldedIndex < remaining.length) {
    yield remaining.substring(yieldedIndex);
  }
}

Stream<String> transformNoStreaming(Stream<String> source) async* {
  final buffer = StringBuffer();
  await for (final chunk in source) {
    buffer.write(chunk);
  }
  if (buffer.isNotEmpty) {
    yield buffer.toString();
  }
}

/// Utility function to stream text in chunks with configurable timing.
///
/// This is useful for testing the parser with simulated streaming data
/// or for processing large text files in chunks.
///
/// ## Parameters
///
/// - [text] - The complete text to stream
/// - [chunkSize] - Number of characters per chunk
/// - [interval] - Delay between emitting chunks
///
/// ## Example
///
/// ```dart
/// final stream = streamTextInChunks(
///   text: '{"name": "John", "age": 30}',
///   chunkSize: 5,
///   interval: Duration(milliseconds: 50),
/// );
///
/// final parser = JsonStreamParser(stream);
/// final name = await parser.getStringProperty('name').future;
/// print(name); // "John"
/// ```
Stream<String> streamTextInChunks({
  required String text,
  required int chunkSize,
  required Duration interval,
  int chunkSizeImmediatelyEmit = 0,
  bool emitImmediately = true,
}) async* {
  if (emitImmediately == false) await Future.delayed(interval);

  yield text.substring(0, chunkSizeImmediatelyEmit);
  text = text.substring(chunkSizeImmediatelyEmit);

  // Calculate the number of chunks we'll need.
  int totalLength = text.length;
  int numChunks = (totalLength / chunkSize).ceil();

  // Loop through each chunk index.
  for (int i = 0; i < numChunks; i++) {
    // Determine the start and end indices for the current chunk.
    int start = i * chunkSize;
    // The end is either the next chunk's start or the total length,
    // whichever comes first (to handle the final, possibly smaller chunk).
    int end = (start + chunkSize < totalLength)
        ? start + chunkSize
        : totalLength;

    // Get the substring for the current chunk.
    String chunk = text.substring(start, end);

    // 'yield' is the magic word for async* functions. It adds the value
    // to the stream and pauses until the next iteration.
    yield chunk;

    // Wait for the specified interval before yielding the next chunk.
    // This is what makes it "stream" over time.
    await Future.delayed(interval);
  }
}
