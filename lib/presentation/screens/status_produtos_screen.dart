import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/app_config.dart';
import '../../domain/entities/produto.dart';
import '../cubits/config/config_cubit.dart';
import '../cubits/config/config_state.dart';
import '../cubits/produto/produto_cubit.dart';
import '../cubits/produto/produto_state.dart';

class StatusProdutosScreen extends StatefulWidget {
  const StatusProdutosScreen({super.key});

  @override
  State<StatusProdutosScreen> createState() => _StatusProdutosScreenState();
}

class _StatusProdutosScreenState extends State<StatusProdutosScreen> {
  final TextEditingController _buscaController = TextEditingController();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDados();
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  void _carregarDados({bool forcarRemoto = false}) {
    final configState = context.read<ConfigCubit>().state;
    if (configState is ConfigLoaded) {
      context.read<ProdutoCubit>().carregarProdutos(
            config: configState.config,
            forcarRemoto: forcarRemoto,
          );
    }
  }

  Future<void> _confirmarAlteracaoStatus(
    BuildContext context,
    Produto produto,
    AppConfig config,
  ) async {
    final cubit = context.read<ProdutoCubit>();
    final bool vaiAtivar = !produto.isAtivo;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final bool? confirmou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: vaiAtivar
                      ? (isDark
                          ? const Color(0xFF14532D)
                          : const Color(0xFFDCFCE7))
                      : (isDark
                          ? const Color(0xFF7F1D1D)
                          : const Color(0xFFFEE2E2)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  vaiAtivar
                      ? Icons.check_circle_outline_rounded
                      : Icons.block_flipped,
                  color: vaiAtivar
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  vaiAtivar ? 'Ativar Produto?' : 'Inativar Produto?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card de pré-visualização do produto
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Cód: ${produto.codigo}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                          if (produto.grupoDescricao != null) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                produto.grupoDescricao!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        produto.descricao,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _currencyFormat.format(produto.precoVenda),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: produto.isAtivo
                                  ? const Color(0xFF16A34A).withOpacity(0.15)
                                  : const Color(0xFFDC2626).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Status Atual: ${produto.statusDescricao}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: produto.isAtivo
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  vaiAtivar
                      ? 'Deseja realmente ativar este produto para permitir pedidos e vendas no salão?'
                      : 'Deseja realmente inativar este produto para bloquear lançamentos em pedidos e mesas?',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1B4B).withOpacity(0.4)
                        : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF4338CA).withOpacity(0.4)
                          : const Color(0xFFC7D2FE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_edu_rounded,
                        size: 20,
                        color: isDark
                            ? const Color(0xFF818CF8)
                            : const Color(0xFF4F46E5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A alteração será registrada na Auditoria do Cadastro (TB_AUDITORIA / TB_AUDITORIA_ITEM).',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? const Color(0xFFC7D2FE)
                                : const Color(0xFF3730A3),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: vaiAtivar
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: Icon(
                vaiAtivar ? Icons.check_rounded : Icons.block_flipped,
                size: 18,
              ),
              label: Text(
                vaiAtivar ? 'Ativar Produto' : 'Inativar Produto',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmou != true || !mounted) return;

    cubit.alterarStatusProduto(
      config: config,
      produto: produto,
      ativar: vaiAtivar,
      usuarioId: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ConfigCubit, ConfigState>(
      builder: (context, configState) {
        final AppConfig config = configState is ConfigLoaded
            ? configState.config
            : const AppConfig();

        return Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.inventory_2_rounded, size: 22, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Status Produtos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Recarregar da Retaguarda',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => _carregarDados(forcarRemoto: true),
              ),
            ],
          ),
          body: BlocConsumer<ProdutoCubit, ProdutoState>(
            listener: (context, state) {
              if (state is ProdutoLoaded && state.mensagemSucesso != null) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.greenAccent, size: 22),
                        const SizedBox(width: 10),
                        Expanded(child: Text(state.mensagemSucesso!)),
                      ],
                    ),
                    backgroundColor: const Color(0xFF064E3B),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 4),
                  ),
                );
              } else if (state is ProdutoError) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.amberAccent, size: 22),
                        const SizedBox(width: 10),
                        Expanded(child: Text(state.mensagem)),
                      ],
                    ),
                    backgroundColor: const Color(0xFF7F1D1D),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is ProdutoLoading) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Carregando produtos da base Firebird...'),
                    ],
                  ),
                );
              }

              if (state is ProdutoError && state is! ProdutoLoaded) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            size: 64, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(
                          state.mensagem,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _carregarDados(forcarRemoto: true),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is ProdutoLoaded) {
                return Column(
                  children: [
                    // Resumo e Contadores
                    _buildResumoContadores(state, isDark),

                    // Barra de busca e filtros
                    _buildBarraBuscaEFiltros(state, isDark),

                    // Filtro de grupos (se houver grupos)
                    if (state.gruposDisponiveis.isNotEmpty)
                      _buildFiltroGrupos(state, isDark),

                    const Divider(height: 1),

                    // Lista de Produtos
                    Expanded(
                      child: state.produtosFiltrados.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 56,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    state.termoBusca.isNotEmpty
                                        ? 'Nenhum produto encontrado para "${state.termoBusca}".'
                                        : 'Nenhum produto com este filtro.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(10),
                              itemCount: state.produtosFiltrados.length,
                              separatorBuilder: (_, index) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final produto = state.produtosFiltrados[index];
                                final isEmAlteracao = state.isAlterando &&
                                    state.produtoEmAlteracaoId == produto.id;

                                return _buildProdutoCard(
                                  context: context,
                                  produto: produto,
                                  config: config,
                                  isDark: isDark,
                                  isEmAlteracao: isEmAlteracao,
                                );
                              },
                            ),
                    ),
                  ],
                );
              }

              return const SizedBox();
            },
          ),
        );
      },
    );
  }

  Widget _buildResumoContadores(ProdutoLoaded state, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildBadgeContador(
              titulo: 'Total',
              valor: state.totalGeral,
              cor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              icone: Icons.inventory_2_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBadgeContador(
              titulo: 'Ativos',
              valor: state.totalAtivos,
              cor: const Color(0xFF16A34A),
              icone: Icons.check_circle_outline_rounded,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildBadgeContador(
              titulo: 'Inativos',
              valor: state.totalInativos,
              cor: const Color(0xFFDC2626),
              icone: Icons.block_flipped,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeContador({
    required String titulo,
    required int valor,
    required Color cor,
    required IconData icone,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icone, size: 16, color: cor),
          const SizedBox(width: 6),
          Text(
            '$titulo: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
          Text(
            '$valor',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraBuscaEFiltros(ProdutoLoaded state, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Column(
        children: [
          // Campo de busca
          TextField(
            controller: _buscaController,
            decoration: InputDecoration(
              hintText: 'Buscar por nome, código ou referência...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _buscaController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _buscaController.clear();
                        context.read<ProdutoCubit>().atualizarBusca('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F172A)
                  : Theme.of(context).cardColor,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF0284C7),
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (val) {
              context.read<ProdutoCubit>().atualizarBusca(val);
            },
          ),
          const SizedBox(height: 8),

          // Segmented Buttons de Status
          Row(
            children: [
              Expanded(
                child: _buildFiltroStatusBotao(
                  rotulo: 'Todos (${state.totalGeral})',
                  valor: 'TODOS',
                  selecionado: state.filtroStatus == 'TODOS',
                  cor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildFiltroStatusBotao(
                  rotulo: 'Ativos (${state.totalAtivos})',
                  valor: 'ATIVOS',
                  selecionado: state.filtroStatus == 'ATIVOS',
                  cor: const Color(0xFF16A34A),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildFiltroStatusBotao(
                  rotulo: 'Inativos (${state.totalInativos})',
                  valor: 'INATIVOS',
                  selecionado: state.filtroStatus == 'INATIVOS',
                  cor: const Color(0xFFDC2626),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroStatusBotao({
    required String rotulo,
    required String valor,
    required bool selecionado,
    required Color cor,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () =>
          context.read<ProdutoCubit>().atualizarFiltroStatus(valor),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selecionado
              ? cor.withOpacity(isDark ? 0.25 : 0.15)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selecionado
                ? cor
                : (isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0)),
            width: selecionado ? 1.5 : 1,
          ),
        ),
        child: Text(
          rotulo,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.w500,
            color: selecionado
                ? (isDark ? cor : cor.withOpacity(0.95))
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltroGrupos(ProdutoLoaded state, bool isDark) {
    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          _buildChipGrupo(
            rotulo: 'Todos os Grupos',
            selecionado: state.grupoFiltro == null,
            onTap: () => context.read<ProdutoCubit>().atualizarFiltroGrupo(null),
            isDark: isDark,
          ),
          ...state.gruposDisponiveis.map((grupo) {
            return _buildChipGrupo(
              rotulo: grupo,
              selecionado: state.grupoFiltro == grupo,
              onTap: () =>
                  context.read<ProdutoCubit>().atualizarFiltroGrupo(grupo),
              isDark: isDark,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChipGrupo({
    required String rotulo,
    required bool selecionado,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          rotulo,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
            color: selecionado
                ? Colors.white
                : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
          ),
        ),
        selected: selecionado,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFF0284C7),
        backgroundColor:
            isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
    );
  }

  Widget _buildProdutoCard({
    required BuildContext context,
    required Produto produto,
    required AppConfig config,
    required bool isDark,
    required bool isEmAlteracao,
  }) {
    final bool isAtivo = produto.isAtivo;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAtivo
              ? (isDark
                  ? const Color(0xFF1E3A8A).withOpacity(0.5)
                  : const Color(0xFFE2E8F0))
              : (isDark
                  ? const Color(0xFF7F1D1D).withOpacity(0.6)
                  : const Color(0xFFFECACA)),
          width: isAtivo ? 1.0 : 1.4,
        ),
      ),
      color: isAtivo
          ? (isDark ? const Color(0xFF1E293B) : Colors.white)
          : (isDark
              ? const Color(0xFF26181B)
              : const Color(0xFFFFF5F5)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isEmAlteracao
            ? null
            : () => _confirmarAlteracaoStatus(context, produto, config),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Ícone lateral
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isAtivo
                      ? (isDark
                          ? const Color(0xFF14532D).withOpacity(0.5)
                          : const Color(0xFFDCFCE7))
                      : (isDark
                          ? const Color(0xFF7F1D1D).withOpacity(0.5)
                          : const Color(0xFFFEE2E2)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isEmAlteracao
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Icon(
                        isAtivo
                            ? Icons.check_circle_rounded
                            : Icons.block_flipped,
                        color: isAtivo
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),

              // Informações do Produto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${produto.codigo}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ),
                        if (produto.grupoDescricao != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: (isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0))
                                    .withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                produto.grupoDescricao!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      produto.descricao,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currencyFormat.format(produto.precoVenda),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Botão de Ação Rápida
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAtivo
                          ? const Color(0xFF16A34A).withOpacity(0.15)
                          : const Color(0xFFDC2626).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isAtivo
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      produto.statusDescricao.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                        color: isAtivo
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAtivo ? 'Toque para Inativar' : 'Toque para Ativar',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
