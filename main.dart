import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'data.dart'; // Import the data file

void main() {
  runApp(const QuestifyApp());
}

class QuestifyApp extends StatelessWidget {
  const QuestifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Questify',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white),
        ),
      ),
      home: const QuestifyHomePage(),
    );
  }
}

class QuestifyHomePage extends StatefulWidget {
  const QuestifyHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _QuestifyHomePageState createState() => _QuestifyHomePageState();
}

class _QuestifyHomePageState extends State<QuestifyHomePage> {
  String selectedImage = '';
  String selectedQuote = '';
  String selectedAuthor = '';
  final TextEditingController questController = TextEditingController();
  final List<String> quests = [];
  bool isAddingQuest = false;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadRandomImageAndQuote();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      quests.addAll(prefs.getStringList('quests') ?? []);
    });
    // Add items to AnimatedList
    for (int i = 0; i < quests.length; i++) {
      _listKey.currentState?.insertItem(i);
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('quests', quests);
  }

  void addQuest(String quest) {
    setState(() {
      int index = quests.length;
      quests.add(quest);
      _listKey.currentState?.insertItem(index);
      isAddingQuest = false;
    });
    questController.clear();
    _saveData();
  }

  void completeQuest(int index) {
    setState(() {
      String removedQuest = quests.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildItem(removedQuest, animation),
      );
      _saveData();
    });
  }

  Widget _buildItem(String quest, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: GestureDetector(
        onTap: () => completeQuest(quests.indexOf(quest)),
        child: Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              quest,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  void _loadRandomImageAndQuote() {
    final random = Random();
    final imageIndex = random.nextInt(imageAssets.length); // Now selects from the entire list
    final quoteIndex = random.nextInt(quotes.length); // Randomly choose a quote

    setState(() {
      selectedImage = imageAssets[imageIndex]; // Select a random image
      selectedQuote = quotes[quoteIndex]['quote']!;
      selectedAuthor = quotes[quoteIndex]['author']!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Background color for the rest of the app
      body: Stack(
        children: [
          Column(
            children: [
              // Painting and quote section
              Expanded(
                flex: 3, // Adjusts the space taken by the painting and quote section
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4, // Set height of the container
                  child: Stack(
                    children: [
                      // Painting
                      if (selectedImage.isNotEmpty)
                        Positioned.fill(
                          child: Image.asset(
                            selectedImage,
                            fit: BoxFit.cover,
                          ),
                        ),
                      // Quote overlay
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20, // Move up from the bottom of the container
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '"$selectedQuote"',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '- $selectedAuthor',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Quest list section
              Expanded(
                flex: 7, // Adjusts the space taken by the quest list section
                child: Column(
                  children: [
                    const SizedBox(height: 10), // Adds spacing between the sections
                    Expanded(
                      child: quests.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Add tasks to complete',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Icon(
                                    Icons.arrow_downward,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ],
                              ),
                            )
                          : AnimatedList(
                              key: _listKey,
                              initialItemCount: quests.length,
                              itemBuilder: (context, index, animation) {
                                return _buildItem(quests[index], animation);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isAddingQuest)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.grey[800],
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: questController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Enter a new task',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none, // Remove the outline
                          ),
                          filled: true,
                          fillColor: Colors.grey[600], // Gray background
                        ),
                        cursorColor: Colors.grey, // Set the cursor color to gray
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (questController.text.isNotEmpty) {
                          addQuest(questController.text);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.grey[700], // Matching gray color
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 70.0), // Adjust bottom padding
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isAddingQuest = !isAddingQuest;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700], // Gray color for the button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: Text(
                    isAddingQuest ? 'Close' : 'Add a Task',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
