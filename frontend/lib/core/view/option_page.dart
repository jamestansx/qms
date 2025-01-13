import 'package:flutter/material.dart';
import 'package:qms/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OptionPage extends StatefulWidget {
  const OptionPage({super.key});

  static Widget widget(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            OptionPage.route(),
          );
        },
        child: const Text(
          "Settings",
          style: TextStyle(color: Colors.deepPurple),
        ),
      ),
    );
  }

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => OptionPage());
  }

  @override
  State<OptionPage> createState() => _OptionPageState();
}

class _OptionPageState extends State<OptionPage> {
  final _formKey = GlobalKey<FormState>();
  final inputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: inputController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final prefs = SharedPreferencesAsync();
                      await prefs.setString("BASEURL", inputController.text);
                      final apiUrl = await prefs.getString("BASEURL") ?? baseUrl;
                      baseUrl = "http://$apiUrl:8000/api/v1";
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
