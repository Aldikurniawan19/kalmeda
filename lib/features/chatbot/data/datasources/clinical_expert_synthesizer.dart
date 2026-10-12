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
    List<ChatMessageModel>? conversationHistory,
    String? userName,
    String? clinicalContext,
    UserCalendarContext? calendarContext,
  }) {
    final lower = query.toLowerCase().trim();
    final greeting = _getUserGreeting(userName);
    final priorContext = _extractPriorTopicContext(conversationHistory);
    final isFollowUp = _isFollowUpQuery(lower, priorContext);

    // 1. Check if the query is outside women's reproductive health domain
    if (!_isWomensHealthDomain(lower, conversationHistory: conversationHistory)) {
      return ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text:
            '$greeting terima kasih atas pertanyaannya. Sebagai konsultan klinis resmi di Kalmeda, fokus utama saya adalah membantu konsultasi seputar **kesehatan reproduksi wanita**, **siklus menstruasi**, **masa subur & ovulasi**, **gejala PMS**, **kehamilan**, serta keluhan kewanitaan lainnya.\n\nPertanyaan yang Kakak sampaikan tampaknya berada di luar ruang lingkup kesehatan kewanitaan. Apakah ada keluhan atau pertanyaan terkait siklus haid, kram perut, atau kesehatan tubuh yang ingin Kakak tanyakan?',
        isUser: false,
        timestamp: DateTime.now(),
        suggestedChips: const [
          'Berapa hari rentang siklus normal?',
          'Cara meredakan kram perut tanpa obat',
          'Kapan masa subur (ovulasi) terjadi?',
          'Kenapa darah haid berwarna hitam?',
        ],
      );
    }

    // If it's a chained follow-up referring to the prior topic in this session
    if (isFollowUp && priorContext != null && priorContext.hasTopic) {
      return _synthesizeFollowUpResponse(
        query: query,
        priorContext: priorContext,
        greeting: greeting,
        userName: userName,
        calendarContext: calendarContext,
        conversationHistory: conversationHistory,
      );
    }

    // 2. Extract clinical entities from natural user phrasing
    final detectedEntities = _extractEntities(lower);

    // 3. Compose medical response sections following the unified 6-part clinical template
    final physiologicalExplanation = _buildPhysiologicalExplanation(
      greeting,
      detectedEntities,
      lower,
    );
    final calendarSection = _buildCalendarSection(
      detectedEntities,
      lower,
      calendarContext,
    );
    final practicalRelief = _buildCareGuidance(detectedEntities, lower);
    final redFlags = _buildRedFlags(detectedEntities);
    final followUpEvaluation = _buildFollowUpEvaluation(
      detectedEntities,
      lower,
      calendarContext,
    );
    const expertReference =
        '**Referensi Pakar & Literatur Terpercaya:**\n'
        'Panduan klinis ini disusun dan diverifikasi berdasarkan konsensus medis resmi Dokter Spesialis Obstetri & Ginekologi (**Sp.OG**), American College of Obstetricians and Gynecologists (**ACOG**), Perkumpulan Obstetri dan Ginekologi Indonesia (**POGI**), dan Standar Pelayanan Medis Kemenkes RI.';

    final buffer = StringBuffer();
    buffer.writeln(physiologicalExplanation);
    buffer.writeln();

    if (calendarSection != null && calendarSection.isNotEmpty) {
      buffer.writeln(calendarSection);
      buffer.writeln();
    }

    buffer.writeln(practicalRelief);
    buffer.writeln();

    buffer.writeln(redFlags);
    buffer.writeln();

    buffer.writeln(followUpEvaluation);
    buffer.writeln();

    buffer.writeln(expertReference);

    final suggestedChips = generateContextualQuestions(
      query,
      answerText: buffer.toString(),
      calendarContext: calendarContext,
      conversationHistory: conversationHistory,
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
    List<ChatMessageModel>? conversationHistory,
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

    const expertRef =
        '\n\n**Referensi Pakar & Literatur Terpercaya:**\n'
        'Panduan klinis ini disusun dan diverifikasi berdasarkan konsensus medis resmi Dokter Spesialis Obstetri & Ginekologi (**Sp.OG**), American College of Obstetricians and Gynecologists (**ACOG**), Perkumpulan Obstetri dan Ginekologi Indonesia (**POGI**), dan Standar Pelayanan Medis Kemenkes RI.';

    return '${conversationalBody.trim()}$expertRef';
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
              'Berdasarkan data kalender kesehatan Kakak, hari pertama haid terakhir (HPHT) tercatat pada **${DateFormatter.format(calendarContext.lastPeriodDate)}** dengan panjang siklus rata-rata **${calendarContext.cycleLength} hari** (${calendarContext.regularityLabel}). Saat ini Kakak berada di **hari ke-${calendarContext.currentCycleDay}** (${calendarContext.phaseName}), dan perkiraan jadwal menstruasi berikutnya jatuh pada **${DateFormatter.format(calendarContext.nextPeriodDate)}** ($lateStatus).\n\n';
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
              'Berdasarkan data kalender kesehatan Kakak, saat ini Kakak berada di **hari ke-${calendarContext.currentCycleDay}** (${calendarContext.phaseName}). Puncak masa subur (ovulasi) diperkirakan terjadi pada **${DateFormatter.format(calendarContext.ovulationDate)}**, dengan jendela masa subur (*fertile window*) berlangsung dari tanggal **${DateFormatter.format(calendarContext.fertileWindowStart)}** hingga **${DateFormatter.format(calendarContext.fertileWindowEnd)}**.\n\n';
        } else {
          calendarSection = '';
        }

        return '$greeting $problem, pada siklus menstruasi standar 28 hari, ovulasi umumnya terjadi sekitar hari ke-14 (tepatnya 14 hari sebelum hari pertama haid berikutnya). Masa subur (*fertile window*) mencakup 5 hari sebelum ovulasi hingga 1 hari setelah ovulasi, karena sperma dapat bertahan hidup 3–5 hari di rahim sedangkan sel telur bertahan 12–24 jam.\n\n'
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
            '**Secara fisiologis klinis, langkah-langkah penanganan mandiri berikut dapat membantu meredakan kram:**\n'
            '1. **Kompres Hangat:** Tempelkan botol air hangat atau heating pad pada perut bagian bawah selama 15–20 menit untuk membantu merelaksasi otot rahim.\n'
            '2. **Cukupi Hidrasi Tubuh:** Minum air putih hangat sedikitnya 2 liter sehari untuk mencegah retensi cairan dan kembung begah.\n'
            '3. **Seduhan Jahe atau Kunyit:** Mengandung senyawa kurkumin dan gingerol yang berfungsi sebagai antiinflamasi alami pereda prostaglandin.\n'
            '4. **Peregangan Ringan (Yoga):** Lakukan pose Child Pose atau Cat-Cow pose untuk melancarkan sirkulasi panggul.\n'
            '5. **Batasi Kafein & Garam:** Kurangi sementara kopi dan makanan tinggi garam untuk meredakan ketegangan pembuluh darah panggul.';

      case 'nyeri_haid_bahaya_endometriosis':
        return '$greeting $problem, rasa nyeri haid patut dicurigai sebagai kondisi khusus (seperti endometriosis atau adenomiosis) bila kamu merasakan tanda-tanda berikut:\n\n'
            '**Tanda-tanda bahaya yang patut diwaspadai untuk segera periksa ke dokter:**\n'
            '• **Nyeri Sangat Melumpuhkan:** Rasa nyeri tidak kunjung membaik meski sudah mengonsumsi obat pereda nyeri standar.\n'
            '• **Nyeri Persisten:** Nyeri tetap terasa hebat bahkan setelah menstruasi selesai, atau terasa terus-menerus sepanjang bulan.\n'
            '• **Penjalaran Nyeri:** Nyeri menjalar hingga ke punggung bawah, panggul, bokong, atau paha.\n'
            '• **Nyeri saat Ekskresi atau Seks:** Disertai rasa sakit tajam saat buang air besar, buang air kecil, atau saat berhubungan intim.\n'
            '• **Perdarahan Berlebihan:** Volume darah haid keluar sangat berlebihan.\n\n'
            '**Pemeriksaan Lanjutan:**\n'
            'Bila mengalami kombinasi tanda ini, sangat disarankan untuk melakukan pemeriksaan USG ke dokter spesialis kandungan.';

      case 'darah_haid_hitam_cokelat':
        return '$greeting $problem, kamu tidak perlu cemas karena darah haid yang berwarna cokelat tua atau hitam pekat adalah hal yang normal dan tidak berbahaya. Warna gelap ini merupakan darah lama yang tersimpan lebih lama di rahim dan teroksidasi alami saat bereaksi dengan oksigen.\n\n'
            'Kondisi ini paling lazim ditemukan pada hari pertama menstruasi saat darah sisa awal mengalir lambat, atau pada hari-hari terakhir siklus ketika volume aliran mulai menipis sehingga membutuhkan waktu lebih lama untuk keluar dari liang kewanitaan.';

      case 'darah_haid_menggumpal':
        return '$greeting $problem, gumpalan darah haid ini terbentuk karena tubuh melepaskan enzim antikoagulan alami untuk mencairkan darah sebelum dikeluarkan. Namun pada hari aliran deras (hari ke-1 dan 2), darah mengalir lebih cepat daripada kemampuan enzim untuk mencairkannya, sehingga sebagian darah menggumpal.\n\n'
            'Gumpalan berukuran kecil (kurang dari koin) dan berwarna merah gelap pada hari-hari awal menstruasi merupakan hal yang wajar. Namun jika gumpalan berukuran sangat besar, keluar terus-menerus, atau membuatmu harus mengganti pembalut tebal setiap 1 jam sekali, kondisi tersebut perlu dievaluasi oleh dokter spesialis kandungan.';

      case 'flek_hamil_vs_flek_haid':
        return '$greeting $problem, perbedaan utama antara flek tanda kehamilan (implantasi) dengan flek menjelang haid terletak pada karakteristik berikut:\n\n'
            '1. **Perdarahan Implantasi (Tanda Hamil):** Volume hanya beberapa tetes bercak tipis di celana dalam, berwarna merah muda samar atau cokelat terang, dan berlangsung singkat 1–2 hari tanpa berkembang menjadi aliran deras.\n\n'
            '2. **Flek Menjelang Haid:** Volume bercak akan terus bertambah dalam 24–48 jam ke depan dan segera berkembang menjadi aliran darah menstruasi berwarna merah segar selama 3–7 hari.';

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
                  'Hari ini (${DateFormatter.format(calendarContext.nextPeriodDate)}) adalah perkiraan jadwal menstruasimu dimulai (hari ke-${calendarContext.currentCycleDay} dari siklus ${calendarContext.cycleLength} hari, dengan HPHT ${DateFormatter.format(calendarContext.lastPeriodDate)}).\n\n';
            } else {
              calendarSection =
                  'Menstruasi terakhirmu tercatat pada **${DateFormatter.format(calendarContext.lastPeriodDate)}** dengan panjang siklus rata-rata **${calendarContext.cycleLength} hari**. Jadwal perkiraan menstruasimu seharusnya dimulai pada **${DateFormatter.format(calendarContext.nextPeriodDate)}**, yang berarti saat ini kamu sudah **terlambat ${calendarContext.daysLate} hari** (berada di hari ke-${calendarContext.currentCycleDay} siklus).\n\n';
            }
          } else {
            calendarSection =
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
              calendarContext.cycleLength >= 21 &&
              calendarContext.cycleLength <= 35;
          final isDurationNormal =
              calendarContext.periodDuration >= 3 &&
              calendarContext.periodDuration <= 7;
          calendarSection =
              'Berdasarkan data kalender kesehatan Kakak, saat ini Kakak berada di **hari ke-${calendarContext.currentCycleDay}** (${calendarContext.phaseName}) dengan HPHT tercatat pada **${DateFormatter.format(calendarContext.lastPeriodDate)}**. Panjang siklus rata-rata Kakak adalah **${calendarContext.cycleLength} hari** (${calendarContext.regularityLabel}, ${isCycleNormal ? 'berada dalam standar medis yang sangat baik' : 'patut dipantau'}) dan durasi haid **${calendarContext.periodDuration} hari** (${isDurationNormal ? 'termasuk dalam durasi normal' : 'perlu dievaluasi'}), dengan perkiraan menstruasi berikutnya pada **${DateFormatter.format(calendarContext.nextPeriodDate)}**.\n\n';
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

      case 'kapan_ke_dokter_telat':
        return '$greeting $problem, keterlambatan haid perlu dievaluasi lebih mendalam oleh Dokter Spesialis Obstetri & Ginekologi (**Sp.OG**) bila memenuhi kriteria berikut:\n\n'
            '**Tanda-tanda yang patut diwaspadai untuk segera periksa ke dokter:**\n'
            '• **Amenore Sekunder:** Tidak mengalami menstruasi selama 3 siklus berturut-turut (lebih dari 90 hari) padahal sebelumnya siklus teratur.\n'
            '• **Siklus Kronis Tidak Teratur:** Jarak siklus selalu kurang dari 21 hari atau lebih dari 35 hari secara berkelanjutan.\n'
            '• **Tanda Hiperandrogen:** Disertai jerawat parah resisten, pertumbuhan rambut tebal di wajah/dada (hirsutisme), atau kerontokan rambut berpola.\n'
            '• **Nyeri Hebat:** Disertai rasa nyeri menusuk atau kram panggul yang melumpuhkan aktivitas.\n\n'
            '**Evaluasi Lanjutan:**\n'
            'Dokter biasanya akan melakukan pemeriksaan USG panggul dan profil hormonal untuk mendeteksi kemungkinan PCOS atau gangguan tiroid.';

      case 'siklus_maju_mundur':
        return '$greeting $problem, pergeseran tanggal menstruasi sebanyak 2 hingga 7 hari dari perkiraan adalah hal yang sangat normal dan wajar secara fisiologis.\n\n'
            'Tubuh wanita bukan mesin; fase folikuler (fase pematangan sel telur sebelum ovulasi) sangat peka terhadap dinamika hidup sehari-hari, seperti kualitas tidur, pergantian jadwal kerja/shift, perjalanan jauh, hingga perubahan pola makan.';

      case 'ciri_fisik_masa_subur':
        return '$greeting $problem, tubuh wanita memberikan beberapa sinyal fisiologis alami saat memasuki masa subur (ovulasi):\n\n'
            '**Secara fisiologis klinis, tanda-tanda masa subur meliputi:**\n'
            '1. **Perubahan Lendir Serviks:** Lendir serviks menjadi sangat bening, licin, dan elastis menyerupai putih telur mentah yang dapat diregangkan tanpa putus.\n'
            '2. **Peningkatan Suhu Basal Tubuh:** Suhu basal tubuh saat bangun tidur di pagi hari meningkat sekitar 0,3 hingga 0,5 derajat Celsius pasca-ovulasi.\n'
            '3. **Nyeri Ovulasi (Mittelschmerz):** Sensasi kram ringan atau kedutan di salah satu sisi perut bawah saat sel telur dilepaskan.\n'
            '4. **Sensitivitas Payudara:** Payudara terasa sedikit lebih kencang atau sensitif akibat lonjakan hormon estrogen dan LH.';

      case 'ganti_pembalut_berapa_jam':
        return '$greeting $problem, menjaga kebersihan area intim saat menstruasi sangat penting untuk mencegah infeksi saluran reproduksi dan kemih:\n\n'
            '**Langkah penanganan mandiri yang disarankan:**\n'
            '1. **Ganti Berkala 3–4 Jam Sekali:** Pembalut wajib diganti setiap 3 hingga 4 jam sekali, bahkan saat volume darah sedang sedikit, untuk mencegah pertumbuhan bakteri dan jamur pada media lembap.\n'
            '2. **Ganti Lebih Sering Saat Aliran Deras:** Pada hari ke-1 dan ke-2 saat darah mengalir deras, gantilah setiap 2 jam sekali agar tidak terjadi iritasi ruam kulit.\n'
            '3. **Bilas dengan Air Bersih Mengalir:** Setiap kali mengganti pembalut, bilas vulva dengan air bersih dari arah depan ke belakang dan keringkan dengan handuk bersih.';

      case 'hamil_saat_haid':
        return '$greeting $problem, peluang kehamilan saat sedang haid memang tergolong rendah, namun secara medis kemungkinannya TIDAK pernah 0%:\n\n'
            '**Secara klinis ginekologi, peluang hamil saat haid dapat terjadi karena:**\n'
            '1. **Siklus Haid Pendek:** Pada siklus 21–24 hari, masa ovulasi dapat terjadi sangat cepat setelah perdarahan menstruasi selesai.\n'
            '2. **Daya Tahan Sperma:** Sel sperma mampu bertahan hidup di saluran reproduksi hingga 5 hari, sehingga hubungan di akhir periode haid berpotensi membuahi sel telur yang matang lebih awal.\n'
            '3. **Perdarahan Bukan Haid Asli:** Bercak ovulasi atau perdarahan serviks terkadang disalahartikan sebagai darah haid biasa.';

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

  /// Determines if the query contains any keywords related to women's health domain,
  /// or if it is a contextual follow-up to an ongoing consultation session.
  static bool _isWomensHealthDomain(
    String q, {
    List<ChatMessageModel>? conversationHistory,
  }) {
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

    // Check if the query is a multi-turn follow-up referencing prior consultation context
    final priorContext = _extractPriorTopicContext(conversationHistory);
    if (priorContext != null &&
        priorContext.hasTopic &&
        _isFollowUpQuery(q, priorContext)) {
      return true;
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

  /// Builds paragraph 1: Empathetic greeting, reflection of problem, and direct biological mechanism.
  static String _buildPhysiologicalExplanation(
    String greeting,
    _ClinicalEntities e,
    String rawQuery,
  ) {
    final problem = _reflectProblem(rawQuery, e);

    if (rawQuery.contains('kapan') &&
        (rawQuery.contains('haid') ||
            rawQuery.contains('mens') ||
            rawQuery.contains('datang bulan'))) {
      return '$greeting $problem, perkiraan jadwal menstruasi berikutnya dihitung dari tanggal hari pertama haid terakhir (HPHT) ditambah panjang siklus rata-rata bulananmu.\n\n'
          'Siklus menstruasi sangat peka terhadap dinamika fisik dan stres harian, sehingga pergeseran 2 hingga 3 hari dari perkiraan adalah hal yang wajar secara fisiologis.';
    } else if (rawQuery.contains('normal') &&
        (rawQuery.contains('siklus') ||
            rawQuery.contains('haid') ||
            rawQuery.contains('mens') ||
            rawQuery.contains('waktu') ||
            rawQuery.contains('berapa hari'))) {
      return '$greeting $problem, secara medis klinis (standar konsensus ACOG & Kemenkes RI), panjang siklus menstruasi yang normal berkisar antara **21 hingga 35 hari**, dihitung sejak hari pertama haid saat ini hingga hari pertama haid berikutnya. Durasi keluarnya darah rata-rata berlangsung **3 hingga 7 hari** dengan variasi 2–3 hari yang masih tergolong wajar.';
    } else if (e.organs.contains('vagina') ||
        rawQuery.contains('kemaluan') ||
        rawQuery.contains('miss v') ||
        rawQuery.contains('vulva')) {
      return '$greeting $problem, kondisi ini umumnya merupakan manifestasi dari iritasi jaringan kulit vulva, penurunan hormon **estrogen**, atau pergeseran flora bakteri alami yang membuat dinding liang kewanitaan lebih sensitif.';
    } else if (e.symptoms.contains('nyeri tajam') ||
        rawQuery.contains('ditusuk') ||
        (e.phases.contains('ovulasi') &&
            (e.symptoms.contains('kram') || e.symptoms.contains('nyeri')))) {
      return '$greeting $problem, rasa nyeri menusuk di pertengahan siklus dalam dunia medis dikenal sebagai **Mittelschmerz**, yaitu peregangan fisiologis dinding ovarium saat folikel sel telur bersiap pecah pada masa ovulasi.';
    } else if (e.phases.contains('ovulasi') ||
        rawQuery.contains('subur') ||
        rawQuery.contains('ovulasi')) {
      return '$greeting $problem, pada siklus menstruasi standar 28 hari, masa subur (*fertile window*) terjadi sekitar hari ke-10 hingga ke-15 siklus, dengan puncak ovulasi 14 hari sebelum hari pertama haid berikutnya.';
    } else if (e.organs.contains('payudara') &&
        (e.symptoms.contains('nyeri') ||
            e.phases.contains('sebelum haid') ||
            rawQuery.contains('payudara'))) {
      return '$greeting $problem, kondisi ini dalam dunia medis dikenal sebagai **Mastalgia Siklik**, yaitu respon alami jaringan kelenjar payudara terhadap lonjakan hormon **estrogen** dan **progesteron** menjelang menstruasi.';
    } else if (e.phases.contains('telat haid') ||
        rawQuery.contains('telat') ||
        rawQuery.contains('terlambat') ||
        rawQuery.contains('belum haid')) {
      return '$greeting $problem, keterlambatan siklus haid mencerminkan proses ovulasi yang tertunda akibat fluktuasi poros hormon hipotalamus-hipofisis-ovarium yang sangat responsif terhadap kelelahan fisik atau beban pikiran (**kortisol**).';
    } else if (e.bloodFeatures.contains('darah gelap')) {
      return '$greeting $problem, darah haid berwarna cokelat tua atau hitam pekat adalah darah lama yang membutuhkan waktu lebih lambat mengalir keluar dari rahim, sehingga zat besi di dalamnya mengalami oksidasi alami.';
    } else if (e.bloodFeatures.contains('gumpalan darah')) {
      return '$greeting $problem, gumpalan darah haid terbentuk ketika volume darah mengalir lebih deras daripada kapasitas enzim antikoagulan alami rahim untuk mencairkannya pada hari-hari awal menstruasi.';
    } else if (e.symptoms.contains('kram') || e.symptoms.contains('nyeri')) {
      return '$greeting $problem, kondisi ini umumnya merupakan manifestasi dari kontraksi otot rahim yang dipicu oleh pelepasan zat kimia alami tubuh bernama **prostaglandin**.';
    } else if (e.bloodFeatures.contains('keputihan')) {
      return '$greeting $problem, cairan keputihan merupakan mekanisme alami tubuh untuk membersihkan dan menjaga kelembapan organ reproduksi yang dipengaruhi oleh ritme hormon **estrogen**.';
    } else if (e.lifestyle.contains('jamu/kunyit')) {
      return '$greeting $problem, konsumsi kunyit saat haid terbukti secara klinis memiliki zat aktif kurkumin sebagai antiinflamasi alami yang membantu menghambat enzim pemicu **prostaglandin**.';
    } else if (e.organs.contains('panggul') || e.isBackPain) {
      return '$greeting $problem, rasa pegal di area pinggang dan panggul merupakan nyeri alih (*referred pain*) akibat kontraksi rahim yang merambat melalui serabut saraf panggul menuju saraf tulang belakang bawah.';
    } else {
      return '$greeting $problem, kondisi ini berkaitan erat dengan dinamika fluktuasi hormon reproduksi wanita (**estrogen**, **progesteron**, dan **prostaglandin**) yang berinteraksi langsung dengan organ panggul dan sistem saraf tubuh.';
    }
  }

  /// Builds paragraph 2: Seamless integration of user's calendar context data.
  static String? _buildCalendarSection(
    _ClinicalEntities e,
    String rawQuery,
    UserCalendarContext? calendarContext,
  ) {
    if (calendarContext == null) return null;

    final nextPeriodStr = DateFormatter.format(calendarContext.nextPeriodDate);
    final phase = calendarContext.phaseName;

    if (calendarContext.isLate) {
      if (calendarContext.daysLate == 0) {
        return 'Berdasarkan data kalender kesehatan Kakak, hari ini (${DateFormatter.format(calendarContext.nextPeriodDate)}) adalah perkiraan jadwal menstruasi Kakak dimulai (berada di hari ke-${calendarContext.currentCycleDay} dari siklus ${calendarContext.cycleLength} hari). Dinamika hormon **progesteron** yang menurun tajam saat ini memicu respon pada rahim dan tubuh Kakak.';
      } else {
        return 'Berdasarkan data kalender kesehatan Kakak, saat ini Kakak berada di hari ke-${calendarContext.currentCycleDay} dari siklus ${calendarContext.cycleLength} hari dan telah **terlambat ${calendarContext.daysLate} hari** dari perkiraan haid (${DateFormatter.format(calendarContext.nextPeriodDate)}). Keterlambatan ini sering kali berkaitan dengan penundaan fase ovulasi akibat fluktuasi hormon tubuh.';
      }
    }

    return 'Berdasarkan data kalender kesehatan Kakak, saat ini Kakak berada di hari ke-${calendarContext.currentCycleDay} dari siklus ${calendarContext.cycleLength} hari, yang berarti Kakak sedang berada di **$phase** menuju periode menstruasi berikutnya pada $nextPeriodStr. Keluhan yang muncul di fase ini sering kali berkaitan dengan sindrom pramenstruasi (**PMS**) akibat fluktuasi hormon **progesteron** dan **estrogen** yang mempersiapkan lapisan rahim.';
  }

  /// Builds Section 3: Structured self-care guidance with numbered steps matching the clinical template.
  static String _buildCareGuidance(_ClinicalEntities e, String rawQuery) {
    final buffer = StringBuffer();
    final topic = e.isCramps
        ? 'kram'
        : (e.isHeadache
            ? 'sakit kepala'
            : (e.isBackPain
                ? 'nyeri pinggang'
                : (e.isBreastPain
                    ? 'nyeri payudara'
                    : (e.isBloating
                        ? 'perut kembung'
                        : 'keluhan tersebut'))));

    buffer.writeln(
      '**Secara fisiologis klinis, langkah-langkah penanganan mandiri berikut dapat membantu meredakan $topic:**',
    );

    if (e.organs.contains('vagina') ||
        rawQuery.contains('kemaluan') ||
        rawQuery.contains('miss v') ||
        rawQuery.contains('vulva')) {
      buffer.writeln(
        '1. **Jaga Area Kewanitaan Tetap Kering:** Segera ganti celana dalam jika terasa lembap dan pilih bahan katun yang longgar serta menyerap keringat.',
      );
      buffer.writeln(
        '2. **Basuh Hanya dengan Air Bersih Mengalir:** Bilas dari arah depan ke belakang menggunakan air bersih suam-suam kuku, dan hindari penggunaan sabun berpewangi atau cairan antiseptik sirih.',
      );
      buffer.writeln(
        '3. **Kompres Sejuk:** Bila terasa perih di bagian luar, Anda dapat menempelkan kompres kain bersih yang dibasahi air sejuk selama 10–15 menit untuk menenangkan kulit.',
      );
    } else if (e.symptoms.contains('kram') ||
        e.symptoms.contains('nyeri') ||
        e.symptoms.contains('nyeri tajam') ||
        rawQuery.contains('ditusuk')) {
      buffer.writeln(
        '1. **Kompres Hangat:** Letakkan botol berisi air hangat atau heating pad pada area perut bawah selama 15 hingga 20 menit. Panas membantu merelaksasi otot-otot rahim yang sedang berkontraksi dan meningkatkan aliran darah lokal.',
      );
      buffer.writeln(
        '2. **Hidrasi Optimal:** Pastikan asupan cairan tercukupi. Dehidrasi dapat memperburuk kontraksi otot dan retensi cairan di rongga panggul.',
      );
      buffer.writeln(
        '3. **Peregangan Ringan:** Lakukan relaksasi atau pose peregangan panggul ringan seperti Child Pose untuk mengurangi ketegangan serabut saraf.',
      );
    } else if (e.organs.contains('payudara')) {
      buffer.writeln(
        '1. **Gunakan Bra Tanpa Kawat:** Pakai sport bra atau bra penyangga yang lembut tanpa kawat agar tidak menekan jaringan kelenjar payudara yang sedang sensitif.',
      );
      buffer.writeln(
        '2. **Batasi Asupan Kafein & Garam:** Kurangi sementara kopi, teh pekat, cokelat, dan garam untuk mencegah penumpukan cairan di jaringan payudara.',
      );
      buffer.writeln(
        '3. **Kompres Nyaman:** Tempelkan kompres sejuk atau hangat suam-suam kuku bila rasa kencang terasa mengganggu kenyamanan beristirahat.',
      );
    } else if (e.phases.contains('telat haid')) {
      buffer.writeln(
        '1. **Tidur Berkualitas:** Prioritaskan tidur berkualitas 7–8 jam per hari dan luangkan waktu untuk relaksasi guna memulihkan ritme hormon hipotalamus.',
      );
      buffer.writeln(
        '2. **Hindari Diet Ekstrem:** Hindari diet ketat drastis atau aktivitas fisik yang terlalu menguras energi secara mendadak.',
      );
      buffer.writeln(
        '3. **Uji Kehamilan Mandiri:** Jika memiliki riwayat hubungan intim, lakukan uji kehamilan mandiri (**test pack**) menggunakan urine pertama di pagi hari.',
      );
    } else {
      buffer.writeln(
        '1. **Pola Makan Bergizi:** Pertahankan pola makan bergizi seimbang, cukupi asupan zat besi dari sayuran hijau dan protein, serta penuhi kebutuhan cairan tubuh.',
      );
      buffer.writeln(
        '2. **Aktivitas Fisik Ringan:** Lakukan aktivitas fisik ringan seperti jalan santai atau peregangan untuk menjaga kelancaran sirkulasi darah panggul.',
      );
      buffer.writeln(
        '3. **Waktu Istirahat Cukup:** Dengarkan sinyal tubuh dan berikan waktu istirahat yang cukup saat tubuh terasa lelah.',
      );
    }

    return buffer.toString().trim();
  }

  /// Builds Section 4: Red flags and warning signs with bullet items.
  static String _buildRedFlags(_ClinicalEntities e) {
    final buffer = StringBuffer();
    buffer.writeln(
      '**Tanda-tanda bahaya yang patut diwaspadai untuk segera periksa ke dokter:**',
    );

    if (e.organs.contains('vagina')) {
      buffer.writeln(
        '• **Keputihan Abnormal & Berbau:** Jika cairan keputihan berwarna kuning pekat atau kehijauan disertai bau amis menyengat.',
      );
      buffer.writeln(
        '• **Luka atau Bintil:** Muncul luka lecet, lepuh, atau bintil perih pada area kemaluan.',
      );
      buffer.writeln(
        '• **Nyeri Hebat Saat Berkemih:** Timbul rasa sangat panas perih saat buang air kecil atau nyeri tajam saat berhubungan intim.',
      );
    } else if (e.symptoms.contains('kram') ||
        e.symptoms.contains('nyeri') ||
        e.symptoms.contains('nyeri tajam')) {
      buffer.writeln(
        '• **Nyeri Hebat yang Melumpuhkan:** Jika kram terasa sangat intens hingga mengganggu aktivitas harian secara signifikan atau tidak membaik dengan tindakan mandiri.',
      );
      buffer.writeln(
        '• **Perdarahan Tidak Normal:** Jika terjadi perdarahan di luar jadwal siklus menstruasi atau volume darah yang keluar sangat banyak (ganti pembalut setiap 1-2 jam).',
      );
      buffer.writeln(
        '• **Gejala Sistemik:** Jika kram disertai dengan demam, keputihan dengan bau tidak sedap, atau nyeri hebat yang menjalar hingga ke area panggul yang tidak kunjung hilang setelah periode menstruasi selesai.',
      );
    } else if (e.phases.contains('telat haid')) {
      buffer.writeln(
        '• **Keterlambatan Lebih dari 14 Hari:** Siklus terlambat melebihi 2 minggu dengan hasil test pack negatif berulang.',
      );
      buffer.writeln(
        '• **Nyeri Panggul Akut:** Terjadi kram perut hebat di satu sisi panggul yang muncul mendadak.',
      );
      buffer.writeln(
        '• **Perdarahan Bercak Mencurigakan:** Disertai bercak darah flek yang terus-menerus keluar di luar siklus haid.',
      );
    } else {
      buffer.writeln(
        '• **Perdarahan Sangat Deras:** Volume darah keluar sangat deras hingga harus mengganti pembalut tebal setiap 1 jam.',
      );
      buffer.writeln(
        '• **Nyeri Panggul Persisten:** Rasa nyeri panggul yang menetap dan tidak membaik dengan istirahat.',
      );
      buffer.writeln(
        '• **Amenore Berkepanjangan:** Tidak kunjung menstruasi selama 3 bulan berturut-turut tanpa adanya kehamilan.',
      );
    }

    return buffer.toString().trim();
  }

  /// Builds Section 5: Follow-up evaluation guidance and Kalmeda calendar tracking reminder.
  static String _buildFollowUpEvaluation(
    _ClinicalEntities e,
    String rawQuery,
    UserCalendarContext? calendarContext,
  ) {
    final nextPeriodStr = calendarContext != null
        ? 'tanggal perkiraan haid ${DateFormatter.format(calendarContext.nextPeriodDate)} mendatang'
        : 'jadwal siklus berikutnya';

    final topic = e.isCramps
        ? 'kram'
        : (e.isHeadache
            ? 'sakit kepala'
            : (e.isBackPain
                ? 'nyeri pinggang'
                : (e.isBreastPain
                    ? 'nyeri payudara'
                    : 'keluhan')));

    final secondaryCondition = e.isCramps
        ? '**dismenorea** sekunder atau kondisi ginekologis lainnya seperti **endometriosis**'
        : (e.phases.contains('telat haid')
            ? 'gangguan hormonal seperti **PCOS** atau ketidakseimbangan fungsi tiroid'
            : 'kondisi klinis ginekologis yang memerlukan penanganan khusus');

    return 'Jika $topic yang Kakak alami terasa semakin memberat di siklus-siklus berikutnya, hal ini perlu dievaluasi lebih lanjut untuk menyingkirkan kemungkinan adanya $secondaryCondition. Tetap pantau siklus Kakak melalui aplikasi Kalmeda hingga $nextPeriodStr.';
  }

  /// Validates that a question is strictly phrased from the user's perspective asking the doctor/consultant,
  /// rather than the chatbot interrogating or asking the user.
  static bool _isUserPerspectiveQuestion(String q) {
    final lower = q.toLowerCase().trim();
    if (lower.isEmpty || lower.length < 8) return false;

    // Filter out chatbot interview questions directed at the user
    if (lower.contains('kakak') ||
        lower.contains('anda') ||
        lower.contains('kamu') ||
        lower.contains('keluhanmu') ||
        lower.contains('siklusmu') ||
        lower.contains('tubuhmu')) {
      return false;
    }

    if (lower.startsWith('sudah berapa') ||
        lower.startsWith('sejak kapan') ||
        lower.startsWith('apakah ada keluhan lain') ||
        lower.startsWith('apakah ada gejala lain') ||
        lower.startsWith('apakah merasa') ||
        lower.startsWith('apakah mengalami')) {
      return false;
    }

    return true;
  }

  static List<String> generateContextualQuestions(
    String userQuery, {
    String? answerText,
    List<int>? symptomIndices,
    UserCalendarContext? calendarContext,
    List<String>? candidateQuestions,
    List<ChatMessageModel>? conversationHistory,
  }) {
    final results = <String>[];
    final cleanQuery = userQuery.toLowerCase().trim();

    // 1. If candidate questions (e.g. from Gemini AI or KnowledgeBase) are present, sanitize and validate them
    if (candidateQuestions != null && candidateQuestions.isNotEmpty) {
      for (final q in candidateQuestions) {
        var cleanQ = q.trim();
        // Remove leading numbers, dots, dashes, bullets
        cleanQ = cleanQ.replaceFirst(RegExp(r'^\d+[\.\)\-]\s*'), '').trim();
        cleanQ = cleanQ.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim();
        if (cleanQ.isNotEmpty &&
            _isUserPerspectiveQuestion(cleanQ) &&
            !cleanQ.toLowerCase().contains(cleanQuery) &&
            !cleanQuery.contains(cleanQ.toLowerCase()) &&
            !results.any((r) => r.toLowerCase() == cleanQ.toLowerCase())) {
          results.add(cleanQ);
        }
      }
    }

    if (results.length >= 3) {
      return results.take(4).toList();
    }

    // 2. Semantic analysis based on user query, answer content, cycle status, and prior history
    final historyContext = conversationHistory != null
        ? conversationHistory
            .where((m) => m.id != 'welcome_msg')
            .map((m) => m.text.toLowerCase())
            .join(' ')
        : '';
    final fullContext = '$cleanQuery ${answerText?.toLowerCase() ?? ''} $historyContext';
    final fallbackPool = <String>[];

    // Kram, Dismenore, Nyeri Perut
    if (fullContext.contains('kram') ||
        fullContext.contains('nyeri haid') ||
        fullContext.contains('dismenore') ||
        fullContext.contains('sakit perut') ||
        (symptomIndices != null && symptomIndices.contains(0))) {
      fallbackPool.addAll([
        'Kapan kram haid perlu pemeriksaan USG?',
        'Berapa dosis aman paracetamol atau ibuprofen?',
        'Makanan apa yang memicu kram makin parah?',
        'Apakah kompres hangat terbukti efektif?',
        'Posisi tidur terbaik saat kram haid',
      ]);
    }

    // Telat Haid, Siklus Tidak Teratur, Amenore
    if (fullContext.contains('telat') ||
        fullContext.contains('terlambat') ||
        fullContext.contains('tidak teratur') ||
        fullContext.contains('belum haid') ||
        fullContext.contains('pcos') ||
        (calendarContext != null && calendarContext.isLate)) {
      fallbackPool.addAll([
        'Kapan waktu paling akurat untuk test pack?',
        'Kenapa haid bisa telat selain karena hamil?',
        'Kapan telat haid harus periksa ke dokter Sp.OG?',
        'Apakah stres bisa menunda ovulasi?',
        'Cara membedakan flek implantasi vs awal haid',
      ]);
    }

    // Masa Subur, Ovulasi, Promil
    if (fullContext.contains('subur') ||
        fullContext.contains('ovulasi') ||
        fullContext.contains('promil') ||
        fullContext.contains('hamil') ||
        fullContext.contains('fase folikular')) {
      fallbackPool.addAll([
        'Bagaimana ciri lendir serviks saat ovulasi?',
        'Berapa hari sel telur bertahan setelah ovulasi?',
        'Kapan waktu terbaik berhubungan saat promil?',
        'Apakah bisa hamil di luar masa subur?',
        'Cara deteksi ovulasi dengan tes strip LH',
      ]);
    }

    // Keputihan, Gatal, Infeksi
    if (fullContext.contains('keputihan') ||
        fullContext.contains('gatal') ||
        fullContext.contains('bau') ||
        fullContext.contains('lendir') ||
        fullContext.contains('vagina') ||
        fullContext.contains('infeksi')) {
      fallbackPool.addAll([
        'Perbedaan keputihan normal vs infeksi jamur',
        'Apakah sabun pembersih kewanitaan aman?',
        'Kapan keputihan butuh obat resep dokter?',
        'Cara menjaga kebersihan area intim saat haid',
      ]);
    }

    // Darah Hitam, Gumpalan, Flek Cokelat
    if (fullContext.contains('darah') ||
        fullContext.contains('hitam') ||
        fullContext.contains('cokelat') ||
        fullContext.contains('gumpal') ||
        fullContext.contains('flek') ||
        fullContext.contains('spotting') ||
        fullContext.contains('deras')) {
      fallbackPool.addAll([
        'Kenapa darah haid berwarna hitam atau gelap?',
        'Apakah wajar darah haid menggumpal seperti jelly?',
        'Berapa batas normal ganti pembalut sehari?',
        'Kapan darah haid deras dianggap tidak normal?',
      ]);
    }

    // PMS, Mood Swing, Payudara Nyeri, Kembung, Sakit Kepala
    if (fullContext.contains('pms') ||
        fullContext.contains('mood') ||
        fullContext.contains('emosi') ||
        fullContext.contains('payudara') ||
        fullContext.contains('kembung') ||
        fullContext.contains('jerawat') ||
        fullContext.contains('pusing') ||
        fullContext.contains('sakit kepala') ||
        (symptomIndices != null &&
            (symptomIndices.contains(1) ||
                symptomIndices.contains(3) ||
                symptomIndices.contains(5)))) {
      fallbackPool.addAll([
        'Nutrisi apa yang membantu menstabilkan mood PMS?',
        'Kenapa payudara terasa kencang sebelum haid?',
        'Cara mengatasi perut kembung begah saat PMS',
        'Perbedaan gejala PMS biasa dengan PMDD',
        'Tips mengatasi jerawat hormonal menjelang haid',
      ]);
    }

    // Mitos, Makanan, Minuman, Olahraga
    if (fullContext.contains('es') ||
        fullContext.contains('minum') ||
        fullContext.contains('makan') ||
        fullContext.contains('olahraga') ||
        fullContext.contains('keramas') ||
        fullContext.contains('mitos')) {
      fallbackPool.addAll([
        'Apakah minum air es benar membekukan darah haid?',
        'Olahraga apa yang aman saat menstruasi?',
        'Makanan yang dianjurkan untuk menambah darah',
        'Bolehkah keramas saat haid pertama?',
      ]);
    }

    // General fallback if pool is still empty
    if (fallbackPool.isEmpty) {
      fallbackPool.addAll([
        'Berapa hari rentang siklus normal?',
        'Cara meredakan kram perut tanpa obat',
        'Kapan masa subur (ovulasi) terjadi?',
        'Kenapa darah haid berwarna hitam?',
        'Tanda bahaya yang perlu diperiksa ke dokter',
      ]);
    }

    // Fill results from fallbackPool
    for (final q in fallbackPool) {
      if (results.length >= 4) break;
      if (!cleanQuery.contains(q.toLowerCase()) &&
          !q.toLowerCase().contains(cleanQuery) &&
          !results.any((r) => r.toLowerCase() == q.toLowerCase())) {
        results.add(q);
      }
    }

    return results.take(4).toList();
  }

  /// Extracts prior topic context from recent messages in the conversation history.
  static _PriorTopicContext? _extractPriorTopicContext(
    List<ChatMessageModel>? history,
  ) {
    if (history == null || history.isEmpty) return null;

    final validMessages = history.where((m) {
      if (m.id == 'welcome_msg') return false;
      return m.text.trim().isNotEmpty;
    }).toList();

    if (validMessages.isEmpty) return null;

    String lastUserText = '';
    String lastBotText = '';

    for (int i = validMessages.length - 1; i >= 0; i--) {
      final msg = validMessages[i];
      if (msg.isUser && lastUserText.isEmpty) {
        lastUserText = msg.text.toLowerCase();
      } else if (!msg.isUser && lastBotText.isEmpty) {
        lastBotText = msg.text.toLowerCase();
      }
      if (lastUserText.isNotEmpty && lastBotText.isNotEmpty) break;
    }

    final combinedText = '$lastUserText $lastBotText';
    final entities = _extractEntities(combinedText);

    String topicType = '';
    String topicTitle = '';

    if (combinedText.contains('telat') ||
        combinedText.contains('terlambat') ||
        combinedText.contains('ngaret') ||
        combinedText.contains('mundur') ||
        combinedText.contains('jadwal haid') ||
        combinedText.contains('belum haid') ||
        combinedText.contains('belum dapet')) {
      topicType = 'telat_haid';
      topicTitle = 'keterlambatan siklus haid';
    } else if (combinedText.contains('kram') ||
        combinedText.contains('melilit') ||
        combinedText.contains('dismenore') ||
        combinedText.contains('sakit perut') ||
        combinedText.contains('mules') ||
        combinedText.contains('kontraksi')) {
      topicType = 'kram_haid';
      topicTitle = 'kram dan nyeri perut menstruasi';
    } else if (combinedText.contains('hitam') ||
        combinedText.contains('cokelat') ||
        combinedText.contains('coklat') ||
        combinedText.contains('gelap') ||
        combinedText.contains('item')) {
      topicType = 'darah_hitam';
      topicTitle = 'darah haid yang berwarna gelap atau hitam';
    } else if (combinedText.contains('gumpal') ||
        combinedText.contains('bekuan') ||
        combinedText.contains('jelly')) {
      topicType = 'darah_gumpal';
      topicTitle = 'gumpalan darah haid';
    } else if (combinedText.contains('keputihan') ||
        combinedText.contains('lendir') ||
        combinedText.contains('becek')) {
      topicType = 'keputihan';
      topicTitle = 'cairan keputihan';
    } else if (combinedText.contains('flek') ||
        combinedText.contains('spotting') ||
        combinedText.contains('bercak') ||
        combinedText.contains('implantasi')) {
      topicType = 'flek';
      topicTitle = 'bercak flek kecokelatan';
    } else if (combinedText.contains('payudara') ||
        combinedText.contains('dada') ||
        combinedText.contains('mastalgia')) {
      topicType = 'payudara';
      topicTitle = 'rasa kencang dan nyeri pada payudara';
    } else if (combinedText.contains('air es') ||
        combinedText.contains('air dingin') ||
        combinedText.contains('es batu')) {
      topicType = 'air_es';
      topicTitle = 'minum air es saat menstruasi';
    } else if (combinedText.contains('kemaluan') ||
        combinedText.contains('vagina') ||
        combinedText.contains('miss v') ||
        combinedText.contains('vulva')) {
      topicType = 'vagina_nyeri';
      topicTitle = 'keluhan pada area kemaluan';
    } else if (combinedText.contains('subur') ||
        combinedText.contains('ovulasi') ||
        combinedText.contains('mittelschmerz')) {
      topicType = 'masa_subur';
      topicTitle = 'waktu masa subur dan ovulasi';
    } else if (combinedText.contains('siklus') ||
        combinedText.contains('rentang') ||
        combinedText.contains('normal')) {
      topicType = 'siklus_normal';
      topicTitle = 'rentang normal siklus haid';
    } else if (entities.hasSymptom || entities.hasOrgan) {
      topicType = 'umum';
      topicTitle = 'keluhan siklus kewanitaan yang sedang dialami';
    }

    if (topicType.isEmpty) return null;

    return _PriorTopicContext(
      topicType: topicType,
      topicTitle: topicTitle,
      entities: entities,
      lastUserText: lastUserText,
      lastBotText: lastBotText,
    );
  }

  /// Detects the follow-up intent of the incoming user question.
  static _FollowUpIntent _detectFollowUpIntent(String q) {
    final lower = q.toLowerCase();
    if (lower.contains('aman') ||
        lower.contains('bahaya') ||
        lower.contains('berbahaya') ||
        lower.contains('normal') ||
        lower.contains('wajar') ||
        lower.contains('risiko') ||
        lower.contains('efek') ||
        lower.contains('dampak') ||
        lower.contains('masalah')) {
      return _FollowUpIntent.safety;
    }
    if (lower.contains('obat') ||
        lower.contains('minum apa') ||
        lower.contains('parasetamol') ||
        lower.contains('mefenamat') ||
        lower.contains('jamu') ||
        lower.contains('analgesik')) {
      return _FollowUpIntent.medication;
    }
    if (lower.contains('solusi') ||
        lower.contains('cara') ||
        lower.contains('ngatasin') ||
        lower.contains('mengatasi') ||
        lower.contains('gimana') ||
        lower.contains('bagaimana') ||
        lower.contains('tips') ||
        lower.contains('langkah') ||
        lower.contains('harus apa') ||
        lower.contains('lakukan')) {
      return _FollowUpIntent.solution;
    }
    if (lower.contains('kenapa') ||
        lower.contains('mengapa') ||
        lower.contains('sebab') ||
        lower.contains('kok bisa') ||
        lower.contains('pemicu') ||
        lower.contains('penyebab')) {
      return _FollowUpIntent.cause;
    }
    if (lower.contains('berapa lama') ||
        lower.contains('sampai kapan') ||
        lower.contains('berapa hari') ||
        lower.contains('kapan selesai') ||
        lower.contains('durasi')) {
      return _FollowUpIntent.duration;
    }
    if (lower.contains('dokter') ||
        lower.contains('periksa') ||
        lower.contains('waspada') ||
        lower.contains('kapan ke')) {
      return _FollowUpIntent.redFlags;
    }
    return _FollowUpIntent.generalFollowUp;
  }

  /// Checks if the query is a follow-up referring to the ongoing topic.
  static bool _isFollowUpQuery(String q, _PriorTopicContext? priorContext) {
    if (priorContext == null || !priorContext.hasTopic) return false;
    final lower = q.toLowerCase().trim();

    // Referential pronouns & contextual continuity words
    const referralWords = [
      'itu',
      'ini',
      'tadi',
      'tersebut',
      'kondisi ini',
      'hal itu',
      'hal tersebut',
      'begitu',
      'gitu',
      'seperti itu',
      'seperti tadi',
      'keluhan ini',
      'hal ini',
    ];
    for (final ref in referralWords) {
      if (lower.contains(ref)) return true;
    }

    // Short query patterns (<= 8 words)
    final words = lower.split(RegExp(r'\s+'));
    if (words.length <= 8) {
      const followUpStarts = [
        'apakah',
        'apakah aman',
        'apakah bahaya',
        'apakah normal',
        'apakah wajar',
        'aman',
        'bahaya',
        'normal',
        'wajar',
        'solusi',
        'solusinya',
        'gimana',
        'bagaimana',
        'kenapa',
        'mengapa',
        'kok bisa',
        'obat',
        'obatnya',
        'minum apa',
        'berapa lama',
        'sampai kapan',
        'terus gimana',
        'lalu gimana',
        'boleh ga',
        'boleh tidak',
        'apakah boleh',
        'efeknya',
        'dampaknya',
        'apa itu',
        'artinya',
      ];
      for (final start in followUpStarts) {
        if (lower.contains(start)) return true;
      }
    }

    return false;
  }

  /// Synthesizes a structured 6-part clinical response tailored for multi-turn follow-up consultations.
  static ChatMessageModel _synthesizeFollowUpResponse({
    required String query,
    required _PriorTopicContext priorContext,
    required String greeting,
    String? userName,
    UserCalendarContext? calendarContext,
    List<ChatMessageModel>? conversationHistory,
  }) {
    final intent = _detectFollowUpIntent(query);
    final lower = query.toLowerCase();

    final String physiologicalExplanation;
    final String? calendarSection;
    final String practicalRelief;
    final String redFlags;
    final String followUpEvaluation;
    const expertReference =
        '**Referensi Pakar & Literatur Terpercaya:**\n'
        'Panduan klinis ini disusun dan diverifikasi berdasarkan konsensus medis resmi Dokter Spesialis Obstetri & Ginekologi (**Sp.OG**), American College of Obstetricians and Gynecologists (**ACOG**), Perkumpulan Obstetri dan Ginekologi Indonesia (**POGI**), dan Standar Pelayanan Medis Kemenkes RI.';

    switch (priorContext.topicType) {
      case 'telat_haid':
        if (intent == _FollowUpIntent.safety ||
            lower.contains('aman') ||
            lower.contains('bahaya') ||
            lower.contains('normal') ||
            lower.contains('wajar')) {
          physiologicalExplanation =
              '$greeting mengenai apakah keterlambatan siklus haid tersebut aman atau berbahaya, secara medis keterlambatan haid selama **2 hingga 7 hari** dari tanggal perkiraan umumnya tergolong **aman dan normal secara fisiologis**, terutama bila baru terjadi pada siklus ini dan dipicu oleh lonjakan hormon stres (**kortisol**), kelelahan fisik, atau fluktuasi poros **hipotalamus-hipofisis-ovarium** yang menunda proses ovulasi.';
        } else if (intent == _FollowUpIntent.solution ||
            intent == _FollowUpIntent.medication) {
          physiologicalExplanation =
              '$greeting untuk membantu menstabilkan dan memulihkan kembali siklus haid yang terlambat secara alami, kunci utamanya adalah menyeimbangkan kembali ritme pelepasan hormon **GnRH**, **FSH**, dan **LH** di otak.';
        } else if (intent == _FollowUpIntent.cause) {
          physiologicalExplanation =
              '$greeting keterlambatan siklus haid tanpa adanya kehamilan paling mendasar terjadi karena tertundanya proses pematangan dan pelepasan sel telur (ovulasi) di ovarium akibat fluktuasi hormon **estrogen** dan **progesteron** yang dipengaruhi oleh beban fisik atau emosional.';
        } else if (intent == _FollowUpIntent.duration) {
          physiologicalExplanation =
              '$greeting secara standar konsensus ginekologi, toleransi pergeseran siklus haid yang masih dianggap wajar berkisar antara **2 hingga 7 hari**. Siklus menstruasi wanita sangat dinamis dan dapat berfluktuasi dari bulan ke bulan.';
        } else {
          physiologicalExplanation =
              '$greeting mengenai evaluasi lanjutan untuk keterlambatan siklus haid yang sedang Kakak tanyakan, tubuh membutuhkan kestabilan hormon dan ritme istirahat yang baik agar dinding rahim dapat meluruh tepat waktu.';
        }

        calendarSection = _buildCalendarSection(
          priorContext.entities,
          'telat',
          calendarContext,
        );

        practicalRelief =
            '**Secara fisiologis klinis, langkah-langkah penanganan mandiri berikut dapat membantu menstabilkan siklus haid:**\n'
            '1. **Kelola Beban Pikiran & Relaksasi:** Lakukan latihan pernapasan dalam (*deep breathing*) atau peregangan ringan 15 menit sehari untuk menurunkan hormon kortisol.\n'
            '2. **Tidur Teratur & Berkualitas:** Pastikan tidur malam cukup 7–8 jam untuk menjaga ritme sirkadian hormon melatonin dan reproduksi.\n'
            '3. **Cukupi Nutrisi & Hidrasi:** Konsumsi makanan bergizi seimbang, cukupi asupan zat besi, vitamin C, dan minum air putih sedikitnya 2 liter per hari.\n'
            '4. **Lakukan Uji Kehamilan (Bila Aktif Seksual):** Bila memiliki riwayat berhubungan intim, lakukan tes *test pack* menggunakan urine pertama di pagi hari.';

        redFlags =
            '**Tanda-tanda bahaya yang patut diwaspadai untuk segera periksa ke dokter:**\n'
            '• **Keterlambatan Lebih dari 14 Hari:** Siklus terlambat lebih dari 2 minggu dengan hasil *test pack* negatif berturut-turut.\n'
            '• **Amenore Sekunder:** Tidak mengalami menstruasi selama 3 siklus berturut-turut (lebih dari 90 hari) padahal sebelumnya teratur.\n'
            '• **Nyeri Panggul Hebat:** Disertai rasa nyeri melilit tajam pada salah satu sisi perut bawah.\n'
            '• **Tanda Hiperandrogenisme:** Disertai pertumbuhan rambut tebal di wajah/dada atau jerawat parah resisten (indikasi PCOS).';

        followUpEvaluation =
            'Jika keterlambatan siklus terus berulang di siklus-siklus mendatang, sangat disarankan untuk berkonsultasi langsung dengan Dokter Spesialis Obstetri & Ginekologi (**Sp.OG**) guna pemeriksaan USG panggul dan evaluasi hormonal. Tetap catat dan pantau terus tanggal siklus Kakak di aplikasi Kalmeda.';
        break;

      case 'kram_haid':
        if (intent == _FollowUpIntent.safety ||
            lower.contains('aman') ||
            lower.contains('bahaya')) {
          physiologicalExplanation =
              '$greeting mengenai rasa kram perut menstruasi tersebut, kondisi ini umumnya **aman dan merupakan proses fisiologis alami (Dismenore Primer)** yang dipicu oleh pelepasan zat kimia alami tubuh bernama **prostaglandin** untuk meluruhkan dinding rahim.';
        } else {
          physiologicalExplanation =
              '$greeting untuk meredakan keluhan kram perut haid tersebut secara optimal, penanganan difokuskan pada relaksasi otot polos miometrium rahim dan penghambatan sintesis **prostaglandin**.';
        }

        calendarSection = _buildCalendarSection(
          priorContext.entities,
          'kram',
          calendarContext,
        );

        practicalRelief =
            '**Secara fisiologis klinis, langkah-langkah penanganan mandiri berikut dapat membantu meredakan kram haid:**\n'
            '1. **Kompres Hangat (Heating Pad):** Tempelkan botol air hangat pada perut bagian bawah selama 15–20 menit untuk melancarkan sirkulasi darah rahim.\n'
            '2. **Minum Seduhan Kunyit & Jahe:** Senyawa kurkumin dan gingerol bekerja sebagai antiinflamasi alami pereda kontraksi rahim.\n'
            '3. **Peregangan Ringan (*Yoga Stretch*):** Lakukan gerakan *Child Pose* atau *Cat-Cow* untuk merelaksasi otot dasar panggul.\n'
            '4. **Pilihan Obat Pereda Nyeri:** Bila nyeri mengganggu, obat golongan analgesik atau NSAID (seperti Parasetamol atau Asam Mefenamat) dapat diminum setelah makan sesuai petunjuk.';

        redFlags =
            '**Tanda-tanda bahaya yang patut diwaspadai untuk segera periksa ke dokter:**\n'
            '• **Nyeri Sangat Melumpuhkan:** Nyeri hebat yang tidak membaik meski sudah meminum obat pereda nyeri standar.\n'
            '• **Nyeri Persisten:** Nyeri tetap terasa menusuk bahkan setelah menstruasi selesai.\n'
            '• **Nyeri Menjalar:** Rasa sakit menjalar hingga ke paha, bokong, atau punggung bawah (indikasi **endometriosis** atau **adenomiosis**).\n'
            '• **Nyeri saat BAB atau Berhubungan Intim:** Disertai diskezia atau dispareunia.';

        followUpEvaluation =
            'Pantau intensitas kram perut Kakak di setiap siklus melalui fitur pencatatan gejala Kalmeda. Bila rasa sakit semakin memberat dan melumpuhkan aktivitas rutin, lakukan pemeriksaan USG ke dokter spesialis kandungan.';
        break;

      case 'darah_hitam':
        physiologicalExplanation =
            '$greeting darah haid yang berwarna hitam, cokelat tua, atau gelap pekat adalah kondisi yang **sepenuhnya aman, normal, dan tidak berbahaya**. Warna gelap tersebut merupakan darah lama dari dinding rahim yang mengalir lebih lambat sehingga mengalami **oksidasi alami** saat bereaksi dengan oksigen di liang vagina sebelum keluar.';

        calendarSection = null;

        practicalRelief =
            '**Secara fisiologis klinis, langkah-langkah perawatan mandiri yang dianjurkan:**\n'
            '1. **Ganti Pembalut Berkala:** Tetap ganti pembalut setiap 3–4 jam sekali meski volume darah terlihat sedikit untuk menjaga higienitas.\n'
            '2. **Bilas dengan Air Bersih Mengalir:** Bersihkan area kewanitaan dari arah depan ke belakang dengan air bersih suam-suam kuku.\n'
            '3. **Cukupi Asupan Cairan:** Minum air putih minimal 2 liter per hari untuk menjaga sirkulasi darah tubuh tetap lancar.';

        redFlags =
            '**Tanda-tanda bahaya yang patut diwaspadai untuk segera periksa ke dokter:**\n'
            '• **Disertai Bau Busuk Menyengat:** Darah gelap disertai aroma busuk yang tajam (tanda infeksi rongga rahim atau vagina).\n'
            '• **Disertai Demam & Nyeri Panggul:** Adanya demam menggigil atau kram panggul yang sangat menyiksa.\n'
            '• **Perdarahan Gelap Berkelanjutan:** Darah gelap keluar terus-menerus selama lebih dari 10 hari.';

        followUpEvaluation =
            'Kondisi darah haid gelap di awal atau akhir siklus adalah variasi biologis yang sehat. Tetap pantau warna dan durasi siklus Kakak di aplikasi Kalmeda.';
        break;

      case 'darah_gumpal':
        physiologicalExplanation =
            '$greeting gumpalan darah haid berukuran kecil (kurang dari koin) pada hari aliran deras (hari ke-1 dan ke-2) adalah hal yang **fisiologis normal dan aman**. Gumpalan terbentuk karena laju keluarnya darah lebih cepat dibandingkan kemampuan enzim **antikoagulan alami** tubuh untuk mengencerkannya.';

        calendarSection = null;

        practicalRelief =
            '**Secara fisiologis klinis, langkah-langkah penanganan mandiri yang dianjurkan:**\n'
            '1. **Ganti Pembalut Lebih Sering:** Pada hari aliran deras, gantilah pembalut setiap 2–3 jam sekali agar area intim tidak lembap.\n'
            '2. **Konsumsi Makanan Kaya Zat Besi:** Konsumsi bayam, daging merah tanpa lemak, atau kacang-kacangan untuk mencegah penurunan hemoglobin akibat aliran deras.\n'
            '3. **Istirahat yang Cukup:** Hindari aktivitas fisik yang terlalu berat saat volume darah sedang banyak.';

        redFlags =
            '**Tanda-tanda bahaya yang patut diwaspadai untuk segera periksa ke dokter:**\n'
            '• **Ukuran Gumpalan Sangat Besar:** Gumpalan berukuran lebih besar dari koin 500 rupiah atau keluar dalam jumlah banyak berturut-turut.\n'
            '• **Pembalut Penuh Setiap 1 Jam:** Mengharuskan ganti pembalut tebal setiap 1–2 jam selama berjam-jam berturut-turut (menoragia).\n'
            '• **Tanda Anemia Berat:** Disertai rasa lemas ekstrem, pusing berputar berkunang-kunang, dan wajah pucat pasi.';

        followUpEvaluation =
            'Bila gumpalan darah berukuran besar terjadi di setiap siklus haid, konsultasikan ke Dokter Spesialis Obstetri & Ginekologi (**Sp.OG**) untuk evaluasi USG menyingkirkan miom atau polip rahim.';
        break;

      case 'keputihan':
        physiologicalExplanation =
            '$greeting mengenai keluhan cairan keputihan tersebut, keputihan yang berwarna bening hingga putih susu tipis, tidak berbau, dan tidak gatal adalah **fisiologis normal dan aman**. Namun jika keputihan berubah warna (kuning/hijau), bergumpal, atau berbau amis disertai gatal, kondisi tersebut merupakan tanda infeksi jamur (*kandidiasis*) atau bakteri (*vaginosis*).';

        calendarSection = null;

        practicalRelief =
            '**Secara fisiologis klinis, langkah-langkah perawatan mandiri untuk menjaga kebersihan intim:**\n'
            '1. **Jaga Area Intim Tetap Kering:** Keringkan area vulva dengan handuk lembut setelah buang air sebelum mengenakan celana dalam.\n'
            '2. **Gunakan Celana Dalam Katun Longgar:** Hindari celana ketat berbahan sintetis yang dapat memerangkap kelembapan.\n'
            '3. **Hindari Sabun Antiseptik Sirih / Pewangi:** Vagina memiliki mekanisme *self-cleaning*. Sabun pewangi dapat merusak pH alami dan mematikan bakteri baik *Lactobacillus*.\n'
            '4. **Bilas dari Arah Depan ke Belakang:** Selalu bilas dari arah depan (vagina) menuju belakang (anus) untuk mencegah kontaminasi bakteri usus.';

        redFlags =
            '**Tanda-tanda bahaya yang patut diwaspadai untuk segera periksa ke dokter:**\n'
            '• **Keputihan Berwarna Kuning Kehijauan / Abu-abu:** Disertai bau busuk menyengat atau amis tajam.\n'
            '• **Rasa Gatal & Perih Hebat:** Kemaluan terasa panas terbakar atau bengkak kemerahan.\n'
            '• **Keputihan Bergumpal Seperti Keju:** Tanda khas infeksi jamur *Candida albicans* yang membutuhkan antijamur resep dokter.';

        followUpEvaluation =
            'Bila keluhan keputihan abnormal tidak membaik dalam 3–5 hari dengan perawatan mandiri, periksakan diri ke dokter spesialis kandungan atau dokter kulit kelamin untuk mendapatkan terapi obat antijamur/antibiotik yang tepat.';
        break;

      case 'flek':
        physiologicalExplanation =
            '$greeting keluarnya bercak flek cokelat di luar jadwal haid rutin umumnya tergolong **aman dan normal** bila berlangsung singkat (1–2 hari), yang sering dipicu oleh penurunan hormon estrogen sementara menjelang haid atau saat masa ovulasi (pelepasan sel telur).';

        calendarSection = null;

        practicalRelief =
            '**Secara fisiologis klinis, langkah penanganan yang dianjurkan:**\n'
            '1. **Gunakan Pantyliner Bersih:** Ganti pantyliner secara berkala untuk menjaga kebersihan pakaian dalam.\n'
            '2. **Catat Waktu Munculnya Flek:** Tandai apakah flek muncul di tengah siklus (masa ovulasi) atau beberapa hari sebelum tanggal haid.\n'
            '3. **Lakukan Uji Test Pack:** Bila ada riwayat hubungan intim tanpa pengaman, lakukan tes kehamilan mandiri untuk mengevaluasi apakah flek merupakan tanda implantasi.';

        redFlags =
            '**Tanda-tanda bahaya yang patut diwaspadai untuk segera periksa ke dokter:**\n'
            '• **Flek Terus-Menerus Lebih dari 7 Hari:** Bercak darah tidak kunjung berhenti.\n'
            '• **Flek Disertai Nyeri Panggul Tajam:** Dikhawatirkan kehamilan ektopik atau gangguan serviks.\n'
            '• **Perdarahan Pasca-Hubungan Seksual (*Postcoital Bleeding*):** Keluar darah setiap kali selesai berhubungan intim.';

        followUpEvaluation =
            'Catat kemunculan bercak flek pada kalender Kalmeda Kakak. Bila bercak darah terus berulang di luar siklus normal, jadwalkan pemeriksaan ginekologi ke dokter spesialis kandungan.';
        break;

      case 'payudara':
        physiologicalExplanation =
            '$greeting rasa kencang, bengkak, atau nyeri pada payudara menjelang haid (dikenal sebagai **Mastalgia Siklik**) adalah kondisi yang **sangat jinak, normal, dan aman**. Kondisi ini dipicu oleh lonjakan hormon **estrogen** yang memperbesar saluran kelenjar susu dan hormon **progesteron** yang memicu retensi cairan di jaringan payudara.';

        calendarSection = null;

        practicalRelief =
            '**Secara fisiologis klinis, langkah-langkah penanganan mandiri berikut dapat meredakan nyeri payudara:**\n'
            '1. **Kenakan Bra yang Tepat (*Supportive Bra*):** Gunakan bra tanpa kawat (*seamless* atau *sports bra*) yang menopang payudara dengan nyaman.\n'
            '2. **Kompres Hangat atau Dingin:** Tempelkan kompres hangat atau handuk dingin pada payudara selama 10–15 menit untuk meredakan ketegangan jaringan.\n'
            '3. **Batasi Asupan Kafein & Garam:** Kurangi sementara kopi, teh pekat, dan makanan tinggi natrium yang memicu retensi cairan.\n'
            '4. **Konsumsi Makanan Kaya Vitamin E & B6:** Membantu menyeimbangkan sensitivitas reseptor prolaktin pada jaringan payudara.';

        redFlags =
            '**Tanda-tanda bahaya yang patut diwaspadai untuk segera periksa ke dokter:**\n'
            '• **Benjolan Padat yang Menetap:** Teraba benjolan keras yang tidak hilang atau membesar setelah haid selesai.\n'
            '• **Cairan Keluar dari Puting Secara Spontan:** Terutama bila cairan berwarna keruh, berdarah, atau hanya keluar dari satu sisi payudara.\n'
            '• **Perubahan Bentuk Kulit Payudara:** Kulit payudara tertarik ke dalam, berkerut menyerupai kulit jeruk (*peau d\'orange*), atau puting tertarik ke dalam (*retraksi*).';

        followUpEvaluation =
            'Nyeri payudara siklik akan mereda dengan sendirinya begitu menstruasi dimulai dan hormon menurun. Lakukan pemeriksaan payudara sendiri (SADARI) secara rutin pada hari ke-7 hingga ke-10 setelah hari pertama haid.';
        break;

      case 'air_es':
        physiologicalExplanation =
            '$greeting minum air es atau minuman dingin saat sedang menstruasi **100% aman dan tidak membekukan darah haid**. Secara anatomi medis, saluran pencernaan (kerongkongan dan lambung) terpisah total dengan rongga rahim (saluran reproduksi), sehingga suhu air dingin yang masuk ke lambung akan langsung dinetralkan oleh suhu inti tubuh manusia (37 derajat Celcius) sebelum diserap ke pembuluh darah.';

        calendarSection = null;

        practicalRelief =
            '**Secara fisiologis klinis, panduan hidrasi dan kenyamanan saat menstruasi:**\n'
            '1. **Cukupi Kebutuhan Cairan Tubuh:** Minum air putih sedikitnya 2 liter sehari sangat penting untuk mencegah kembung dan kelelahan.\n'
            '2. **Pilih Air Hangat Bila Sedang Kram:** Bila sedang merasakan kram perut, minum air hangat atau seduhan jahe dapat membantu memberikan efek relaksasi pada otot tubuh.\n'
            '3. **Hindari Minuman Tinggi Gula & Kafein Berlebih:** Kurangi minuman bersoda atau boba manis yang dapat memicu fluktuasi energi dan peradangan.';

        redFlags =
            '**Tanda-tanda bahaya yang patut diwaspadai untuk segera periksa ke dokter:**\n'
            '• **Darah Haid Tiba-tiba Berhenti Disertai Nyeri Hebat:** Yang bukan karena air es melainkan karena gangguan hormonal atau sumbatan saluran serviks.\n'
            '• **Demam Tinggi & Menggigil Saat Haid:** Tanda adanya infeksi panggul aktif.';

        followUpEvaluation =
            'Kakak tidak perlu khawatir mengonsumsi air dingin saat haid. Tetap jaga pola makan bergizi seimbang dan pantau siklus menstruasi Kakak melalui aplikasi Kalmeda.';
        break;

      default:
        physiologicalExplanation =
            '$greeting mengenai pertanyaan lanjutan yang Kakak sampaikan terkait ${priorContext.topicTitle}, secara medis kondisi ini merupakan bagian dari dinamika fisiologis tubuh wanita yang sangat dipengaruhi oleh fluktuasi hormon **estrogen** dan **progesteron** serta ritme aktivitas harian.';

        calendarSection = _buildCalendarSection(
          priorContext.entities,
          lower,
          calendarContext,
        );

        practicalRelief =
            '**Secara fisiologis klinis, langkah-langkah penanganan mandiri yang dianjurkan:**\n'
            '1. **Jaga Pola Istirahat & Relaksasi:** Cukupi waktu tidur malam 7–8 jam untuk mendukung kestabilan poros hormonal tubuh.\n'
            '2. **Cukupi Hidrasi & Nutrisi Seimbang:** Minum air putih minimal 2 liter per hari dan perbanyak asupan sayur serta buah kaya antioksidan.\n'
            '3. **Peregangan Ringan:** Lakukan aktivitas fisik ringan untuk melancarkan sirkulasi darah dan meredakan ketegangan tubuh.';

        redFlags =
            '**Tanda-tanda bahaya yang patut diwaspadai untuk segera periksa ke dokter:**\n'
            '• **Keluhan Semakin Memberat:** Rasa nyeri atau ketidaknyamanan melumpuhkan aktivitas harian.\n'
            '• **Gejala Berlangsung Kronis:** Berlangsung terus-menerus selama berminggu-minggu tanpa ada perbaikan.\n'
            '• **Disertai Perdarahan Abnormal:** Perdarahan hebat atau bercak darah yang tidak wajar.';

        followUpEvaluation =
            'Tetap catat dan evaluasi setiap perubahan siklus dan gejala fisik Kakak melalui aplikasi Kalmeda. Bila keluhan berlanjut, konsultasikan dengan Dokter Spesialis Obstetri & Ginekologi (**Sp.OG**).';
        break;
    }

    final buffer = StringBuffer();
    buffer.writeln(physiologicalExplanation);
    buffer.writeln();

    if (calendarSection != null && calendarSection.isNotEmpty) {
      buffer.writeln(calendarSection);
      buffer.writeln();
    }

    buffer.writeln(practicalRelief);
    buffer.writeln();

    buffer.writeln(redFlags);
    buffer.writeln();

    buffer.writeln(followUpEvaluation);
    buffer.writeln();

    buffer.writeln(expertReference);

    final suggestedChips = generateContextualQuestions(
      query,
      answerText: buffer.toString(),
      calendarContext: calendarContext,
      conversationHistory: conversationHistory,
    );

    final bool shouldSuggestRecord =
        priorContext.entities.hasSymptom || priorContext.entities.hasOrgan;

    final symptomList = <int>[];
    if (priorContext.entities.isCramps) symptomList.add(0);
    if (priorContext.entities.isBloating) symptomList.add(1);
    if (priorContext.entities.isFatigue) symptomList.add(2);
    if (priorContext.entities.isHeadache) symptomList.add(3);
    if (priorContext.entities.isBackPain) symptomList.add(4);
    if (priorContext.entities.isBreastPain) symptomList.add(5);

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
      symptomIndices: symptomList.isNotEmpty ? symptomList : null,
    );
  }
}

/// Helper container representing previously active discussion topic and extracted entities.
class _PriorTopicContext {
  final String topicType;
  final String topicTitle;
  final _ClinicalEntities entities;
  final String lastUserText;
  final String lastBotText;

  const _PriorTopicContext({
    required this.topicType,
    required this.topicTitle,
    required this.entities,
    required this.lastUserText,
    required this.lastBotText,
  });

  bool get hasTopic => topicType.isNotEmpty;
}

/// Categorized user follow-up intent.
enum _FollowUpIntent {
  safety,
  solution,
  medication,
  cause,
  duration,
  redFlags,
  generalFollowUp,
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
