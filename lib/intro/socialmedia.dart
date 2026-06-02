import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLinks extends StatelessWidget {
  const SocialLinks({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  Widget _buildSocialIcon(IconData icon, String url, Color color) {
    return GestureDetector(
      onTap: () => _launchURL(url),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color,
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Follow Us',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black54,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSocialIcon(
                Icons.ondemand_video, 'https://www.youtube.com/@ridealmobility', Colors.red),
            _buildSocialIcon(
                Icons.facebook, 'https://www.facebook.com/profile.php?id=61579358969926', Colors.blue.shade800),
            _buildSocialIcon(
                Icons.alternate_email, 'https://x.com/ridealmobi18276', Colors.black),
            _buildSocialIcon(
                Icons.camera_alt, 'https://www.instagram.com/ridealmobility__/', Colors.pink),
            _buildSocialIcon(
                Icons.send, 'https://t.me/RiDealIndia', Colors.blue),
          ],
        ),
      ],
    );
  }
}
