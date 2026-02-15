import 'package:flutter/material.dart';

class StoreAppBar extends StatelessWidget  {
  final String title;
  final String? status;
  final String? profileImage;

  const StoreAppBar({
    super.key,
    required this.title,
    this.status,
    this.profileImage,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 80,
      elevation: 0,
      backgroundColor: const Color(0xFF2196F3),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0593FF), Color(0xFF0476D9)],
          ),
        ),
      ),
      title: Row(
        children: [
          _buildProfileImage(),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusText(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
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
  }

  Widget _buildProfileImage() {
  if (profileImage == null || profileImage!.isEmpty) {
    return _fallbackImage();
  }

  return ClipOval(
    child: Image.network(
      profileImage!,
      width: 50,
      height: 50,
      fit: BoxFit.cover,

      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },

      errorBuilder: (_, __, ___) => _fallbackImage(),
    ),
  );
}


  Widget _fallbackImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        'assets/images/logo.png',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.store,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    final s = status?.toLowerCase() ?? '';
    if (['เปิดร้าน'].contains(s)) {
      return Colors.greenAccent;
    }
    if ([ 'ปิดชั่วคราว'].contains(s)) {
      return Colors.redAccent;
    }
    return Colors.grey;
  }

  String _getStatusText() {
    final s = status ?? '';
    switch (s) {
      case 'เปิดร้าน':
        return 'เปิดให้บริการ';
      case 'ปิดชั่วคราว':
        return 'ปิดชั่วคราว';
      case '':
        return 'กำลังโหลด...';
      default:
        return s;
    }
  }


}
