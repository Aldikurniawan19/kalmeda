import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:menstracker/features/auth/presentation/widgets/auth_text_field.dart';

/// Screen allowing the user to update their account password.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSendingResetEmail = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authController = AuthController();
    final success = await authController.changePassword(
      currentPassword: _currentPasswordController.text.trim(),
      newPassword: _newPasswordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi Anda berhasil diperbarui.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final error = authController.errorMessage ?? 'Gagal mengubah kata sandi.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    final user = AuthController().currentUser;
    if (user == null || user.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email akun tidak ditemukan. Silakan login ulang.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSendingResetEmail = true;
    });

    final success = await AuthController().sendPasswordResetEmail(email: user.email);

    if (!mounted) return;

    setState(() {
      _isSendingResetEmail = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tautan reset kata sandi telah dikirim ke ${user.email}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final error = AuthController().errorMessage ?? 'Gagal mengirim email reset.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthController(),
      builder: (context, _) {
        final isLoading = AuthController().isLoading;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: AppColors.cardBackground,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Ubah Kata Sandi',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                color: const Color(0xFFF3EFF4),
                height: 1,
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.space20,
                vertical: AppSizes.space20,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Security Guidance Card
                    Container(
                      padding: const EdgeInsets.all(AppSizes.space16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F5),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        border: Border.all(
                          color: const Color(0xFFFFD6E3),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSizes.space8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                            ),
                            child: const Icon(
                              Icons.shield_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppSizes.space12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Keamanan Akun',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Kata sandi baru harus minimal 6 karakter. Gunakan kombinasi huruf dan angka agar akun tetap aman.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.space24),

                    // 1. Current Password
                    AuthTextField(
                      controller: _currentPasswordController,
                      label: 'Kata Sandi Saat Ini',
                      hintText: 'Masukkan kata sandi saat ini',
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      isPasswordVisible: _isCurrentPasswordVisible,
                      onTogglePasswordVisibility: () {
                        setState(() {
                          _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                        });
                      },
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Kata sandi saat ini harus diisi.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.space8),

                    // Forgot Password Reset Action
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isSendingResetEmail ? null : _handleForgotPassword,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _isSendingResetEmail
                              ? 'Mengirim email reset...'
                              : 'Lupa kata sandi saat ini?',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.space16),

                    // 2. New Password
                    AuthTextField(
                      controller: _newPasswordController,
                      label: 'Kata Sandi Baru',
                      hintText: 'Masukkan minimal 6 karakter',
                      prefixIcon: Icons.lock_reset_rounded,
                      isPassword: true,
                      isPasswordVisible: _isNewPasswordVisible,
                      onTogglePasswordVisibility: () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      },
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Kata sandi baru harus diisi.';
                        }
                        if (val.trim().length < 6) {
                          return 'Kata sandi baru minimal 6 karakter.';
                        }
                        if (val.trim() == _currentPasswordController.text.trim()) {
                          return 'Kata sandi baru tidak boleh sama dengan kata sandi lama.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSizes.space16),

                    // 3. Confirm New Password
                    AuthTextField(
                      controller: _confirmPasswordController,
                      label: 'Konfirmasi Kata Sandi Baru',
                      hintText: 'Ulangi kata sandi baru',
                      prefixIcon: Icons.check_circle_outline_rounded,
                      isPassword: true,
                      isPasswordVisible: _isConfirmPasswordVisible,
                      textInputAction: TextInputAction.done,
                      onTogglePasswordVisibility: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Konfirmasi kata sandi baru harus diisi.';
                        }
                        if (val.trim() != _newPasswordController.text.trim()) {
                          return 'Konfirmasi kata sandi tidak cocok.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleSubmit(),
                    ),
                    const SizedBox(height: AppSizes.space32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFFFB3C7),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Text(
                                'Simpan Kata Sandi Baru',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
