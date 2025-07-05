import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:math_buddy_v1/pages/teacher/audio_widget.dart';

class SubtopicContentPage extends StatefulWidget {
  final String chapterId;
  final String subtopicId;
  final String subtopicTitle;

  const SubtopicContentPage({
    required this.chapterId,
    required this.subtopicId,
    required this.subtopicTitle,
    super.key,
  });

  @override
  State<SubtopicContentPage> createState() => _SubtopicContentPageState();
}

class _SubtopicContentPageState extends State<SubtopicContentPage> {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  void _showAddContentDialog() {
    final TextEditingController descController = TextEditingController();
    File? image1;
    File? image2;
    File? audioFile;

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
                                Icons.add_circle_outline,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Tambah Kandungan',
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
                                // Description Field
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
                                    controller: descController,
                                    decoration: InputDecoration(
                                      labelText: 'Penerangan',
                                      labelStyle: TextStyle(
                                        color: Colors.blue.shade600,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                    maxLines: 3,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Image 1 Selection
                                _buildFilePickerCard(
                                  title: 'Gambar 1',
                                  icon: Icons.image_outlined,
                                  file: image1,
                                  onTap: () async {
                                    final picked = await ImagePicker()
                                        .pickImage(source: ImageSource.gallery);
                                    if (picked != null) {
                                      setState(
                                        () => image1 = File(picked.path),
                                      );
                                    }
                                  },
                                  color: Colors.blue,
                                ),

                                const SizedBox(height: 12),

                                // Image 2 Selection
                                _buildFilePickerCard(
                                  title: 'Gambar 2',
                                  icon: Icons.image_outlined,
                                  file: image2,
                                  onTap: () async {
                                    final picked = await ImagePicker()
                                        .pickImage(source: ImageSource.gallery);
                                    if (picked != null) {
                                      setState(
                                        () => image2 = File(picked.path),
                                      );
                                    }
                                  },
                                  color: Colors.green,
                                ),

                                const SizedBox(height: 12),

                                // Audio Selection
                                // _buildFilePickerCard(
                                //   title: 'Audio *',
                                //   icon: Icons.audiotrack_outlined,
                                //   file: audioFile,
                                //   onTap: () async {
                                //     final picker = await FilePicker.platform
                                //         .pickFiles(type: FileType.audio);
                                //     if (picker != null &&
                                //         picker.files.single.path != null) {
                                //       setState(
                                //         () =>
                                //             audioFile = File(
                                //               picker.files.single.path!,
                                //             ),
                                //       );
                                //     }
                                //   },
                                //   color: Colors.orange,
                                //   isRequired: true,
                                // ),
                                // Audio Selection
                                _buildFilePickerCard(
                                  title: 'Audio *',
                                  icon: Icons.audiotrack_outlined,
                                  file: audioFile,
                                  onTap: () async {
                                    final result = await FilePicker.platform
                                        .pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: ['mp3'],
                                        );

                                    if (result != null &&
                                        result.files.single.path != null) {
                                      final selectedFile = File(
                                        result.files.single.path!,
                                      );
                                      final fileSizeInMB =
                                          await selectedFile.length() /
                                          (1024 * 1024);

                                      if (fileSizeInMB > 5) {
                                        // Show file too large error
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Row(
                                              children: [
                                                Icon(
                                                  Icons.warning,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  'Fail audio melebihi 5MB. Sila pilih semula.',
                                                ),
                                              ],
                                            ),
                                            backgroundColor:
                                                Colors.red.shade600,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      setState(() => audioFile = selectedFile);
                                    }
                                  },
                                  color: Colors.orange,
                                  isRequired: true,
                                ),

                                const SizedBox(height: 8),
                                Text(
                                  '* Medan wajib',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
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
                                    () => _handleSaveContent(
                                      context,
                                      descController,
                                      image1,
                                      image2,
                                      audioFile,
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

  void _showEditContentDialog(
    String contentId,
    Map<String, dynamic> contentData,
  ) {
    final TextEditingController descController = TextEditingController(
      text: contentData['description'] ?? '',
    );

    File? image1File;
    File? image2File;
    File? audioFile;

    String? existingImage1Url = contentData['imageUrl1'];
    String? existingImage2Url = contentData['imageUrl2'];
    String? existingAudioUrl = contentData['audioUrl'];

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
                            children: const [
                              Icon(Icons.edit, color: Colors.white),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Edit Kandungan',
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
                                // Description Field
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
                                    controller: descController,
                                    decoration: InputDecoration(
                                      labelText: 'Penerangan',
                                      labelStyle: TextStyle(
                                        color: Colors.blue.shade600,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                    maxLines: 3,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Image 1
                                _buildFilePickerCard(
                                  title: 'Gambar 1',
                                  icon: Icons.image_outlined,
                                  file: image1File ?? existingImage1Url,
                                  onTap: () async {
                                    final picked = await ImagePicker()
                                        .pickImage(source: ImageSource.gallery);
                                    if (picked != null) {
                                      setState(
                                        () => image1File = File(picked.path),
                                      );
                                    }
                                  },
                                  color: Colors.blue,
                                ),

                                const SizedBox(height: 12),

                                // Image 2
                                _buildFilePickerCard(
                                  title: 'Gambar 2',
                                  icon: Icons.image_outlined,
                                  file: image2File ?? existingImage2Url,
                                  onTap: () async {
                                    final picked = await ImagePicker()
                                        .pickImage(source: ImageSource.gallery);
                                    if (picked != null) {
                                      setState(
                                        () => image2File = File(picked.path),
                                      );
                                    }
                                  },
                                  color: Colors.green,
                                ),

                                const SizedBox(height: 12),

                                // Audio
                                _buildFilePickerCard(
                                  title: 'Audio *',
                                  icon: Icons.audiotrack_outlined,
                                  file: audioFile ?? existingAudioUrl,
                                  onTap: () async {
                                    final result = await FilePicker.platform
                                        .pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: ['mp3'],
                                        );
                                    if (result != null &&
                                        result.files.single.path != null) {
                                      final selectedFile = File(
                                        result.files.single.path!,
                                      );
                                      final fileSizeInMB =
                                          await selectedFile.length() /
                                          (1024 * 1024);
                                      if (fileSizeInMB > 5) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Row(
                                              children: [
                                                Icon(
                                                  Icons.warning,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  'Fail audio melebihi 5MB. Sila pilih semula.',
                                                ),
                                              ],
                                            ),
                                            backgroundColor:
                                                Colors.red.shade600,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      setState(() => audioFile = selectedFile);
                                    }
                                  },
                                  color: Colors.orange,
                                  isRequired: true,
                                ),

                                const SizedBox(height: 8),
                                Text(
                                  '* Medan wajib',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
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
                                    () => _handleUpdateContent(
                                      context,
                                      contentId,
                                      descController,
                                      image1File,
                                      image2File,
                                      audioFile,
                                      existingImage1Url,
                                      existingImage2Url,
                                      existingAudioUrl,
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

  Future<void> _handleUpdateContent(
    BuildContext context,
    String contentId,
    TextEditingController descController,
    File? image1File,
    File? image2File,
    File? audioFile,
    String? existingImage1Url,
    String? existingImage2Url,
    String? existingAudioUrl,
  ) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance
        .collection('chapters')
        .doc(widget.chapterId)
        .collection('subtopics')
        .doc(widget.subtopicId)
        .collection('contents')
        .doc(contentId);

    Map<String, dynamic> updatedData = {
      'description': descController.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

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
                  'Memuat naik kandungan...',
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
      final storage = FirebaseStorage.instance;

      // Upload new image1 if changed
      if (image1File != null) {
        final ref = storage.ref('contents/$userId/${contentId}_img1.jpg');
        await ref.putFile(image1File).timeout(const Duration(minutes: 2));
        final url = await ref.getDownloadURL();
        updatedData['imageUrl1'] = url;
      } else {
        updatedData['imageUrl1'] = existingImage1Url;
      }

      // Upload new image2 if changed
      if (image2File != null) {
        final ref = storage.ref('contents/$userId/${contentId}_img2.jpg');
        await ref.putFile(image2File).timeout(const Duration(minutes: 2));
        final url = await ref.getDownloadURL();
        updatedData['imageUrl2'] = url;
      } else {
        updatedData['imageUrl2'] = existingImage2Url;
      }

      // Upload new audio if changed
      if (audioFile != null) {
        final ref = storage.ref('contents/$userId/${contentId}_audio.mp3');
        await ref.putFile(audioFile).timeout(const Duration(minutes: 2));
        final url = await ref.getDownloadURL();
        updatedData['audioUrl'] = url;
      } else {
        updatedData['audioUrl'] = existingAudioUrl;
      }

      // Update Firestore document
      await docRef.update(updatedData);

      // Close loading dialog
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Kandungan berjaya dikemaskini!'),
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
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!); // Close loading dialog
      }
      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Close edit dialog
      }

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Ralat semasa kemaskini: ${e.toString()}')),
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

  // Audio dialog with controls
  void _showAudioDialog(BuildContext context, String audioUrl) {
    showDialog(
      context: context,
      builder: (context) => AudioPlayerDialog(audioUrl: audioUrl),
    );
  }

  // Widget _buildFilePickerCard({
  //   required String title,
  //   required IconData icon,
  //   required File? file,
  //   required VoidCallback onTap,
  //   required MaterialColor color,
  //   bool isRequired = false,
  // }) {
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(
  //         color: file != null ? color.shade300 : Colors.grey.shade300,
  //         width: 2,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.grey.shade100,
  //           blurRadius: 4,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: InkWell(
  //       onTap: onTap,
  //       borderRadius: BorderRadius.circular(12),
  //       child: Padding(
  //         padding: const EdgeInsets.all(16),
  //         child: Row(
  //           children: [
  //             Container(
  //               width: 48,
  //               height: 48,
  //               decoration: BoxDecoration(
  //                 color: color.shade100,
  //                 shape: BoxShape.circle,
  //               ),
  //               child: Icon(
  //                 file != null ? Icons.check_circle : icon,
  //                 color: file != null ? color.shade700 : color.shade600,
  //                 size: 24,
  //               ),
  //             ),
  //             const SizedBox(width: 16),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     title,
  //                     style: TextStyle(
  //                       fontWeight: FontWeight.w600,
  //                       fontSize: 16,
  //                       color: Colors.grey.shade800,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     file != null
  //                         ? file.path.split('/').last
  //                         : 'Ketik untuk memilih fail',
  //                     style: TextStyle(
  //                       color:
  //                           file != null
  //                               ? color.shade700
  //                               : Colors.grey.shade600,
  //                       fontSize: 14,
  //                       fontWeight:
  //                           file != null ? FontWeight.w500 : FontWeight.normal,
  //                     ),
  //                     maxLines: 1,
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             Icon(
  //               Icons.arrow_forward_ios,
  //               color: Colors.grey.shade400,
  //               size: 16,
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildFilePickerCard({
    required String title,
    required IconData icon,
    required dynamic file, // Accept File or String (URL)
    required VoidCallback onTap,
    required MaterialColor color,
    bool isRequired = false,
  }) {
    String fileName = 'Ketik untuk memilih fail';
    bool isSelected = false;

    if (file is File) {
      fileName = file.path.split('/').last;
      isSelected = true;
    } else if (file is String && file.isNotEmpty) {
      fileName = Uri.parse(file).pathSegments.last;
      isSelected = true;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color.shade300 : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSelected ? Icons.check_circle : icon,
                  color: isSelected ? color.shade700 : color.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fileName,
                      style: TextStyle(
                        color:
                            isSelected ? color.shade700 : Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSaveContent(
    BuildContext context,

    TextEditingController descController,
    File? image1,
    File? image2,
    File? audioFile,
  ) async {
    if (descController.text.trim().isEmpty || audioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Lengkapkan penerangan dan audio.'),
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

    // Close the form dialog first
    Navigator.pop(context);

    // Show loading dialog
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
                  'Memuat naik kandungan...',
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
      final docRef =
          FirebaseFirestore.instance
              .collection('chapters')
              .doc(widget.chapterId)
              .collection('subtopics')
              .doc(widget.subtopicId)
              .collection('contents')
              .doc();

      final contentId = docRef.id;

      // Upload files
      String? url1, url2, audioUrl;

      if (image1 != null) {
        final ref1 = _storage.ref('contents/$userId/${contentId}_img1.jpg');
        await ref1.putFile(image1);
        url1 = await ref1.getDownloadURL();
      }

      if (image2 != null) {
        final ref2 = _storage.ref('contents/$userId/${contentId}_img2.jpg');
        await ref2.putFile(image2);
        url2 = await ref2.getDownloadURL();
      }

      final audioRef = _storage.ref('contents/$userId/${contentId}_audio.mp3');
      // await audioRef.putFile(audioFile!);
      await audioRef.putFile(audioFile!).timeout(const Duration(minutes: 2));

      audioUrl = await audioRef.getDownloadURL();

      // Save to Firestore
      await docRef.set({
        'description': descController.text.trim(),
        'imageUrl1': url1,
        'imageUrl2': url2,
        'audioUrl': audioUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Kandungan berjaya disimpan!'),
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
      // Close loading dialog
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Ralat semasa muat naik: ${e.toString()}')),
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

  @override
  Widget build(BuildContext context) {
    final contentRef = FirebaseFirestore.instance
        .collection('chapters')
        .doc(widget.chapterId)
        .collection('subtopics')
        .doc(widget.subtopicId)
        .collection('contents');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Kandungan - ${widget.subtopicTitle}'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: contentRef.orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
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
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Memuatkan kandungan...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            // Handle error
            // return Center(child: Text('Error: ${snapshot.error}'));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Gagal memuatkan kandungan')),
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
          } else if (snapshot.connectionState == ConnectionState.done) {
            if (mounted) {
              Navigator.pop(context);
            }
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    color: Colors.grey.shade400,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tiada kandungan ditambah',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ketik butang + untuk menambah kandungan pertama',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              // print(data.data());
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
                    // Content Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade100, Colors.blue.shade50],
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
                              color: Colors.blue.shade600,
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
                              'Kandungan',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue.shade400),
                            onPressed:
                                () => _showEditContentDialog(
                                  data.id,
                                  data.data() as Map<String, dynamic>,
                                  // contentRef,
                                ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade400,
                            ),
                            onPressed:
                                () => _showDeleteDialog(
                                  context,
                                  data,
                                  contentRef,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Content Body
                    Padding(
                      padding: EdgeInsets.all(
                        MediaQuery.of(context).size.width < 350 ? 12 : 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description
                          Text(
                            data['description'] ?? '',
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width < 350
                                      ? 14
                                      : 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Media Files
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (data['imageUrl1'] != null)
                                _buildMediaChip(
                                  'Gambar 1',
                                  Icons.image,
                                  Colors.blue,
                                  () => _showImageDialog(
                                    context,
                                    data['imageUrl1'],
                                  ),
                                ),
                              if (data['imageUrl2'] != null)
                                _buildMediaChip(
                                  'Gambar 2',
                                  Icons.image,
                                  Colors.green,
                                  () => _showImageDialog(
                                    context,
                                    data['imageUrl2'],
                                  ),
                                ),
                              if (data['audioUrl'] != null)
                                _buildMediaChip(
                                  'Audio',
                                  Icons.audiotrack,
                                  Colors.orange,
                                  () => _showAudioDialog(
                                    context,
                                    data['audioUrl'],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddContentDialog,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Kandungan',
          style: TextStyle(fontWeight: FontWeight.w600),
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

  Future<void> _showDeleteDialog(
    BuildContext context,
    QueryDocumentSnapshot data,
    CollectionReference contentRef,
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
                    'Padam Kandungan',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Adakah anda pasti mahu memadam kandungan ini? Tindakan ini tidak boleh dibatalkan.',
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
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final contentId = data.id;

      // Delete associated files in Firebase Storage
      final image1Ref = _storage.ref('contents/$userId/${contentId}_img1.jpg');
      final image2Ref = _storage.ref('contents/$userId/${contentId}_img2.jpg');
      final audioRef = _storage.ref('contents/$userId/${contentId}_audio.mp3');

      await Future.wait([
        image1Ref.delete().catchError((_) {}),
        image2Ref.delete().catchError((_) {}),
        audioRef.delete().catchError((_) {}),
      ]);

      // Delete Firestore document
      await contentRef.doc(contentId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Kandungan berjaya dipadam!'),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Gagal memadam kandungan: ${e.toString()}')),
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
}
