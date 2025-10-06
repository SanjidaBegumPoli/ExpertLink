import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class PrefectProfilePage extends StatefulWidget {
  final String userId;

  const PrefectProfilePage({super.key, required this.userId});

  @override
  State<PrefectProfilePage> createState() => _PrefectProfilePageState();
}

class _PrefectProfilePageState extends State<PrefectProfilePage> {
  final picker = ImagePicker();
  File? _imageFile;
  bool _isEditing = false;
  bool _isUploading = false;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();


  final String cloudName = "dxhfsxl6l";
  final String uploadPreset = "uploads";

  Future<void> _pickImage() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint("Image picker error: $e");
    }
  }
//image upload part
  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      setState(() => _isUploading = true);

      final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(await response.stream.bytesToString());
        return responseData['secure_url'];
      } else {
        debugPrint("Upload failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// Update Firestore profile
  Future<void> _updateProfile(String userId) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
      String? imageUrl;

      if (_imageFile != null) {
        imageUrl = await _uploadToCloudinary(_imageFile!);
      }

      await docRef.update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'batch': _batchController.text.trim(),
        'department': _departmentController.text.trim(),
        if (imageUrl != null) 'profileImage': imageUrl,
      });

      setState(() {
        _isEditing = false;
        _imageFile = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

  ///Delete Firestore profile
  Future<void> _deleteProfile(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile deleted')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final docRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.pink,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => _updateProfile(widget.userId),
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteProfile(widget.userId),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final profileImage = data['profileImage'] ?? '';

          // Update controllers
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _batchController.text = data['batch'] ?? '';
          _departmentController.text = data['department'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 16),
            child: Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.pink.shade100,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (profileImage.isNotEmpty
                            ? NetworkImage(profileImage)
                            : null) as ImageProvider?,
                        child: (profileImage.isEmpty && _imageFile == null)
                            ? const Icon(Icons.person, size: 55, color: Colors.white)
                            : null,
                      ),
                      if (_isEditing)
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: InkWell(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.pink,
                              child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (_isUploading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: CircularProgressIndicator(color: Colors.pink),
                    ),

                  // 🔹 Profile Info
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _isEditing
                              ? _editableField("Name", _nameController)
                              : _displayField("Name", data['name']),
                          _isEditing
                              ? _editableField("Email", _emailController)
                              : _displayField("Email", data['email']),
                          _isEditing
                              ? _editableField("Phone", _phoneController)
                              : _displayField("Phone", data['phone']),
                          _isEditing
                              ? _editableField("Batch", _batchController)
                              : _displayField("Batch", data['batch']),
                          _isEditing
                              ? _editableField("Department", _departmentController)
                              : _displayField("Department", data['department']),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔹 Text display mode
  Widget _displayField(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        "$title: ${value ?? '-'}",
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  // 🔹 Editable text field
  Widget _editableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.pink, width: 2),
          ),
        ),
      ),
    );
  }
}
