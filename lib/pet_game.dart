enum PetOutcome { playing, won, gameOver }

/// Owns the Digital Pet rules. Widgets render this state but do not duplicate
/// meter or outcome calculations.
class PetGame {
  PetGame({
    int happiness = 50,
    int hunger = 50,
    int energy = 70,
    this.name = 'Pip',
  }) : happiness = _clamp(happiness),
       hunger = _clamp(hunger),
       energy = _clamp(energy) {
    _checkLoss();
  }

  static const initialHappiness = 50;
  static const initialHunger = 50;
  static const initialEnergy = 70;

  int happiness;
  int hunger;
  int energy;
  String name;
  PetOutcome outcome = PetOutcome.playing;

  bool get canCareForPet => outcome == PetOutcome.playing;
  bool get isWinEligible => happiness > 80;

  String get mood {
    if (happiness > 70) return 'Happy';
    if (happiness >= 30) return 'Neutral';
    return 'Unhappy';
  }

  void feed() {
    if (!canCareForPet) return;
    hunger = _clamp(hunger - 10);
    happiness = _clamp(happiness + (hunger < 30 ? -20 : 10));
    _checkLoss();
  }

  void play() {
    if (!canCareForPet) return;
    happiness = _clamp(happiness + 15);
    hunger = _clamp(hunger + 5);
    energy = _clamp(energy - 15);
    _checkLoss();
  }

  void rest() {
    if (!canCareForPet) return;
    energy = _clamp(energy + 25);
    hunger = _clamp(hunger + 10);
    happiness = _clamp(happiness + 5);
    _checkLoss();
  }

  /// A tick from 95 to 100 has no penalty; the next tick at 100 does.
  void hungerTick() {
    if (!canCareForPet) return;
    if (hunger + 5 > 100) {
      hunger = 100;
      happiness = _clamp(happiness - 20);
    } else {
      hunger = _clamp(hunger + 5);
    }
    _checkLoss();
  }

  void win() {
    if (canCareForPet && isWinEligible) outcome = PetOutcome.won;
  }

  void reset() {
    happiness = initialHappiness;
    hunger = initialHunger;
    energy = initialEnergy;
    outcome = PetOutcome.playing;
  }

  void _checkLoss() {
    if (hunger == 100 && happiness <= 10) outcome = PetOutcome.gameOver;
  }

  static int _clamp(int value) => value.clamp(0, 100).toInt();
}
