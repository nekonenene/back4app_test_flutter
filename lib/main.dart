import 'package:flutter/material.dart';

import 'package:email_validator/email_validator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logger/logger.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

var logger = Logger();

void main() async {
  await dotenv.load(fileName: '.env');
  logger.d('BACK4APP_APPLICATION_ID: ${dotenv.env['BACK4APP_APPLICATION_ID']}');

  final applicationId = dotenv.env['BACK4APP_APPLICATION_ID'];
  final clientKey = dotenv.env['BACK4APP_CLIENT_KEY'];
  const parseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(applicationId!, parseServerUrl, clientKey: clientKey, autoSendSessionId: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appTitle = 'People';

    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(appTitle),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Expanded(
              flex: 3,
              child: MyCustomForm(),
            ),
            Expanded(
              flex: 2,
              child: PeopleList(),
            ),
          ],
        ),
      ),
    );
  }
}

// Create a Form widget.
class MyCustomForm extends StatefulWidget {
  const MyCustomForm({super.key});

  @override
  MyCustomFormState createState() {
    return MyCustomFormState();
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class MyCustomFormState extends State<MyCustomForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  String username = '';
  String email = '';

  @override
  Widget build(BuildContext context) {
    return
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Username',
                      ),
                      onChanged: (value) {
                        username = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter username';
                        }
                        return null;
                      },
                    ),
                    const Padding(
                        padding: EdgeInsets.only(top: 12)
                    ),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                      onChanged: (value) {
                        email = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter email';
                        }
                        if (!EmailValidator.validate(value)) {
                          return 'Please input valid email';
                        }
                        return null;
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: ElevatedButton(
                        onPressed: () {
                          // Validate returns true if the form is valid, or false otherwise.
                          if (_formKey.currentState!.validate()) {
                            // If the form is valid, display a snackbar. In the real world,
                            // you'd often call a server or save the information in a database.
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Hello, $username!!\nYour email is $email')),
                            );
                          }
                        },
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }
}

// Create a Form widget.
class PeopleList extends StatefulWidget {
  const PeopleList({super.key});

  @override
  PeopleListState createState() {
    return PeopleListState();
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class PeopleListState extends State<PeopleList> {
  final List<String> entries = <String>['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];

  @override
  Widget build(BuildContext context) {
    return
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Scrollbar(
          child: ListView.separated(
            shrinkWrap: true,
            // physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
            itemCount: entries.length,
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                height: 40,
                child: Center(child: Text('Entry ${entries[index]}')),
              );
            },
            separatorBuilder: (BuildContext context, int index) => const Divider(),
          ),
        ),
      );
  }
}
