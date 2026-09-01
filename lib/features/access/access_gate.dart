import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../home/home_screen.dart';

class AccessGate extends StatefulWidget {
  const AccessGate({super.key});

  @override
  State<AccessGate> createState() => _AccessGateState();
}

class _AccessGateState extends State<AccessGate> {
  static const Color _gold = Color(0xFFE8B85A);
  static const Color _purple = Color(0xFF5B1FA3);
  static const Color _panel = Color(0xFF1A1022);

  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  late final StreamSubscription<AuthState> _authSubscription;
  Timer? _accessTimer;

  bool _loading = true;
  bool _signingIn = false;
  bool _allowed = false;
  String? _message;
  DateTime? _expiresAt;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _authSubscription = _client.auth.onAuthStateChange.listen((AuthState state) {
      if (state.event == AuthChangeEvent.signedOut) {
        _accessTimer?.cancel();
        if (mounted) {
          setState(() {
            _allowed = false;
            _loading = false;
            _expiresAt = null;
          });
        }
      }
    });
    _checkAccess();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _accessTimer?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _checkAccess({bool showLoading = true}) async {
    final Session? session = _client.auth.currentSession;
    if (session == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _allowed = false;
        });
      }
      return;
    }

    if (mounted && showLoading) {
      setState(() {
        _loading = true;
        _message = null;
      });
    }

    try {
      final dynamic result =
          await _client.rpc('check_diosa_fortuna_access');
      final Map<String, dynamic>? row = result is List && result.isNotEmpty
          ? Map<String, dynamic>.from(result.first as Map)
          : null;
      final bool allowed = row?['allowed'] == true;
      final String? expiry = row?['expires_at'] as String?;

      if (!mounted) {
        return;
      }

      setState(() {
        _allowed = allowed;
        _loading = false;
        _message = allowed
            ? null
            : (row?['reason'] as String? ??
                'No tienes una suscripción activa para este servicio.');
        _expiresAt = expiry == null ? null : DateTime.tryParse(expiry)?.toLocal();
      });

      _accessTimer?.cancel();
      if (allowed) {
        _accessTimer = Timer.periodic(
          const Duration(minutes: 15),
          (_) => _checkAccess(showLoading: false),
        );
      }
    } catch (_) {
      if (mounted) {
        if (showLoading || !_allowed) {
          setState(() {
            _allowed = false;
            _loading = false;
            _message =
                'No fue posible validar tu suscripción. Intenta nuevamente.';
          });
        }
      }
    }
  }

  Future<void> _signIn() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _message = 'Escribe tu correo y contraseña.');
      return;
    }
    setState(() {
      _signingIn = true;
      _message = null;
    });
    try {
      await _client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      await _checkAccess();
    } on AuthException catch (error) {
      if (mounted) {
        setState(() => _message = _translateAuthError(error.message));
      }
    } finally {
      if (mounted) {
        setState(() => _signingIn = false);
      }
    }
  }

  String _translateAuthError(String message) {
    final String normalized = message.toLowerCase();
    if (normalized.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (normalized.contains('email not confirmed')) {
      return 'Confirma tu correo antes de ingresar.';
    }
    return 'No fue posible iniciar sesión. Intenta nuevamente.';
  }

  Future<void> _signOut() async {
    _accessTimer?.cancel();
    FocusManager.instance.primaryFocus?.unfocus();
    TextInput.finishAutofillContext(shouldSave: false);
    _email.clear();
    _password.clear();
    await _client.auth.signOut();
    if (mounted) {
      setState(() {
        _message = null;
        _signingIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _gold)),
      );
    }

    if (_allowed) {
      return Stack(
        children: <Widget>[
          const HomeScreen(),
          Positioned(
            right: 18,
            top: 12,
            child: SafeArea(
              child: Material(
                color: _panel.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (_expiresAt != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          'Acceso hasta ${_expiresAt!.day.toString().padLeft(2, '0')}/'
                          '${_expiresAt!.month.toString().padLeft(2, '0')}/'
                          '${_expiresAt!.year}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    IconButton(
                      tooltip: 'Cerrar sesión',
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout, color: _gold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Image.asset('assets/images/oraculo_logo.png', height: 108),
                      const SizedBox(height: 18),
                      const Text(
                        'Acceso para suscriptores',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.w800,
                          fontSize: 23,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ingresa con el mismo correo y contraseña de Academia PIT.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _email,
                        autofillHints: const <String>[AutofillHints.email],
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _password,
                        autofillHints: const <String>[AutofillHints.password],
                        obscureText: true,
                        onSubmitted: (_) => _signIn(),
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      if (_message != null) ...<Widget>[
                        const SizedBox(height: 14),
                        Text(
                          _message!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.orangeAccent),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _signingIn ? null : _signIn,
                        style: FilledButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: Text(_signingIn ? 'Validando…' : 'Ingresar'),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: _client.auth.currentSession == null
                            ? null
                            : _signOut,
                        child: const Text('Usar otra cuenta'),
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
