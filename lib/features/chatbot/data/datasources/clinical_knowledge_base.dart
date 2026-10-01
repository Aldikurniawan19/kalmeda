import 'package:menstracker/features/chatbot/data/models/faq_knowledge_model.dart';

/// Preloaded clinical knowledge base containing structured answers for common women's health inquiries.
/// Derived from clinical guidelines (ACOG, WHO, and Kementerian Kesehatan RI).
/// Completely free of emojis and colloquial slops, strictly adhering to `aturan-desain.md`.
class ClinicalKnowledgeBase {
  static const List<FaqKnowledgeModel> entries = [
    // ------------------------------------------------------------------------
    // 1. SIKLUS & KETERLAMBATAN HAID
    // ------------------------------------------------------------------------
    FaqKnowledgeModel(
      id: 'siklus_normal',
      category: 'Siklus Haid',
      question: 'Berapa hari rentang siklus menstruasi yang dianggap normal?',
      answer:
          'Secara medis klinis (standar ACOG & Kemenkes RI), panjang siklus menstruasi yang normal berkisar antara 21 hingga 35 hari, dihitung dari hari pertama haid saat ini hingga hari pertama haid berikutnya. Durasi keluarnya darah rata-rata berlangsung 3 hingga 7 hari dengan perkiraan volume darah 30 hingga 40 ml per siklus.\n\nVariasi beberapa hari setiap bulannya masih dianggap fisiologis wajar, terutama jika dipengaruhi fluktuasi kelelahan fisik atau stres ringan.',
      keywords: [
        'siklus normal',
        'berapa hari',
        'panjang siklus',
        'durasi haid',
        'siklus ideal',
        'lama haid',
      ],
      relatedChips: [
        'Kenapa haid bisa telat selain hamil?',
        'Kapan harus ke dokter jika telat haid?',
        'Kenapa siklus haid bisa maju mundur?',
      ],
      actionRoute: 'record',
      actionLabel: 'Catat Tanggal Haid',
    ),
    FaqKnowledgeModel(
      id: 'telat_haid_bukan_hamil',
      category: 'Siklus Haid',
      question: 'Kenapa haid saya bisa terlambat padahal tidak sedang hamil?',
      answer:
          'Keterlambatan menstruasi tanpa adanya kehamilan paling sering dipicu oleh:\n1. Stres Emosional atau Beban Pikiran: Memicu hormon kortisol yang menekan kerja hipotalamus dalam mengatur hormon reproduksi GnRH.\n2. Perubahan Berat Badan Drastis: Penurunan atau kenaikan berat badan tiba-tiba mengganggu produksi hormon estrogen.\n3. Kelelahan Fisik & Olahraga Ekstrem: Menghambat proses ovulasi (fase anovulasi).\n4. Ketidakseimbangan Hormon: Sindrom ovarium polikistik (PCOS) atau gangguan fungsi tiroid.\n5. Efek Samping Kontrasepsi atau Obat Tertentu.\n\nJika terlambat lebih dari 7-14 hari, disarankan melakukan tes kehamilan terlebih dahulu untuk memastikan, atau mengevaluasi pola istirahat.',
      keywords: [
        'telat haid',
        'terlambat haid',
        'kenapa telat',
        'bukan hamil',
        'tidak hamil',
        'telat seminggu',
        'telat sebulan',
      ],
      relatedChips: [
        'Kapan harus ke dokter jika telat haid?',
        'Apa itu PCOS dan tanda-tandanya?',
        'Cara melancarkan siklus haid alami',
      ],
      actionRoute: 'record',
      actionLabel: 'Catat Keluhan Hari Ini',
    ),
    FaqKnowledgeModel(
      id: 'kapan_ke_dokter_telat',
      category: 'Siklus Haid',
      question:
          'Kapan keterlambatan haid harus diperiksakan ke dokter spesialis?',
      answer:
          'Konsultasi ke Dokter Spesialis Obstetri & Ginekologi (Sp.OG) sangat disarankan apabila Anda mengalami:\n1. Amenore Sekunder: Tidak mengalami haid selama 3 siklus berturut-turut (atau lebih dari 90 hari) padahal sebelumnya teratur.\n2. Siklus Kronis Tidak Teratur: Jarak siklus selalu lebih pendek dari 21 hari atau lebih panjang dari 35 hari.\n3. Disertai Gejala Tambahan: Muncul jerawat parah tak kunjung sembuh, pertumbuhan rambut tebal di area wajah/dada (hirsutisme), atau kerontokan rambut signifikan.\n4. Disertai Nyeri Hebat di Perut Bawah.',
      keywords: [
        'kapan ke dokter',
        'telat parah',
        'tidak haid 3 bulan',
        'amenore',
        'periksa kandungan',
        'dokter spog',
      ],
      relatedChips: [
        'Apa itu PCOS dan tanda-tandanya?',
        'Berapa hari rentang siklus normal?',
        'Perbedaan kram normal vs endometriosis',
      ],
    ),
    FaqKnowledgeModel(
      id: 'siklus_maju_mundur',
      category: 'Siklus Haid',
      question:
          'Kenapa tanggal menstruasi saya sering maju atau mundur beberapa hari?',
      answer:
          'Pergeseran tanggal menstruasi sebanyak 2 hingga 7 hari dari perkiraan adalah hal yang sangat normal dan fisiologis. Tubuh wanita bukan mesin; fase folikuler (fase pematangan sel telur sebelum ovulasi) sangat peka terhadap dinamika hidup sehari-hari, seperti kualitas tidur, pergantian jadwal kerja/shift, perjalanan jauh (jet lag), hingga perubahan pola makan.',
      keywords: [
        'maju mundur',
        'siklus bergeser',
        'tanggal maju',
        'tanggal mundur',
        'siklus tidak tepat',
      ],
      relatedChips: [
        'Berapa hari rentang siklus normal?',
        'Cara melancarkan siklus haid alami',
      ],
    ),
    FaqKnowledgeModel(
      id: 'jadwal_haid_berikutnya',
      category: 'Siklus Haid',
      question: 'Kapan perkiraan jadwal menstruasi saya berikutnya?',
      answer:
          'Jadwal menstruasi berikutnya dihitung dari tanggal hari pertama haid terakhir (HPHT) ditambah dengan panjang siklus rata-rata Anda. Siklus normal umumnya berulang setiap 21 hingga 35 hari.',
      keywords: [
        'kapan haid berikutnya',
        'kapan saya haid',
        'jadwal haid',
        'kapan datang bulan',
        'prediksi haid',
        'kapan mens lagi',
        'kapan haid lagi',
      ],
      relatedChips: [
        'Berapa hari rentang siklus normal?',
        'Kapan masa subur (ovulasi) terjadi?',
        'Kenapa haid bisa telat selain hamil?',
      ],
      actionRoute: 'calendar',
      actionLabel: 'Lihat Kalender Siklus',
    ),

    // ------------------------------------------------------------------------
    // 2. KRAM, NYERI & DISMENORE
    // ------------------------------------------------------------------------
    FaqKnowledgeModel(
      id: 'penyebab_kram_haid',
      category: 'Nyeri & Kram',
      question: 'Mengapa perut terasa kram dan melilit hebat saat menstruasi?',
      answer:
          'Kram menstruasi (dismenore primer) disebabkan oleh pelepasan zat kimia alami tubuh bernama prostaglandin. Prostaglandin memicu otot-otot dinding rahim berkontraksi secara ritmis untuk membantu meluruhkan lapisan endometrium (darah haid).\n\nKadar prostaglandin biasanya berada di puncaknya pada hari ke-1 dan ke-2 menstruasi, sehingga wajar jika intensitas kram terasa paling kuat pada hari-hari awal tersebut sebelum berangsur mereda.',
      keywords: [
        'kram perut',
        'nyeri haid',
        'kenapa kram',
        'sakit perut',
        'dismenore',
        'perut melilit',
        'kontraksi rahim',
      ],
      relatedChips: [
        'Cara meredakan kram perut tanpa obat',
        'Kapan nyeri haid berbahaya atau endometriosis?',
        'Posisi tidur terbaik saat kram haid',
      ],
      actionRoute: 'record',
      actionLabel: 'Catat Nyeri di Menu Catat',
    ),
    FaqKnowledgeModel(
      id: 'cara_redakan_kram_alami',
      category: 'Nyeri & Kram',
      question:
          'Bagaimana cara meredakan kram perut saat haid secara alami tanpa obat?',
      answer:
          'Langkah-langkah pereda kram alami yang terbukti secara klinis:\n1. Kompres Hangat: Letakkan botol air hangat atau heating pad pada perut bagian bawah selama 15-20 menit untuk merelaksasi otot rahim.\n2. Cukupi Cairan Tubuh: Minum air putih hangat mencegah retensi cairan dan kembung yang memperberat rasa sakit.\n3. Seduhan Jahe atau Kunyit: Mengandung senyawa kurkumin dan gingerol yang berfungsi sebagai antiinflamasi alami pereda prostaglandin.\n4. Peregangan Ringan (Yoga): Lakukan pose Child Pose atau Cat-Cow pose untuk melancarkan sirkulasi panggul.\n5. Hindari Kafein & Garam Berlebih: Menurunkan ketegangan pembuluh darah di area panggul.',
      keywords: [
        'meredakan kram',
        'tanpa obat',
        'kompres hangat',
        'ramuan kram',
        'obat alami haid',
        'mengatasi nyeri perut',
      ],
      relatedChips: [
        'Posisi tidur terbaik saat kram haid',
        'Makanan yang harus dihindari saat haid',
        'Kapan nyeri haid berbahaya atau endometriosis?',
      ],
      actionRoute: 'record',
      actionLabel: 'Catat Gejala Ini',
    ),
    FaqKnowledgeModel(
      id: 'nyeri_haid_bahaya_endometriosis',
      category: 'Nyeri & Kram',
      question:
          'Kapan nyeri haid dianggap tidak normal atau dicurigai endometriosis?',
      answer:
          'Nyeri haid dicurigai sebagai dismenore sekunder (seperti endometriosis atau adenomiosis) bila memiliki tanda berikut:\n1. Rasa nyeri sangat melumpuhkan, tidak membaik meski sudah mengonsumsi obat pereda nyeri standar.\n2. Nyeri tetap terasa hebat bahkan setelah menstruasi selesai, atau terasa sepanjang bulan.\n3. Nyeri menjalar hingga ke punggung bawah, bokong, atau paha.\n4. Disertai rasa sakit tajam saat buang air besar, buang air kecil, atau saat berhubungan seksual (dispareunia).\n5. Disertai darah haid yang sangat berlebihan (menoragia).\n\nBila mengalami kombinasi tanda ini, segera lakukan USG transvaginal/pemeriksaan ke dokter spesialis kandungan.',
      keywords: [
        'nyeri berbahaya',
        'endometriosis',
        'dismenore sekunder',
        'sakit parah',
        'tidak mempan obat',
        'kista coklat',
      ],
      relatedChips: [
        'Cara meredakan kram perut tanpa obat',
        'Penyebab darah haid menggumpal',
        'Kapan keterlambatan haid harus ke dokter?',
      ],
    ),
    FaqKnowledgeModel(
      id: 'nyeri_payudara_sebelum_haid',
      category: 'Nyeri & Kram',
      question:
          'Kenapa payudara terasa bengkak, kencang, dan nyeri sebelum menstruasi?',
      answer:
          'Kondisi ini disebut Mastalgia Siklik. Menjelang menstruasi (fase luteal), terjadi lonjakan hormon estrogen yang memicu pembesaran saluran kelenjar susu, serta hormon progesteron yang menyebabkan pembengkakan pada kelenjar lobulus payudara.\n\nKondisi ini sepenuhnya normal dan akan mereda dengan sendirinya begitu menstruasi dimulai dan kadar hormon menurun. Disarankan memakai bra tanpa kawat (sport bra) dan membatasi asupan kafein untuk mengurangi ketegangan jaringan.',
      keywords: [
        'payudara nyeri',
        'payudara bengkak',
        'payudara kencang',
        'sakit payudara',
        'mastalgia',
        'nyeri dada sebelum haid',
      ],
      relatedChips: [
        'Perbedaan gejala PMS dan awal kehamilan',
        'Penyebab kram perut saat menstruasi',
      ],
      actionRoute: 'record',
      actionLabel: 'Catat Gejala Payudara',
    ),
    FaqKnowledgeModel(
      id: 'nyeri_kemaluan_vagina',
      category: 'Nyeri & Kram',
      question: 'Kenapa area kemaluan atau miss V terasa nyeri dan perih?',
      answer:
          'Rasa nyeri, perih, atau ngilu pada area kemaluan (vagina atau vulva) wajar membuat cemas. Secara medis klinis, kondisi ini paling sering dipicu oleh:\n1. Iritasi Kulit Luar (Dermatitis Kontak): Gesekan pakaian dalam yang ketat, penggunaan pembalut lembap yang jarang diganti, atau sensitivitas terhadap sabun pembersih berpewangi.\n2. Infeksi Vagina (Vaginitis): Infeksi jamur (kandidiasis) atau vaginosis bakterialis yang biasanya disertai rasa gatal dan keputihan abnormal.\n3. Perubahan Hormon: Penurunan estrogen menjelang atau selama menstruasi membuat dinding vagina lebih kering dan sensitif.\n4. Ketegangan Otot Panggul: Otot dasar panggul yang berkontraksi tegang dapat memicu rasa ngilu menusuk.\n\nDisarankan menjaga area kemaluan tetap kering, mengenakan celana dalam katun yang longgar, membilas hanya dengan air bersih mengalir suam-suam kuku, dan menghindari sabun antiseptik sirih.',
      keywords: [
        'kemaluan nyeri',
        'kemaluan terasa nyeri',
        'vagina sakit',
        'miss v perih',
        'nyeri kemaluan',
        'sakit kemaluan',
        'vagina nyeri',
        'kemaluan perih',
        'vulva nyeri',
        'ngilu kemaluan',
        'kemaluan sakit',
        'perih kemaluan',
        'vulvodynia',
      ],
      relatedChips: [
        'Perbedaan keputihan normal vs tanda infeksi',
        'Cara meredakan kram perut tanpa obat',
        'Kapan keterlambatan haid harus ke dokter?',
      ],
      actionRoute: 'record',
      actionLabel: 'Catat Keluhan Kemaluan Ini',
    ),

    // ------------------------------------------------------------------------
    // 3. WARNA & KARAKTERISTIK DARAH
    // ------------------------------------------------------------------------
    FaqKnowledgeModel(
      id: 'darah_haid_hitam_cokelat',
      category: 'Karakteristik Darah',
      question:
          'Kenapa darah menstruasi berwarna cokelat tua atau hitam pekat?',
      answer:
          'Darah haid berwarna cokelat tua atau hitam adalah hal yang normal dan tidak berbahaya. Warna gelap ini merupakan darah lama yang tersimpan lebih lama di dalam rahim dan mengalami proses oksidasi saat bereaksi dengan oksigen.\n\nKondisi ini paling lazim ditemukan pada:\n- Hari pertama menstruasi: Darah sisa awal yang mengalir lambat.\n- Hari-hari terakhir menstruasi: Aliran darah mulai menipis sehingga membutuhkan waktu lebih lama untuk keluar dari liang vagina.',
      keywords: [
        'darah hitam',
        'darah coklat',
        'kenapa darah gelap',
        'darah pekat',
        'oksidasi darah',
        'darah tua',
      ],
      relatedChips: [
        'Penyebab darah haid menggumpal besar',
        'Perbedaan flek hamil vs flek haid',
      ],
    ),
    FaqKnowledgeModel(
      id: 'darah_haid_menggumpal',
      category: 'Karakteristik Darah',
      question:
          'Kenapa darah menstruasi menggumpal seperti jelly? Apakah berbahaya?',
      answer:
          'Gumpalan darah haid terbentuk karena tubuh melepaskan enzim antikoagulan alami untuk mencairkan darah sebelum dikeluarkan. Namun, pada hari-hari aliran deras (biasanya hari ke-1 dan 2), darah mengalir lebih cepat daripada kemampuan enzim untuk mencairkannya, sehingga sebagian darah menggumpal.\n\nKapan Wajar vs Bahaya:\n- Wajar: Gumpalan berukuran kecil (kurang dari ukuran uang koin 500 rupiah), berwarna merah gelap, dan hanya muncul di hari aliran deras.\n- Waspada: Gumpalan berukuran sangat besar (seperti bola golf), muncul terus menerus, atau membuat Anda harus berganti pembalut tebal setiap 1 jam sekali. Kondisi ini perlu pemeriksaan miom, polip, atau gangguan pembekuan darah.',
      keywords: [
        'darah menggumpal',
        'bekuan darah',
        'darah jelly',
        'gumpalan daging',
        'gumpalan haid',
        'gumpalan besar',
      ],
      relatedChips: [
        'Kenapa darah haid berwarna hitam?',
        'Kapan nyeri haid berbahaya atau endometriosis?',
      ],
      actionRoute: 'record',
      actionLabel: 'Catat Volume Darah',
    ),
    FaqKnowledgeModel(
      id: 'flek_hamil_vs_flek_haid',
      category: 'Karakteristik Darah',
      question:
          'Apa perbedaan flek tanda kehamilan (implantasi) dengan flek menjelang haid?',
      answer:
          'Perbedaan utama antara keduanya terletak pada warna, durasi, dan volume:\n\n1. Perdarahan Implantasi (Tanda Hamil):\n- Volume: Hanya beberapa tetes atau bercak tipis di celana dalam.\n- Warna: Cenderung merah muda samar atau cokelat terang.\n- Durasi: Singkat, hanya berlangsung 1 hingga 2 hari, dan tidak pernah berkembang menjadi aliran deras.\n- Gejala penyerta: Kram sangat ringan di satu titik perut.\n\n2. Flek Menjelang Haid:\n- Volume: Terus bertambah dalam 24-48 jam.\n- Perkembangan: Berubah menjadi aliran darah merah segar khas menstruasi.\n- Durasi: Berlanjut hingga 3-7 hari.',
      keywords: [
        'flek implantasi',
        'flek hamil',
        'beda flek',
        'bercak darah',
        'flek coklat',
        'tanda hamil atau haid',
      ],
      relatedChips: [
        'Perbedaan gejala PMS dan awal kehamilan',
        'Keputihan menjelang haid vs tanda kehamilan',
      ],
    ),

    // ------------------------------------------------------------------------
    // 4. KEPUTIHAN & KEBERSIHAN
    // ------------------------------------------------------------------------
    FaqKnowledgeModel(
      id: 'keputihan_normal_vs_infeksi',
      category: 'Keputihan',
      question:
          'Bagaimana membedakan keputihan normal dengan keputihan akibat infeksi?',
      answer:
          '1. Keputihan Fisiologis (Normal):\n- Warna: Bening transparan atau putih susu.\n- Tekstur: Encer atau elastis seperti putih telur mentah (terutama saat ovulasi).\n- Bau: Tidak berbau menyengat atau sedikit asam normal.\n- Sensasi: Tidak menimbulkan rasa gatal, panas, atau perih.\n\n2. Keputihan Patologis (Perlu Diobati):\n- Warna: Kuning pekat, kehijauan, atau abu-abu.\n- Tekstur: Menggumpal seperti ampas tahu/keju cottage (indikasi jamur Candida), atau berbusa encer.\n- Bau: Bau amis kuat (fishy odor) atau bau busuk menyengat.\n- Sensasi: Sangat gatal, nyeri saat buang air kecil, kemerahan di bibir vagina.',
      keywords: [
        'keputihan normal',
        'keputihan tidak normal',
        'keputihan gatal',
        'keputihan bau',
        'keputihan hijau',
        'keputihan ampas tahu',
      ],
      relatedChips: [
        'Keputihan menjelang haid vs tanda kehamilan',
        'Berapa jam sekali harus ganti pembalut?',
        'Bahaya sabun pembersih kewanitaan',
      ],
      actionRoute: 'record',
      actionLabel: 'Catat Keluhan Keputihan',
    ),
    FaqKnowledgeModel(
      id: 'keputihan_haid_vs_hamil',
      category: 'Keputihan',
      question:
          'Apa perbedaan keputihan menjelang haid dengan keputihan tanda kehamilan?',
      answer:
          '1. Menjelang Haid: Keputihan biasanya lebih sedikit, teksturnya cenderung kental dan lengket, berwarna keputihan atau sedikit kekuningan, dan menghilang saat menstruasi dimulai.\n\n2. Tanda Awal Kehamilan (Leukorea): Keputihan diproduksi dalam jumlah lebih banyak karena peningkatan hormon estrogen dan aliran darah ke dinding rahim. Teksturnya lebih cair atau licin seperti lendir bening/putih susu tanpa bau menyengat.\n\nCatatan Medis: Karena perbedaan fisik sulit dipastikan hanya dengan mata telanjang, cara paling valid bila terlambat haid adalah menggunakan alat tes kehamilan (test pack).',
      keywords: [
        'keputihan haid vs hamil',
        'leukorea',
        'keputihan tanda hamil',
        'keputihan sebelum haid',
      ],
      relatedChips: [
        'Perbedaan flek hamil vs flek haid',
        'Perbedaan gejala PMS dan awal kehamilan',
      ],
    ),
    FaqKnowledgeModel(
      id: 'ganti_pembalut_berapa_jam',
      category: 'Kebersihan Organ Intim',
      question:
          'Berapa jam sekali idealnya harus mengganti pembalut saat menstruasi?',
      answer:
          'Secara medis, pembalut wajib diganti setiap 3 hingga 4 jam sekali, bahkan jika pembalut belum terisi penuh darah. Darah menstruasi yang tertampung di pembalut menciptakan lingkungan yang hangat dan lembap, yang merupakan media ideal bagi perkembangbiakan bakteri dan jamur.\n\nBila aliran darah sedang sangat deras di hari pertama atau kedua, gantilah setiap 2 jam sekali untuk mencegah iritasi kulit (ruam pembalut) dan infeksi saluran kemih (ISK).',
      keywords: [
        'ganti pembalut',
        'berapa jam ganti pembalut',
        'kebersihan haid',
        'ruam pembalut',
        'hygiene menstruasi',
      ],
      relatedChips: [
        'Bahaya sabun pembersih kewanitaan',
        'Cara mencegah bau tidak sedap saat haid',
      ],
    ),
    FaqKnowledgeModel(
      id: 'sabun_kewanitaan',
      category: 'Kebersihan Organ Intim',
      question:
          'Apakah aman memakai sabun pembersih kewanitaan beraroma harum?',
      answer:
          'Dokter spesialis ginekologi tidak menganjurkan penggunaan sabun kewanitaan berpewangi atau produk douching (pembersih vagina ke dalam liang). Vagina memiliki mekanisme pembersihan alami (*self-cleaning*) yang diatur oleh bakteri baik Lactobacillus untuk menjaga derajat keasaman (pH 3.8 - 4.5).\n\nSabun berpewangi keras merusak flora normal dan mengikis lapisan pelindung, memicu infeksi jamur berulang (candidiasis) dan vaginosis bakterial. Cukup bersihkan area luar (vulva) dengan air bersih mengalir dari arah depan ke belakang.',
      keywords: [
        'sabun kewanitaan',
        'feminine wash',
        'pembersih vagina',
        'bau wangi',
        'douching',
        'ph vagina',
      ],
      relatedChips: [
        'Berapa jam sekali harus ganti pembalut?',
        'Bagaimana membedakan keputihan normal dan infeksi?',
      ],
    ),

    // ------------------------------------------------------------------------
    // 5. MASA SUBUR & OVULASI
    // ------------------------------------------------------------------------
    FaqKnowledgeModel(
      id: 'kapan_masa_subur',
      category: 'Masa Subur',
      question: 'Kapan masa subur (ovulasi) terjadi dalam siklus menstruasi?',
      answer:
          'Pada siklus menstruasi standar 28 hari, ovulasi umumnya terjadi sekitar hari ke-14 (tepatnya 14 hari sebelum hari pertama haid berikutnya). Masa subur (*fertile window*) mencakup 5 hari sebelum ovulasi hingga 1 hari setelah ovulasi.\n\nHal ini karena sel sperma dapat bertahan hidup di dalam saluran reproduksi wanita selama 3 hingga 5 hari, sedangkan sel telur yang telah dilepaskan hanya bertahan hidup selama 12 hingga 24 jam.',
      keywords: [
        'masa subur',
        'kapan ovulasi',
        'fertile window',
        'hari ovulasi',
        'kapan masa subur',
        'cara hitung masa subur',
      ],
      relatedChips: [
        'Ciri-ciri fisik saat sedang masa subur',
        'Apakah bisa hamil berhubungan saat haid?',
        'Apakah aplikasi ini bisa untuk alat kontrasepsi?',
      ],
      actionRoute: 'calendar',
      actionLabel: 'Cek Kalender Masa Subur',
    ),
    FaqKnowledgeModel(
      id: 'ciri_fisik_masa_subur',
      category: 'Masa Subur',
      question: 'Apa saja ciri-ciri fisik tubuh saat sedang dalam masa subur?',
      answer:
          'Tanda-tanda fisiologis masa subur meliputi:\n1. Perubahan Lendir Serviks: Lendir vagina menjadi sangat bening, licin, dan elastis (mirip putih telur mentah yang bisa ditarik tanpa putus).\n2. Peningkatan Suhu Tubuh Basal: Suhu tubuh saat baru bangun tidur naik sekitar 0.3 - 0.5 derajat Celsius setelah ovulasi.\n3. Nyeri Ovulasi (Mittelschmerz): Kram ringan atau sensasi kedutan di salah satu sisi perut bawah.\n4. Payudara Lebih Sensitif dan Libido Meningkat secara alami karena lonjakan hormon estrogen dan LH.',
      keywords: [
        'ciri masa subur',
        'lendir putih telur',
        'tanda ovulasi',
        'mittelschmerz',
        'suhu basal',
      ],
      relatedChips: [
        'Kapan masa subur terjadi?',
        'Apakah bisa hamil berhubungan saat haid?',
      ],
    ),
    FaqKnowledgeModel(
      id: 'hamil_saat_haid',
      category: 'Masa Subur',
      question:
          'Apakah wanita bisa hamil jika berhubungan intim saat sedang menstruasi?',
      answer:
          'Peluang kehamilan saat sedang haid tergolong rendah, namun kemungkinannya TIDAK pernah 0%. Peluang ini bisa terjadi jika:\n1. Siklus Haid Anda Pendek: Jika siklus Anda 21-24 hari, ovulasi dapat terjadi sangat cepat setelah menstruasi selesai.\n2. Daya Tahan Sperma: Sperma dapat bertahan hidup di dalam rahim hingga 5 hari. Hubungan intim di akhir masa haid bisa bertemu dengan sel telur yang matang lebih awal.\n3. Perdarahan Bukan Haid: Terkadang bercak ovulasi atau perdarahan serviks disalahartikan sebagai darah menstruasi.',
      keywords: [
        'hamil saat haid',
        'berhubungan saat haid',
        'apakah bisa hamil waktu menstruasi',
        'peluang hamil haid',
      ],
      relatedChips: [
        'Kapan masa subur terjadi?',
        'Apakah aplikasi ini bisa untuk alat kontrasepsi?',
      ],
    ),
    FaqKnowledgeModel(
      id: 'aplikasi_bukan_kontrasepsi',
      category: 'Masa Subur',
      question:
          'Apakah prediksi masa subur di aplikasi bisa dipakai sebagai metode KB alami?',
      answer:
          'Secara medis tegas dinyatakan: TIDAK. Kalmeda dan aplikasi kalender menstruasi lainnya berfungsi sebagai alat estimasi pola statistik dan edukasi kesehatan, bukan sebagai metode kontrasepsi medis.\n\nKarena ovulasi dapat bergeser sewaktu-waktu akibat stres, sakit, atau perubahan hormon, mengandalkan kalender saja untuk mencegah kehamilan memiliki tingkat kegagalan (*failure rate*) yang tinggi hingga 24%. Gunakan kontrasepsi medis teruji (seperti kondom, IUD, atau pil KB) setelah berkonsultasi dengan bidan/dokter.',
      keywords: [
        'alat kontrasepsi',
        'kb alami',
        'pencegah hamil',
        'metode kalender aman',
        'efektivitas aplikasi',
      ],
      relatedChips: [
        'Kapan masa subur terjadi?',
        'Apakah bisa hamil berhubungan saat haid?',
      ],
    ),

    // ------------------------------------------------------------------------
    // 6. PMS & SUASANA HATI
    // ------------------------------------------------------------------------
    FaqKnowledgeModel(
      id: 'perbedaan_pms_dan_pmdd',
      category: 'PMS & Mood',
      question: 'Apa perbedaan antara PMS biasa dengan PMDD?',
      answer:
          '1. PMS (Premenstrual Syndrome):\nDialami sekitar 75% wanita. Gejalanya meliputi kembung, mudah tersinggung, lelah, dan payudara nyeri. Gejala ini mengganggu namun tidak sampai melumpuhkan aktivitas harian.\n\n2. PMDD (Premenstrual Dysphoric Disorder):\nBentuk parah dari PMS yang dialami sekitar 3-8% wanita. Ditandai dengan ledakan emosi ekstrem, depresi berat, keputusasaan, kemarahan tak terkendali, kecemasan akut, hingga pikiran membahayakan diri sendiri.\n\nPMDD diakui sebagai gangguan medis neurobiologis terkait sensitivitas otak terhadap fluktuasi hormon, dan memerlukan penanganan dokter spesialis kesehatan jiwa (psikiater) atau Sp.OG.',
      keywords: [
        'pms',
        'pmdd',
        'perbedaan pms pmdd',
        'depresi sebelum haid',
        'marah sebelum haid',
        'gangguan mood parah',
      ],
      relatedChips: [
        'Kenapa nafsu makan naik drastis sebelum haid?',
        'Perbedaan gejala PMS dan awal kehamilan',
      ],
      actionRoute: 'record',
      actionLabel: 'Catat Mood Hari Ini',
    ),
    FaqKnowledgeModel(
      id: 'craving_makanan_sebelum_haid',
      category: 'PMS & Mood',
      question:
          'Kenapa nafsu makan melonjak tinggi (craving) sebelum menstruasi?',
      answer:
          'Keinginan kuat untuk makan makanan manis, gurih, atau berkarbohidrat tinggi (craving) sebelum haid dipicu oleh dua mekanisme biologis:\n1. Penurunan Hormon Serotonin: Menjelang haid, kadar hormon bahagia (serotonin) menurun, memicu otak mendambakan gula dan karbohidrat untuk menaikkan suasana hati secara instan.\n2. Peningkatan Hormon Progesteron: Sedikit meningkatkan laju metabolisme basal tubuh, sehingga tubuh secara alami membakar lebih banyak kalori dan mengirimkan sinyal rasa lapar ekstra.',
      keywords: [
        'craving',
        'nafsu makan tinggi',
        'lapar terus sebelum haid',
        'pengen makan manis',
        'makan banyak saat pms',
      ],
      relatedChips: [
        'Makanan yang dianjurkan dan dihindari saat haid',
        'Apa perbedaan PMS dan PMDD?',
      ],
    ),

    // ------------------------------------------------------------------------
    // 7. POLA HIDUP, NUTRISI & MITOS
    // ------------------------------------------------------------------------
    FaqKnowledgeModel(
      id: 'makanan_anjuran_pantangan_haid',
      category: 'Pola Hidup & Mitos',
      question:
          'Apa saja makanan yang dianjurkan dan makanan yang harus dihindari saat haid?',
      answer:
          '1. Makanan yang Sangat Dianjurkan:\n- Makanan Kaya Zat Besi: Bayam, daging merah tanpa lemak, brokoli, dan hati ayam untuk mengganti hemoglobin darah yang hilang.\n- Asam Lemak Omega-3: Ikan salmon, chia seed, dan kacang-kacangan untuk menekan inflamasi prostaglandin pereda kram.\n- Buah Kaya Kalium & Magnesium: Pisang, semangka, dan alpukat untuk meredakan kram otot dan kembung.\n\n2. Makanan yang Sebaiknya Dibatasi:\n- Makanan Sangat Asin/Garam Tinggi: Memperparah retensi air dan begah pada perut.\n- Minuman Tinggi Kafein (Kopi Pekat): Menyempitkan pembuluh darah yang bisa memperparah kram.\n- Minuman Beralkohol dan Makanan Sangat Pedas: Memicu iritasi saluran cerna dan diare haid.',
      keywords: [
        'makanan haid',
        'makanan dilarang haid',
        'pantangan haid',
        'nutrisi menstruasi',
        'makanan pereda nyeri',
      ],
      relatedChips: [
        'Cara meredakan kram perut tanpa obat',
        'Bolehkah olahraga saat haid?',
        'Mitos minum air es saat menstruasi',
      ],
    ),
    FaqKnowledgeModel(
      id: 'olahraga_saat_haid',
      category: 'Pola Hidup & Mitos',
      question: 'Apakah wanita boleh berolahraga saat sedang menstruasi?',
      answer:
          'Sangat boleh dan justru dianjurkan secara medis! Berolahraga ringan hingga sedang (seperti jalan santai, yoga, peregangan, atau bersepeda santai) memicu pelepasan hormon endorfin di otak.\n\nEndorfin berfungsi sebagai pereda nyeri alami tubuh (*natural painkiller*) yang terbukti efektif mengurangi kram perut, meredakan sakit kepala, dan memperbaiki suasana hati yang murung saat haid. Hindari latihan angkat beban berlebihan atau posisi inversi ekstrem jika Anda merasa pusing.',
      keywords: [
        'olahraga saat haid',
        'boleh olahraga',
        'fitness saat haid',
        'gym saat haid',
        'jalan santai haid',
      ],
      relatedChips: [
        'Cara meredakan kram perut tanpa obat',
        'Mitos keramas saat haid',
      ],
      actionRoute: 'record',
      actionLabel: 'Catat Aktivitas Olahraga',
    ),
    FaqKnowledgeModel(
      id: 'mitos_keramas_potong_kuku',
      category: 'Pola Hidup & Mitos',
      question:
          'Apakah benar tidak boleh keramas atau potong kuku saat sedang haid?',
      answer:
          'Mitos tersebut sama sekali TIDAK MEMILIKI DASAR MEDIS. Secara anatomi, pori-pori kulit kepala tidak memiliki hubungan langsung dengan pembuluh darah rahim.\n\nSebaliknya, menjaga kebersihan diri (mandi, keramas dengan air hangat, dan memotong kuku) sangat dianjurkan saat haid untuk mencegah infeksi bakteri, memberikan rasa segar, dan membantu merilekskan otot tubuh yang tegang.',
      keywords: [
        'keramas saat haid',
        'potong kuku haid',
        'mitos keramas',
        'boleh keramas',
        'mandi saat haid',
      ],
      relatedChips: [
        'Mitos minum air es saat menstruasi',
        'Berapa jam sekali harus ganti pembalut?',
      ],
    ),
    FaqKnowledgeModel(
      id: 'mitos_air_es_bekukan_darah',
      category: 'Pola Hidup & Mitos',
      question:
          'Benarkah minum air es atau minuman dingin membuat darah haid membeku atau memicu kista?',
      answer:
          'Mitos ini 100% SALAH. Sistem pencernaan dan sistem reproduksi wanita berada di saluran yang terpisah:\n- Air es masuk ke lambung dan suhu cairannya akan langsung disesuaikan dengan suhu internal tubuh (sekitar 37 derajat Celsius) sebelum diserap usus.\n- Darah haid berada di rongga rahim dan dikeluarkan melalui leher rahim dan vagina.\n\nAir dingin tidak bisa menjangkau rahim apalagi membekukan darah di dalamnya. Kista ovarium terbentuk karena gangguan hormonal atau sel abnormal, bukan karena air es.',
      keywords: [
        'air es',
        'minum es saat haid',
        'darah membeku',
        'air dingin haid',
        'mitos air es',
        'kista karena es',
      ],
      relatedChips: [
        'Mitos keramas saat haid',
        'Makanan yang dianjurkan dan dihindari saat haid',
      ],
    ),

    // ------------------------------------------------------------------------
    // 8. KONDISI KHUSUS (PCOS & KISTA)
    // ------------------------------------------------------------------------
    FaqKnowledgeModel(
      id: 'apa_itu_pcos',
      category: 'Kondisi Khusus',
      question:
          'Apa itu PCOS (Sindrom Ovarium Polikistik) dan apa saja tanda-tandanya?',
      answer:
          'PCOS adalah gangguan keseimbangan hormon reproduksi yang umum terjadi pada wanita usia subur. Pada PCOS, indung telur (ovarium) memproduksi hormon pria (androgen) secara berlebih, yang menyebabkan sel telur sulit matang dan tidak bisa dilepaskan secara rutin (anovulasi).\n\nTiga Tanda Utama Kriteria Rotterdam PCOS:\n1. Siklus Haid Tidak Teratur atau Sangat Jarang (oligomenore / amenore).\n2. Kelebihan Androgen Fisik: Tumbuh rambut halus berlebih di dagu/kumis/perut, jerawat parah di rahang, atau kerontokan rambut berpola pria.\n3. Gambaran Polikistik pada USG: Terlihat banyak kantung folikel kecil yang belum matang (seperti untaian mutiara) pada ovarium.\n\nPenanganan utama meliputi modifikasi gaya hidup (diet rendah indeks glikemik, olahraga rutin), penurunan resistensi insulin, dan terapi hormon sesuai arahan dokter spesialis kandungan.',
      keywords: [
        'pcos',
        'sindrom ovarium polikistik',
        'apa itu pcos',
        'gejala pcos',
        'tanda pcos',
        'sel telur kecil',
      ],
      relatedChips: [
        'Kapan keterlambatan haid harus ke dokter?',
        'Berapa hari rentang siklus normal?',
        'Kapan nyeri haid berbahaya atau endometriosis?',
      ],
    ),
  ];

  /// Returns list of available distinct categories.
  static List<String> get categories {
    return [
      'Semua',
      'Siklus Haid',
      'Nyeri & Kram',
      'Karakteristik Darah',
      'Keputihan',
      'Masa Subur',
      'PMS & Mood',
      'Pola Hidup & Mitos',
      'Kondisi Khusus',
    ];
  }

  /// Finds best direct match using tokenized keyword scoring and organ-conflict prevention.
  static FaqKnowledgeModel? findBestMatch(String query) {
    final cleanQuery = query.toLowerCase().trim();
    if (cleanQuery.isEmpty) return null;

    const stopWords = {
      'saya',
      'aku',
      'kamu',
      'dan',
      'ini',
      'itu',
      'ada',
      'apa',
      'kenapa',
      'mengapa',
      'bagaimana',
      'apakah',
      'kok',
      'bisa',
      'terasa',
      'rasa',
      'saat',
      'waktu',
      'pas',
      'lagi',
      'dong',
      'sih',
      'ya',
      'kan',
      'kak',
      'dok',
      'yang',
      'pada',
      'dari',
      'untuk',
      'dengan',
      'dalam',
      'terus',
      'saja',
      'banget',
    };

    final hasGenital =
        cleanQuery.contains('kemaluan') ||
        cleanQuery.contains('vagina') ||
        cleanQuery.contains('miss v') ||
        cleanQuery.contains('vulva');
    final hasBreast =
        cleanQuery.contains('payudara') ||
        cleanQuery.contains('dada') ||
        cleanQuery.contains('puting');

    FaqKnowledgeModel? bestEntry;
    int maxScore = 0;

    for (final entry in entries) {
      final entryLowerQ = entry.question.toLowerCase();
      final isBreastEntry =
          entryLowerQ.contains('payudara') || entryLowerQ.contains('dada');
      final isGenitalEntry =
          entryLowerQ.contains('kemaluan') ||
          entryLowerQ.contains('vagina') ||
          entryLowerQ.contains('miss v');

      // Prevent cross-organ false positive matches
      if (hasGenital && isBreastEntry) continue;
      if (hasBreast && isGenitalEntry) continue;

      int score = 0;

      // Exact question containment
      if (entryLowerQ.contains(cleanQuery) ||
          cleanQuery.contains(entryLowerQ)) {
        score += 25;
      }

      // Keyword match scoring (full phrase or all meaningful words match)
      for (final kw in entry.keywords) {
        final kwLower = kw.toLowerCase();
        if (cleanQuery.contains(kwLower)) {
          score += 15;
        } else {
          final kwWords = kwLower
              .split(RegExp(r'\s+'))
              .where((w) => w.length >= 3 && !stopWords.contains(w))
              .toList();
          if (kwWords.isNotEmpty &&
              kwWords.every((w) => cleanQuery.contains(w))) {
            score += 12;
          }
        }
      }

      // Filtered meaningful word tokens
      final queryTokens = cleanQuery
          .split(RegExp(r'\s+'))
          .map((t) => t.replaceAll(RegExp(r'[^\w]'), ''))
          .where((t) => t.length >= 3 && !stopWords.contains(t));

      for (final token in queryTokens) {
        if (entryLowerQ.contains(token)) score += 3;
        for (final kw in entry.keywords) {
          if (kw.toLowerCase().contains(token)) score += 2;
        }
      }

      if (score > maxScore) {
        maxScore = score;
        bestEntry = entry;
      }
    }

    // Threshold score to qualify as a confident direct match
    if (maxScore >= 10) {
      return bestEntry;
    }

    return null;
  }
}
