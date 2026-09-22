const { onCall, HttpsError } = require("firebase-functions/v2/https");
const {
  onDocumentCreated,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const cloudinary = require("cloudinary").v2;

admin.initializeApp();

const db = admin.firestore();
const serverTimestamp = () => admin.firestore.FieldValue.serverTimestamp();

setGlobalOptions({
  region: "asia-northeast3",
  maxInstances: 10,
});

// ============================================================
// CLOUDINARY SECRETS
// ============================================================
// Set these once per project with:
//   firebase functions:secrets:set CLOUDINARY_API_KEY
//   firebase functions:secrets:set CLOUDINARY_API_SECRET
// (v2 functions use Secret Manager, not functions.config().)

const cloudinaryApiKey = defineSecret("CLOUDINARY_API_KEY");
const cloudinaryApiSecret = defineSecret("CLOUDINARY_API_SECRET");

const CLOUDINARY_CLOUD_NAME = "riassg6d";

// ============================================================
// HELPERS
// ============================================================

function requireAuth(request) {
  if (!request.auth || !request.auth.uid) {
    throw new HttpsError("unauthenticated", "You must be logged in.");
  }

  return request.auth.uid;
}

function requireAdmin(request) {
  const uid = requireAuth(request);

  const email = request.auth.token.email || "";

  if (email.toLowerCase() !== "miamdarif010@gmail.com") {
    throw new HttpsError("permission-denied", "Admin access required.");
  }

  return uid;
}

// Extracts the Cloudinary public_id from a delivery URL, e.g.
//   https://res.cloudinary.com/<cloud>/video/upload/v170.../buynova_products/abc123.mp4
// -> buynova_products/abc123
function extractCloudinaryPublicId(url) {
  try {
    const uri = new URL(url);
    const path = uri.pathname;

    const uploadIndex = path.indexOf("/upload/");
    if (uploadIndex === -1) return null;

    let rest = path.substring(uploadIndex + "/upload/".length);

    // Strip a leading transformation segment (e.g. "so_0/"),
    // present on generated thumbnail URLs but not on video URLs.
    const segments = rest.split("/");
    if (segments.length > 1 && /^[a-z]{1,3}_/.test(segments[0])) {
      segments.shift();
    }
    rest = segments.join("/");

    // Strip a leading version segment like "v1710000000/"
    rest = rest.replace(/^v\d+\//, "");

    // Strip the file extension
    rest = rest.replace(/\.[^./]+$/, "");

    return rest || null;
  } catch (e) {
    return null;
  }
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
// DELETE CLOUDINARY VIDEO (+ thumbnail)
// ============================================================
// Called from MyVideosPage before the Firestore "sellerVideos"
// document is deleted, so the underlying media doesn't stay
// orphaned on Cloudinary.

exports.deleteCloudinaryVideo = onCall(
  { secrets: [cloudinaryApiKey, cloudinaryApiSecret] },
  async (request) => {
    requireAuth(request);

    const { videoUrl, thumbnailUrl } = request.data || {};

    if (!videoUrl || typeof videoUrl !== "string") {
      throw new HttpsError("invalid-argument", "videoUrl is required.");
    }

    cloudinary.config({
      cloud_name: CLOUDINARY_CLOUD_NAME,
      api_key: cloudinaryApiKey.value(),
      api_secret: cloudinaryApiSecret.value(),
    });

    const results = { video: null, thumbnail: null };

    const videoPublicId = extractCloudinaryPublicId(videoUrl);

    if (videoPublicId) {
      try {
        results.video = await cloudinary.uploader.destroy(videoPublicId, {
          resource_type: "video",
          invalidate: true,
        });
      } catch (e) {
        console.error("Failed to delete Cloudinary video:", e);
        results.video = { error: e.message };
      }
    }

    if (thumbnailUrl && typeof thumbnailUrl === "string") {
      const thumbPublicId = extractCloudinaryPublicId(thumbnailUrl);

      if (thumbPublicId) {
        try {
          results.thumbnail = await cloudinary.uploader.destroy(
            thumbPublicId,
            {
              resource_type: "image",
              invalidate: true,
            }
          );
        } catch (e) {
          console.error("Failed to delete Cloudinary thumbnail:", e);
          results.thumbnail = { error: e.message };
        }
      }
    }

    return results;
  }
);

// ============================================================
// WALLET TRANSACTION LISTENER
// ============================================================

exports.onWalletTransactionCreated = onDocumentCreated(
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

exports.getWalletBalance = onCall(async (request) => {
  const uid = requireAuth(request);

  const userSnapshot = await db.collection("users").doc(uid).get();

  if (!userSnapshot.exists) {
    throw new HttpsError("not-found", "User account not found.");
  }

  const userData = userSnapshot.data() || {};

  const rawBalance = userData.cashBalance ?? userData.walletBalance ?? 0;

  const balance = Number(rawBalance) || 0;

  return {
    success: true,
    balance: balance,
    cashBalance: balance,
    currency: "BDT",
  };
});

// ============================================================
// APPROVE WALLET TRANSACTION
// ============================================================

exports.approveWalletTransaction = onCall(async (request) => {
  requireAdmin(request);

  const { userId, transactionId } = request.data || {};

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

  const result = await db.runTransaction(async (transaction) => {
    const transactionSnapshot = await transaction.get(transactionRef);

    if (!transactionSnapshot.exists) {
      throw new HttpsError("not-found", "Wallet transaction not found.");
    }

    const transactionData = transactionSnapshot.data() || {};

    if (transactionData.status === "approved") {
      return { alreadyApproved: true };
    }

    if (transactionData.status === "rejected") {
      throw new HttpsError(
        "failed-precondition",
        "This transaction has already been rejected."
      );
    }

    const userRef = db.collection("users").doc(userId);

    const userSnapshot = await transaction.get(userRef);

    if (!userSnapshot.exists) {
      throw new HttpsError("not-found", "User account not found.");
    }

    const userData = userSnapshot.data() || {};

    const currentBalance = Number(
      userData.cashBalance ?? userData.walletBalance ?? 0
    );

    const amount = Number(transactionData.amount ?? 0);

    if (amount <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "Invalid wallet transaction amount."
      );
    }

    const newBalance = currentBalance + amount;

    transaction.update(userRef, {
      cashBalance: newBalance,
      walletBalance: newBalance,
      updatedAt: serverTimestamp(),
    });

    transaction.update(transactionRef, {
      status: "approved",
      balanceBefore: currentBalance,
      balanceAfter: newBalance,
      approvedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    return {
      alreadyApproved: false,
      newBalance,
    };
  });

  await db
    .collection("users")
    .doc(userId)
    .collection("notifications")
    .add({
      title: "Wallet Updated",
      message: "Your BuyNova Wallet transaction has been approved.",
      type: "wallet",
      read: false,
      createdAt: serverTimestamp(),
    });

  return {
    success: true,
    ...result,
  };
});

// ============================================================
// REJECT WALLET TRANSACTION
// ============================================================

exports.rejectWalletTransaction = onCall(async (request) => {
  requireAdmin(request);

  const { userId, transactionId, reason } = request.data || {};

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

  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(transactionRef);

    if (!snapshot.exists) {
      throw new HttpsError("not-found", "Wallet transaction not found.");
    }

    const data = snapshot.data() || {};

    if (data.status === "rejected") {
      return;
    }

    if (data.status === "approved") {
      throw new HttpsError(
        "failed-precondition",
        "An approved transaction cannot be rejected."
      );
    }

    transaction.update(transactionRef, {
      status: "rejected",
      rejectionReason: reason || "Rejected by admin.",
      rejectedAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });
  });

  await db
    .collection("users")
    .doc(userId)
    .collection("notifications")
    .add({
      title: "Wallet Transaction Rejected",
      message: reason || "Your BuyNova Wallet transaction was rejected.",
      type: "wallet",
      read: false,
      createdAt: serverTimestamp(),
    });

  return {
    success: true,
    message: "Wallet transaction rejected.",
  };
});

// ============================================================
// PLACE WALLET ORDER
// ============================================================
// NOTE: Firestore transactions require ALL reads to happen
// before ANY writes. All reads are grouped at the top below.

exports.placeWalletOrder = onCall(async (request) => {
  const uid = requireAuth(request);

  const { orderId } = request.data || {};

  if (!orderId) {
    throw new HttpsError("invalid-argument", "orderId is required.");
  }

  const userRef = db.collection("users").doc(uid);
  const orderRef = db.collection("orders").doc(orderId);

  const result = await db.runTransaction(async (transaction) => {
    // ==========================================================
    // ALL READS FIRST
    // ==========================================================

    const userSnapshot = await transaction.get(userRef);

    if (!userSnapshot.exists) {
      throw new HttpsError("not-found", "User account not found.");
    }

    const orderSnapshot = await transaction.get(orderRef);

    if (!orderSnapshot.exists) {
      throw new HttpsError("not-found", "Order not found.");
    }

    const sellerOrdersSnapshot = await transaction.get(
      db.collection("seller_orders").where("orderId", "==", orderId)
    );

    const resellerOrdersSnapshot = await transaction.get(
      db.collection("reseller_orders").where("orderId", "==", orderId)
    );

    // ==========================================================
    // VALIDATION
    // ==========================================================

    const orderData = orderSnapshot.data() || {};

    const orderUserId = orderData.userId ?? orderData.customerId;

    if (orderUserId !== uid) {
      throw new HttpsError(
        "permission-denied",
        "You cannot pay for this order."
      );
    }

    if (orderData.paymentMethod !== "BuyNova Wallet") {
      throw new HttpsError(
        "failed-precondition",
        "This order is not using BuyNova Wallet."
      );
    }

    if (orderData.paymentStatus === "paid") {
      return {
        alreadyPaid: true,
        transactionId: orderData.walletTransactionId || null,
        newBalance: null,
      };
    }

    const totalAmount = Number(
      orderData.grandTotal ?? orderData.total ?? orderData.totalAmount ?? 0
    );

    if (!Number.isFinite(totalAmount) || totalAmount <= 0) {
      throw new HttpsError("failed-precondition", "Invalid order amount.");
    }

    const userData = userSnapshot.data() || {};

    const balanceBefore = Number(
      userData.cashBalance ?? userData.walletBalance ?? 0
    );

    if (!Number.isFinite(balanceBefore)) {
      throw new HttpsError("failed-precondition", "Invalid wallet balance.");
    }

    if (balanceBefore < totalAmount) {
      throw new HttpsError(
        "failed-precondition",
        "Insufficient wallet balance."
      );
    }

    const balanceAfter = balanceBefore - totalAmount;

    // ==========================================================
    // ALL WRITES AFTER
    // ==========================================================

    const walletTransactionRef = userRef.collection("walletTransactions").doc();

    transaction.set(walletTransactionRef, {
      type: "debit",
      source: "order_payment",
      status: "approved",
      amount: totalAmount,
      currency: "BDT",
      orderId: orderId,
      balanceBefore: balanceBefore,
      balanceAfter: balanceAfter,
      description: `Payment for BuyNova order ${orderId}`,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    transaction.update(userRef, {
      cashBalance: balanceAfter,
      walletBalance: balanceAfter,
      updatedAt: serverTimestamp(),
    });

    transaction.update(orderRef, {
      paymentStatus: "paid",
      paymentMethod: "BuyNova Wallet",
      walletPaid: true,
      walletTransactionId: walletTransactionRef.id,
      walletPaidAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    for (const sellerDoc of sellerOrdersSnapshot.docs) {
      transaction.update(sellerDoc.ref, {
        paymentStatus: "paid",
        paymentMethod: "BuyNova Wallet",
        walletTransactionId: walletTransactionRef.id,
        updatedAt: serverTimestamp(),
      });
    }

    for (const resellerDoc of resellerOrdersSnapshot.docs) {
      transaction.update(resellerDoc.ref, {
        paymentStatus: "paid",
        paymentMethod: "BuyNova Wallet",
        walletTransactionId: walletTransactionRef.id,
        updatedAt: serverTimestamp(),
      });
    }

    const notificationRef = userRef.collection("notifications").doc();

    transaction.set(notificationRef, {
      title: "Payment Successful",
      message: `৳${totalAmount.toFixed(2)} was paid from your BuyNova Wallet for order ${orderId}.`,
      type: "order_payment",
      orderId: orderId,
      amount: totalAmount,
      currency: "BDT",
      read: false,
      createdAt: serverTimestamp(),
    });

    return {
      alreadyPaid: false,
      transactionId: walletTransactionRef.id,
      newBalance: balanceAfter,
      amountPaid: totalAmount,
    };
  });

  return {
    success: true,
    ...result,
  };
});


// ============================================================
// ORDER STATUS SYNC + WALLET REFUND ON CANCEL
// ============================================================
// When a seller_orders / reseller_orders document changes status:
//  1) If it became "cancelled" and the order was paid with the
//     BuyNova Wallet, the customer's share is refunded to the
//     wallet (once only).
//  2) The main "orders" document status is recalculated from all
//     of its seller / reseller sub-orders.

const STATUS_RANK = {
  placed: 0,
  confirmed: 1,
  processing: 2,
  shipped: 3,
  delivered: 4,
  returned: 5,
  refunded: 6,
};

function roundMoney(value) {
  return Math.round((Number(value) || 0) * 100) / 100;
}

function statusRank(status) {
  const rank = STATUS_RANK[status];
  return rank === undefined ? 0 : rank;
}

async function refundCancelledSubOrder(orderId, collectionName, subOrderId) {
  const orderRef = db.collection("orders").doc(orderId);
  const subRef = db.collection(collectionName).doc(subOrderId);

  await db.runTransaction(async (transaction) => {
    // ==========================================================
    // ALL READS FIRST
    // ==========================================================

    const orderSnap = await transaction.get(orderRef);
    if (!orderSnap.exists) return;

    const subSnap = await transaction.get(subRef);
    if (!subSnap.exists) return;

    const sellerOrdersSnap = await transaction.get(
      db.collection("seller_orders").where("orderId", "==", orderId)
    );

    const resellerOrdersSnap = await transaction.get(
      db.collection("reseller_orders").where("orderId", "==", orderId)
    );

    const order = orderSnap.data() || {};
    const sub = subSnap.data() || {};

    // Only wallet-paid orders are refunded to the wallet.
    const paymentStatus = String(order.paymentStatus || "");

    if (
      order.paymentMethod !== "BuyNova Wallet" ||
      (paymentStatus !== "paid" && paymentStatus !== "partially_refunded")
    ) {
      return;
    }

    const userId = order.userId || order.customerId;
    if (!userId) return;

    const userRef = db.collection("users").doc(userId);
    const userSnap = await transaction.get(userRef);
    if (!userSnap.exists) return;

    // Already refunded for this sub-order? (idempotency)
    const refundedIds = Array.isArray(order.refundedSubOrderIds)
      ? order.refundedSubOrderIds
      : [];

    const key = `${collectionName}:${subOrderId}`;
    if (refundedIds.includes(key)) return;

    // ==========================================================
    // CALCULATE REFUND
    // ==========================================================

    const orderSubtotal = Number(order.subtotal) || 0;
    const discount = Number(order.discount) || 0;
    const deliveryFee = Number(order.deliveryFee) || 0;
    const grandTotal = Number(order.grandTotal ?? order.total) || 0;

    const subBase =
      collectionName === "reseller_orders"
        ? Number(sub.sellingTotal) || 0
        : Number(sub.subtotal ?? sub.sellerSubtotal) || 0;

    // Spread any coupon discount proportionally over the sub-orders.
    let share = subBase;

    if (orderSubtotal > 0 && discount > 0) {
      share = subBase * (1 - Math.min(discount, orderSubtotal) / orderSubtotal);
    }

    const allSubOrders = [...sellerOrdersSnap.docs, ...resellerOrdersSnap.docs];

    const allCancelled =
      allSubOrders.length > 0 &&
      allSubOrders.every(
        (d) =>
          String((d.data() || {}).orderStatus || "").toLowerCase() ===
          "cancelled"
      );

    const alreadyRefundedTotal = Number(order.walletRefundedTotal) || 0;
    const deliveryAlreadyRefunded = order.deliveryFeeRefunded === true;
    const maxRefundable = roundMoney(grandTotal - alreadyRefundedTotal);

    let refundAmount = share;
    let refundsDeliveryFee = false;

    if (allCancelled && !deliveryAlreadyRefunded && deliveryFee > 0) {
      refundAmount += deliveryFee;
      refundsDeliveryFee = true;
    }

    // Last sub-order of a fully cancelled order: refund exactly what is left.
    if (allCancelled && refundedIds.length + 1 >= allSubOrders.length) {
      refundAmount = maxRefundable;
      refundsDeliveryFee = true;
    }

    refundAmount = roundMoney(refundAmount);

    if (refundAmount > maxRefundable) {
      refundAmount = maxRefundable;
    }

    if (refundAmount <= 0) return;

    const userData = userSnap.data() || {};

    const balanceBefore = Number(
      userData.cashBalance ?? userData.walletBalance ?? 0
    );

    if (!Number.isFinite(balanceBefore)) return;

    const balanceAfter = roundMoney(balanceBefore + refundAmount);
    const newRefundedTotal = roundMoney(alreadyRefundedTotal + refundAmount);
    const fullyRefunded = newRefundedTotal >= roundMoney(grandTotal) - 0.005;

    // ==========================================================
    // ALL WRITES AFTER
    // ==========================================================

    const walletTransactionRef = userRef.collection("walletTransactions").doc();

    transaction.set(walletTransactionRef, {
      type: "credit",
      source: "order_refund",
      status: "approved",
      amount: refundAmount,
      currency: "BDT",
      currencySymbol: "৳",
      userId: userId,
      orderId: orderId,
      subOrderId: subOrderId,
      subOrderCollection: collectionName,
      balanceBefore: balanceBefore,
      balanceAfter: balanceAfter,
      description: `Refund for cancelled order ${orderId}`,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    });

    transaction.update(userRef, {
      cashBalance: balanceAfter,
      walletBalance: balanceAfter,
      updatedAt: serverTimestamp(),
    });

    transaction.update(orderRef, {
      walletRefundedTotal: newRefundedTotal,
      refundedSubOrderIds: [...refundedIds, key],
      deliveryFeeRefunded: deliveryAlreadyRefunded || refundsDeliveryFee,
      paymentStatus: fullyRefunded ? "refunded" : "partially_refunded",
      updatedAt: serverTimestamp(),
    });

    transaction.update(subRef, {
      paymentStatus: "refunded",
      refundedAmount: refundAmount,
      updatedAt: serverTimestamp(),
    });

    const notificationRef = userRef.collection("notifications").doc();

    transaction.set(notificationRef, {
      title: "Order Refund",
      message: `৳${refundAmount.toFixed(2)} was refunded to your BuyNova Wallet for cancelled order ${orderId}.`,
      type: "order_refund",
      orderId: orderId,
      amount: refundAmount,
      currency: "BDT",
      read: false,
      isRead: false,
      createdAt: serverTimestamp(),
    });
  });
}

async function syncMainOrderStatus(orderId) {
  const orderRef = db.collection("orders").doc(orderId);

  const [orderSnap, sellerSnap, resellerSnap] = await Promise.all([
    orderRef.get(),
    db.collection("seller_orders").where("orderId", "==", orderId).get(),
    db.collection("reseller_orders").where("orderId", "==", orderId).get(),
  ]);

  if (!orderSnap.exists) return;

  const statuses = [...sellerSnap.docs, ...resellerSnap.docs].map((d) =>
    String((d.data() || {}).orderStatus || "placed").toLowerCase()
  );

  if (statuses.length === 0) return;

  const active = statuses.filter((s) => s !== "cancelled");

  let newStatus = "cancelled";

  if (active.length > 0) {
    newStatus = active.reduce(
      (lowest, s) => (statusRank(s) < statusRank(lowest) ? s : lowest),
      active[0]
    );
  }

  const currentStatus = String(
    (orderSnap.data() || {}).orderStatus || "placed"
  ).toLowerCase();

  if (currentStatus === newStatus) return;

  await orderRef.update({
    orderStatus: newStatus,
    updatedAt: serverTimestamp(),
  });
}

async function handleSubOrderStatusChange(event, collectionName) {
  const before = event.data && event.data.before && event.data.before.data();
  const after = event.data && event.data.after && event.data.after.data();

  if (!before || !after) return null;

  const beforeStatus = String(before.orderStatus || "placed").toLowerCase();
  const afterStatus = String(after.orderStatus || "placed").toLowerCase();

  if (beforeStatus === afterStatus) return null;

  const orderId = after.orderId;
  const subOrderId = event.params.subOrderId;

  if (!orderId) return null;

  if (afterStatus === "cancelled") {
    try {
      await refundCancelledSubOrder(orderId, collectionName, subOrderId);
    } catch (error) {
      console.error(
        "Refund failed for",
        collectionName,
        subOrderId,
        "order",
        orderId,
        error
      );
    }
  }

  try {
    await syncMainOrderStatus(orderId);
  } catch (error) {
    console.error("Main order status sync failed for", orderId, error);
  }

  return null;
}

exports.onSellerOrderStatusChanged = onDocumentUpdated(
  "seller_orders/{subOrderId}",
  (event) => handleSubOrderStatusChange(event, "seller_orders")
);

exports.onResellerOrderStatusChanged = onDocumentUpdated(
  "reseller_orders/{subOrderId}",
  (event) => handleSubOrderStatusChange(event, "reseller_orders")
);
