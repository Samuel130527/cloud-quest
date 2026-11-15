
const admin = require("firebase-admin");
const {FieldValue} = require("firebase-admin/firestore");

const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {setGlobalOptions} = require("firebase-functions");

admin.initializeApp();

const db = admin.firestore();

setGlobalOptions({
  maxInstances: 10,
});

// Complete today's quest and award the reward exactly once.
exports.completeToday = onCall(async (request) => {

  // 1. Verify authentication.
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Please sign in before completing the quest."
    );
  }

  // 2. Get UID from verified Firebase authentication.
  const uid = request.auth.uid;

  // 3. Define Firestore document references.
  const challengeRef = db
    .collection("challenges")
    .doc("today");

  const progressRef = db
    .collection("users")
    .doc(uid)
    .collection("progress")
    .doc("today");

  // 4. Use a transaction to prevent duplicate rewards.
  return await db.runTransaction(async (transaction) => {

    // Read both documents before making writes.
    const challengeSnapshot =
      await transaction.get(challengeRef);

    const progressSnapshot =
      await transaction.get(progressRef);

    if (!challengeSnapshot.exists) {
      throw new HttpsError(
        "not-found",
        "Today's challenge does not exist."
      );
    }

    const existingProgress = progressSnapshot.exists
      ? progressSnapshot.data()
      : {};

    // 5. If already completed, do not award again.
    if (existingProgress.completed === true) {
      return {
        success: true,
        alreadyCompleted: true,
        pointsAwarded: 0,
        totalPoints: existingProgress.points || 0,
        message: "Quest was already completed.",
      };
    }

    // 6. Calculate the reward.
    const currentPoints = existingProgress.points || 0;

    const existingBadges = Array.isArray(
      existingProgress.badges
    )
      ? existingProgress.badges
      : [];

    const updatedBadges = [
      ...new Set([...existingBadges, "first-quest"]),
    ];

    const updatedPoints = currentPoints + 10;

    // 7. Save progress securely using Admin SDK.
    transaction.set(progressRef, {
      points: updatedPoints,
      badges: updatedBadges,
      completed: true,
      challengeId: "today",
      completedAt: FieldValue.serverTimestamp(),
    });

    // 8. Return the result.
    return {
      success: true,
      alreadyCompleted: false,
      pointsAwarded: 10,
      totalPoints: updatedPoints,
      badgeAwarded: "first-quest",
      message: "Congratulations! You completed today's quest.",
    };
  });
});
// Export the authenticated Quest Coach callable.
const {askQuestCoach} = require("./questCoach");
exports.askQuestCoach = askQuestCoach;