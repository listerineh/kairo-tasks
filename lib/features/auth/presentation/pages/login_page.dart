import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_motion.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/widgets/kairo_button.dart';
import '../../../../core/widgets/kairo_entrance.dart';
import '../../../../core/widgets/kairo_segmented_control.dart';
import '../../../dashboard/domain/mascot/mascot_mood.dart';
import '../../../dashboard/presentation/widgets/mascot/mascot_behavior.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/login_hero.dart';

/// Sign in or create an account (docs/design.md § Login and onboarding).
///
/// An `ink` hero with Kairo and drifting task chips sits above a white
/// form card. Kairo follows the form: he glances over when a field gets
/// focus, closes his eyes while you type a hidden password, concentrates
/// while signing in, looks sad (and the card shakes) on an error, and hops
/// when you get in. The hero shrinks while the keyboard is up.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.now, this.drift});

  /// Fixed in goldens: the greeting's time and the chips' drift phase.
  final DateTime? now;
  final double? drift;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _passwordFocus = FocusNode();
  final _focusScope = FocusScopeNode();

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  bool _showPassword = false;
  bool _signUp = false;
  bool _typing = false;
  bool _sad = false;
  int _hops = 0;
  int _cues = 0;
  MascotBehavior? _cue;
  Timer? _sadTimer;

  @override
  void initState() {
    super.initState();
    _focusScope.addListener(_onFocusChanged);
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _sadTimer?.cancel();
    _shake.dispose();
    _email.dispose();
    _password.dispose();
    _name.dispose();
    _username.dispose();
    _passwordFocus.dispose();
    _focusScope.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    final typing = _focusScope.hasFocus;
    if (typing && !_typing) _glance();
    if (typing != _typing) setState(() => _typing = typing);
  }

  void _glance() => setState(() {
    _cue = MascotBehavior.look;
    _cues++;
  });

  void _submit() {
    final email = _email.text.trim();
    final password = _password.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _fail();
      return;
    }
    FocusScope.of(context).unfocus();
    final bloc = context.read<AuthBloc>();
    if (_signUp) {
      final name = _name.text.trim();
      final username = _username.text.trim().toLowerCase();
      final fallback = email.split('@').first;
      bloc.add(
        AuthSignUpRequested(
          email: email,
          password: password,
          displayName: name.isNotEmpty ? name : fallback,
          username: username.isNotEmpty ? username : fallback,
        ),
      );
    } else {
      bloc.add(AuthSignInRequested(email: email, password: password));
    }
  }

  /// Sad Kairo for a moment and a short shake of the card.
  void _fail() {
    _sadTimer?.cancel();
    setState(() => _sad = true);
    _sadTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _sad = false);
    });
    if (!context.motion.reduced) unawaited(_shake.forward(from: 0));
  }

  MascotMood _mood(AuthStatus status) {
    if (status == AuthStatus.authenticated) return MascotMood.happy;
    if (status == AuthStatus.loading) return MascotMood.focused;
    if (_sad) return MascotMood.sad;
    if (_passwordFocus.hasFocus && !_showPassword) return MascotMood.sleeping;
    return MascotMood.idle;
  }

  String _greeting() {
    final l10n = context.l10n;
    final hour = (widget.now ?? DateTime.now()).hour;
    return hour < 12
        ? l10n.greetMorning
        : hour < 19
        ? l10n.greetAfternoon
        : l10n.greetEvening;
  }

  Future<void> _onAuth(BuildContext context, AuthState state) async {
    if (state.status == AuthStatus.authenticated) {
      unawaited(registeredHaptics?.celebrated());
      setState(() => _hops++);
      // Let the hop land before leaving.
      await Future<void>.delayed(
        context.motion.reduced
            ? Duration.zero
            : const Duration(milliseconds: 550),
      );
      if (context.mounted) context.go('/dashboard');
    } else if (state.status == AuthStatus.error) {
      _fail();
      final message = state.errorMessage;
      if (message != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: _onAuth,
      child: Scaffold(
        backgroundColor: colors.background,
        body: DefaultTextStyle.merge(
          style: TextStyle(color: colors.label),
          child: BlocBuilder<AuthBloc, AuthState>(
            buildWhen: (a, b) => a.status != b.status,
            builder: (context, auth) {
              final mood = _mood(auth.status);
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 24,
                ),
                child: Stack(
                  children: [
                    LoginHero(
                      mood: mood,
                      compact: _typing,
                      title: _signUp ? l10n.createAccount : _greeting(),
                      subtitle: _signUp
                          ? l10n.startYourJourney
                          : l10n.startSignInPrompt,
                      caption: mood == MascotMood.sleeping
                          ? l10n.kairoNotLooking
                          : null,
                      hopTrigger: _hops,
                      cue: _cue,
                      cueTrigger: _cues,
                      onTapKairo: _glance,
                      drift: widget.drift,
                    ),
                    _formCard(context, auth),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _formCard(BuildContext context, AuthState auth) {
    final colors = context.appColors;
    final motion = context.motion;
    final topInset = MediaQuery.paddingOf(context).top;
    final heroHeight =
        topInset + (_typing ? LoginHero.compactHeight : LoginHero.fullHeight);

    return AnimatedPadding(
      duration: motion.duration(KairoSpring.smooth),
      curve: motion.curve(KairoSpring.smooth),
      // Overlap the hero's rounded edge.
      padding: EdgeInsets.only(top: heroHeight - 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AnimatedBuilder(
            animation: _shake,
            builder: (context, child) => Transform.translate(
              offset: Offset(
                math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value),
                0,
              ),
              child: child,
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenMargin,
              ),
              padding: const EdgeInsets.all(AppSpacing.spacing16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A121417),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                  BoxShadow(
                    color: Color(0x14121417),
                    blurRadius: 32,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: FocusScope(node: _focusScope, child: _form(context, auth)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _form(BuildContext context, AuthState auth) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final motion = context.motion;

    final fields = <Widget>[
      KairoSegmentedControl<bool>(
        segments: {false: l10n.signIn, true: l10n.signUp},
        selected: _signUp,
        onChanged: (v) => setState(() => _signUp = v),
      ),
      AnimatedSize(
        duration: motion.duration(KairoSpring.smooth),
        curve: motion.curve(KairoSpring.smooth),
        alignment: Alignment.topCenter,
        child: _signUp
            ? Column(
                children: [
                  const SizedBox(height: AppSpacing.spacing12),
                  _Field(
                    controller: _name,
                    label: l10n.displayName,
                    icon: CupertinoIcons.person,
                    capitalization: TextCapitalization.words,
                    autofill: AutofillHints.name,
                  ),
                  const SizedBox(height: AppSpacing.spacing12),
                  _Field(
                    controller: _username,
                    label: l10n.username,
                    icon: CupertinoIcons.at,
                    autofill: AutofillHints.newUsername,
                  ),
                ],
              )
            : const SizedBox(width: double.infinity),
      ),
      AutofillGroup(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.spacing12),
            _Field(
              controller: _email,
              label: l10n.email,
              icon: CupertinoIcons.mail,
              keyboard: TextInputType.emailAddress,
              autofill: AutofillHints.email,
            ),
            const SizedBox(height: AppSpacing.spacing12),
            _Field(
              controller: _password,
              focusNode: _passwordFocus,
              label: l10n.password,
              icon: CupertinoIcons.lock,
              obscure: !_showPassword,
              done: true,
              onSubmitted: _submit,
              autofill: _signUp
                  ? AutofillHints.newPassword
                  : AutofillHints.password,
              suffix: IconButton(
                tooltip: l10n.password,
                onPressed: () => setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                  size: 20,
                  color: colors.labelSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
      if (!_signUp)
        Align(
          alignment: Alignment.centerRight,
          child: KairoButton(
            label: l10n.forgotPassword,
            variant: KairoButtonVariant.plain,
            onPressed: () => ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(l10n.passwordResetComingSoon),
                  behavior: SnackBarBehavior.floating,
                ),
              ),
          ),
        )
      else
        const SizedBox(height: AppSpacing.spacing16),
      KairoButton(
        label: _signUp ? l10n.createAccountButton : l10n.signIn,
        expand: true,
        loading: auth.status == AuthStatus.loading,
        onPressed: _submit,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing12),
        child: Row(
          children: [
            Expanded(child: Divider(color: colors.separator)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.orDivider,
                style: context.typography.footnote.copyWith(
                  color: colors.labelSecondary,
                ),
              ),
            ),
            Expanded(child: Divider(color: colors.separator)),
          ],
        ),
      ),
      _GoogleButton(
        onTap: () =>
            context.read<AuthBloc>().add(const AuthGoogleSignInRequested()),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < fields.length; i++)
          KairoEntrance(index: math.min(i, 5), child: fields[i]),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.focusNode,
    this.keyboard,
    this.obscure = false,
    this.done = false,
    this.onSubmitted,
    this.suffix,
    this.autofill,
    this.capitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final IconData icon;
  final TextInputType? keyboard;
  final bool obscure;
  final bool done;
  final VoidCallback? onSubmitted;
  final Widget? suffix;
  final String? autofill;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = BorderRadius.circular(AppSpacing.radiusTile);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboard,
      obscureText: obscure,
      autocorrect: false,
      textCapitalization: capitalization,
      textInputAction: done ? TextInputAction.done : TextInputAction.next,
      onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
      autofillHints: autofill == null ? null : [autofill!],
      style: context.typography.body,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: colors.labelSecondary),
        suffixIcon: suffix,
        filled: true,
        fillColor: colors.fill,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: colors.tint, width: 1.5),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.label,
        backgroundColor: colors.surface,
        side: BorderSide(color: colors.separator),
        minimumSize: const Size(double.infinity, 52),
        shape: const StadiumBorder(),
        textStyle: context.typography.headline,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset('assets/icons/google_logo.svg', width: 20),
          const SizedBox(width: AppSpacing.spacing8),
          Flexible(child: Text(context.l10n.continueWithGoogle)),
        ],
      ),
    );
  }
}
