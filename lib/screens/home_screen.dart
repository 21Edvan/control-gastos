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
        DBHelper.instance.getTopExpenseCategoriesForMonth(now),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data as List<dynamic>;
        final balance = data[0] as double;
        final incomes = data[1] as double;
        final expenses = data[2] as double;
        final topCategories = data[3] as List<CategorySpending>;

        final monthText =
            DateFormat('MMMM yyyy', 'es').format(now).toUpperCase();

        // Regla simple: que tus gastos no superen el 70% de tus ingresos
        final recommendedMaxExpenses = incomes * 0.7;
        final bool? isOverSpending = incomes > 0
            ? expenses > recommendedMaxExpenses
            : null; // null si no hay ingresos (aún)

        // Categoría donde más se va la plata
        CategorySpending? worstCategory =
            topCategories.isNotEmpty ? topCategories.first : null;

        String planText;
        if (worstCategory == null || expenses == 0) {
          planText =
              'Empieza registrando TODO lo que gastas esta semana. La app te dirá luego dónde se te va más.';
        } else {
          final percent =
              ((worstCategory.total / (expenses == 0 ? 1 : expenses)) * 100)
                  .round();
          planText =
              'Este mes tu mayor fuga de dinero es **${worstCategory.name}** (aprox. $percent% de tus gastos). '
              'El plan: intenta bajar esa categoría al menos un 10% quitando gustos que no son realmente necesarios.';
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Text(
                monthText,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              // Saldo del mes
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

              // Ingresos vs Gastos
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

              // Bloque: Plan para controlar gastos
              Text(
                'Plan para no gastar de más',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. Regla 70/30',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        incomes > 0
                            ? 'Idealmente tus gastos no deberían pasar del 70% de lo que ganas.\n'
                                '70% de tus ingresos este mes ≈ ${recommendedMaxExpenses.toStringAsFixed(2)}'
                            : 'Cuando empieces a registrar tus ingresos, aquí verás un límite sugerido de gastos (70% de lo que ganes).',
                      ),
                      const SizedBox(height: 8),
                      if (isOverSpending == true)
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Estás gastando por encima del 70% de lo que ganas. Intenta recortar un poco los gastos variables (salidas, antojos, compras no urgentes).',
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                            ),
                          ],
                        )
                      else if (isOverSpending == false)
                        Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.teal),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Vas bien: tus gastos están dentro de un rango razonable respecto a tus ingresos.',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Top categorías donde se va más dinero
              Text(
                'Dónde se está yendo más tu dinero',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (topCategories.isEmpty)
                const Text(
                    'Cuando registres más gastos, aquí verás tus 3 mayores categorías de gasto.')
              else
                Card(
                  child: Column(
                    children: topCategories.map((cat) {
                      final percent = expenses == 0
                          ? 0
                          : ((cat.total / expenses) * 100).round();
                      return ListTile(
                        leading: const Icon(Icons.pie_chart_outline),
                        title: Text(cat.name),
                        subtitle: Text(
                            '${cat.total.toStringAsFixed(2)}   (${percent}% de tus gastos)'),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 16),

              // Objetivo del mes (texto motivacional basado en tu peor categoría)
              Text(
                'Objetivo de este mes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    planText,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
