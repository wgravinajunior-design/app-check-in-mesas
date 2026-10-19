import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/app_config.dart';
import '../../../domain/entities/produto.dart';
import '../../../domain/repositories/produto_repository.dart';
import 'produto_state.dart';

class ProdutoCubit extends Cubit<ProdutoState> {
  final ProdutoRepository produtoRepository;

  ProdutoCubit({required this.produtoRepository}) : super(ProdutoInitial());

  Future<void> carregarProdutos({
    required AppConfig config,
    bool forcarRemoto = false,
  }) async {
    emit(ProdutoLoading());
    try {
      final produtos = await produtoRepository.listarProdutos(
        config: config,
        forcarRemoto: forcarRemoto,
      );

      final grupos = produtos
          .map((p) => p.grupoDescricao?.trim())
          .where((g) => g != null && g.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList()
        ..sort();

      final filtrados = _filtrarLista(
        produtos: produtos,
        termoBusca: '',
        filtroStatus: 'TODOS',
        grupoFiltro: null,
      );

      emit(ProdutoLoaded(
        produtos: produtos,
        produtosFiltrados: filtrados,
        gruposDisponiveis: grupos,
        filtroStatus: 'TODOS',
        termoBusca: '',
        grupoFiltro: null,
      ));
    } catch (e) {
      emit(ProdutoError('Erro ao carregar produtos: $e'));
    }
  }

  void atualizarBusca(String termo) {
    if (state is! ProdutoLoaded) return;
    final current = state as ProdutoLoaded;

    final filtrados = _filtrarLista(
      produtos: current.produtos,
      termoBusca: termo,
      filtroStatus: current.filtroStatus,
      grupoFiltro: current.grupoFiltro,
    );

    emit(current.copyWith(
      termoBusca: termo,
      produtosFiltrados: filtrados,
      resetMensagemSucesso: true,
    ));
  }

  void atualizarFiltroStatus(String status) {
    if (state is! ProdutoLoaded) return;
    final current = state as ProdutoLoaded;

    final filtrados = _filtrarLista(
      produtos: current.produtos,
      termoBusca: current.termoBusca,
      filtroStatus: status,
      grupoFiltro: current.grupoFiltro,
    );

    emit(current.copyWith(
      filtroStatus: status,
      produtosFiltrados: filtrados,
      resetMensagemSucesso: true,
    ));
  }

  void atualizarFiltroGrupo(String? grupo) {
    if (state is! ProdutoLoaded) return;
    final current = state as ProdutoLoaded;

    final novoGrupo = (grupo == null || grupo == 'TODOS') ? null : grupo;

    final filtrados = _filtrarLista(
      produtos: current.produtos,
      termoBusca: current.termoBusca,
      filtroStatus: current.filtroStatus,
      grupoFiltro: novoGrupo,
    );

    emit(current.copyWith(
      grupoFiltro: novoGrupo,
      resetGrupoFiltro: novoGrupo == null,
      produtosFiltrados: filtrados,
      resetMensagemSucesso: true,
    ));
  }

  Future<void> alterarStatusProduto({
    required AppConfig config,
    required Produto produto,
    required bool ativar,
    int? usuarioId,
  }) async {
    if (state is! ProdutoLoaded) return;
    final current = state as ProdutoLoaded;

    emit(current.copyWith(
      isAlterando: true,
      produtoEmAlteracaoId: produto.id,
      resetMensagemSucesso: true,
    ));

    try {
      await produtoRepository.alterarStatusProduto(
        config: config,
        produto: produto,
        ativar: ativar,
        usuarioId: usuarioId,
      );

      final String novoStatus = ativar ? 'A' : 'I';
      final listaAtualizada = current.produtos.map((p) {
        if (p.id == produto.id) {
          return p.copyWith(status: novoStatus);
        }
        return p;
      }).toList();

      final filtrados = _filtrarLista(
        produtos: listaAtualizada,
        termoBusca: current.termoBusca,
        filtroStatus: current.filtroStatus,
        grupoFiltro: current.grupoFiltro,
      );

      final acao = ativar ? 'ativado' : 'inativado';
      final msg = 'Produto "${produto.descricao}" $acao com sucesso na retaguarda e registrado na auditoria!';

      emit(current.copyWith(
        produtos: listaAtualizada,
        produtosFiltrados: filtrados,
        isAlterando: false,
        resetProdutoEmAlteracao: true,
        mensagemSucesso: msg,
      ));
    } catch (e) {
      emit(current.copyWith(
        isAlterando: false,
        resetProdutoEmAlteracao: true,
      ));
      emit(ProdutoError('Falha ao alterar status do produto: $e'));
      // Restaura o estado carregado após emitir o erro
      emit(current.copyWith(
        isAlterando: false,
        resetProdutoEmAlteracao: true,
      ));
    }
  }

  List<Produto> _filtrarLista({
    required List<Produto> produtos,
    required String termoBusca,
    required String filtroStatus,
    required String? grupoFiltro,
  }) {
    List<Produto> lista = produtos;

    // Filtro por status
    if (filtroStatus == 'ATIVOS') {
      lista = lista.where((p) => p.isAtivo).toList();
    } else if (filtroStatus == 'INATIVOS') {
      lista = lista.where((p) => !p.isAtivo).toList();
    }

    // Filtro por grupo
    if (grupoFiltro != null && grupoFiltro.isNotEmpty && grupoFiltro != 'TODOS') {
      lista = lista.where((p) => p.grupoDescricao == grupoFiltro).toList();
    }

    // Filtro por termo de busca
    if (termoBusca.trim().isNotEmpty) {
      final termo = termoBusca.toLowerCase().trim();
      lista = lista.where((p) {
        return p.descricao.toLowerCase().contains(termo) ||
            p.codigo.toLowerCase().contains(termo) ||
            (p.referencia?.toLowerCase().contains(termo) ?? false) ||
            (p.grupoDescricao?.toLowerCase().contains(termo) ?? false);
      }).toList();
    }

    return lista;
  }
}
