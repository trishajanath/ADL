import 'package:flutter/material.dart';
import 'package:my_app/models/expense.dart';
import 'package:my_app/projects_service.dart';

class ExpenseTracker extends StatelessWidget {
  final double budget;
  final List<Expense> expenses;

  const ExpenseTracker({
    super.key,
    required this.budget,
    required this.expenses,
  });

  @override
  Widget build(BuildContext context) {
    final double totalSpent = expenses.fold(0, (sum, item) => sum + item.amount);
    final double remaining = budget - totalSpent;
    final double spentPercentage = budget > 0 ? totalSpent / budget : 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBudgetBar(spentPercentage, context),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoTile('Budget', ProjectsService.formatCurrency(budget), Colors.blue),
                _buildInfoTile('Spent', ProjectsService.formatCurrency(totalSpent), Colors.red),
                _buildInfoTile('Remaining', ProjectsService.formatCurrency(remaining), Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetBar(double percentage, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: percentage,
          minHeight: 10,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage > 1.0 ? Colors.red : (percentage > 0.8 ? Colors.orange : Colors.green),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(percentage * 100).toStringAsFixed(1)}% of budget used',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
