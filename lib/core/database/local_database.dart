import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gestao_permanencia.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Configura o sqflite FFI para Desktop (Windows, Linux, macOS)
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final appSupportDir = await getApplicationSupportDirectory();
      path = join(appSupportDir.path, filePath);
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    }

    final db = await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
    await _ensureTables(db);
    return db;
  }

  Future<void> _ensureTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS TB_COMANDA (
        COM_ID INTEGER PRIMARY KEY,
        COM_EMPRESA INTEGER NOT NULL,
        COM_CODIGO TEXT NOT NULL,
        COM_DESCRICAO TEXT,
        COM_STATUS TEXT NOT NULL DEFAULT 'A'
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS IDX_TB_COMANDA_EMPRESA_CODIGO 
      ON TB_COMANDA (COM_EMPRESA, COM_CODIGO)
    ''');
  }

  Future<void> _createDB(Database db, int version) async {
    // Tabela TB_MESA espelhada do ERP
    await db.execute('''
      CREATE TABLE TB_MESA (
        MSA_ID INTEGER PRIMARY KEY,
        MSA_EMPRESA INTEGER NOT NULL,
        MSA_CODIGO TEXT NOT NULL,
        MSA_DESCRICAO TEXT,
        MSA_NR_PESSOAS INTEGER DEFAULT 4,
        MSA_STATUS TEXT NOT NULL DEFAULT 'A'
      )
    ''');

    // Tabela TB_COMANDA
    await db.execute('''
      CREATE TABLE TB_COMANDA (
        COM_ID INTEGER PRIMARY KEY,
        COM_EMPRESA INTEGER NOT NULL,
        COM_CODIGO TEXT NOT NULL,
        COM_DESCRICAO TEXT,
        COM_STATUS TEXT NOT NULL DEFAULT 'A'
      )
    ''');


    // Tabela TB_INGRESSO espelhada do ERP para auditoria e histórico de check-in / check-out
    await db.execute('''
      CREATE TABLE TB_INGRESSO (
        ING_EMPRESA INTEGER NOT NULL,
        ING_ID INTEGER NOT NULL,
        ING_STATUS TEXT NOT NULL DEFAULT 'A',
        ING_USUARIO INTEGER DEFAULT 1,
        ING_DT_LANCAMENTO TEXT,
        ING_DT_EMISSAO TEXT,
        ING_DT_EVENTO TEXT,
        ING_HR_EVENTO TEXT,
        ING_DT_ENTRADA TEXT,
        ING_DT_SAIDA TEXT,
        ING_DURACAO INTEGER DEFAULT 0,
        ING_PESSOA INTEGER,
        ING_TIPO_INGRESSO INTEGER DEFAULT 1,
        ING_VALOR REAL DEFAULT 0.0,
        ING_OBSERVACAO TEXT,
        ING_PEDIDO INTEGER,
        ING_CODIGO TEXT NOT NULL,
        ING_TOTAL_RECEBIDO REAL DEFAULT 0.0,
        ING_TOTAL_PRODUTOS REAL DEFAULT 0.0,
        ING_VALOR_DIFERENCA REAL DEFAULT 0.0,
        ING_CAIXA INTEGER DEFAULT 1,
        ING_FECHAMENTO INTEGER,
        ING_TROCO REAL DEFAULT 0.0,
        ING_TIPO_TROCO TEXT,
        ING_GERAR_FINANCEIRO TEXT DEFAULT 'N',
        PRIMARY KEY (ING_EMPRESA, ING_ID)
      )
    ''');

    // Índices de alta performance
    await db.execute('''
      CREATE INDEX IDX_TB_INGRESSO_MESA_STATUS 
      ON TB_INGRESSO (ING_EMPRESA, ING_CODIGO, ING_STATUS)
    ''');

    await db.execute('''
      CREATE INDEX IDX_TB_INGRESSO_ENTRADA 
      ON TB_INGRESSO (ING_EMPRESA, ING_DT_ENTRADA)
    ''');

    await db.execute('''
      CREATE INDEX IDX_TB_MESA_EMPRESA_CODIGO 
      ON TB_MESA (MSA_EMPRESA, MSA_CODIGO)
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
