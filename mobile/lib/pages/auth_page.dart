import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme/cova_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/brand_logo.dart';
import '../widgets/cova_panel.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, required this.onLoggedIn});

  final Future<void> Function(AuthSession session) onLoggedIn;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _api = ApiClient();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registerMode = false;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final session = _registerMode
          ? await _api.register(
              _fullName.text.trim(),
              _email.text.trim(),
              _password.text,
            )
          : await _api.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _registerMode ? 'Compte cree avec succes' : 'Connexion reussie',
          ),
          backgroundColor: CovaColors.accentStrong,
        ),
      );
      await widget.onLoggedIn(session);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: CovaColors.danger),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de joindre l API'),
          backgroundColor: CovaColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CovaPanel(
                      glow: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: CovaColors.soft,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: CovaColors.line),
                                ),
                                child: const BrandLogo(height: 34),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'COVATASK',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Organisez vos taches, web et mobile, au meme rythme.',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    CovaPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _registerMode ? 'Creer un compte' : 'Connexion',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 22),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _registerMode
                                ? 'Inscrivez-vous pour demarrer sur CovaTask.'
                                : 'Accedez a votre liste de taches CovaTask.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 22),
                          if (_registerMode) ...[
                            TextField(
                              controller: _fullName,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Nom complet',
                                hintText: 'votre nom',
                                prefixIcon: Icon(Icons.person_outline, color: CovaColors.muted),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'yourname@exemple.com',
                              prefixIcon: Icon(Icons.mail_outline, color: CovaColors.muted),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _password,
                            obscureText: _obscure,
                            onSubmitted: (_) => _loading ? null : _submit(),
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              hintText: 'Minimum 6 caracteres',
                              prefixIcon: const Icon(Icons.lock_outline, color: CovaColors.muted),
                              suffixIcon: IconButton(
                                onPressed: () => setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: CovaColors.muted,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: CovaColors.accentInk,
                                    ),
                                  )
                                : Text(
                                    _registerMode ? "S'inscrire" : 'Se connecter',
                                  ),
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  _registerMode
                                      ? 'Deja inscrit ? '
                                      : 'Pas encore de compte ? ',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                GestureDetector(
                                  onTap: _loading
                                      ? null
                                      : () => setState(() => _registerMode = !_registerMode),
                                  child: Text(
                                    _registerMode ? 'Se connecter' : 'Creer un compte',
                                    style: const TextStyle(
                                      color: CovaColors.accent,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
