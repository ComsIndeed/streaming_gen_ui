import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

/// Fetches and parses organic search snippets from DuckDuckGo HTML.
///
/// Fetches search results directly using `html.duckduckgo.com` (which requires
/// zero API keys, setup, or JavaScript execution) and parses standard organic
/// results. Sponsors and ads are explicitly excluded to keep the context dense and clean.
Future<String> fetchDuckDuckGoSearch(String query, {int maxResults = 3}) async {
  final url = Uri.parse('https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}');

  try {
    final response = await http.get(url, headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    }).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      return '<system_results><Search error="Failed to fetch search results (Status Code ${response.statusCode})" /></system_results>';
    }

    final document = html_parser.parse(response.body);
    final resultElements = document.getElementsByClassName('result__body');
    final buffer = StringBuffer();

    int count = 0;
    for (final element in resultElements) {
      if (count >= maxResults) break;

      // Filter out Microsoft Bing / DDG sponsored ads
      final isAd = element.parent?.classes.contains('result--ad') ?? false;
      if (isAd) continue;

      final titleElement = element.querySelector('.result__a');
      final snippetElement = element.querySelector('.result__snippet');

      final title = titleElement?.text.trim() ?? '';
      final snippet = snippetElement?.text.trim() ?? '';

      // Resolve URL from relative redirect if needed, or get the link href
      var urlStr = '';
      if (titleElement != null) {
        final href = titleElement.attributes['href'] ?? '';
        if (href.isNotEmpty) {
          if (href.startsWith('//')) {
            urlStr = 'https:$href';
          } else if (href.startsWith('/')) {
            urlStr = 'https://duckduckgo.com$href';
          } else {
            urlStr = href;
          }
        }
      }

      if (title.isNotEmpty && snippet.isNotEmpty) {
        buffer.writeln('  <Ui.WebResult title="$title" url="$urlStr" snippet="$snippet" />');
        count++;
      }
    }

    if (buffer.isEmpty) {
      return '<system_results>\n  <Search error="No results found." />\n</system_results>';
    }

    return '<system_results>\n$buffer</system_results>';
  } catch (e) {
    return '<system_results>\n  <Search error="Exception occurred during search: $e" />\n</system_results>';
  }
}
