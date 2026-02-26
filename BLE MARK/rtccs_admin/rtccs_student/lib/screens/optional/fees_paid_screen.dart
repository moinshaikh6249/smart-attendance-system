import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/optional/fees_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/module_availability_service.dart';
import '../../services/module_error_handler.dart';

class FeesPaidScreen extends StatelessWidget {
  const FeesPaidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final schoolId = profileProvider.student?.schoolId;

    return ModuleAvailabilityService.moduleGuard(
      moduleName: 'feesPaid',
      schoolId: schoolId,
      child: const _FeesPaidContent(),
    );
  }
}

class _FeesPaidContent extends StatefulWidget {
  const _FeesPaidContent();

  @override
  State<_FeesPaidContent> createState() => _FeesPaidContentState();
}

class _FeesPaidContentState extends State<_FeesPaidContent> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFees();
  }

  Future<void> _loadFees() async {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final feesProvider = Provider.of<FeesProvider>(context, listen: false);
    
    final student = profileProvider.student;
    if (student == null || student.schoolId == null) {
      setState(() => _isLoading = false);
      return;
    }

    await feesProvider.fetchFees(
      schoolId: student.schoolId!,
      studentUUID: student.uuid,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1F3A),
      appBar: AppBar(
        title: Text('Fees Payment', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
      ),
      body: _isLoading
          ? ModuleErrorHandler.buildLoadingState(message: 'Loading fee information...')
          : Consumer<FeesProvider>(
              builder: (context, provider, child) {
                if (provider.error != null) {
                  return ModuleErrorHandler.buildErrorState(
                    moduleName: 'feesPaid',
                    error: provider.error!,
                    onRetry: _loadFees,
                  );
                }

                if (provider.feeInfo == null) {
                  return ModuleErrorHandler.buildEmptyState(
                    moduleName: 'feesPaid',
                    icon: Icons.account_balance_wallet,
                    message: 'No Fee Information',
                  );
                }

                final feeInfo = provider.feeInfo!;
                return RefreshIndicator(
                  onRefresh: _loadFees,
                  color: Colors.white,
                  backgroundColor: Colors.blue.shade700,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cache/offline indicator
                        if (provider.isFromCache || (provider.error != null && feeInfo != null))
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade900.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade700.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.wifi_off, size: 16, color: Colors.orange.shade300),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    provider.error ?? 'Showing cached fee information. Pull to refresh.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.orange.shade200,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        _buildSummaryCard(feeInfo),
                        const SizedBox(height: 24),
                        
                        // Fee Components Section
                        if (feeInfo.feeComponents.isNotEmpty) ...[
                          _buildFeeComponentsSection(feeInfo.feeComponents),
                          const SizedBox(height: 24),
                        ],
                        
                        _buildPaymentHistory(feeInfo.payments),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSummaryCard(FeeInfo feeInfo) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.blue.shade700,
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Fee Summary',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Progress indicator
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: feeInfo.paidPercentage / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${feeInfo.paidPercentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Paid',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Fee breakdown
            _buildFeeRow('Total Fee', feeInfo.totalFee, currencyFormat, isTotal: true),
            const Divider(color: Colors.white24, height: 24),
            _buildFeeRow('Paid Amount', feeInfo.paidAmount, currencyFormat, color: Colors.green.shade300),
            const SizedBox(height: 8),
            _buildFeeRow('Pending Amount', feeInfo.pendingAmount, currencyFormat, color: Colors.orange.shade300),
            
            if (feeInfo.nextDueDate != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Next Due: ${DateFormat('dd MMM yyyy').format(feeInfo.nextDueDate!)}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeeComponentsSection(List<dynamic> components) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.blue.shade400, size: 20),
              const SizedBox(width: 8),
              Text(
                'Fee Breakdown',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...components.map((component) => _buildFeeComponentCard(component)),
      ],
    );
  }

  Widget _buildFeeComponentCard(dynamic component) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    // Get status color
    Color statusColor;
    IconData statusIcon;
    switch (component.status.toLowerCase()) {
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'partially paid':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'overdue':
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.schedule;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF242B3D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Fee Type and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    component.feeType,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        component.status,
                        style: GoogleFonts.poppins(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Amount breakdown
            Row(
              children: [
                Expanded(
                  child: _buildAmountColumn(
                    'Payable',
                    component.amountPayable,
                    currencyFormat,
                    Colors.blue.shade300,
                  ),
                ),
                Expanded(
                  child: _buildAmountColumn(
                    'Paid',
                    component.amountPaid,
                    currencyFormat,
                    Colors.green.shade300,
                  ),
                ),
                Expanded(
                  child: _buildAmountColumn(
                    'Due',
                    component.dueAmount,
                    currencyFormat,
                    Colors.orange.shade300,
                  ),
                ),
              ],
            ),
            
            // Additional info
            if (component.lastPaymentDate != null || component.dueDate != null) ...[
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF3A4050), height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (component.lastPaymentDate != null)
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.payment, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Last: ${DateFormat('dd MMM yy').format(component.lastPaymentDate)}',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (component.dueDate != null)
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.event, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Due: ${DateFormat('dd MMM yy').format(component.dueDate)}',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmountColumn(String label, double amount, NumberFormat format, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey.shade400,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          format.format(amount),
          style: GoogleFonts.poppins(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFeeRow(String label, double amount, NumberFormat format, {Color? color, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: color ?? Colors.white,
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          format.format(amount),
          style: GoogleFonts.poppins(
            color: color ?? Colors.white,
            fontSize: isTotal ? 20 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentHistory(List<PaymentRecord> payments) {
    if (payments.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF242B3D),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No payment history',
              style: GoogleFonts.poppins(color: Colors.grey.shade400),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment History',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...payments.map((payment) => _buildPaymentCard(payment)),
      ],
    );
  }

  Widget _buildPaymentCard(PaymentRecord payment) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF242B3D),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade700,
          child: const Icon(Icons.check, color: Colors.white),
        ),
        title: Text(
          currencyFormat.format(payment.amount),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(payment.date),
              style: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getModeColor(payment.mode).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    payment.mode.toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: _getModeColor(payment.mode),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (payment.transactionId != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    payment.transactionId!,
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: payment.receiptUrl != null
            ? IconButton(
                icon: const Icon(Icons.download, color: Colors.blue),
                onPressed: () {
                  // TODO: Download receipt
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Receipt download coming soon')),
                  );
                },
              )
            : null,
      ),
    );
  }

  Color _getModeColor(String mode) {
    switch (mode.toLowerCase()) {
      case 'online':
        return Colors.blue;
      case 'cash':
        return Colors.green;
      case 'cheque':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
