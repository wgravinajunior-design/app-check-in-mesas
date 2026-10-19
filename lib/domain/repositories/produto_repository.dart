import '../entities/app_config.dart';
import '../entities/produto.dart';

abstract class ProdutoRepository {
  /// Lista todos os produtos cadastrados com grupo e status
  Future<List<Produto>> listarProdutos({
    required AppConfig config,
    bool forcarRemoto = false,
  });

  /// Altera o status do produto ('A' ou 'I') na TB_PRODUTO e grava a auditoria na TB_AUDITORIA e TB_AUDITORIA_ITEM
  Future<void> alterarStatusProduto({
    required AppConfig config,
    required Produto produto,
    required bool ativar,
    int? usuarioId,
  });
}
