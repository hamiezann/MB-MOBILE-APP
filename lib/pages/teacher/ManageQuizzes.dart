import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ManageQuizContentPage extends StatefulWidget {
  final String chapterId;
  final String quizId;
  const ManageQuizContentPage({
    required this.chapterId,
    required this.quizId,
    super.key,
  });

  @override
  State<ManageQuizContentPage> createState() => _ManageQuizContentPageState();
}

class _ManageQuizContentPageState extends State<ManageQuizContentPage> {
  List<DocumentSnapshot> _quizList = [];

  @override
  void initState() {
    super.initState();
    _fetchQuizContent();
  }

  Future<void> _fetchQuizContent() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('chapters')
              .doc(widget.chapterId)
              .collection('quizzes')
              .doc(widget.quizId)
              .collection('questions')
              .orderBy('createdAt', descending: true)
              .get();

      setState(() {
        _quizList = snapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Gagal memuatkan soalan kuiz: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<Map<String, String>> _uploadImage(File imageFile) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final fileName = 'quiz_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storagePath = 'quizzes/$userId/$fileName';

    final ref = FirebaseStorage.instance.ref().child(storagePath);
    await ref.putFile(imageFile);
    final downloadUrl = await ref.getDownloadURL();

    return {'downloadUrl': downloadUrl, 'storagePath': storagePath};
  }

  void _showAddQuizDialog() {
    final TextEditingController jawapan1Controller = TextEditingController();
    final TextEditingController jawapan2Controller = TextEditingController();
    final TextEditingController jawapanBetulController =
        TextEditingController();
    File? selectedImage;
    final dialogWidth = MediaQuery.of(context).size.width * 0.9;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Material(
                  type: MaterialType.transparency,
                  child: Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 16,
                    child: Container(
                      width: dialogWidth,
                      constraints: const BoxConstraints(maxHeight: 600),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.teal.shade50, Colors.white],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.teal.shade600,
                                  Colors.teal.shade400,
                                ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.quiz_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Tambah Soalan Quiz',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Content
                          Flexible(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Jawapan 1
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade200,
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: jawapan1Controller,
                                      decoration: InputDecoration(
                                        labelText: 'Jawapan A',
                                        labelStyle: TextStyle(
                                          color: Colors.teal.shade600,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Jawapan 2
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade200,
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: jawapan2Controller,
                                      decoration: InputDecoration(
                                        labelText: 'Jawapan B',
                                        labelStyle: TextStyle(
                                          color: Colors.teal.shade600,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Jawapan Betul
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.shade200,
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: jawapanBetulController,
                                      decoration: InputDecoration(
                                        labelText: 'Jawapan Betul (A atau B)',
                                        labelStyle: TextStyle(
                                          color: Colors.teal.shade600,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.all(
                                          16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Gambar Soalan
                                  _buildFilePickerCard(
                                    title: 'Gambar Soalan',
                                    icon: Icons.image,
                                    file: selectedImage,
                                    onTap: () async {
                                      final picked = await ImagePicker()
                                          .pickImage(
                                            source: ImageSource.gallery,
                                          );
                                      if (picked != null) {
                                        setState(
                                          () =>
                                              selectedImage = File(picked.path),
                                        );
                                      }
                                    },
                                    color: Colors.teal,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Actions
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text(
                                    'Batal',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  // onPressed:
                                  //     () => _handleSaveQuizQuestion(
                                  //       context: context,
                                  //       chapterId: widget.chapterId,
                                  //       quizId: widget.quizId,
                                  //       questionImage: selectedImage,
                                  //       optionA: jawapan1Controller.text,
                                  //       optionB: jawapan2Controller.text,
                                  //       correctAnswer:
                                  //           jawapanBetulController.text,
                                  //     ),
                                  onPressed: () {
                                    final jawapan1 =
                                        jawapan1Controller.text.trim();
                                    final jawapan2 =
                                        jawapan2Controller.text.trim();
                                    final jawapanBetul =
                                        jawapanBetulController.text.trim();

                                    if (jawapanBetul != jawapan1 &&
                                        jawapanBetul != jawapan2) {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (_) => AlertDialog(
                                              title: const Text('Ralat'),
                                              content: const Text(
                                                'Jawapan betul mesti sama dengan salah satu jawapan A atau B.',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                      );
                                      return;
                                    }

                                    _handleSaveQuizQuestion(
                                      context: context,
                                      chapterId: widget.chapterId,
                                      quizId: widget.quizId,
                                      questionImage: selectedImage,
                                      optionA: jawapan1,
                                      optionB: jawapan2,
                                      correctAnswer: jawapanBetul,
                                    );
                                  },

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.save_outlined, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Simpan',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildFilePickerCard({
    required String title,
    required IconData icon,
    required File? file,
    required VoidCallback onTap,
    required MaterialColor color,
    bool isRequired = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: file != null ? color.shade300 : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                file != null ? Icons.check_circle : icon,
                // color: color,
                color: file != null ? color : Colors.grey,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  file != null
                      ? file.path.split('/').last
                      : 'Ketik untuk memilih gambar',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStyledQuizCard(
    int index,
    Map<String, dynamic> quiz,
    String docId,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade100, Colors.purple.shade50],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Soalan Kuiz',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.purple.shade400),
                  onPressed: () => _showEditQuizDialog(docId, quiz),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  onPressed:
                      () => _showDeleteDialog(
                        context,
                        widget.chapterId,
                        widget.quizId,
                        docId,
                      ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "A: ${quiz['optionA']}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "B: ${quiz['optionB']}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Jawapan Betul: ${quiz['correctAnswer']}",
                  style: TextStyle(color: Colors.green.shade700),
                ),
                const SizedBox(height: 12),
                if (quiz['imagePaths'] != null &&
                    quiz['imagePaths'].toString().isNotEmpty)
                  // ClipRRect(
                  //   borderRadius: BorderRadius.circular(12),
                  //   child: CachedNetworkImage(
                  //     imageUrl: quiz['imagePaths'],
                  //     height: 120,
                  //     width: double.infinity,
                  //     fit: BoxFit.cover,
                  //     placeholder:
                  //         (context, url) =>
                  //             const Center(child: CircularProgressIndicator()),
                  //     errorWidget:
                  //         (context, url, error) => Icon(
                  //           Icons.broken_image,
                  //           size: 48,
                  //           color: Colors.grey.shade400,
                  //         ),
                  //   ),
                  // ),
                  Row(
                    children: [
                      _buildMediaChip(
                        'Gambar Soalan',
                        Icons.image,
                        Colors.purple,
                        () => _showImageDialog(context, quiz['imagePaths']),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Urus Soalan Kuiz'),
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body:
          _quizList.isEmpty
              ?
              // const Center(child: Text("Tiada soalan quiz"))
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade400,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Ralat memuat kandungan',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _quizList.length,
                itemBuilder: (context, index) {
                  final quiz = _quizList[index].data() as Map<String, dynamic>;
                  final docId = _quizList[index].id;

                  return buildStyledQuizCard(index, quiz, docId);
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQuizDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    String chapterId,
    String quizId,
    String questionId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.red.shade50, Colors.white],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade600,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Padam Soalan Kuiz',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Adakah anda pasti mahu memadam soalan ini? Tindakan ini tidak boleh dibatalkan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Padam',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );

    if (confirm != true) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('chapters')
          .doc(chapterId)
          .collection('quizzes')
          .doc(quizId)
          .collection('questions')
          .doc(questionId);

      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final storagePath = data['imageStoragePath'] as String?;

        if (storagePath != null && storagePath.isNotEmpty) {
          try {
            final ref = FirebaseStorage.instance.ref(storagePath);
            await ref.delete();
          } catch (e) {
            debugPrint('Failed to delete image: $e');
          }
        }

        await docRef.delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Soalan kuiz berjaya dipadam!'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

      await _fetchQuizContent(); // Refresh content
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Gagal memadam soalan: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showEditQuizDialog(String questionId, Map<String, dynamic> quizData) {
    File? selectedImage;
    final TextEditingController optionAController = TextEditingController(
      text: quizData['optionA'],
    );
    final TextEditingController optionBController = TextEditingController(
      text: quizData['optionB'],
    );
    final TextEditingController correctAnswerController = TextEditingController(
      text: quizData['correctAnswer'],
    );
    String currentImageUrl = quizData['imagePaths'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 16,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints: const BoxConstraints(maxHeight: 600),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.blue.shade50, Colors.white],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade600,
                                Colors.blue.shade400,
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.edit_note,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Edit Soalan Kuiz',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Content
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Option A
                                _buildStyledTextField(
                                  controller: optionAController,
                                  label: 'Jawapan A',
                                ),
                                const SizedBox(height: 12),

                                // Option B
                                _buildStyledTextField(
                                  controller: optionBController,
                                  label: 'Jawapan B',
                                ),
                                const SizedBox(height: 12),

                                // Correct Answer
                                _buildStyledTextField(
                                  controller: correctAnswerController,
                                  label: 'Jawapan Betul (A atau B)',
                                ),
                                const SizedBox(height: 12),

                                // Current image
                                if (currentImageUrl.isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Gambar Semasa:",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
                                          imageUrl: currentImageUrl,
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          placeholder:
                                              (context, url) => const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                          errorWidget:
                                              (context, url, error) => Icon(
                                                Icons.image_not_supported,
                                                color: Colors.red,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),

                                // New image picker
                                _buildFilePickerCard(
                                  title: 'Gambar Baru (Opsyenal)',
                                  icon: Icons.image,
                                  file: selectedImage,
                                  onTap: () async {
                                    final picked = await ImagePicker()
                                        .pickImage(source: ImageSource.gallery);
                                    if (picked != null) {
                                      setState(
                                        () => selectedImage = File(picked.path),
                                      );
                                    }
                                  },
                                  color: Colors.orange,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Actions
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  'Batal',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed:
                                    () => _handleSaveQuizQuestion(
                                      context: context,
                                      chapterId: widget.chapterId,
                                      quizId: widget.quizId,
                                      questionImage: selectedImage,
                                      optionA: optionAController.text,
                                      optionB: optionBController.text,
                                      correctAnswer:
                                          correctAnswerController.text,
                                      questionId: questionId,
                                    ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.save_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Simpan',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blue.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Future<void> _handleSaveQuizQuestion({
    required BuildContext context,
    required String chapterId,
    required String quizId,
    File? questionImage,
    required String optionA,
    required String optionB,
    required String correctAnswer,
    String? questionId, // If null = add new; if not null = edit existing
  }) async {
    if (optionA.isEmpty || optionB.isEmpty || correctAnswer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Sila isi semua pilihan dan jawapan betul.'),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    Navigator.pop(context);

    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogContext = ctx;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.white],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 20),
                Text(
                  questionId == null
                      ? 'Memuat naik soalan kuiz...'
                      : 'Mengemas kini soalan kuiz...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sila tunggu sebentar',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      final docRef = FirebaseFirestore.instance
          .collection('chapters')
          .doc(chapterId)
          .collection('quizzes')
          .doc(quizId)
          .collection('questions')
          .doc(
            questionId ?? FirebaseFirestore.instance.collection('tmp').doc().id,
          );

      final actualQuestionId = docRef.id;

      Map<String, String>? uploadResult;
      if (questionImage != null) {
        uploadResult = await _uploadImage(questionImage);
      }
      final data = {
        'optionA': optionA.trim(),
        'optionB': optionB.trim(),
        'correctAnswer': correctAnswer.trim(),
        // 'imagePath': imageUrl ?? '',
        'imagePaths': uploadResult?['downloadUrl'],
        'imageStoragePath': uploadResult?['storagePath'], // 🔐 Save this!F
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (questionId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(data, SetOptions(merge: true));

      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }

      await _fetchQuizContent();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                questionId == null
                    ? 'Soalan kuiz berjaya disimpan!'
                    : 'Soalan kuiz berjaya dikemas kini!',
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Ralat semasa simpan kuiz: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: const Text('Image'),
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder:
                            (context, url) => const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Loading image...'),
                                ],
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  SizedBox(height: 16),
                                  Text('Failed to load image'),
                                ],
                              ),
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildMediaChip(
    String label,
    IconData icon,
    MaterialColor color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color.shade700),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
