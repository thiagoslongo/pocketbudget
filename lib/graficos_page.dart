import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraficosPage extends StatelessWidget {
  final List<Map<String, dynamic>> transacoes;

  const GraficosPage(this.transacoes, {super.key});

  @override
  Widget build(BuildContext context) {
    Map<String, double> totaisPorCategoria = {};
    double totalEntradas = 0;
    double totalSaidas = 0;

    for (var t in transacoes) {
      if (t["tipo"] == "Saída") {
        String cat = t["categoria"] ?? "Outros";
        totaisPorCategoria[cat] = (totaisPorCategoria[cat] ?? 0) + t["valor"];
        totalSaidas += t["valor"];
      } else {
        totalEntradas += t["valor"];
      }
    }

    // Paleta de cores mais suave e elegante
    final cores = [
      const Color(0xFF2D3436), // Cinza escuro
      const Color(0xFF636E72), // Cinza médio
      const Color(0xFFB2BEC3), // Cinza claro
      const Color(0xFF74B9FF), // Azul suave
      const Color(0xFFA29BFE), // Roxo suave
      const Color(0xFFDFE6E9), // Cinza muito claro
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Análise Financeira",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          totaisPorCategoria.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Nenhum gasto registrado ainda",
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Cards de resumo com design minimalista
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
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
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_downward,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Entradas",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "R\$ ${totalEntradas.toStringAsFixed(2).replaceAll('.', ',')}",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
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
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_upward,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Saídas",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "R\$ ${totalSaidas.toStringAsFixed(2).replaceAll('.', ',')}",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Gráfico de Pizza
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Distribuição de Gastos",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 250,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 70,
                                sections:
                                    totaisPorCategoria.entries.map((e) {
                                      final index = totaisPorCategoria.keys
                                          .toList()
                                          .indexOf(e.key);
                                      final cor = cores[index % cores.length];
                                      final total = totaisPorCategoria.values
                                          .reduce((a, b) => a + b);
                                      final porcentagem = (e.value /
                                              total *
                                              100)
                                          .toStringAsFixed(1);

                                      return PieChartSectionData(
                                        color: cor,
                                        value: e.value,
                                        title: "$porcentagem%",
                                        radius: 60,
                                        titleStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Gráfico de Barras
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Comparativo por Categoria",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 300,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY:
                                    totaisPorCategoria.values.reduce(
                                      (a, b) => a > b ? a : b,
                                    ) *
                                    1.2,
                                barTouchData: BarTouchData(enabled: false),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 60,
                                      getTitlesWidget: (value, meta) {
                                        if (value.toInt() >= 0 &&
                                            value.toInt() <
                                                totaisPorCategoria.length) {
                                          final categoria = totaisPorCategoria
                                              .keys
                                              .elementAt(value.toInt());
                                          return Transform.rotate(
                                            angle: -0.5,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Text(
                                                categoria,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: 500,
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: Colors.white,
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups:
                                    totaisPorCategoria.entries.map((e) {
                                      final index = totaisPorCategoria.keys
                                          .toList()
                                          .indexOf(e.key);
                                      return BarChartGroupData(
                                        x: index,
                                        barRods: [
                                          BarChartRodData(
                                            toY: e.value,
                                            color: cores[index % cores.length],
                                            width: 40,
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(8),
                                                ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Lista de categorias
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Detalhamento",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...totaisPorCategoria.entries.map((e) {
                            final index = totaisPorCategoria.keys
                                .toList()
                                .indexOf(e.key);
                            final cor = cores[index % cores.length];
                            final total = totaisPorCategoria.values.reduce(
                              (a, b) => a + b,
                            );
                            final porcentagem = (e.value / total * 100);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: cor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          e.key,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "R\$ ${e.value.toStringAsFixed(2).replaceAll('.', ',')}",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: porcentagem / 100,
                                      backgroundColor: Colors.white,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        cor,
                                      ),
                                      minHeight: 8,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }
}
