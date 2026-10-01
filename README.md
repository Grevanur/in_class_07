# In-Class Activity 07 — Digital Pet

Flutter pet-care app for the Mobile Application Development two-team lab. This repository currently contains the Team 1 Care Systems workstream on `team-1/care-systems`.

## Run, test, and build

```bash
flutter pub get
flutter run
flutter analyze
flutter test
flutter build apk --release
```

The release APK is generated at `build/app/outputs/flutter-apk/app-release.apk`. Rename the final merged APK to `DigitalPet_TeamName.apk` before each student uploads it.

## Team roles and ownership

| Workstream | Owner | Evidence |
| --- | --- | --- |
| Team 1 — Care Systems | Gowtham Revanur | `lib/pet_game.dart`, timer ownership in `lib/main.dart`, and `test/` |
| Team 2 — Pet Personality | Add team member(s) after integration | PR, review, and implementation link |

> Add the shared GitHub issue and pull-request links here after the team repository is created. Do not invent evidence.

## Implemented care rules

| Event | State change |
| --- | --- |
| Feed | Hunger −10; happiness +10 unless resulting hunger is below 30, then happiness −20 |
| Play | Happiness +15, hunger +5, energy −15 |
| Rest | Energy +25, hunger +10, happiness +5 |
| Hunger tick | Every 30 seconds hunger +5. A tick from 95 to 100 has no penalty; a later tick at 100 reduces happiness by 20. |
| Win | Happiness must remain strictly above 80 continuously for three minutes. |
| Loss | Hunger is 100 and happiness is 10 or lower. Care controls lock until Reset. |
| Pause/Resume | Pausing cancels both timers; resuming starts exactly one hunger timer and restarts win eligibility safely. |
| Reset | Restores happiness 50, hunger 50, energy 70, clears outcome state, cancels old timers, and starts one hunger timer. |

All meters are clamped to 0–100. The visible mood label is not color-only: 0–29 is Unhappy/red, 30–70 is Neutral/yellow, and 71–100 is Happy/green. The grayscale `assets/pet.png` is tinted with `ColorFiltered` using `BlendMode.modulate`.

## Asset attribution

`assets/pet.png` is an original project asset generated for this assignment with OpenAI image generation. It has no downloaded third-party source or attribution requirement. Material icons are provided by the Flutter framework.

## Architecture and trade-off

`PetGame` owns meter transitions, boundary rules, and terminal outcomes. `PetScreen` owns Flutter-specific resources: the name controller and hunger/win timers. This keeps rules unit-testable without a widget tree, while timers stay tied to `initState`/`dispose`. The trade-off is a small amount of coordination after each UI state update so timer state reflects the rule state.

## Test evidence

Automated tests cover feed/play boundaries, hunger overflow, loss locking, strict win eligibility, reset behavior, and a short-duration widget win-timer check. Run `flutter test` before every commit and after Team 2 merges.

Manual checks still required before submission:

1. Capture mood behavior at happiness 29, 30, 70, and 71.
2. Confirm a three-minute production win and that dropping to 80 cancels it.
3. Install and launch the merged release APK on the intended device.
4. Add final screenshots, asset attribution, issue/PR links, and both teams' review evidence.

## Feature-to-outcome map

| Feature | Learning outcome | Evidence |
| --- | --- | --- |
| Bounded care actions | `setState` updates local mutable state and meter values remain valid | `pet_game_test.dart` |
| Hunger and win timers | Lifecycle-owned periodic/one-shot work is started and canceled safely | `main.dart`, `pet_screen_test.dart` |
| Energy plus Play/Rest selection | Multiple related values transition predictably from a selected activity | UI controls and `PetGame` |
| Pause/Resume session control | Timer resources stop and restart without duplicate active hunger timers | `main.dart` |
