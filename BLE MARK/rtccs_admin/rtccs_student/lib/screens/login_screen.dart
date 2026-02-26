import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/school_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final schoolProvider = Provider.of<SchoolProvider>(context, listen: false);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE0B2), Color(0xFFFF7043)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/logo.png', height: 80),
                      const SizedBox(height: 16),
                      Text('Student Login', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
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
                      const SizedBox(height: 24),
                      if (_loading || authProvider.isLoading)
                        const CircularProgressIndicator(),
                      if (!_loading && !authProvider.isLoading)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                setState(() { _loading = true; _error = null; });
                                await authProvider.login(_email, _password);
                                if (authProvider.user != null) {
                                  await profileProvider.fetchProfile(authProvider.user!.uid);
                                  await schoolProvider.loadSchools();
                                  if (mounted) {
                                    Navigator.of(context).pushReplacementNamed('/home');
                                  }
                                } else {
                                  setState(() { _error = authProvider.error ?? 'Login failed'; });
                                }
                                setState(() { _loading = false; });
                              }
                            },
                            child: const Text('Login'),
                          ),
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(_error!, style: const TextStyle(color: Colors.red)),
                        ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password?'),
                      ),
                    ],
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