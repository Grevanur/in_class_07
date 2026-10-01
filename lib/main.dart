import 'dart:async';

import 'package:flutter/material.dart';

import 'pet_game.dart';

void main() => runApp(const DigitalPetApp());

class DigitalPetApp extends StatelessWidget {
  const DigitalPetApp({
    super.key,
    this.hungerInterval = const Duration(seconds: 30),
    this.winDuration = const Duration(minutes: 3),
  });

  final Duration hungerInterval;
  final Duration winDuration;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Pet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: PetScreen(hungerInterval: hungerInterval, winDuration: winDuration),
    );
  }
}

class PetScreen extends StatefulWidget {
  const PetScreen({
    super.key,
    required this.hungerInterval,
    required this.winDuration,
  });

  final Duration hungerInterval;
  final Duration winDuration;

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  final _nameController = TextEditingController(text: 'Pip');
  final PetGame _game = PetGame();

  Timer? _hungerTimer;
  Timer? _winTimer;
  Timer? _reactionTimer;

  bool _isPaused = false;
  bool _petBouncing = false;

  String _feedback = 'Choose an activity to care for Pip.';
  String _reaction = '';

  String _selectedActivity = 'Play';

  @override
  void initState() {
    super.initState();
    _startHungerTimer();
  }

  void _startHungerTimer() {
    _hungerTimer?.cancel();

    _hungerTimer = Timer.periodic(widget.hungerInterval, (_) {
      if (!mounted || _isPaused || !_game.canCareForPet) return;

      setState(() {
        _game.hungerTick();
        _feedback = '${_game.name} is getting hungry.';
      });

      _syncTimersAndOutcome();
    });
  }

  void _stopTimers() {
    _hungerTimer?.cancel();
    _hungerTimer = null;

    _winTimer?.cancel();
    _winTimer = null;
  }

  void _syncTimersAndOutcome() {
    if (!_game.canCareForPet) {
      _stopTimers();
      return;
    }

    if (_game.isWinEligible && !_isPaused) {
      _winTimer ??= Timer(widget.winDuration, () {
        _winTimer = null;

        if (!mounted || _isPaused || !_game.isWinEligible) return;

        setState(() {
          _game.win();
          _feedback = 'You kept ${_game.name} happy for three minutes!';
          _reaction = '🏆';
        });

        _stopTimers();
      });
    } else {
      _winTimer?.cancel();
      _winTimer = null;
    }
  }

  void _performActivity() {
    if (_isPaused || !_game.canCareForPet) return;

    switch (_selectedActivity) {
      case 'Feed':
        _careForPet(_game.feed, '${_game.name} enjoyed the meal! 🍖', '🍖');
        break;

      case 'Play':
        _careForPet(_game.play, '${_game.name} had fun playing! 🎾', '🎾');
        break;

      case 'Rest':
        _careForPet(_game.rest, '${_game.name} feels rested! 💤', '💤');
        break;
    }
  }

  void _careForPet(void Function() action, String feedback, String reaction) {
    if (_isPaused || !_game.canCareForPet) return;

    setState(() {
      action();
      _feedback = feedback;
    });

    _showReaction(reaction);
    _syncTimersAndOutcome();
  }

  void _showReaction(String reaction) {
    _reactionTimer?.cancel();

    setState(() {
      _reaction = reaction;
      _petBouncing = true;
    });

    _reactionTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;

      setState(() {
        _reaction = '';
        _petBouncing = false;
      });
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      _feedback = _isPaused ? 'Care session paused.' : 'Care session resumed.';
    });

    if (_isPaused) {
      _stopTimers();
    } else {
      _startHungerTimer();
      _syncTimersAndOutcome();
    }
  }

  void _reset() {
    _stopTimers();
    _reactionTimer?.cancel();

    setState(() {
      _game.reset();
      _isPaused = false;
      _selectedActivity = 'Play';
      _feedback = '${_game.name} is ready for a fresh start.';
      _reaction = '';
      _petBouncing = false;
    });

    _startHungerTimer();
  }

  void _saveName() {
    final candidate = _nameController.text.trim();

    if (candidate.isEmpty) return;

    setState(() {
      _game.name = candidate;
      _feedback = 'Welcome, ${_game.name}!';
    });
  }

  Color get _moodColor {
    if (_game.happiness > 70) return Colors.green;
    if (_game.happiness >= 30) return Colors.amber;
    return Colors.red;
  }

  double get _moodScale {
    if (_game.happiness > 70) return 1.06;
    if (_game.happiness < 30) return 0.94;
    return 1.0;
  }

  String get _petMessage {
    if (_game.outcome == PetOutcome.gameOver) {
      return 'I need a fresh start.';
    }

    if (_game.outcome == PetOutcome.won) {
      return 'Best day ever! 🎉';
    }

    if (_isPaused) {
      return 'I am waiting for you.';
    }

    if (_game.hunger > 80) {
      return 'I am getting hungry!';
    }

    if (_game.energy < 20) {
      return 'So sleepy... I need some rest.';
    }

    if (_game.happiness <= 30) {
      return 'Play with me?';
    }

    if (_game.happiness > 70) {
      return 'I feel great today!';
    }

    return "Hi, I'm ${_game.name}!";
  }

  String get _statusMessage {
    if (_game.outcome == PetOutcome.won) {
      return 'You won! ${_game.name} is thriving.';
    }

    if (_game.outcome == PetOutcome.gameOver) {
      return 'Game over. ${_game.name} needs a restart.';
    }

    if (_isPaused) {
      return 'Session paused';
    }

    return '${_game.mood} mood';
  }

  @override
  void dispose() {
    _stopTimers();
    _reactionTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canCare = _game.canCareForPet && !_isPaused;

    // Accessibility: respect the device's reduced-motion preference.
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final petScale = _moodScale * (_petBouncing && !reduceMotion ? 1.08 : 1.0);

    final animationDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 250);

    return Scaffold(
      appBar: AppBar(title: const Text('Digital Pet Care'), centerTitle: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // PET NAME
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveName(),
                    decoration: const InputDecoration(
                      labelText: 'Pet name',
                      prefixIcon: Icon(Icons.pets),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _saveName, child: const Text('Save')),
              ],
            ),

            const SizedBox(height: 20),

            // PET DISPLAY
            Semantics(
              label: '${_game.name}, ${_game.mood} mood. $_petMessage',
              image: true,
              child: Column(
                children: [
                  AnimatedScale(
                    scale: petScale,
                    duration: animationDuration,
                    curve: Curves.easeOutBack,
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _moodColor.withValues(alpha: 0.12),
                            border: Border.all(color: _moodColor, width: 3),
                          ),
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              _moodColor,
                              BlendMode.modulate,
                            ),
                            child: Image.asset('assets/pet.png', height: 170),
                          ),
                        ),

                        // ACTION REACTION
                        if (_reaction.isNotEmpty)
                          AnimatedSlide(
                            offset: reduceMotion
                                ? Offset.zero
                                : const Offset(0.0, -0.25),
                            duration: animationDuration,
                            child: AnimatedOpacity(
                              opacity: _reaction.isEmpty ? 0 : 1,
                              duration: animationDuration,
                              child: Text(
                                _reaction,
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // DERIVED PET MESSAGE
                  AnimatedSwitcher(
                    duration: reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    child: Text(
                      _petMessage,
                      key: ValueKey(_petMessage),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _statusMessage,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // METERS
            _Meter(
              label: 'Happiness',
              value: _game.happiness,
              color: Colors.pink,
              reduceMotion: reduceMotion,
            ),

            _Meter(
              label: 'Hunger',
              value: _game.hunger,
              color: Colors.orange,
              reduceMotion: reduceMotion,
            ),

            _Meter(
              label: 'Energy',
              value: _game.energy,
              color: Colors.blue,
              reduceMotion: reduceMotion,
            ),

            const SizedBox(height: 8),

            // ACCESSIBLE FEEDBACK
            Semantics(
              liveRegion: true,
              label: _feedback,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(_feedback, textAlign: TextAlign.center),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ACTIVITY SELECTION
            Text(
              'Choose an Activity',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('🍖 Feed'),
                  selected: _selectedActivity == 'Feed',
                  onSelected: canCare
                      ? (_) {
                          setState(() {
                            _selectedActivity = 'Feed';
                          });
                        }
                      : null,
                ),
                ChoiceChip(
                  label: const Text('🎾 Play'),
                  selected: _selectedActivity == 'Play',
                  onSelected: canCare
                      ? (_) {
                          setState(() {
                            _selectedActivity = 'Play';
                          });
                        }
                      : null,
                ),
                ChoiceChip(
                  label: const Text('💤 Rest'),
                  selected: _selectedActivity == 'Rest',
                  onSelected: canCare
                      ? (_) {
                          setState(() {
                            _selectedActivity = 'Rest';
                          });
                        }
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: canCare ? _performActivity : null,
                icon: const Icon(Icons.touch_app),
                label: Text('Do $_selectedActivity'),
              ),
            ),

            const SizedBox(height: 12),

            // SESSION CONTROLS
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _game.canCareForPet ? _togglePause : null,
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                  label: Text(_isPaused ? 'Resume' : 'Pause'),
                ),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ACCESSIBILITY NOTE
            Semantics(
              label: 'Mood is shown using text, icon feedback, and color.',
              child: Text(
                'Mood: ${_game.mood} • '
                'Color and text both communicate pet mood.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({
    required this.label,
    required this.value,
    required this.color,
    required this.reduceMotion,
  });

  final String label;
  final int value;
  final Color color;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        label: '$label: $value out of 100',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label: $value / 100',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value / 100),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, animatedValue, _) {
                return LinearProgressIndicator(
                  value: animatedValue,
                  color: color,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(8),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
