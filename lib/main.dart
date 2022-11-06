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
              child: NewPersonForm(),
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
class NewPersonForm extends StatefulWidget {
  const NewPersonForm({super.key});

  @override
  NewPersonFormState createState() {
    return NewPersonFormState();
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class NewPersonFormState extends State<NewPersonForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<NewPersonFormState>.
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
                            saveNewPerson(username, email).then((person) {
                              _formKey.currentState!.reset();
                              // If the form is valid, display a snackbar. In the real world,
                              // you'd often call a server or save the information in a database.
                              return ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Saved $username ($email)')),
                              );
                            }).onError((error, stackTrace) =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed $error')),
                              ),
                            );
                          }
                        },
                        child: const Text('Add Person'),
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
          child: FutureBuilder<List<ParseObject>>(
            future: fetchPeople(),
            builder: (BuildContext context, AsyncSnapshot<List<ParseObject>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Text('Connecting...'),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(snapshot.error.toString()),
                );
              }
              if (snapshot.hasData) {
                return ListView.separated(
                  shrinkWrap: true,
                  // physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    final person = snapshot.data![index];
                    final name = person.get<String>('name');
                    final email = person.get<String>('email');

                    return SizedBox(
                      height: 60,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$name', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Padding(padding: EdgeInsets.only(top: 8)),
                            Text('$email'),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (BuildContext context, int index) => const Divider(),
                );
              }

              return const Center(
                child: Text('Failed to fetch data...'),
              );
            }
          ),
        ),
      );
  }
}

Future<ParseObject> saveNewPerson(String name, String email) async {
  final person = ParseObject('Person')..set('name', name)..set('email', email);
  final ParseResponse apiResponse = await person.save();

  logger.i(apiResponse.result);
  return apiResponse.result as ParseObject;
}

Future<List<ParseObject>> fetchPeople() async {
  QueryBuilder<ParseObject> queryBuilder = QueryBuilder<ParseObject>(ParseObject('Person'));
  final ParseResponse apiResponse = await queryBuilder.query();

  if (apiResponse.success && apiResponse.results != null) {
    return apiResponse.results as List<ParseObject>;
  } else {
    return [] as List<ParseObject>;
  }
}

