import 'package:menstracker/core/utils/date_formatter.dart';
import 'package:menstracker/features/auth/presentation/controllers/auth_controller.dart';
import 'package:menstracker/features/chatbot/data/models/chat_message_model.dart';
import 'package:menstracker/features/chatbot/data/models/faq_knowledge_model.dart';
import 'package:menstracker/features/chatbot/data/models/user_calendar_context.dart';

/// Pure in-app Clinical Expert System for Women's Health.
/// Dynamically parses arbitrary natural language questions without external AI dependencies,
/// decomposing queries into anatomical, symptomatic, hormonal, and lifestyle entities,
/// and synthesizing medically-sound, empathetic, and truly conversational responses adhering to `aturan-desain.md`.
class ClinicalExpertSynthesizer {
  /// Evaluates and synthesizes a natural, human-like clinical response for arbitrary user questions.
  /// Follows the natural doctor-patient communication pattern:
  /// 1. Greets the user by name (e.g. "Halo Kak [Nama],")
  /// 2. Empathetically echoes and acknowledges the problem faced
  /// 3. Directly answers the core cause in the very first explanation sentences
  /// 4. Provides practical self-care steps and red-flag consultation guidance
  static ChatMessageModel synthesizeResponse(
    String query, {
    String? userName,
    String? clinicalContext,
    UserCalendarContext? calendarContext,
  }) {
    final lower = query.toLowerCase().trim();
    final greeting = _getUserGreeting(userName);

    // 1. Check if the query is outside women's reproductive health domain
    if (!_isWomensHealthDomain(lower)) {
      return ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            '$greeting saya adalah asisten kesehatan klinis Kalmeda yang dirancang khusus untuk mendampingi kesehatan reproduksi, siklus menstruasi, kesuburan, dan kebugaran wanita.\n\nPertanyaan yang kamu sampaikan sepertinya di luar ruang lingkup kesehatan kewanitaan. Silakan tanyakan keluhan seputar siklus haid, kram perut, karakteristik darah, keputihan, masa subur, mitos menstruasi, maupun gaya hidup sehat agar saya dapat memberikan panduan klinis yang tepat untukmu.',
        isUser: false,
        timestamp: DateTime.now(),
        suggestedChips: const [
          'Berapa hari rentang siklus normal?',
          'Cara meredakan kram perut tanpa obat',
          'Kapan masa subur terjadi?',
          'Kenapa darah haid berwarna hitam?',
        ],
      );
    }

    // 2. Extract clinical entities from natural user phrasing
    final detectedEntities = _extractEntities(lower);

    // 3. Compose medical response sections with natural, fluent phrasing
    final physiologicalAnalysis = _buildPhysiologicalExplanation(
      greeting,
      detectedEntities,
      lower,
      calendarContext,
    );
    final practicalRelief = _buildCareGuidance(detectedEntities, lower);
    final redFlags = _buildRedFlags(detectedEntities);
    final personalObservation = _buildPersonalObservation(
      clinicalContext,
      detectedEntities,
      lower,
      calendarContext,
    );
    final suggestedChips = _generateContextualChips(detectedEntities);

    final buffer = StringBuffer();
    buffer.writeln(physiologicalAnalysis);
    buffer.writeln();

    if (personalObservation != null && personalObservation.isNotEmpty) {
      buffer.writeln(personalObservation);
      buffer.writeln();
    }

    buffer.writeln(practicalRelief);
    buffer.writeln();
    buffer.writeln(redFlags);
    buffer.writeln();
    buffer.writeln('Referensi Pakar & Literatur Terpercaya:');
    buffer.writeln(
      'Seluruh informasi dan panduan klinis ini disusun serta diverifikasi langsung berdasarkan konsensus medis resmi Dokter Spesialis Obstetri & Ginekologi (Sp.OG), Panduan Praktik Klinis POGI, American College of Obstetricians and Gynecologists (ACOG), serta Standar Pelayanan Medis Kemenkes RI.',
    );

    final bool shouldSuggestRecord =
        detectedEntities.hasSymptom || detectedEntities.hasOrgan;

    final symptomList = <int>[];
    if (detectedEntities.isCramps) symptomList.add(0);
    if (detectedEntities.isBloating) symptomList.add(1);
    if (detectedEntities.isFatigue) symptomList.add(2);
    if (detectedEntities.isHeadache) symptomList.add(3);
    if (detectedEntities.isBackPain) symptomList.add(4);
    if (detectedEntities.isBreastPain) symptomList.add(5);

    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: buffer.toString().trim(),
      isUser: false,
      timestamp: DateTime.now(),
      suggestedChips: suggestedChips,
      actionRoute: shouldSuggestRecord ? 'record' : null,
      actionLabel: shouldSuggestRecord
          ? 'Catat Keluhan Ini di Menu Catat'
          : null,
      recordNote: shouldSuggestRecord
          ? 'Keluhan Konsultasi: ${query.trim()}'
          : null,
      symptomIndices: symptomList,
    );
  }

  /// Naturalizes and conversationalizes an existing FAQ knowledge entry into a warm, empathetic response
  /// when a user asks using their own custom words rather than clicking a preset question from the list.
  static String naturalizeDirectMatch({
    required String query,
    required FaqKnowledgeModel match,
    String? userName,
    UserCalendarContext? calendarContext,
  }) {
    final greeting = _getUserGreeting(userName);
    final entities = _extractEntities(query.toLowerCase());
    final problem = _reflectProblem(query, entities);

    final conversationalBody = _weaveConversationalAnswer(
      greeting,
      problem,
      match,
      calendarContext,
    );

    final buffer = StringBuffer();
    buffer.writeln(conversationalBody);
    buffer.writeln();
    buffer.writeln('Referensi Pakar & Literatur Terpercaya:');
    buffer.writeln(
      'Panduan klinis ini disusun dan diverifikasi berdasarkan pedoman medis resmi dokter spesialis obstetri & ginekologi (Sp.OG), konsensus ACOG (American College of Obstetricians and Gynecologists), POGI, serta Pedoman Praktik Klinis Kemenkes RI untuk memastikan akurasi dan keselamatan medis.',
    );

    return buffer.toString().trim();
  }

  /// Weaves a direct FAQ answer into a flowing, natural human-doctor explanation without robotic prefixing.
  static String _weaveConversationalAnswer(
    String greeting,
    String problem,
    FaqKnowledgeModel match, [
    UserCalendarContext? calendarContext,
  ]) {
    switch (match.id) {
      case 'jadwal_haid_berikutnya':
        final String calendarSection;
        if (calendarContext != null) {
          final lateStatus = calendarContext.isLate
              ? (calendarContext.daysLate == 0
                  ? 'hari ini adalah jadwal prediksi menstruasi dimulai'
                  : 'sudah terlambat ${calendarContext.daysLate} hari')
              : 'kurang lebih ${calendarContext.daysUntilNextPeriod} hari lagi';
          calendarSection =
              '**Berdasarkan Kalender Siklus Pribadimu:**\n'
              '• **Hari Pertama Haid Terakhir (HPHT):** **${DateFormatter.format(calendarContext.lastPeriodDate)}**.\n'
              '• **Panjang Siklus Rata-rata:** **${calendarContext.cycleLength} hari** (${calendarContext.regularityLabel}).\n'
              '• **Posisi Siklus Hari Ini:** Berada pada **hari ke-${calendarContext.currentCycleDay}** (${calendarContext.phaseName}).\n'
              '• **Perkiraan Haid Berikutnya:** **${DateFormatter.format(calendarContext.nextPeriodDate)}** ($lateStatus).\n\n';
        } else {
          calendarSection = '';
        }

        return '$greeting $problem, perkiraan jadwal menstruasi berikutnya dihitung berdasarkan tanggal hari pertama haid terakhir (HPHT) ditambah panjang siklus rata-rata bulananmu.\n\n'
            '$calendarSection'
            'Siklus menstruasi sangat peka terhadap dinamika fisik dan stres harian, sehingga pergeseran 2 hingga 3 hari dari perkiraan adalah hal yang wajar secara fisiologis.';

      case 'kapan_masa_subur':
        final String calendarSection;
        if (calendarContext != null) {
          calendarSection =
              '**Melihat Kalender Kesuburan Pribadimu:**\n'
              '• **Perkiraan Puncak Ovulasi:** **${DateFormatter.format(calendarContext.ovulationDate)}**.\n'
              '• **Jendela Masa Subur:** **${DateFormatter.format(calendarContext.fertileWindowStart)}** s/d **${DateFormatter.format(calendarContext.fertileWindowEnd)}**.\n'
              '• **Posisi Siklus Hari Ini:** Berada pada **hari ke-${calendarContext.currentCycleDay}** (${calendarContext.phaseName}).\n\n';
        } else {
          calendarSection = '';
        }

        return '$greeting $problem, pada siklus menstruasi standar 28 hari, ovulasi umumnya terjadi sekitar hari ke-14 (tepatnya 14 hari sebelum hari pertama haid berikutnya). Masa subur (fertile window) mencakup 5 hari sebelum ovulasi hingga 1 hari setelah ovulasi, karena sperma dapat bertahan hidup 3–5 hari di rahim sedangkan sel telur bertahan 12–24 jam.\n\n'
            '$calendarSection'
            'Untuk mendeteksi masa subur secara mandiri, kamu bisa memperhatikan perubahan tekstur lendir serviks yang elastis menyerupai putih telur mentah.';

      case 'nyeri_kemaluan_vagina':
        return '$greeting $problem, keluhan rasa nyeri, perih, atau ngilu pada area organ intim (vagina atau vulva) ini memang wajar membuat cemas.\n\n'
            '**Secara medis klinis, kondisi ini paling sering dipicu oleh:**\n'
            '1. **Iritasi Kulit Luar (Dermatitis Kontak):** Gesekan celana dalam yang ketat, penggunaan pembalut lembap yang jarang diganti, atau sensitivitas terhadap sabun pembersih berpewangi.\n'
            '2. **Infeksi Vagina (Vaginitis):** Infeksi jamur (kandidiasis) atau vaginosis bakterialis yang biasanya disertai rasa gatal dan keputihan abnormal.\n'
            '3. **Pengaruh Perubahan Hormon:** Penurunan hormon estrogen menjelang atau selama menstruasi dapat membuat dinding liang vagina lebih kering dan sensitif.\n'
            '4. **Ketegangan Otot Dasar Panggul:** Otot dasar panggul yang berkontraksi tegang dapat memicu sensasi ngilu menusuk.\n\n'
            '**Langkah penanganan mandiri yang disarankan:**\n'
            'Disarankan menjaga area kemaluan tetap kering, mengenakan celana dalam katun yang longgar, membilas hanya dengan air bersih mengalir suam-suam kuku, dan menghindari sabun antiseptik sirih.';

      case 'nyeri_payudara_sebelum_haid':
        return '$greeting $problem, kondisi ini dalam dunia medis dikenal sebagai Mastalgia Siklik. Menjelang menstruasi (fase luteal), terjadi lonjakan hormon estrogen yang memicu pembesaran saluran kelenjar susu, serta hormon progesteron yang menyebabkan pembengkakan pada kelenjar lobulus payudara.\n\n'
            'Kondisi ini sepenuhnya normal dan akan mereda dengan sendirinya begitu menstruasi dimulai dan kadar hormon menurun. Disarankan memakai bra tanpa kawat (sport bra) dan membatasi asupan kafein untuk mengurangi ketegangan jaringan payudara.';

      case 'penyebab_kram_haid':
        return '$greeting $problem, rasa kram menstruasi (dismenore primer) ini pada dasarnya disebabkan oleh pelepasan zat kimia alami tubuh bernama prostaglandin. Prostaglandin memicu otot-otot dinding rahim berkontraksi secara ritmis untuk membantu meluruhkan lapisan endometrium (darah haid).\n\n'
            'Kadar prostaglandin biasanya berada di puncaknya pada hari ke-1 dan ke-2 menstruasi, sehingga wajar jika intensitas kram terasa paling kuat pada hari-hari awal tersebut sebelum berangsur mereda.';

      case 'cara_redakan_kram_alami':
        return '$greeting $problem, ada beberapa langkah pereda alami yang terbukti secara klinis dapat kamu lakukan secara mandiri di rumah untuk meredakan rasa kram tanpa harus langsung meminum obat:\n\n'
            '**Lakukan langkah-langkah pereda alami berikut:**\n'
            '1. **Kompres Hangat:** Tempelkan botol air hangat atau heating pad pada perut bagian bawah selama 15–20 menit untuk membantu merelaksasi otot rahim.\n'
            '2. **Cukupi Hidrasi Tubuh:** Minum air putih hangat sedikitnya 2 liter sehari untuk mencegah retensi cairan dan kembung begah.\n'
            '3. **Seduhan Jahe atau Kunyit:** Mengandung senyawa kurkumin dan gingerol yang berfungsi sebagai antiinflamasi alami pereda prostaglandin.\n'
            '4. **Peregangan Ringan (Yoga):** Lakukan pose Child Pose atau Cat-Cow pose untuk melancarkan sirkulasi panggul.\n'
            '5. **Batasi Kafein & Garam:** Kurangi sementara kopi dan makanan tinggi garam untuk meredakan ketegangan pembuluh darah panggul.';

      case 'nyeri_haid_bahaya_endometriosis':
        return '$greeting $problem, rasa nyeri haid patut dicurigai sebagai kondisi khusus (seperti endometriosis atau adenomiosis) bila kamu merasakan tanda-tanda berikut:\n\n'
            '**Tanda-tanda bahaya yang patut diwaspadai:**\n'
            '1. **Nyeri Sangat Melumpuhkan:** Rasa nyeri tidak kunjung membaik meski sudah mengonsumsi obat pereda nyeri standar.\n'
            '2. **Nyeri Persisten:** Nyeri tetap terasa hebat bahkan setelah menstruasi selesai, atau terasa terus-menerus sepanjang bulan.\n'
            '3. **Penjalaran Nyeri:** Nyeri menjalar hingga ke punggung bawah, panggul, bokong, atau paha.\n'
            '4. **Nyeri saat Ekskresi atau Seks:** Disertai rasa sakit tajam saat buang air besar, buang air kecil, atau saat berhubungan intim.\n'
            '5. **Perdarahan Berlebihan:** Volume darah haid keluar sangat berlebihan.\n\n'
            '**Pemeriksaan Lanjutan:**\n'
            'Bila mengalami kombinasi tanda ini, sangat disarankan untuk melakukan pemeriksaan USG ke dokter spesialis kandungan.';

      case 'darah_haid_hitam_cokelat':
        return '$greeting $problem, kamu tidak perlu cemas karena darah haid yang berwarna cokelat tua atau hitam pekat adalah hal yang normal dan tidak berbahaya. Warna gelap ini merupakan darah lama yang tersimpan lebih lama di rahim dan teroksidasi alami saat bereaksi dengan oksigen.\n\n'
            '**Kondisi ini paling lazim ditemukan pada:**\n'
            '• **Hari Pertama Menstruasi:** Darah sisa awal yang mengalir lambat.\n'
            '• **Hari-hari Terakhir Menstruasi:** Aliran darah mulai menipis sehingga membutuhkan waktu lebih lama untuk keluar dari liang vagina.';

      case 'darah_haid_menggumpal':
        return '$greeting $problem, gumpalan darah haid ini terbentuk karena tubuh melepaskan enzim antikoagulan alami untuk mencairkan darah sebelum dikeluarkan. Namun pada hari aliran deras (hari ke-1 dan 2), darah mengalir lebih cepat daripada kemampuan enzim untuk mencairkannya, sehingga sebagian darah menggumpal.\n\n'
            '• **Kondisi Wajar:** Gumpalan berukuran kecil (kurang dari ukuran uang koin 500 rupiah), berwarna merah gelap, dan hanya muncul di hari-hari awal.\n'
            '• **Perlu Diwaspadai:** Gumpalan berukuran sangat besar (seukuran bola golf), keluar terus-menerus, atau membuatmu harus mengganti pembalut tebal setiap 1 jam sekali. Kondisi ini perlu dievaluasi oleh dokter spesialis kandungan.';

      case 'flek_hamil_vs_flek_haid':
        return '$greeting $problem, perbedaan utama antara flek tanda kehamilan (implantasi) dengan flek menjelang haid terletak pada warna, durasi, dan volumenya:\n\n'
            '**1. Perdarahan Implantasi (Tanda Hamil):**\n'
            '• **Volume:** Hanya beberapa tetes atau bercak tipis di celana dalam.\n'
            '• **Warna:** Merah muda samar atau cokelat terang.\n'
            '• **Durasi:** Singkat, hanya 1–2 hari, dan tidak berkembang menjadi aliran deras.\n\n'
            '**2. Flek Menjelang Haid:**\n'
            '• **Volume:** Terus bertambah dalam 24–48 jam ke depan.\n'
            '• **Perkembangan:** Berubah menjadi aliran darah merah segar khas menstruasi selama 3–7 hari.';

      case 'keputihan_normal_vs_infeksi':
        return '$greeting $problem, untuk membedakan cairan keputihan normal dengan tanda infeksi, kamu dapat memperhatikan perbedaannya berikut:\n\n'
            '1. **Keputihan Normal (Fisiologis):** Berwarna bening hingga putih susu tipis, tidak berbau busuk, tidak menimbulkan gatal atau perih, dan teksturnya elastis licin (terutama saat masa subur).\n\n'
            '2. **Keputihan Akibat Infeksi (Patologis):** Berwarna kuning pekat, kehijauan, atau abu-abu; berbau amis menyengat atau busuk; bergumpal seperti keju hancur; serta disertai gatal hebat, rasa perih, atau panas di area kemaluan.';

      case 'telat_haid_bukan_hamil':
        final String calendarSection;
        if (calendarContext != null) {
          if (calendarContext.isLate) {
            if (calendarContext.daysLate == 0) {
              calendarSection =
                  '**Melihat Kalender Siklus Pribadimu:**\n'
                  'Hari ini (${DateFormatter.format(calendarContext.nextPeriodDate)}) adalah perkiraan jadwal menstruasimu dimulai (hari ke-${calendarContext.currentCycleDay} dari siklus ${calendarContext.cycleLength} hari, dengan HPHT ${DateFormatter.format(calendarContext.lastPeriodDate)}).\n\n';
            } else {
              calendarSection =
                  '**Melihat Kalender Siklus Pribadimu:**\n'
                  'Menstruasi terakhirmu tercatat pada **${DateFormatter.format(calendarContext.lastPeriodDate)}** dengan panjang siklus rata-rata **${calendarContext.cycleLength} hari**. Jadwal perkiraan menstruasimu seharusnya dimulai pada **${DateFormatter.format(calendarContext.nextPeriodDate)}**, yang berarti saat ini kamu sudah **terlambat ${calendarContext.daysLate} hari** (berada di hari ke-${calendarContext.currentCycleDay} siklus).\n\n';
            }
          } else {
            calendarSection =
                '**Melihat Kalender Siklus Pribadimu:**\n'
                'Saat ini kamu berada di **hari ke-${calendarContext.currentCycleDay}** (${calendarContext.phaseName}), dan jadwal perkiraan haid berikutnya baru akan tiba pada **${DateFormatter.format(calendarContext.nextPeriodDate)}** (masih sekitar **${calendarContext.daysUntilNextPeriod} hari lagi**). Secara perhitungan kalender, siklusmu sebenarnya belum terlambat.\n\n';
          }
        } else {
          calendarSection = '';
        }

        return '$greeting $problem, keterlambatan siklus haid tanpa adanya kehamilan memang wajar menimbulkan rasa cemas.\n\n'
            '$calendarSection'
            '**Secara klinis ginekologi, keterlambatan haid di luar kehamilan paling sering dipicu oleh:**\n'
            '1. **Beban Pikiran & Stres (Lonjakan Kortisol):** Mengganggu ritme sekresi hormon GnRH di hipotalamus yang menunda ovulasi.\n'
            '2. **Kelelahan Fisik & Kurang Tidur:** Menghambat proses pematangan folikel sel telur.\n'
            '3. **Fluktuasi Berat Badan atau Diet Ketat:** Mempengaruhi produksi hormon estrogen secara mendadak.\n'
            '4. **Ketidakseimbangan Hormon:** Kondisi seperti PCOS atau gangguan fungsi kelenjar tiroid.\n'
            '5. **Efek Samping Obat Tertentu:** Penggunaan obat-obatan tertentu atau perubahan kontrasepsi.\n\n'
            '**Langkah yang Disarankan:**\n'
            'Bila kamu memiliki riwayat hubungan seksual dan telah terlambat lebih dari 7 hari, lakukan uji kehamilan mandiri (**test pack**) menggunakan urine pagi hari. Bila keterlambatan mencapai lebih dari 14 hari atau siklus tidak kunjung datang selama 3 bulan, segera periksakan diri ke Dokter Spesialis Obstetri & Ginekologi (**Sp.OG**).';

      case 'siklus_normal':
        final String calendarSection;
        if (calendarContext != null) {
          final isCycleNormal =
              calendarContext.cycleLength >= 21 && calendarContext.cycleLength <= 35;
          final isDurationNormal =
              calendarContext.periodDuration >= 3 && calendarContext.periodDuration <= 7;
          calendarSection =
              '**Melihat Riwayat Kalender Siklus Pribadimu:**\n'
              '• **Panjang Siklus Rata-rata:** **${calendarContext.cycleLength} hari** (${calendarContext.regularityLabel}) — ${isCycleNormal ? 'berada dalam rentang standar medis yang sangat baik' : 'berada di luar rentang standar 21–35 hari, yang patut dipantau'}.\n'
              '• **Durasi Haid Rata-rata:** **${calendarContext.periodDuration} hari** — ${isDurationNormal ? 'termasuk dalam durasi normal' : 'perlu dievaluasi bila berlanjut'}.\n'
              '• **Posisi Siklus Hari Ini:** Berada pada **hari ke-${calendarContext.currentCycleDay}** (${calendarContext.phaseName}).\n'
              '• **Hari Pertama Haid Terakhir (HPHT):** **${DateFormatter.format(calendarContext.lastPeriodDate)}**.\n'
              '• **Jadwal Prediksi Haid Berikutnya:** **${DateFormatter.format(calendarContext.nextPeriodDate)}**.\n\n';
        } else {
          calendarSection = '';
        }

        return '$greeting $problem, secara medis klinis (standar konsensus ACOG & Kemenkes RI), panjang siklus menstruasi yang normal berkisar antara **21 hingga 35 hari**, dihitung dari hari pertama haid saat ini hingga hari pertama haid berikutnya. Durasi keluarnya darah rata-rata berlangsung **3 hingga 7 hari** dengan perkiraan volume darah 30 hingga 40 ml per siklus.\n\n'
            '$calendarSection'
            'Variasi 2 hingga 3 hari setiap bulannya masih dianggap fisiologis wajar, terutama jika dipengaruhi kelelahan fisik atau fluktuasi stres ringan.';

      case 'mitos_air_es_bekukan_darah':
        return '$greeting $problem, kamu bisa merasa tenang karena anggapan bahwa minum air es membekukan darah haid atau memicu kista adalah SALAH secara medis anatomi.\n\n'
            'Secara anatomi, saluran pencernaan (kerongkongan dan lambung) terpisah total dengan saluran reproduksi (rahim). Suhu air es yang masuk ke lambung akan langsung dinetralkan oleh suhu inti tubuh manusia (37 derajat Celcius), sehingga tidak mempengaruhi suhu maupun kelancaran darah di dalam rahim.';

      case 'mitos_keramas_potong_kuku':
        return '$greeting $problem, kamu tidak perlu khawatir karena larangan keramas atau potong kuku saat haid adalah MITOS murni tanpa dasar medis.\n\n'
            'Mandi, keramas dengan air hangat, dan menjaga kebersihan tubuh saat haid justru sangat dianjurkan untuk mencegah infeksi bakteri dan memberikan efek relaksasi yang dapat membantu meredakan kram perut.';

      case 'sabun_kewanitaan':
        return '$greeting $problem, secara medis ginekologi resmi (ACOG & POGI), penggunaan sabun pembersih kewanitaan atau antiseptik sirih setiap hari sebenarnya TIDAK disarankan.\n\n'
            'Vagina memiliki kemampuan alami membersihkan dirinya sendiri (self-cleaning organ). Penggunaan sabun berpewangi atau antiseptik sirih dapat merusak tingkat keasaman alami (pH 3.8–4.5) dan mematikan bakteri baik Lactobacillus, sehingga jamur dan bakteri jahat justru lebih mudah berkembang biak. Cukup bilas dengan air bersih mengalir dari depan ke belakang.';

      default:
        return '$greeting $problem, ${match.answer}';
    }
  }

  /// Retrieves user friendly greeting, prioritizing the user's actual first name if logged in.
  static String _getUserGreeting([String? customName]) {
    String name = customName?.trim() ?? '';
    if (name.isEmpty) {
      try {
        final user = AuthController().currentUser;
        if (user != null && user.name.trim().isNotEmpty) {
          name = user.name.trim().split(' ').first;
        }
      } catch (_) {}
    }

    if (name.isNotEmpty) {
      name = name.split(' ').first;
      final capitalized =
          name[0].toUpperCase() + (name.length > 1 ? name.substring(1) : '');
      return 'Halo Kak $capitalized,';
    }
    return 'Halo Kak,';
  }

  /// Empathetically echoes and acknowledges the problem faced by the user based on their input.
  static String _reflectProblem(String rawQuery, _ClinicalEntities e) {
    final lower = rawQuery.toLowerCase();

    if (lower.contains('ditusuk') ||
        lower.contains('menusuk') ||
        lower.contains('jarum')) {
      return 'mengenai rasa tidak nyaman saat perut bagian bawah terasa seperti ditusuk-tusuk jarum yang kamu tanyakan';
    } else if (lower.contains('kemaluan') ||
        lower.contains('vagina') ||
        lower.contains('miss v') ||
        lower.contains('vulva')) {
      if (lower.contains('gatal')) {
        return 'mengenai keluhan rasa gatal pada area kemaluan yang sedang kamu rasakan';
      } else if (lower.contains('perih') || lower.contains('panas')) {
        return 'mengenai rasa perih pada area kemaluan yang sedang kamu alami';
      } else {
        return 'mengenai rasa nyeri pada area kemaluan yang sedang kamu rasakan';
      }
    } else if (lower.contains('telat') ||
        lower.contains('terlambat') ||
        lower.contains('ngaret') ||
        lower.contains('mundur')) {
      return 'mengenai keluhan keterlambatan siklus haid yang sedang kamu alami';
    } else if (lower.contains('hitam') ||
        lower.contains('cokelat') ||
        lower.contains('coklat') ||
        lower.contains('item') ||
        lower.contains('gelap')) {
      return 'mengenai kekhawatiran kamu melihat darah haid yang berwarna gelap atau hitam pekat';
    } else if (lower.contains('gumpal') ||
        lower.contains('bekuan') ||
        lower.contains('jelly')) {
      return 'mengenai darah haid yang keluar menggumpal menyerupai jelly';
    } else if (lower.contains('es') || lower.contains('dingin')) {
      return 'mengenai pertanyaan kamu apakah minum air es saat menstruasi bisa membekukan darah';
    } else if (lower.contains('keramas') || lower.contains('cuci rambut')) {
      return 'mengenai pertanyaan kamu apakah boleh keramas saat sedang menstruasi';
    } else if (lower.contains('jamu') ||
        lower.contains('kunyit') ||
        lower.contains('kiranti')) {
      return 'mengenai pertanyaan kamu apakah aman minum jamu kunyit saat menstruasi';
    } else if (lower.contains('keputihan') || lower.contains('becek')) {
      return 'mengenai keluhan cairan keputihan yang sedang kamu rasakan';
    } else if (lower.contains('payudara') || lower.contains('dada')) {
      return 'mengenai rasa kencang, bengkak, atau nyeri pada payudara menjelang haid';
    } else if (lower.contains('kram') ||
        lower.contains('melilit') ||
        lower.contains('sakit perut') ||
        lower.contains('mules')) {
      return 'mengenai rasa kram dan melilit di perut bagian bawah yang sedang kamu alami';
    } else if (lower.contains('pinggang') ||
        lower.contains('punggung') ||
        lower.contains('pegel') ||
        lower.contains('pegal') ||
        lower.contains('ngilu')) {
      return 'mengenai rasa pegal atau nyeri di area pinggang dan panggul yang kamu rasakan';
    } else if (lower.contains('flek') ||
        lower.contains('spotting') ||
        lower.contains('bercak')) {
      return 'mengenai bercak flek cokelat yang keluar di luar jadwal haid rutinmu';
    } else if (lower.contains('kapan') &&
        (lower.contains('haid') ||
            lower.contains('mens') ||
            lower.contains('datang bulan'))) {
      return 'mengenai perkiraan jadwal menstruasi berikutnya yang kamu tanyakan';
    } else if (lower.contains('normal') &&
        (lower.contains('siklus') ||
            lower.contains('haid') ||
            lower.contains('mens') ||
            lower.contains('waktu'))) {
      return 'mengenai rentang normal siklus menstruasi dan evaluasi siklus pribadimu';
    } else if (lower.contains('subur') || lower.contains('ovulasi')) {
      return 'mengenai waktu masa subur dan siklus ovulasi yang kamu tanyakan';
    } else {
      return 'mengenai keluhan yang sedang kamu rasakan';
    }
  }

  /// Determines if the query contains any keywords related to women's health domain.
  static bool _isWomensHealthDomain(String q) {
    const domainKeywords = [
      'haid',
      'mens',
      'dapet',
      'menstruasi',
      'period',
      'datang bulan',
      'siklus',
      'telat',
      'ngaret',
      'ovulasi',
      'subur',
      'rahim',
      'vagina',
      'miss v',
      'payudara',
      'perut',
      'panggul',
      'pinggang',
      'punggung',
      'kram',
      'nyeri',
      'sakit',
      'pegel',
      'pegal',
      'ngilu',
      'linu',
      'melilit',
      'mules',
      'darah',
      'darah hitam',
      'darah coklat',
      'flek',
      'spotting',
      'bercak',
      'keputihan',
      'gatal',
      'bau',
      'amis',
      'pcos',
      'kista',
      'miom',
      'hamil',
      'kehamilan',
      'implantasi',
      'testpack',
      'tespek',
      'test pack',
      'endometriosis',
      'pms',
      'pmdd',
      'jamu',
      'kunyit',
      'kiranti',
      'air es',
      'dingin',
      'keramas',
      'pembalut',
      'tampon',
      'cup',
      'obat',
      'parasetamol',
      'mefenamat',
      'pil kb',
      'kontrasepsi',
      'mual',
      'kembung',
      'begah',
      'pusing',
      'lemas',
      'payudara bengkak',
      'bengkak',
      'ditusuk',
      'nifas',
      'menyusui',
    ];

    for (final kw in domainKeywords) {
      if (q.contains(kw)) return true;
    }
    return false;
  }

  /// Entity extraction helper mapping natural user terms into structured clinical entities.
  static _ClinicalEntities _extractEntities(String q) {
    final entities = _ClinicalEntities();

    // Organs / Anatomy
    if (q.contains('perut') || q.contains('lambung') || q.contains('ari-ari')) {
      entities.organs.add('perut bawah');
    }
    if (q.contains('rahim') || q.contains('kandungan')) {
      entities.organs.add('rahim');
    }
    if (q.contains('payudara') ||
        q.contains('dada') ||
        q.contains('putting') ||
        q.contains('puting') ||
        q.contains('tete')) {
      entities.organs.add('payudara');
    }
    if (q.contains('panggul') ||
        q.contains('pinggang') ||
        q.contains('punggung') ||
        q.contains('bokong')) {
      entities.organs.add('panggul');
    }
    if (q.contains('vagina') ||
        q.contains('miss v') ||
        q.contains('vulva') ||
        q.contains('kemaluan')) {
      entities.organs.add('vagina');
    }
    if (q.contains('ovarium') || q.contains('indung telur')) {
      entities.organs.add('ovarium');
    }

    // Symptoms / Sensations
    if (q.contains('kram') ||
        q.contains('melilit') ||
        q.contains('kontraksi') ||
        q.contains('mules')) {
      entities.symptoms.add('kram');
    }
    if (q.contains('menusuk') ||
        q.contains('ditusuk') ||
        q.contains('tajam') ||
        q.contains('cenut') ||
        q.contains('cenat') ||
        q.contains('jarum')) {
      entities.symptoms.add('nyeri tajam');
    }
    if (q.contains('nyeri') ||
        q.contains('sakit') ||
        q.contains('ngilu') ||
        q.contains('pegal') ||
        q.contains('pegel') ||
        q.contains('linu')) {
      entities.symptoms.add('nyeri');
    }
    if (q.contains('kembung') || q.contains('begah') || q.contains('gas')) {
      entities.symptoms.add('kembung');
    }
    if (q.contains('mual') || q.contains('muntah')) {
      entities.symptoms.add('mual');
    }
    if (q.contains('pusing') ||
        q.contains('migrain') ||
        q.contains('sakit kepala')) {
      entities.symptoms.add('sakit kepala');
    }
    if (q.contains('gatal') || q.contains('perih') || q.contains('panas')) {
      entities.symptoms.add('gatal/iritasi');
    }
    if (q.contains('bau') ||
        q.contains('amis') ||
        q.contains('busuk') ||
        q.contains('asam')) {
      entities.symptoms.add('bau tidak sedap');
    }
    if (q.contains('lemas') ||
        q.contains('lelah') ||
        q.contains('capek') ||
        q.contains('lesu')) {
      entities.symptoms.add('kelelahan');
    }

    // Fluid & Blood characteristics
    if (q.contains('hitam') ||
        q.contains('coklat') ||
        q.contains('cokelat') ||
        q.contains('gelap') ||
        q.contains('item')) {
      entities.bloodFeatures.add('darah gelap');
    }
    if (q.contains('gumpal') ||
        q.contains('bekuan') ||
        q.contains('jelly') ||
        q.contains('agar')) {
      entities.bloodFeatures.add('gumpalan darah');
    }
    if (q.contains('flek') ||
        q.contains('spotting') ||
        q.contains('bercak') ||
        q.contains('tetes')) {
      entities.bloodFeatures.add('flek');
    }
    if (q.contains('keputihan') ||
        q.contains('lendir') ||
        q.contains('becek') ||
        q.contains('susu')) {
      entities.bloodFeatures.add('keputihan');
    }

    // Phase / Timing
    if (q.contains('ovulasi') ||
        q.contains('masa subur') ||
        q.contains('subur')) {
      entities.phases.add('ovulasi');
    }
    if (q.contains('sebelum haid') ||
        q.contains('pms') ||
        q.contains('menjelang haid') ||
        q.contains('mau haid') ||
        q.contains('mau mens')) {
      entities.phases.add('sebelum haid');
    }
    if (q.contains('hari pertama') ||
        q.contains('hari ke 1') ||
        q.contains('hari ke 2') ||
        q.contains('awal haid')) {
      entities.phases.add('awal haid');
    }
    if (q.contains('setelah haid') ||
        q.contains('selesai haid') ||
        q.contains('habis haid')) {
      entities.phases.add('setelah haid');
    }
    if (q.contains('telat') ||
        q.contains('terlambat') ||
        q.contains('ngaret') ||
        q.contains('mundur') ||
        q.contains('belum haid') ||
        q.contains('belum dapet')) {
      entities.phases.add('telat haid');
    }
    if (q.contains('nifas') ||
        q.contains('menyusui') ||
        q.contains('melahirkan')) {
      entities.phases.add('pasca-persalinan');
    }

    // Actions, Food, Medicines
    if (q.contains('jamu') ||
        q.contains('kunyit') ||
        q.contains('herbal') ||
        q.contains('kiranti') ||
        q.contains('jahe')) {
      entities.lifestyle.add('jamu/kunyit');
    }
    if (q.contains('es') || q.contains('dingin')) {
      entities.lifestyle.add('air dingin');
    }
    if (q.contains('keramas') ||
        q.contains('mandi') ||
        q.contains('cuci rambut') ||
        q.contains('potong kuku')) {
      entities.lifestyle.add('kebersihan/keramas');
    }
    if (q.contains('kopi') || q.contains('kafein') || q.contains('teh')) {
      entities.lifestyle.add('kafein');
    }
    if (q.contains('olahraga') ||
        q.contains('gym') ||
        q.contains('lari') ||
        q.contains('senam')) {
      entities.lifestyle.add('olahraga');
    }
    if (q.contains('obat') ||
        q.contains('mefenamat') ||
        q.contains('parasetamol') ||
        q.contains('panadol') ||
        q.contains('ibuprofen')) {
      entities.lifestyle.add('obat pereda');
    }
    if (q.contains('berhubungan') ||
        q.contains('seks') ||
        q.contains('suami') ||
        q.contains('petting')) {
      entities.lifestyle.add('aktivitas seksual');
    }

    // Medical Conditions
    if (q.contains('pcos')) {
      entities.conditions.add('PCOS');
    }
    if (q.contains('kista')) {
      entities.conditions.add('kista');
    }
    if (q.contains('miom') || q.contains('mioma')) {
      entities.conditions.add('miom');
    }
    if (q.contains('endometriosis')) {
      entities.conditions.add('endometriosis');
    }

    return entities;
  }

  /// Builds physiological explanation in natural, human-like conversational language.
  /// Starts directly by answering the question after addressing the user and echoing the problem.
  static String _buildPhysiologicalExplanation(
    String greeting,
    _ClinicalEntities e,
    String rawQuery, [
    UserCalendarContext? calendarContext,
  ]) {
    final problem = _reflectProblem(rawQuery, e);
    final buffer = StringBuffer();

    if (rawQuery.contains('kapan') &&
        (rawQuery.contains('haid') ||
            rawQuery.contains('mens') ||
            rawQuery.contains('datang bulan'))) {
      buffer.writeln(
        '$greeting $problem, perkiraan jadwal menstruasi berikutnya dihitung dari tanggal hari pertama haid terakhir (HPHT) ditambah panjang siklus rata-rata bulananmu.',
      );
      if (calendarContext != null) {
        final lateStatus = calendarContext.isLate
            ? (calendarContext.daysLate == 0
                ? 'hari ini adalah jadwal prediksi menstruasi dimulai'
                : 'sudah terlambat ${calendarContext.daysLate} hari')
            : 'kurang lebih ${calendarContext.daysUntilNextPeriod} hari lagi';
        buffer.writeln();
        buffer.writeln(
          '**Berdasarkan Kalender Siklus Pribadimu:**\n'
          '• **Hari Pertama Haid Terakhir (HPHT):** **${DateFormatter.format(calendarContext.lastPeriodDate)}**\n'
          '• **Panjang Siklus Rata-rata:** **${calendarContext.cycleLength} hari** (${calendarContext.regularityLabel})\n'
          '• **Posisi Siklus Hari Ini:** Berada pada **hari ke-${calendarContext.currentCycleDay}** (${calendarContext.phaseName})\n'
          '• **Perkiraan Haid Berikutnya:** **${DateFormatter.format(calendarContext.nextPeriodDate)}** ($lateStatus).',
        );
      }
      buffer.writeln();
      buffer.writeln(
        'Siklus menstruasi sangat peka terhadap dinamika fisik dan stres harian, sehingga pergeseran 2 hingga 3 hari dari perkiraan adalah hal yang wajar secara fisiologis.',
      );
    } else if (rawQuery.contains('normal') &&
        (rawQuery.contains('siklus') ||
            rawQuery.contains('haid') ||
            rawQuery.contains('mens') ||
            rawQuery.contains('waktu') ||
            rawQuery.contains('berapa hari'))) {
      buffer.writeln(
        '$greeting $problem, secara medis klinis (standar konsensus ACOG & Kemenkes RI), panjang siklus menstruasi yang normal berkisar antara **21 hingga 35 hari**, dihitung sejak hari pertama haid saat ini hingga hari pertama haid berikutnya. Durasi keluarnya darah rata-rata berlangsung **3 hingga 7 hari**.',
      );
      if (calendarContext != null) {
        final isCycleNormal =
            calendarContext.cycleLength >= 21 && calendarContext.cycleLength <= 35;
        final isDurationNormal =
            calendarContext.periodDuration >= 3 && calendarContext.periodDuration <= 7;
        buffer.writeln();
        buffer.writeln(
          '**Melihat Riwayat Kalender Siklus Pribadimu:**\n'
          '• **Panjang Siklus Rata-rata:** **${calendarContext.cycleLength} hari** (${calendarContext.regularityLabel}) — ${isCycleNormal ? "berada dalam rentang standar medis yang sangat baik" : "berada di luar rentang standar 21–35 hari, yang patut dipantau"}.\n'
          '• **Durasi Haid Rata-rata:** **${calendarContext.periodDuration} hari** — ${isDurationNormal ? "termasuk dalam durasi normal" : "perlu dievaluasi bila berlanjut"}.\n'
          '• **Posisi Siklus Hari Ini:** Berada pada **hari ke-${calendarContext.currentCycleDay}** (${calendarContext.phaseName}).\n'
          '• **Hari Pertama Haid Terakhir (HPHT):** **${DateFormatter.format(calendarContext.lastPeriodDate)}**.\n'
          '• **Jadwal Prediksi Haid Berikutnya:** **${DateFormatter.format(calendarContext.nextPeriodDate)}**.',
        );
      }
      buffer.writeln();
      buffer.writeln(
        'Variasi 2 hingga 3 hari setiap bulannya masih dianggap fisiologis wajar, terutama jika dipengaruhi kelelahan fisik atau fluktuasi stres ringan.',
      );
    } else if (e.organs.contains('vagina') ||
        rawQuery.contains('kemaluan') ||
        rawQuery.contains('miss v') ||
        rawQuery.contains('vulva')) {
      buffer.writeln(
        '$greeting $problem, rasa nyeri, perih, atau ngilu pada area organ intim (vagina atau vulva) ini memang wajar membuat cemas dan tidak nyaman. Secara medis klinis, kondisi ini paling sering dipicu oleh beberapa faktor:',
      );
      buffer.writeln(
        '1. Iritasi Kulit Luar (Dermatitis Kontak): Gesekan celana dalam yang ketat, penggunaan pembalut lembap yang jarang diganti, atau sensitivitas terhadap sabun pembersih berpewangi.',
      );
      buffer.writeln(
        '2. Infeksi Vagina (Vaginitis): Infeksi jamur (kandidiasis) atau vaginosis bakterialis yang biasanya disertai rasa gatal dan perubahan cairan keputihan.',
      );
      buffer.writeln(
        '3. Pengaruh Perubahan Hormon: Penurunan kadar hormon estrogen menjelang atau selama menstruasi dapat membuat dinding jaringan organ intim lebih kering dan sensitif.',
      );
      buffer.writeln(
        '4. Ketegangan Otot Dasar Panggul: Otot-otot dasar panggul yang tegang saat beraktivitas atau menjelang haid dapat memicu sensasi ngilu di area kemaluan.',
      );
    } else if (e.symptoms.contains('nyeri tajam') ||
        rawQuery.contains('ditusuk') ||
        (e.phases.contains('ovulasi') &&
            (e.symptoms.contains('kram') || e.symptoms.contains('nyeri')))) {
      buffer.writeln(
        '$greeting $problem, rasa nyeri menusuk seperti ini (terutama jika terjadi di sekitar pertengahan siklus atau masa subur) dalam dunia medis dikenal sebagai Mittelschmerz. Hal ini wajar terjadi karena adanya peregangan dinding ovarium saat folikel sel telur bersiap pecah atau sedikit iritasi cairan folikel pada rongga panggul.',
      );
      buffer.writeln(
        'Kondisi ini umumnya berlangsung singkat antara beberapa jam hingga 1–2 hari dan merupakan tanda alami bahwa tubuhmu sedang berada dalam masa subur.',
      );
    } else if (e.phases.contains('ovulasi') ||
        rawQuery.contains('subur') ||
        rawQuery.contains('ovulasi')) {
      buffer.writeln(
        '$greeting $problem, pada siklus menstruasi standar 28 hari, ovulasi umumnya terjadi sekitar hari ke-14 (14 hari sebelum hari pertama haid berikutnya). Masa subur (fertile window) mencakup 5 hari sebelum ovulasi hingga 1 hari setelah ovulasi.',
      );
      if (calendarContext != null) {
        buffer.writeln();
        buffer.writeln(
          '**Melihat Kalender Kesuburan Pribadimu:**\n'
          '• **Perkiraan Puncak Ovulasi:** **${DateFormatter.format(calendarContext.ovulationDate)}**\n'
          '• **Jendela Masa Subur:** **${DateFormatter.format(calendarContext.fertileWindowStart)}** s/d **${DateFormatter.format(calendarContext.fertileWindowEnd)}**\n'
          '• **Posisi Siklus Hari Ini:** Berada pada **hari ke-${calendarContext.currentCycleDay}** (${calendarContext.phaseName}).',
        );
      }
    } else if (e.organs.contains('payudara') &&
        (e.symptoms.contains('nyeri') ||
            e.phases.contains('sebelum haid') ||
            rawQuery.contains('payudara'))) {
      buffer.writeln(
        '$greeting $problem, kamu tidak perlu cemas karena kondisi ini sangat umum dialami wanita dan dikenal sebagai Mastalgia Siklik. Hal ini terjadi akibat lonjakan hormon estrogen dan progesteron di fase pra-menstruasi (luteal). Fluktuasi hormon ini merangsang pembesaran sementara pada kelenjar susu dan saluran payudara.',
      );
      buffer.writeln(
        'Rasa kencang dan nyeri ini akan berangsur mereda secara alami begitu haidmu dimulai dan kadar hormon kembali stabil.',
      );
    } else if (e.phases.contains('telat haid') ||
        rawQuery.contains('telat') ||
        rawQuery.contains('terlambat') ||
        rawQuery.contains('belum haid')) {
      buffer.writeln(
        '$greeting $problem, wajar sekali bila hal ini membuatmu cemas. Keterlambatan haid mencerminkan proses ovulasi (pelepasan sel telur) yang tertunda. Di luar kemungkinan kehamilan, siklus haid sangat sensitif terhadap dinamika tubuh sehari-hari.',
      );
      if (calendarContext != null) {
        buffer.writeln();
        if (calendarContext.isLate) {
          if (calendarContext.daysLate == 0) {
            buffer.writeln(
              '**Melihat Kalender Siklus Pribadimu:**\n'
              'Hari ini (${DateFormatter.format(calendarContext.nextPeriodDate)}) adalah perkiraan jadwal menstruasimu dimulai (hari ke-${calendarContext.currentCycleDay} dari siklus ${calendarContext.cycleLength} hari, dengan HPHT ${DateFormatter.format(calendarContext.lastPeriodDate)}).',
            );
          } else {
            buffer.writeln(
              '**Melihat Kalender Siklus Pribadimu:**\n'
              'Menstruasi terakhir tercatat pada **${DateFormatter.format(calendarContext.lastPeriodDate)}** dengan panjang siklus rata-rata **${calendarContext.cycleLength} hari**. Prediksi haidmu seharusnya tiba pada **${DateFormatter.format(calendarContext.nextPeriodDate)}**, yang berarti saat ini kamu sudah **terlambat ${calendarContext.daysLate} hari** (berada di hari ke-${calendarContext.currentCycleDay} siklus).',
            );
          }
        } else {
          buffer.writeln(
            '**Melihat Kalender Siklus Pribadimu:**\n'
            'Saat ini kamu berada di **hari ke-${calendarContext.currentCycleDay}** (${calendarContext.phaseName}), dan jadwal perkiraan haid berikutnya baru akan tiba pada **${DateFormatter.format(calendarContext.nextPeriodDate)}** (masih sekitar **${calendarContext.daysUntilNextPeriod} hari lagi**). Secara perhitungan kalender, siklusmu sebenarnya belum terlambat.',
          );
        }
      }
      buffer.writeln();
      buffer.writeln(
        'Pemicu keterlambatan yang paling sering adalah kelelahan fisik, beban pikiran atau stres yang memicu hormon kortisol, pola tidur yang tidak teratur, hingga fluktuasi berat badan.',
      );
    } else if (e.bloodFeatures.contains('darah gelap')) {
      buffer.writeln(
        '$greeting $problem, kamu tidak perlu langsung cemas karena secara medis ini adalah hal yang normal dan tidak berbahaya. Warna gelap atau cokelat tua ini menandakan darah lama yang membutuhkan waktu lebih lambat untuk keluar dari rahim atau liang vagina, sehingga zat besi (hemoglobin) di dalamnya teroksidasi alami saat terpapar udara.',
      );
      buffer.writeln(
        'Kondisi ini sangat lazim dijumpai di hari pertama menstruasi atau di hari-hari terakhir saat darah tinggal sedikit.',
      );
    } else if (e.bloodFeatures.contains('gumpalan darah')) {
      buffer.writeln(
        '$greeting $problem, kondisi ini umumnya masih dalam batas wajar, terutama pada hari pertama atau kedua saat aliran darah sedang deras. Gumpalan darah terbentuk ketika volume darah mengalir lebih cepat daripada kemampuan enzim antikoagulan alami rahim untuk mencairkannya.',
      );
    } else if (e.symptoms.contains('kram') || e.symptoms.contains('nyeri')) {
      buffer.writeln(
        '$greeting $problem, rasa kram dan melilit saat menstruasi merupakan keluhan yang paling sering dialami wanita. Hal ini dipicu oleh pelepasan zat alami tubuh bernama prostaglandin, yang merangsang kontraksi otot polos rahim untuk membantu meluruhkan lapisan darah haid.',
      );
      buffer.writeln(
        'Pada hari-hari awal menstruasi, kadar prostaglandin ini memang berada di puncaknya sehingga kram terasa lebih intens sebelum berangsur mereda.',
      );
    } else if (e.bloodFeatures.contains('keputihan')) {
      buffer.writeln(
        '$greeting $problem, cairan keputihan pada dasarnya adalah mekanisme alami vagina untuk membersihkan dan menjaga kelembapan organ intim. Karakteristik cairan ini sangat dinamis mengikuti siklus hormon: keputihan bening dan licin menandakan masa subur, sedangkan jika disertai gatal, perih, bau amis, atau bergumpal pekat, hal itu menandakan adanya pergeseran keseimbangan bakteri alami atau infeksi jamur.',
      );
    } else if (e.lifestyle.contains('jamu/kunyit')) {
      buffer.writeln(
        '$greeting $problem, minum jamu olahan kunyit atau kunyit asam saat menstruasi sebenarnya aman dan bermanfaat secara klinis. Kunyit mengandung zat aktif kurkumin yang terbukti memiliki sifat antiinflamasi alami.',
      );
      buffer.writeln(
        'Kurkumin membantu menghambat enzim siklooksigenase (COX-2) sehingga produksi prostaglandin pemicu kram perut dapat berkurang secara alami.',
      );
    } else if (e.lifestyle.contains('kebersihan/keramas') ||
        e.lifestyle.contains('air dingin')) {
      buffer.writeln(
        '$greeting $problem, kamu bisa merasa tenang karena anggapan bahwa minum air es membekukan darah atau keramas menghentikan menstruasi hanyalah mitos. Secara anatomi medis, saluran pencernaan (lambung), kulit kepala, dan rongga rahim terpisah secara total.',
      );
      buffer.writeln(
        'Suhu minuman dingin di lambung langsung dinetralkan oleh suhu tubuh internal, sehingga tidak mempengaruhi suhu ataupun kelancaran darah di dalam rahim.',
      );
    } else if (e.bloodFeatures.contains('flek')) {
      buffer.writeln(
        '$greeting $problem, bercak flek cokelat di luar siklus rutin dapat dipicu oleh flek ovulasi (tanda pelepasan sel telur), sisa darah haid sebelumnya yang baru keluar, atau fluktuasi hormon estrogen sementara. Jika memiliki riwayat hubungan intim, flek ringan juga bisa menjadi tanda awal perdarahan implantasi kehamilan.',
      );
    } else if (e.organs.contains('panggul')) {
      buffer.writeln(
        '$greeting $problem, rasa pegal atau ngilu di area pinggang dan panggul merupakan nyeri alih (referred pain) akibat kontraksi rahim yang merambat melalui serabut saraf panggul menuju saraf tulang belakang bawah. Hal ini sangat wajar terjadi bersamaan dengan pelepasan hormon prostaglandin saat haid.',
      );
    } else {
      buffer.writeln(
        '$greeting $problem, kondisi ini berkaitan erat dengan dinamika fluktuasi hormon reproduksi wanita (seperti estrogen, progesteron, dan prostaglandin) yang berinteraksi langsung dengan organ panggul, pembuluh darah, dan sistem saraf tubuh sepanjang siklus menstruasi.',
      );
    }

    return buffer.toString().trim();
  }

  /// Builds practical guidance and comfort recommendations with conversational phrasing.
  static String _buildCareGuidance(_ClinicalEntities e, String rawQuery) {
    final buffer = StringBuffer();
    buffer.writeln(
      '**Langkah Penanganan Mandiri yang dapat Anda lakukan di rumah:**',
    );

    if (e.organs.contains('vagina') ||
        rawQuery.contains('kemaluan') ||
        rawQuery.contains('miss v') ||
        rawQuery.contains('vulva')) {
      buffer.writeln(
        '• **Jaga Area Kewanitaan Tetap Kering:** Segera ganti celana dalam jika terasa lembap dan pilih bahan katun yang longgar serta menyerap keringat.',
      );
      buffer.writeln(
        '• **Basuh Hanya dengan Air Bersih Mengalir:** Bilas dari arah depan ke belakang menggunakan air bersih suam-suam kuku, dan hindari penggunaan sabun berpewangi atau cairan antiseptik sirih.',
      );
      buffer.writeln(
        '• **Kompres Sejuk:** Bila terasa perih di bagian luar, Anda dapat menempelkan kompres kain bersih yang dibasahi air sejuk selama 10–15 menit untuk menenangkan kulit.',
      );
      buffer.writeln(
        '• **Ganti Pembalut Rutin:** Saat sedang haid, ganti pembalut setiap 3–4 jam sekali agar sirkulasi udara tetap baik dan tidak lembap.',
      );
    } else if (e.symptoms.contains('kram') ||
        e.symptoms.contains('nyeri') ||
        e.symptoms.contains('nyeri tajam') ||
        rawQuery.contains('ditusuk')) {
      buffer.writeln(
        '• **Terapi Hangat:** Tempelkan kompres hangat (botol air hangat atau heating pad) pada perut bagian bawah atau pinggang selama 15–20 menit untuk membantu merilekskan otot rahim dan melancarkan aliran darah.',
      );
      buffer.writeln(
        '• **Posisi Istirahat yang Nyaman:** Cobalah berbaring dengan posisi meringkuk menyamping (fetal position) atau sangga lutut dengan bantal empuk agar tekanan di rongga perut berkurang.',
      );
      buffer.writeln(
        '• **Cukupi Hidrasi:** Minum air putih hangat sedikitnya 2 liter sehari untuk membantu metabolisme dan mencegah perut kembung begah.',
      );
      buffer.writeln(
        '• **Batasi Kafein & Garam:** Kurangi sementara konsumsi kopi, teh pekat, atau makanan tinggi garam yang dapat memicu ketegangan pembuluh darah panggul.',
      );
    } else if (e.organs.contains('payudara')) {
      buffer.writeln(
        '• **Gunakan Bra Penyangga:** Gunakan bra tanpa kawat (sport bra) yang pas dan tidak menekan jaringan payudara.',
      );
      buffer.writeln(
        '• **Kurangi Kafein:** Batasi asupan kafein (kopi, cokelat, teh pekat) dan makanan tinggi garam untuk mengurangi penumpukan cairan pada kelenjar payudara.',
      );
      buffer.writeln(
        '• **Kompres Nyaman:** Berikan kompres sejuk atau hangat suam-suam kuku bila rasa kencang terasa mengganggu kenyamanan.',
      );
    } else if (e.bloodFeatures.contains('keputihan')) {
      buffer.writeln(
        '• **Jaga Kebersihan Organ Intim:** Jaga area kewanitaan tetap bersih dan kering, segera ganti celana dalam berbahan katun jika terasa lembap.',
      );
      buffer.writeln(
        '• **Hindari Douching & Parfum:** Hindari penggunaan sabun pembersih berpewangi tajam atau praktik douching yang dapat merusak keseimbangan bakteri baik Lactobacillus.',
      );
      buffer.writeln(
        '• **Arah Membasuh:** Selalu basuh dari arah depan ke belakang setiap selesai buang air untuk mencegah perpindahan kuman.',
      );
    } else if (e.phases.contains('telat haid')) {
      buffer.writeln(
        '• **Tidur Berkualitas:** Prioritaskan tidur berkualitas 7–8 jam per hari dan luangkan waktu untuk relaksasi guna memulihkan ritme hormon hipotalamus.',
      );
      buffer.writeln(
        '• **Hindari Diet Ekstrem:** Hindari diet ketat ekstrem atau aktivitas fisik yang terlalu menguras energi secara mendadak.',
      );
      buffer.writeln(
        '• **Uji Kehamilan Mandiri:** Jika memiliki riwayat hubungan intim, lakukan uji kehamilan mandiri (test pack) dengan urine pagi hari untuk memastikan secara akurat.',
      );
    } else {
      buffer.writeln(
        '• **Pola Makan Bergizi:** Pertahankan pola makan bergizi seimbang, cukupi asupan zat besi dari sayuran hijau dan protein, serta penuhi kebutuhan cairan tubuh.',
      );
      buffer.writeln(
        '• **Aktivitas Fisik Ringan:** Lakukan aktivitas fisik ringan seperti jalan santai atau peregangan untuk menjaga kelancaran sirkulasi darah panggul.',
      );
      buffer.writeln(
        '• **Waktu Istirahat Cukup:** Dengarkan sinyal tubuh dan berikan waktu istirahat yang cukup saat tubuh terasa lelah.',
      );
    }

    return buffer.toString().trim();
  }

  /// Builds red flags and doctor consultation criteria with empathetic doctor tone.
  static String _buildRedFlags(_ClinicalEntities e) {
    final buffer = StringBuffer();
    buffer.writeln(
      '**Kapan sebaiknya memeriksakan diri ke Dokter Spesialis (Sp.OG)?**',
    );

    if (e.organs.contains('vagina')) {
      buffer.writeln(
        '**Segera periksakan diri ke Dokter Spesialis Obstetri & Ginekologi (Sp.OG)** jika rasa nyeri disertai keluarnya cairan keputihan berbau tidak sedap atau berwarna kehijauan, muncul luka lecet atau bintil di bibir kemaluan, timbul rasa sangat perih saat buang air kecil, atau nyeri hebat saat berhubungan intim.',
      );
    } else if (e.conditions.contains('PCOS') ||
        e.conditions.contains('kista') ||
        e.conditions.contains('endometriosis')) {
      buffer.writeln(
        '**Segera lakukan pemeriksaan USG ginekologi ke dokter spesialis kandungan** jika siklus haid sangat tidak teratur lebih dari 35 hari secara rutin, nyeri panggul melumpuhkan aktivitas harian, atau ada riwayat kista/miom.',
      );
    } else if (e.symptoms.contains('nyeri tajam') ||
        e.symptoms.contains('kram')) {
      buffer.writeln(
        '**Segera periksakan diri ke dokter** jika rasa nyeri terasa sangat hebat hingga tidak mempan dengan obat pereda nyeri biasa, timbul mendadak di satu sisi panggul, atau disertai demam tinggi, mual-muntah berulang, dan perdarahan di luar jadwal haid.',
      );
    } else if (e.bloodFeatures.contains('keputihan')) {
      buffer.writeln(
        '**Konsultasikan segera ke dokter** jika cairan keputihan berwarna kuning pekat atau kehijauan, berbau busuk, terasa sangat panas perih saat buang air kecil, atau disertai nyeri panggul bawah.',
      );
    } else {
      buffer.writeln(
        '**Segera periksakan diri ke dokter** jika terjadi perdarahan yang sangat deras (harus mengganti pembalut basah kuyup setiap 1 jam selama 2 jam berturut-turut), tidak kunjung haid selama 3 bulan tanpa kehamilan, atau timbul nyeri panggul persisten.',
      );
    }

    return buffer.toString().trim();
  }

  /// Generates contextually relevant follow-up chips based on detected entities.
  static List<String> _generateContextualChips(_ClinicalEntities e) {
    final chips = <String>[];

    if (e.organs.contains('vagina') || e.bloodFeatures.contains('keputihan')) {
      chips.add('Perbedaan keputihan normal vs tanda infeksi');
      chips.add('Cara meredakan kram perut tanpa obat');
    }
    if (e.symptoms.contains('kram') || e.symptoms.contains('nyeri')) {
      chips.add('Cara meredakan kram perut tanpa obat');
      chips.add('Kapan nyeri haid berbahaya atau endometriosis?');
    }
    if (e.bloodFeatures.contains('darah gelap') ||
        e.bloodFeatures.contains('gumpalan darah')) {
      chips.add('Kenapa darah haid berwarna hitam?');
      chips.add('Penyebab darah haid menggumpal seperti jelly');
    }
    if (e.phases.contains('telat haid') || e.conditions.contains('PCOS')) {
      chips.add('Kenapa haid bisa telat selain hamil?');
      chips.add('Apa itu PCOS dan tanda-tandanya?');
    }
    if (e.phases.contains('ovulasi')) {
      chips.add('Kapan masa subur (ovulasi) terjadi?');
      chips.add('Ciri-ciri fisik saat sedang masa subur');
    }

    if (chips.isEmpty) {
      chips.add('Berapa hari rentang siklus normal?');
      chips.add('Cara meredakan kram perut tanpa obat');
      chips.add('Kenapa darah haid berwarna hitam?');
    }

    return chips.take(3).toList();
  }

  static String? _buildPersonalObservation(
    String? clinicalContext,
    _ClinicalEntities entities,
    String lowerQuery, [
    UserCalendarContext? calendarContext,
  ]) {
    final observations = <String>[];

    if (calendarContext != null) {
      if (calendarContext.isLate &&
          calendarContext.daysLate >= 7 &&
          (entities.phases.contains('telat haid') ||
              lowerQuery.contains('telat') ||
              lowerQuery.contains('terlambat') ||
              lowerQuery.contains('belum haid'))) {
        observations.add(
          'Mengingat catatan kalender menunjukkan keterlambatan telah mencapai **${calendarContext.daysLate} hari** dari perkiraan (${DateFormatter.format(calendarContext.nextPeriodDate)}), jika kamu aktif secara seksual, sangat disarankan melakukan pemeriksaan awal menggunakan alat tes kehamilan (**test pack**) pada pagi hari.',
        );
      }
      if (calendarContext.regularity == 'irregular' &&
          (lowerQuery.contains('siklus') ||
              lowerQuery.contains('telat') ||
              lowerQuery.contains('jadwal'))) {
        observations.add(
          'Berdasarkan riwayat siklusmu yang **tidak teratur**, estimasi tanggal menstruasi pada kalender memiliki rentang toleransi pergeseran yang lebih luas. Terus catat tanggal awal haid setiap bulan agar algoritma prediksi Kalmeda semakin presisi menyesuaikan dengan tubuhmu.',
        );
      }
    }

    if (clinicalContext != null && clinicalContext.isNotEmpty) {
      final lowerContext = clinicalContext.toLowerCase();

      if (lowerContext.contains('pcos') &&
          (entities.conditions.contains('PCOS') ||
              lowerQuery.contains('siklus') ||
              lowerQuery.contains('telat') ||
              lowerQuery.contains('teratur') ||
              lowerQuery.contains('jerawat') ||
              lowerQuery.contains('panjang'))) {
        observations.add(
          'Berdasarkan catatan riwayat **PCOS** pada profilmu, fluktuasi ovulasi dan ketidakseimbangan hormon androgen merupakan faktor utama yang kerap mempengaruhi ritme siklus. Penerapan pola gizi rendah indeks glikemik serta latihan resistensi teratur terbukti klinis membantu memperbaiki sensitivitas reseptor insulin dan merangsang ovulasi alami.',
        );
      }

      if (lowerContext.contains('endometriosis') &&
          (entities.isCramps ||
              entities.isBackPain ||
              lowerQuery.contains('nyeri') ||
              lowerQuery.contains('sakit') ||
              lowerQuery.contains('kram'))) {
        observations.add(
          'Mengingat riwayat **endometriosis** pada profil kesehatanmu, intensitas nyeri panggul atau kram yang dirasakan bisa lebih tinggi dari normal akibat peradangan pada jaringan endometrium ektopik. Sangat dianjurkan untuk mendiskusikan strategi pereda nyeri spesifik dan terarah bersama dokter spesialis obstetri & ginekologi.',
        );
      }

      if (lowerContext.contains('promil') || lowerContext.contains('merencanakan kehamilan')) {
        if (entities.phases.contains('ovulasi') ||
            lowerQuery.contains('subur') ||
            lowerQuery.contains('hamil') ||
            lowerQuery.contains('telat')) {
          observations.add(
            'Karena kamu sedang dalam **program hamil (promil)**, pemantauan perubahan tekstur lendir serviks yang elastis menyerupai putih telur mentah serta deteksi lonjakan hormon LH dengan ovulation test kit adalah metode non-invasif paling efektif untuk menentukan jendela masa subur optimal.',
          );
        }
      }

      if (lowerContext.contains('kontrasepsi') && !lowerContext.contains('tidak menggunakan')) {
        if (lowerQuery.contains('darah') ||
            lowerQuery.contains('flek') ||
            lowerQuery.contains('spotting') ||
            lowerQuery.contains('haid') ||
            lowerQuery.contains('telat')) {
          observations.add(
            'Penggunaan **kontrasepsi hormonal** secara langsung memodulasi dinding endometrium, sehingga keluarnya flek ringan (spotting) atau perubahan jadwal perdarahan adalah respons fisiologis adaptasi tubuh terhadap hormon eksogen.',
          );
        }
      }
    }

    if (observations.isEmpty) return null;
    return 'Catatan Klinis Personal:\n${observations.join('\n\n')}';
  }
}

class _ClinicalEntities {
  final Set<String> organs = <String>{};
  final Set<String> symptoms = <String>{};
  final Set<String> bloodFeatures = <String>{};
  final Set<String> phases = <String>{};
  final Set<String> lifestyle = <String>{};
  final Set<String> conditions = <String>{};

  bool get hasOrgan => organs.isNotEmpty;
  bool get hasSymptom => symptoms.isNotEmpty || bloodFeatures.isNotEmpty;

  bool get isCramps =>
      symptoms.contains('kram') ||
      symptoms.contains('nyeri tajam') ||
      (organs.contains('perut bawah') && symptoms.contains('nyeri'));
  bool get isBloating => symptoms.contains('kembung');
  bool get isFatigue => symptoms.contains('kelelahan');
  bool get isHeadache => symptoms.contains('sakit kepala');
  bool get isBackPain => organs.contains('panggul');
  bool get isBreastPain => organs.contains('payudara');
}
