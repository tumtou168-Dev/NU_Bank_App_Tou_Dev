import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 2. DESIGN CONSTANTS
const Color primaryBlue = Colors.blue;
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
    setState(() {
      _selectedIndex = index;
    });
    debugPrint('Navigation Item Tapped: $index');
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

      bottomNavigationBar: _builBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  //Bottom navigation bar
  Widget _builBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        color: Colors.white,
        elevation: 0,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              _buildNavItem(Icons.wallet, 'Account', 1),
              const SizedBox(width: 40), // Space for FAB
              _buildNavItem(Icons.folder, 'Apply', 3),
              _buildNavItem(Icons.more_horiz, 'More', 4),
            ],
          ),
        ),
      ),
    );
  }

  //Build indivadual navigation items
  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? primaryBlue : Colors.grey;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Floating Action Button
  Widget _buildFloatingActionButton() {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [primaryBlue, secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: secondaryBlue, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => _onItemTapped(2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
      ),
    );
  }
}

/// 4. PAGE CONTENT LAYOUT
class _HomePageContent extends StatelessWidget {
  const _HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          HeaderSection(),
          BankCardWidget(),
          ActionGridSection(),
          TransactionHistorySection(),
        ],
      ),
    );
  }
}

///5. HEADER SECTION
//  Top section gradient background and greeting
class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

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
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            _buildCircleIcon(Icons.chat_bubble_outline),
            const SizedBox(width: 8),
            _buildCircleIcon(Icons.notifications_none),
            const SizedBox(width: 8),
            _buildCircleIconWithAction(Icons.logout, () async {
              await FirebaseAuth.instance.signOut();
            }),
          ],
        ),
      ],
    );
  }

  // Circular icon button
  Widget _buildCircleIcon(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.3),
      ),
      padding: const EdgeInsets.all(8),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  // Circular icon button with action
  Widget _buildCircleIconWithAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.3),
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
          children: const [
            Text(
              'Good morning,',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              'Mr ALex',
              style: TextStyle(
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
  const BankCardWidget({super.key});

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
          _buildCartDetail(),
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
          '\$1,234,50',
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
    return const Text(
      '**** **** **** 1234',
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 4,
      ),
    );
  }

  Widget _buildCartDetail() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Card Holder',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'Alex',
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          _buildSectionHeader(),
          const SizedBox(height: 10),
          Column(children: List.generate(5, (index) => const TransactionRow())),
        ],
      ),
    );
  }
}

// Section header with See All button
Widget _buildSectionHeader() {
  return Row(
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
        onPressed: () {},
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
  );
}

// Single Transaction row with skeleton loading effect
class TransactionRow extends StatelessWidget {
  const TransactionRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          //_builtIconPlaceholder(),
          const SizedBox(width: 15),
          _buildDetailsPlaceholder(),
          const SkeletonContainer(width: 70, height: 16, radius: 4),
        ],
      ),
    );
  }
}

// Transaction icon placeholder
Widget _builtIconPlaceholder() {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.2),
          spreadRadius: 1,
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    // child:  const SkeletonContainer(width: 24, height: 24, radius: 4),
  );
}

//Transaction details placehoder(title & category)
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
