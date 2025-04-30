// ignore_for_file: unused_element

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sportify_final/pages/utility/api_constants.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final Color backgroundGrey = const Color(0xFFF5F5F5);
  bool isChanged = false;
  String selectedGender = "Male";
  File? _image;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  String? profilePicturePath;
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      firstNameController.text = prefs.getString('firstName') ?? "";
      lastNameController.text = prefs.getString('lastName') ?? "";
      emailController.text = prefs.getString('email') ?? "";
      phoneController.text = prefs.getString('phoneNo') ?? "";
      bioController.text = prefs.getString('bio') ?? "";
      addressController.text = prefs.getString('address') ?? "";
      selectedGender = prefs.getString('gender') ?? "Male";

      // Load profile picture
      profilePicturePath = prefs.getString('profilePicture');
      if (profilePicturePath != null && profilePicturePath!.isNotEmpty) {
        _image = File(profilePicturePath!);
      }
    });
  }

  void _updateChanges() {
    setState(() {
      isChanged = true;
    });
  }

  Future<void> _saveProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final userUuid = prefs.getString('userUuid');

    if (userUuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in!')),
      );
      return;
    }

    final profileData = {
      "gender": selectedGender,
      "bio": bioController.text,
      "address": addressController.text,
      "profilePicture": _image?.path ?? ""
    };

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}:5000/api/user/editprofile/$userUuid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profileData),
    );

    if (response.statusCode == 200) {
      // **Save data in SharedPreferences**
      await prefs.setString('gender', selectedGender);
      await prefs.setString('bio', bioController.text);
      await prefs.setString('address', addressController.text);

      if (_image != null) {
        await prefs.setString('profilePicture', _image!.path);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      setState(() {
        isChanged = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  void _editField(String field, TextEditingController controller) {
    if (field == "Bio") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditBioPage(),
        ),
      ).then((_) => _updateChanges());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              EditFieldPage(field: field, controller: controller),
        ),
      ).then((_) => _updateChanges());
    }
  }

  void _selectGender() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Select Gender",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: const Text("Male",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                value: "Male",
                groupValue: selectedGender,
                onChanged: (value) {
                  setState(() {
                    selectedGender = value.toString();
                    isChanged = true;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile(
                title: const Text("Female",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                value: "Female",
                groupValue: selectedGender,
                onChanged: (value) {
                  setState(() {
                    selectedGender = value.toString();
                    isChanged = true;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        isChanged = true;
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Edit Profile",
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: isChanged
                ? _saveProfile
                : null, // Calls API when button is enabled
            child: Text(
              "Save Changes",
              style: TextStyle(
                color: isChanged ? Colors.green : Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _image != null
                        ? FileImage(_image!) // If a new image is picked, use it
                        : (profilePicturePath != null &&
                                    profilePicturePath!.isNotEmpty
                                ? FileImage(File(profilePicturePath!))
                                : const AssetImage("assets/profile.png"))
                            as ImageProvider,
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _showImagePickerOptions,
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                    child: const Text("Change Profile Picture",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildEditableField("First Name", firstNameController,
                editableDirectly: true),
            _buildEditableField("Last Name", lastNameController,
                editableDirectly: true),
            _buildEditableField("Email", emailController, isNavigable: false),
            _buildEditableField("Phone Number", phoneController,
                isNavigable: false),
            _buildEditableField("Address", addressController,
                isNavigable: true),
            _buildEditableField(
                "Gender", TextEditingController(text: selectedGender),
                isDropdown: true),
            _buildEditableField("Bio", bioController, isNavigable: true),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller,
      {bool editableDirectly = false,
      bool isNavigable = false,
      bool isDropdown = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        readOnly: !editableDirectly,
        onChanged: (value) => _updateChanges(),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: isNavigable
              ? IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () => _editField(label, controller),
                )
              : isDropdown
                  ? IconButton(
                      icon:
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      onPressed: _selectGender,
                    )
                  : null,
        ),
      ),
    );
  }
}

class EditFieldPage extends StatelessWidget {
  final String field;
  final TextEditingController controller;

  const EditFieldPage(
      {super.key, required this.field, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit $field",
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: "Enter new value"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}

class EditBioPage extends StatefulWidget {
  const EditBioPage({super.key});

  @override
  State<EditBioPage> createState() => _EditBioPageState();
}

class _EditBioPageState extends State<EditBioPage> {
  final TextEditingController descriptionController = TextEditingController();
  String selectedSkillLevel = "Beginner";
  final TextEditingController experienceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBioData();
  }

  Future<void> _loadBioData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      descriptionController.text = prefs.getString('bioDescription') ?? "";
      selectedSkillLevel = prefs.getString('bioSkillLevel') ?? "Beginner";
      experienceController.text = prefs.getString('bioExperience') ?? "";
    });
  }

  Future<void> _saveBio() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final userUuid = prefs.getString('userUuid');

    if (userUuid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in!')),
      );
      return;
    }

    final bioData = {
      "description": descriptionController.text,
      "skillLevel": selectedSkillLevel,
      "experience": int.tryParse(experienceController.text) ?? 0,
    };

    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}:5000/api/user/edituserbio/$userUuid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(bioData),
    );

    if (response.statusCode == 200) {
      // Save data in SharedPreferences
      await prefs.setString('bioDescription', descriptionController.text);
      await prefs.setString('bioSkillLevel', selectedSkillLevel);
      await prefs.setString('bioExperience', experienceController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bio updated successfully')),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update bio')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Bio"),
      ),
      body: SingleChildScrollView(
        // Added SingleChildScrollView
        padding:
            EdgeInsets.all(isSmallScreen ? 12.0 : 16.0), // Responsive padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Describe yourself in 25 words",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: isSmallScreen ? 15 : 20), // Responsive spacing
            const Text("How do you rate your skills?",
                style: TextStyle(fontWeight: FontWeight.bold)),
            Column(
              children: ["Beginner", "Amateur", "Expert", "Pro"]
                  .map((level) => RadioListTile(
                        title: Text(level),
                        value: level,
                        groupValue: selectedSkillLevel,
                        onChanged: (value) {
                          setState(() {
                            selectedSkillLevel = value.toString();
                          });
                        },
                      ))
                  .toList(),
            ),
            SizedBox(height: isSmallScreen ? 15 : 20), // Responsive spacing
            TextField(
              controller: experienceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: "How many years of experience?",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: isSmallScreen ? 15 : 20), // Responsive spacing
            ElevatedButton(
              onPressed: _saveBio,
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
