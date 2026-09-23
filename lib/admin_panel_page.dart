rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // =====================================================
    // HELPER FUNCTIONS
    // =====================================================

    function signedIn() {
      return request.auth != null;
    }

    function isAdmin() {
      return signedIn()
        && request.auth.token.email == 'miamdarif010@gmail.com';
    }

    function isOwner(uid) {
      return signedIn()
        && request.auth.uid == uid;
    }

    // =====================================================
    // USERS
    // =====================================================

    match /users/{userId} {

      allow read:
        if isOwner(userId) || isAdmin();

      allow create:
        if isOwner(userId);

      allow update: if isAdmin()
        || (
          isOwner(userId)

          && request.resource.data
              .diff(resource.data)
              .affectedKeys()
              .hasOnly([
                'name',
                'phone',
                'profileImageUrl',
                'email',
                'updatedAt',
                'sellerStatus',
                'entrepreneurStatus',
                'sellerRequestedAt',
                'entrepreneurRequestedAt'
              ])

          // User can request seller status as pending only.
          && (
            !request.resource.data
              .diff(resource.data)
              .affectedKeys()
              .hasAny(['sellerStatus'])
            ||
            request.resource.data.sellerStatus == 'pending'
          )

          // User can request entrepreneur status as pending only.
          && (
            !request.resource.data
              .diff(resource.data)
              .affectedKeys()
              .hasAny(['entrepreneurStatus'])
            ||
            request.resource.data.entrepreneurStatus == 'pending'
          )
        );

      allow delete:
        if isAdmin();

      // ---------------- PAYMENT METHODS ----------------

      match /paymentMethods/{methodId} {
        allow read, write:
          if isOwner(userId) || isAdmin();
      }

      // ---------------- ADDRESSES ----------------
      // (used by checkout and the address book)

      match /addresses/{addressId} {
        allow read, write:
          if isOwner(userId) || isAdmin();
      }

      // ---------------- CART ----------------

      match /cart/{itemId} {
        allow read, write:
          if isOwner(userId) || isAdmin();
      }

      // ---------------- FAVORITES ----------------

      match /favorites/{productId} {
        allow read, create, delete:
          if isOwner(userId) || isAdmin();

        allow update:
          if false;
      }

      // ---------------- WALLET TRANSACTIONS ----------------

      match /walletTransactions/{transactionId} {

        allow read:
          if isOwner(userId) || isAdmin();

        // User can create ONLY a pending deposit or withdrawal request.
        allow create: if isOwner(userId)

          && request.resource.data.userId == userId
          && request.resource.data.status == 'pending'
          && request.resource.data.currency == 'BDT'
          && request.resource.data.currencySymbol == 'à§³'
          && request.resource.data.amount is number
          && request.resource.data.amount >= 100

          && (
            (
              request.resource.data.type == 'credit'
              && request.resource.data.source == 'deposit'
            )
            ||
            (
              request.resource.data.type == 'debit'
              && request.resource.data.source == 'withdrawal'
              && request.resource.data.withdrawalMethod is string
              && request.resource.data.withdrawalMethod
                  in ['bkash', 'nagad', 'rocket', 'bank']
              && request.resource.data.accountNumber is string
              && request.resource.data.accountNumber.size() >= 6
              && request.resource.data.accountNumber.size() <= 100
            )
          );

        allow update, delete:
          if isAdmin();
      }

      // ---------------- NOTIFICATIONS ----------------

      match /notifications/{notificationId} {

        allow read:
          if isOwner(userId) || isAdmin();

        allow create: if isAdmin()
          || (
            signedIn()
            && request.resource.data.customerId == userId
            && request.resource.data.sellerId == request.auth.uid
            && request.resource.data.orderId is string
            && request.resource.data.title is string
            && request.resource.data.message is string
            && request.resource.data.type is string
            && request.resource.data.orderStatus is string
            && request.resource.data.isRead == false
          );

        allow update: if isAdmin()
          || (
            isOwner(userId)
            && request.resource.data
                .diff(resource.data)
                .affectedKeys()
                .hasOnly(['isRead', 'readAt'])
            && request.resource.data.isRead == true
          );

        allow delete:
          if isAdmin();
      }
    }

    // =====================================================
    // WALLET TRANSACTIONS - COLLECTION GROUP ACCESS
    // =====================================================

    match /{path=**}/walletTransactions/{transactionId} {

      allow read:
        if isAdmin()
        || (
          signedIn()
          && resource.data.userId == request.auth.uid
        );

      allow create, update, delete:
        if false;
    }

    // =====================================================
    // PRODUCTS
    // =====================================================

    match /products/{productId} {

      allow read:
        if true;

      allow create: if signedIn()
        && request.resource.data.sellerId == request.auth.uid;

      allow update, delete: if isAdmin()
        || (
          signedIn()
          && resource.data.sellerId == request.auth.uid
        );
    }

    match /Products/{productId} {

      allow read:
        if true;

      allow write:
        if isAdmin();
    }

    // =====================================================
    // COUPONS (used by checkout)
    // =====================================================

    match /coupons/{couponId} {

      allow read:
        if signedIn();

      allow write:
        if isAdmin();
    }

    // =====================================================
    // VIDEOS
    // =====================================================

    match /videos/{videoId} {

      allow read:
        if true;

      allow create:
        if signedIn();

      allow update, delete:
        if isAdmin();
    }

    // =====================================================
    // SELLER VIDEOS
    // =====================================================

    match /sellerVideos/{videoId} {

      allow read:
        if true;

      allow create: if signedIn()
        && (
          request.resource.data.userId == request.auth.uid
          ||
          request.resource.data.sellerId == request.auth.uid
        );

      allow update, delete: if isAdmin()
        || (
          signedIn()
          && (
            resource.data.userId == request.auth.uid
            ||
            resource.data.sellerId == request.auth.uid
          )
        );

      match /likes/{uid} {

        allow read:
          if true;

        allow create: if signedIn()
          && request.auth.uid == uid;

        allow delete: if signedIn()
          && request.auth.uid == uid;

        allow update:
          if false;
      }

      match /comments/{commentId} {

        allow read:
          if true;

        allow create: if signedIn()
          && request.resource.data.userId == request.auth.uid;

        allow update: if isAdmin()
          || (
            signedIn()
            && resource.data.userId == request.auth.uid
          );

        allow delete: if isAdmin()
          || (
            signedIn()
            && resource.data.userId == request.auth.uid
          );
      }

      match /views/{uid} {

        allow read: if isAdmin()
          || (
            signedIn()
            && request.auth.uid == uid
          );

        allow create: if signedIn()
          && request.auth.uid == uid;

        allow update, delete:
          if isAdmin();
      }
    }

    // =====================================================
    // WATCH REWARD CLAIMS
    // =====================================================

    match /watchRewardClaims/{claimId} {

      allow read: if isAdmin()
        || (
          signedIn()
          && resource.data.userId == request.auth.uid
        );

      allow create: if signedIn()
        && request.resource.data.userId == request.auth.uid
        && request.resource.data.videoId is string
        && request.resource.data.status == 'pending'
        && request.resource.data.source == 'watch_video';

      allow update, delete:
        if isAdmin();
    }

    // =====================================================
    // RESELLER PRODUCTS
    // =====================================================

    match /reseller_products/{resellerProductId} {

      allow read: if signedIn()
        && (
          isAdmin()
          ||
          get(
            /databases/$(database)/documents/users/$(request.auth.uid)
          ).data.entrepreneurStatus == 'approved'
        );

      allow create: if signedIn()
        && request.resource.data.entrepreneurUid == request.auth.uid
        && get(
          /databases/$(database)/documents/users/$(request.auth.uid)
        ).data.entrepreneurStatus == 'approved';

      allow update, delete: if isAdmin()
        || (
          signedIn()
          && resource.data.entrepreneurUid == request.auth.uid
        );
    }

    // =====================================================
    // MAIN ORDERS
    // =====================================================

    match /orders/{orderId} {

      allow create: if signedIn()
        && request.resource.data.userId == request.auth.uid;

      allow read: if isAdmin()
        || (
          signedIn()
          && resource.data.userId == request.auth.uid
        );

      allow update, delete:
        if isAdmin();
    }

    // =====================================================
    // SELLER ORDERS
    // =====================================================

    match /seller_orders/{sellerOrderId} {

      // Customer creates seller order.
      allow create: if signedIn()
        && request.resource.data.customerId == request.auth.uid;

      allow read: if isAdmin()
        || (
          signedIn()
          && resource.data.sellerId == request.auth.uid
        )
        || (
          signedIn()
          && resource.data.customerId == request.auth.uid
        );

      allow update: if isAdmin()

        || (
          signedIn()
          && resource.data.sellerId == request.auth.uid
        )

        || (
          signedIn()
          && resource.data.customerId == request.auth.uid
          && resource.data.orderStatus
              in ['placed', 'confirmed', 'processing']
          && request.resource.data.orderStatus == 'cancelled'
          && request.resource.data
              .diff(resource.data)
              .affectedKeys()
              .hasOnly([
                'orderStatus',
                'cancelledBy',
                'cancelledAt',
                'updatedAt'
              ])
        );

      allow delete:
        if isAdmin();
    }

    // =====================================================
    // RETURN & REFUND REQUESTS
    // =====================================================

    match /return_refund_requests/{requestId} {

      allow create: if signedIn()
        && request.resource.data.customerId == request.auth.uid
        && request.resource.data.status == 'pending'
        && request.resource.data.requestType in ['return', 'refund']
        && request.resource.data.orderId is string
        && request.resource.data.sellerOrderId is string
        && request.resource.data.sellerId is string
        && request.resource.data.productId is string;

      allow read: if isAdmin()
        || (
          signedIn()
          && resource.data.customerId == request.auth.uid
        )
        || (
          signedIn()
          && resource.data.sellerId == request.auth.uid
        );

      allow update: if isAdmin()
        || (
          signedIn()
          && resource.data.sellerId == request.auth.uid
          && request.resource.data
              .diff(resource.data)
              .affectedKeys()
              .hasOnly([
                'status',
                'sellerMessage',
                'sellerNote',
                'updatedAt',
                'approvedAt',
                'rejectedAt',
                'completedAt'
              ])
        );

      allow delete:
        if isAdmin();
    }

    // =====================================================
    // PRODUCT REVIEWS
    // =====================================================

    match /product_reviews/{reviewId} {

      allow read:
        if true;

      allow create: if signedIn()
        && request.resource.data.userId == request.auth.uid
        && request.resource.data.productId is string
        && request.resource.data.productName is string
        && request.resource.data.rating is int
        && request.resource.data.rating >= 1
        && request.resource.data.rating <= 5
        && request.resource.data.review is string
        && request.resource.data.review.size() > 0
        && request.resource.data.review.size() <= 500;

      allow update: if signedIn()
        && resource.data.userId == request.auth.uid
        && request.resource.data.userId == resource.data.userId
        && request.resource.data.productId == resource.data.productId
        && request.resource.data
            .diff(resource.data)
            .affectedKeys()
            .hasOnly(['rating', 'review', 'updatedAt'])
        && request.resource.data.rating is int
        && request.resource.data.rating >= 1
        && request.resource.data.rating <= 5
        && request.resource.data.review is string
        && request.resource.data.review.size() > 0
        && request.resource.data.review.size() <= 500;

      allow delete: if isAdmin()
        || (
          signedIn()
          && resource.data.userId == request.auth.uid
        );
    }

    // =====================================================
    // CHAT / CONVERSATIONS
    // =====================================================

    match /conversations/{conversationId} {

      allow read: if isAdmin()
        || (
          signedIn()
          && (
            resource.data.buyerId == request.auth.uid
            ||
            resource.data.sellerId == request.auth.uid
          )
        );

      allow create: if signedIn()
        && request.resource.data.conversationId == conversationId
        && request.resource.data.buyerId is string
        && request.resource.data.sellerId is string
        && request.resource.data.buyerId != request.resource.data.sellerId
        && (
          request.resource.data.buyerId == request.auth.uid
          ||
          request.resource.data.sellerId == request.auth.uid
        )
        && request.resource.data.lastMessage is string
        && request.resource.data.buyerUnreadCount is int
        && request.resource.data.sellerUnreadCount is int
        && request.resource.data.buyerUnreadCount >= 0
        && request.resource.data.sellerUnreadCount >= 0;

      allow update: if isAdmin()
        || (
          signedIn()
          && (
            resource.data.buyerId == request.auth.uid
            ||
            resource.data.sellerId == request.auth.uid
          )
          && request.resource.data.buyerId == resource.data.buyerId
          && request.resource.data.sellerId == resource.data.sellerId
          && request.resource.data.conversationId
              == resource.data.conversationId
          && request.resource.data
              .diff(resource.data)
              .affectedKeys()
              .hasOnly([
                'sellerName',
                'buyerName',
                'lastMessage',
                'lastMessageAt',
                'buyerUnreadCount',
                'sellerUnreadCount',
                'updatedAt'
              ])
          && request.resource.data.buyerUnreadCount is int
          && request.resource.data.sellerUnreadCount is int
          && request.resource.data.buyerUnreadCount >= 0
          && request.resource.data.sellerUnreadCount >= 0
        );

      allow delete:
        if isAdmin();

      match /messages/{messageId} {

        allow read: if isAdmin()
          || (
            signedIn()
            && (
              get(
                /databases/$(database)/documents/conversations/$(conversationId)
              ).data.buyerId == request.auth.uid
              ||
              get(
                /databases/$(database)/documents/conversations/$(conversationId)
              ).data.sellerId == request.auth.uid
            )
          );

        allow create: if signedIn()
          && request.resource.data.senderId == request.auth.uid
          && request.resource.data.senderId is string
          && request.resource.data.receiverId is string
          && request.resource.data.senderId != request.resource.data.receiverId
          && (
            request.resource.data.senderId
              == get(
                /databases/$(database)/documents/conversations/$(conversationId)
              ).data.buyerId
            ||
            request.resource.data.senderId
              == get(
                /databases/$(database)/documents/conversations/$(conversationId)
              ).data.sellerId
          )
          && (
            request.resource.data.receiverId
              == get(
                /databases/$(database)/documents/conversations/$(conversationId)
              ).data.buyerId
            ||
            request.resource.data.receiverId
              == get(
                /databases/$(database)/documents/conversations/$(conversationId)
              ).data.sellerId
          )
          && request.resource.data.message is string
          && request.resource.data.message.size() > 0
          && request.resource.data.message.size() <= 5000
          && request.resource.data.isRead == false;

        allow update: if isAdmin()
          || (
            signedIn()
            && (
              get(
                /databases/$(database)/documents/conversations/$(conversationId)
              ).data.buyerId == request.auth.uid
              ||
              get(
                /databases/$(database)/documents/conversations/$(conversationId)
              ).data.sellerId == request.auth.uid
            )
            && request.resource.data
                .diff(resource.data)
                .affectedKeys()
                .hasOnly(['isRead', 'readAt'])
            && request.resource.data.isRead == true
          );

        allow delete:
          if isAdmin();
      }
    }

    // =====================================================
    // RESELLER / ENTREPRENEUR ORDERS
    // =====================================================

    match /reseller_orders/{resellerOrderId} {

      // Entrepreneur, the customer who bought, the supplier
      // (seller) who ships it, and admin can read.
      allow read: if isAdmin()
        || (
          signedIn()
          && resource.data.entrepreneurUid == request.auth.uid
        )
        || (
          signedIn()
          && resource.data.customerId == request.auth.uid
        )
        || (
          signedIn()
          && resource.data.sellerId == request.auth.uid
        );

      // Created either by the CUSTOMER at checkout, or by the
      // entrepreneur himself. Profit may be "resellerProfit" or "profit".
      allow create: if signedIn()
        && request.resource.data.orderStatus == 'placed'
        && request.resource.data.customerId is string
        && request.resource.data.sellerId is string
        && request.resource.data.entrepreneurUid is string
        && request.resource.data.items is list
        && request.resource.data.sellingTotal is number
        && request.resource.data.supplierTotal is number
        && (
          request.resource.data.resellerProfit is number
          || request.resource.data.profit is number
        )
        && (
          request.resource.data.customerId == request.auth.uid
          || request.resource.data.entrepreneurUid == request.auth.uid
        );

      allow update: if isAdmin()

        // Entrepreneur changes the order status.
        || (
          signedIn()
          && resource.data.entrepreneurUid == request.auth.uid
          && request.resource.data.entrepreneurUid
              == resource.data.entrepreneurUid
          && request.resource.data.customerId == resource.data.customerId
          && request.resource.data.sellerId == resource.data.sellerId
          && request.resource.data
              .diff(resource.data)
              .affectedKeys()
              .hasOnly(['orderStatus', 'updatedAt'])
          && request.resource.data.orderStatus
              in [
                'placed',
                'confirmed',
                'processing',
                'shipped',
                'delivered',
                'cancelled',
                'returned',
                'refunded'
              ]
        )

        // Customer cancels his own order before it ships.
        || (
          signedIn()
          && resource.data.customerId == request.auth.uid
          && resource.data.orderStatus
              in ['placed', 'confirmed', 'processing']
          && request.resource.data.orderStatus == 'cancelled'
          && request.resource.data
              .diff(resource.data)
              .affectedKeys()
              .hasOnly([
                'orderStatus',
                'cancelledBy',
                'cancelledAt',
                'updatedAt'
              ])
        );

      allow delete:
        if isAdmin();
    }

    // =====================================================
    // DEFAULT DENY
    // =====================================================

    match /{document=**} {

      allow read, write:
        if false;
    }
  }
}
