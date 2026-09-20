const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

// =========================================================
// GLOBAL SETTINGS
// =========================================================

setGlobalOptions({
region: "asia-northeast3",
maxInstances: 10,
});

// =========================================================
// HEALTH CHECK
// =========================================================

exports.healthCheck = onCall(async () => {
return {
success: true,
service: "BuyNova Cloud Functions",
status: "online",
timestamp: new Date().toISOString(),
};
});

// =========================================================
// WALLET TRANSACTION CREATED
// =========================================================
//
// This function watches new wallet transactions.
//
// IMPORTANT:
// Client-side Flutter code can only create a PENDING transaction.
// Actual balance changes will be handled by secure server-side
// functions in the next steps.
//

exports.onWalletTransactionCreated = onDocumentCreated(
"users/{userId}/walletTransactions/{transactionId}",
async (event) => {
const snapshot = event.data;

if (!snapshot) {
  return;
}

const data = snapshot.data();

console.log("BuyNova wallet transaction received:", {
  userId: event.params.userId,
  transactionId: event.params.transactionId,
  type: data.type || null,
  source: data.source || null,
  status: data.status || null,
  amount: data.amount || null,
});

// New transactions remain PENDING.
// Admin/server-side approval will process the balance later.
return;

},
);

// =========================================================
// SECURE WALLET BALANCE
// =========================================================
//
// This callable function only reads the authenticated user's
// wallet balance.
//
// It does NOT modify the balance.
//

exports.getWalletBalance = onCall(async (request) => {
if (!request.auth) {
throw new HttpsError(
"unauthenticated",
"You must be logged in to access your wallet.",
);
}

const userId = request.auth.uid;

const userRef = db.collection("users").doc(userId);
const userSnapshot = await userRef.get();

if (!userSnapshot.exists) {
throw new HttpsError(
"not-found",
"BuyNova user account was not found.",
);
}

const userData = userSnapshot.data() || {};

const cashBalance =
typeof userData.cashBalance === "number"
? userData.cashBalance
: 0;

const points =
typeof userData.points === "number"
? userData.points
: 0;

return {
success: true,
currency: "BDT",
currencySymbol: "৳",
cashBalance: cashBalance,
points: points,
};
});
