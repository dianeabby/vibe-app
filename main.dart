import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(VibeCheckApp());
}

class VibeCheckApp extends StatefulWidget {
  @override
  State<VibeCheckApp> createState() => _VibeCheckAppState();
}

class _VibeCheckAppState extends State<VibeCheckApp> {
  List<Map<String, dynamic>> moodLog = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMoodLog();
  }

  Future<void> _loadMoodLog() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('moodLog');
    if (data != null) {
      final decoded = List<Map<String, dynamic>>.from(json.decode(data));
      setState(() {
        moodLog = decoded;
      });
    }
  }

  Future<void> _saveMoodLog(List<Map<String, dynamic>> log) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(log);
    await prefs.setString('moodLog', encoded);
  }

  void _addMoodEntry(Map<String, dynamic> entry) {
    final updatedLog = [...moodLog, entry];
    setState(() {
      moodLog = updatedLog;
    });
    _saveMoodLog(updatedLog);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      MoodSelectorScreen(moodLog: moodLog, onMoodLogged: _addMoodEntry),
      MoodCalendarPage(moodLog: moodLog),
      FaqPage(),
    ];

    return MaterialApp(
      title: 'VibeCheck',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: Scaffold(
        body: pages[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (value) => setState(() => _currentIndex = value),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.palette), label: 'Canvas'),
            BottomNavigationBarItem(
                icon: Icon(Icons.brush), label: 'Masterpiece'),
            BottomNavigationBarItem(
                icon: Icon(Icons.book), label: 'Guidebook'),
          ],
        ),
      ),
    );
  }
}

const moodColors = {
  'Happy': Color(0xFFFFEB3B),
  'Neutral': Color(0xFFFF9800),
  'Sad': Color(0xFF2196F3),
  'Angry': Color(0xFFF44336),
  'Tired': Color(0xFF9E9E9E),
  'Stressed': Color(0xFF673AB7),
  'Productive': Color(0xFFE91E63),
  'Disgusted': Color(0xFF4CAF50),
};

class MoodSelectorScreen extends StatefulWidget {
  final List<Map<String, dynamic>> moodLog;
  final Function(Map<String, dynamic>) onMoodLogged;

  MoodSelectorScreen({required this.moodLog, required this.onMoodLogged});

  @override
  State<MoodSelectorScreen> createState() => _MoodSelectorScreenState();
}

class _MoodSelectorScreenState extends State<MoodSelectorScreen> {
  final List<Map<String, String>> moods = [
    {'emoji': '😊', 'label': 'Happy'},
    {'emoji': '😐', 'label': 'Neutral'},
    {'emoji': '😢', 'label': 'Sad'},
    {'emoji': '😠', 'label': 'Angry'},
    {'emoji': '🥱', 'label': 'Tired'},
    {'emoji': '🤯', 'label': 'Stressed'},
    {'emoji': '😄', 'label': 'Productive'},
    {'emoji': '🤧', 'label': 'Disgusted'},
  ];

  String? selectedMoodLabel;
  String? selectedMoodEmoji;
  DateTime selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();

  void _selectMood(String label, String emoji) {
    setState(() {
      selectedMoodLabel = label;
      selectedMoodEmoji = emoji;
      selectedDate = DateTime.now();
      _noteController.clear();
    });
  }

  void _saveMood() {
    if (selectedMoodLabel == null || selectedMoodEmoji == null) return;

    final moodEntry = {
      'emoji': selectedMoodEmoji!,
      'label': selectedMoodLabel!,
      'note': _noteController.text.trim(),
      'timestamp': selectedDate.toIso8601String(),
    };

    widget.onMoodLogged(moodEntry);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Mood '$selectedMoodLabel' logged.")),
    );

    setState(() {
      selectedMoodLabel = null;
      selectedMoodEmoji = null;
      _noteController.clear();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
Widget build(BuildContext context) {
  final List<List<Map<String, String>>> moodRows = [];
  for (int i = 0; i < moods.length; i += 4) {
    moodRows.add(moods.sublist(i, i + 4));
  }

  return Scaffold(
    appBar: AppBar(
      title: const Text('Canvas'),
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Text(
            "Time to Paint Your Day",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Column(
            children: moodRows.map((row) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row.map((mood) {
                  final isSelected = selectedMoodLabel == mood['label'];
                  return GestureDetector(
                    onTap: () => _selectMood(mood['label']!, mood['emoji']!),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.indigo[100] : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mood['emoji']!,
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mood['label']!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          if (selectedMoodLabel != null) ...[
            Text(
              "You selected: $selectedMoodEmoji $selectedMoodLabel",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 2,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: "Sketch your thoughts.",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text("Date: "),
                TextButton(
                  onPressed: _pickDate,
                  child: Text("${selectedDate.toLocal()}".split(' ')[0]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saveMood,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Finish Piece"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



class MoodCalendarPage extends StatefulWidget {
  final List<Map<String, dynamic>> moodLog;

  const MoodCalendarPage({required this.moodLog});

  @override
  State<MoodCalendarPage> createState() => _MoodCalendarPageState();
}

class _MoodCalendarPageState extends State<MoodCalendarPage> {
  int selectedMonth = DateTime.now().month;
  final int currentYear = DateTime.now().year;
  String viewMode = 'Monthly';

  String _monthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return names[month];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Mood Masterpiece"),
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("View: "),
                DropdownButton<String>(
                  value: viewMode,
                  items: const [
                    DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      viewMode = value!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (viewMode == 'Monthly') _buildMonthlyView(),
            if (viewMode == 'Yearly') Expanded(child: _buildYearlyView()),
            const SizedBox(height: 20),
            const Text("Mood Legend:",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: moodColors.entries.map((e) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 16, height: 16, color: e.value),
                    const SizedBox(width: 6),
                    Text(e.key),
                  ],
                );
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyView() {
    final filteredLog = widget.moodLog.where((entry) {
      final date = DateTime.parse(entry['timestamp']);
      return date.month == selectedMonth && date.year == currentYear;
    }).toList();

    final dayColorMap = <int, Color>{};
    final dayNoteMap = <int, String>{};

    for (var entry in filteredLog) {
      final date = DateTime.parse(entry['timestamp']);
      final mood = entry['label'];
      if (moodColors.containsKey(mood)) {
        // Always overwrite to keep the most recent mood
        dayColorMap[date.day] = moodColors[mood]!;
        if (entry['note'] != null && entry['note'].toString().isNotEmpty) {
          dayNoteMap[date.day] = entry['note'];
        }
      }
    }


    final int daysInMonth = DateTime(currentYear, selectedMonth + 1, 0).day;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Select Month: "),
            DropdownButton<int>(
              value: selectedMonth,
              items: List.generate(12, (i) {
                final month = i + 1;
                return DropdownMenuItem(
                  value: month,
                  child: Text(_monthName(month)),
                );
              }),
              onChanged: (value) {
                setState(() {
                  selectedMonth = value!;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "${_monthName(selectedMonth)} $currentYear",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          itemCount: daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemBuilder: (context, index) {
            final day = index + 1;
            final color = dayColorMap[day] ?? Colors.grey[300];

            return GestureDetector(
              onLongPress: () {
                final note = dayNoteMap[day];
                if (note != null) {
                  _showNoteDialog(day: day, note: note);
                }
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  day.toString(),
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildYearlyView() {
    final dayMonthColorMap = <String, Color>{};
    final dayMonthNoteMap = <String, String>{};

    for (var entry in widget.moodLog) {
      final date = DateTime.parse(entry['timestamp']);
      final key = "${date.month}-${date.day}";
      final mood = entry['label'];
      if (moodColors.containsKey(mood)) {
        // Show most recent mood per day
        dayMonthColorMap[key] = moodColors[mood]!;
        if (entry['note'] != null && entry['note'].toString().isNotEmpty) {
          dayMonthNoteMap[key] = entry['note'];
        }
      }
    }

    final monthInitials = [
      'J',
      'F',
      'M',
      'A',
      'M',
      'J',
      'J',
      'A',
      'S',
      'O',
      'N',
      'D'
    ];


    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month labels on top
          Row(
            children: [
              const SizedBox(width: 30), // space for day numbers
              ...monthInitials.map((month) => SizedBox(
                    width: 18,
                    height: 18,
                    child: Center(
                      child: Text(
                        month,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )),
            ],
          ),

          // Mood grid with day labels on left
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(31, (dayIndex) {
                  final day = dayIndex + 1;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 30,
                        alignment: Alignment.centerRight,
                        margin: const EdgeInsets.only(right: 4),
                        child: Text(day.toString(),
                            style: const TextStyle(fontSize: 12)),
                      ),
                      ...List.generate(12, (monthIndex) {
                        final month = monthIndex + 1;
                        final key = "$month-$day";
                        final color = dayMonthColorMap[key] ?? Colors.grey[200];
                        final note = dayMonthNoteMap[key];

                        return GestureDetector(
                          onLongPress: () {
                            if (note != null) {
                              _showNoteDialog(
                                  day: day, month: month, note: note);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showNoteDialog({required int day, int? month, required String note}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(month != null
            ? "Note for ${_monthName(month)} $day"
            : "Note for Day $day"),
        content: Text(note),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'question': 'What is VIBErance?',
        'answer':
            'VIBErance is a simple and private mood tracking app designed to help you reflect on your emotional well-being through daily mood logs, notes, and visual summaries.'
      },
      {
        'question': 'How does the mood tracking work?',
        'answer':
            'Simply tap the emoji that matches your mood, write a short note (optional), and save it. You can view your past moods in a monthly or yearly calendar heatmap.'
      },
      {
        'question': 'Can I track moods for previous days?',
        'answer':
            'Yes! If you missed a day, just select the mood, pick a past date using the calendar button, and save it as if you logged it that day.'
      },
      {
        'question': 'How is my data kept safe?',
        'answer':
            'Your emotional masterpiece is completely private and secure. All of your data is stored securely on your device, and you have the option to protect your gallery.'
      },
      {
        'question': 'Can I export my mood data?',
        'answer':
            'Not yet, but this feature is on our roadmap! Stay tuned for future updates.'
      },
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Guidebook"),
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Illustration
            Center(
              child: Image.asset(
                'assets/images/mood-changes.png',
                height: 120,
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "What is VIBErance?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "VIBErance is your personal canvas and mood companion. This app helps you reflect your feelings as colors, add details as brushstrokes, and view your entire emotional journey as a beautiful gallery of masterpieces.",
              style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[300] : Colors.black87),
            ),
            const SizedBox(height: 30),
            const Text(
              "Frequently Asked Questions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...faqs.map((faq) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black54
                          : Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ExpansionTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(
                    faq['question']!,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        faq['answer']!,
                        style: const TextStyle(fontSize: 15),
                      ),
                    )
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
