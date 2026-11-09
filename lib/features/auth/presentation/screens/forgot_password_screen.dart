import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../../data/exceptions/auth_exception.dart';
import '../providers/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(email: _emailController.text);
    if (success && mounted) {
      setState(() => _emailSent = true);
    } else if (!success && mounted) {
      final error = ref.read(authControllerProvider).error;
      final msg = error is AppAuthException
          ? error.message
          : ErrorMapper.toUserMessage(error);
      showGlassSnackBar(context, msg, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final isDark = AppColors.isDark(context);

    return GlassScaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _emailSent
              ? Center(
                  child: GlassCard(
                    padding: const EdgeInsets.all(28),
                    borderRadius: 26,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.income(context).withValues(alpha: 0.15),
                          ),
                          child: Icon(
                            Icons.mark_email_read_rounded,
                            size: 48,
                            color: AppColors.income(context),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Email Terkirim!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tautan reset password telah dikirimkan ke:\n${_emailController.text}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 26),
                        AppButton(
                          label: 'Kembali ke Login',
                          icon: Icons.arrow_back_rounded,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                )
              : Center(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Atur Ulang Password',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 26),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Masukkan alamat email yang terdaftar. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi Anda.',
                            style: TextStyle(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          GlassCard(
                            padding: const EdgeInsets.all(22),
                            borderRadius: 26,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  hint: 'nama@email.com',
                                  keyboardType: TextInputType.emailAddress,
                                  validator: Validators.email,
                                ),
                                const SizedBox(height: 20),
                                AppButton(
                                  label: 'Kirim Tautan Reset',
                                  icon: Icons.send_rounded,
                                  isLoading: isLoading,
                                  onPressed: _handleSubmit,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
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
