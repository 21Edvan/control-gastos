import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/db_helper.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return FutureBuilder(
      future: Future.wait([
        DBHelper.instance.getBalanceForMonth(now),
        DBHelper.instance.getTotalByTypeForMonth('income', now),
        DBHelper.instance.getTotalByTypeForMonth('expense', now),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final balance = snapshot.data![0] as double;
        final incomes = snapshot.data![1] as double;
        final expenses = snapshot.data![2] as double;

        final monthText = DateFormat('MMMM yyyy', 'es')
            .format(now)
            .toUpperCase();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                monthText,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: const Text('Saldo del mes'),
                  subtitle: const Text('Ingresos - Gastos'),
                  trailing: Text(
                    balance.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: balance >= 0 ? Colors.teal : Colors.red,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: ListTile(
                        title: const Text('Ingresos'),
                        trailing: Text(
                          incomes.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      child: ListTile(
                        title: const Text('Gastos'),
                        trailing: Text(
                          expenses.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Esta semana fíjate sobre todo en bajar los "gustos" 😉',
              ),
            ],
          ),
        );
      },
    );
  }
}
