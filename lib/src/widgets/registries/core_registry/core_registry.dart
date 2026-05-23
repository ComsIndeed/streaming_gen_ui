import 'package:flutter/material.dart';
import 'package:streaming_gen_ui/src/models/widget_registry.dart';

// Core imports
import 'package:streaming_gen_ui/src/widgets/core/streaming_text.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_icon.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_media.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_markdown.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_button.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_container.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_column.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_row.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_textfield.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_slider.dart';

// Core Extended imports
import 'package:streaming_gen_ui/src/widgets/core/streaming_icon_button.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_text_button.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_progression_bar.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_progression_circle.dart';
import 'package:streaming_gen_ui/src/widgets/core/streaming_stepper.dart';

// Themed Base imports
import 'package:streaming_gen_ui/src/widgets/base_themed_card.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_user_profile.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_carousel.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_weather.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_graph.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_web_result.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_product_result.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_location.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_list_results.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_todo.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_note.dart';
import 'package:streaming_gen_ui/src/widgets/base_themed_comparison.dart';

// Theme Wrapper imports
import 'package:streaming_gen_ui/src/widgets/material/streaming_material_card.dart';
import 'package:streaming_gen_ui/src/widgets/material/streaming_material_user_profile.dart';
import 'package:streaming_gen_ui/src/widgets/material/streaming_material_carousel.dart';

import 'package:streaming_gen_ui/src/widgets/fluent/streaming_fluent_card.dart';
import 'package:streaming_gen_ui/src/widgets/fluent/streaming_fluent_user_profile.dart';
import 'package:streaming_gen_ui/src/widgets/fluent/streaming_fluent_carousel.dart';

import 'package:streaming_gen_ui/src/widgets/apple/streaming_apple_card.dart';
import 'package:streaming_gen_ui/src/widgets/apple/streaming_apple_user_profile.dart';
import 'package:streaming_gen_ui/src/widgets/apple/streaming_apple_carousel.dart';

import 'package:streaming_gen_ui/src/widgets/glassmorphic/streaming_glassmorphic_card.dart';
import 'package:streaming_gen_ui/src/widgets/glassmorphic/streaming_glassmorphic_user_profile.dart';
import 'package:streaming_gen_ui/src/widgets/glassmorphic/streaming_glassmorphic_carousel.dart';

import 'package:streaming_gen_ui/src/widgets/neumorphic/streaming_neumorphic_card.dart';
import 'package:streaming_gen_ui/src/widgets/neumorphic/streaming_neumorphic_user_profile.dart';
import 'package:streaming_gen_ui/src/widgets/neumorphic/streaming_neumorphic_carousel.dart';

import 'package:streaming_gen_ui/src/widgets/skeumorphic/streaming_skeumorphic_card.dart';
import 'package:streaming_gen_ui/src/widgets/skeumorphic/streaming_skeumorphic_user_profile.dart';
import 'package:streaming_gen_ui/src/widgets/skeumorphic/streaming_skeumorphic_carousel.dart';

import 'package:streaming_gen_ui/src/widgets/brutalist/streaming_brutalist_card.dart';
import 'package:streaming_gen_ui/src/widgets/brutalist/streaming_brutalist_user_profile.dart';
import 'package:streaming_gen_ui/src/widgets/brutalist/streaming_brutalist_carousel.dart';

/// Overhauled central registry mapping namespaces to high-fidelity streaming widget implementations.
final Map<String, WidgetDefinition> coreRegistry = {
  // ==========================================
  // CORE PRIMITIVES (core:*)
  // ==========================================

  "core:text": WidgetDefinition(
    builder: (context, props) => StreamingText(
      props: props,
      builder: (context, text) => Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
      ),
    ),
    description: "Displays a dynamically streamed block of text character-by-character.",
    properties: {"content": "String"},
    jsonExample: '{"namespace":"core:text","content":"Hello from Antigravity!"}',
  ),

  "core:icon": WidgetDefinition(
    builder: (context, props) => StreamingIcon(props: props),
    description: "Displays a material icon with dynamic stream color morphs.",
    properties: {
      "icon": "String (icon name, e.g., settings, star)",
      "color": "String (optional HEX color code, e.g. #ff0055)",
      "size": "Num (optional icon size)",
    },
    jsonExample: '{"namespace":"core:icon","icon":"settings","color":"#ff0055","size":24}',
  ),

  "core:media": WidgetDefinition(
    builder: (context, props) => StreamingMedia(props: props),
    description: "Renders responsive, aspect-ratio locked network images with elegant shimmer placeholders.",
    properties: {
      "url": "String (image URL)",
      "aspectRatio": "Num (default 16/9)",
      "borderRadius": "Num (default 16.0)",
    },
    jsonExample: '{"namespace":"core:media","url":"https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800"}',
  ),

  "core:markdown": WidgetDefinition(
    builder: (context, props) => StreamingMarkdown(props: props),
    description: "Renders dynamically streamed rich markdown documentation text.",
    properties: {"content": "String (raw markdown content)"},
    jsonExample: '{"namespace":"core:markdown","content":"# Heading\\n- Bullet 1\\n- Bullet **bold item**"}',
  ),

  "core:button": WidgetDefinition(
    builder: (context, props) => StreamingButton(props: props),
    description: "A tactile, click-responsive layouts block with pressed scaling and submit actions.",
    properties: {
      "child": "Component",
      "action": "String (callback action trigger key)",
    },
    jsonExample: '{"namespace":"core:button","child":{"namespace":"core:text","content":"Save Settings"},"action":"save_settings"}',
  ),

  "core:container": WidgetDefinition(
    builder: (context, props) => StreamingContainer(props: props),
    description: "A flexible layout box wrapping dynamic children inside elegant border radius sheets.",
    properties: {
      "child": "Component",
      "width": "Num",
      "height": "Num",
      "padding": "Num",
      "borderRadius": "Num",
      "color": "String (HEX color code)",
    },
    jsonExample: '{"namespace":"core:container","padding":16,"color":"#0f172a","child":{"namespace":"core:text","content":"Inside Container"}}',
  ),

  "core:column": WidgetDefinition(
    builder: (context, props) {
      final childrenProperty = props.asMap.getListProperty("children");
      return StreamingColumn(childrenProperty: childrenProperty);
    },
    description: "A stable, self-appending vertical layout system that aggregates nested children.",
    properties: {"children": "List<Component>"},
    jsonExample: '{"namespace":"core:column","children":[{"namespace":"core:text","content":"First"},{"namespace":"core:text","content":"Second"}]}',
  ),

  "core:row": WidgetDefinition(
    builder: (context, props) {
      final childrenProperty = props.asMap.getListProperty("children");
      return StreamingRow(childrenProperty: childrenProperty);
    },
    description: "A stable, self-appending horizontal layout system that aggregates nested children.",
    properties: {"children": "List<Component>"},
    jsonExample: '{"namespace":"core:row","children":[{"namespace":"core:text","content":"Left"},{"namespace":"core:text","content":"Right"}]}',
  ),

  "core:textfield": WidgetDefinition(
    builder: (context, props) => StreamingTextField(props: props),
    description: "An interactive input field that executes actions on submit.",
    properties: {
      "placeholder": "String",
      "labelText": "String (optional)",
      "color": "String (HEX background)",
      "action": "String (callback action trigger key)",
    },
    jsonExample: '{"namespace":"core:textfield","placeholder":"Search files...","action":"search_files"}',
  ),

  "core:slider": WidgetDefinition(
    builder: (context, props) => StreamingSlider(props: props),
    description: "An anatomy-first slider input control.",
    properties: {
      "min": "Num",
      "max": "Num",
      "value": "Num",
      "label": "String",
      "action": "String (callback action trigger key)",
    },
    jsonExample: '{"namespace":"core:slider","min":0,"max":10,"value":5,"label":"Uptime Scale","action":"adjust_uptime"}',
  ),

  // ==========================================
  // CORE EXTENDED (core_extended:*)
  // ==========================================

  "core_extended:icon_button": WidgetDefinition(
    builder: (context, props) => StreamingIconButton(props: props),
    description: "A circular tactile button centered around an icon with pressed scaling.",
    properties: {
      "icon": "String",
      "size": "Num",
      "color": "String",
      "backgroundColor": "String",
      "action": "String (callback action trigger key)",
    },
    jsonExample: '{"namespace":"core_extended:icon_button","icon":"settings","action":"open_settings"}',
  ),

  "core_extended:text_button": WidgetDefinition(
    builder: (context, props) => StreamingTextButton(props: props),
    description: "A low-emphasis underline hyperlink button.",
    properties: {
      "text": "String",
      "action": "String (callback action trigger key)",
    },
    jsonExample: '{"namespace":"core_extended:text_button","text":"Learn More","action":"learn_more"}',
  ),

  "core_extended:progression_bar": WidgetDefinition(
    builder: (context, props) => StreamingProgressionBar(props: props),
    description: "A linear progress indicator that fills dynamically.",
    properties: {
      "value": "Num (0.0 to 1.0)",
      "color": "String (HEX)",
    },
    jsonExample: '{"namespace":"core_extended:progression_bar","value":0.68,"color":"#10b981"}',
  ),

  "core_extended:progression_circle": WidgetDefinition(
    builder: (context, props) => StreamingProgressionCircle(props: props),
    description: "A radial progress loop or circular tracking spinner.",
    properties: {
      "value": "Num (0.0 to 1.0)",
      "size": "Num",
      "color": "String (HEX)",
    },
    jsonExample: '{"namespace":"core_extended:progression_circle","value":0.85,"size":32}',
  ),

  "core_extended:stepper": WidgetDefinition(
    builder: (context, props) => StreamingStepper(props: props),
    description: "An interactive, vertical accordion step progression panel list.",
    properties: {
      "steps": "List<Map> (each step maps: title, description, content Component)",
    },
    jsonExample: '{"namespace":"core_extended:stepper","steps":[{"title":"Initialize Profile","description":"Setup credentials","content":{"namespace":"core:text","content":"Profile is being set up..."}}]}',
  ),

  // ==========================================
  // THEMED UI WIDGETS
  // ==========================================

  ..._generateThemeWidgets(),
};

/// Programmatically builds the 7-themed widget sets, integrating Vincent Sanicolas's info!
Map<String, WidgetDefinition> _generateThemeWidgets() {
  final Map<String, WidgetDefinition> widgets = {};
  final themes = ['material', 'fluent', 'apple', 'glassmorphic', 'neumorphic', 'skeumorphic', 'brutalist'];

  for (final theme in themes) {
    // 1. Polymorphic Card
    widgets["${theme}_ui:card"] = WidgetDefinition(
      builder: (context, props) {
        switch (theme) {
          case 'fluent': return StreamingFluentCard(props: props);
          case 'apple': return StreamingAppleCard(props: props);
          case 'glassmorphic': return StreamingGlassmorphicCard(props: props);
          case 'neumorphic': return StreamingNeumorphicCard(props: props);
          case 'skeumorphic': return StreamingSkeumorphicCard(props: props);
          case 'brutalist': return StreamingBrutalistCard(props: props);
          case 'material':
          default:
            return StreamingMaterialCard(props: props);
        }
      },
      description: "A themed high-fidelity layout card aligned to the $theme design system.",
      properties: {
        "title": "String",
        "subtitle": "String",
        "imageUrl": "String",
        "imagePosition": "String (left/right/top/bottom)",
        "statusLabel": "String",
        "statusStyle": "String (success/warning/danger/info)",
        "body": "Component",
        "themeSettings": "Map (primaryColor, backgroundColor, borderRadius)",
      },
      jsonExample: '{"namespace":"${theme}_ui:card","title":"Creative Design","subtitle":"Aesthetic presets","imagePosition":"left","imageUrl":"https://images.unsplash.com/photo-1604871000636-074fa5117945?w=800","body":{"namespace":"core:text","content":"Rich content bodies."}}',
    );

    // 2. User Profile Card (exposing Vincent Sanicolas's Developer info)
    widgets["${theme}_ui:user_profile"] = WidgetDefinition(
      builder: (context, props) {
        switch (theme) {
          case 'fluent': return StreamingFluentUserProfile(props: props);
          case 'apple': return StreamingAppleUserProfile(props: props);
          case 'glassmorphic': return StreamingGlassmorphicUserProfile(props: props);
          case 'neumorphic': return StreamingNeumorphicUserProfile(props: props);
          case 'skeumorphic': return StreamingSkeumorphicUserProfile(props: props);
          case 'brutalist': return StreamingBrutalistUserProfile(props: props);
          case 'material':
          default:
            return StreamingMaterialUserProfile(props: props);
        }
      },
      description: "A portfolio contact and developer badge card designed for the $theme ecosystem.",
      properties: {
        "name": "String",
        "role": "String",
        "website": "String",
        "avatarUrl": "String",
        "bio": "String",
        "skills": "List<String>",
        "action": "String (callback action trigger key)",
        "themeSettings": "Map",
      },
      jsonExample: '{"namespace":"${theme}_ui:user_profile","name":"Vincent Sanicolas","role":"Flutter and Web Developer","website":"https://www.vincentsanicolas.me","bio":"Design Engineer specializing in high-performance Web and Flutter Generative UI systems.","skills":["Flutter","Web Development","Generative UI","Design Systems"],"action":"contact_vincent"}',
    );

    // 3. Carousel Viewport
    widgets["${theme}_ui:carousel"] = WidgetDefinition(
      builder: (context, props) {
        switch (theme) {
          case 'fluent': return StreamingFluentCarousel(props: props);
          case 'apple': return StreamingAppleCarousel(props: props);
          case 'glassmorphic': return StreamingGlassmorphicCarousel(props: props);
          case 'neumorphic': return StreamingNeumorphicCarousel(props: props);
          case 'skeumorphic': return StreamingSkeumorphicCarousel(props: props);
          case 'brutalist': return StreamingBrutalistCarousel(props: props);
          case 'material':
          default:
            return StreamingMaterialCarousel(props: props);
        }
      },
      description: "A swipable multi-item carousel slider or 3D stacking card deck matching $theme.",
      properties: {
        "carouselType": "String (slide or stack)",
        "items": "List<Component>",
        "themeSettings": "Map",
      },
      jsonExample: '{"namespace":"${theme}_ui:carousel","carouselType":"slide","items":[{"namespace":"${theme}_ui:card","title":"Gallery Album 1","subtitle":"Photography"}]}',
    );

    // 4. Weather Card
    widgets["${theme}_ui:weather"] = WidgetDefinition(
      builder: (context, props) => BaseThemedWeatherCard(props: props, themeName: theme),
      description: "A themed weather card showing current conditions and dynamic forecasts aligned to $theme.",
      properties: {
        "temp": "Num (temperature)",
        "condition": "String (sunny, rainy, cloudy, snowy)",
        "location": "String (city)",
        "humidity": "Num",
        "windSpeed": "Num",
        "size": "String (mini/normal)",
        "forecast": "List<Map> (each maps day, temp, condition)",
        "themeSettings": "Map",
      },
      jsonExample: '{"namespace":"${theme}_ui:weather","temp":24.5,"condition":"sunny","location":"San Francisco","size":"normal","forecast":[{"day":"Mon","temp":25,"condition":"sunny"},{"day":"Tue","temp":23,"condition":"cloudy"}]}',
    );

    // 5. Graph / Chart Card
    widgets["${theme}_ui:graph"] = WidgetDefinition(
      builder: (context, props) => BaseThemedGraphCard(props: props, themeName: theme),
      description: "A themed visualization dashboard displaying line, bar, pie, and data table charts reactively aligned to $theme.",
      properties: {
        "type": "String (bar/line/pie/table)",
        "title": "String",
        "subtitle": "String",
        "labels": "List<String>",
        "values": "List<Num>",
        "headers": "List<String> (for table headers)",
        "rows": "List<List/Map> (for table rows)",
        "themeSettings": "Map",
      },
      jsonExample: '{"namespace":"${theme}_ui:graph","type":"bar","title":"Quarterly Performance","subtitle":"Real-time updates","labels":["Q1","Q2","Q3"],"values":[120,150,180]}',
    );

    // 6. Web Search Result Card
    widgets["${theme}_ui:web_result"] = WidgetDefinition(
      builder: (context, props) => BaseThemedWebResultCard(props: props, themeName: theme),
      description: "A themed search result listing showing page snippets, favicons, and site anchors matching $theme.",
      properties: {
        "title": "String",
        "url": "String",
        "snippet": "String",
        "faviconUrl": "String",
        "siteName": "String",
        "publishDate": "String",
        "action": "String",
        "themeSettings": "Map",
      },
      jsonExample: '{"namespace":"${theme}_ui:web_result","title":"Antigravity AI Assistant","url":"https://github.com/google-deepmind/antigravity","snippet":"Discover the next generation of AI pair programming and developer systems.","siteName":"GitHub","publishDate":"May 2026"}',
    );

    // 7. Product Result Card
    widgets["${theme}_ui:product_result"] = WidgetDefinition(
      builder: (context, props) => BaseThemedProductResultCard(props: props, themeName: theme),
      description: "A themed e-commerce and product result showcase aligned to $theme.",
      properties: {
        "title": "String",
        "price": "Num",
        "originalPrice": "Num",
        "rating": "Num",
        "imageUrl": "String",
        "description": "String",
        "badge": "String",
        "features": "List<String>",
        "action": "String",
        "themeSettings": "Map",
      },
      jsonExample: '{"namespace":"${theme}_ui:product_result","title":"Squircle mechanical keyboard","price":129.99,"originalPrice":149.99,"rating":4.8,"imageUrl":"https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=800","description":"Premium tactile response with custom hot-swap squircle caps.","badge":"Sale","features":["Tactile","Hot-Swap"]}',
    );

    // 8. Location Card
    widgets["${theme}_ui:location"] = WidgetDefinition(
      builder: (context, props) => BaseThemedLocationCard(props: props, themeName: theme),
      description: "A themed location, address search, and navigation card matching $theme.",
      properties: {
        "name": "String",
        "address": "String",
        "latitude": "Num",
        "longitude": "Num",
        "rating": "Num",
        "imageUrl": "String",
        "distance": "String",
        "phone": "String",
        "hours": "String",
        "action": "String",
        "themeSettings": "Map",
      },
      jsonExample: '{"namespace":"${theme}_ui:location","name":"Blue Bottle Coffee","address":"1355 Market St, San Francisco, CA","distance":"0.4 mi","rating":4.5,"hours":"7:00 AM - 6:00 PM"}',
    );

    // 9. List/File Results Card
    widgets["${theme}_ui:list_results"] = WidgetDefinition(
      builder: (context, props) => BaseThemedListResultsCard(props: props, themeName: theme),
      description: "A themed catalog of minified recent files or list tile directories matching $theme.",
      properties: {
        "title": "String",
        "items": "List<Map> (each maps title, subtitle, icon, date, size, status)",
        "action": "String",
        "themeSettings": "Map",
      },
      jsonExample: '{"namespace":"${theme}_ui:list_results","title":"Recent Designs","items":[{"title":"profile_spec.pdf","subtitle":"Design blueprint","icon":"pdf","size":"2.4 MB","date":"Today"},{"title":"squircle_hero.png","subtitle":"Asset graphic","icon":"image","size":"1.1 MB","date":"Yesterday"}]}',
    );

    // 10. Todo List Checklist Card
    widgets["${theme}_ui:todo_list"] = WidgetDefinition(
      builder: (context, props) => BaseThemedTodoCard(props: props, themeName: theme),
      description: "A themed checklist, pending todos, and reminders catalog card matching $theme.",
      properties: {
        "title": "String",
        "items": "List<Map> (each maps text, completed, dueDate, priority)",
        "action": "String",
        "themeSettings": "Map",
      },
      jsonExample: '{"namespace":"${theme}_ui:todo_list","title":"My Checklist","items":[{"text":"Finalize UI specifications","completed":true,"priority":"high"},{"text":"Write package tests","completed":false,"dueDate":"Monday"}]}',
    );

    // 11. Standalone Note/Todo/Reminder Card
    widgets["${theme}_ui:note"] = WidgetDefinition(
      builder: (context, props) => BaseThemedNoteCard(props: props, themeName: theme),
      description: "A themed standalone note, alert, or task card built for full reading layout matching $theme.",
      properties: {
        "type": "String (note/todo/reminder)",
        "title": "String",
        "content": "String",
        "completed": "Bool",
        "dueDate": "String",
        "priority": "String (high/medium/low)",
        "tags": "List<String>",
        "lastModified": "String",
        "action": "String",
        "themeSettings": "Map",
      },
      jsonExample: '{"namespace":"${theme}_ui:note","type":"note","title":"Meeting Notes","content":"Discussed the new squircle dynamic animations and glassmorphism sigmas.","tags":["design","sprint-5"],"lastModified":"2 Hours Ago"}',
    );

    // 12. Product Comparison Table Card
    widgets["${theme}_ui:comparison"] = WidgetDefinition(
      builder: (context, props) => BaseThemedComparisonCard(props: props, themeName: theme),
      description: "A themed product comparison table displaying side-by-side spec comparisons matching $theme.",
      properties: {
        "title": "String",
        "products": "List<Map> (each maps name, price, rating, specs)",
        "features": "List<String> (specs keys list to compare)",
        "action": "String",
        "themeSettings": "Map",
      },
      jsonExample: '{"namespace":"${theme}_ui:comparison","title":"Pro Keyboards","products":[{"name":"Apex Squircle","price":129,"rating":4.7,"specs":{"Switch":"Brown","Format":"75%"}},{"name":"Craft Slate","price":149,"rating":4.5,"specs":{"Switch":"Red","Format":"100%"}}],"features":["Switch","Format"]}',
    );
  }

  return widgets;
}
