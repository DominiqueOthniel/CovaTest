import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);
// Pour l APK / vrai device, passer l URL Railway du backend:
// API_BASE_URL=https://TON-BACKEND.up.railway.app

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2AA86F)),
        useMaterial3: true,
      ),
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
  String? token;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token');
      loading = false;
    });
  }

  Future<void> _onLoggedIn(String nextToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', nextToken);
    setState(() => token = nextToken);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    setState(() => token = null);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (token == null) {
      return LoginPage(onLoggedIn: _onLoggedIn);
    }
    return TasksPage(token: token!, onLogout: _logout);
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLoggedIn});

  final Future<void> Function(String token) onLoggedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String? error;
  bool loading = false;

  Future<void> _login() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        await widget.onLoggedIn(body['token'] as String);
      } else {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() => error = body['message']?.toString() ?? 'Echec de connexion');
      }
    } catch (_) {
      setState(() => error = 'Impossible de joindre l API');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text('Task Manager', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Connectez-vous pour gerer vos taches'),
              const SizedBox(height: 32),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loading ? null : _login,
                child: Text(loading ? 'Connexion...' : 'Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.token, required this.onLogout});

  final String token;
  final Future<void> Function() onLogout;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final titleController = TextEditingController();
  List<dynamic> tasks = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  Future<void> _loadTasks() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/tasks'), headers: _headers);
      if (response.statusCode == 200) {
        setState(() => tasks = jsonDecode(response.body) as List<dynamic>);
      } else {
        setState(() => error = 'Impossible de charger les taches');
      }
    } catch (_) {
      setState(() => error = 'Impossible de joindre l API');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _createTask() async {
    final title = titleController.text.trim();
    if (title.isEmpty) return;
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/tasks'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'description': '',
        'status': 'TODO',
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      titleController.clear();
      await _loadTasks();
    }
  }

  Future<void> _deleteTask(int id) async {
    await http.delete(Uri.parse('$apiBaseUrl/api/tasks/$id'), headers: _headers);
    await _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes taches'),
        actions: [
          IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Nouvelle tache',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _createTask, child: const Text('Ajouter')),
              ],
            ),
            const SizedBox(height: 16),
            if (loading) const CircularProgressIndicator(),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            if (!loading)
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index] as Map<String, dynamic>;
                    return ListTile(
                      title: Text(task['title']?.toString() ?? ''),
                      subtitle: Text(task['status']?.toString() ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteTask(task['id'] as int),
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
