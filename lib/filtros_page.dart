import 'package:flutter/material.dart';

class FiltrosPage extends StatefulWidget {
  final List<Map<String, dynamic>> todasTransacoes;

  const FiltrosPage({super.key, required this.todasTransacoes});

  @override
  State<FiltrosPage> createState() => _FiltrosPageState();
}

class _FiltrosPageState extends State<FiltrosPage> {
  String _periodoSelecionado = 'Todos';
  String? _categoriaSelecionada;
  List<Map<String, dynamic>> _transacoesFiltradas = [];

  @override
  void initState() {
    super.initState();
    _transacoesFiltradas = widget.todasTransacoes;
  }

  void _aplicarFiltros() {
    setState(() {
      _transacoesFiltradas =
          widget.todasTransacoes.where((t) {
            if (_periodoSelecionado != 'Todos') {
              if (t['data'] == null) return false;

              try {
                final data = DateTime.parse(t['data']);
                final agora = DateTime.now();

                if (_periodoSelecionado == 'Este mês') {
                  if (data.month != agora.month || data.year != agora.year) {
                    return false;
                  }
                } else if (_periodoSelecionado == 'Esta semana') {
                  final diferenca = agora.difference(data).inDays;
                  if (diferenca > 7) return false;
                } else if (_periodoSelecionado == 'Hoje') {
                  if (data.day != agora.day ||
                      data.month != agora.month ||
                      data.year != agora.year) {
                    return false;
                  }
                } else if (_periodoSelecionado == 'Mês passado') {
                  final mesPassado = DateTime(agora.year, agora.month - 1);
                  if (data.month != mesPassado.month ||
                      data.year != mesPassado.year) {
                    return false;
                  }
                }
              } catch (e) {
                return false;
              }
            }

            if (_categoriaSelecionada != null &&
                _categoriaSelecionada != 'Todas') {
              if (t['categoria'] != _categoriaSelecionada) return false;
            }

            return true;
          }).toList();
    });
  }

  Set<String> _obterCategorias() {
    return widget.todasTransacoes
        .where((t) => t['categoria'] != null)
        .map((t) => t['categoria'] as String)
        .toSet();
  }

  IconData _getCategoriaIcon(String? categoria) {
    if (categoria == null) return Icons.help_outline;

    switch (categoria.toLowerCase().trim()) {
      case 'alimentação':
      case 'alimentacao':
        return Icons.restaurant;
      case 'transporte':
        return Icons.directions_car;
      case 'salário':
      case 'salario':
        return Icons.attach_money;
      case 'lazer':
        return Icons.sports_esports;
      case 'contas':
        return Icons.receipt_long;
      case 'freelance':
        return Icons.laptop_mac;
      case 'investimento':
        return Icons.trending_up;
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

  @override
  Widget build(BuildContext context) {
    final categorias = ['Todas', ..._obterCategorias()];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Filtrar Transações",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFF5F5F5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Período",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                        'Todos',
                        'Hoje',
                        'Esta semana',
                        'Este mês',
                        'Mês passado',
                      ].map((periodo) {
                        return ChoiceChip(
                          label: Text(periodo),
                          selected: _periodoSelecionado == periodo,
                          onSelected: (selected) {
                            setState(() {
                              _periodoSelecionado = periodo;
                              _aplicarFiltros();
                            });
                          },
                          selectedColor: Colors.black87,
                          labelStyle: TextStyle(
                            color:
                                _periodoSelecionado == periodo
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Categoria",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _categoriaSelecionada,
                  hint: const Text("Todas as categorias"),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items:
                      categorias.map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoriaSelecionada = value;
                      _aplicarFiltros();
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_transacoesFiltradas.length} transações encontradas",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_periodoSelecionado != 'Todos' ||
                    _categoriaSelecionada != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _periodoSelecionado = 'Todos';
                        _categoriaSelecionada = null;
                        _aplicarFiltros();
                      });
                    },
                    child: const Text('Limpar filtros'),
                  ),
              ],
            ),
          ),
          Expanded(
            child:
                _transacoesFiltradas.isEmpty
                    ? const Center(
                      child: Text(
                        "Nenhuma transação encontrada",
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _transacoesFiltradas.length,
                      itemBuilder: (ctx, i) {
                        final t = _transacoesFiltradas[i];

                        // Formata a data com segurança
                        String dataFormatada = 'Sem data';
                        if (t['data'] != null) {
                          try {
                            final data = DateTime.parse(t['data']);
                            dataFormatada =
                                '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
                          } catch (e) {
                            dataFormatada = 'Data inválida';
                          }
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8E8E8),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getCategoriaIcon(t["categoria"]?.toString()),
                                  size: 26,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t["descricao"] ?? "Sem descrição",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${t["categoria"] ?? "Sem categoria"} • $dataFormatada',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                "${t["tipo"] == "Entrada" ? "+" : "-"} R\$ ${(t["valor"] ?? 0.0).toStringAsFixed(2).replaceAll('.', ',')}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      t["tipo"] == "Entrada"
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
