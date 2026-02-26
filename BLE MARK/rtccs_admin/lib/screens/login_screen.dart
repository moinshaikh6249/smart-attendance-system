import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool rememberMe = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final horizontalPadding = isTablet ? 48.0 : 16.0;
    final verticalPadding = isTablet ? 32.0 : 16.0;

    return GradientBackground(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(child: Image.asset('assets/images/logo.png', height: 100)),
                            const SizedBox(height: 16),
                            Text('Admin Login', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                            const SizedBox(height: 32),
                            TextFormField(
                              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (v) => _email = v,
                              validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                              obscureText: true,
                              onChanged: (v) => _password = v,
                              validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 chars',
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: rememberMe,
                                  onChanged: (v) => setState(() => rememberMe = v!),
                                ),
                                const Text('Remember me'),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {/* forgot password logic */},
                                  child: const Text('Forgot Password?'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (authProvider.error != null)
                              Text(authProvider.error!, style: const TextStyle(color: Colors.red)),
                            if (authProvider.isLoading)
                              const Center(child: CircularProgressIndicator()),
                            if (!authProvider.isLoading)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.login),
                                  label: const Text('Login'),
                                  onPressed: () async {
                                    if (_formKey.currentState!.validate()) {
                                      await authProvider.login(_email, _password);
                                      if (authProvider.user != null && mounted) {
                                        Navigator.of(context).pushReplacementNamed('/dashboard');
                                      }
                                    }
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 