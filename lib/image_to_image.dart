import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'Appbar.dart';
import 'Drawer.dart';
import 'ip_class.dart';
class ImageToImage extends StatefulWidget {
  const ImageToImage({Key? key}) : super(key: key);
  @override
  State<ImageToImage> createState() => _ImageToImageState();
}
class _ImageToImageState extends State<ImageToImage> {
  final IpController ipController = Get.find<IpController>();
  var isobsecure = true.obs;
  final ImagePicker _imagePicker = ImagePicker();
  File? _coverImage;
  File? _secretImage;
  File? _processedImage;
  final TextEditingController _passwordController = TextEditingController();
  FirebaseStorage storage = FirebaseStorage.instance;
  Future<void> _pickImage(bool isCover) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose an option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Take Photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickImageFromSource(isCover, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Pick from Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickImageFromSource(isCover, ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromSource(bool isCover, ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          if (isCover) {
            _coverImage = File(pickedFile.path);
          } else {
            _secretImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _hideImage() async {
    if (_coverImage == null || _secretImage == null) {
      print('Cover image or secret image not selected');
      return;
    }
    String ip = ipController.ipAddress.value;
    var request = http.MultipartRequest('POST', Uri.parse('$ip/hide_image'));
    request.files.add(await http.MultipartFile.fromPath('cover_image', _coverImage!.path));
    request.files.add(await http.MultipartFile.fromPath('secret_image', _secretImage!.path));
    request.fields['password'] = _passwordController.text;
    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await http.Response.fromStream(response);
      var jsonResponse = jsonDecode(responseData.body);
      var encodedImageUrl = jsonResponse['encoded_image_url'];
      _fetchImage(encodedImageUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to hide image'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _fetchImage(String url) async {
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var documentDirectory = await getApplicationDocumentsDirectory();
      var filePath = '${documentDirectory.path}/processed_image.png';
      File file = File(filePath);
      file.writeAsBytesSync(response.bodyBytes);
      setState(() {
        _processedImage = file;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image processed successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      print('Failed to fetch image');
    }
  }
  Future<String?> uploadImageToFirebase(File imageFile) async {
    try {
      // Ensure user is authenticated
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not authenticated');
        return null;
      }
      // Create a reference to Firebase Storage
      FirebaseStorage storage = FirebaseStorage.instance;
      // Create a unique file name for the image
      String uid = user.uid;
      String fileName = 'user_uploads/$uid/Image in image/${DateTime.now().millisecondsSinceEpoch}.png';
      // Create a reference to the file path
      Reference ref = storage.ref().child(fileName);
      // Upload the file to Firebase Storage
      await ref.putFile(imageFile);
      // Get the download URL of the uploaded file
      String downloadUrl = await ref.getDownloadURL();
      print('Uploaded image URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image to Firebase: $e');
      return null;
    }
  }
  Future<void> _saveImageToGallery() async {
    if (_processedImage != null) {
      bool? result = await GallerySaver.saveImage(_processedImage!.path);
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved to gallery'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save image to gallery'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(),
      drawer: AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff98dce1), Color(0xff3f5efb)],
            stops: [0.25, 0.75],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 25),
              Text(
                "Encrypt message".toUpperCase(),
                style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.bold
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Pick Cover Image",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              FloatingActionButton(
                onPressed: () => _pickImage(true),
                tooltip: 'Pick Cover Image',
                child: const Icon(
                  Icons.photo_library,
                  size: 40,
                  color: Colors.black,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Pick Secret Image",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              FloatingActionButton(
                onPressed: () => _pickImage(false),
                tooltip: 'Pick Secret Image',
                child: const Icon(
                  Icons.photo_library,
                  size: 40,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20),
              Obx(() =>
                  Container(
                    width: 250,
                    child: TextField(
                      obscureText: isobsecure.value,
                      controller: _passwordController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white54,
                        hintText: 'Enter Password',
                        hintStyle: const TextStyle(color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 2.0,
                          ),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {
                            isobsecure.toggle();
                          },
                          child: Icon(
                            isobsecure.isTrue
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                  )),
              SizedBox(height: 25),
              TextButton(
                onPressed: _hideImage,
                child: Container(
                  width: 130,
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30)),
                  child: const Center(
                    child: Text(
                      "Hide Image",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30),
              Container(
                width: 250,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2.0),
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white54,
                ),
                child: _processedImage == null
                    ? const Center(
                  child: Text(
                    'No Image Selected',
                    style: TextStyle(color: Colors.black),
                  ),
                )
                    : Image.file(
                  _processedImage!,
                  fit: BoxFit.cover,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _saveImageToGallery,
                    child: Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30)),
                      child: const Center(
                        child: Text(
                          "Save",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (_processedImage != null) {
                        String? uploadedImageUrl = await uploadImageToFirebase(_processedImage!);
                        if (uploadedImageUrl != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Image uploaded to Firebase successfully'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to upload image to Firebase'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No processed image to upload'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30)),
                      child: const Center(
                        child: Text(
                          "Upload",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
