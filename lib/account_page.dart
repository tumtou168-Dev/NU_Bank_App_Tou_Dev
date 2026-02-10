import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'button_nav_bar.dart';

const Color primaryBlue = Color(0xFF1E3A8A);
const Color secondaryBlue = Color(0xFF4C1D95);

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  int _selectedNavIndex = 4;

  void _onNavItemTapped(int index) {
    switch (index) {
      case 0: //Navigate to home
        Navigator.pushNamed(context, '/home');
        break;
      case 1: //Navigate to analytics page
        setState(() {
          _selectedNavIndex = index;
        });
        break;
      case 2: //Navigate to QR page
        Navigator.pushNamed(context, '/qr_payment');
        break;
      case 3: //Navigate to cards page
        setState(() {
          _selectedNavIndex = index;
        });
        break;
      case 4: // Currently in account page
        setState(() {
          _selectedNavIndex = index;
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: const _AccountPageContent(),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedNavIndex,
        onItemTapped: _onNavItemTapped,
      ),
      floatingActionButton: CustomFloatingActionButton(
        onPressed: () => _onNavItemTapped(2),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _AccountPageContent extends StatelessWidget {
  const _AccountPageContent();

  Future<Map<String, dynamic>?> _fetchUserData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return docSnapshot.data();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryBlue),
          );
        }

        final userData = snapshot.data;
        final name = userData?['name'] ?? 'User';

        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildProfileSection(name),
              const SizedBox(height: 20),
              _buildSpendingOverview(),
              const SizedBox(height: 20),
              _buildInviteFriends(),
              const SizedBox(height: 20),
              _builMenuList(context),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'My Account',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.grid_view, color: primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(String name) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.topRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(Icons.person, size: 60, color: Colors.white),
        ),

        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpendingOverview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Overview',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                '\$12,521.10',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'From \$20,000.00',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 15),

          //Progress Bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.35,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                child: FractionallySizedBox(
                  widthFactor: 0.75,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSpendingCategory(
                Colors.black87,
                'Subscription',
                '\$8,221.00',
              ),
              _buildSpendingCategory(
                primaryBlue,
                'Friend & Family',
                '\$4,300.10',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingCategory(Color color, String label, String amount) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInviteFriends() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBlue, secondaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invite Friends',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    children: [
                      TextSpan(
                        text:
                            'Invate your friends to manageing\ntheir finances and get',
                      ),
                      TextSpan(
                        text: '\$100',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextSpan(text: 'each'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.group_add, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _builMenuList(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            iconColor: primaryBlue,
            title: 'My Account',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.receipt_long_outlined,
            iconColor: primaryBlue,
            title: 'Transaction History',
            onTap: () {
              Navigator.pushNamed(context, '/transactions');
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.security_outlined,
            iconColor: primaryBlue,
            title: 'Security Settings',
            onTap: () {},
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.settings_outlined,
            iconColor: primaryBlue,
            title: 'Genaral Settings',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, color: Colors.grey[200]),
    );
  }
}
