import 'package:flutter_test/flutter_test.dart';
import 'package:in_class_07/pet_game.dart';

void main() {
  test('feed clamps hunger at zero and applies the low-hunger rule', () {
    final game = PetGame(hunger: 5, happiness: 50);

    game.feed();

    expect(game.hunger, 0);
    expect(game.happiness, 30);
  });

  test('play clamps happiness and energy at the meter boundaries', () {
    final game = PetGame(happiness: 95, hunger: 95, energy: 5);

    game.play();

    expect(game.happiness, 100);
    expect(game.hunger, 100);
    expect(game.energy, 0);
  });

  test(
    'hunger overflow applies a penalty only after hunger is already 100',
    () {
      final game = PetGame(hunger: 95, happiness: 50);

      game.hungerTick();
      expect(game.hunger, 100);
      expect(game.happiness, 50);

      game.hungerTick();
      expect(game.hunger, 100);
      expect(game.happiness, 30);
    },
  );

  test('loss locks care actions at hunger 100 and happiness 10 or lower', () {
    final game = PetGame(hunger: 100, happiness: 10);

    expect(game.outcome, PetOutcome.gameOver);
    game.feed();
    expect(game.hunger, 100);
  });

  test('win eligibility is strictly above 80', () {
    expect(PetGame(happiness: 80).isWinEligible, isFalse);
    expect(PetGame(happiness: 81).isWinEligible, isTrue);
  });

  test('reset restores initial meters and a playable outcome', () {
    final game = PetGame(hunger: 100, happiness: 10, energy: 0);

    game.reset();

    expect(game.hunger, PetGame.initialHunger);
    expect(game.happiness, PetGame.initialHappiness);
    expect(game.energy, PetGame.initialEnergy);
    expect(game.outcome, PetOutcome.playing);
  });
}
