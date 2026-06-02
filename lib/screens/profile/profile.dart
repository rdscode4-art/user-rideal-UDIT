import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rideal/intro/socialmedia.dart';
import 'package:rideal/model/ridermodel.dart';
import 'package:rideal/authservices.dart';
import 'package:rideal/screens/contact_info_section.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with TickerProviderStateMixin {
  Rider? rider;
  bool isLoading = true;
  String riderId = '';
  String? cachedProfileImageBase64;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    fetchProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchProfile() async {
    // 1. Instantly read cached profile if available to display user details immediately
    try {
      final cachedRider = await Authservices.getCachedRiderProfile();
      if (cachedRider != null) {
        if (mounted) {
          setState(() {
            rider = cachedRider;
            isLoading = false;
          });
          _animationController.forward();
        }
      }
    } catch (e) {
      print("⚠️ Error loading cached profile in Profile Screen: $e");
    }

    // 2. Instantly read cached profile image (base64) to show the image immediately
    try {
      final cachedBase64 = await Authservices.getCachedProfileImageBase64();
      if (cachedBase64 != null && mounted) {
        setState(() {
          cachedProfileImageBase64 = cachedBase64;
        });
      }
    } catch (e) {
      print("⚠️ Error loading cached profile image in Profile Screen: $e");
    }

    // 3. Fetch fresh profile data and ratings from the server
    try {
      final riderIdFromStorage = await Authservices.getRiderId();

      if (riderIdFromStorage == null) {
        print("⚠️ No Rider ID found in storage.");
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final fetchedRider = await Authservices.getRiderProfile(
        riderIdFromStorage,
      );
      final ratingData = await Authservices.getRiderRatings(riderIdFromStorage);

      await fetchRiderId(riderIdFromStorage);

      if (mounted) {
        setState(() {
          rider = fetchedRider;
          if (ratingData != null) {
            rider = rider?.copyWith(rating: ratingData["avgRating"]);
            print(
              "✅ Rating loaded: ${ratingData["avgRating"]} (${ratingData["totalRatings"]} reviews)",
            );
          } else {
            print("⚠️ No rating data received");
          }
          isLoading = false;
        });
      }

      // Update image cache base64 locally after server profile retrieval completes
      final updatedBase64 = await Authservices.getCachedProfileImageBase64();
      if (updatedBase64 != null && mounted) {
        setState(() {
          cachedProfileImageBase64 = updatedBase64;
        });
      }

      if (mounted) {
        _animationController.forward();
      }
    } catch (e) {
      print("❌ Error fetching profile from server: $e");
      if (rider == null && mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String? getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    const String baseUrl = "https://backend.ridealmobility.com";
    return '$baseUrl$imagePath';
  }

  Future<void> fetchRiderId(String riderDbId) async {
    try {
      print('🚀 Fetching Rider ID for: $riderDbId');

      final response = await Authservices.getRiderIdFromApi(riderDbId);

      if (response != null && response['success'] == true) {
        setState(() {
          riderId = response['data']['riderId'] ?? '';
        });
        print('✅ Rider ID fetched: $riderId');
      } else {
        print('⚠️ Failed to fetch Rider ID');
      }
    } catch (e) {
      print('❌ Error fetching Rider ID: $e');
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final TextEditingController reasonController = TextEditingController();
    String? selectedReason;

    final reasons = [
      "I no longer need this service",
      "I'm not satisfied with the service",
      "Privacy concerns",
      "Found a better alternative",
      "Too expensive",
      "Other",
    ];

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
                  const SizedBox(width: 12),
                  const Text(
                    "Delete Account",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "We're sad to see you go. This action cannot be undone.",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Please tell us why:",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...reasons.map((reason) {
                      return RadioListTile<String>(
                        title: Text(
                          reason,
                          style: const TextStyle(fontSize: 14),
                        ),
                        value: reason,
                        groupValue: selectedReason,
                        activeColor: Colors.green.shade600,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedReason = value;
                            if (value != "Other") {
                              reasonController.text = value!;
                            } else {
                              reasonController.clear();
                            }
                          });
                        },
                      );
                    }),
                    if (selectedReason == "Other") ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: "Please specify your reason...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                ElevatedButton(
                  onPressed: selectedReason == null ||
                          (selectedReason == "Other" &&
                              reasonController.text.trim().isEmpty)
                      ? null
                      : () {
                          Navigator.of(context).pop();
                          _confirmDeleteAccount(reasonController.text.trim());
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Delete Account"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount(String reason) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Final Confirmation",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            "Are you absolutely sure? This will permanently delete your account and all associated data.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount(reason);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Yes, Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(String reason) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.green.shade600),
              const SizedBox(height: 16),
              const Text("Processing request..."),
            ],
          ),
        );
      },
    );

    try {
      final response = await Authservices.deleteAccountRequest(reason);

      Navigator.of(context).pop(); // Close loading dialog

      if (response != null && response['success'] == true) {
        // Show success message
        _showSuccessDialog();
      } else if (response != null && 
                 response['success'] == false && 
                 response['message']?.toString().contains('pending') == true) {
        // Already has pending request
        _showPendingRequestDialog(response);
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response?['message'] ?? 'Failed to delete account',
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      print("❌ Error deleting account: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                "Account Deletion Requested",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Your account deletion request has been submitted successfully.",
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showPendingRequestDialog(Map<String, dynamic> response) {
    final request = response['request'];
    final requestedAt = request?['requestedAt'] ?? '';
    final status = request?['status'] ?? 'pending';
    final reason = request?['reason'] ?? 'Not specified';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade600),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Pending Request",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "You already have a pending account deletion request.",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Status:",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.notes,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Reason:",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            reason,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (requestedAt.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Requested:",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatDate(requestedAt),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Your request is being processed. We'll contact you soon.",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return "Today";
      } else if (difference.inDays == 1) {
        return "Yesterday";
      } else if (difference.inDays < 7) {
        return "${difference.inDays} days ago";
      } else {
        return "${date.day}/${date.month}/${date.year}";
      }
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildRatingDisplay() {
    final rating = rider?.rating;

    if (rating == null || rating == 0.0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border_rounded, color: Colors.amber.shade700, size: 18),
            const SizedBox(width: 6),
            Text(
              "No ratings yet",
              style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: Colors.amber.shade800,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageWidget() {
    if (cachedProfileImageBase64 != null) {
      try {
        return Image.memory(
          base64Decode(cachedProfileImageBase64!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackOrNetworkImage(),
        );
      } catch (e) {
        print("⚠️ Error decoding base64 image in Profile: $e");
      }
    }
    return _buildFallbackOrNetworkImage();
  }

  Widget _buildFallbackOrNetworkImage() {
    if (rider?.profileImage != null && rider!.profileImage!.isNotEmpty) {
      final imageUrl = getFullImageUrl(rider!.profileImage!);
      if (imageUrl != null) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, size: 40, color: Colors.grey.shade400),
        );
      }
    }
    return Icon(Icons.person_rounded, size: 40, color: Colors.grey.shade400);
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        children: [
          // Top bar row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
                ),
              ),
              const Text(
                "Profile",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),

          const SizedBox(height: 20),

          // Profile card with banner
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Banner + avatar using Stack
                Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    // Green banner
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF0F9D58), Colors.green.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -10, top: -20,
                            child: Container(
                              width: 120, height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.07),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 20, bottom: -20,
                            child: Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.05),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Avatar overlapping banner
                    Positioned(
                      bottom: -40,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildProfileImageWidget(),
                        ),
                      ),
                    ),
                  ],
                ),

                // Space for the overflowing avatar
                const SizedBox(height: 52),

                // Name
                Text(
                  rider?.name ?? "Unknown User",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),

                if (rider?.phone.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    rider!.phone,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                _buildRatingDisplay(),
                const SizedBox(height: 14),

                // Rider ID chip
                if (riderId.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F9D58).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.badge_outlined, size: 14, color: Color(0xFF0F9D58)),
                        const SizedBox(width: 6),
                        Text(
                          "ID: $riderId",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F9D58),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),

        ],
      ),
    );
  }


  Widget _buildInfoCard(String title, String value, IconData icon, {Color? iconColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor ?? const Color(0xFF0F9D58)).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor ?? const Color(0xFF0F9D58), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? "Not provided" : value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: value.isEmpty ? Colors.red.shade300 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      width: double.infinity,
      child: GestureDetector(
        onTap: _showDeleteAccountDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_forever_rounded, color: Colors.red.shade400, size: 16),
              const SizedBox(width: 6),
              Text(
                "Delete Account",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body:
          isLoading
              ? Container(
                  color: Colors.grey.shade50,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F9D58)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Loading Profile...",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : rider == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Failed to load profile",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLoading = true;
                        });
                        fetchProfile();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              )
              : FadeTransition(
                opacity: _fadeAnimation,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    const SizedBox(height: 8),
                    SafeArea(bottom: false, child: _buildProfileHeader()),
                    _buildSectionTitle("Personal Information"),
                    _buildInfoCard("Name", rider?.name ?? "", Icons.person_outline_rounded,
                        iconColor: Colors.green.shade600),
                    _buildInfoCard("Phone", rider?.phone ?? "", Icons.phone_outlined,
                        iconColor: Colors.blue.shade500),
                    _buildInfoCard("Gender", rider?.gender ?? "", Icons.wc_rounded,
                        iconColor: Colors.purple.shade400),
                    _buildInfoCard("Address", rider?.address ?? "", Icons.location_on_outlined,
                        iconColor: Colors.red.shade400),
                    _buildSectionTitle("Connect With Us"),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SocialLinks(),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ContactInfoSection(),
                    ),
                    _buildSectionTitle("Account"),
                    _buildDeleteAccountButton(),
                    const SizedBox(height: 180),
                  ],

                ),
              ),
    );
  }
}