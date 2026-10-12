const http = require('http');
const { exec } = require('child_process');
const fs = require('fs');

const PORTA = 8082;
const ISQL_PATH = 'C:\\Program Files\\Firebird\\Firebird_5_0\\isql.exe';
const DB_PATH = 'localhost/3060:C:\\Users\\Walter\\OneDrive\\DADOS\\MANSAO\\DADOS.FDB';
const DB_USER = 'SYSDBA';
const DB_PASS = 'masterkey';

function executarIsql(sqlComandos, callback) {
  const tempScript = `temp_script_${Date.now()}.sql`;
  const conteudo = `SET HEADING OFF;\n${sqlComandos}\nCOMMIT;\nQUIT;\n`;

  fs.writeFileSync(tempScript, conteudo, 'utf8');

  const cmd = `"${ISQL_PATH}" -u ${DB_USER} -p ${DB_PASS} -q "${DB_PATH}" -i "${tempScript}"`;

  exec(cmd, { windowsHide: true }, (error, stdout, stderr) => {
    try {
      if (fs.existsSync(tempScript)) fs.unlinkSync(tempScript);
    } catch (_) {}

    if (error && stderr && !stdout) {
      return callback(error, null);
    }
    return callback(null, stdout);
  });
}

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    return res.end();
  }

  // Rota de Teste de Conexão e Status
  if (req.url === '/api/status' || req.url === '/VerificarVersao') {
    executarIsql('SHOW DATABASE;', (err, out) => {
      if (err) {
        res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({ status: 'ERRO', mensagem: err.message }));
      }
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({
        status: 'OK',
        versao: 'Firebird 5.0 (ODS 13.1)',
        banco: DB_PATH,
        porta: PORTA
      }));
    });
    return;
  }

  // Rota para Listar as 75 Mesas da TB_MESA
  if (req.url === '/api/mesas' || req.url.startsWith('/api/mesas')) {
    const sql = `SELECT MSA_ID || ';' || COALESCE(MSA_EMPRESA, 1) || ';' || TRIM(MSA_CODIGO) || ';' || COALESCE(TRIM(MSA_DESCRICAO), '') || ';' || COALESCE(MSA_NR_PESSOAS, 4) || ';' || COALESCE(MSA_STATUS, 'A') FROM TB_MESA ORDER BY MSA_ID;`;

    executarIsql(sql, (err, out) => {
      if (err) {
        res.writeHead(500, { 'Content-Type': 'application/json; charset=utf-8' });
        return res.end(JSON.stringify({ status: 'ERRO', mensagem: err.message }));
      }

      const mesas = [];
      const linhas = (out || '').split(/\r?\n/);
      for (const linha of linhas) {
        const l = linha.trim();
        if (!l || l.startsWith('Database:') || l.startsWith('SQL>')) continue;
        const partes = l.split(';');
        if (partes.length >= 6) {
          const id = parseInt(partes[0].trim(), 10);
          const emp = parseInt(partes[1].trim(), 10) || 1;
          const codigo = partes[2].trim();
          const desc = partes[3].trim() || `Mesa ${codigo}`;
          const nrPessoas = parseInt(partes[4].trim(), 10) || 4;
          const status = partes[5].trim();

          if (id > 0 && codigo) {
            mesas.push({
              MSA_ID: id,
              MSA_EMPRESA: emp,
              MSA_CODIGO: codigo,
              MSA_DESCRICAO: desc,
              MSA_NR_PESSOAS: nrPessoas,
              MSA_STATUS: status
            });
          }
        }
      }

      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ total: mesas.length, data: mesas }));
    });
    return;
  }

  // Rota para Ingressos em Aberto (TB_INGRESSO)
  if (req.url === '/api/ingressos/abertos' || req.url.startsWith('/api/ingressos/abertos')) {
    const sql = `SELECT ING_EMPRESA || ';' || ING_ID || ';' || ING_CODIGO || ';' || COALESCE(ING_STATUS, 'A') || ';' || COALESCE(ING_DT_ENTRADA, '') FROM TB_INGRESSO WHERE ING_STATUS = 'A' ORDER BY ING_ID ASC;`;

    executarIsql(sql, (err, out) => {
      const ingressos = [];
      if (!err && out) {
        const linhas = out.split(/\r?\n/);
        for (const linha of linhas) {
          const l = linha.trim();
          if (!l || l.startsWith('Database:') || l.startsWith('SQL>')) continue;
          const partes = l.split(';');
          if (partes.length >= 5) {
            ingressos.push({
              ING_EMPRESA: parseInt(partes[0], 10),
              ING_ID: parseInt(partes[1], 10),
              ING_CODIGO: partes[2],
              ING_STATUS: partes[3],
              ING_DT_ENTRADA: partes[4]
            });
          }
        }
      }
      res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
      res.end(JSON.stringify({ total: ingressos.length, data: ingressos }));
    });
    return;
  }

  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ erro: 'Rota não encontrada' }));
});

server.listen(PORTA, '0.0.0.0', () => {
  console.log('================================================================');
  console.log(`[SERVIDOR BRIDGE FIREBIRD 5.0 ATIVO]`);
  console.log(`Escutando na porta: ${PORTA}`);
  console.log(`IP local na rede Wi-Fi: http://192.168.0.109:${PORTA}`);
  console.log(`Base de dados: ${DB_PATH}`);
  console.log('================================================================');
});
