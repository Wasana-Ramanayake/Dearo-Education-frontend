import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'quiz_marks.dart';
import '../config/api.dart'; // <-- Import your Api class

class QuizPage extends StatefulWidget {
  final String subjectName;
  final int quizId;
  final int memberId;

  const QuizPage({
    super.key,
    required this.subjectName,
    required this.quizId,
    required this.memberId,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Map<String, dynamic>> _questions = [];
  final Map<int, int?> _selectedAnswers = {};
  bool _isSubmitted = false;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    try {
      final response = await http.get(
        Uri.parse('${Api.quizQuestions}?q_id=${widget.quizId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final formattedQuestions = data.map<Map<String, dynamic>>((q) {
          final answers = q['answers'] ?? [];
          return {
            'id': q['id'],
            'question': q['question'],
            'answer_id': q['answer_id'],
            'answers': answers
                .map((a) => {
                      'id': a['id'],
                      'text': a['answer'],
                    })
                .toList(),
          };
        }).toList();

        setState(() {
          _questions = formattedQuestions;
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitQuiz() async {
    if (_questions.isEmpty) return;
    setState(() => _isSubmitted = true);

    int score = 0;

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final selectedIndex = _selectedAnswers[i];
      final correctId = q['answer_id'];

      final selectedAnswerId =
          selectedIndex != null ? q['answers'][selectedIndex]['id'] : 0;

      final isCorrect = selectedAnswerId == correctId;
      if (isCorrect) score++;

      try {
        final response = await http.post(
          Uri.parse(Api.quizMarks),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'm_id': widget.memberId,
            'c_q_id': widget.quizId,
            'c_q_question_id': q['id'],
            'c_q_q_answers_id': selectedAnswerId,
            'marks': isCorrect ? 1 : 0,
          }),
        );

        if (response.statusCode != 201) {
          debugPrint('❌ Failed to store mark for Q${q['id']}: ${response.body}');
        }
      } catch (e) {
        debugPrint('⚠️ Error submitting mark for Q${q['id']}: $e');
      }
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Quiz Completed!'),
        content: Text(
            'Subject: ${widget.subjectName}\nYour Score: $score / ${_questions.length}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizMarksPage(memberId: widget.memberId),
                ),
              );
            },
            icon: const Icon(Icons.bar_chart),
            label: const Text("View Progress"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo.shade900,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = MediaQuery.of(context).size.width < 400 ? 14.0 : 16.0;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_hasError) {
      return const Scaffold(
        body: Center(child: Text("❌ Failed to load questions")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subjectName} Quiz'),
        backgroundColor: Colors.indigo.shade900,
        iconTheme: const IconThemeData(
          color: Colors.white, // <-- Back arrow color
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white, // <-- Title color
          fontSize: 20,
          fontWeight: FontWeight.normal,
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _questions.length,
        itemBuilder: (context, index) {
          final q = _questions[index];
          final answers = q['answers'];
          final selectedIdx = _selectedAnswers[index];
          final correctId = q['answer_id'];

          return Card(
            margin: const EdgeInsets.only(bottom: 20),
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${index + 1}. ${q['question']}',
                      style: TextStyle(
                          fontSize: fontSize + 1,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...answers.asMap().entries.map((entry) {
                    final optionIdx = entry.key;
                    final answer = entry.value;
                    final isSelected = selectedIdx == optionIdx;
                    final isCorrectAnswer = answer['id'] == correctId;

                    return ListTile(
                      dense: true,
                      tileColor: _isSubmitted && isCorrectAnswer
                          ? Colors.green.shade600
                          : null,
                      leading: _isSubmitted
                          ? Icon(
                              isCorrectAnswer
                                  ? Icons.check_circle
                                  : (isSelected
                                      ? Icons.cancel
                                      : Icons.radio_button_unchecked),
                              color: isCorrectAnswer
                                  ? Colors.white
                                  : (isSelected ? Colors.red : Colors.grey),
                            )
                          : Radio<int>(
                              value: optionIdx,
                              groupValue: selectedIdx,
                              activeColor: Colors.indigo.shade900,
                              onChanged: (value) {
                                if (!_isSubmitted) {
                                  setState(() => _selectedAnswers[index] = value);
                                }
                              },
                            ),
                      title: Text(
                        answer['text'],
                        style: TextStyle(
                          fontSize: fontSize,
                          color: _isSubmitted
                              ? (isCorrectAnswer
                                  ? Colors.white
                                  : (isSelected ? Colors.red : null))
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                  if (_isSubmitted && !_selectedAnswers.containsKey(index))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '⚠️ You didn\'t answer this question!',
                        style: TextStyle(
                          fontSize: fontSize - 1,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: !_isSubmitted
          ? FloatingActionButton.extended(
              onPressed: _submitQuiz,
              label: const Text('Submit', style: TextStyle(color: Colors.white)),
              icon: const Icon(Icons.check, color: Colors.white),
              backgroundColor: Colors.indigo.shade900,
            )
          : null,
    );
  }
}
