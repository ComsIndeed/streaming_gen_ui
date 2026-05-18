import 'package:flutter/material.dart';
import 'package:example/models/parsed_result.dart';

Color? parseHexColor(String hexString) {
  try {
    hexString = hexString.replaceAll('#', '');
    if (hexString.length == 6) {
      hexString = 'FF$hexString';
    }
    return Color(int.parse(hexString, radix: 16));
  } catch (_) {
    return null;
  }
}

ParsedResult parseText(String text) {
  int startIndex = text.indexOf('<interface>');
  String startTag = '<interface>';
  String endTag = '</interface>';

  if (startIndex == -1) {
    startIndex = text.indexOf('<interactive>');
    startTag = '<interactive>';
    endTag = '</interactive>';
  }

  if (startIndex == -1) {
    return ParsedResult(
      preText: text,
      jsonText: '',
      postText: '',
      hasInteractive: false,
      isInteractiveClosed: false,
      startTag: '<interface>',
      endTag: '</interface>',
    );
  }

  final String preText = text.substring(0, startIndex);
  final String remaining = text.substring(startIndex + startTag.length);

  final int endIndex = remaining.indexOf(endTag);
  if (endIndex == -1) {
    return ParsedResult(
      preText: preText,
      jsonText: remaining,
      postText: '',
      hasInteractive: true,
      isInteractiveClosed: false,
      startTag: startTag,
      endTag: endTag,
    );
  }

  final String jsonText = remaining.substring(0, endIndex);
  final String postText = remaining.substring(endIndex + endTag.length);

  return ParsedResult(
    preText: preText,
    jsonText: jsonText,
    postText: postText,
    hasInteractive: true,
    isInteractiveClosed: true,
    startTag: startTag,
    endTag: endTag,
  );
}

String cleanJsonString(String rawJson) {
  return rawJson.trim();
}
