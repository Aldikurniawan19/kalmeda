import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';

/// Screen presenting the privacy policy and health data protection guarantees.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Kebijakan Privasi',
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
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.space20,
          vertical: AppSizes.space16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trust & Encryption Banner
            Container(
              padding: const EdgeInsets.all(AppSizes.space16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 22),
                  SizedBox(width: AppSizes.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Komitmen Privasi Kesehatan Anda',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF166534),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Data siklus, rekam gejala, dan profil kesehatan reproduksi Anda bersifat rahasia dan tidak pernah diperjualbelikan kepada pengiklan atau pihak ketiga manapun.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF15803D),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.space20),

            _buildSection(
              number: '1',
              title: 'Data yang Kami Kumpulkan',
              content:
                  'Kami hanya mengumpulkan informasi yang esensial untuk memproses siklus dan personalisasi akun Anda:\n'
                  '• Informasi Akun: Alamat email dan nama pengguna untuk autentikasi.\n'
                  '• Parameter Siklus: Hari pertama haid terakhir (HPHT), rata-rata panjang siklus, durasi menstruasi, dan tanggal lahir.\n'
                  '• Catatan Harian (Opsional): Volume aliran darah haid, gejala fisik harian, suasana hati (mood), dan catatan pribadi.',
            ),
            const SizedBox(height: AppSizes.space16),

            _buildSection(
              number: '2',
              title: 'Tujuan Penggunaan Data',
              content:
                  'Data biologis dan siklus digunakan semata-mata untuk:\n'
                  '• Menghitung proyeksi tanggal menstruasi berikutnya, jendela masa subur (fertile window), dan hari ovulasi.\n'
                  '• Menyajikan wawasan kesehatan dan rekomendasi kebugaran yang relevan dengan fase siklus Anda saat ini.\n'
                  '• Memberikan notifikasi pengingat sebelum jadwal menstruasi tiba.',
            ),
            const SizedBox(height: AppSizes.space16),

            _buildSection(
              number: '3',
              title: 'Keamanan Data & Ruang Konsultasi',
              content:
                  'Semua data profil dan catatan siklus Anda disimpan secara aman dan terkunci rapi dengan standar keamanan modern agar tidak dapat diakses oleh pihak yang tidak berhak.\n\n'
                  '• Privasi Ruang Tanya Jawab: Seluruh percakapan di menu konsultasi bersifat rahasia. Pesan tidak pernah kami simpan di server dan otomatis terhapus bersih setelah Anda menutup aplikasi.',
            ),
            const SizedBox(height: AppSizes.space16),

            _buildSection(
              number: '4',
              title: 'Hak Pengguna & Kontrol Data',
              content:
                  'Anda memiliki kontrol penuh atas data Anda di Kalmeda:\n'
                  '• Mengubah atau mengoreksi data profil dan parameter siklus kapan saja melalui menu Informasi Pribadi.\n'
                  '• Mengubah kata sandi atau memperbarui kredensial akun.\n'
                  '• Menghapus riwayat catatan atau akun Anda sewaktu-waktu.',
            ),
            const SizedBox(height: AppSizes.space16),

            _buildSection(
              number: '5',
              title: 'Pembaruan Kebijakan',
              content:
                  'Kebijakan privasi ini dapat disesuaikan secara berkala seiring penambahan fitur baru. Pembaruan signifikan akan diinformasikan secara transparan melalui pembaruan aplikasi.',
            ),
            const SizedBox(height: AppSizes.space20),

            // Footer Note
            Center(
              child: Text(
                'Terakhir diperbarui: September 2026',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.space24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: const Color(0xFFF3EFF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
