import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final List<String> roles = ['Student', 'Mentor', 'Educator'];
  final List<MaterialColor> colors = [Colors.blue, Colors.green, Colors.orange];
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roles List',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Roles List'),
          backgroundColor: Colors.teal,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Tap on a role to see a message!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: roles.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: colors[index % colors.length].shade200,
                    child: ListTile(
                      leading: Icon(Icons.person, color: colors[index % colors.length]),
                      title: Text(
                        roles[index],
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('Role Selected'),
                              content: Text('You tapped on ${roles[index]}!'),
                              actions: [
                                TextButton(
                                  child: Text('OK'),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      
    );
  }
}
