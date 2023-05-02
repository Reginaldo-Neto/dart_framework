import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

// Cria uma instância do roteador do Shelf
final app = Router();

// Função que retorna uma resposta com o conteúdo do arquivo 'formulario.html'
Response _formulario(Request request) {
  return Response.ok(File('formulario.html').readAsStringSync(),
      headers: {'Content-Type': 'text/html'});
}

// Função que processa o formulário submetido via POST
Future<Response> _processarFormulario(Request request) async {
  // Lê o corpo da requisição (o formulário submetido)
  final bodyBytes = await request.read().toList();
  // Decodifica o corpo da requisição (que está em bytes) para uma string UTF-8
  final body = utf8.decode(bodyBytes.expand((x) => x).toList());
  // Converte a string contendo o formulário em um mapa de dados
  final formData = Uri.splitQueryString(body);

  // Abre uma conexão com o banco de dados SQLite3
  final conn = sqlite3.open('dados.db');

  // Extrai as informações do formulário do mapa de dados
  final nome = formData['Nome'];
  final sobrenome = formData['Sobrenome'];
  final nascimento = formData['Nascimento'];
  final morte = formData['Morte'];
  final historia = formData['Historia'];

  // Imprime as informações do formulário no console
  print(formData);

  // Cria a tabela 'formulario' no banco de dados (se ela não existir)
  conn.execute('CREATE TABLE IF NOT EXISTS formulario '
      '(id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'nome TEXT, '
      'sobrenome TEXT, '
      'historia VARCHAR(255), '
      'nascimento DATE, '
      'morte DATE NULL);');

  // Insere os dados do formulário na tabela 'formulario'
  conn.execute(
      'INSERT INTO formulario (nome, sobrenome, nascimento, morte, historia) VALUES (?, ?, ?, ?, ?)',
      [nome, sobrenome, nascimento, morte, historia]);

  // Fecha a conexão com o banco de dados
  conn.dispose();

  // Retorna uma resposta de sucesso indicando que os dados foram salvos
  return Response.ok('Dados salvos com sucesso!',
      headers: {'Content-Type': 'text/plain'});
}

// Função principal que configura o roteamento e inicia o servidor
Future<void> main() async {
  // Registra a função '_formulario' para lidar com requisições GET para '/'
  app.get('/', _formulario);
  // Registra a função '_processarFormulario' para lidar com requisições POST para '/'
  app.post('/', _processarFormulario);

  // Inicia o servidor na porta 8080
  var server = await shelf_io.serve(app, InternetAddress.anyIPv4, 8080);
  // Imprime no console a mensagem "Servidor rodando em <endereco>:<porta>"
  print('Servidor rodando em ${server.address}:${server.port}');
}
