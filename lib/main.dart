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
  bool _isPaused = false;
  String _feedback = 'Choose an action to care for Pip.';

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
        });
        _stopTimers();
      });
    } else {
      _winTimer?.cancel();
      _winTimer = null;
    }
  }

  void _careForPet(void Function() action, String feedback) {
    if (_isPaused || !_game.canCareForPet) return;
    setState(() {
      action();
      _feedback = feedback;
    });
    _syncTimersAndOutcome();
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
    setState(() {
      _game.reset();
      _isPaused = false;
      _feedback = '${_game.name} is ready for a fresh start.';
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
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canCare = _game.canCareForPet && !_isPaused;
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Pet Care')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveName(),
                    decoration: const InputDecoration(
                      labelText: 'Pet name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _saveName, child: const Text('Save')),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Semantics(
                label: '${_game.name}, ${_game.mood} mood',
                image: true,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(_moodColor, BlendMode.modulate),
                  child: Image.asset('assets/pet.png', height: 190),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _statusMessage,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            _Meter(
              label: 'Happiness',
              value: _game.happiness,
              color: Colors.pink,
            ),
            _Meter(label: 'Hunger', value: _game.hunger, color: Colors.orange),
            _Meter(label: 'Energy', value: _game.energy, color: Colors.blue),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(_feedback, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: canCare
                      ? () => _careForPet(
                          _game.feed,
                          '${_game.name} enjoyed the meal.',
                        )
                      : null,
                  icon: const Icon(Icons.restaurant),
                  label: const Text('Feed'),
                ),
                FilledButton.icon(
                  onPressed: canCare
                      ? () => _careForPet(
                          _game.play,
                          '${_game.name} had fun playing.',
                        )
                      : null,
                  icon: const Icon(Icons.sports_tennis),
                  label: const Text('Play'),
                ),
                FilledButton.icon(
                  onPressed: canCare
                      ? () => _careForPet(
                          _game.rest,
                          '${_game.name} feels rested.',
                        )
                      : null,
                  icon: const Icon(Icons.bedtime),
                  label: const Text('Rest'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
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
          ],
        ),
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        label: '$label: $value out of 100',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label: $value / 100'),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: value / 100, color: color),
          ],
        ),
      ),
    );
  }
}
