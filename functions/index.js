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
// HELPERS
// =========================================================

function requireAdmin(request) {
if (!request.auth) {
throw new HttpsError(
"unauthenticated",
"You must be logged in.",
);
}

const adminEmail = "miamdarif010@gmail.com";
const email = request.auth.token.email;

if (email !== adminEmail) {
throw new HttpsError(
"permission-denied",
"Admin permission is required.",
);
}
}

// =========================================================
// HEALTH CHECK
// =========================================================

exports.healthCheck = onCall(async () => {
return {
success: true,
service: "BuyNova Cloud Functions",
status: "online",
currency: "BDT",
currencySymbol: "৳",
timestamp: new Date().toISOString(),
};
});

// =========================================================
// WALLET TRANSACTION CREATED
// =========================================================
//
// New wallet transactions created by the Flutter app remain
// PENDING until an authorized admin processes them.
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

},
);

// =========================================================
// GET WALLET BALANCE
// =========================================================
//
// Securely reads the authenticated user's balance.
//

exports.getWalletBalance = onCall(async (request) => {
if (!request.auth) {
throw new HttpsError(
"unauthenticated",
"You must be logged in to access your wallet.",
);
}

const userId = request.auth.uid;

const userSnapshot = await db
.collection("users")
.doc(userId)
.get();

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
cashBalance,
points,
};
});

// =========================================================
// APPROVE WALLET TRANSACTION
// =========================================================
//
// ADMIN ONLY.
//
// Supports:
//
// 1. Deposit
//    pending credit/deposit
//    -> adds money to cashBalance
//
// 2. Withdrawal
//    pending debit/withdrawal
//    -> subtracts money from cashBalance
//
// All balance changes happen inside a Firestore transaction.
//

exports.approveWalletTransaction = onCall(async (request) => {
requireAdmin(request);

const transactionId = request.data?.transactionId;

if (
typeof transactionId !== "string" ||
transactionId.trim().isEmpty
) {
throw new HttpsError(
"invalid-argument",
"A valid transaction ID is required.",
);
}

const transactionRef = findWalletTransactionReference(
transactionId.trim(),
);

const result = await db.runTransaction(async (transaction) => {
const transactionSnapshot =
await transaction.get(transactionRef);

if (!transactionSnapshot.exists) {
  throw new HttpsError(
    "not-found",
    "Wallet transaction was not found.",
  );
}

const transactionData = transactionSnapshot.data() || {};

if (transactionData.status !== "pending") {
  throw new HttpsError(
    "failed-precondition",
    "This transaction has already been processed.",
  );
}

const userId = transactionData.userId;

if (typeof userId !== "string" || userId.isEmpty) {
  throw new HttpsError(
    "invalid-argument",
    "Transaction user ID is missing.",
  );
}

const amount = transactionData.amount;

if (
  typeof amount !== "number" ||
  !Number.isFinite(amount) ||
  amount < 100
) {
  throw new HttpsError(
    "invalid-argument",
    "Invalid wallet amount.",
  );
}

if (transactionData.currency !== "BDT") {
  throw new HttpsError(
    "invalid-argument",
    "Only BDT wallet transactions are supported.",
  );
}

const userRef = db.collection("users").doc(userId);
const userSnapshot = await transaction.get(userRef);

if (!userSnapshot.exists) {
  throw new HttpsError(
    "not-found",
    "User account was not found.",
  );
}

const userData = userSnapshot.data() || {};

const currentBalance =
  typeof userData.cashBalance === "number"
    ? userData.cashBalance
    : 0;

let newBalance = currentBalance;

if (
  transactionData.type === "credit" &&
  transactionData.source === "deposit"
) {
  newBalance = currentBalance + amount;
} else if (
  transactionData.type === "debit" &&
  transactionData.source === "withdrawal"
) {
  if (amount > currentBalance) {
    throw new HttpsError(
      "failed-precondition",
      "Insufficient wallet balance.",
    );
  }

  newBalance = currentBalance - amount;
} else {
  throw new HttpsError(
    "invalid-argument",
    "Unsupported wallet transaction type.",
  );
}

transaction.update(userRef, {
  cashBalance: newBalance,
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
});

transaction.update(transactionRef, {
  status: "approved",
  approvedAt: admin.firestore.FieldValue.serverTimestamp(),
  processedBy: request.auth.uid,
  processedByEmail:
    request.auth.token.email || null,
});

return {
  previousBalance: currentBalance,
  newBalance,
  amount,
  type: transactionData.type,
  source: transactionData.source,
  userId,
};

});

// =======================================================
// USER NOTIFICATION
// =======================================================

const notificationRef = db
.collection("users")
.doc(result.userId)
.collection("notifications")
.doc();

let title = "Wallet Updated";
let message = "Your wallet has been updated by ৳${result.amount}.";
let type = "wallet";

if (result.source === "deposit") {
title = "Deposit Approved";
message =
"Your deposit of ৳${result.amount} has been approved. " +
"Your new wallet balance is ৳${result.newBalance}.";
type = "wallet_deposit";
} else if (result.source === "withdrawal") {
title = "Withdrawal Approved";
message =
"Your withdrawal of ৳${result.amount} has been approved. " +
"Your remaining wallet balance is ৳${result.newBalance}.";
type = "wallet_withdrawal";
}

await notificationRef.set({
customerId: result.userId,
sellerId: request.auth.uid,
title,
message,
type,
orderStatus: "wallet",
isRead: false,
createdAt: admin.firestore.FieldValue.serverTimestamp(),
});

return {
success: true,
message: "Wallet transaction approved successfully.",
transactionId,
previousBalance: result.previousBalance,
newBalance: result.newBalance,
};
});

// =========================================================
// REJECT WALLET TRANSACTION
// =========================================================
//
// ADMIN ONLY.
//
// Rejection NEVER changes the user's wallet balance.
//

exports.rejectWalletTransaction = onCall(async (request) => {
requireAdmin(request);

const transactionId = request.data?.transactionId;
const reason = request.data?.reason;

if (
typeof transactionId !== "string" ||
transactionId.trim().length === 0
) {
throw new HttpsError(
"invalid-argument",
"A valid transaction ID is required.",
);
}

const cleanReason =
typeof reason === "string" && reason.trim().length > 0
? reason.trim()
: "Transaction rejected by BuyNova administration.";

const transactionRef = findWalletTransactionReference(
transactionId.trim(),
);

const result = await db.runTransaction(async (transaction) => {
const transactionSnapshot =
await transaction.get(transactionRef);

if (!transactionSnapshot.exists) {
  throw new HttpsError(
    "not-found",
    "Wallet transaction was not found.",
  );
}

const transactionData = transactionSnapshot.data() || {};

if (transactionData.status !== "pending") {
  throw new HttpsError(
    "failed-precondition",
    "This transaction has already been processed.",
  );
}

const userId = transactionData.userId;

if (typeof userId !== "string") {
  throw new HttpsError(
    "invalid-argument",
    "Transaction user ID is missing.",
  );
}

transaction.update(transactionRef, {
  status: "rejected",
  rejectionReason: cleanReason,
  rejectedAt: admin.firestore.FieldValue.serverTimestamp(),
  processedBy: request.auth.uid,
  processedByEmail:
    request.auth.token.email || null,
});

return {
  userId,
  amount: transactionData.amount,
  source: transactionData.source,
};

});

// =======================================================
// USER NOTIFICATION
// =======================================================

const notificationRef = db
.collection("users")
.doc(result.userId)
.collection("notifications")
.doc();

let title = "Wallet Transaction Rejected";
let type = "wallet_rejected";

if (result.source === "deposit") {
title = "Deposit Rejected";
type = "wallet_deposit_rejected";
} else if (result.source === "withdrawal") {
title = "Withdrawal Rejected";
type = "wallet_withdrawal_rejected";
}

await notificationRef.set({
customerId: result.userId,
sellerId: request.auth.uid,
title,
message:
"Your wallet transaction of ৳${result.amount} was rejected. " +
"Reason: ${cleanReason}",
type,
orderStatus: "wallet",
isRead: false,
createdAt: admin.firestore.FieldValue.serverTimestamp(),
});

return {
success: true,
message: "Wallet transaction rejected successfully.",
transactionId,
};
});

// =========================================================
// FIND WALLET TRANSACTION
// =========================================================
//
// Wallet transactions are stored inside:
// users/{userId}/walletTransactions/{transactionId}
//
// Because transactionId alone does not tell us the user ID,
// we search the walletTransactions collection group.
//

function findWalletTransactionReference(transactionId) {
const query = db
.collectionGroup("walletTransactions")
.where(
admin.firestore.FieldPath.documentId(),
"==",
transactionId,
)
.limit(1);

// This helper cannot return a document reference directly from
// an async query. The actual lookup is handled below.
//
// The placeholder is intentionally replaced by the async helper.
return {
async get() {
const snapshot = await query.get();

  if (snapshot.empty) {
    return {
      exists: false,
    };
  }

  return snapshot.docs[0];
},

};
}
