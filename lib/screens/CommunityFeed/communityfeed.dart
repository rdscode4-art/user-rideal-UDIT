import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:rideal/widget/CommunityFeedCardWidget.dart';
import 'package:rideal/authservices.dart';

class RiDealFeedScreen extends StatefulWidget {
  const RiDealFeedScreen({super.key});

  @override
  State<RiDealFeedScreen> createState() => _RiDealFeedScreenState();
}

class _RiDealFeedScreenState extends State<RiDealFeedScreen>
    with SingleTickerProviderStateMixin {
  static const Color brandGreen = Color(0xFF0F9D58);

  List<Map<String, dynamic>> feedItems = [];
  bool _isLoading = true;
  String _errorMessage = '';

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _loadCommunityFeed();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _parseApiResponse(Map<String, dynamic> apiResponse) {
    final feedList = (apiResponse['feed'] as List?) ?? [];
    return feedList.map((item) {
      var rawUrl = item['imageUrl'] ?? '';
      if (rawUrl.startsWith('//uploads')) {
        rawUrl = rawUrl.replaceFirst('//uploads', '/uploads');
      }
      return {
        "title": item['content'] ?? 'No content',
        "imageUrl": rawUrl.isNotEmpty ? "${Authservices.baseUrl}$rawUrl" : null,
        "actionLabel": "View",
      };
    }).toList();
  }

  Future<void> _loadCommunityFeed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await Authservices.getCommunityFeed();
      if (mounted) {
        if (result['success'] == true && result['data'] != null) {
          setState(() {
            feedItems = _parseApiResponse(result['data']);
            _isLoading = false;
          });
          _animController.forward(from: 0);
        } else {
          setState(() {
            _errorMessage = result['message'] ?? "Something went wrong";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load feed: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Floating Header
            Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: brandGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Image.asset(
                      "assets/images/logorideal.png",
                      height: 24.w,
                      width: 24.w,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Community Feed',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: _loadCommunityFeed,
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(Icons.refresh_rounded, color: Colors.black54, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage.isNotEmpty
                      ? _buildErrorState()
                      : FadeTransition(
                          opacity: _fadeAnim,
                          child: RefreshIndicator(
                            onRefresh: _loadCommunityFeed,
                            color: brandGreen,
                            child: feedItems.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                                    itemCount: feedItems.length,
                                    itemBuilder: (context, index) {
                                      final item = feedItems[index];
                                      return RiDealCard(
                                        title: item['title'],
                                        imageUrl: item['imageUrl'],
                                      );
                                    },
                                  ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: brandGreen.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(brandGreen),
            ),
          ),
          SizedBox(height: 20.w),
          Text(
            'Loading community posts...',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.wifi_off_rounded, size: 48, color: Colors.red.shade300),
            ),
            SizedBox(height: 20.w),
            Text(
              'Could not load feed',
              style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.w),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade500),
            ),
            SizedBox(height: 20.w),
            ElevatedButton(
              onPressed: _loadCommunityFeed,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 12.w),
                elevation: 0,
              ),
              child: Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Column(
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(Icons.people_outline_rounded,
                  size: 48, color: Colors.grey.shade300),
            ),
            SizedBox(height: 20.w),
            Text(
              'No Posts Yet',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.w),
            Text(
              'Be the first to post in the community!',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade400),
            ),
          ],
        ),
      ],
    );
  }
}
