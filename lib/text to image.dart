import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'Appbar.dart';
import 'Drawer.dart';
import 'ip_class.dart';
class TextToImage extends StatefulWidget {
  const TextToImage({Key? key}) : super(key: key);
  @override
  State<TextToImage> createState() => _TextToImageState();
}
class _TextToImageState extends State<TextToImage> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _pickedImage;
  final IpController ipController = Get.find<IpController>();
  Uint8List? _processedImage;
  String _secretMessage = "";
  var isObscure = true.obs;
  String _password = "";

  Future<void> _pickImage() async {
    try {
      showModalBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Take a picture'),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImage(ImageSource.gallery);
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);

      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
        print('Image picked from $source: ${pickedFile.path}');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _sendImageToServer() async {
    if (_pickedImage == null || _secretMessage.isEmpty) {
      return;
    }
    try {
      String ip = ipController.ipAddress.value;
      print(ip);
      var uri = Uri.parse('$ip/encode'); // Adjust the URL
      var request = http.MultipartRequest('POST', uri)
        ..fields['password'] = _password
        ..fields['secret_message'] = _secretMessage
        ..files.add(await http.MultipartFile.fromPath(
          'file', _pickedImage!.path,
          filename: _pickedImage!.path.split('/').last,
        ));
      print(ip);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sending image to server...'),
          duration: Duration(seconds: 3),
        ),
      );
      var response = await request.send();
      print("Response status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        final contentType = response.headers['content-type'];
        if (contentType == null || !contentType.contains('image')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid content type'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        setState(() {
          _processedImage = bytes;
        });
      } else {
        final errorResponse = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to encode image'),
            duration: Duration(seconds: 2),
          ),
        );
        print('Failed to encode image: $errorResponse');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed due to $e'),
          duration: Duration(seconds: 2),
        ),
      );
      print('Error sending image to server: $e');
    }
  }

  Future<void> _saveImage(Uint8List imageBytes) async {
    try {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/temp_image.png';
      final file = File(imagePath);
      await file.writeAsBytes(imageBytes);
      await GallerySaver.saveImage(imagePath, albumName: "MyImages");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image saved to gallery'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save image due to $e'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<String?> uploadImageToFirebase(Uint8List imageBytes) async {
    try {
      // Ensure user is authenticated
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User not authenticated');
        return null;
      }
      // Use user UID to create file path
      String uid = user.uid;
      String fileName = 'user_uploads/$uid/Text in Image/${DateTime.now().millisecondsSinceEpoch}.png';
      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref().child(fileName);
      UploadTask uploadTask = ref.putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Uploaded image URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image to Firebase: $e');
      return null;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(),
      drawer: AppDrawer(),
      body: Container(
        width: Get.width,
        height: Get.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff98dce1), Color(0xff3f5efb)],
            stops: [0.25, 0.75],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                SizedBox(height:25),
                Text(
                  "Encrypt Message".toUpperCase(),
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 20),
                Text(
                  "Pick Image",
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20),
                FloatingActionButton(
                  onPressed: _pickImage,
                  tooltip: 'Pick Image',
                  child: const Icon(
                    Icons.photo_library,
                    size: 40,
                  ),
                ),
                SizedBox(height: 25),
                Container(
                  width: 250,
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _secretMessage = value;
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white54,
                      hintText: 'Enter Secret Message',
                      hintStyle: const TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Obx(() => Container(
                  width: 250,
                  child: TextField(
                    obscureText: isObscure.value,
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
                          isObscure.value = !isObscure.value;
                        },
                        child: Icon(
                          isObscure.value ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                    style: const TextStyle(color: Colors.black),
                    onChanged: (value) {
                      _password = value;
                    },
                  ),
                )),
                SizedBox(height: 25),
                TextButton(
                  onPressed: _sendImageToServer,
                  child: Container(
                    width: 130,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30)),
                    child: const Center(
                      child: Text(
                        "Hide Message",
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
                      : Image.memory(_processedImage!,
                  fit: BoxFit.cover,),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed:() async {
                        if (_processedImage != null) {
                          await _saveImage(_processedImage!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No processed image to save'),
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
      ),
    );
  }
}
