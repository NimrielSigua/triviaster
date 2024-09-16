import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triviaster/admin.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
     apiKey: "AIzaSyDE_YDJpKboa_Nk8h1Y7lneAU5TLRkFRQ4",
     authDomain: "triviaster-22089.firebaseapp.com",
     projectId: "triviaster-22089",
     storageBucket: "triviaster-22089.appspot.com",
     messagingSenderId: "897767391224",
     appId: "1:897767391224:web:d3079f7ddb9f0aa95de00d"
    ));
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firestore Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const FirestoreAddAndDisplay(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FirestoreAddAndDisplay extends StatefulWidget {
  const FirestoreAddAndDisplay({Key? key}) : super(key: key);

  @override
  _FirestoreAddAndDisplayState createState() => _FirestoreAddAndDisplayState();
}

class _FirestoreAddAndDisplayState extends State<FirestoreAddAndDisplay> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final Uuid uuid = Uuid();

  CollectionReference users = FirebaseFirestore.instance.collection('users');

  Future<void> Register() async {
    String name = nameController.text;
    
    // Check if the username already exists in Firestore
    QuerySnapshot querySnapshot = await users
        .where('name', isEqualTo: name)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      // Show snackbar if username already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Username already exists!')),
      );
    } else {
      // If username doesn't exist, proceed with registration
      String userId = uuid.v4(); // Generate a new random userId using the Uuid package

      await users
          .add({
            'userId': userId, // Randomized unique userId
            'role': 'student', // Randomized unique userId
            'name': nameController.text, // Name of the person
            'password': passwordController.text, // Password of the person
          })
          .then((value) => print("User Added with ID: $userId"))
          .catchError((error) => print("Failed to add user: $error"));
      
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User registered successfully!')),
      );
    }
  }

// In FirestoreAddAndDisplay
Future<void> Login() async {
  String name = nameController.text;
  String password = passwordController.text;

  // Query Firestore to check if the email and password exist
  QuerySnapshot querySnapshot = await users
      .where('name', isEqualTo: name)
      .where('password', isEqualTo: password)
      .get();

  if (querySnapshot.docs.isNotEmpty) {
    // Get the role of the user
    String role = querySnapshot.docs.first['role'] ?? 'student';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Admin(
          role: role,
          userName: name, // Pass the user's name to the Admin screen
        ),
      ),
    );
  } else {
    // No matching document found, login failed
    print("Login Failed: Invalid credentials");
  }
}

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Triviaster',
          style: TextStyle(
            fontFamily: 'PressStart2P', // Custom gaming font
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                offset: Offset(1.5, 1.5),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.7),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent, // Set background to transparent
        elevation: 0, // Remove default shadow
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.gamepad), // Gaming-related icon
          color: Colors.white,
          onPressed: () {
            // Handle icon press
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings), // Example action icon
            color: Colors.white,
            onPressed: () {
              // Handle settings icon press
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Welcome to Triviaster!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
                shadows: [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 3,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.amber),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orangeAccent),
                ),
              ),
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.amber),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.orangeAccent),
                ),
              ),
              obscureText: true,
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: Register,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black, backgroundColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              child: Text(
                'Register',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: Login,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              child: Text(
                'Login',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      backgroundColor: Colors.black87,
    );
  }
}


