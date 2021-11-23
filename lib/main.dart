// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseStorage storage = FirebaseStorage.instance;
FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;
String? userID;

//initialisation Firebase
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //Récupérer l'identifiant dès le début
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
      userID = user.uid;
    }
  });
}

// page profil
class ProfilPage extends StatelessWidget {
  const ProfilPage({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text('Page de profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshPage(context),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [
            UserInfo(),
            ModifyImage(),
          ],
        ),
      ),
    );
  }
}

// Partie supérieur de la page profil
class UserInfo extends StatelessWidget {
  const UserInfo({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 30, 0, 30),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.teal,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.amber.shade300,
            Colors.amber.shade700,
            Colors.amber.shade900
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          ImagePicture(),
          SizedBox(height: 10),
          ProfilTextSection(),
        ],
      ),
    );
  }
}

class ModifyImage extends StatefulWidget {
  const ModifyImage({Key? key}) : super(key: key);
  @override
  _ModifyImageState createState() => _ModifyImageState();
}

class _ModifyImageState extends State<ModifyImage> {
  File? _image;
  final picker = ImagePicker();

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

  Future getCamera() async {
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future uploadFile() async {
    Reference storageRef = storage.ref('Users').child('$userID.png');
    UploadTask uploadTask = storageRef.putFile(_image!);
    await uploadTask.whenComplete(() {
      print('Photo de profil mise à jour');
      refreshPage(context);
    });
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 150,
          child: Column(
            children: <Widget>[
              ListTile(
                onTap: () {
                  Navigator.pop(context);
                  getCamera();
                },
                leading: const Icon(Icons.photo_camera),
                title: const Text("Caméra"),
              ),
              ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    getImage();
                  },
                  leading: const Icon(Icons.photo_library),
                  title: const Text("Bibliothèque photo"))
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: Colors.black,
            ),
            child: const Text('Modifier ma photo'),
            onPressed: () => _showOptions(context),
          ),
          _image == null
              ? const Text('Sélectionnez une image')
              : Container(
                  margin: const EdgeInsets.all(10),
                  height: 150,
                  width: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.file(_image!),
                  ),
                ),
          _image == null
              ? const Text('Puis enregistrez-la dans Firebase')
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.amber,
                  ),
                  child: const Text('Envoyer dans Firebase'),
                  onPressed: () => uploadFile(),
                ),
        ],
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProfilPage(),
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
    Reference ref = storage.ref().child("Users/$userID.png");
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

/* class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? _image;
  final picker = ImagePicker();

  Future uploadFile() async {
    Reference storageRef = storage.ref('Users').child('$userID.png');
    UploadTask uploadTask = storageRef.putFile(_image!);
    // on peut mettre un loading ici
    await uploadTask.whenComplete((() {
      print('Photo de profil mise à jour');
      /* refreshPage(context); */
    }));
  } */
/* 
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
} */

class GetUserData extends StatelessWidget {
  final String fieldName;
  final TextStyle fieldStyle;
  const GetUserData({
    Key? key,
    required this.fieldName,
    required this.fieldStyle,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    CollectionReference users = firestore.collection('Users');
    return FutureBuilder<DocumentSnapshot>(
      future: users.doc(userID).get(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Un problème est survenu',
            style: fieldStyle,
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          return Text(
            data[fieldName],
            style: fieldStyle,
          );
        }
        return Text(
          'En cours de chargement',
          style: fieldStyle,
        );
      },
    );
  }
}

class ProfilTextSection extends StatelessWidget {
  const ProfilTextSection({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GetUserData(
          fieldName: 'pseudo',
          fieldStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        const GetUserData(
          fieldName: 'bio',
          fieldStyle: TextStyle(
            color: Colors.white,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.location_on,
              color: Colors.white,
            ),
            GetUserData(
              fieldName: 'location',
              fieldStyle: TextStyle(
                color: Colors.white,
                fontSize: 17,
              ),
            ),
          ],
        )
      ],
    );
  }
}

refreshPage(context) {
  Navigator.pushReplacement(
    context,
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => const ProfilPage(),
      transitionDuration: const Duration(seconds: 0),
    ),
  );
}
