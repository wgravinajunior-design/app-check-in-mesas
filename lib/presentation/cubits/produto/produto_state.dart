import 'package:equatable/equatable.dart';
import '../../../domain/entities/produto.dart';

abstract class ProdutoState extends Equatable {
  const ProdutoState();

  @override
  List<Object?> get props => [];
}

class ProdutoInitial extends ProdutoState {}

class ProdutoLoading extends ProdutoState {}

class ProdutoLoaded extends ProdutoState {
  final List<Produto> produtos;
  final List<Produto> produtosFiltrados;
  final String filtroStatus; // 'TODOS', 'ATIVOS', 'INATIVOS'
  final String termoBusca;
  final String? grupoFiltro;
  final List<String> gruposDisponiveis;
  final bool isAlterando;
  final int? produtoEmAlteracaoId;
  final String? mensagemSucesso;

  const ProdutoLoaded({
    required this.produtos,
    required this.produtosFiltrados,
    this.filtroStatus = 'TODOS',
    this.termoBusca = '',
    this.grupoFiltro,
    required this.gruposDisponiveis,
    this.isAlterando = false,
    this.produtoEmAlteracaoId,
    this.mensagemSucesso,
  });

  int get totalAtivos => produtos.where((p) => p.isAtivo).length;
  int get totalInativos => produtos.where((p) => !p.isAtivo).length;
  int get totalGeral => produtos.length;

  ProdutoLoaded copyWith({
    List<Produto>? produtos,
    List<Produto>? produtosFiltrados,
    String? filtroStatus,
    String? termoBusca,
    String? grupoFiltro,
    bool resetGrupoFiltro = false,
    List<String>? gruposDisponiveis,
    bool? isAlterando,
    int? produtoEmAlteracaoId,
    bool resetProdutoEmAlteracao = false,
    String? mensagemSucesso,
    bool resetMensagemSucesso = false,
  }) {
    return ProdutoLoaded(
      produtos: produtos ?? this.produtos,
      produtosFiltrados: produtosFiltrados ?? this.produtosFiltrados,
      filtroStatus: filtroStatus ?? this.filtroStatus,
      termoBusca: termoBusca ?? this.termoBusca,
      grupoFiltro: resetGrupoFiltro ? null : (grupoFiltro ?? this.grupoFiltro),
      gruposDisponiveis: gruposDisponiveis ?? this.gruposDisponiveis,
      isAlterando: isAlterando ?? this.isAlterando,
      produtoEmAlteracaoId: resetProdutoEmAlteracao ? null : (produtoEmAlteracaoId ?? this.produtoEmAlteracaoId),
      mensagemSucesso: resetMensagemSucesso ? null : (mensagemSucesso ?? this.mensagemSucesso),
    );
  }

  @override
  List<Object?> get props => [
        produtos,
        produtosFiltrados,
        filtroStatus,
        termoBusca,
        grupoFiltro,
        gruposDisponiveis,
        isAlterando,
        produtoEmAlteracaoId,
        mensagemSucesso,
      ];
}

class ProdutoError extends ProdutoState {
  final String mensagem;

  const ProdutoError(this.mensagem);

  @override
  List<Object?> get props => [mensagem];
}
