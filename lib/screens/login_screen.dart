import 'package:flutter/material.dart';
import 'package:marker_app/values/app_regex.dart';

import '../components/app_text_form_field.dart';
import '../utils/common_widgets/gradient_background.dart';
import '../utils/helpers/navigation_helper.dart';
import '../values/app_constants.dart';
import '../values/app_routes.dart';
import '../values/app_strings.dart';
import '../values/app_theme.dart';

import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final ValueNotifier<bool> passwordNotifier = ValueNotifier(true);
  final ValueNotifier<bool> fieldValidNotifier = ValueNotifier(false);

  late final TextEditingController emailController;
  late final TextEditingController passwordController;

  String _message = '';

  void initializeControllers() {
    emailController = TextEditingController()..addListener(controllerListener);
    passwordController = TextEditingController()
      ..addListener(controllerListener);
  }

  void disposeControllers() {
    emailController.dispose();
    passwordController.dispose();
  }

  void controllerListener() {
    final email = emailController.text;
    final password = passwordController.text;

    if (email.isEmpty && password.isEmpty) return;

    if (AppRegex.emailRegex.hasMatch(email) &&
        AppRegex.passwordRegex.hasMatch(password)) {
      fieldValidNotifier.value = true;
    } else {
      fieldValidNotifier.value = false;
    }
  }

  Future<void> signIntoApp() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text
      );

    emailController.clear();
    passwordController.clear();

    NavigationHelper.pushReplacementNamed(
    AppRoutes.mainMap,
    );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
    }

    emailController.clear();
    passwordController.clear();
  }

  void showSnackbar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ),
  );
}

  Future resetPassword(String email) async {
    if(!AppConstants.emailRegex.hasMatch(email)) {
      showSnackbar("In order to send a password reset request, a valid email must be entered!");
    } else {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        showSnackbar("Password reset link has been sent to your email.");
      } catch (e) {
        showSnackbar("An error occurred while trying to send reset link: ${e.toString()}");
      }
    }
  }

  @override
  void initState() {
    initializeControllers();
    super.initState();
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: const BoxDecoration(
                  color: Colors.black87,
                ),
            child: const Column(
              children: [
                SizedBox(height: 40),
                Text('Sign in', style: AppTheme.titleLarge),
                Text('Log in to your account', style: AppTheme.bodySmall),
                SizedBox(height: 40),
              ],
            ),
          ),
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppTextFormField(
                    controller: emailController,
                    labelText: AppStrings.email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _formKey.currentState?.validate(),
                    validator: (value) {
                      return value!.isEmpty
                          ? AppStrings.pleaseEnterEmailAddress
                          : AppConstants.emailRegex.hasMatch(value)
                              ? null
                              : AppStrings.invalidEmailAddress;
                    },
                  ),
                  ValueListenableBuilder(
                    valueListenable: passwordNotifier,
                    builder: (_, passwordObscure, __) {
                      return AppTextFormField(
                        obscureText: passwordObscure,
                        controller: passwordController,
                        labelText: AppStrings.password,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.visiblePassword,
                        onChanged: (_) => _formKey.currentState?.validate(),
                        validator: (value) {
                          return value!.isEmpty
                              ? AppStrings.pleaseEnterPassword
                              : AppConstants.passwordRegex.hasMatch(value)
                                  ? null
                                  : AppStrings.invalidPassword;
                        },
                        suffixIcon: IconButton(
                          onPressed: () =>
                              passwordNotifier.value = !passwordObscure,
                          style: IconButton.styleFrom(
                            minimumSize: const Size.square(48),
                          ),
                          icon: Icon(
                            passwordObscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                  TextButton(
                    onPressed: () {resetPassword(emailController.text);},
                    child: const Text(AppStrings.forgotPassword),
                  ),
                  const SizedBox(height: 20),
                  ValueListenableBuilder(
                    valueListenable: fieldValidNotifier,
                    builder: (_, isValid, __) {
                      return FilledButton(
                        onPressed: isValid
                            ? () {
                                signIntoApp();
                              }
                            : null,
                        child: const Text(AppStrings.login),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.doNotHaveAnAccount,
                style: AppTheme.bodySmall.copyWith(color: Colors.black),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () => NavigationHelper.pushReplacementNamed(
                  AppRoutes.register,
                ),
                child: const Text(AppStrings.register),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
