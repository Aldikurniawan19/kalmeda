import 'package:flutter/material.dart';

import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/core/utils/app_page_route.dart';
import 'package:menstracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:menstracker/features/auth/presentation/screens/login_screen.dart';
import 'package:menstracker/features/home/presentation/widgets/home_bottom_navbar.dart';
import 'package:menstracker/features/home/presentation/widgets/reminder_settings_bottom_sheet.dart';
import 'package:menstracker/features/profile/presentation/screens/about_app_screen.dart';
import 'package:menstracker/features/profile/presentation/screens/change_password_screen.dart';
import 'package:menstracker/features/profile/presentation/screens/help_center_screen.dart';
import 'package:menstracker/features/profile/presentation/screens/personal_info_screen.dart';
import 'package:menstracker/features/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:menstracker/features/profile/presentation/widgets/profile_header.dart';
import 'package:menstracker/features/profile/presentation/widgets/profile_logout_button.dart';
import 'package:menstracker/features/profile/presentation/widgets/profile_menu_group.dart';
import 'package:menstracker/features/profile/presentation/widgets/profile_user_card.dart';

/// Profile screen displaying user account and help settings.
class ProfileScreen extends StatefulWidget {
  final ValueChanged<int>? onNavTapped;
  final bool showBottomNav;

  const ProfileScreen({
    super.key,
    this.onNavTapped,
    this.showBottomNav = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentNavIndex = 4;

  void _handleNavTapped(int index) {
    if (widget.onNavTapped != null) {
      widget.onNavTapped!(index);
    } else {
      setState(() {
        _currentNavIndex = index;
      });
    }
  }

  Future<void> _openPersonalInfo() async {
    final updated = await Navigator.of(
      context,
    ).push<bool>(AppPageRoute(builder: (_) => const PersonalInfoScreen()));

    if (updated == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _openChangePassword() async {
    await Navigator.of(
      context,
    ).push(AppPageRoute(builder: (_) => const ChangePasswordScreen()));
  }

  void _openHelpCenter() {
    Navigator.of(
      context,
    ).push(AppPageRoute(builder: (_) => const HelpCenterScreen()));
  }

  void _openPrivacyPolicy() {
    Navigator.of(
      context,
    ).push(AppPageRoute(builder: (_) => const PrivacyPolicyScreen()));
  }

  void _openAboutApp() {
    Navigator.of(
      context,
    ).push(AppPageRoute(builder: (_) => const AboutAppScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.space20,
            vertical: AppSizes.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header with Title & Settings
              ProfileHeader(onBack: () => _handleNavTapped(0)),
              const SizedBox(height: AppSizes.space14),

              // User Profile Info & Stats Card
              ProfileUserCard(onEditProfile: _openPersonalInfo),
              const SizedBox(height: AppSizes.space20),

              // Section 1: Akun Saya
              ProfileMenuGroup(
                title: 'Akun Saya',
                items: [
                  ProfileMenuItemData(
                    icon: Icons.person_outline_rounded,
                    title: 'Informasi Pribadi',
                    onTap: _openPersonalInfo,
                  ),
                  ProfileMenuItemData(
                    icon: Icons.notifications_none_rounded,
                    title: 'Pengaturan Notifikasi',
                    onTap: () => ReminderSettingsBottomSheet.show(context),
                  ),
                  ProfileMenuItemData(
                    icon: Icons.lock_outline_rounded,
                    title: 'Ubah Kata Sandi',
                    onTap: _openChangePassword,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.space20),

              // Section 2: Bantuan & Lainnya
              ProfileMenuGroup(
                title: 'Bantuan & Lainnya',
                items: [
                  ProfileMenuItemData(
                    icon: Icons.help_outline_rounded,
                    title: 'Pusat Bantuan',
                    onTap: _openHelpCenter,
                  ),
                  ProfileMenuItemData(
                    icon: Icons.description_outlined,
                    title: 'Kebijakan Privasi',
                    onTap: _openPrivacyPolicy,
                  ),
                  ProfileMenuItemData(
                    assetIconPath: 'assets/icon/app_icon.png',
                    icon: Icons.info_outline_rounded,
                    title: 'Tentang Aplikasi',
                    onTap: _openAboutApp,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.space20),

              // Logout Button
              ProfileLogoutButton(
                onLogout: () async {
                  await AuthController().logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    AppPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: AppSizes.space24),

              // Developer & Version info footer
              const Center(
                child: Column(
                  children: [
                    Text(
                      'Kalmeda v2.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Dikembangkan oleh Aldi Kurniawan & Wiyanda Susanti',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.space32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? HomeBottomNavbar(
              selectedIndex: _currentNavIndex,
              onItemTapped: _handleNavTapped,
            )
          : null,
    );
  }
}
