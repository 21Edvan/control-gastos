import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/db_helper.dart';
import '../data/category_model.dart';
import '../data/transaction_model.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  String _type = 'expense'; // gasto por defecto
  double? _amount;
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  String? _note;
  String? _paymentMethod;

  List<Category> _categories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    final cats = await DBHelper.instance.getCategoriesByType(_type);
    setState(() {
      _categories = cats;
      _selectedCategory = cats.isNotEmpty ? cats.first : null;
      _loadingCategories = false;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
  final isValid = _formKey.currentState?.validate() ?? false;
  if (!isValid || _selectedCategory == null) return;

  _formKey.currentState?.save();

  final tx = TransactionModel(
    type: _type,
    amount: _amount!,
    date: _selectedDate,
    categoryId: _selectedCategory!.id!,
    note: _note,
    paymentMethod: _paymentMethod,
  );

  try {
    await DBHelper.instance.insertTransaction(tx);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Movimiento guardado')),
    );

    // 🔄 Limpiar formulario en lugar de cerrar la pantalla
    _formKey.currentState!.reset();
    setState(() {
      _type = 'expense';
      _selectedDate = DateTime.now();
      _paymentMethod = null;
      _note = null;
      _amount = null;
    });
    await _loadCategories();
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al guardar: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd/MM/yyyy').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo movimiento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loadingCategories
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('Gasto'),
                          selected: _type == 'expense',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _type = 'expense';
                              });
                              _loadCategories();
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text('Ingreso'),
                          selected: _type == 'income',
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _type = 'income';
                              });
                              _loadCategories();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Monto',
                        prefixIcon: Icon(Icons.monetization_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa un monto';
                        }
                        final v = double.tryParse(value.replaceAll(',', '.'));
                        if (v == null || v <= 0) {
                          return 'Monto inválido';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _amount = double.parse(
                            value!.trim().replaceAll(',', '.'));
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(dateText),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Category>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories
                          .map(
                            (cat) => DropdownMenuItem<Category>(
                              value: cat,
                              child: Text(cat.name),
                            ),
                          )
                          .toList(),
                      onChanged: (cat) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Método de pago (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'cash', child: Text('Efectivo')),
                        DropdownMenuItem(
                            value: 'card', child: Text('Tarjeta')),
                        DropdownMenuItem(
                            value: 'transfer', child: Text('Transferencia')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Nota (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      onSaved: (value) {
                        _note = value?.trim().isEmpty ?? true ? null : value;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveTransaction,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
