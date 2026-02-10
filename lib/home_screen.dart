import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'button_nav_bar.dart';

const Color primaryBlue = Color(0xFF1E3A8A);
const Color secondaryBlue = Color(0xFF4C1D95);

/// Data Model for grid buttons
class ActionItem {
  final IconData icon;
  final String label;
  final Color iconColor;

  const ActionItem({
    required this.icon,
    required this.label,
    required this.iconColor,
  });
}

// List of actions items displayed in the grid
const List<ActionItem> actionItems = [
  ActionItem(icon: Icons.sync_alt, label: 'Transfer', iconColor: primaryBlue),
  ActionItem(
    icon: Icons.wallet_outlined,
    label: 'Payment',
    iconColor: primaryBlue,
  ),
  ActionItem(
    icon: Icons.shopping_cart_outlined,
    label: 'Shop',
    iconColor: primaryBlue,
  ),
  ActionItem(icon: Icons.apps, label: 'Others', iconColor: primaryBlue),
];

/// 3. MAIN PAGE  STRUCTURE

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 2) {
      // Special case for QR payment screen
      Navigator.pushNamed(context, '/qr_payment');
    } else {
      // Handle navigation for other bottom bar items
      if (_selectedIndex != index) {
        setState(() {
          _selectedIndex = index;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: const _HomePageContent(),

      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      floatingActionButton: CustomFloatingActionButton(
        onPressed: () => _onItemTapped(2),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

/// 4. PAGE CONTENT LAYOUT (modified for data fetching)
class _HomePageContent extends StatefulWidget {
  const _HomePageContent();

  @override
  State<_HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<_HomePageContent> {
  bool _isEnsuringUserDoc = false;
  String? _firestoreStatusMessage;

  @override
  void initState() {
    super.initState();
    _ensureUserDocument();
  }

  String _deriveUserName(User user) {
    final displayName = user.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final email = user.email?.trim();
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'User';
  }

  String? _friendlyFirestoreError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Firestore permission denied. Ensure the Cloud Firestore API is enabled and security rules allow access.';
        case 'unavailable':
          return 'Firestore unavailable. Check your internet connection and ensure the Cloud Firestore API is enabled.';
      }

      final message = error.message ?? '';
      if (message.contains('Cloud Firestore API') ||
          message.contains('firestore.googleapis.com')) {
        return 'Cloud Firestore is disabled for this Firebase project. Enable it and try again.';
      }
    }

    final message = error.toString();
    if (message.contains('Cloud Firestore API') ||
        message.contains('firestore.googleapis.com')) {
      return 'Cloud Firestore is disabled for this Firebase project. Enable it and try again.';
    }

    return null;
  }

  Future<void> _ensureUserDocument() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final derivedName = _deriveUserName(user);

    try {
      final doc = await userRef.get();
      if (!doc.exists) {
        if (mounted) {
          setState(() {
            _isEnsuringUserDoc = true;
          });
        }

        await userRef.set({
          'uid': user.uid,
          if (user.email != null) 'email': user.email,
          'name': derivedName,
          'account_balance': 0.0,
          'card_number_suffix': '1234',
        });
      } else {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final updates = <String, dynamic>{};

        if (!data.containsKey('uid')) {
          updates['uid'] = user.uid;
        }
        if (!data.containsKey('email') && user.email != null) {
          updates['email'] = user.email;
        }
        final existingName = data['name'];
        final existingNameIsEmpty =
            existingName is! String || existingName.trim().isEmpty;
        if ((!data.containsKey('name') || existingNameIsEmpty) &&
            derivedName.isNotEmpty) {
          updates['name'] = derivedName;
        }
        if (!data.containsKey('card_number_suffix')) {
          updates['card_number_suffix'] = '1234';
        }

        if (updates.isNotEmpty) {
          await userRef.set(updates, SetOptions(merge: true));
        }
      }

      if (mounted) {
        setState(() {
          _firestoreStatusMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Failed to ensure Firestore user doc: $e');
      if (mounted) {
        setState(() {
          _firestoreStatusMessage =
              _friendlyFirestoreError(e) ?? 'Unable to connect to Firestore.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEnsuringUserDoc = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildContent(
        name: 'Guest',
        balance: '0.00',
        cardNumberSuffix: 'XXXX',
      );
    }

    // Use StreamBuilder to fetch data in real-time
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        // headle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: CircularProgressIndicator(color: primaryBlue),
            ),
          );
        }

        final statusMessage = snapshot.hasError
            ? (_firestoreStatusMessage ??
                  (snapshot.error != null
                      ? (_friendlyFirestoreError(snapshot.error!) ??
                            'Unable to connect to Firestore.')
                      : 'Unable to connect to Firestore.'))
            : _firestoreStatusMessage;

        // handle error/no data state
        if (snapshot.hasError) {
          debugPrint('Firestore Error: ${snapshot.error}');
          return _buildContent(
            name: user.displayName ?? _deriveUserName(user),
            balance: '0.00',
            cardNumberSuffix: '1234',
            firestoreStatusMessage: statusMessage,
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          debugPrint('Document does not exist for UID: ${user.uid}');
          // Fallback to FirebaseAuth display name if Firestore document is missing
          return _buildContent(
            name: user.displayName ?? _deriveUserName(user),
            balance: '0.00',
            cardNumberSuffix: '1234',
            firestoreStatusMessage: _isEnsuringUserDoc
                ? 'Setting up your account...'
                : statusMessage,
          );
        }

        // Extract data safely when available
        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        // Default to a safe value if the field is missing
        final name = userData['name'] ?? user.displayName ?? 'User';
        // Format balance to 2 decimal places, default is '0.00'
        final balance = (userData['account_balance'] is num)
            ? (userData['account_balance'] as num).toStringAsFixed(2)
            : '0.00';
        final cardNumberSuffix =
            userData['card_number_suffix']?.toString() ?? '1234';

        // Build content, passing dynamic data
        return _buildContent(
          name: name,
          balance: balance,
          cardNumberSuffix: cardNumberSuffix,
          firestoreStatusMessage: statusMessage,
        );
      },
    );
  }

  // Helper method to build the main scrollable content
  Widget _buildContent({
    required String name,
    required String balance,
    required String cardNumberSuffix,
    String? firestoreStatusMessage,
  }) {
    return SingleChildScrollView(
      child: Column(
        children: [
          //Pass dynamic data to children
          HeaderSection(name: name),
          if (firestoreStatusMessage != null)
            _FirestoreStatusBanner(message: firestoreStatusMessage),
          BankCardWidget(
            name: name,
            balance: balance,
            cardNumberSuffix: cardNumberSuffix,
          ),
          ActionGridSection(),
          TransactionHistorySection(),
        ],
      ),
    );
  }
}

class _FirestoreStatusBanner extends StatelessWidget {
  final String message;

  const _FirestoreStatusBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[800], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

///5. HEADER SECTION
//  Top section gradient background and greeting
class HeaderSection extends StatelessWidget {
  final String name; //new paramater for dynamic data
  const HeaderSection({super.key, required this.name}); // Updated constructor

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          height: 150,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [secondaryBlue, primaryBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Content Overlay
        Padding(
          padding: const EdgeInsetsGeometry.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildGreeting(),
            ],
          ),
        ),
      ],
    );
  }

  // App bar with title and action icons
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'ABC Bank',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            _buildCircleIcon(Icons.chat_bubble_outline),
            const SizedBox(width: 8),
            _buildCircleIconWithAction(Icons.logout, () async {
              await FirebaseAuth.instance.signOut();
            }),
          ],
        ),
      ],
    );
  }

  // Circular icon button with action
  Widget _buildCircleIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // Circular icon button with action
  Widget _buildCircleIconWithAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // User greeting section
  Widget _buildGreeting() {
    return Row(
      children: [
        const Icon(Icons.lock_outline, color: Colors.white, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good morning,',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

///6. BANK CARD WIDGET
class BankCardWidget extends StatelessWidget {
  final String name;
  final String balance;
  final String cardNumberSuffix;

  const BankCardWidget({
    super.key,
    required this.name,
    required this.balance,
    required this.cardNumberSuffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(20),
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [secondaryBlue, primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCardTop(),
          _buildBalanceDisplay(),
          _buildCardNumber(),
          _buildCardDetail(),
        ],
      ),
    );
  }

  Widget _buildCardTop() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(Icons.credit_card, size: 40, color: Colors.yellow[800]),
        Text(
          'VISA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                blurRadius: 5,
                color: Colors.black45,
                offset: Offset(1, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Balance',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        SizedBox(height: 4),
        Text(
          '\$$balance',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCardNumber() {
    return Text(
      '**** **** **** $cardNumberSuffix',
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 4,
      ),
    );
  }

  Widget _buildCardDetail() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card Holder',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              name.toUpperCase(),
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            Text(
              'Expires',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              '12/26',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

///7. ACTION GRID
class ActionGridSection extends StatelessWidget {
  const ActionGridSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What would you like to do today?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 15),
            GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.8,
              children: actionItems
                  .map((item) => ActionButton(item: item))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

//individual actionbutton in the grid
class ActionButton extends StatelessWidget {
  final ActionItem item;

  const ActionButton({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        debugPrint('Tapped ${item.label}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, color: item.iconColor, size: 30),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

///8. TRANSACTION HISTORY SECTION
class TransactionHistorySection extends StatelessWidget {
  const TransactionHistorySection({super.key});

  Stream<QuerySnapshot> _getTransactionsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Don't show transaction history if user is not logged in
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          _buildSectionHeader(context),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: _getTransactionsStream(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  children: List.generate(3, (index) => const _TransactionRowSkeleton()),
                );
              }
              if (snapshot.hasError) {
                debugPrint('Transaction error: ${snapshot.error}');
                return Container(
                  padding: const EdgeInsetsGeometry.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[300],
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Error loading transactions',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${snapshot.error}',
                        style: TextStyle(color: Colors.grey[300], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsetsGeometry.all(30),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        'No transactions yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      )
                    ],
                  ),
                );
              }
              final transactions = snapshot.data!.docs;

              return Column(
                children: transactions.take(5).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return TransactionRow(
                    type: data['type'] ?? 'debit',
                    description: data['description'] ?? 'Transaction',
                    category: data['category'] ?? 'General',
                    amount: (data['amount'] ?? 0.0).toDouble(),
                    timestamp: (data['timestamp'] as Timestamp?) ?? Timestamp.now(),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Section header with See All button
  Widget _buildSectionHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Transaction History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/transaction');
            },
            child: const Text(
              'See All',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// Transaction row with real data
class TransactionRow extends StatelessWidget {
  final String type;
  final String description;
  final String category;
  final double amount;
  final Timestamp timestamp;

  const TransactionRow({
    super.key,
    required this.type,
    required this.description,
    required this.category,
    required this.amount,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final isDebit = type == 'debit';
    final icon = isDebit ? Icons.arrow_upward : Icons.arrow_downward;
    final iconColor = isDebit ? Colors.red : Colors.green;
    final amountText = '${isDebit ? '-' : '+'}\$${amount.toStringAsFixed(2)}';
    final amountColor = isDebit ? Colors.red : Colors.green;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          _buildIcon(icon, iconColor),
          const SizedBox(width: 15),
          _buildDetails(description, category),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildDetails(String title, String subtitle) {
    return Expanded(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        )
      ],
    ));
  }
}

// Single Transaction row with skeleton loading effect
class _TransactionRowSkeleton extends StatelessWidget {
  const _TransactionRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          _buildIconPlaceholder(),
          const SizedBox(width: 15),
          _buildDetailsPlaceholder(),
          const SkeletonContainer(width: 70, height: 16, radius: 4),
        ],
      ),
    );
  }
}

// Transaction icon placeholder
Widget _buildIconPlaceholder() {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
    child: const SkeletonContainer(width: 24, height: 24, radius: 4),
  );
}

//Transaction details placeholder(title & category)
Widget _buildDetailsPlaceholder() {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonContainer(width: 120, height: 16, radius: 4),
        SizedBox(height: 5),
        SkeletonContainer(width: 80, height: 16, radius: 4),
      ],
    ),
  );
}

/// 9. Utility Widget
class SkeletonContainer extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonContainer({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
