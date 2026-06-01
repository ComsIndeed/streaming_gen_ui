import 'package:flutter/material.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            height: double.infinity,
            width: 720,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemBuilder: (_, _) => const Text("Hello World"),
                    itemCount: 50,
                  ),
                ),
                TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    suffix: IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.arrow_upward),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: Center(child: Text("Hello world"))),
        ],
      ),
    );
  }
}
