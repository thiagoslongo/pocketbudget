import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MetasPage extends StatefulWidget {
  const MetasPage({super.key});

  @override
  State<MetasPage> createState() => _MetasPageState();
}

class _MetasPageState extends State<MetasPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, TextEditingController> _controllers = {};
  Map<String, double> _metasAtuais = {};
  final Map<String, double> _gastosAtuais = {};
  bool _isLoading = true;

  final List<String> _categorias = [
    'Alimentação',
    'Transporte',
    'Lazer',
    'Contas',
    'Saúde',
    'Educação',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final metasDoc =
          await _firestore.collection('metas').doc('orcamento').get();
      if (metasDoc.exists) {
        final data = metasDoc.data() as Map<String, dynamic>;
        _metasAtuais = data.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
      }

      final transacoesSnapshot =
          await _firestore.collection('transacoes').get();
      final agora = DateTime.now();

      for (var doc in transacoesSnapshot.docs) {
        final t = doc.data();
        if (t['tipo'] == 'Saída' && t['data'] != null) {
          try {
            final dataTransacao = DateTime.parse(t['data']);
            if (dataTransacao.month == agora.month &&
                dataTransacao.year == agora.year) {
              String cat = t['categoria'] ?? 'Outros';
              _gastosAtuais[cat] =
                  (_gastosAtuais[cat] ?? 0) + (t['valor'] as num).toDouble();
            }
          } catch (e) {}
        }
      }

      for (var cat in _categorias) {
        _controllers[cat] = TextEditingController(
          text: _metasAtuais[cat]?.toStringAsFixed(0) ?? '',
        );
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar dados: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _salvarMetas() async {
    try {
      Map<String, double> novasMetas = {};

      for (var cat in _categorias) {
        final valor = double.tryParse(_controllers[cat]!.text);
        if (valor != null && valor > 0) {
          novasMetas[cat] = valor;
        }
      }

      await _firestore.collection('metas').doc('orcamento').set(novasMetas);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Metas salvas com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  IconData _getCategoriaIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'alimentação':
      case 'alimentacao':
        return Icons.restaurant;
      case 'transporte':
        return Icons.directions_car;
      case 'lazer':
        return Icons.sports_esports;
      case 'contas':
        return Icons.receipt_long;
      case 'saúde':
      case 'saude':
        return Icons.local_hospital;
      case 'educação':
      case 'educacao':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  Color _getProgressColor(double percentual) {
    if (percentual < 0.7) return Colors.green;
    if (percentual < 0.9) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Metas e Orçamento",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _salvarMetas,
            child: const Text(
              'Salvar',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Define o orçamento mensal para cada categoria',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ..._categorias.map((categoria) {
                      final gastoAtual = _gastosAtuais[categoria] ?? 0.0;
                      final metaAtual = _metasAtuais[categoria] ?? 0.0;
                      final percentual =
                          metaAtual > 0 ? (gastoAtual / metaAtual) : 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Linha 1: Ícone + Nome
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8E8E8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getCategoriaIcon(categoria),
                                    size: 22,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  categoria,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),

                            if (metaAtual > 0) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Gasto: R\$ ${gastoAtual.toStringAsFixed(2).replaceAll('.', ',')} de R\$ ${metaAtual.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            TextField(
                              controller: _controllers[categoria],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                hintText: 'Orçamento mensal',
                                prefixText: 'R\$ ',
                                prefixStyle: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),

                            if (metaAtual > 0) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: percentual > 1.0 ? 1.0 : percentual,
                                  backgroundColor: Colors.white,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getProgressColor(percentual),
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(percentual * 100).toStringAsFixed(0)}% usado',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getProgressColor(percentual),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (percentual >= 1.0)
                                    const Text(
                                      'Orçamento excedido!',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
    );
  }
}
