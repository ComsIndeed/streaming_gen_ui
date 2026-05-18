class ExampleData {
  final String name;
  final String shortName;
  final String content;

  ExampleData({
    required this.name,
    required this.shortName,
    required this.content,
  });
}

// --- DATASETS (TEST EXAMPLES WITH XML + SPEC COMPLIANT JSON) ---

final List<ExampleData> mockExamples = [
  ExampleData(
    name: '🏨 Paris Hotel Recommendations',
    shortName: 'HOTELS_SCHEMA',
    content: exampleHotels,
  ),
  ExampleData(
    name: '👤 Vincent\'s Profile Card',
    shortName: 'PROFILE_SCHEMA',
    content: exampleProfile,
  ),
  ExampleData(
    name: '✈️ Airline Boarding Pass',
    shortName: 'BOARDING_PASS_SCHEMA',
    content: exampleInvoice,
  ),
];

const String exampleHotels = '''
Here are some excellent hotel recommendations for your stay in Paris, curated just for you:

<interface>
{
  "namespace": "core:column",
  "children": [
    {
      "namespace": "core:container",
      "padding": "12",
      "decoration": {
        "color": "#F1F5F9",
        "borderRadius": "8",
        "border": {
          "color": "#3B82F6",
          "width": "1"
        }
      },
      "child": {
        "namespace": "core:column",
        "children": [
          {
            "namespace": "core:text",
            "text": "🏨 Hotel Plaza Athénée",
            "style": {
              "fontWeight": "bold",
              "fontSize": "16",
              "color": "#1E3A8A"
            }
          },
          {
            "namespace": "core:container",
            "height": "4"
          },
          {
            "namespace": "core:text",
            "text": "Luxury hotel near Champs-Élysées with stunning views of the Eiffel Tower. Rating: 4.9/5",
            "style": {
              "fontSize": "12",
              "color": "#475569"
            }
          }
        ]
      }
    },
    {
      "namespace": "core:container",
      "height": "8"
    },
    {
      "namespace": "core:container",
      "padding": "12",
      "decoration": {
        "color": "#F1F5F9",
        "borderRadius": "8",
        "border": {
          "color": "#3B82F6",
          "width": "1"
        }
      },
      "child": {
        "namespace": "core:column",
        "children": [
          {
            "namespace": "core:text",
            "text": "🏨 Le Bristol Paris",
            "style": {
              "fontWeight": "bold",
              "fontSize": "16",
              "color": "#1E3A8A"
            }
          },
          {
            "namespace": "core:container",
            "height": "4"
          },
          {
            "namespace": "core:text",
            "text": "A historic palace hotel featuring a beautiful rooftop pool and 3-star Michelin dining. Rating: 4.8/5",
            "style": {
              "fontSize": "12",
              "color": "#475569"
            }
          }
        ]
      }
    },
    {
      "namespace": "core:container",
      "height": "12"
    },
    {
      "namespace": "core:elevated_button",
      "child": {
        "namespace": "core:text",
        "text": "Book Now • Explore Paris"
      }
    }
  ]
}
</interface>

I hope these recommendations help you plan an unforgettable trip to Paris. Please let me know if you would like to filter by specific price ranges or search for other locations!
''';

const String exampleProfile = '''
Here is the user profile schema loaded from the secure production database:

<interface>
{
  "namespace": "core:container",
  "padding": "16",
  "decoration": {
    "color": "#F8FAFC",
    "borderRadius": "12",
    "border": {
      "color": "#64748B",
      "width": "1.5"
    }
  },
  "child": {
    "namespace": "core:column",
    "children": [
      {
        "namespace": "core:row",
        "children": [
          {
            "namespace": "core:text",
            "text": "👤 Vincent Sanicolas",
            "style": {
              "fontWeight": "bold",
              "fontSize": "18",
              "color": "#0F172A"
            }
          }
        ]
      },
      {
        "namespace": "core:text",
        "text": "Senior Flutter Developer & Web Architect",
        "style": {
          "fontSize": "12",
          "fontStyle": "italic",
          "color": "#475569"
        }
      },
      {
        "namespace": "core:container",
        "height": "8"
      },
      {
        "namespace": "core:row",
        "children": [
          {
            "namespace": "core:container",
            "padding": "6",
            "decoration": {
              "color": "#E0F2FE",
              "borderRadius": "4"
            },
            "child": {
              "namespace": "core:text",
              "text": "Tags: Flutter • Dart • Web",
              "style": {
                "fontSize": "10",
                "color": "#0369A1"
              }
            }
          }
        ]
      },
      {
        "namespace": "core:container",
        "height": "12"
      },
      {
        "namespace": "core:row",
        "children": [
          {
            "namespace": "core:elevated_button",
            "child": {
              "namespace": "core:text",
              "text": "Contact Author"
            }
          }
        ]
      }
    ]
  }
}
</interface>

I have confirmed this profile has active read/write permissions. Let me know if you would like me to render another profile card or query the DB.
''';

const String exampleInvoice = '''
Here is your airline invoice and electronic boarding pass information:

<interface>
{
  "namespace": "core:column",
  "children": [
    {
      "namespace": "core:text",
      "text": "✈️ Flight Booking Confirmed",
      "style": {
        "fontWeight": "bold",
        "fontSize": "16",
        "color": "#15803D"
      }
    },
    {
      "namespace": "core:container",
      "height": "8"
    },
    {
      "namespace": "core:container",
      "padding": "10",
      "decoration": {
        "color": "#F0FDF4",
        "borderRadius": "6",
        "border": {
          "color": "#86EFAC",
          "width": "1"
        }
      },
      "child": {
        "namespace": "core:text",
        "text": "Reservation Reference: #AG-255463",
        "style": {
          "fontWeight": "bold",
          "fontSize": "11",
          "color": "#166534"
        }
      }
    },
    {
      "namespace": "core:container",
      "height": "12"
    },
    {
      "namespace": "core:row",
      "children": [
        {
          "namespace": "core:text",
          "text": "Depart: MNL ➔ Arrive: CDG",
          "style": {
            "fontSize": "13",
            "fontWeight": "bold",
            "color": "#1E293B"
          }
        }
      ]
    },
    {
      "namespace": "core:container",
      "height": "4"
    },
    {
      "namespace": "core:text",
      "text": "Gate: A12 | Boarding: 21:50 | Seat: 12B",
      "style": {
        "fontSize": "11",
        "color": "#475569"
      }
    },
    {
      "namespace": "core:container",
      "height": "12"
    },
    {
      "namespace": "core:elevated_button",
      "child": {
        "namespace": "core:text",
        "text": "Download Boarding Pass"
      }
    }
  ]
}
</interface>

Your ticket has been sent to your registered email address. Have a wonderful and safe flight with us!
''';
