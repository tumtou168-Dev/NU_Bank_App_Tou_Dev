import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

const Color primaryBlue = Color(0xFF1E3A8A);
const Color secondaryBlue = Color(0xFF4C1D95);

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String _filterType = 'all';

  Stream<QuerySnapshot> _getTransactionsStream(String userId) {
    Query query = FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true);

    // Apply filter if not all
    if (_filterType != 'all') {
      query = query.where('type', isEqualTo: _filterType);
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Transaction History'),
          backgroundColor: primaryBlue,
        ),
        body: const Center(child: Text('Please log in to view transactions')),
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Transaction History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryBlue,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterButtons(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getTransactionsStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[300],
                          size: 60,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Error loading transactions',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'No transactions found',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your transactions will appear here',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final transactions = snapshot.data!.docs;

                // sort transactions by timestamp (newest first)
                transactions.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTimestamp = aData['timestamp'] as Timestamp?;
                  final bTimestamp = bData['timestamp'] as Timestamp?;

                  if (aTimestamp == null) return 1;
                  if (bTimestamp == null) return -1;

                  return bTimestamp.compareTo(aTimestamp);
                });
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, indeX) {
                    final doc = transactions[indeX];
                    final data = doc.data() as Map<String, dynamic>;

                    return TransactionCard(
                      transactionId: doc.id,
                      type: data['type'] ?? 'debit',
                      description: data['description'] ?? 'Transaction',
                      category: data['category'] ?? 'General',
                      amount: (data['amount'] ?? 0.0).toDouble(),
                      timestamp: data['timestamp'] as Timestamp?,
                      note: data['note'],
                      recipient: data['recipient'],
                      sender: data['sender'],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: _buildFilterButton('All', 'all')),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterButton('Sent', 'debit')),
          const SizedBox(width: 10),
          Expanded(child: _buildFilterButton('Receive', 'credit')),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _filterType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _filterType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

//Transaction Card widget
class TransactionCard extends StatelessWidget {
  final String transactionId;
  final String type;
  final String description;
  final String category;
  final double amount;
  final Timestamp? timestamp;
  final String? note;
  final String? recipient;
  final String? sender;

  const TransactionCard({
    super.key,
    required this.transactionId,
    required this.type,
    required this.description,
    required this.category,
    required this.amount,
    this.timestamp,
    this.note,
    this.recipient,
    this.sender,
  });

  @override
  Widget build(BuildContext context) {
    final isDebit = type == 'debit';
    final icon = isDebit ? Icons.arrow_upward : Icons.arrow_downward;
    final iconColor = isDebit ? Colors.red : Colors.green;
    final amountText = '${isDebit ? '-' : '+'}\$${amount.toStringAsFixed(2)}';
    final amountColor = isDebit ? Colors.red : Colors.green;

    String formattedDate = 'Unknown Date';
    if (timestamp != null) {
      final date = timestamp!.toDate();
      formattedDate = DateFormat('MMM dd, yyyy. hh:mm a').format(date);
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.circular(15),
      ),
      child: InkWell(
        onTap: () {
          _showTransactionDetails(context);
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: iconColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    if (note != null && note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        note!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(BuildContext context) {
    final isDebit = type == 'debit';
    final iconColor = isDebit ? Colors.red : Colors.green;
    final amountText = '${isDebit ? '-' : '+'}\$${amount.toStringAsFixed(2)}';
    final amountColor = isDebit ? Colors.red : Colors.green;

    String formattedDate = 'Unknown Date';
    String formattedTime = '';
    if (timestamp != null) {
      final date = timestamp!.toDate();
      formattedDate = DateFormat('EEEE, MMMM, dd, yyyy').format(date);
      formattedTime = DateFormat('hh:mm a').format(date);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsetsGeometry.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                    color: iconColor,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),

                // Amount
                Text(
                  amountText,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
                const SizedBox(height: 8),

                //Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Completed',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Deatail
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Transaction Type',
                        isDebit ? 'Sent' : 'Received',
                        Icons.swap_horiz,
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Description',
                        description,
                        Icons.description_outlined,
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Category',
                        category,
                        Icons.category_outlined,
                      ),
                      if (recipient != null) ...[
                        const Divider(height: 24),
                        _buildDetailRow(
                          'Recipient',
                          recipient!,
                          Icons.percent_outlined,
                        ),
                      ],
                      if (sender != null) ...[
                        const Divider(height: 24),
                        _buildDetailRow(
                          'Sender',
                          sender!,
                          Icons.percent_outlined,
                        ),
                      ],

                      const Divider(height: 24),
                      _buildDetailRow(
                        'Date',
                        formattedDate,
                        Icons.calendar_today,
                      ),
                      const Divider(height: 24),
                      _buildDetailRow('Time', formattedTime, Icons.access_time),
                      if (note != null && note!.isNotEmpty) ...[
                        const Divider(height: 24),
                        _buildDetailRow('Note', note!, Icons.note_outlined),
                      ],
                      const Divider(height: 24),
                      _buildDetailRow(
                        'Transaction ID',
                        transactionId.substring(0, 16) + '...',
                        Icons.tag,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
