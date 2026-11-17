import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_motion.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/services/haptics_service.dart';
import '../../../../core/widgets/kairo_button.dart';
import '../../../../core/widgets/kairo_entrance.dart';
import '../../../../core/widgets/kairo_segmented_control.dart';
import '../../../dashboard/domain/mascot/mascot_mood.dart';
import '../../../dashboard/presentation/widgets/mascot/kairo_mascot.dart';
import '../../../dashboard/presentation/widgets/mascot/mascot_behavior.dart';
import '../bloc/auth_bloc.dart';

/// Sign in or create an account (docs/design.md § Login and onboarding).
///
/// It opens on Kairo, a greeting and the ways in: Apple (iOS), Google, and
/// "Continue with email". Email slides a white sheet up with the form while
/// Kairo shrinks above it. Kairo follows along: he glances over when the
/// form opens, closes his eyes while you type a hidden password,
/// concentrates while signing in, looks sad (and the sheet shakes) on an
/// error, and hops when you get in.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.now});

  /// Fixed in goldens: the greeting's time.
  final DateTime? now;

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

  /// Kairo's area above the email form, and its least height above the
  /// ways in (it takes about half the screen when there is room).
  static const double _compactHero = 176;
  static const double _minHero = 240;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  bool _withEmail = false;
  bool _showPassword = false;
  bool _signUp = false;
  bool _sad = false;
  int _hops = 0;
  int _cues = 0;
  MascotBehavior? _cue;
  Timer? _sadTimer;

  @override
  void initState() {
    super.initState();
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

  void _glance() => setState(() {
    _cue = MascotBehavior.look;
    _cues++;
  });

  void _openEmail() {
    setState(() => _withEmail = true);
    _glance();
  }

  void _closeEmail() {
    FocusScope.of(context).unfocus();
    setState(() => _withEmail = false);
  }

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

  /// Sad Kairo for a moment and a short shake of the form.
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
    if (_withEmail && _passwordFocus.hasFocus && !_showPassword) {
      return MascotMood.sleeping;
    }
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
    final colors = context.appColors;
    final motion = context.motion;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: _onAuth,
      child: PopScope(
        // Back from the email form returns to the ways in.
        canPop: !_withEmail,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _closeEmail();
        },
        child: Scaffold(
          backgroundColor: colors.background,
          body: DefaultTextStyle.merge(
            style: TextStyle(color: colors.label),
            child: BlocBuilder<AuthBloc, AuthState>(
              buildWhen: (a, b) => a.status != b.status,
              builder: (context, auth) => SafeArea(
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final heroHeight = _withEmail
                        ? _compactHero
                        : math.max(_minHero, constraints.maxHeight * 0.46);
                    return Stack(
                      children: [
                        Column(
                          children: [
                            AnimatedContainer(
                              duration: motion.duration(KairoSpring.smooth),
                              curve: motion.curve(KairoSpring.smooth),
                              height: heroHeight,
                              child: _Hero(
                                mood: _mood(auth.status),
                                compact: _withEmail,
                                hopTrigger: _hops,
                                cue: _cue,
                                cueTrigger: _cues,
                                onTapKairo: _glance,
                              ),
                            ),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: motion.duration(KairoSpring.smooth),
                                switchInCurve: motion.curve(KairoSpring.smooth),
                                switchOutCurve: Curves.easeOut,
                                transitionBuilder: _panelTransition,
                                // Both panels fill the space below Kairo.
                                layoutBuilder: (current, previous) => Stack(
                                  fit: StackFit.expand,
                                  children: [...previous, ?current],
                                ),
                                child: _withEmail
                                    ? KeyedSubtree(
                                        key: const ValueKey('email'),
                                        child: _emailSheet(context, auth),
                                      )
                                    : KeyedSubtree(
                                        key: const ValueKey('start'),
                                        child: _start(context),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: AppSpacing.spacing8,
                          left: AppSpacing.spacing16,
                          child: AnimatedOpacity(
                            opacity: _withEmail ? 1 : 0,
                            duration: motion.duration(KairoSpring.snappy),
                            child: IgnorePointer(
                              ignoring: !_withEmail,
                              child: _BackButton(onTap: _closeEmail),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The email sheet rises from the bottom; the start panel just fades.
  Widget _panelTransition(Widget child, Animation<double> animation) {
    final isSheet = child.key == const ValueKey('email');
    if (!isSheet) return FadeTransition(opacity: animation, child: child);
    return SlideTransition(
      position: Tween(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

  Widget _start(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final bottom = MediaQuery.paddingOf(context).bottom;

    final actions = <Widget>[
      // Apple requires its own sign-in, at least as prominent as Google's,
      // in iOS apps that offer a third-party login.
      if (defaultTargetPlatform == TargetPlatform.iOS)
        _AppleButton(
          onTap: () =>
              context.read<AuthBloc>().add(const AuthAppleSignInRequested()),
        ),
      _GoogleButton(
        onTap: () =>
            context.read<AuthBloc>().add(const AuthGoogleSignInRequested()),
      ),
      KairoButton(
        label: l10n.continueWithEmail,
        variant: KairoButtonVariant.plain,
        expand: true,
        onPressed: _openEmail,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.spacing24,
          0,
          AppSpacing.spacing24,
          bottom + AppSpacing.spacing16,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(
              0,
              constraints.maxHeight - bottom - AppSpacing.spacing16,
            ),
          ),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KairoEntrance(
                  child: Semantics(
                    header: true,
                    child: Text(
                      _greeting(),
                      textAlign: TextAlign.center,
                      style: context.typography.largeTitle,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing8),
                KairoEntrance(
                  index: 1,
                  child: Text(
                    l10n.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: context.typography.bodyMultiline.copyWith(
                      color: colors.labelSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(height: AppSpacing.spacing24),
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.spacing12),
                  KairoEntrance(index: i + 2, child: actions[i]),
                ],
                KairoEntrance(
                  index: actions.length + 2,
                  child: const _Consent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailSheet(BuildContext context, AuthState auth) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final motion = context.motion;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value),
          0,
        ),
        child: child,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14121417),
              blurRadius: 40,
              offset: Offset(0, -12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.spacing20,
            AppSpacing.spacing24,
            AppSpacing.spacing20,
            bottom + AppSpacing.spacing16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: FocusScope(
                node: _focusScope,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    KairoSegmentedControl<bool>(
                      segments: {false: l10n.signIn, true: l10n.createAccount},
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
                              onPressed: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                              icon: Icon(
                                _showPassword
                                    ? CupertinoIcons.eye_slash
                                    : CupertinoIcons.eye,
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
                      const SizedBox(height: AppSpacing.spacing20),
                    KairoButton(
                      label: _signUp ? l10n.createAccount : l10n.signIn,
                      expand: true,
                      loading: auth.status == AuthStatus.loading,
                      onPressed: _submit,
                    ),
                    const _Consent(),
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

/// Kairo and, while he looks away from a password, his promise.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.mood,
    required this.compact,
    required this.hopTrigger,
    required this.cue,
    required this.cueTrigger,
    required this.onTapKairo,
  });

  final MascotMood mood;
  final bool compact;
  final int hopTrigger;
  final MascotBehavior? cue;
  final int cueTrigger;
  final VoidCallback onTapKairo;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final motion = context.motion;
    final caption = mood == MascotMood.sleeping
        ? context.l10n.kairoNotLooking
        : null;
    // Bottom-anchored; while the hero animates between heights the top
    // clips instead of overflowing.
    return SingleChildScrollView(
      reverse: true,
      physics: const NeverScrollableScrollPhysics(),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: motion.duration(KairoSpring.smooth),
              curve: motion.curve(KairoSpring.smooth),
              height: compact ? 124 : 200,
              child: FittedBox(
                child: KairoMascot(
                  mood: mood,
                  hopTrigger: hopTrigger,
                  cue: cue,
                  cueTrigger: cueTrigger,
                  onTap: onTapKairo,
                  size: 200,
                ),
              ),
            ),
            SizedBox(
              height: 28,
              child: AnimatedSwitcher(
                duration: motion.duration(KairoSpring.smooth),
                child: caption == null
                    ? const SizedBox.shrink()
                    : Text(
                        caption,
                        key: ValueKey(caption),
                        style: context.typography.footnote.copyWith(
                          color: colors.tint,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing8),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: context.l10n.back,
      child: Material(
        color: colors.surface,
        shape: CircleBorder(side: BorderSide(color: colors.separator)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(
              CupertinoIcons.chevron_back,
              size: 20,
              color: colors.label,
            ),
          ),
        ),
      ),
    );
  }
}

/// "By continuing you agree to the Privacy policy." The whole line opens
/// the policy, so the target stays large.
class _Consent extends StatelessWidget {
  const _Consent();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final style = context.typography.footnote.copyWith(
      color: colors.labelSecondary,
    );
    return Semantics(
      link: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => launchUrl(
          Uri.parse(AppConstants.privacyPolicyUrl),
          mode: LaunchMode.externalApplication,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing8),
            child: Center(
              child: Text.rich(
                TextSpan(
                  style: style,
                  children: [
                    TextSpan(text: '${l10n.legalConsentLead} '),
                    TextSpan(
                      text: l10n.privacyPolicy,
                      style: style.copyWith(
                        color: colors.tint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
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
        minimumSize: const Size(double.infinity, 54),
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

/// Sign in with Apple, styled per Apple's guidelines: black in light mode,
/// white in dark mode, the Apple logo and "Continue with Apple".
class _AppleButton extends StatelessWidget {
  const _AppleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    final bg = dark ? Colors.white : Colors.black;
    final fg = dark ? Colors.black : Colors.white;
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        foregroundColor: fg,
        backgroundColor: bg,
        minimumSize: const Size(double.infinity, 54),
        shape: const StadiumBorder(),
        textStyle: context.typography.headline,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apple, size: 22, color: fg),
          const SizedBox(width: AppSpacing.spacing8),
          Flexible(child: Text(context.l10n.continueWithApple)),
        ],
      ),
    );
  }
}
