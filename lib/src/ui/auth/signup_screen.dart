import 'package:food_app/src/imports/core_imports.dart';
import 'package:food_app/src/imports/packages_imports.dart';
import 'package:food_app/src/ui/auth/bloc/auth_bloc.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    debugPrint('[SignupScreen] signup submitted');
    context.read<AuthBloc>().add(
          SignUpRequested(
            context: context,
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select((AuthBloc b) => b.state.isLoading);
    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;
    debugPrint('[SignupScreen] build isLoading=$isLoading');

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // ── Gradient header ──────────────────────────────
          _SignupHeader(primary: cs.primary),

          // ── Form area ────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create account ✨',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Join and start discovering recipes',
                    style:
                        tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  SizedBox(height: 24.h),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _nameController,
                          enabled: !isLoading,
                          label: 'Full name',
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: (v) =>
                              AppUtils.isBlank(v) ? 'Name is required' : null,
                        ),
                        SizedBox(height: 12.h),
                        AppTextField(
                          controller: _emailController,
                          enabled: !isLoading,
                          keyboardType: TextInputType.emailAddress,
                          label: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: (v) {
                            if (AppUtils.isBlank(v)) {
                              return 'Email is required';
                            }
                            if (!AppUtils.isValidEmail(v!)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 12.h),
                        AppTextField(
                          controller: _passwordController,
                          enabled: !isLoading,
                          label: 'Password',
                          obscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          validator: (v) {
                            if (AppUtils.isBlank(v)) {
                              return 'Password is required';
                            }
                            if (v!.length < 6) return 'Min 6 characters';
                            return null;
                          },
                        ),
                        SizedBox(height: 12.h),
                        AppTextField(
                          controller: _confirmPasswordController,
                          enabled: !isLoading,
                          label: 'Confirm password',
                          obscureText: _obscureConfirm,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                          validator: (v) {
                            if (AppUtils.isBlank(v)) {
                              return 'Please confirm your password';
                            }
                            if (v != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 22.h),
                        SizedBox(
                          width: double.infinity,
                          height: 54.h,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleSignup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: 22.w,
                                    height: 22.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: cs.onPrimary,
                                    ),
                                  )
                                : Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: cs.outlineVariant,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: Text(
                          'or sign up with',
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: cs.outlineVariant,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialButton(
                        color: const Color(0xFFEA4335),
                        child: SvgPicture.asset(
                          AppAssets.googleIcon,
                          width: 22.w,
                          height: 22.w,
                        ),
                        onTap: () {},
                      ),
                      SizedBox(width: 16.w),
                      _SocialButton(
                        color: const Color(0xFF1877F2),
                        child: SvgPicture.asset(
                          AppAssets.facebookIcon,
                          width: 22.w,
                          height: 22.w,
                        ),
                        onTap: () {},
                      ),
                      SizedBox(width: 16.w),
                      _SocialButton(
                        color: Colors.black,
                        child: SvgPicture.asset(
                          AppAssets.appleIcon,
                          width: 22.w,
                          height: 22.w,
                        ),
                        onTap: () {},
                      ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account?  ',
                          style: tt.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                          children: [
                            TextSpan(
                              text: 'Sign in',
                              style: TextStyle(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupHeader extends StatelessWidget {
  const _SignupHeader({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        height: 160.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary,
              Color.lerp(primary, const Color(0xFFF97316), 0.5)!,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Bite & Time',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 48.w),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - 20,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 40,
      size.width,
      size.height - 10,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.color,
    required this.child,
    required this.onTap,
  });
  final Color color;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54.w,
        height: 54.w,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Center(child: child),
      ),
    );
  }
}
