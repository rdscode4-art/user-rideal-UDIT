import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

class Favorites extends StatefulWidget {
  const Favorites({super.key});

  @override
  State<Favorites> createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> with SingleTickerProviderStateMixin {
  static const Color brandGreen = Color(0xFF0F9D58);

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Simulated favorites list — replace with real data source when available
  final List<Map<String, dynamic>> _favorites = [
    {'title': 'Office', 'subtitle': '2972 Westheimer Rd. Santa Ana, Illinois 85486', 'icon': Icons.business_rounded},
    {'title': 'Home', 'subtitle': '123 Main Street, Springfield, IL 62704', 'icon': Icons.home_rounded},
    {'title': 'Office', 'subtitle': '2972 Westheimer Rd. Santa Ana, Illinois 85486', 'icon': Icons.business_rounded},
    {'title': 'Home', 'subtitle': '123 Main Street, Springfield, IL 62704', 'icon': Icons.home_rounded},
    {'title': 'Office', 'subtitle': '2972 Westheimer Rd. Santa Ana, Illinois 85486', 'icon': Icons.business_rounded},
    {'title': 'Home', 'subtitle': '123 Main Street, Springfield, IL 62704', 'icon': Icons.home_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _removeItem(int index) {
    setState(() => _favorites.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // Custom Floating Header
              Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                      ),
                    ),
                    Text(
                      'Favourites',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Quick feedback to indicate place creation
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("📍 Select a place to add to Favourites"),
                            backgroundColor: brandGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.add_location_alt_rounded, color: brandGreen, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Count chip with premium branding
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.w),
                    decoration: BoxDecoration(
                      color: brandGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_rounded, color: brandGreen, size: 14),
                        SizedBox(width: 6.w),
                        Text(
                          '${_favorites.length} saved places',
                          style: TextStyle(
                            color: brandGreen,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.w),

              // List View
              Expanded(
                child: _favorites.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.w),
                        itemCount: _favorites.length,
                        itemBuilder: (context, index) {
                          return _buildFavoriteCard(_favorites[index], index);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> item, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.w),
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: brandGreen.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(item['icon'] as IconData, color: brandGreen, size: 20),
        ),
        title: Text(
          item['title'] as String,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15.sp,
            color: Colors.black87,
            letterSpacing: -0.3,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4.w),
          child: Text(
            item['subtitle'] as String,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: GestureDetector(
          onTap: () => _showDeleteConfirm(index),
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 18),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade500),
            SizedBox(width: 10.w),
            Text(
              'Remove Place',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18.sp),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove this place from your Favourites?',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp, height: 1.4.w),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeItem(index);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.w),
              elevation: 0,
            ),
            child: Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(28.w),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              Icons.favorite_border_rounded,
              size: 56,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 24.w),
          Text(
            'No Favourites Yet',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 8.w),
          Text(
            'Save your frequent places for quick access',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
