import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/constants.dart';
import 'login_screen.dart';
import 'setup_profile_screen.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (fullName.isEmpty) { _showSnackBar('Vui lòng nhập họ và tên'); return; }
    if (email.isEmpty) { _showSnackBar('Vui lòng nhập email'); return; }
    if (!email.contains('@')) { _showSnackBar('Email không hợp lệ'); return; }
    if (username.isEmpty) { _showSnackBar('Vui lòng nhập tên đăng nhập'); return; }
    if (password.isEmpty) { _showSnackBar('Vui lòng nhập mật khẩu'); return; }
    if (password.length < 6) { _showSnackBar('Mật khẩu phải có ít nhất 6 ký tự'); return; }
    if (confirmPassword.isEmpty) { _showSnackBar('Vui lòng xác nhận mật khẩu'); return; }
    if (confirmPassword != password) { _showSnackBar('Mật khẩu không khớp'); return; }

    context.read<AuthBloc>().add(AuthRegisterRequested(
      email: email,
      password: password,
      username: username,
      fullName: fullName,
    ));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          curr.status == AuthStatus.error && prev.status != AuthStatus.error,
      listener: (context, state) {
        if (state.errorMessage != null) {
          _showSnackBar(state.errorMessage!);
        }
      },
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) =>
            curr.status == AuthStatus.authenticated &&
            prev.status != AuthStatus.authenticated,
        listener: (context, state) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SetupProfileScreen()),
          );
        },
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.white, Color(0xFFEFF6FF)],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingL),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildHeader(),
                    const SizedBox(height: AppSizes.paddingXL),
                    _buildRegisterCard(),
                    const SizedBox(height: AppSizes.paddingXL),
                    _buildFooter(),
                    const SizedBox(height: AppSizes.paddingXL),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            style: IconButton.styleFrom(backgroundColor: AppColors.surface),
          ),
        ),
        const SizedBox(height: AppSizes.paddingL),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            boxShadow: const [BoxShadow(color: AppColors.secondary, blurRadius: 20, offset: Offset(0, 8))],
          ),
          child: const Icon(Icons.person_add_alt_1_rounded, size: 40, color: AppColors.white),
        ),
        const SizedBox(height: AppSizes.paddingL),
        const Text('Tạo tài khoản', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: AppSizes.paddingS),
        const Text('Tham gia Find My Team để tìm đồng đội phù hợp', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildRegisterCard() {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        boxShadow: const [BoxShadow(color: AppColors.divider, blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(controller: _fullNameController, label: 'HỌ VÀ TÊN', hint: 'Nguyễn Văn A', icon: Icons.badge_outlined),
          const SizedBox(height: AppSizes.paddingL),
          _buildTextField(controller: _emailController, label: 'EMAIL', hint: 'email@example.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: AppSizes.paddingL),
          _buildTextField(controller: _usernameController, label: 'TÊN ĐĂNG NHẬP', hint: 'username', icon: Icons.person_outline),
          const SizedBox(height: AppSizes.paddingL),
          _buildPasswordField(controller: _passwordController, label: 'MẬT KHẨU', hint: '********', isConfirm: false),
          const SizedBox(height: AppSizes.paddingL),
          _buildPasswordField(controller: _confirmPasswordController, label: 'XÁC NHẬN MẬT KHẨU', hint: '********', isConfirm: true),
          const SizedBox(height: AppSizes.paddingL),
          _buildRegisterButton(),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: AppSizes.paddingS),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 16),
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: AppSizes.iconM),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS), borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS), borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({required TextEditingController controller, required String label, required String hint, required bool isConfirm}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: AppSizes.paddingS),
        TextFormField(
          controller: controller,
          obscureText: isConfirm ? _obscureConfirmPassword : _obscurePassword,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 16),
            prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.textSecondary, size: AppSizes.iconM),
            suffixIcon: IconButton(
              icon: Icon((isConfirm ? _obscureConfirmPassword : _obscurePassword) ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size: AppSizes.iconM),
              onPressed: () => setState(() { isConfirm ? _obscureConfirmPassword = !_obscureConfirmPassword : _obscurePassword = !_obscurePassword; }),
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS), borderSide: const BorderSide(color: AppColors.divider)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS), borderSide: const BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSizes.radiusS), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingM, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) =>
          curr.status == AuthStatus.loading ||
          prev.status == AuthStatus.loading,
      builder: (context, state) {
        final isLoading = state.status == AuthStatus.loading;
        return SizedBox(
          height: AppSizes.buttonHeightL,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radiusL)),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                  )
                : const Text('ĐĂNG KÝ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Đã có tài khoản? ', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        TextButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: const Text('Đăng nhập', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
      ],
    );
  }
}
