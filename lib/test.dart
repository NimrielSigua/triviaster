import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Admin extends StatefulWidget {
  final String userName;
  final String role;

  const Admin({Key? key, required this.userName, required this.role}) : super(key: key);

  @override
  _AdminState createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  final TextEditingController userAnswerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.grey[800]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.role != 'Screen')
                Column(
                  children: [
                    Container(
                      alignment: Alignment.topCenter,
                      padding: EdgeInsets.only(top: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Welcome, ",
                            style: TextStyle(
                              fontFamily: 'PressStart2P',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.greenAccent,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${widget.userName}",
                            style: TextStyle(
                              fontFamily: 'PressStart2P',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.purpleAccent,
                              shadows: [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.purpleAccent,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              // Countdown visible to all roles
              buildCountdownTimer(), // Call the countdown timer widget here

              if (widget.role == 'admin')
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: ElevatedButton(
                    onPressed: startTrivia,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.orangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    ),
                    child: const Text('Start the trivia'),
                  ),
                ),
              const SizedBox(height: 20),

              // StreamBuilder for displaying the active question
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('active_question')
                    .doc('current')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Text(
                      "Wait for the admin to start the trivia.",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final bool isActive = data?['isActive'] ?? false;
                  final question = data?['question'];

                  if (!isActive) {
                    return Text(
                      "Wait for the admin to start the trivia.",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    );
                  }

                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "$question",
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          if (widget.role == 'student')
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: userAnswerController,
                                    decoration: InputDecoration(
                                      labelText: 'Enter your answer',
                                      labelStyle: TextStyle(color: Colors.yellowAccent),
                                      border: OutlineInputBorder(),
                                    ),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: submitAnswer,
                                    style: ElevatedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      backgroundColor: Colors.orangeAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 20),
                                    ),
                                    child: const Text('Submit Answer'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    
    );
  }

  // Countdown Timer Method
  StreamBuilder<DocumentSnapshot> buildCountdownTimer() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('active_question')
          .doc('current')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Text(
            "Countdown not started.",
            style: TextStyle(color: Colors.white, fontSize: 18),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final timeRemaining = data?['timeRemaining'] ?? 0;
        final isActive = data?['isActive'] ?? false;

        if (!isActive) {
          return Text(
            "Waiting for trivia to start...",
            style: TextStyle(color: Colors.white, fontSize: 18),
          );
        }

        return Text(
          "$timeRemaining",
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.redAccent,
                offset: Offset(0, 0),
              ),
            ],
          ),
        );
      },
    );
  }

  // Placeholder method for starting the trivia
  void startTrivia() {
    // Implement trivia start logic
  }

  // Placeholder method for submitting the answer
  void submitAnswer() {
    // Implement answer submission logic
  }
}
