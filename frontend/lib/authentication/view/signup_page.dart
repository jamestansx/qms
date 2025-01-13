import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:qms/authentication/bloc/auth_bloc.dart';
import 'package:qms/authentication/view/login_page.dart';
import 'package:qms/core/view/option_page.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SignupPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: const SignupScreen(),
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final dateOfBirthController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    dateOfBirthController.dispose();
    super.dispose();
  }

  Widget _header() {
    return const Column(
      children: [
        Text(
          "QMS App",
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          "Create your account",
          style: TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  Widget _inputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: usernameController,
          decoration: InputDecoration(
            hintText: "Username",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            filled: true,
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: firstNameController,
          decoration: InputDecoration(
            hintText: "First name",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            filled: true,
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: lastNameController,
          decoration: InputDecoration(
            hintText: "Last name",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            filled: true,
            prefixIcon: const Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          child: TextFormField(
            controller: dateOfBirthController,
            readOnly: true,
            onTap: () async {
              final dob = await showDatePicker(
                context: context,
                firstDate: DateTime(1900),
                lastDate: DateTime(2400),
              );

              if (dob != null) {
                dateOfBirthController.text =
                    DateFormat("dd/MM/yyyy").format(dob);
              }
            },
            decoration: InputDecoration(
              hintText: "Date of birth",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              filled: true,
              prefixIcon: const Icon(Icons.calendar_month),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: passwordController,
          decoration: InputDecoration(
            hintText: "Password",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            filled: true,
            prefixIcon: const Icon(Icons.password),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 10),
        TextFormField(
          decoration: InputDecoration(
            hintText: "Confirm password",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            filled: true,
            prefixIcon: const Icon(Icons.password),
          ),
          obscureText: true,
          validator: (val) {
            if (val == null || val.isEmpty || val != passwordController.text) {
              return "Password not match!";
            }
            return null;
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _header(),
          _inputField(),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                BlocProvider.of<AuthBloc>(context).add(
                  SignupUser(
                    username: usernameController.text,
                    password: passwordController.text,
                    firstName: firstNameController.text,
                    lastName: lastNameController.text,
                    dateOfBirth: DateFormat("dd/MM/yyyy")
                        .parseUtc(dateOfBirthController.text),
                  ),
                );
              }
            },
            child: Text("Sign up", style: TextStyle(fontSize: 20)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Already have an account? "),
              GestureDetector(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    LoginPage.route(),
                    (_) => false,
                  );
                },
                child: const Text(
                  "Login",
                  style: TextStyle(color: Colors.deepPurple),
                ),
              ),
              OptionPage.widget(context),
            ],
          ),
        ],
      ),
    );
  }
}
