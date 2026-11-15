import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/quest_service.dart';
import '../services/completion_service.dart';

class QuestScreen extends StatefulWidget {
  final String email;

  const QuestScreen({super.key, required this.email});

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> {
  final QuestService _questService = QuestService();
  final CompletionService _completionService = CompletionService();
  final AuthService _authService = AuthService();

  final TextEditingController _coachController = TextEditingController();

  bool _isCompleting = false;
  bool _isAskingCoach = false;

  String _coachReply = '';

  // Complete today's quest securely through Cloud Function.
  Future<void> _completeQuest() async {
    if (_isCompleting) return;

    setState(() {
      _isCompleting = true;
    });

    try {
      final result = await _completionService.completeToday();

      if (!mounted) return;

      final alreadyCompleted = result['alreadyCompleted'] == true;

      final pointsAwarded = result['pointsAwarded'] ?? 0;

      final totalPoints = result['totalPoints'] ?? 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            alreadyCompleted
                ? 'Quest already completed! No extra points awarded. Total: $totalPoints'
                : 'Congratulations! You earned $pointsAwarded points. Total: $totalPoints',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Could not complete the quest.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  // Ask the authenticated Quest Coach.
  Future<void> _askCoach() async {
    final question = _coachController.text.trim();

    if (question.isEmpty || question.length > 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a question between 1 and 300 characters.'),
        ),
      );
      return;
    }

    if (_isAskingCoach) return;

    setState(() {
      _isAskingCoach = true;
      _coachReply = '';
    });

    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'askQuestCoach',
      );

      final result = await callable.call({'question': question});

      if (!mounted) return;

      final data = Map<String, dynamic>.from(result.data);

      setState(() {
        _coachReply =
            data['reply']?.toString() ?? 'The coach did not return a response.';
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      setState(() {
        _coachReply = 'Coach error: ${e.message ?? e.code}';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _coachReply = 'Something went wrong: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAskingCoach = false;
        });
      }
    }
  }

  // Sign out the current user.
  Future<void> _signOut() async {
    await _authService.signOut();
  }

  @override
  void dispose() {
    _coachController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in again.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Quest'),
        actions: [
          IconButton(
            onPressed: _signOut,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _questService.watchTodayChallenge(),
        builder: (context, challengeSnapshot) {
          if (challengeSnapshot.hasError) {
            return Center(
              child: Text(
                'Could not load challenge: ${challengeSnapshot.error}',
              ),
            );
          }

          if (challengeSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!challengeSnapshot.hasData || !challengeSnapshot.data!.exists) {
            return const Center(
              child: Text('No challenge is available today.'),
            );
          }

          final challenge = challengeSnapshot.data!.data()!;

          final title = challenge['title'] ?? 'Today\'s Quest';

          final prompt = challenge['prompt'] ?? 'No prompt available.';

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _questService.watchTodayProgress(user.uid),
            builder: (context, progressSnapshot) {
              if (progressSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Could not load your progress: ${progressSnapshot.error}',
                  ),
                );
              }

              if (progressSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final progress = progressSnapshot.data?.data() ?? {};

              final points = progress['points'] ?? 0;

              final completed = progress['completed'] == true;

              final badges =
                  (progress['badges'] as List<dynamic>?)?.cast<String>() ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),

                    const Icon(Icons.cloud, size: 64, color: Colors.deepPurple),

                    const SizedBox(height: 12),

                    Text(
                      'Welcome, ${widget.email}!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    const SizedBox(height: 24),

                    // Today's challenge card.
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TODAY\'S CHALLENGE',
                              style: TextStyle(
                                color: Colors.deepPurple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              title.toString(),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),

                            const SizedBox(height: 12),

                            Text(
                              prompt.toString(),
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),

                            const SizedBox(height: 20),

                            const Row(
                              children: [
                                Icon(Icons.stars, color: Colors.orange),
                                SizedBox(width: 8),
                                Text(
                                  'Reward: 10 points',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Learner progress card.
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'My Progress',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                const Icon(
                                  Icons.stars,
                                  color: Colors.orange,
                                  size: 30,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '$points points',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Icon(
                                  completed
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: completed ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  completed
                                      ? 'Quest completed'
                                      : 'Quest not completed yet',
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            const Text(
                              'Badges',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 8),

                            if (badges.isEmpty)
                              const Text('No badges earned yet.')
                            else
                              Wrap(
                                spacing: 8,
                                children: badges.map((badge) {
                                  return Chip(
                                    avatar: const Icon(
                                      Icons.military_tech,
                                      size: 18,
                                    ),
                                    label: Text(badge),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // AI Quest Coach card.
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'AI Quest Coach',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),

                            const SizedBox(height: 8),

                            const Text(
                              'Ask for a hint about today\'s challenge.',
                            ),

                            const SizedBox(height: 12),

                            TextField(
                              controller: _coachController,
                              maxLength: 300,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Type your question here...',
                              ),
                            ),

                            const SizedBox(height: 8),

                            FilledButton.icon(
                              onPressed: _isAskingCoach ? null : _askCoach,
                              icon: _isAskingCoach
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.chat),
                              label: Text(
                                _isAskingCoach
                                    ? 'Asking Coach...'
                                    : 'Ask Coach',
                              ),
                            ),

                            if (_coachReply.isNotEmpty) ...[
                              const SizedBox(height: 16),

                              const Text(
                                'Coach Response',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),

                              const SizedBox(height: 8),

                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(_coachReply),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Complete quest button.
                    FilledButton.icon(
                      onPressed: _isCompleting ? null : _completeQuest,
                      icon: _isCompleting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle),
                      label: Text(
                        _isCompleting
                            ? 'Completing...'
                            : completed
                            ? 'Check Completion'
                            : 'Complete Quest',
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Your points and badges are awarded securely '
                      'by the Firebase Cloud Function.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
