import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:rideal/authservices.dart';
import 'package:rideal/intro/Intropage.dart';
import 'package:rideal/intro/socialmedia.dart';
import 'package:rideal/screens/MultiStop/multistoprouteplanner.dart';
import 'package:rideal/screens/RideStarted/ridestarted.dart';
import 'package:rideal/screens/hiredriver/hiredriverscreen.dart';
import 'package:rideal/screens/home/Drawar.dart';
import 'package:rideal/screens/transport/confirmed.dart';
import 'package:rideal/screens/transport/confirmpickup.dart';
import 'package:rideal/screens/rental/rental_screen.dart';
import 'SearchScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideal/model/ridetypemodel.dart';
import 'dart:async';
import 'dart:convert';
import 'package:rideal/main.dart';
import 'dart:io';
import 'package:shimmer/shimmer.dart';

// Responsive breakpoints
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

// Helper class for responsive sizing
class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.mobile &&
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.desktop;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.desktop;

  static double getResponsiveValue(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getResponsiveValue(
        context,
        mobile: 16,
        tablet: 32,
        desktop: 48.w,
      ),
      vertical: 8.w,
    );
  }
}

class Home2 extends StatefulWidget {
  const Home2({super.key});

  @override
  State<Home2> createState() => _Home2State();
}

class _Home2State extends State<Home2> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = true;
  List<RideType> rideTypes = [];
  List<Map<String, String>> recentSearches = [];
  bool isSearchesLoading = true;
  String? token;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
    loadRideTypes();
    loadRecentSearches();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadRecentSearches();
  }

  void refreshScreen() {
    loadRecentSearches();
  }

 static String getImageForRideType(String type, RideType? rideTypeObj) {
  const String baseUrl = 'https://backend.ridealmobility.com';
  
  // First check if backend image URL is available
  if (rideTypeObj?.imageUrl != null && rideTypeObj!.imageUrl!.isNotEmpty) {
    // Check if the URL is already complete
    if (rideTypeObj.imageUrl!.startsWith('http://') || 
        rideTypeObj.imageUrl!.startsWith('https://')) {
      return rideTypeObj.imageUrl!;
    }
    
    // Extract the path from full server path
    String path = rideTypeObj.imageUrl!;
    
    // If path contains full server path, extract only from 'uploads' onwards
    if (path.contains('/uploads/')) {
      int uploadsIndex = path.indexOf('/uploads/');
      path = path.substring(uploadsIndex);
    } else if (!path.startsWith('/')) {
      // If it doesn't start with /, add it
      path = '/$path';
    }
    
    return '$baseUrl$path';
  }
  
  // Fallback to local assets
  final lowerType = type.toLowerCase();
  
  if (lowerType.contains('sedan') || lowerType.contains('car')) {
    return 'assets/images/taxi.png';
  } else if (lowerType.contains('suv')) {
    return 'assets/images/suv.png';
  } else if (lowerType.contains('ev') || lowerType.contains('electric')) {
    return 'assets/images/ev.png';
  } else if (lowerType.contains('bike') || lowerType.contains('motorcycle')) {
    return 'assets/images/bike.png';
  } else if (lowerType.contains('auto') || lowerType.contains('rickshaw')) {
    return 'assets/images/auto.png';
  } else {
    return 'assets/images/bike.png'; // default fallback
  }
}
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('auth_token');
      _loading = false;
    });
  }

  Future<void> loadRideTypes() async {
    final types = await Authservices.fetchRideTypes();
    if (types != null && types.isNotEmpty) {
      setState(() {
        // Filter out Goods carriers or any ride type containing "goods" or "carrier"
        rideTypes =
            types.where((rideType) {
              final typeName = rideType.type.toLowerCase();
              return !typeName.contains('goods') &&
                  !typeName.contains('carrier') &&
                  !typeName.contains('freight') &&
                  !typeName.contains('cargo') &&
                  typeName != 'mini truck' &&
                  typeName != 'pickup' &&
                  typeName != 'truck';
            }).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to load ride types")),
      );
    }
  }

  Future<void> loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searchesJson = prefs.getStringList('recent_searches') ?? [];

      List<Map<String, String>> searches = [];
      for (String searchJson in searchesJson) {
        final Map<String, dynamic> search = jsonDecode(searchJson);
        searches.add({
          'pickup': search['pickup'] ?? '',
          'dropoff': search['dropoff'] ?? '',
        });
      }

      setState(() {
        recentSearches = searches.take(5).toList();
        isSearchesLoading = false;
      });
    } catch (e) {
      print('❌ Error loading recent searches: $e');
      setState(() {
        isSearchesLoading = false;
      });
    }
  }

  static Future<void> saveRecentSearch(String pickup, String dropoff) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searchesJson = prefs.getStringList('recent_searches') ?? [];

      final newSearch = jsonEncode({
        'pickup': pickup,
        'dropoff': dropoff,
        'timestamp': DateTime.now().toIso8601String(),
      });

      searchesJson.removeWhere((search) {
        final decoded = jsonDecode(search);
        return decoded['pickup'] == pickup && decoded['dropoff'] == dropoff;
      });

      searchesJson.insert(0, newSearch);

      if (searchesJson.length > 10) {
        searchesJson.removeRange(10, searchesJson.length);
      }

      await prefs.setStringList('recent_searches', searchesJson);
    } catch (e) {
      print('❌ Error saving recent search: $e');
    }
  }

  String _getTimeBasedGreeting() {
    return "Good RiDeal morning,";
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    if (_loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (token == null || token!.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            'You need to login first',
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveValue(
                context,
                mobile: 18,
                tablet: 22,
                desktop: 24.w,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer:
          isMobile
              ? CustomDrawer(
                logoutUser: () async {
                  bool success = await Authservices.logoutUser();
                  if (success) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => IntroScreen()),
                    );
                  }
                  return success;
                },
              )
              : null,
      body: Row(
        children: [
          // Desktop sidebar navigation
          if (isDesktop)
            Container(
              width: 280.w,
              color: Colors.green.shade50,
              child: CustomDrawer(
                logoutUser: () async {
                  bool success = await Authservices.logoutUser();
                  if (success) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => IntroScreen()),
                    );
                  }
                  return success;
                },
              ),
            ),
          // Main content
          Expanded(
            child: _buildMainContent(context, isMobile, isTablet, isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1400 : double.infinity,
          ),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.5,
              colors: [
                const Color(0xFF0F9D58).withOpacity(0.08),
                Colors.white,
                Colors.white,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isMobile, isTablet, isDesktop),
              SizedBox(height: 24.w),
              // Action Cards (replacing service chips)
              _buildActionCards(context),
              const HomeBannerSection(),
              SizedBox(
                height: ResponsiveHelper.getResponsiveValue(
                  context,
                  mobile: 10,
                  tablet: 15,
                  desktop: 20.w,
                ),
              ),
              // Ongoing Ride Widget
              const OngoingRideWidget(),
              // Recent Searches Section
              _buildRecentSearchesSection(
                context,
                isMobile,
                isTablet,
                isDesktop,
              ),
              // Explore Section
              _buildExploreSection(context, isMobile, isTablet, isDesktop),
              SizedBox(
                height: ResponsiveHelper.getResponsiveValue(
                  context,
                  mobile: 20,
                  tablet: 25,
                  desktop: 30.w,
                ),
              ),
              // Additional Features
              _buildAdditionalFeatures(context, isMobile, isTablet, isDesktop),
              SizedBox(height: 180.w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16, // Reverted based on user feedback
        left: 20.w,
        right: 20.w,
        bottom: 8.w,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                "assets/images/logorideal.png",
                height: 75.w, // Massive logo
                fit: BoxFit.contain,
              ),
              if (isMobile)
                GestureDetector(
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                  child: Container(
                    padding: EdgeInsets.all(8.w), // Scaled down
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.menu, color: Colors.black87, size: 20), // Changed to menu icon
                  ),
                ),
            ],
          ),
          SizedBox(height: 0), // Removed spacing to compensate for 52px logo, keeping "Good morning" in place
          Text(
            _getTimeBasedGreeting(),
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14.sp, // Scaled down
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            "Where to next?",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 22.sp, // Scaled down from 34
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 20.w),
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
              loadRecentSearches();
            },
            child: Container(
              height: 50.w, // Scaled down from 64
              padding: EdgeInsets.only(left: 16.w, right: 6.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.black54, size: 20),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      "Enter destination...",
                      style: TextStyle(
                        color: Colors.black38,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    height: 38.w, // Scaled down
                    width: 38.w,
                    decoration: BoxDecoration(
                      color: Color(0xFF0F9D58),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards(BuildContext context) {
    final services = [
      {
        'title': 'Hire Driver',
        'icon': Icons.person_outline,
        'route': () => HireDriverScreen(),
      },
      {
        'title': 'Multi-Stop',
        'icon': Icons.alt_route,
        'route': () => MultiStopRoutePlanner(),
      },
      {
        'title': 'Transport',
        'icon': Icons.local_shipping_outlined,
        'route': () => const SearchScreen(isTransport: true),
      },
      {
        'title': 'Rentals',
        'icon': Icons.car_rental,
        'route': () => const RentalScreen(),
      },
    ];

    // Ultra-compact, premium "squircle" chips
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: services.map((service) {
          return Expanded(
            child: GestureDetector(
              onTap: () {
                final route = service['route'] as Function;
                Navigator.push(context, MaterialPageRoute(builder: (context) => route()));
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 6.w),
                padding: EdgeInsets.symmetric(vertical: 12.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.grey.shade100, width: 1.w),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F9D58).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        service['icon'] as IconData,
                        color: const Color(0xFF0F9D58),
                        size: 22,
                      ),
                    ),
                    SizedBox(height: 8.w),
                    Text(
                      service['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11.sp,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentSearchesSection(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Column(
      children: [
        Padding(
          padding: ResponsiveHelper.getResponsivePadding(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Searches",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveHelper.getResponsiveValue(
                    context,
                    mobile: 18,
                    tablet: 20,
                    desktop: 22.w,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.w),
        isSearchesLoading
            ? (isDesktop ? _buildRecentSearchesGridSkeleton(context) : _buildRecentSearchesListSkeleton(context))
            : recentSearches.isEmpty
                ? SizedBox(
                    height: 120.w,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off, color: Colors.grey.shade400, size: 40),
                          SizedBox(height: 12.w),
                          Text(
                            "No recent searches yet",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: ResponsiveHelper.getResponsiveValue(
                                context,
                                mobile: 14,
                                tablet: 15,
                                desktop: 16.w,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : isDesktop
                    ? _buildRecentSearchesGrid(context)
                    : _buildRecentSearchesList(context),
      ],
    );
  }

  Widget _buildRecentSearchesList(BuildContext context) {
    return ListView.builder(
      padding: ResponsiveHelper.getResponsivePadding(context),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentSearches.length,
      itemBuilder: (context, index) {
        final search = recentSearches[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12.w),
          child: Material(
            color: Colors.white,
            elevation: 0.5,
            shadowColor: Colors.black.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(color: Colors.grey.shade100),
            ),
            child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: Icon(Icons.history, color: Colors.green.shade600, size: 20),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.green),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        search['pickup'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.w),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 10, color: Colors.red),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        search['dropoff'] ?? '',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12.sp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.grey, size: 18),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => SearchScreen(
                        initialPickup: search['pickup'],
                        initialDropoff: search['dropoff'],
                      ),
                ),
              );
              loadRecentSearches();
            },
          ),
          ),
        );
      },
    );
  }

  Widget _buildRecentSearchesGrid(BuildContext context) {
    return GridView.builder(
      padding: ResponsiveHelper.getResponsivePadding(context),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 12,
      ),
      itemCount: recentSearches.length,
      itemBuilder: (context, index) {
        final search = recentSearches[index];
        return InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => SearchScreen(
                      initialPickup: search['pickup'],
                      initialDropoff: search['dropoff'],
                    ),
              ),
            );
            loadRecentSearches();
          },
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.grey, size: 20),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              search['pickup'] ?? '',
                              style: TextStyle(fontSize: 13.sp),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.w),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.red),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              search['dropoff'] ?? '',
                              style: TextStyle(fontSize: 13.sp),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExploreSection(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            "Explore Rides",
            style: TextStyle(
              fontWeight: FontWeight.bold, // Scaled back from w800
              fontSize: ResponsiveHelper.getResponsiveValue(
                context,
                mobile: 18, // Scaled down from 22
                tablet: 20,
                desktop: 22.w,
              ),
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(height: 12.w),
        isDesktop
            ? Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildRideTypesGrid(context),
              )
            : _buildRideTypesList(context),
      ],
    );
  }

  Widget _buildRideTypesList(BuildContext context) {
    return SizedBox(
      height: 120.w, // Adjusted height for landscape cards
      child: isLoading
          ? _buildRideTypesListSkeleton(context)
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              scrollDirection: Axis.horizontal,
              itemCount: rideTypes.length,
              itemBuilder: (context, index) {
                final ride = rideTypes[index];
                final imagePath = getImageForRideType(ride.type, ride);
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.0.w),
                  child: HomeTransportCard(imagePath, ride.type),
                );
              },
            ),
    );
  }

  Widget _buildRideTypesGrid(BuildContext context) {
    return isLoading
        ? _buildRideTypesGridSkeleton(context)
        : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.9,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: rideTypes.length,
            itemBuilder: (context, index) {
              final ride = rideTypes[index];
              final imagePath = getImageForRideType(ride.type, ride);
              return HomeTransportCard(imagePath, ride.type);
            },
          );
  }

  Widget HomeTransportCard(String imagePath, String type) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SearchScreen()),
        );
        loadRecentSearches();
      },
      child: Container(
        width: 160.w, // Wider for landscape banner images
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image filling the card
              Container(
                color: Colors.white,
                child: imagePath.startsWith('http')
                    ? Image.network(
                        imagePath,
                        fit: BoxFit.cover, // Changed from contain to cover
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset('assets/images/bike.png', fit: BoxFit.cover);
                        },
                      )
                    : Image.asset(imagePath, fit: BoxFit.cover), // Changed from contain to cover
              ),
              // Gradient Overlay for Text Readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.4, 0.7, 1.0],
                  ),
                ),
              ),
              // Text Content Overlay
              Positioned(
                bottom: 12.w,
                left: 12.w,
                right: 12.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.w),
                    Row(
                      children: [
                        Text(
                          "Book now",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.arrow_forward_ios, size: 8, color: Colors.white70),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalFeatures(
    BuildContext context,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
  ) {
    return Column(
      children: [
        SocialLinks(),
      ],
    );
  }

  Widget _buildRecentSearchesListSkeleton(BuildContext context) {
    return ListView.builder(
      padding: ResponsiveHelper.getResponsivePadding(context),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListTile(
            leading: Icon(Icons.history, color: Colors.white),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 15.w, width: double.infinity, color: Colors.white),
                SizedBox(height: 8.w),
                Container(height: 15.w, width: double.infinity, color: Colors.white),
                SizedBox(height: 8.w),
                Divider(color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentSearchesGridSkeleton(BuildContext context) {
    return GridView.builder(
      padding: ResponsiveHelper.getResponsivePadding(context),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 12,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRideTypesListSkeleton(BuildContext context) {
    return SizedBox(
      height: ResponsiveHelper.getResponsiveValue(
        context,
        mobile: 130,
        tablet: 150,
        desktop: 170.w,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0.w),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                children: [
                  Container(
                    height: ResponsiveHelper.getResponsiveValue(context, mobile: 80, tablet: 100, desktop: 120.w),
                    width: ResponsiveHelper.getResponsiveValue(context, mobile: 70, tablet: 90, desktop: 110.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  SizedBox(height: 5.w),
                  Container(height: 15.w, width: 50.w, color: Colors.white),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRideTypesGridSkeleton(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            children: [
              Container(
                height: ResponsiveHelper.getResponsiveValue(context, mobile: 80, tablet: 100, desktop: 120.w),
                width: ResponsiveHelper.getResponsiveValue(context, mobile: 70, tablet: 90, desktop: 110.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(height: 5.w),
              Container(height: 15.w, width: 50.w, color: Colors.white),
            ],
          ),
        );
      },
    );
  }
}

// OngoingRideWidget remains largely the same but with responsive adjustments
class OngoingRideWidget extends StatefulWidget {
  const OngoingRideWidget({super.key});

  @override
  State<OngoingRideWidget> createState() => _OngoingRideWidgetState();
}

class _OngoingRideWidgetState extends State<OngoingRideWidget> with RouteAware {
  List<Map<String, dynamic>> _ongoingRides = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
    _checkOngoingRides();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    print("📌 Back to Home2 → restarting auto refresh");
    _checkOngoingRides();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        print("⏳ Auto-refresh tick... checking rides");
        _checkOngoingRides();
      }
    });
  }

  void _stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  static Future<bool> hasOngoingRide() async {
    final prefs = await SharedPreferences.getInstance();
    final ongoingRides = prefs.getStringList('ongoingRideIds') ?? [];
    return ongoingRides.isNotEmpty;
  }

  Future<void> _checkOngoingRides() async {
    final prefs = await SharedPreferences.getInstance();
    final singleRideId = prefs.getString('rideId');
    final currentRideId = prefs.getString('current_ride_id');
    final multipleRideIds = prefs.getStringList('ongoingRideIds') ?? [];

    List<String> allRideIds = [];
    if (singleRideId != null) allRideIds.add(singleRideId);
    if (currentRideId != null) allRideIds.add(currentRideId);
    allRideIds.addAll(multipleRideIds);
    allRideIds = allRideIds.toSet().toList();

    List<Map<String, dynamic>> activeRides = [];

    for (String rideId in allRideIds) {
      try {
        // ✅ Safe network call — catches internet/background errors
        final rideStatus = await Authservices.getRideStatus(rideId);
        print('🔍 Basic ride status: $rideStatus');

        if (rideStatus != null) {
          final status = rideStatus['status']?.toString().toLowerCase() ?? '';

          if (status == 'pending' ||
              status == 'accepted' ||
              status == 'ongoing') {
            if (status == 'pending' || status == 'accepted') {
              try {
                // ✅ Safe nested API call
                final fullRideDetails = await Authservices.getRideDetail(
                  rideId,
                );
                print('🔍 Full ride details: $fullRideDetails');

                if (fullRideDetails != null) {
                  final pickupStop = fullRideDetails.pickupStop;
                  final dropoffStop = fullRideDetails.dropoffStop;

                  activeRides.add({
                    'rideId': rideId,
                    'status': status,
                    'details': {
                      'rideType': fullRideDetails.type,
                      'pickupLocation': {
                        'address': pickupStop.address,
                        'lat': pickupStop.lat,
                        'lng': pickupStop.lng,
                      },
                      'dropoffLocation': {
                        'address': dropoffStop.address,
                        'lat': dropoffStop.lat,
                        'lng': dropoffStop.lng,
                      },
                    },
                  });
                } else {
                  activeRides.add({
                    'rideId': rideId,
                    'status': status,
                    'details': rideStatus,
                  });
                }
              } on SocketException {
                print('🌐 No internet while fetching details for $rideId');
                activeRides.add({
                  'rideId': rideId,
                  'status': status,
                  'details': rideStatus,
                });
              } catch (detailError) {
                print(
                  '❌ Error fetching ride details for $rideId: $detailError',
                );
                activeRides.add({
                  'rideId': rideId,
                  'status': status,
                  'details': rideStatus,
                });
              }
            } else {
              activeRides.add({
                'rideId': rideId,
                'status': status,
                'details': rideStatus,
              });
            }
          } else {
            print('🧹 Removing completed ride: $rideId (status: $status)');
            await _removeCompletedRide(rideId);
          }
        } else {
          await _removeCompletedRide(rideId);
        }
      } on SocketException {
        print('🌐 No internet while checking ride $rideId, skipping...');
        activeRides.add({
          'rideId': rideId,
          'status': 'unknown',
          'details': null,
        });
      } catch (e) {
        print('❌ Unexpected error checking ride $rideId: $e');
        activeRides.add({
          'rideId': rideId,
          'status': 'unknown',
          'details': null,
        });
      }
    }

    if (mounted) {
      setState(() {
        _ongoingRides = activeRides;
        _isLoading = false;
      });
    }

    if (activeRides.isEmpty) {
      _stopAutoRefresh();
    }
  }

  Future<void> _removeCompletedRide(String rideId) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> currentRides = prefs.getStringList('ongoingRideIds') ?? [];
    currentRides.remove(rideId);
    await prefs.setStringList('ongoingRideIds', currentRides);

    final singleRideId = prefs.getString('rideId');
    if (singleRideId == rideId) {
      if (currentRides.isNotEmpty) {
        await prefs.setString('rideId', currentRides.first);
      } else {
        await prefs.remove('rideId');
      }
    }

    final currentRideId = prefs.getString('current_ride_id');
    if (currentRideId == rideId) {
      await prefs.remove('current_ride_id');
    }
  }

  Future<void> _navigateToRideScreen(Map<String, dynamic> ride) async {
    final prefs = await SharedPreferences.getInstance();
    final details = ride['details'] ?? ride['ride'] ?? {};

    final pickup = details['pickupLocation'] ?? {};
    final dropoff = details['dropoffLocation'] ?? {};

    var pickupAddress =
        pickup['address'] ??
        prefs.getString('last_pickup_address') ??
        "Pickup address not available";
    var dropoffAddress =
        dropoff['address'] ??
        prefs.getString('last_drop_address') ??
        "Dropoff address not available";

    var pickupLat =
        pickup['lat'] ??
        double.tryParse(prefs.getString('last_pickup_lat') ?? '0') ??
        0.0;
    var pickupLng =
        pickup['lng'] ??
        double.tryParse(prefs.getString('last_pickup_lng') ?? '0') ??
        0.0;
    var dropLat =
        dropoff['lat'] ??
        double.tryParse(prefs.getString('last_drop_lat') ?? '0') ??
        0.0;
    var dropLng =
        dropoff['lng'] ??
        double.tryParse(prefs.getString('last_drop_lng') ?? '0') ??
        0.0;

    final status = ride['status'] ?? 'unknown';

    print('🚗 Navigating to $status ride with:');
    print('   Pickup: $pickupAddress ($pickupLat, $pickupLng)');
    print('   Dropoff: $dropoffAddress ($dropLat, $dropLng)');

    switch (status.toLowerCase()) {
      case 'pending':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => Confirm(
                  pickupLocation: pickupAddress,
                  dropoffLocation: dropoffAddress,
                  rideType: details['rideType'] ?? "Unknown",
                  originalRideType: details['rideType'] ?? "Unknown",
                  pickupLat: pickupLat,
                  pickupLng: pickupLng,
                  dropLat: dropLat,
                  dropLng: dropLng,
                  autoBook: false, // Already booked/pending
                ),
          ),
        );
        break;

      case 'accepted':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    Confirmed(rideType: details['rideType'] ?? "Unknown"),
          ),
        );
        break;

      case 'ongoing':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RideStarted(rideId: ride['rideId']),
          ),
        );
        break;

      default:
        print('Unknown ride status: $status');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot navigate to ride with status: $status'),
          ),
        );
        break;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'ongoing':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle;
      case 'ongoing':
        return Icons.directions_car;
      default:
        return Icons.help;
    }
  }

  String _getStatusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return "Searching for driver...";
      case 'accepted':
        return "Driver is on the way";
      case 'ongoing':
        return "Your ride is active";
      default:
        return "Unknown status";
    }
  }

  String _getStatusSubtitle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return "Please wait while we find a driver";
      case 'accepted':
        return "Tap to view driver details";
      case 'ongoing':
        return "Tap to view live location";
      default:
        return "Tap for details";
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = ResponsiveHelper.getResponsiveValue(
      context,
      mobile: 12,
      tablet: 24,
      desktop: 48.w,
    );

    if (_isLoading) {
      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 12.w,
        ),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: SizedBox(
            height: 20.w,
            width: 20.w,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_ongoingRides.isEmpty) {
      return SizedBox.shrink();
    }

    if (_ongoingRides.length == 1) {
      final ride = _ongoingRides[0];
      final rideId = ride['rideId'];
      final status = ride['status'];
      final statusColor = _getStatusColor(status);

      return GestureDetector(
        onTap: () => _navigateToRideScreen(ride),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 12.w,
          ),
          padding: EdgeInsets.all(
            ResponsiveHelper.getResponsiveValue(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24.w,
            ),
          ),
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              status == 'pending'
                  ? SizedBox(
                    width: ResponsiveHelper.getResponsiveValue(
                      context,
                      mobile: 32,
                      tablet: 36,
                      desktop: 40.w,
                    ),
                    height: ResponsiveHelper.getResponsiveValue(
                      context,
                      mobile: 32,
                      tablet: 36,
                      desktop: 40.w,
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  )
                  : Icon(
                    _getStatusIcon(status),
                    color: Colors.white,
                    size: ResponsiveHelper.getResponsiveValue(
                      context,
                      mobile: 32,
                      tablet: 36,
                      desktop: 40.w,
                    ),
                  ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusMessage(status),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.getResponsiveValue(
                          context,
                          mobile: 16,
                          tablet: 18,
                          desktop: 20.w,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.w),
                    Text(
                      _getStatusSubtitle(status),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: ResponsiveHelper.getResponsiveValue(
                          context,
                          mobile: 14,
                          tablet: 15,
                          desktop: 16.w,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.white),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.multiple_stop, color: Colors.blue.shade700),
                SizedBox(width: 8.w),
                Text(
                  "Multiple Rides (${_ongoingRides.length})",
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontSize: ResponsiveHelper.getResponsiveValue(
                      context,
                      mobile: 16,
                      tablet: 17,
                      desktop: 18.w,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16.r),
                bottomRight: Radius.circular(16.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ongoingRides.length,
              separatorBuilder:
                  (context, index) =>
                      Divider(height: 1.w, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final ride = _ongoingRides[index];
                final rideId = ride['rideId'];
                final status = ride['status'];
                final statusColor = _getStatusColor(status);

                return GestureDetector(
                  onTap: () => _navigateToRideScreen(ride),
                  child: Container(
                    padding: EdgeInsets.all(
                      ResponsiveHelper.getResponsiveValue(
                        context,
                        mobile: 16,
                        tablet: 18,
                        desktop: 20.w,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child:
                              status == 'pending'
                                  ? SizedBox(
                                    width: 24.w,
                                    height: 24.w,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        statusColor,
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Icon(
                                    _getStatusIcon(status),
                                    color: statusColor,
                                    size: 24,
                                  ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "Ride ${index + 1}",
                                    style: TextStyle(
                                      fontSize:
                                          ResponsiveHelper.getResponsiveValue(
                                            context,
                                            mobile: 16,
                                            tablet: 17,
                                            desktop: 18.w,
                                          ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 2.w,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.w),
                              Text(
                                "ID: $rideId",
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getResponsiveValue(
                                    context,
                                    mobile: 12,
                                    tablet: 13,
                                    desktop: 14.w,
                                  ),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                _getStatusSubtitle(status),
                                style: TextStyle(
                                  fontSize: ResponsiveHelper.getResponsiveValue(
                                    context,
                                    mobile: 14,
                                    tablet: 15,
                                    desktop: 16.w,
                                  ),
                                  color: Colors.grey.shade500,
                                ),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> addOngoingRide(
    String rideId,
    void Function() refresh,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentRides = prefs.getStringList('ongoingRideIds') ?? [];

    if (!currentRides.contains(rideId)) {
      currentRides.add(rideId);
      await prefs.setStringList('ongoingRideIds', currentRides);
      if (currentRides.length == 1) {
        await prefs.setString('rideId', rideId);
        await prefs.setString('current_ride_id', rideId);
      }
    }
    refresh();
  }

  static Future<void> removeOngoingRide(String rideId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currentRides = prefs.getStringList('ongoingRideIds') ?? [];

    currentRides.remove(rideId);
    await prefs.setStringList('ongoingRideIds', currentRides);

    final currentRideId = prefs.getString('current_ride_id');
    if (currentRideId == rideId) {
      await prefs.remove('current_ride_id');
    }

    if (currentRides.isEmpty) {
      await prefs.remove('rideId');
    } else {
      await prefs.setString('rideId', currentRides.first);
    }
  }

  static Future<void> clearAllOngoingRides() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ongoingRideIds');
    await prefs.remove('rideId');
    await prefs.remove('current_ride_id');
  }
}

class HomeBannerSection extends StatefulWidget {
  const HomeBannerSection({super.key});

  @override
  State<HomeBannerSection> createState() => _HomeBannerSectionState();
}

class _HomeBannerSectionState extends State<HomeBannerSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  List<String> _bannerUrls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    final urls = await Authservices.fetchBanners();
    if (mounted) {
      setState(() {
        _bannerUrls = urls;
        _isLoading = false;
      });
      if (urls.isNotEmpty) {
        _startAutoScroll(urls.length);
      } else {
        _startAutoScroll(3);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll(int itemCount) {
    _timer?.cancel();
    if (itemCount <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % itemCount;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.w),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 125.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
        ),
      );
    }

    if (_bannerUrls.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.w),
        child: Column(
          children: [
            SizedBox(
              height: 125.w,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _bannerUrls.length,
                itemBuilder: (context, index) {
                  final url = _bannerUrls[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SearchScreen()),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.broken_image, color: Colors.grey, size: 40),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10.w),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _bannerUrls.length,
                (index) => Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: _currentPage == index ? 16.w : 6.w,
                  height: 6.w,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF0F9D58)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
