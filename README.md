# Cloud Quest

## Project Overview

Cloud Quest is a Flutter mobile application integrated with Firebase. It provides a daily learning challenge, tracks individual learner progress, awards points and badges through a secure Cloud Function, and includes an AI Quest Coach interface.

## Features

- Firebase Authentication using email and password.
- Daily challenge retrieved from Cloud Firestore.
- Individual learner progress stored under their authenticated user ID.
- Secure quest completion using a Firebase Callable Cloud Function.
- 10 points awarded for the first successful completion.
- `first-quest` badge awarded once.
- Duplicate completion protection using a Firestore transaction.
- Quest Coach interface for asking questions about the daily challenge.

## Technologies Used

- Flutter and Dart
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Functions
- Firebase Emulator Suite
- Node.js
- Genkit

## Project Structure

```text
cloud_quest/
├── lib/
│   ├── main.dart
│   ├── screens/
│   └── services/
├── functions/
│   ├── index.js
│   ├── questCoach.js
│   └── package.json
├── test/
│   └── widget_test.dart
├── firestore.rules
├── firebase.json
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

## Firebase Configuration

The application uses the Firebase project configured in `lib/firebase_options.dart`.

Firebase services used:

- Authentication
- Cloud Firestore
- Cloud Functions

The local Firebase Emulator Suite uses these ports:

| Service | Port |
|---|---:|
| Authentication | 9099 |
| Firestore | 8080 |
| Functions | 5001 |
| Emulator UI | 4000 |

## Database Structure

### Daily Challenge

```text
challenges/
    today
```

### Individual Learner Progress

```text
users/
    {uid}/
        progress/
            today
```

Each learner's progress is associated with their authenticated Firebase user ID.

## Security Implementation

### Firestore Security Rules

- Signed-in users can read challenge documents.
- Users can read only their own progress.
- Client-side writes to progress documents are denied.
- Challenge writes are denied to clients.

### Cloud Function: completeToday

The `completeToday` callable function:

1. Verifies Firebase authentication.
2. Gets the learner UID from the verified authentication context.
3. Reads the daily challenge and learner progress.
4. Uses a Firestore transaction.
5. Awards 10 points and the `first-quest` badge only once.
6. Prevents duplicate rewards on repeated requests.

### Quest Coach

The `askQuestCoach` callable endpoint:

- Requires an authenticated user.
- Validates that the question contains 1–300 characters.
- Does not accept a user ID from the client.
- Uses a server-side read tool intended to access the daily challenge and the authenticated learner's progress.
- Does not provide reward-writing functionality.

**Current limitation:** The Quest Coach is currently implemented with a local test-mode response rather than a configured AI model. Its callable request is currently returning an error during Android testing. Full coach functionality and adversarial testing remain to be verified.

## Running the Project

### Flutter Dependencies

```bash
flutter pub get
```

### Cloud Functions Dependencies

```bash
cd functions
npm install
cd ..
```

### Start Firebase Emulators

```bash
firebase emulators:start
```

Keep the emulator terminal running.

### Run the Flutter Application

```bash
flutter run
```

The current development configuration uses Firebase emulators on the Android device.

### Run Flutter Tests

```bash
flutter test
```

### Analyze Flutter Code

```bash
flutter analyze
```

## Testing Status

| Test | Status |
|---|---|
| Flutter login screen widget test | Passed |
| Firebase Authentication | Tested |
| Daily challenge and progress display | Tested |
| First quest reward of 10 points | Tested |
| Duplicate reward prevention | Tested |
| Quest Coach normal response | Tested |
| Quest Coach adversarial response | Not verified |
| Automated graduate-level emulator security test | Not yet implemented |

## Limitations and Future Improvements

- Complete and verify the Genkit AI Quest Coach integration.
- Test prompt-injection resistance and read-only access.
- Add automated Firebase Emulator tests for security boundaries and reward idempotency.
- Improve error handling and user feedback.

## Platform

Developed and tested using Flutter on a physical Android device with Firebase Emulator Suite.

## Reflection

I developed Cloud Quest using Flutter and Firebase. The application supports email and password authentication, displays a daily challenge, and stores learner progress in Firestore. I implemented a callable Cloud Function to award 10 points and the first-quest badge. I tested duplicate completion and confirmed that completing the same challenge again does not award additional points. I also configured Firestore security rules to prevent clients from directly modifying progress data. The Quest Coach integration remains incomplete because the callable function currently returns an error during testing. One important safety check was verifying that rewards are handled on the server rather than trusted from the client. As a next step, I would complete and test the AI Coach integration and add automated emulator security tests.