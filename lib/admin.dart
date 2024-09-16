import 'dart:async';
 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
 
class TimerManager {
  static final TimerManager _instance = TimerManager._internal();
  Timer? _timer;
  Duration _remainingTime = Duration(seconds: 15);
  final ValueNotifier<Duration> _remainingTimeNotifier =
      ValueNotifier<Duration>(Duration(seconds: 15));
 
  factory TimerManager() {
    return _instance;
  }
 
  TimerManager._internal();
 
  ValueNotifier<Duration> get remainingTimeNotifier => _remainingTimeNotifier;
 
  void startCountdown(Duration duration) {
    _remainingTime = duration;
    _remainingTimeNotifier.value = _remainingTime;
 
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds <= 0) {
        _timer?.cancel();
      } else {
        _remainingTime = _remainingTime - Duration(seconds: 1);
        _remainingTimeNotifier.value = _remainingTime;
      }
    });
  }
 
  void stopCountdown() {
    _timer?.cancel();
  }
 
  Duration get remainingTime => _remainingTime;
}
 

 
class Admin extends StatefulWidget {
  final String role;
  final String userName;
 
  const Admin({Key? key, required this.role, required this.userName})
      : super(key: key);
 
  @override
  _AdminState createState() => _AdminState();
}
 
class _AdminState extends State<Admin> with SingleTickerProviderStateMixin {
  final TextEditingController questionController = TextEditingController();
  final TextEditingController answerController = TextEditingController();
  final TextEditingController userAnswerController = TextEditingController();
  final Uuid uuid = Uuid();
 
  CollectionReference questions =
      FirebaseFirestore.instance.collection('questions');
  CollectionReference activeQuestion =
      FirebaseFirestore.instance.collection('active_question');
  CollectionReference answers =
      FirebaseFirestore.instance.collection('answers');
 
  String? currentQuestion;
  String? correctAnswer;
  String? activeQuestionId;
  ValueNotifier<int> _timeRemainingNotifier = ValueNotifier<int>(15);
  Timer? _timer;
 
  late AnimationController _controller;
  late Animation<double> _animation;
  late List<String> _names;
  late double _angle;
 
  @override
  void initState() {
    super.initState();
    if (widget.role == 'Screen') {
      listenForTriviaEnd(
          context); // Start listening when the screen user is active
    }
    fetchActiveQuestion();
 
    _angle = 0.0;
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..addListener(() {
        setState(() {
          _angle += _animation.value;
        });
      });
 
    _animation = Tween<double>(begin: 0.0, end: 2 * pi).animate(_controller);
  }
 
  String selectRandomWinner(List<String> users) {
    final random = Random();
    final randomIndex = random.nextInt(users.length);
    return users[randomIndex];
  }
 
  // Function to add a question to Firestore
  Future<void> registerQuestion() async {
    String questionId = uuid.v4();
 
    await questions.add({
      'questionId': questionId,
      'question': questionController.text,
      'answer': answerController.text,
    }).then((value) {
      print("Question Added with ID: $questionId");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully added question')),
      );
    }).catchError((error) {
      print("Failed to add question: $error");
    });
 
    questionController.clear();
    answerController.clear();
  }
 
  void startCountdownTimer(String role) {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('active_question')
          .doc('current')
          .get();

      if (snapshot.exists) {
        int timeRemaining = snapshot.get('timeRemaining') ?? 0;
        bool isActive = snapshot.get('isActive') ?? false;

        if (timeRemaining > 0 && isActive) {
          await FirebaseFirestore.instance
              .collection('active_question')
              .doc('current')
              .update({'timeRemaining': timeRemaining - 1});
        } else {
          timer.cancel();
          await endTrivia();
        }
      } else {
        timer.cancel();
      }
    });
  }
  // Function to fetch questions from Firestore
  Future<List<Map<String, dynamic>>> fetchQuestions() async {
    try {
      QuerySnapshot querySnapshot = await questions.get();
      List<QueryDocumentSnapshot> docs = querySnapshot.docs;
 
      return docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching questions: $e");
      return [];
    }
  }
 
  // Function to select a random question from the list
  Map<String, dynamic>? getRandomQuestion(
      List<Map<String, dynamic>> questionsList) {
    if (questionsList.isEmpty) return null;
 
    final randomIndex = (questionsList.length * Random().nextDouble()).toInt();
    return questionsList[randomIndex];
  }
 
  // Function to start trivia and display a random question
  void startTrivia() async {
    List<Map<String, dynamic>> questionsList = await fetchQuestions();
 
    Map<String, dynamic>? randomQuestion = getRandomQuestion(questionsList);
 
    if (randomQuestion != null) {
      setState(() {
        currentQuestion = randomQuestion['question'];
        correctAnswer = randomQuestion['answer'];
      });
 
      await addActiveQuestion();
      startCountdownTimer(widget.role); // Start the countdown timer
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions available')),
      );
    }
  }
 
  // Function to add a random question as the active question
  Future<void> addActiveQuestion() async {
    if (currentQuestion != null && correctAnswer != null) {
      String activeQuestionIdGenerated = uuid.v4();
      await FirebaseFirestore.instance
          .collection('active_question')
          .doc('current')
          .set({
        'activeQuestionId': activeQuestionIdGenerated,
        'question': currentQuestion,
        'answer': correctAnswer,
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': true,
        'timeRemaining': 15, // Initial time
      }).then((value) {
        print("Active randomized question added");
      }).catchError((error) {
        print("Failed to add active question: $error");
      });

      setState(() {
        activeQuestionId = activeQuestionIdGenerated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully updated active question')),
      );
    }
  }

  // Function to fetch the active question
  Future<void> fetchActiveQuestion() async {
    DocumentSnapshot snapshot = await activeQuestion.doc('current').get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      setState(() {
        currentQuestion = data['question'];
        correctAnswer = data['answer'];
        activeQuestionId = data['activeQuestionId']; // Store activeQuestionId
      });
    }
  }
 
  Future<void> endTrivia() async {
    await FirebaseFirestore.instance
        .collection('active_question')
        .doc('current')
        .update({
      'isActive': false,
      'timeRemaining': 0,
    }).then((value) {
      print("Trivia ended, isActive set to false");
    }).catchError((error) {
      print("Failed to end trivia: $error");
    });
  }
 
  bool previousIsActive = true; // Track the previous state of 'isActive'
 
  void listenForTriviaEnd(BuildContext context) {
    FirebaseFirestore.instance
        .collection('active_question')
        .doc('current')
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        bool isActive = snapshot.data()?['isActive'] ?? true;
 
        // Only show the wheel when 'isActive' changes from true to false
        if (previousIsActive && !isActive) {
          List<String> correctUsers = await fetchCorrectUsers();
          showCorrectUsersDialog(context, correctUsers);
        }
 
        // Update the previous state
        previousIsActive = isActive;
      }
    });
  }
 
  // Function to submit the user's answer
  Future<void> submitAnswer() async {
    // Fetch the latest active question and answer
    DocumentSnapshot snapshot = await activeQuestion.doc('current').get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final correctAnswerFromDB = data['answer'] as String?;
      final activeQuestionIdFromDB = data['activeQuestionId'] as String?;
 
      if (correctAnswerFromDB != null && activeQuestionIdFromDB != null) {
        String userAnswer = userAnswerController.text.trim();
 
        // Check if the user has already submitted an answer for the current question
        QuerySnapshot userSubmission = await answers
            .where('username', isEqualTo: widget.userName)
            .where('activeQuestionId', isEqualTo: activeQuestionIdFromDB)
            .get();
 
        if (userSubmission.docs.isNotEmpty) {
          // User has already submitted an answer for this question
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'You have already submitted an answer for this question.')),
          );
          return;
        }
 
        bool isCorrect =
            userAnswer.toLowerCase() == correctAnswerFromDB.toLowerCase();
 
        try {
          await answers.add({
            'username': widget.userName,
            'question': currentQuestion,
            'user_answer': userAnswer,
            'is_correct': isCorrect,
            'activeQuestionId': activeQuestionIdFromDB,
          });
 
          if (isCorrect) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Correct answer!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Incorrect answer. Better luck next time!')),
            );
          }
 
          // Clear text field after saving
          userAnswerController.clear();
        } catch (error) {
          print("Failed to add answer: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add answer: $error')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No current answer available')),
        );
      }
    }
  }
 
  // Function to fetch usernames who answered the current question correctly
  Future<List<String>> fetchCorrectUsers() async {
    List<String> correctUsers = [];
 
    // Fetch the active question
    DocumentSnapshot snapshot = await activeQuestion.doc('current').get();
    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      final currentActiveQuestionId = data['activeQuestionId'];
 
      // Query the 'answers' collection for correct answers with matching activeQuestionId
      QuerySnapshot answerSnapshot = await answers
          .where('activeQuestionId', isEqualTo: currentActiveQuestionId)
          .where('is_correct', isEqualTo: true)
          .get();
 
      // Extract usernames of users who got the correct answer
      answerSnapshot.docs.forEach((doc) {
        correctUsers.add((doc.data() as Map<String, dynamic>)['username']);
      });
    }
 
    return correctUsers;
  }
 
  // Function to display a dialog with the usernames of correct users
  void showCorrectUsersDialog(BuildContext context, List<String> correctUsers) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Players who got the correct answer',
            style: TextStyle(
              color: Colors.orangeAccent,
              fontFamily: 'PressStart2P', // Gaming-themed font
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          titlePadding: EdgeInsets.all(16),
          contentPadding: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.black87,
          content: Container(
            height: correctUsers.isNotEmpty
                ? 380
                : 80, // Adjust the height based on content
            child: correctUsers.isNotEmpty
                ? SpinnerWidget(
                    names: correctUsers,
                    onWinnerSelected: (winner) {
                      Navigator.of(context).pop(); // Close the spinner dialog
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                              'Lucky Winner',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontFamily: 'PressStart2P',
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(2, 2),
                                    blurRadius: 4,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                ],
                              ),
                            ),
                            titlePadding: EdgeInsets.all(16),
                            contentPadding: EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Colors.black87,
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 50,
                                  color: Colors.yellowAccent,
                                ),
                                SizedBox(height: 10),
                                Column(
                                  children: [
                                    Text(
                                      'The lucky winner is:',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(1, 1),
                                            blurRadius: 4,
                                            color:
                                                Colors.black.withOpacity(0.7),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      '$winner',
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 40,
                                        fontFamily: 'PressStart2P',
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                        shadows: [
                                          Shadow(
                                            offset: Offset(2, 2),
                                            blurRadius: 6,
                                            color:
                                                Colors.black.withOpacity(0.9),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pop(); // Close the winner dialog
                                  endTrivia(); // Set isActive to false
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.orangeAccent,
                                      size: 20,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'OK',
                                      style: TextStyle(
                                        color: Colors.orangeAccent,
                                        fontFamily: 'PressStart2P',
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  )
                : Center(
                    child: Text(
                      "No one answered correctly yet.",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Close',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontFamily: 'PressStart2P',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.role == 'admin'
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(
                        "Add New Question",
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontFamily: 'PressStart2P', // Gaming-themed font
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      titlePadding: EdgeInsets.all(16),
                      contentPadding: EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.black87,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: questionController,
                            decoration: InputDecoration(
                              labelText: 'Enter the question',
                              labelStyle: TextStyle(color: Colors.yellowAccent),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.orangeAccent),
                              ),
                              filled: true,
                              fillColor: Colors.grey[850],
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: answerController,
                            decoration: InputDecoration(
                              labelText: 'Enter the correct answer',
                              labelStyle: TextStyle(color: Colors.yellowAccent),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.orangeAccent),
                              ),
                              filled: true,
                              fillColor: Colors.grey[850],
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontFamily: 'PressStart2P',
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text(
                            "Save",
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontFamily: 'PressStart2P',
                            ),
                          ),
                          onPressed: () {
                            registerQuestion();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Icon(Icons.add),
              backgroundColor: Colors.orangeAccent,
            )
          : null,
      appBar: AppBar(
        title: Text(
          "Triviaster",
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                offset: Offset(2, 2),
                blurRadius: 4,
                color: Colors.black.withOpacity(0.7),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
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

}
 
class SpinnerWidget extends StatefulWidget {
  final List<String> names;
  final ValueChanged<String> onWinnerSelected;
 
  SpinnerWidget({required this.names, required this.onWinnerSelected});
 
  @override
  _SpinnerWidgetState createState() => _SpinnerWidgetState();
}
 
class _SpinnerWidgetState extends State<SpinnerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _angle;
 
  @override
  void initState() {
    super.initState();
    _angle = 0.0;
 
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..addListener(() {
        setState(() {
          _angle += _animation.value;
        });
      });
 
    _animation = Tween<double>(begin: 0.0, end: 2 * pi).animate(_controller);
  }
 
  void _spinWheel() {
    if (widget.names.isEmpty) return;
 
    _controller.forward().then((_) {
      _controller.reset();
      final selectedIndex =
          (widget.names.length * (_angle / (2 * pi))).toInt() %
              widget.names.length;
      widget.onWinnerSelected(widget.names[selectedIndex]);
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 300,
            height: 300,
            child: CustomPaint(
              painter: WheelPainter(angle: _angle, names: widget.names),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _spinWheel,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.orangeAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              textStyle: TextStyle(
                fontFamily: 'PressStart2P', // Gaming-themed font
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Text('Spin the Wheel'),
          ),
        ],
      ),
    );
  }
}
 
class WheelPainter extends CustomPainter {
  final double angle;
  final List<String> names;
 
  WheelPainter({required this.angle, required this.names});
 
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final double sliceAngle = 2 * pi / names.length;
 
    // Draw each slice of the wheel
    for (int i = 0; i < names.length; i++) {
      final double startAngle = sliceAngle * i + angle;
      final double sweepAngle = sliceAngle;
 
      // Draw slice with gradient effect
      final Paint paint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.primaries[i % Colors.primaries.length],
            Colors.primaries[(i + 1) % Colors.primaries.length],
          ],
          stops: [0.5, 1.0],
        ).createShader(
            Rect.fromCircle(center: Offset(radius, radius), radius: radius))
        ..style = PaintingStyle.fill;
 
      canvas.drawArc(
        Rect.fromCircle(center: Offset(radius, radius), radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
 
      // Draw text in each slice
      final TextPainter textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
 
      textPainter.text = TextSpan(
        text: names[i],
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              offset: Offset(1, 1),
              blurRadius: 3,
              color: Colors.black.withOpacity(0.7),
            ),
          ],
        ),
      );
      textPainter.layout();
 
      final double textAngle = startAngle + sweepAngle / 2;
      final double x = radius + radius * 0.6 * cos(textAngle);
      final double y = radius + radius * 0.6 * sin(textAngle);
 
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(textAngle + pi / 2);
      textPainter.paint(
        canvas,
        Offset(
          -textPainter.width / 2,
          -textPainter.height / 2,
        ),
      );
      canvas.restore();
    }
 
    // Draw wheel border
    final Paint borderPaint = Paint()
      ..color = Colors.yellowAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
 
    canvas.drawCircle(Offset(radius, radius), radius, borderPaint);
  }
 
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}