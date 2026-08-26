import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isSignUp = false;

  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animationController?.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final size = MediaQuery.of(context).size;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.go('/tasks');
        } else if (state.status == AuthStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.surface,
                colors.surfaceSubtle,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing32,
                  vertical: AppSpacing.spacing24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: FadeTransition(
                    opacity: _animationController ??
                        const AlwaysStoppedAnimation<double>(1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: size.height * 0.04),

                        // Logo
                        Center(
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: colors.surfaceElevated,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colors.textPrimary.withValues(
                                    alpha: 0.06,
                                  ),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: SvgPicture.asset(
                              'assets/icons/app_icon.svg',
                              width: 140,
                              height: 140,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.spacing32),

                        // Title with animation
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.1),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            _isSignUp
                                ? context.l10n.createAccount
                                : context.l10n.loginTitle,
                            key: ValueKey('title_$_isSignUp'),
                            style: context.textTheme.headlineLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: AppSpacing.spacing8),

                        Text(
                          _isSignUp
                              ? context.l10n.startYourJourney
                              : context.l10n.startSignInPrompt,
                          style: context.textTheme.bodyLarge?.copyWith(
                            color: colors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: AppSpacing.spacing40),

                        // Form
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          layoutBuilder: (currentChild, previousChildren) {
                            return Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                ...previousChildren,
                                if (currentChild != null) currentChild,
                              ],
                            );
                          },
                          child: _buildForm(colors),
                        ),

                        const SizedBox(height: AppSpacing.spacing24),

                        // Submit
                        _SubmitButton(
                          isSignUp: _isSignUp,
                          onTap: _submit,
                        ),

                        const SizedBox(height: AppSpacing.spacing24),

                        // Google sign in
                        _GoogleButton(
                          onTap: () => context
                              .read<AuthBloc>()
                              .add(const AuthGoogleSignInRequested()),
                        ),

                        const SizedBox(height: AppSpacing.spacing32),

                        // Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignUp
                                  ? context.l10n.alreadyHaveAnAccount
                                  : context.l10n.dontHaveAnAccount,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSignUp = !_isSignUp;
                                  _animationController
                                    ?..reset()
                                    ..forward();
                                });
                              },
                              child: Text(
                                _isSignUp
                                ? context.l10n.signIn
                                : context.l10n.signUp,
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: colors.accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: size.height * 0.04),
                      ],
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

  Widget _buildForm(AppColorScheme colors) {
    return Column(
      key: ValueKey('form_$_isSignUp'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isSignUp) ...[
          _ModernTextField(
            controller: _nameController,
            label: context.l10n.displayName,
            hint: context.l10n.displayNameHint,
            icon: Icons.person_outline,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.spacing16),
          _ModernTextField(
            controller: _usernameController,
            label: context.l10n.username,
            hint: context.l10n.usernameHint,
            icon: Icons.alternate_email,
            textInputAction: TextInputAction.next,
            autocorrect: false,
          ),
          const SizedBox(height: AppSpacing.spacing16),
        ],
        _ModernTextField(
          controller: _emailController,
          label: context.l10n.email,
          hint: context.l10n.emailHint,
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.spacing16),
        _ModernTextField(
          controller: _passwordController,
          label: context.l10n.password,
          hint: _isSignUp
              ? context.l10n.passwordHintSignUp
              : context.l10n.passwordHintSignIn,
          icon: Icons.lock_outline,
          obscureText: !_isPasswordVisible,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          suffix: IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: colors.textMuted,
              size: 20,
            ),
            onPressed: () => setState(
              () => _isPasswordVisible = !_isPasswordVisible,
            ),
          ),
        ),
        if (!_isSignUp) ...[
          const SizedBox(height: AppSpacing.spacing8),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.passwordResetComingSoon),
                  ),
                );
              },
              child: Text(
                context.l10n.forgotPassword,
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _submit() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) return;

    if (_isSignUp) {
      final name = _nameController.text.trim();
      final username = _usernameController.text.trim().toLowerCase();
      context.read<AuthBloc>().add(
            AuthSignUpRequested(
              email: email,
              password: password,
              displayName: name.isNotEmpty ? name : email.split('@').first,
              username: username.isNotEmpty
                  ? username
                  : email.split('@').first,
            ),
          );
    } else {
      context.read<AuthBloc>().add(
            AuthSignInRequested(email: email, password: password),
          );
    }
  }
}

class _ModernTextField extends StatelessWidget {
  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.autocorrect = true,
    this.onSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool autocorrect;
  final void Function(String)? onSubmitted;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: colors.border.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        autocorrect: autocorrect,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: Icon(icon, color: colors.textSecondary),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing16,
            vertical: AppSpacing.spacing16,
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isSignUp,
    required this.onTap,
  });

  final bool isSignUp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;

        return GestureDetector(
          onTap: isLoading ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 56,
            decoration: BoxDecoration(
              color: colors.accent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isSignUp
                          ? context.l10n.createAccountButton
                          : context.l10n.signIn,
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: SvgPicture.asset(
        'assets/icons/google_logo.svg',
        width: 24,
        height: 24,
      ),
      label: Text(context.l10n.continueWithGoogle),
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        backgroundColor: colors.surfaceElevated,
        side: BorderSide(color: colors.border),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
