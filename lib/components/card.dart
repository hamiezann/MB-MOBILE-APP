import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class TopicCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const TopicCard({
    required this.title,
    required this.imagePath,
    required this.onTap,
    super.key,
  });

  bool isUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      // isUrl(imagePath)
                      //     ? Image.network(
                      //       imagePath,
                      //       fit: BoxFit.contain,
                      //       loadingBuilder: (context, child, loadingProgress) {
                      //         if (loadingProgress == null) return child;
                      //         return const Center(
                      //           child: CircularProgressIndicator(),
                      //         );
                      //       },
                      //       errorBuilder:
                      //           (context, error, stackTrace) =>
                      //               const Icon(Icons.broken_image),
                      //     )
                      //     : Image.asset(imagePath, fit: BoxFit.contain),
                      isUrl(imagePath)
                          ? CachedNetworkImage(
                            imageUrl: imagePath,
                            // height: screenWidth * 1.8,
                            fit: BoxFit.contain,
                            placeholder:
                                (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            errorWidget:
                                (context, url, error) =>
                                    const Icon(Icons.broken_image),
                          )
                          : Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                            // height: screenWidth * 1.8,
                          ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
