import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

class AddTransactionScreen extends StatelessWidget {
  const AddTransactionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Transaction Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      color: AppColors.expenseContainerLight,
                      borderColor: AppColors.expense.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Expense Form will be built in Milestone 5')),
                        );
                      },
                      child: const Column(
                        children: [
                          Icon(Icons.arrow_upward_rounded, color: AppColors.expense, size: 28),
                          SizedBox(height: 8),
                          Text(
                            'Expense (-)',
                            style: TextStyle(
                              color: AppColors.expense,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppCard(
                      color: AppColors.creditContainerLight,
                      borderColor: AppColors.credit.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Credit/Income Form will be built in Milestone 5')),
                        );
                      },
                      child: const Column(
                        children: [
                          Icon(Icons.arrow_downward_rounded, color: AppColors.credit, size: 28),
                          SizedBox(height: 8),
                          Text(
                            'Income (+)',
                            style: TextStyle(
                              color: AppColors.credit,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              AppButton(
                label: 'Close',
                type: AppButtonType.outlined,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
