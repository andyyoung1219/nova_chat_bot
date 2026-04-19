import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SkyCard extends StatelessWidget {
  final String title;
  final String date;
  final String imageUrl;
  final String? userName;
  final GlobalKey boundaryKey;

  const SkyCard({
    super.key,
    required this.title,
    required this.date,
    required this.imageUrl,
    this.userName,
    required this.boundaryKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: 320,
        color: const Color(0xFF0B0D17),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (userName != null && userName!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${userName!.trim()}',
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const Text(
              '🎂 Happy Birthday! 🎂',
              style: TextStyle(color: Colors.pinkAccent, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: 250, //
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(
                  height: 250,
                  child: Center(child: CircularProgressIndicator(color: Colors.amber)),
                ),
                errorWidget: (context, url, error) => const SizedBox(
                  height: 250,
                  child: Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 48)),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '$date',
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}