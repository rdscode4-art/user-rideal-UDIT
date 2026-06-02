import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rideal/model/ridermodel.dart';
import 'package:rideal/authservices.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  Rider? rider;
  bool isLoading = true;
  File? selectedImageFile;
  bool isUploadingImage = false;

  // Form controllers
  late TextEditingController nameController;
  late TextEditingController phoneController;

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
    try {
      final riderId = await Authservices.getRiderId();
      if (riderId == null) {
        throw Exception('No rider ID found');
      }

      final fetchedRider = await Authservices.getRiderProfile(riderId);
      setState(() {
        rider = fetchedRider;
        nameController.text = rider?.name ?? "";
        phoneController.text = rider?.phone ?? "";
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching profile: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Select Profile Image",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
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
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
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
              SizedBox(height: 16),
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
        // Validate file extension
        String fileName = image.path.toLowerCase();
        List<String> validExtensions = [
          '.jpg',
          '.jpeg',
          '.png',
          '.gif',
          '.webp',
        ];
        bool isValidImage = validExtensions.any(
          (ext) => fileName.endsWith(ext),
        );

        if (!isValidImage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "❌ Please select a valid image file (JPG, PNG, GIF, WEBP)",
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

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

      final riderId = await Authservices.getRiderId();
      if (riderId == null) {
        throw Exception('No rider ID found');
      }

      print("🚀 Uploading image using authservices...");
      print("📁 File path: ${selectedImageFile!.path}");

      // Use the updated authservices method with improved MIME type handling
      final updatedRider = await Authservices.updateRiderProfileWithImage(
        riderId,
        nameController.text.trim(),
        phoneController.text.trim(),
        selectedImageFile!.path,
      );

      // Update local state
      setState(() {
        rider = updatedRider;
        nameController.text = updatedRider.name ?? "";
        phoneController.text = updatedRider.phone ?? "";
        selectedImageFile = null;
        isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Profile image updated successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      print("✅ Profile updated successfully with image");

      // Return success result for profile refresh
      Navigator.of(context).pop({'updated': true, 'rider': updatedRider});
    } catch (e) {
      setState(() {
        isUploadingImage = false;
      });

      print("❌ Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to update profile image: $e"),
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

      if (phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Phone number cannot be empty"),
            backgroundColor: Colors.red,
          ),
        );
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
                SizedBox(width: 16),
                Text("Saving changes..."),
              ],
            ),
          );
        },
      );

      // If image file is selected, upload it first
      if (selectedImageFile != null) {
        await _uploadProfileImage();
        Navigator.of(context).pop(); // Close loading dialog
        return; // uploadProfileImage now handles the navigation return
      }

      // Use regular API update for text-only changes
      final updates = <String, dynamic>{
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
      };

      final updatedRider = await Authservices.updateRiderProfile(
        riderId,
        updates,
      );

      setState(() {
        rider = updatedRider;
        nameController.text = updatedRider.name ?? "";
        phoneController.text = updatedRider.phone ?? "";
      });

      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Profile updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // Return true to indicate successful update for profile refresh
      Navigator.of(context).pop({'updated': true, 'rider': updatedRider});
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
    // Priority: Local selected file > Rider profile image
    if (selectedImageFile != null) {
      return FileImage(selectedImageFile!);
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
        (rider?.profileImage != null && rider!.profileImage!.isNotEmpty)) {
      return null;
    }
    return Icon(Icons.person, size: 50, color: Colors.grey.shade600);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Edit Profile"),
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              "Save",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image Section
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _getProfileImage(),
                    child: _getProfileImageChild(),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: isUploadingImage ? null : _pickImage,
                        padding: EdgeInsets.zero,
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Image upload button
            if (selectedImageFile != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton.icon(
                  onPressed: isUploadingImage ? null : _uploadProfileImage,
                  icon:
                      isUploadingImage
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Icon(Icons.upload, size: 18),
                  label: Text(
                    isUploadingImage ? "Uploading..." : "Upload Image",
                    style: TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

            SizedBox(height: 32),

            // Form Fields
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Full Name",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.green.shade600,
                    width: 2,
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),

            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: "Phone Number",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.green.shade600,
                    width: 2,
                  ),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),

            SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
