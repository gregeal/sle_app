import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth/web_auth_service.dart';
import '../../providers.dart';

class WebAuthGate extends ConsumerWidget {
  const WebAuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(webAuthSessionProvider);
    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => _AuthError(
        error: error,
        onRetry: () => ref.invalidate(webAuthSessionProvider),
      ),
      data: (session) {
        if (!session.authenticated) return _SignInScreen(session: session);
        if (!session.offline) return child;
        return Column(
          children: [
            MaterialBanner(
              content: const Text(
                'Mode hors ligne : les exercices locaux restent disponibles; '
                'les fonctions IA reprendront à la reconnexion.',
              ),
              leading: const Icon(Icons.cloud_off_outlined),
              actions: [
                TextButton(
                  onPressed: () => ref.invalidate(webAuthSessionProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class _SignInScreen extends ConsumerStatefulWidget {
  const _SignInScreen({required this.session});

  final WebAuthSession session;

  @override
  ConsumerState<_SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<_SignInScreen> {
  final _emailController = TextEditingController();
  Object? _error;
  var _busy = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _passkey() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Entrez l’adresse courriel autorisée.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(webAuthServiceProvider).signInWithPasskey(email);
      ref.invalidate(webAuthSessionProvider);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 58,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SLE Prep',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ouvrez une session pour accéder à votre espace '
                      'd’apprentissage sécurisé.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    if (widget.session.passkeysEnabled) ...[
                      TextField(
                        controller: _emailController,
                        enabled: !_busy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Adresse courriel autorisée',
                        ),
                        onSubmitted: (_) => _passkey(),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _busy ? null : _passkey,
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Continuer avec une passkey'),
                      ),
                    ],
                    if (widget.session.googleEnabled) ...[
                      if (widget.session.passkeysEnabled)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('ou'),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : ref.read(webAuthServiceProvider).signInWithGoogle,
                        icon: const Icon(Icons.account_circle_outlined),
                        label: const Text('Continuer avec Google'),
                      ),
                    ],
                    if (!widget.session.googleEnabled &&
                        !widget.session.passkeysEnabled)
                      const Text(
                        'Aucune méthode de connexion n’est configurée sur ce '
                        'serveur. Consultez le guide de déploiement.',
                        textAlign: TextAlign.center,
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        '$_error',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Text(
                      'Votre progression reste dans ce navigateur. La clé '
                      'OpenAI demeure uniquement sur le serveur.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5),
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

class _AuthError extends StatelessWidget {
  const _AuthError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            const Text('Impossible de joindre le serveur sécurisé.'),
            const SizedBox(height: 6),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    ),
  );
}
