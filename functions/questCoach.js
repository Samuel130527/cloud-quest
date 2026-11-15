
const {genkit, z} = require("genkit");
const admin = require("firebase-admin");
const {onCall, HttpsError} = require("firebase-functions/v2/https");

// Genkit instance for the Quest Coach.
const ai = genkit({
  plugins: [],
});

// The only tool available to the coach.
// UID is supplied by the authenticated server, never by the client.
const readMyQuestState = ai.defineTool(
  {
    name: "readMyQuestState",
    description:
      "Read today's challenge and the authenticated learner's own progress.",
    inputSchema: z.object({}),
    outputSchema: z.object({
      challenge: z.string(),
      completed: z.boolean(),
      points: z.number(),
      badges: z.array(z.string()),
    }),
  },
  async (_, context) => {
    const uid = context?.context?.uid;

    if (!uid) {
      throw new Error("Authenticated user context is missing.");
    }

    const db = admin.firestore();

    const challengeRef = db.collection("challenges").doc("today");
    const progressRef = db.collection("users")
      .doc(uid)
      .collection("progress")
      .doc("today");

    const [challengeSnap, progressSnap] = await Promise.all([
      challengeRef.get(),
      progressRef.get(),
    ]);

    const challengeData = challengeSnap.exists
      ? challengeSnap.data()
      : {};

    const progressData = progressSnap.exists
      ? progressSnap.data()
      : {};

    return {
      challenge: challengeData.prompt || challengeData.title ||
        "Today's challenge is not available yet.",
      completed: progressData.completed === true,
      points: Number(progressData.points || 0),
      badges: Array.isArray(progressData.badges)
        ? progressData.badges
        : [],
    };
  },
);

// Genkit flow: reads the learner's state before producing a response.
const questCoachFlow = ai.defineFlow(
  {
    name: "questCoachFlow",
    inputSchema: z.object({
      question: z.string(),
    }),
    outputSchema: z.string(),
  },
  async ({question}, context) => {
    const state = await readMyQuestState({}, {
      context: context?.context,
    });

    // Emulator-safe response while the course AI gateway is not configured.
    return [
      "Quest Coach (local test mode):",
      `Today's challenge: ${state.challenge}`,
      `Your progress: ${state.completed ? "Completed" : "Not completed"}.`,
      `Your points: ${state.points}.`,
      `Your badges: ${state.badges.join(", ") || "None yet"}.`,
      "",
      "Hint: Break the challenge into small steps and try the first step yourself.",
      "I cannot award or change points. Use the separate Complete Quest button.",
    ].join("\n");
  },
);

// Authenticated callable endpoint.
exports.askQuestCoach = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "Please sign in to use the Quest Coach.",
    );
  }

  const question = request.data?.question;

  if (
    typeof question !== "string" ||
    question.trim().length === 0 ||
    question.length > 300
  ) {
    throw new HttpsError(
      "invalid-argument",
      "Enter a question containing 1 to 300 characters.",
    );
  }

  try {
    const reply = await questCoachFlow.run(
      {question: question.trim()},
      {context: {uid: request.auth.uid}},
    );

    return {reply};
  } catch (error) {
    console.error("Quest Coach error:", error);
    throw new HttpsError(
      "internal",
      "The Quest Coach could not answer right now.",
    );
  }
});
