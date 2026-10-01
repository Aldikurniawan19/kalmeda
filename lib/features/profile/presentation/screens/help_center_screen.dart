import 'package:flutter/material.dart';
import 'package:menstracker/core/constants/app_colors.dart';
import 'package:menstracker/core/constants/app_sizes.dart';
import 'package:menstracker/features/chatbot/presentation/screens/chatbot_screen.dart';

/// Screen providing user help guides, searchable FAQs, and support contact channels.
class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _faqList = [
    {
      'question': 'Bagaimana cara aplikasi memprediksi siklus menstruasi saya?',
      'category': 'Prediksi Siklus',
      'answer':
          'Aplikasi menggunakan metode klinis berbasis durasi siklus dan tanggal Hari Pertama Haid Terakhir (HPHT). Prediksi ovulasi dan masa subur dihitung berdasarkan rata-rata panjang fase luteal (14 hari sebelum siklus berikutnya), sesuai pedoman ACOG (American College of Obstetricians and Gynecologists).',
    },
    {
      'question': 'Mengapa perkiraan tanggal haid saya bisa bergeser?',
      'category': 'Prediksi Siklus',
      'answer':
          'Siklus menstruasi wanita dapat bervariasi karena faktor hormonal, stres fisik/emosional, pola tidur, diet, atau obat-obatan. Setiap kali Anda mencatat tanggal haid aktual di Beranda, sistem akan mengadaptasi perhitungan untuk siklus berikutnya.',
    },
    {
      'question': 'Dari mana sumber saran dan artikel kesehatan di aplikasi ini?',
      'category': 'Validitas Medis',
      'answer':
          'Seluruh wawasan klinis, saran nutrisi, dan batasan normalitas menstruasi (seperti rentang normal 21-35 hari dan durasi 2-7 hari) disarikan dari standar medis terpercaya seperti ACOG, WHO, dan FIGO.',
    },
    {
      'question': 'Bagaimana cara memperbarui panjang siklus atau durasi haid saya?',
      'category': 'Pengaturan Akun',
      'answer':
          'Buka menu Profil > Informasi Pribadi. Di halaman tersebut, Anda dapat menggeser slider Panjang Siklus (21-45 hari) dan Durasi Menstruasi (2-10 hari), lalu tekan tombol "Simpan Perubahan".',
    },
    {
      'question': 'Apakah data kesehatan reproduksi saya aman?',
      'category': 'Privasi & Data',
      'answer':
          'Data Anda dienkripsi secara aman di database Firebase Firestore. Data siklus dan catatan gejala hanya digunakan untuk keperluan kalkulasi profil pribadi Anda dan tidak pernah diperjualbelikan kepada pihak ketiga.',
    },
    {
      'question': 'Apa yang harus dilakukan jika menstruasi berlangsung lebih dari 8 hari?',
      'category': 'Validitas Medis',
      'answer':
          'Jika pendarahan berlangsung lebih dari 8 hari berturut-turut (menstruasi berkepanjangan), aplikasi akan menampilkan peringatan klinis di Beranda. Kami menyarankan untuk berkonsultasi langsung dengan dokter spesialis obstetri dan ginekologi (Sp.OG).',
    },
    {
      'question': 'Dari mana sumber jawaban saat saya bertanya di menu konsultasi?',
      'category': 'Validitas Medis',
      'answer':
          'Semua jawaban dan saran kesehatan disusun langsung oleh dokter spesialis kandungan. Penjelasannya disajikan dengan bahasa yang sederhana dan mudah dipahami agar Anda bisa merawat kesehatan tubuh dengan tenang dan tepat.',
    },
    {
      'question': 'Apakah obrolan saya di menu konsultasi aman dan tersimpan?',
      'category': 'Privasi & Data',
      'answer':
          'Sangat aman. Percakapan Anda bersifat rahasia dan tidak pernah kami simpan. Saat Anda menutup aplikasi atau keluar dari menu, semua riwayat percakapan akan langsung terhapus otomatis demi menjaga privasi Anda.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqList.where((item) {
      final query = _searchQuery.toLowerCase();
      final q = item['question']!.toLowerCase();
      final a = item['answer']!.toLowerCase();
      final c = item['category']!.toLowerCase();
      return q.contains(query) || a.contains(query) || c.contains(query);
    }).toList();

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
          'Pusat Bantuan',
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
            // Search Input Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.space14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(color: const Color(0xFFF3EFF4)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value.trim()),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                  hintText: 'Cari topik bantuan atau pertanyaan...',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.space20),

            // Quick Category Cards
            const Text(
              'Kategori Bantuan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.space12),

            Row(
              children: [
                Expanded(
                  child: _buildCategoryCard(
                    icon: Icons.calendar_month_rounded,
                    title: 'Prediksi Siklus',
                    subtitle: 'Algoritma & Estimasi',
                    onTap: () => setState(() => _searchController.text = 'Prediksi Siklus'),
                  ),
                ),
                const SizedBox(width: AppSizes.space12),
                Expanded(
                  child: _buildCategoryCard(
                    icon: Icons.verified_user_outlined,
                    title: 'Validitas Medis',
                    subtitle: 'Standar ACOG/WHO',
                    onTap: () => setState(() => _searchController.text = 'Validitas Medis'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space12),
            Row(
              children: [
                Expanded(
                  child: _buildCategoryCard(
                    icon: Icons.lock_outline_rounded,
                    title: 'Privasi & Data',
                    subtitle: 'Keamanan Rekam Medis',
                    onTap: () => setState(() => _searchController.text = 'Privasi'),
                  ),
                ),
                const SizedBox(width: AppSizes.space12),
                Expanded(
                  child: _buildCategoryCard(
                    icon: Icons.tune_rounded,
                    title: 'Pengaturan Akun',
                    subtitle: 'Profil & Notifikasi',
                    onTap: () => setState(() => _searchController.text = 'Pengaturan Akun'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.space20),

            // Featured: Konsultan Klinis Reproduksi Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.space16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFF0F4),
                    Color(0xFFFFF7F9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                border: Border.all(color: const Color(0xFFFFDDE6)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFDDE6)),
                        ),
                        child: const Icon(
                          Icons.health_and_safety_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSizes.space10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanya Ahli Kesehatan Wanita',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Arahan Terpercaya dari Dokter Kandungan',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.space10),
                  const Text(
                    'Punya keluhan kram perut, haid terlambat, atau pertanyaan seputar tubuhmu? Tanyakan di sini dan dapatkan jawaban yang jelas, aman, dan menenangkan langsung dari panduan dokter spesialis kandungan.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSizes.space14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textWhite,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        ),
                      ),
                      onPressed: () => ChatbotScreen.open(context),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      label: const Text(
                        'Mulai Tanya Dokter',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.space24),

            // FAQ Accordion List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pertanyaan Umum (FAQ)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.space12),

            if (filteredFaqs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.space24),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(color: const Color(0xFFF3EFF4)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 40, color: AppColors.textSecondary),
                    SizedBox(height: AppSizes.space8),
                    Text(
                      'Pertanyaan tidak ditemukan.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ...filteredFaqs.map((faq) => _buildFaqItem(faq)),

            const SizedBox(height: AppSizes.space20),

            // Contact Support Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.space16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F4),
                borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                border: Border.all(color: const Color(0xFFFFDDE6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Masih Butuh Bantuan?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tim dukungan kami siap membantu menjawab pertanyaan teknis atau kendala pada akun Anda.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSizes.space12),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      const Text(
                        'support@menstracker.app',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
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

  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.space12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(color: const Color(0xFFF3EFF4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(Map<String, String> faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.space10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: const Color(0xFFF3EFF4)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textSecondary,
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSizes.space14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(AppSizes.space14, 0, AppSizes.space14, AppSizes.space14),
          title: Text(
            faq['question']!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          children: [
            Text(
              faq['answer']!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
