import 'package:flutter/material.dart';
import 'package:my_app/models/expense.dart';
import 'package:my_app/projects_service.dart';

class ExpenseList extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseList({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              child: Text(
                'Recent Expenses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            if (expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('No expenses logged yet.')),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(_getIconForCategory(expense.category)),
                    ),
                    title: Text(expense.description),
                    subtitle: Text(expense.category),
                    trailing: Text(
                      ProjectsService.formatCurrency(expense.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'materials':
        return Icons.build;
      case 'labor':
        return Icons.person;
      case 'permits':
        return Icons.description;
      case 'equipment':
        return Icons.construction;
      default:
        return Icons.receipt_long;
    }
  }
}
