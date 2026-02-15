import 'package:flutter/material.dart';

const Color primaryBlue = Color(0xFF1E3A8A);
const Color secondaryBlue = Color(0xFF4C1D95);

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool twoFactorAuth = false;
  bool biometricAuth = false;
  bool pinAuth = false;
  bool securityQuestions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeader(),
            const SizedBox(height: 30),
            _buildSecurityOptions(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.security, color: primaryBlue, size: 40),
        ),
        const SizedBox(height: 15),
        const Text(
          'Security Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityOptions() {
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
          _buildSecurityItem(
            icon: Icons.lock_outline,
            iconColor: primaryBlue,
            title: 'Change Password',
            subtitle: 'Update your password to ensure\nyour account is secure',
            hasSwitch: false,
            onTap: () {
              Navigator.pushNamed(context, '/change_password');
            },
          ),
          _buildDivider(),
          _buildSecurityItem(
            icon: Icons.pin_outlined,
            iconColor: primaryBlue,
            title: 'PIN Security',
            subtitle:
                'Set up a PIN code for quick and\nsecure access to your account',
            hasSwitch: true,
            switchValue: pinAuth,
            onSwitchChanged: (value) {
              setState(() {
                pinAuth = value;
              });
            },
          ),
          _buildDivider(),
          _buildSecurityItem(
            icon: Icons.verified_user_outlined,
            iconColor: primaryBlue,
            title: 'Two-FactorAuthentication',
            subtitle:
                'Enhance the security of your account\nby requiring a second form of verification',
            hasSwitch: true,
            switchValue: twoFactorAuth,
            onSwitchChanged: (value) {
              setState(() {
                twoFactorAuth = value;
              });
            },
          ),
          _buildDivider(),
          _buildSecurityItem(
            icon: Icons.fingerprint,
            iconColor: primaryBlue,
            title: 'Biometric Authentication',
            subtitle:
                'Use your device\'s biometric for a quick\nand secure login',
            hasSwitch: true,
            switchValue: biometricAuth,
            onSwitchChanged: (value) {
              setState(() {
                biometricAuth = value;
              });
            },
          ),
          _buildDivider(),
          _buildSecurityItem(
            icon: Icons.question_answer_outlined,
            iconColor: primaryBlue,
            title: 'Security Questions',
            subtitle:
                'Add an extra layer of security by\nsetting up security questionss',
            hasSwitch: true,
            switchValue: securityQuestions,
            onSwitchChanged: (value) {
              setState(() {
                securityQuestions = value;
              });
            },
          ),
          _buildDivider(),
          _buildSecurityItem(
            icon: Icons.history,
            iconColor: primaryBlue,
            title: 'Login History',
            subtitle:
                'Log of all login attempts to your account,\nincluding successful and failed attempts',
            hasSwitch: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool hasSwitch,
    bool switchValue = false,
    Function(bool)? onSwitchChanged,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: hasSwitch ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (hasSwitch)
              Switch(
                value: switchValue,
                onChanged: onSwitchChanged,
                activeColor: Colors.white,
                activeTrackColor: primaryBlue,
                inactiveTrackColor: Colors.grey[300],
              )
            else
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
