const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

setGlobalOptions({
region: "asia-northeast3",
maxInstances: 10,
});

// =========================================================
// ADMIN CHECK
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
// NEW WALLET TRANSACTION LISTENER
// =========================================================

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

exports.getWalletBalance = onCall(async (request) => {
if (!request.auth) {
throw new HttpsError(
"unauthenticated",
"You must be logged in.",
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
// Deposit:
// pending credit/deposit -> adds money.
//
// Withdrawal:
// pending debit/withdrawal -> subtracts money.
//
// Balance and transaction status are changed atomically.
//

exports.approveWalletTransaction = onCall(async (request) => {
requireAdmin(request);

const userId = request.data?.userId;
const transactionId = request.data?.transactionId;

if (
typeof userId !== "string" ||
userId.trim().length === 0
) {
throw new HttpsError(
"invalid-argument",
"A valid user ID is required.",
);
}

if (
typeof transactionId !== "string" ||
transactionId.trim().length === 0
) {
throw new HttpsError(
"invalid-argument",
"A valid transaction ID is required.",
);
}

const userRef = db.collection("users").doc(userId);

const transactionRef = userRef
.collection("walletTransactions")
.doc(transactionId);

const result = await db.runTransaction(async (transaction) => {
const transactionSnapshot =
await transaction.get(transactionRef);

if (!transactionSnapshot.exists) {
  throw new HttpsError(
    "not-found",
    "Wallet transaction was not found.",
  );
}

const transactionData =
    transactionSnapshot.data() || {};

if (transactionData.userId !== userId) {
  throw new HttpsError(
    "permission-denied",
    "Transaction ownership mismatch.",
  );
}

if (transactionData.status !== "pending") {
  throw new HttpsError(
    "failed-precondition",
    "This transaction has already been processed.",
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
    "Only BDT transactions are supported.",
  );
}

const userSnapshot =
    await transaction.get(userRef);

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
    "Unsupported wallet transaction.",
  );
}

transaction.update(userRef, {
  cashBalance: newBalance,
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
});

transaction.update(transactionRef, {
  status: "approved",
  approvedAt:
      admin.firestore.FieldValue.serverTimestamp(),
  processedBy: request.auth.uid,
  processedByEmail:
      request.auth.token.email || null,
});

return {
  userId,
  amount,
  source: transactionData.source,
  previousBalance: currentBalance,
  newBalance,
};

});

// =======================================================
// NOTIFICATION
// =======================================================

const notificationRef = db
.collection("users")
.doc(result.userId)
.collection("notifications")
.doc();

let title;
let message;
let type;

if (result.source === "deposit") {
title = "Deposit Approved";
message =
"Your deposit of ৳${result.amount} has been approved. " +
"Your new wallet balance is ৳${result.newBalance}.";
type = "wallet_deposit";
} else {
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
createdAt:
admin.firestore.FieldValue.serverTimestamp(),
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
// Rejecting a transaction never changes cashBalance.
//

exports.rejectWalletTransaction = onCall(async (request) => {
requireAdmin(request);

const userId = request.data?.userId;
const transactionId = request.data?.transactionId;
const reason = request.data?.reason;

if (
typeof userId !== "string" ||
userId.trim().length === 0
) {
throw new HttpsError(
"invalid-argument",
"A valid user ID is required.",
);
}

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
typeof reason === "string" &&
reason.trim().length > 0
? reason.trim()
: "Transaction rejected by BuyNova administration.";

const transactionRef = db
.collection("users")
.doc(userId)
.collection("walletTransactions")
.doc(transactionId);

const result = await db.runTransaction(async (transaction) => {
const transactionSnapshot =
await transaction.get(transactionRef);

if (!transactionSnapshot.exists) {
  throw new HttpsError(
    "not-found",
    "Wallet transaction was not found.",
  );
}

const transactionData =
    transactionSnapshot.data() || {};

if (transactionData.userId !== userId) {
  throw new HttpsError(
    "permission-denied",
    "Transaction ownership mismatch.",
  );
}

if (transactionData.status !== "pending") {
  throw new HttpsError(
    "failed-precondition",
    "This transaction has already been processed.",
  );
}

transaction.update(transactionRef, {
  status: "rejected",
  rejectionReason: cleanReason,
  rejectedAt:
      admin.firestore.FieldValue.serverTimestamp(),
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
// NOTIFICATION
// =======================================================

const notificationRef = db
.collection("users")
.doc(result.userId)
.collection("notifications")
.doc();

let title;
let type;

if (result.source === "deposit") {
title = "Deposit Rejected";
type = "wallet_deposit_rejected";
} else {
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
createdAt:
admin.firestore.FieldValue.serverTimestamp(),
});

return {
success: true,
message: "Wallet transaction rejected successfully.",
transactionId,
};
});
// =========================================================
// BUYNOVA WALLET ORDER PAYMENT
// Securely pays an order using the user's common BuyNova Wallet.
// =========================================================

exports.placeWalletOrder = onCall(async (request) => {
  // -------------------------------------------------------
  // 1. Authentication check
  // -------------------------------------------------------
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to use BuyNova Wallet."
    );
  }

  const uid = request.auth.uid;
  const orderId = request.data?.orderId;

  if (!orderId || typeof orderId !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "A valid orderId is required."
    );
  }

  // -------------------------------------------------------
  // References
  // -------------------------------------------------------
  const userRef = db.collection("users").doc(uid);
  const orderRef = db.collection("orders").doc(orderId);

  // -------------------------------------------------------
  // 2. Firestore transaction
  // -------------------------------------------------------
  const result = await db.runTransaction(async (transaction) => {
    const userSnap = await transaction.get(userRef);
    const orderSnap = await transaction.get(orderRef);

    if (!userSnap.exists) {
      throw new HttpsError(
        "not-found",
        "User account was not found."
      );
    }

    if (!orderSnap.exists) {
      throw new HttpsError(
        "not-found",
        "Order was not found."
      );
    }

    const userData = userSnap.data() || {};
    const orderData = orderSnap.data() || {};

    // -----------------------------------------------------
    // 3. Verify order ownership
    // -----------------------------------------------------
    if (orderData.userId !== uid) {
      throw new HttpsError(
        "permission-denied",
        "You are not allowed to pay this order."
      );
    }

    // -----------------------------------------------------
    // 4. Prevent duplicate payment
    // -----------------------------------------------------
    if (orderData.paymentStatus === "paid") {
      return {
        success: true,
        alreadyPaid: true,
        orderId: orderId,
        message: "This order has already been paid.",
      };
    }

    // -----------------------------------------------------
    // 5. Verify payment method
    // -----------------------------------------------------
    if (orderData.paymentMethod !== "BuyNova Wallet") {
      throw new HttpsError(
        "failed-precondition",
        "This order is not configured for BuyNova Wallet."
      );
    }

    // -----------------------------------------------------
    // 6. Read order total
    // -----------------------------------------------------
    const rawTotal =
      orderData.grandTotal ??
      orderData.total ??
      orderData.totalAmount ??
      0;

    const orderTotal = Number(rawTotal);

    if (!Number.isFinite(orderTotal) || orderTotal <= 0) {
      throw new HttpsError(
        "failed-precondition",
        "Invalid order amount."
      );
    }

    // -----------------------------------------------------
    // 7. Read wallet balance
    // -----------------------------------------------------
    const rawBalance =
      userData.cashBalance ??
      userData.walletBalance ??
      0;

    const walletBalance = Number(rawBalance);

    if (!Number.isFinite(walletBalance) || walletBalance < 0) {
      throw new HttpsError(
        "failed-precondition",
        "Invalid wallet balance."
      );
    }

    // -----------------------------------------------------
    // 8. Check sufficient balance
    // -----------------------------------------------------
    if (walletBalance < orderTotal) {
      throw new HttpsError(
        "failed-precondition",
        "Insufficient BuyNova Wallet balance."
      );
    }

    // -----------------------------------------------------
    // 9. Calculate new balance
    // -----------------------------------------------------
    const newBalance = Number(
      (walletBalance - orderTotal).toFixed(2)
    );

    // -----------------------------------------------------
    // 10. Create wallet transaction
    // -----------------------------------------------------
    const walletTransactionRef = db
      .collection("walletTransactions")
      .doc();

    transaction.set(walletTransactionRef, {
      userId: uid,
      type: "debit",
      amount: orderTotal,
      currency: "BDT",
      source: "order_payment",
      status: "approved",
      orderId: orderId,
      description: `Payment for BuyNova order ${orderId}`,
      balanceBefore: walletBalance,
      balanceAfter: newBalance,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // -----------------------------------------------------
    // 11. Deduct wallet balance
    // -----------------------------------------------------
    transaction.update(userRef, {
      cashBalance: newBalance,
      walletUpdatedAt:
        admin.firestore.FieldValue.serverTimestamp(),
    });

    // -----------------------------------------------------
    // 12. Mark order as paid
    // -----------------------------------------------------
    transaction.update(orderRef, {
      paymentMethod: "BuyNova Wallet",
      paymentStatus: "paid",
      walletPaid: true,
      walletTransactionId: walletTransactionRef.id,
      walletPaidAt:
        admin.firestore.FieldValue.serverTimestamp(),
      updatedAt:
        admin.firestore.FieldValue.serverTimestamp(),
    });

    // -----------------------------------------------------
    // 13. Create notification
    // -----------------------------------------------------
    const notificationRef = db
      .collection("notifications")
      .doc();

    transaction.set(notificationRef, {
      userId: uid,
      type: "wallet_order_payment",
      title: "Payment Successful",
      message:
        `৳${orderTotal.toFixed(2)} was paid from your BuyNova Wallet.`,
      orderId: orderId,
      amount: orderTotal,
      currency: "BDT",
      read: false,
      createdAt:
        admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      alreadyPaid: false,
      orderId: orderId,
      transactionId: walletTransactionRef.id,
      amount: orderTotal,
      newBalance: newBalance,
    };
  });

  return result;
});
