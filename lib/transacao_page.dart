import 'package:flutter/material.dart';

class TransacaoPage extends StatefulWidget {
  final bool isEntrada;
  final Map<String, dynamic>? transacaoExistente;

  const TransacaoPage({
    super.key,
    required this.isEntrada,
    this.transacaoExistente,
  });

  @override
  State<TransacaoPage> createState() => _TransacaoPageState();
}

class _TransacaoPageState extends State<TransacaoPage> {
  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  String? _categoriaSelecionada;
  DateTime _dataSelecionada = DateTime.now();

  final List<String> _categoriasDespesas = [
    'Alimentação',
    'Transporte',
    'Lazer',
    'Contas',
    'Saúde',
    'Educação',
    'Outros',
  ];

  final List<String> _categoriasEntradas = [
    'Salário',
    'Freelance',
    'Investimento',
    'Presente',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transacaoExistente != null) {
      _valorController.text = widget.transacaoExistente!['valor'].toString();
      _descricaoController.text = widget.transacaoExistente!['descricao'];
      _categoriaSelecionada = widget.transacaoExistente!['categoria'];

      // Carrega a data existente se houver
      if (widget.transacaoExistente!['data'] != null) {
        try {
          _dataSelecionada = DateTime.parse(widget.transacaoExistente!['data']);
        } catch (e) {
          _dataSelecionada = DateTime.now();
        }
      }
    }
  }

  @override
  void dispose() {
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black87,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dataSelecionada) {
      setState(() {
        _dataSelecionada = picked;
      });
    }
  }

  String _formatarData(DateTime data) {
    final hoje = DateTime.now();
    final ontem = DateTime.now().subtract(const Duration(days: 1));

    if (data.year == hoje.year &&
        data.month == hoje.month &&
        data.day == hoje.day) {
      return 'Hoje';
    } else if (data.year == ontem.year &&
        data.month == ontem.month &&
        data.day == ontem.day) {
      return 'Ontem';
    } else {
      return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
    }
  }

  void _salvar() {
    final valor = double.tryParse(_valorController.text.replaceAll(',', '.'));

    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira um valor válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_categoriaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma categoria'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_descricaoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, insira uma descrição'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final transacao = {
      'valor': valor,
      'categoria': _categoriaSelecionada,
      'descricao': _descricaoController.text.trim(),
      'tipo': widget.isEntrada ? 'Entrada' : 'Saída',
      'data': _dataSelecionada.toIso8601String(),
    };

    Navigator.pop(context, transacao);
  }

  @override
  Widget build(BuildContext context) {
    final categorias =
        widget.isEntrada ? _categoriasEntradas : _categoriasDespesas;
    final isEdicao = widget.transacaoExistente != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEdicao
              ? 'Editar ${widget.isEntrada ? "Entrada" : "Transação"}'
              : 'Adicionar ${widget.isEntrada ? "Entrada" : "Transação"}',
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Valor",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _valorController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                hintText: "0,00",
                prefixText: "R\$ ",
                prefixStyle: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Data",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selecionarData,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.black87,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatarData(_dataSelecionada),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.black54,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Categoria",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _categoriaSelecionada,
              hint: const Text("Selecionar"),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
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
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              "Descrição",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descricaoController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Digite uma descrição...",
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isEdicao ? "Atualizar" : "Salvar",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
