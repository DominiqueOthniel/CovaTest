import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/api_client.dart';
import 'pages/auth_page.dart';
import 'pages/tasks_page.dart';
import 'theme/cova_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CovaTask',
      debugShowCheckedModeBanner: false,
      theme: buildCovaTheme(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthSession? _session;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final email = prefs.getString('email');
    final fullName = prefs.getString('fullName');
    setState(() {
      if (token != null && email != null && fullName != null) {
        _session = AuthSession(token: token, email: email, fullName: fullName);
      }
      _loading = false;
    });
  }

  Future<void> _onLoggedIn(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', session.token);
    await prefs.setString('email', session.email);
    await prefs.setString('fullName', session.fullName);
    setState(() => _session = session);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('email');
    await prefs.remove('fullName');
    setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: CovaColors.accent),
        ),
      );
    }
    if (_session == null) {
      return AuthPage(onLoggedIn: _onLoggedIn);
    }
    return TasksPage(session: _session!, onLogout: _logout);
  }
}
