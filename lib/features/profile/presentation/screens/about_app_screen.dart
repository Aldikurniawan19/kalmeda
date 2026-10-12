import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_info.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/app_update/presentation/controllers/app_update_controller.dart';

/// Screen presenting application information, clinical predictive methodology, medical sources, and disclaimer.
class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

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
          'Tentang Aplikasi',
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
          child: Container(color: const Color(0xFFF3EFF4), height: 1),
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
            // App Branding Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.space20,
                horizontal: AppSizes.space16,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                border: Border.all(color: const Color(0xFFF3EFF4)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space12),
                  const Text(
                    'Kalmeda',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Versi ${AppInfo.appVersion} (Build ${AppInfo.buildNumber})',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Pemantau Siklus & Kesehatan Reproduksi Modern',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space14),
                  OutlinedButton.icon(
                    onPressed: () =>
                        AppUpdateController().checkUpdateManually(context),
                    icon: const Icon(
                      Icons.system_update_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: const Text(
                      'Periksa Pembaruan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFFFB8CC),
                        width: 1.0,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.space16,
                        vertical: AppSizes.space8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMedium),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.space20),

            // Section 1: Ringkasan Aplikasi
            _buildContentCard(
              title: 'Tentang Kalmeda',
              icon: Icons.auto_awesome_rounded,
              children: [
                const Text(
                  'Kalmeda adalah aplikasi pemantauan siklus menstruasi dan kesehatan reproduksi wanita yang dirancang dengan pendekatan medis klinis, antarmuka modern yang tenang, serta perlindungan privasi tingkat tinggi.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space16),

            // Section 2: Metodologi Prediksi & Sumber Data Valid (HIGHLIGHT UTAMA)
            _buildContentCard(
              title: 'Metodologi Prediksi & Dasar Ilmiah',
              icon: Icons.verified_rounded,
              isHighlight: true,
              children: [
                const Text(
                  'Perhitungan perkiraan siklus di aplikasi ini menggunakan algoritma berbasis konsensus ginekologi internasional:',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                _buildBulletPoint(
                  title: 'Data Parameter yang Digunakan:',
                  description:
                      'Hari Pertama Haid Terakhir (HPHT), rata-rata panjang siklus (21-45 hari), durasi perdarahan (2-10 hari), serta konfirmasi catatan riwayat aktual.',
                ),
                const SizedBox(height: 6),
                _buildBulletPoint(
                  title: 'Kalkulasi Ovulasi & Jendela Masa Subur:',
                  description:
                      'Menggunakan prinsip konstan fase luteal (rata-rata 14 hari sebelum hari pertama haid siklus berikutnya) dengan jendela masa subur 5 hari sebelum ovulasi hingga 1 hari setelah ovulasi.',
                ),
                const SizedBox(height: 6),
                _buildBulletPoint(
                  title: 'Standar Referensi Medis Otoritatif:',
                  description:
                      '• ACOG (American College of Obstetricians and Gynecologists) — Standar durasi fisiologis dan batasan menstruasi abnormal.\n'
                      '• WHO (World Health Organization) — Panduan kesehatan reproduksi dan kesuburan wanita.\n'
                      '• FIGO (International Federation of Gynecology and Obstetrics) — Klasifikasi regulasi dan nomenklatur siklus menstruasi.',
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space16),

            // Section 3: Layanan Konsultasi Kesehatan Bersama Ahli
            _buildContentCard(
              title: 'Konsultasi Kesehatan Bersama Ahli',
              icon: Icons.medical_services_outlined,
              children: [
                const Text(
                  'Kalmeda menyediakan ruang tanya jawab seputar kesehatan kewanitaan yang dapat Anda akses kapan saja:',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                _buildBulletPoint(
                  title: 'Bimbingan Dokter Spesialis Kandungan:',
                  description:
                      'Semua penjelasan, saran pereda nyeri haid, dan tips kesehatan disiapkan langsung dari panduan dokter kandungan berpengalaman.',
                ),
                const SizedBox(height: 6),
                _buildBulletPoint(
                  title: 'Perawatan Mandiri yang Aman:',
                  description:
                      'Membantu Anda memahami cara merawat tubuh di rumah, serta memberi tahu tanda-tanda kapan sebaiknya memeriksakan diri langsung ke dokter.',
                ),
                const SizedBox(height: 6),
                _buildBulletPoint(
                  title: 'Privasi Terjaga Sepenuhnya:',
                  description:
                      'Percakapan bersifat pribadi dan tidak pernah disimpan. Semua pesan otomatis terhapus saat Anda menutup aplikasi.',
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space16),

            // Section 4: Disclaimer Medis
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.space16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFD97706),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Pernyataan Penyangkalan Medis (Disclaimer)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Menstracker bertujuan sebagai sarana pencatatan pribadi dan edukasi kesehatan. Prediksi aplikasi ini bukan pengganti diagnosis medis formal atau metode kontrasepsi mutlak. Konsultasikan selalu keluhan atau perubahan siklus yang drastis dengan dokter spesialis obstetri & ginekologi (Sp.OG).',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFFB45309),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.space16),

            // Section 5: Pengembang Aplikasi
            _buildContentCard(
              title: 'Pengembang Aplikasi',
              icon: Icons.business_rounded,
              children: [
                const Text(
                  'Aplikasi Kalmeda dirancang dan dikembangkan secara resmi oleh Aldi Kurniawan & Wiyanda Susanti sebagai komitmen dalam menghadirkan inovasi teknologi kesehatan digital modern yang aman, cerdas, dan mudah digunakan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space24),

            // Footer Hak Cipta
            const Center(
              child: Column(
                children: [
                  Text(
                    '© 2026 Aldis Group. Seluruh hak cipta dilindungi.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Didedikasikan untuk Kesehatan Wanita Indonesia',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.space24),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isHighlight = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.space16),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFFFFDFE) : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(
          color: isHighlight
              ? const Color(0xFFFFDDE6)
              : const Color(0xFFF3EFF4),
          width: isHighlight ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBulletPoint({
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          description,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
