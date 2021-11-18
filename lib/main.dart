// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

FirebaseStorage storage = FirebaseStorage.instance;
FirebaseAuth auth = FirebaseAuth.instance;

//initialisation Firebase
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  getUserID();
  runApp(const MyApp());
}

getUserID() {
  auth.authStateChanges().listen((User? user) {
    if (user == null) {
      try {
        print('Utilisateur non connecté');
        auth.signInWithEmailAndPassword(
            email: 'test@lili.com', password: 'lollol');
      } catch (e) {
        print(e.toString());
      }
    } else {
      print('Utilisateur connecté:' + user.email!);
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ImagePicture(),
    );
  }
}

class ImagePicture extends StatefulWidget {
  const ImagePicture({Key? key}) : super(key: key);
  @override
  _ImagePictureState createState() => _ImagePictureState();
}

class _ImagePictureState extends State<ImagePicture> {
  String? userPhotoUrl;
  String defaultUrl =
      'https://icon-library.com/images/default-profile-icon/default-profile-icon-16.jpg';

  @override
  void initState() {
    super.initState();
    getProfilImage();
  }

  getProfilImage() {
    Reference ref = storage.ref().child("Users/dave.jpg");
    ref.getDownloadURL().then((downloadUrl) {
      setState(() {
        userPhotoUrl = downloadUrl.toString();
      });
    }).catchError((e) {
      setState(() {
        print("Un problème est survenu: ${e.error}");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200,
      child: CircleAvatar(
        backgroundColor: Colors.grey,
        backgroundImage: userPhotoUrl == null
            ? NetworkImage(defaultUrl)
            : NetworkImage(userPhotoUrl!),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  final picker = ImagePicker();

  Future uploadFile() async {
    Reference storageRef = storage.ref('Users').child('test.png');
    UploadTask uploadTask = storageRef.putFile(_image!);
    // on peut mettre un loading ici
    await uploadTask.whenComplete(() => print('File uploaded'));
  }

  Future getImage() async {
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Picker Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image == null
                ? const Text('No image selected.')
                : Image.file(_image!),
            ElevatedButton(
              child: const Text('Envoyer dans Firebase'),
              onPressed: () => uploadFile(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
