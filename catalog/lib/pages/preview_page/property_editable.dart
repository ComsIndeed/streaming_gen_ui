import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:streaming_gen_ui_widget_catalog/core/models/widget_catalog_item.dart';

class PropertyEditable extends StatefulWidget {
  final WidgetCatalogItem catalogItem;
  final String propertyKey;
  final TextEditingController controller;

  const PropertyEditable({
    super.key,
    required this.catalogItem,
    required this.propertyKey,
    required this.controller,
  });

  @override
  State<PropertyEditable> createState() => _PropertyEditableState();
}

class _PropertyEditableState extends State<PropertyEditable> {
  bool _useRawJson = false;
  final Map<String, TextEditingController> _subControllers = {};
  final Set<String> _accessedKeys = {};

  Object? get decodedValue {
    try {
      return jsonDecode(widget.controller.text);
    } catch (_) {
      return widget.controller.text;
    }
  }

  void _updateValue(Object? value) {
    widget.controller.text = jsonEncode(value);
  }

  @override
  void dispose() {
    for (final controller in _subControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(PropertyEditable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.propertyKey != widget.propertyKey ||
        oldWidget.catalogItem != widget.catalogItem) {
      for (final controller in _subControllers.values) {
        controller.dispose();
      }
      _subControllers.clear();
    }
  }

  TextEditingController _getOrCreateController(String key, String initialText) {
    _accessedKeys.add(key);
    if (_subControllers.containsKey(key)) {
      final controller = _subControllers[key]!;
      if (controller.text != initialText) {
        final selection = controller.selection;
        controller.text = initialText;
        if (selection.baseOffset <= initialText.length &&
            selection.extentOffset <= initialText.length) {
          controller.selection = selection;
        }
      }
      return controller;
    } else {
      final controller = TextEditingController(text: initialText);
      _subControllers[key] = controller;
      return controller;
    }
  }

  @override
  Widget build(BuildContext context) {
    _accessedKeys.clear();
    final theme = Theme.of(context);
    final propertyDesc =
        widget.catalogItem.widgetDefinition.properties[widget.propertyKey] ??
        "";
    final value = decodedValue;

    // Detect if this is a color property
    final isColorKey = widget.propertyKey.toLowerCase().contains("color");

    final result = Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.08)),
        ),
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Toggle Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.propertyKey,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    propertyDesc,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 
                        0.7,
                      ),
                    ),
                  ),
                ],
              ),
              // Raw JSON toggle for lists / maps
              if (value is List || value is Map)
                IconButton(
                  tooltip: _useRawJson ? "Visual Form" : "Raw JSON Editor",
                  icon: Icon(
                    _useRawJson ? Icons.visibility_rounded : Icons.code_rounded,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      _useRawJson = !_useRawJson;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Render appropriate rich field
          if (_useRawJson)
            _buildRawJsonField(theme)
          else if (isColorKey)
            _buildColorSelector(value as String? ?? "#6366F1", theme)
          else if (value is bool)
            _buildSwitchToggle(value, theme)
          else if (value is num)
            _buildSlider(value, theme)
          else if (widget.propertyKey == "steps" && value is List)
            _buildStepsListBuilder(value, theme)
          else if (value is List)
            _buildGenericListBuilder(value, theme)
          else if (value is Map)
            _buildMapBuilder(Map<String, dynamic>.from(value), theme)
          else
            _buildStandardStringField(theme),
        ],
      ),
    );

    // Prune unused controllers
    final unusedKeys = _subControllers.keys
        .where((k) => !_accessedKeys.contains(k))
        .toList();
    for (final key in unusedKeys) {
      _subControllers.remove(key)?.dispose();
    }

    return result;
  }

  // --- EDITOR UI BUILDERS ---

  Widget _buildMapBuilder(Map<String, dynamic> map, ThemeData theme) {
    final hasNamespace = map.containsKey("namespace");

    if (hasNamespace) {
      // 1. Nested Child Component Form Builder!
      final namespace = map["namespace"] as String? ?? "core:text";

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "🧩 Nested: $namespace",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: ["core:text", "core:badge"].contains(namespace)
                ? namespace
                : "custom",
            decoration: InputDecoration(
              labelText: "Component Type",
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: "core:text",
                child: Text("Text (core:text)"),
              ),
              DropdownMenuItem(
                value: "core:badge",
                child: Text("Badge (core:badge)"),
              ),
              DropdownMenuItem(
                value: "custom",
                child: Text("Custom Component (JSON)"),
              ),
            ],
            onChanged: (val) {
              if (val == "core:text") {
                _updateValue({"namespace": "core:text", "content": "Hello!"});
              } else if (val == "core:badge") {
                _updateValue({
                  "namespace": "core:badge",
                  "label": "Active",
                  "style": "success",
                });
              } else {
                setState(() {
                  _useRawJson = true; // Fallback to raw JSON editor
                });
              }
            },
          ),
          const SizedBox(height: 12),
          if (namespace == "core:text") ...[
            TextField(
              decoration: InputDecoration(
                labelText: "Text Content",
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              controller: _getOrCreateController(
                "map_nested_content",
                map["content"] as String? ?? "",
              ),
              onChanged: (text) {
                map["content"] = text;
                _updateValue(map);
              },
            ),
          ] else if (namespace == "core:badge") ...[
            TextField(
              decoration: InputDecoration(
                labelText: "Label",
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              controller: _getOrCreateController(
                "map_nested_label",
                map["label"] as String? ?? "",
              ),
              onChanged: (text) {
                map["label"] = text;
                _updateValue(map);
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: map["style"] as String? ?? "neutral",
              decoration: InputDecoration(
                labelText: "Style",
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: const [
                DropdownMenuItem(value: "success", child: Text("Success")),
                DropdownMenuItem(value: "warning", child: Text("Warning")),
                DropdownMenuItem(value: "error", child: Text("Error")),
                DropdownMenuItem(value: "info", child: Text("Info")),
                DropdownMenuItem(value: "neutral", child: Text("Neutral")),
              ],
              onChanged: (val) {
                if (val != null) {
                  map["style"] = val;
                  _updateValue(map);
                }
              },
            ),
          ],
        ],
      );
    } else {
      // 2. Generic Map Dictionary Builder!
      final list = map.entries.toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...list.asMap().entries.map((entry) {
            final item = entry.value;
            final key = item.key;
            final val = item.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: "Key",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      controller: _getOrCreateController(
                        "map_key_${entry.key}",
                        key,
                      ),
                      onChanged: (newKey) {
                        if (newKey.trim().isNotEmpty && newKey != key) {
                          final newMap = <String, dynamic>{};
                          for (final e in map.entries) {
                            if (e.key == key) {
                              newMap[newKey] = e.value;
                            } else {
                              newMap[e.key] = e.value;
                            }
                          }
                          _updateValue(newMap);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: "Value",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      controller: _getOrCreateController(
                        "map_val_${entry.key}",
                        val.toString(),
                      ),
                      onChanged: (newVal) {
                        map[key] = newVal;
                        _updateValue(map);
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: () {
                      map.remove(key);
                      _updateValue(map);
                    },
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: const Text("Add Property"),
              onPressed: () {
                map["new_key_${map.length}"] = "";
                _updateValue(map);
              },
            ),
          ),
        ],
      );
    }
  }

  Widget _buildRawJsonField(ThemeData theme) {
    return TextField(
      controller: widget.controller,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Widget _buildColorSelector(String currentColor, ThemeData theme) {
    final swatches = const [
      "#6366F1", // Indigo
      "#8B5CF6", // Purple
      "#EC4899", // Pink
      "#EF4444", // Red
      "#10B981", // Emerald
      "#F59E0B", // Amber
      "#0F172A", // Dark Slate
      "#FFFFFF", // White
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: swatches.map((hex) {
            final isSelected = currentColor.toLowerCase() == hex.toLowerCase();
            final isWhite = hex == "#FFFFFF";
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () => _updateValue(hex),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Color(int.parse(hex.replaceFirst('#', '0xff'))),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : isWhite
                          ? theme.colorScheme.outline.withValues(alpha: 0.2)
                          : Colors.transparent,
                      width: isSelected ? 3.0 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: isWhite ? Colors.black : Colors.white,
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.palette_rounded, size: 16),
            hintText: "#HEX Color",
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          onChanged: (text) {
            // Keep text controller as raw text if custom input is type written
          },
        ),
      ],
    );
  }

  Widget _buildSwitchToggle(bool val, ThemeData theme) {
    return SwitchListTile(
      value: val,
      title: const Text("Enable Mode", style: TextStyle(fontSize: 14)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onChanged: (newVal) => _updateValue(newVal),
    );
  }

  Widget _buildSlider(num val, ThemeData theme) {
    double min = 0.0;
    double max = 100.0;
    int divisions = 10;

    final key = widget.propertyKey.toLowerCase();
    if (key.contains("radius")) {
      max = 32.0;
      divisions = 32;
    } else if (key.contains("height")) {
      min = 50.0;
      max = 500.0;
      divisions = 45;
    } else if (key.contains("width")) {
      min = 50.0;
      max = 500.0;
      divisions = 45;
    } else if (key.contains("gap")) {
      max = 40.0;
      divisions = 20;
    }

    final double clampedVal = val.toDouble().clamp(min, max);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              clampedVal.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 18,
                  ),
                  onPressed: () {
                    final newVal = (clampedVal - (max - min) / divisions).clamp(
                      min,
                      max,
                    );
                    _updateValue(newVal);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  onPressed: () {
                    final newVal = (clampedVal + (max - min) / divisions).clamp(
                      min,
                      max,
                    );
                    _updateValue(newVal);
                  },
                ),
              ],
            ),
          ],
        ),
        Slider(
          value: clampedVal,
          min: min,
          max: max,
          divisions: divisions,
          label: clampedVal.toStringAsFixed(1),
          onChanged: (newVal) => _updateValue(newVal),
        ),
      ],
    );
  }

  Widget _buildStandardStringField(ThemeData theme) {
    // Check if raw value is stored as JSON string or raw text
    String displayText = widget.controller.text;
    try {
      final decoded = jsonDecode(widget.controller.text);
      if (decoded is String) displayText = decoded;
    } catch (_) {}

    return TextField(
      decoration: InputDecoration(
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      controller: _getOrCreateController("standard_string", displayText),
      onChanged: (text) => _updateValue(text),
    );
  }

  // --- SPECIALIZED LIST STEP Timeline BUILDER (Agent Stepper) ---

  Widget _buildStepsListBuilder(List steps, ThemeData theme) {
    final List<Map<String, dynamic>> stepsList = steps
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...stepsList.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;

          final title = step["title"] as String? ?? "";
          final status = step["status"] as String? ?? "pending";
          final duration = step["duration"] as String? ?? "";

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: "Step Title",
                            border: InputBorder.none,
                          ),
                          controller: _getOrCreateController(
                            "step_title_$index",
                            title,
                          ),
                          onChanged: (val) {
                            stepsList[index]["title"] = val;
                            _updateValue(stepsList);
                          },
                        ),
                        Row(
                          children: [
                            DropdownButton<String>(
                              value: status,
                              isDense: true,
                              items: const [
                                DropdownMenuItem(
                                  value: "completed",
                                  child: Text("Completed"),
                                ),
                                DropdownMenuItem(
                                  value: "running",
                                  child: Text("Running"),
                                ),
                                DropdownMenuItem(
                                  value: "failed",
                                  child: Text("Failed"),
                                ),
                                DropdownMenuItem(
                                  value: "pending",
                                  child: Text("Pending"),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  stepsList[index]["status"] = val;
                                  _updateValue(stepsList);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: "Duration (e.g. 140ms)",
                                  border: InputBorder.none,
                                ),
                                controller: _getOrCreateController(
                                  "step_duration_$index",
                                  duration,
                                ),
                                onChanged: (val) {
                                  stepsList[index]["duration"] = val;
                                  _updateValue(stepsList);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: () {
                      stepsList.removeAt(index);
                      _updateValue(stepsList);
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Center(
          child: FilledButton.icon(
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text("Add Timeline Step"),
            onPressed: () {
              stepsList.add({
                "title": "New step",
                "status": "pending",
                "duration": "",
              });
              _updateValue(stepsList);
            },
          ),
        ),
      ],
    );
  }

  // --- DYNAMIC STRING ARRAY BUILDER ---

  Widget _buildGenericListBuilder(List list, ThemeData theme) {
    final List<String> stringList = list.map((e) => e.toString()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...stringList.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    controller: _getOrCreateController("list_$index", item),
                    onChanged: (val) {
                      stringList[index] = val;
                      _updateValue(stringList);
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: () {
                    stringList.removeAt(index);
                    _updateValue(stringList);
                  },
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
            label: const Text("Add Item"),
            onPressed: () {
              stringList.add("New item");
              _updateValue(stringList);
            },
          ),
        ),
      ],
    );
  }
}
