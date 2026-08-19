# Firebase Console Setup Guide for RR Fabrication

This guide walks you through the Firebase Console configuration needed to enable Google Sign-In and Firestore for your Flutter app.

---

## Step 1: Get Your Android SHA Fingerprints

### A. Generate SHA-1 Fingerprint (Required for Google Sign-In)

1. Open a PowerShell terminal in your project root
2. Run this command:

```powershell
cd android
./gradlew signingReport
```

3. Copy the **SHA-1** value from the output (you'll see `SHA1: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`)

### B. Generate SHA-256 Fingerprint (Optional but Recommended)

The `gradlew signingReport` command above also outputs SHA-256. Copy that value as well.

---

## Step 2: Add SHA Fingerprints to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **rr-fabrication-456eb**
3. In the left sidebar, go to **Project Settings** (gear icon)
4. Click the **Apps** tab
5. Find your Android app: **com.example.rr_fabrication**
6. In the **SHA certificate fingerprints** section, click **Add fingerprint**
7. Paste the SHA-1 fingerprint you copied from `gradlew signingReport`
8. Click **Save**
9. (Optional) Add SHA-256 fingerprint as well using the same process

---

## Step 3: Enable Google Sign-In Method

1. In Firebase Console, go to **Authentication** (left sidebar)
2. Click the **Sign-in method** tab
3. If **Google** is not already enabled:
   - Click on **Google**
   - Toggle **Enable** to ON
   - Enter a support email (your email is fine)
   - Click **Save**
4. If Google is already enabled, you're good to go

---

## Step 4: Configure Firestore Database

### A. Create Firestore Database (if not already created)

1. Go to **Firestore Database** (left sidebar)
2. Click **Create database**
3. Choose **Start in test mode** (for development)
4. Select region: **nam5 (us-central)** or your preferred region
5. Click **Create**

### B. Set Firestore Security Rules

1. In Firestore, click the **Rules** tab
2. Replace all content with these rules:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to create and read their own user document
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow create: if request.auth.uid == userId;
      allow update: if request.auth.uid == userId;
      allow delete: if request.auth.uid == userId;
    }
  }
}
```

3. Click **Publish**

---

## Step 5: Verify Android App Configuration

1. Make sure your `android/app/google-services.json` file contains:
   - `project_id: "rr-fabrication-456eb"`
   - `package_name: "com.example.rr_fabrication"`
   - Correct API keys and client IDs

2. If the file is missing or outdated:
   - Go to **Project Settings** → **Apps** → **com.example.rr_fabrication**
   - Click **Download google-services.json**
   - Replace the existing file at `android/app/google-services.json`

---

## Step 6: Test the App

1. Connect an Android device or start an emulator
2. In your project root, run:

```bash
flutter clean
flutter pub get
flutter run
```

3. Test the login flow:
   - Click **Continue with Google**
   - Sign in with your Google account
   - You should be taken to the **Basic Details** screen
   - Fill in your name and phone number
   - Click **Save Details**
   - You should be routed to the **Home** screen
   - Check Firebase Console → Firestore → `users` collection to confirm your user document was created with role: `CUSTOMER`

4. Test returning user:
   - Sign out (use the Home menu)
   - Click **Continue with Google** again with the same account
   - You should skip the details form and go directly to **Home**

---

## Troubleshooting

### "Google Sign-In failed" on Android

**Cause**: SHA fingerprints not registered in Firebase Console

**Solution**: 
- Run `./gradlew signingReport` again
- Verify you added the SHA-1 to Firebase Console
- Wait 5 minutes for changes to propagate
- Rebuild and reinstall the app: `flutter clean && flutter run`

### "Firebase is not configured" error

**Cause**: `google-services.json` is missing or invalid

**Solution**:
- Download fresh `google-services.json` from Firebase Console
- Place it at `android/app/google-services.json`
- Run `flutter clean && flutter pub get`

### User document not appearing in Firestore

**Cause**: Firestore rules blocking write access

**Solution**:
- Check Firestore rules (follow Step 4B above)
- Make sure rules are **Published** (not just saved as draft)
- Check the phone number is being saved (it's optional, so it might be empty but should still save)

### "Cannot access Firestore" after login

**Cause**: Security rules too restrictive or user not authenticated

**Solution**:
- Verify user is authenticated (check Firebase Console → Authentication → Users)
- Check Firestore rules allow the operation
- See Step 4B for correct rules

---

## What Happens Next

Once you've completed these steps:

1. ✅ Android app can authenticate with Google
2. ✅ New users are directed to fill in basic details
3. ✅ User records are saved to Firestore with role "CUSTOMER"
4. ✅ Returning users go directly to Home
5. ✅ All user data is secure and only accessible by that user

The app is then ready for additional features like worker management, attendance tracking, etc.

---

## Additional Firebase Features (Future)

If you want to add more features later:

- **Cloud Storage**: For profile photos, work documents
- **Cloud Functions**: For automated tasks (notifications, data validation)
- **Realtime Database**: For live attendance updates
- **Analytics**: Track user behavior and adoption

Let me know if you hit any issues during setup!
