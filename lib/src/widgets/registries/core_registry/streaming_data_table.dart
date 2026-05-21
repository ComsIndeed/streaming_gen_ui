import 'package:flutter/material.dart';
import 'package:llm_json_stream/llm_json_stream.dart';
import 'package:streaming_gen_ui/src/widgets/accumulating_string_stream_builder.dart';
import 'package:streaming_gen_ui/src/widgets/registries/core_registry/streaming_entrance.dart';

class StreamingDataTable extends StatelessWidget {
  final PropertyStream props;

  const StreamingDataTable({super.key, required this.props});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapStream = props.asMap;

    final titleProp = mapStream.getStringProperty("title");
    final titleStream = titleProp.stream;
    final titleFuture = titleProp.future;

    final columnsProperty = mapStream.getListProperty("columns");
    final rowsProperty = mapStream.getListProperty("rows");


    return StreamingEntrance(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            // ignore: deprecated_member_use
            color: theme.colorScheme.outline.withOpacity(0.08),
          ),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title display
              FutureBuilder<String>(
                future: titleFuture,
                builder: (context, titleSnap) {
                  final isDone =
                      titleSnap.connectionState == ConnectionState.done &&
                      titleSnap.hasData;
                  final initialTitle = isDone ? titleSnap.data! : '';

                  return AccumulatingStringStreamBuilder(
                    stream: titleStream,
                    initialValue: initialTitle,
                    builder: (context, titleVal) {
                      if (titleVal.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          titleVal,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              // Horizontal Scrollable Data Table
              StreamBuilder<List<dynamic>>(
                stream: columnsProperty.stream,
                builder: (context, colSnap) {
                  final colsList = colSnap.data ?? const [];
                  if (colsList.isEmpty) return const SizedBox.shrink();

                  return StreamBuilder<List<dynamic>>(
                    stream: rowsProperty.stream,
                    builder: (context, rowSnap) {
                      final rowsList = rowSnap.data ?? const [];

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 24,
                          headingRowHeight: 40,
                          dataRowMinHeight: 36,
                          dataRowMaxHeight: 48,
                          headingRowColor: WidgetStateProperty.all(
                            theme.colorScheme.surfaceContainerHigh,
                          ),
                          columns: colsList.map((col) {
                            return DataColumn(
                              label: Text(
                                col.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                          rows: rowsList.map((row) {
                            final List<dynamic> cellsList = row is List<dynamic>
                                ? row
                                : const [];

                            // Map existing cells, handling null or partial values
                            final dataCells = cellsList.map((cell) {
                              return DataCell(
                                Text(
                                  cell?.toString() ?? '',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }).toList();

                            // Pad cells with empty cells to exactly match columns count (prevents DataTable assertion crashes)
                            while (dataCells.length < colsList.length) {
                              dataCells.add(const DataCell(SizedBox.shrink()));
                            }

                            // Truncate cells if there are somehow more cells than columns
                            if (dataCells.length > colsList.length) {
                              dataCells.removeRange(
                                colsList.length,
                                dataCells.length,
                              );
                            }

                            return DataRow(cells: dataCells);
                          }).toList(),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
