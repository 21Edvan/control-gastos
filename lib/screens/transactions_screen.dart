import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/db_helper.dart';
import '../data/transaction_model.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late Future<List<TransactionModel>> _futureTx;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _futureTx = DBHelper.instance.getAllTransactions();
  }

  Future<void> _deleteTx(int id) async {
    await DBHelper.instance.deleteTransaction(id);
    _load();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TransactionModel>>(
      future: _futureTx,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!;
        if (items.isEmpty) {
          return const Center(child: Text('Aún no hay movimientos'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            _load();
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final tx = items[index];
              final isIncome = tx.type == 'income';
              final dateText =
                  DateFormat('dd/MM/yyyy HH:mm').format(tx.date);

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isIncome ? Colors.teal : Colors.red.shade400,
                    child: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    (isIncome ? '+ ' : '- ') +
                        tx.amount.toStringAsFixed(2),
                    style: TextStyle(
                      color: isIncome ? Colors.teal : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('${tx.note ?? "Sin nota"}\n$dateText'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteTx(tx.id!),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
