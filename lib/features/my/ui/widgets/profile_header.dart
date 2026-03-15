import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String? backgroundImage;
  final String? avatarImage;
  final String nickname;
  final String? bio;

  const ProfileHeader({
    super.key,
    this.backgroundImage,
    this.avatarImage,
    required this.nickname,
    this.bio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                image: backgroundImage != null
                    ? DecorationImage(
                        image: NetworkImage(backgroundImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: backgroundImage == null
                  ? Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    )
                  : null,
            ),
            Positioned(
              bottom: -50,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  backgroundImage: avatarImage != null
                      ? NetworkImage(avatarImage!)
                      : null,
                  child: avatarImage == null
                      ? Icon(Icons.person, size: 48, color: Colors.grey[600])
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 60),
        Text(
          nickname,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (bio != null) ...[
          const SizedBox(height: 8),
          Text(bio!, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ],
    );
  }
}
