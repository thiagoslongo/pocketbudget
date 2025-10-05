import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'transacao_page.dart';
import 'graficos_page.dart';
import 'firebase_options.dart';
import 'filtros_page.dart';
import 'metas_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PocketBudgetApp());
}

class PocketBudgetApp extends StatelessWidget {
  const PocketBudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PocketBudget',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double saldo = 1200.0;
  List<Map<String, dynamic>> transacoes = [];
  List<Map<String, dynamic>> transacoesFiltradas = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarTransacoes();
    _searchController.addListener(_filtrarTransacoes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarTransacoes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        transacoesFiltradas = List.from(transacoes);
      } else {
        transacoesFiltradas =
            transacoes.where((t) {
              final descricao = t['descricao'].toString().toLowerCase();
              final categoria = (t['categoria'] ?? '').toString().toLowerCase();
              return descricao.contains(query) || categoria.contains(query);
            }).toList();
      }
    });
  }

  Future<void> _carregarTransacoes() async {
    try {
      print('Tentando carregar do Firebase...');
      final snapshot = await _firestore.collection('transacoes').get();
      print('Documentos encontrados: ${snapshot.docs.length}');

      setState(() {
        transacoes =
            snapshot.docs.map((doc) {
              return {'id': doc.id, ...doc.data()};
            }).toList();

        transacoesFiltradas = List.from(transacoes);

        // Recalcula o saldo
        saldo = 0;
        for (var t in transacoes) {
          saldo += t["tipo"] == "Entrada" ? t["valor"] : -t["valor"];
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _salvarTransacao(Map<String, dynamic> transacao) async {
    try {
      await _firestore.collection('transacoes').add(transacao);
      await _carregarTransacoes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Salvo no Firebase com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao salvar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deletarTransacao(String id) async {
    try {
      await _firestore.collection('transacoes').doc(id).delete();
      await _carregarTransacoes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Transação deletada!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao deletar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _editarTransacao(
    String id,
    Map<String, dynamic> transacao,
  ) async {
    try {
      await _firestore.collection('transacoes').doc(id).update(transacao);
      await _carregarTransacoes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✏️ Transação atualizada!'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao editar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _mostrarOpcoesTransacao(Map<String, dynamic> transacao) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blue),
                  title: const Text('Editar'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final resultado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => TransacaoPage(
                              isEntrada: transacao['tipo'] == 'Entrada',
                              transacaoExistente: transacao,
                            ),
                      ),
                    );

                    if (resultado != null &&
                        resultado is Map<String, dynamic>) {
                      await _editarTransacao(transacao['id'], resultado);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Deletar'),
                  onTap: () {
                    Navigator.pop(ctx);
                    showDialog(
                      context: context,
                      builder:
                          (ctx) => AlertDialog(
                            title: const Text('Confirmar exclusão'),
                            content: const Text(
                              'Deseja realmente deletar esta transação?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _deletarTransacao(transacao['id']);
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Deletar'),
                              ),
                            ],
                          ),
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  IconData _getCategoriaIcon(String? categoria) {
    if (categoria == null) return Icons.help_outline;

    switch (categoria.toLowerCase().trim()) {
      // DESPESAS
      case 'alimentação':
      case 'alimentacao':
        return Icons.restaurant_menu;

      case 'transporte':
        return Icons.directions_car;

      case 'lazer':
        return Icons.beach_access;

      case 'contas':
        return Icons.receipt_long;

      case 'saúde':
      case 'saude':
        return Icons.favorite;

      case 'educação':
      case 'educacao':
        return Icons.school;

      case 'roupas':
        return Icons.checkroom;

      // ENTRADAS
      case 'salário':
      case 'salario':
        return Icons.attach_money;

      case 'freelance':
        return Icons.laptop_mac;

      case 'investimento':
        return Icons.trending_up;

      case 'presente':
        return Icons.card_giftcard;

      // OUTROS
      case 'outros':
        return Icons.more_horiz;

      default:
        return Icons.category;
    }
  }

  Map<String, dynamic> _calcularEstatisticas() {
    final agora = DateTime.now();
    final mesAtual = agora.month;
    final anoAtual = agora.year;
    final transacoesMesAtual =
        transacoes.where((t) {
          if (t['data'] == null) return false;
          try {
            final data = DateTime.parse(t['data']);
            return data.month == mesAtual && data.year == anoAtual;
          } catch (e) {
            return false;
          }
        }).toList();
    final mesPAssado = mesAtual == 1 ? 12 : mesAtual - 1;
    final anoMesPassado = mesAtual == 1 ? anoAtual - 1 : anoAtual;

    final transacoesMesPassado =
        transacoes.where((t) {
          if (t['data'] == null) return false;
          try {
            final data = DateTime.parse(t['data']);
            return data.month == mesPAssado && data.year == anoMesPassado;
          } catch (e) {
            return false;
          }
        }).toList();

    final despesas =
        transacoesMesAtual.where((t) => t['tipo'] == 'Saída').toList();
    Map<String, dynamic>? maiorGasto;
    if (despesas.isNotEmpty) {
      maiorGasto = despesas.reduce((a, b) => a['valor'] > b['valor'] ? a : b);
    }

    Map<String, double> gastosPorCategoria = {};
    for (var t in despesas) {
      final categoria = t['categoria'] ?? 'Outros';
      gastosPorCategoria[categoria] =
          (gastosPorCategoria[categoria] ?? 0) + t['valor'];
    }

    String? categoriaMaisGasta;
    double? valorCategoriaMaisGasta;
    if (gastosPorCategoria.isNotEmpty) {
      final entrada = gastosPorCategoria.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      categoriaMaisGasta = entrada.key;
      valorCategoriaMaisGasta = entrada.value;
    }

    final gastoMesAtual = despesas.fold(
      0.0,
      (sum, t) => sum + (t['valor'] as num).toDouble(),
    );
    final gastoMesPassado = transacoesMesPassado
        .where((t) => t['tipo'] == 'Saída')
        .fold(0.0, (sum, t) => sum + (t['valor'] as num).toDouble());

    double? percentualMudanca;
    bool? gastouMais;
    if (gastoMesPassado > 0) {
      percentualMudanca =
          ((gastoMesAtual - gastoMesPassado) / gastoMesPassado) * 100;
      gastouMais = gastoMesAtual > gastoMesPassado;
    }

    return {
      'maiorGasto': maiorGasto,
      'categoriaMaisGasta': categoriaMaisGasta,
      'valorCategoriaMaisGasta': valorCategoriaMaisGasta,
      'percentualMudanca': percentualMudanca,
      'gastouMais': gastouMais,
      'gastoMesAtual': gastoMesAtual,
    };
  }

  Widget _buildDashboardCards() {
    final stats = _calcularEstatisticas();

    return Column(
      children: [
        Row(
          children: [
            if (stats['maiorGasto'] != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Maior Gasto',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stats['maiorGasto']['descricao'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'R\$ ${stats['maiorGasto']['valor'].toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (stats['categoriaMaisGasta'] != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getCategoriaIcon(stats['categoriaMaisGasta']),
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Top Categoria',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stats['categoriaMaisGasta'],
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'R\$ ${stats['valorCategoriaMaisGasta'].toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),

        if (stats['percentualMudanca'] != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: stats['gastouMais'] ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    stats['gastouMais']
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tendência do Mês',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                      Row(
                        children: [
                          Text(
                            stats['gastouMais']
                                ? 'Gastando mais '
                                : 'Gastando menos ',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${stats['percentualMudanca'].abs().toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  stats['gastouMais']
                                      ? Colors.red
                                      : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _navegarParaAdicionar(bool isEntrada) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => TransacaoPage(isEntrada: isEntrada)),
    );

    if (resultado != null && resultado is Map<String, dynamic>) {
      await _salvarTransacao(resultado);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.black),
                  decoration: const InputDecoration(
                    hintText: 'Buscar transações...',
                    hintStyle: TextStyle(color: Colors.black54),
                    border: InputBorder.none,
                  ),
                )
                : const Text(
                  "PocketBudget",
                  style: TextStyle(color: Colors.black),
                ),
        centerTitle: !_isSearching,
        backgroundColor: Colors.white,
        elevation: 0,
        leading:
            _isSearching
                ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchController.clear();
                    });
                  },
                )
                : null,
        actions: [
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              tooltip: "Buscar transações",
              onPressed: () {
                setState(() => _isSearching = true);
              },
            ),
            IconButton(
              icon: const Icon(Icons.flag_outlined, color: Colors.black),
              tooltip: "Metas e Orçamento",
              onPressed: () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const MetasPage()),
                );
                if (resultado == true) {
                  _carregarTransacoes();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.black),
              tooltip: "Filtrar transações",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => FiltrosPage(todasTransacoes: transacoes),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.bar_chart, color: Colors.black),
              tooltip: "Ver gráficos",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => GraficosPage(transacoes)),
                );
              },
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!_isSearching) ...[
              const Text(
                "Saldo",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                "R\$ ${saldo.toStringAsFixed(2).replaceAll('.', ',')}",
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _navegarParaAdicionar(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE0E0E0),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Adicionar\nDespesa",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _navegarParaAdicionar(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE0E0E0),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Adicionar\nGanho",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              _buildDashboardCards(),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isSearching
                      ? "Resultados (${transacoesFiltradas.length})"
                      : "Transações",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_isSearching &&
                    transacoesFiltradas.length != transacoes.length)
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                    },
                    child: const Text('Limpar'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : transacoesFiltradas.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isSearching
                                  ? Icons.search_off
                                  : Icons.inbox_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isSearching
                                  ? "Nenhuma transação encontrada"
                                  : "Nenhuma transação adicionada ainda",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: transacoesFiltradas.length,
                        itemBuilder: (ctx, i) {
                          final t = transacoesFiltradas[i];
                          return GestureDetector(
                            onLongPress: () => _mostrarOpcoesTransacao(t),
                            child: Container(
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
                                      _getCategoriaIcon(
                                        t["categoria"]?.toString(),
                                      ),
                                      size: 26,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t["descricao"],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              t["categoria"] ?? "Sem categoria",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            if (t["data"] != null) ...[
                                              Text(
                                                " • ",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                () {
                                                  try {
                                                    final data = DateTime.parse(
                                                      t["data"],
                                                    );
                                                    final hoje = DateTime.now();
                                                    final ontem = hoje.subtract(
                                                      const Duration(days: 1),
                                                    );

                                                    if (data.year ==
                                                            hoje.year &&
                                                        data.month ==
                                                            hoje.month &&
                                                        data.day == hoje.day) {
                                                      return 'Hoje';
                                                    } else if (data.year ==
                                                            ontem.year &&
                                                        data.month ==
                                                            ontem.month &&
                                                        data.day == ontem.day) {
                                                      return 'Ontem';
                                                    } else {
                                                      return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
                                                    }
                                                  } catch (e) {
                                                    return '';
                                                  }
                                                }(),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "${t["tipo"] == "Entrada" ? "+" : "-"} R\$ ${t["valor"].toStringAsFixed(2).replaceAll('.', ',')}",
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
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
