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

// ============================================================
// HELPERS
// ============================================================

function requireAuth(request) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in."
    );
  }

  return request.auth.uid;
}

function requireAdmin(request) {
  const uid = requireAuth(request);

  const email =
    request.auth.token.email || "";

  if (email.toLowerCase() !== "miamdarif010@gmail.com") {
    throw new HttpsError(
      "permission-denied",
      "Admin access required."
    );
  }

  return uid;
}

// ============================================================
// HEALTH CHECK
// ============================================================

exports.healthCheck = onCall(async () => {
  return {
    success: true,
    message: "BuyNova Functions are working.",
    region: "asia-northeast3",
    timestamp: new Date().toISOString(),
  };
});

// ============================================================
// WALLET TRANSACTION LISTENER
// ============================================================

exports.onWalletTransactionCreated =
  onDocumentCreated(
    "users/{userId}/walletTransactions/{transactionId}",
    async (event) => {
      const snapshot = event.data;

      if (!snapshot) {
        return;
      }

      const data = snapshot.data();

      console.log(
        "Wallet transaction created:",
        event.params.userId,
        event.params.transactionId,
        data
      );

      return null;
    }
  );

// ============================================================
// GET WALLET BALANCE
// ============================================================

exports.getWalletBalance = onCall(
  async (request) => {
    const uid = requireAuth(request);

    const userRef = db
      .collection("users")
      .doc(uid);

    const userSnapshot =
      await userRef.get();

    if (!userSnapshot.exists) {
      throw new HttpsError(
        "not-found",
        "User account not found."
      );
    }

    const userData =
      userSnapshot.data() || {};

    const rawBalance =
      userData.cashBalance ??
      userData.walletBalance ??
      0;

    const balance =
      Number(rawBalance) || 0;

    return {
      success: true,
      balance: balance,
      cashBalance: balance,
      currency: "BDT",
    };
  }
);

// ============================================================
// APPROVE WALLET TRANSACTION
// ============================================================

exports.approveWalletTransaction =
  onCall(async (request) => {
    requireAdmin(request);

    const {
      userId,
      transactionId,
    } = request.data || {};

    if (!userId || !transactionId) {
      throw new HttpsError(
        "invalid-argument",
        "userId and transactionId are required."
      );
    }

    const transactionRef = db
      .collection("users")
      .doc(userId)
      .collection("walletTransactions")
      .doc(transactionId);

    const result =
      await db.runTransaction(
        async (transaction) => {
          const transactionSnapshot =
            await transaction.get(
              transactionRef
            );

          if (!transactionSnapshot.exists) {
            throw new HttpsError(
              "not-found",
              "Wallet transaction not found."
            );
          }

          const transactionData =
            transactionSnapshot.data() || {};

          if (
            transactionData.status ===
            "approved"
          ) {
            return {
              alreadyApproved: true,
            };
          }

          if (
            transactionData.status ===
            "rejected"
          ) {
            throw new HttpsError(
              "failed-precondition",
              "This transaction has already been rejected."
            );
          }

          const userRef = db
            .collection("users")
            .doc(userId);

          const userSnapshot =
            await transaction.get(
              userRef
            );

          if (!userSnapshot.exists) {
            throw new HttpsError(
              "not-found",
              "User account not found."
            );
          }

          const userData =
            userSnapshot.data() || {};

          const currentBalance =
            Number(
              userData.cashBalance ??
              userData.walletBalance ??
              0
            );

          const amount =
            Number(
              transactionData.amount ?? 0
            );

          if (amount <= 0) {
            throw new HttpsError(
              "invalid-argument",
              "Invalid wallet transaction amount."
            );
          }

          const newBalance =
            currentBalance + amount;

          transaction.update(
            userRef,
            {
              cashBalance: newBalance,
              walletBalance: newBalance,
              updatedAt:
                admin.firestore.FieldValue
                  .serverTimestamp(),
            }
          );

          transaction.update(
            transactionRef,
            {
              status: "approved",
              balanceBefore:
                currentBalance,
              balanceAfter:
                newBalance,
              approvedAt:
                admin.firestore.FieldValue
                  .serverTimestamp(),
              updatedAt:
                admin.firestore.FieldValue
                  .serverTimestamp(),
            }
          );

          return {
            alreadyApproved: false,
            newBalance,
          };
        }
      );

    await db
      .collection("users")
      .doc(userId)
      .collection("notifications")
      .add({
        title: "Wallet Updated",
        message:
          "Your BuyNova Wallet transaction has been approved.",
        type: "wallet",
        read: false,
        createdAt:
          admin.firestore.FieldValue
            .serverTimestamp(),
      });

    return {
      success: true,
      ...result,
    };
  });

// ============================================================
// REJECT WALLET TRANSACTION
// ============================================================

exports.rejectWalletTransaction =
  onCall(async (request) => {
    requireAdmin(request);

    const {
      userId,
      transactionId,
      reason,
    } = request.data || {};

    if (!userId || !transactionId) {
      throw new HttpsError(
        "invalid-argument",
        "userId and transactionId are required."
      );
    }

    const transactionRef = db
      .collection("users")
      .doc(userId)
      .collection("walletTransactions")
      .doc(transactionId);

    await db.runTransaction(
      async (transaction) => {
        const snapshot =
          await transaction.get(
            transactionRef
          );

        if (!snapshot.exists) {
          throw new HttpsError(
            "not-found",
            "Wallet transaction not found."
          );
        }

        const data =
          snapshot.data() || {};

        if (data.status === "rejected") {
          return;
        }

        if (data.status === "approved") {
          throw new HttpsError(
            "failed-precondition",
            "An approved transaction cannot be rejected."
          );
        }

        transaction.update(
          transactionRef,
          {
            status: "rejected",
            rejectionReason:
              reason || "Rejected by admin.",
            rejectedAt:
              admin.firestore.FieldValue
                .serverTimestamp(),
            updatedAt:
              admin.firestore.FieldValue
                .serverTimestamp(),
          }
        );
      }
    );

    await db
      .collection("users")
      .doc(userId)
      .collection("notifications")
      .add({
        title: "Wallet Transaction Rejected",
        message:
          reason ||
          "Your BuyNova Wallet transaction was rejected.",
        type: "wallet",
        read: false,
        createdAt:
          admin.firestore.FieldValue
            .serverTimestamp(),
      });

    return {
      success: true,
      message:
        "Wallet transaction rejected.",
    };
  });

// ============================================================
// PLACE WALLET ORDER
// ============================================================

exports.placeWalletOrder = onCall(
  async (request) => {
    const uid = requireAuth(request);

    const {
      orderId,
    } = request.data || {};

    if (!orderId) {
      throw new HttpsError(
        "invalid-argument",
        "orderId is required."
      );
    }

    const userRef = db
      .collection("users")
      .doc(uid);

    const orderRef = db
      .collection("orders")
      .doc(orderId);

    const result =
      await db.runTransaction(
        async (transaction) => {
          // ----------------------------------------------------
          // READ USER
          // ----------------------------------------------------

          const userSnapshot =
            await transaction.get(
              userRef
            );

          if (!userSnapshot.exists) {
            throw new HttpsError(
              "not-found",
              "User account not found."
            );
          }

          // ----------------------------------------------------
          // READ ORDER
          // ----------------------------------------------------

          const orderSnapshot =
            await transaction.get(
              orderRef
            );

          if (!orderSnapshot.exists) {
            throw new HttpsError(
              "not-found",
              "Order not found."
            );
          }

          const orderData =
            orderSnapshot.data() || {};

          // ----------------------------------------------------
          // VERIFY ORDER OWNER
          // ----------------------------------------------------

          const orderUserId =
            orderData.userId ??
            orderData.customerId;

          if (orderUserId !== uid) {
            throw new HttpsError(
              "permission-denied",
              "You cannot pay for this order."
            );
          }

          // ----------------------------------------------------
          // VERIFY PAYMENT METHOD
          // ----------------------------------------------------

          if (
            orderData.paymentMethod !==
            "BuyNova Wallet"
          ) {
            throw new HttpsError(
              "failed-precondition",
              "This order is not using BuyNova Wallet."
            );
          }

          // ----------------------------------------------------
          // ALREADY PAID
          // ----------------------------------------------------

          if (
            orderData.paymentStatus ===
            "paid"
          ) {
            return {
              alreadyPaid: true,
              transactionId:
                orderData.walletTransactionId ||
                null,
              newBalance: null,
            };
          }

          // ----------------------------------------------------
          // ORDER AMOUNT
          // ----------------------------------------------------

          const totalAmount = Number(
            orderData.grandTotal ??
            orderData.total ??
            orderData.totalAmount ??
            0
          );

          if (
            !Number.isFinite(totalAmount) ||
            totalAmount <= 0
          ) {
            throw new HttpsError(
              "failed-precondition",
              "Invalid order amount."
            );
          }

          // ----------------------------------------------------
          // WALLET BALANCE
          // ----------------------------------------------------

          const userData =
            userSnapshot.data() || {};

          const balanceBefore =
            Number(
              userData.cashBalance ??
              userData.walletBalance ??
              0
            );

          if (
            !Number.isFinite(balanceBefore)
          ) {
            throw new HttpsError(
              "failed-precondition",
              "Invalid wallet balance."
            );
          }

          if (
            balanceBefore < totalAmount
          ) {
            throw new HttpsError(
              "failed-precondition",
              "Insufficient wallet balance."
            );
          }

          // ----------------------------------------------------
          // NEW BALANCE
          // ----------------------------------------------------

          const balanceAfter =
            balanceBefore - totalAmount;

          // ----------------------------------------------------
          // WALLET TRANSACTION
          // ----------------------------------------------------

          const walletTransactionRef =
            userRef
              .collection("walletTransactions")
              .doc();

          transaction.set(
            walletTransactionRef,
            {
              type: "debit",
              source: "order_payment",
              status: "approved",

              amount: totalAmount,
              currency: "BDT",

              orderId: orderId,

              balanceBefore:
                balanceBefore,
              balanceAfter:
                balanceAfter,

              description:
                `Payment for BuyNova order ${orderId}`,

              createdAt:
                admin.firestore.FieldValue
                  .serverTimestamp(),

              updatedAt:
                admin.firestore.FieldValue
                  .serverTimestamp(),
            }
          );

          // ----------------------------------------------------
          // UPDATE USER WALLET
          // ----------------------------------------------------

          transaction.update(
            userRef,
            {
              cashBalance:
                balanceAfter,
              walletBalance:
                balanceAfter,
              updatedAt:
                admin.firestore.FieldValue
                  .serverTimestamp(),
            }
          );

          // ----------------------------------------------------
          // UPDATE MAIN ORDER
          // ----------------------------------------------------

          transaction.update(
            orderRef,
            {
              paymentStatus: "paid",
              paymentMethod:
                "BuyNova Wallet",

              walletPaid: true,

              walletTransactionId:
                walletTransactionRef.id,

              walletPaidAt:
                admin.firestore.FieldValue
                  .serverTimestamp(),

              updatedAt:
                admin.firestore.FieldValue
                  .serverTimestamp(),
            }
          );

          // ----------------------------------------------------
          // FIND SELLER ORDERS
          // ----------------------------------------------------

          const sellerOrdersQuery =
            db
              .collection("seller_orders")
              .where(
                "orderId",
                "==",
                orderId
              );

          const sellerOrdersSnapshot =
            await transaction.get(
              sellerOrdersQuery
            );

          for (
            const sellerDoc of
              sellerOrdersSnapshot.docs
          ) {
            transaction.update(
              sellerDoc.ref,
              {
                paymentStatus: "paid",
                paymentMethod:
                  "BuyNova Wallet",
                walletTransactionId:
                  walletTransactionRef.id,
                updatedAt:
                  admin.firestore.FieldValue
                    .serverTimestamp(),
              }
            );
          }

          // ----------------------------------------------------
          // FIND RESELLER ORDERS
          // ----------------------------------------------------

          const resellerOrdersQuery =
            db
              .collection("reseller_orders")
              .where(
                "orderId",
                "==",
                orderId
              );

          const resellerOrdersSnapshot =
            await transaction.get(
              resellerOrdersQuery
            );

          for (
            const resellerDoc of
              resellerOrdersSnapshot.docs
          ) {
            transaction.update(
              resellerDoc.ref,
              {
                paymentStatus: "paid",
                paymentMethod:
                  "BuyNova Wallet",
                walletTransactionId:
                  walletTransactionRef.id,
                updatedAt:
                  admin.firestore.FieldValue
                    .serverTimestamp(),
              }
            );
          }

          // ----------------------------------------------------
          // NOTIFICATION
          // ----------------------------------------------------

          const notificationRef =
            userRef
              .collection("notifications")
              .doc();

          transaction.set(
            notificationRef,
            {
              title:
                "Payment Successful",
              message:
                `৳${totalAmount.toFixed(2)} was paid from your BuyNova Wallet for order ${orderId}.`,
              type: "order_payment",
              orderId: orderId,
              amount: totalAmount,
              currency: "BDT",
              read: false,
              createdAt:
                admin.firestore.FieldValue
                  .serverTimestamp(),
            }
          );

          return {
            alreadyPaid: false,
            transactionId:
              walletTransactionRef.id,
            newBalance:
              balanceAfter,
            amountPaid:
              totalAmount,
          };
        }
      );

    return {
      success: true,
      ...result,
    };
  }
);
