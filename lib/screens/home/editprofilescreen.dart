import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideal/model/ridermodel.dart';
import 'package:rideal/authservices.dart';

class Editprofilescreen extends StatefulWidget {
  const Editprofilescreen({super.key});

  @override
  State<Editprofilescreen> createState() => _EditprofilescreenState();
}

class _EditprofilescreenState extends State<Editprofilescreen> {
  Rider? rider;
  bool isLoading = true;
  File? selectedImageFile;
  bool isUploadingImage = false;
  String? cachedProfileImageBase64;

  // Form controllers
  late TextEditingController nameController;
  late TextEditingController phoneController;
  
  // Store original phone number
  String? originalPhoneNumber;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    _fetchProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    // 1. Instantly read cached profile if available to display user details immediately
    try {
      final cachedRider = await Authservices.getCachedRiderProfile();
      if (cachedRider != null) {
        if (mounted) {
          setState(() {
            rider = cachedRider;
            nameController.text = rider?.name ?? "";
            phoneController.text = rider?.phone ?? "";
            originalPhoneNumber = rider?.phone;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("⚠️ Error loading cached profile in Edit Profile Screen: $e");
    }

    // 2. Instantly read cached profile image (base64)
    try {
      final cachedBase64 = await Authservices.getCachedProfileImageBase64();
      if (cachedBase64 != null && mounted) {
        setState(() {
          cachedProfileImageBase64 = cachedBase64;
        });
      }
    } catch (e) {
      print("⚠️ Error loading cached profile image in Edit Profile Screen: $e");
    }

    // 3. Fetch from API in background/foreground
    try {
      final riderId = await Authservices.getRiderId();
      if (riderId == null) {
        throw Exception('No rider ID found');
      }

      final fetchedRider = await Authservices.getRiderProfile(riderId);
      if (mounted) {
        setState(() {
          rider = fetchedRider;
          nameController.text = rider?.name ?? "";
          phoneController.text = rider?.phone ?? "";
          originalPhoneNumber = rider?.phone; // Store original phone
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
    } catch (e) {
      print("❌ Error fetching profile from server: $e");
      if (rider == null && mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.w,
                margin: EdgeInsets.symmetric(vertical: 10.w),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  "Select Profile Image",
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.green),
                ),
                title: Text('Camera'),
                subtitle: Text('Take a new photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: Text('Gallery'),
                subtitle: Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
              SizedBox(height: 16.w),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          selectedImageFile = File(image.path);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              source == ImageSource.camera
                  ? "📷 Photo captured successfully!"
                  : "📸 Image selected from gallery!",
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        print("✅ Image selected: ${image.path}");
      }
    } catch (e) {
      print("❌ Image picker error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? "❌ Camera not available. Try gallery."
                : "❌ Gallery not available. Try camera.",
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadProfileImage() async {
    if (selectedImageFile == null) {
      print("❌ No image file selected");
      return;
    }

    try {
      setState(() {
        isUploadingImage = true;
      });

      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      // Create multipart request
      final uri = Uri.parse(
        'https://backend.ridealmobility.com/api/rider/profile',
      );
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add profile photo file
      final multipartFile = await http.MultipartFile.fromPath(
        'profilePhoto',
        selectedImageFile!.path,
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      request.files.add(multipartFile);

      // Add other fields (use original phone number)
      request.fields['name'] = nameController.text.trim();
      request.fields['phone'] = originalPhoneNumber ?? phoneController.text.trim();

      print("🚀 Uploading image to: ${uri.toString()}");
      print("📁 File path: ${selectedImageFile!.path}");

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print("📊 Upload response status: ${response.statusCode}");
      print("📄 Upload response body: ${response.body}");

      if (response.statusCode == 200) {
        // Cache profile image base64 locally instantly
        try {
          if (selectedImageFile != null) {
            final bytes = await selectedImageFile!.readAsBytes();
            final base64Image = base64Encode(bytes);
            await prefs.setString('cached_profile_image_base64', base64Image);
            print("✅ Profile image base64 cached instantly from uploaded file");
          }
        } catch (e) {
          print("⚠️ Error caching local image after upload: $e");
        }

        // Clear selected file and reload profile
        setState(() {
          selectedImageFile = null;
          isUploadingImage = false;
        });

        await _fetchProfile();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Profile image updated successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        print("✅ Image upload successful");
      } else {
        throw Exception(
          'Upload failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print("❌ Image upload error: $e");

      setState(() {
        isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to upload image: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    try {
      final riderId = await Authservices.getRiderId();
      if (riderId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ No rider ID found")));
        return;
      }

      // Validate fields
      if (nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Name cannot be empty"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if phone number was changed (shouldn't happen with read-only, but double check)
      if (phoneController.text.trim() != originalPhoneNumber) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Phone number cannot be changed"),
            backgroundColor: Colors.red,
          ),
        );
        // Reset to original phone number
        setState(() {
          phoneController.text = originalPhoneNumber ?? "";
        });
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16.w),
                Text("Saving changes..."),
              ],
            ),
          );
        },
      );

      // If image file is selected, upload it first
      if (selectedImageFile != null) {
        // Use existing authservices method instead of direct API call
        final riderId = await Authservices.getRiderId();
        if (riderId != null) {
          final updatedRider = await Authservices.updateRiderProfileWithImage(
            riderId,
            nameController.text.trim(),
            originalPhoneNumber ?? phoneController.text.trim(), // Use original phone
            selectedImageFile!.path,
          );

          setState(() {
            rider = updatedRider;
            nameController.text = updatedRider.name;
            phoneController.text = updatedRider.phone;
            originalPhoneNumber = updatedRider.phone;
            selectedImageFile = null;
          });

          Navigator.of(context).pop(); // Close loading dialog
          Navigator.of(context).pop(true); // Return to previous screen

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Profile updated successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // Use regular API update for text-only changes
      final updates = <String, dynamic>{
        'name': nameController.text.trim(),
        'phone': originalPhoneNumber ?? phoneController.text.trim(), // Use original phone
      };

      final updatedRider = await Authservices.updateRiderProfile(
        riderId,
        updates,
      );

      setState(() {
        rider = updatedRider;
        nameController.text = updatedRider.name;
        phoneController.text = updatedRider.phone;
        originalPhoneNumber = updatedRider.phone;
      });

      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Profile updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      print("❌ Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to update profile: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ImageProvider? _getProfileImage() {
    // Priority: Local selected file > Cached base64 image > Rider profile image
    if (selectedImageFile != null) {
      return FileImage(selectedImageFile!);
    }

    if (cachedProfileImageBase64 != null) {
      try {
        return MemoryImage(base64Decode(cachedProfileImageBase64!));
      } catch (e) {
        print("⚠️ Error decoding cached base64 image in Edit Profile: $e");
      }
    }

    if (rider?.profileImage != null && rider!.profileImage!.isNotEmpty) {
      if (rider!.profileImage!.startsWith('http')) {
        return NetworkImage(rider!.profileImage!);
      } else {
        return NetworkImage(
          'https://backend.ridealmobility.com${rider!.profileImage}',
        );
      }
    }
    return null;
  }

  Widget? _getProfileImageChild() {
    if (selectedImageFile != null ||
        cachedProfileImageBase64 != null ||
        (rider?.profileImage != null && rider!.profileImage!.isNotEmpty)) {
      return null;
    }
    return Icon(Icons.person, size: 50, color: Colors.grey.shade600);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F9D58)))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Floating Header
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                    "Edit Profile",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: _saveProfile,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F9D58).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        "Save",
                        style: TextStyle(
                          color: Color(0xFF0F9D58),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image Section
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 64,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _getProfileImage(),
                                child: _getProfileImageChild(),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: isUploadingImage ? null : _pickImage,
                              child: Container(
                                width: 44.w,
                                height: 44.w,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  margin: EdgeInsets.all(4.w),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF0F9D58),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Loading overlay for image upload
                          if (isUploadingImage)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black54,
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24.w),

                    // Image upload button
                    if (selectedImageFile != null)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0.w),
                        child: ElevatedButton.icon(
                          onPressed: isUploadingImage ? null : _uploadProfileImage,
                          icon: isUploadingImage
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(Icons.upload_rounded, size: 18),
                          label: Text(
                            isUploadingImage ? "Uploading..." : "Upload Image",
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F9D58),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.w),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),

                    SizedBox(height: 40.w),

                    // Form Fields (Pill Shaped)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: nameController,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
                        decoration: InputDecoration(
                          hintText: "Full Name",
                          prefixIcon: Icon(Icons.person_rounded, color: Colors.black45),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.w),
                        ),
                      ),
                    ),

                    SizedBox(height: 20.w),

                    // Read-only Phone Number Field
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100, // Light grey to indicate read-only
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.01),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: phoneController,
                        enabled: false,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp, color: Colors.grey.shade600),
                        decoration: InputDecoration(
                          hintText: "Phone Number",
                          prefixIcon: Icon(Icons.phone_rounded, color: Colors.grey.shade400),
                          suffixIcon: Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.w),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.w),
                    Text(
                      "Phone number cannot be changed for security reasons",
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(height: 48.w),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56.w,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F9D58),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Save Changes",
                          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}