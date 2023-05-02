import 'dart:io';
import 'models.dart'; // importa o arquivo models.dart, que contém as classes Texto, Data e Frase
import 'dart:mirrors';
export 'reflexao.dart'; // exporta o arquivo reflexao.dart

import 'package:sqlite3/sqlite3.dart'; // importa a biblioteca sqlite3

String gerar_form(dynamic campos) {
  // função que gera um formulário HTML a partir de um objeto campos

  String html =
      '<!DOCTYPE html><html><head><title>Formulário</title></head><body><form method="POST">'; // inicializa a string html com a estrutura básica do formulário HTML

  InstanceMirror instanceMirror = reflect(campos); // cria um InstanceMirror do objeto campos
  ClassMirror classMirror = instanceMirror.type; // cria um ClassMirror da classe do objeto campos

  for (var fieldName in classMirror.instanceMembers.keys) { // itera sobre as chaves dos membros de instância da classe
    var field = classMirror.declarations[fieldName]; // recupera a declaração do membro de instância
    if (field is VariableMirror) { // se o membro for uma variável
      MirrorSystem.getName(field.simpleName); // recupera o nome da variável

      var fieldType = field.type.reflectedType; // recupera o tipo da variável

      if (fieldType == Texto) { // se o tipo da variável for Texto
        var texto =
            instanceMirror.getField(field.simpleName).reflectee as Texto; // recupera o valor do campo Texto
        html +=
            '<label for="${texto.nome}">${texto.verboso}:</label><br><input type="text" name="${texto.nome}" id="${texto.id}" /> <br>'; // adiciona uma label e um input ao html com as propriedades do campo Texto
      } else if (fieldType == Data) { // se o tipo da variável for Data
        var data = instanceMirror.getField(field.simpleName).reflectee as Data; // recupera o valor do campo Data
        html +=
            '<label for="${data.nome}">${data.verboso}:</label><br><input type="date" name="${data.nome}" id="${data.id}" /> <br>'; // adiciona uma label e um input ao html com as propriedades do campo Data
      } else if (fieldType == Frase) { // se o tipo da variável for Frase
        var frase =
            instanceMirror.getField(field.simpleName).reflectee as Frase; // recupera o valor do campo Frase
        html +=
            '<label for="${frase.nome}">${frase.verboso}:</label><br><textarea name="${frase.nome}" id="${frase.id}"></textarea> <br>'; // adiciona uma label e uma textarea ao html com as propriedades do campo Frase
      }
    }
  }

  html += '<button type="submit">Enviar</button> <br></form></body></html>'; // adiciona um botão Enviar ao html e finaliza a string html

  File('formulario.html').writeAsString(html); // escreve o conteúdo do formulário no arquivo formulario.html

  return html; // retorna o html gerado
}

// Função responsável por gerar uma tabela no banco de dados
// Recebe como parâmetro um objeto campos dinâmico
// Retorna uma string com a tabela gerada
String gerar_tabela(dynamic campos) {
  var file = File('dados.db');
  
  // Verifica se o arquivo do banco de dados existe, caso não exista cria um novo
  if (!file.existsSync()) {
    file.createSync();
  }

  // Abre a conexão com o banco de dados
  var db = sqlite3.open('dados.db');

  // Obtém um objeto InstanceMirror a partir do objeto campos dinâmico
  InstanceMirror instanceMirror = reflect(campos);

  // Obtém um objeto ClassMirror a partir do objeto campos dinâmico
  ClassMirror classMirror = instanceMirror.type;

  // Cria um conjunto vazio para armazenar os nomes dos campos adicionados na tabela
  Set<String> camposAdicionados = {};

  // String que armazenará a tabela gerada
  String tabela = '';

  // Função auxiliar que modifica o nome do campo original caso já exista na tabela
  String criarNomeModificado(String nomeOriginal) {
    // Verifica quantas vezes o campo com o nome original já foi adicionado na tabela
    int contador =
        camposAdicionados.where((campo) => campo == nomeOriginal).length;
    // Adiciona o nome do campo original ao conjunto de campos adicionados na tabela
    camposAdicionados.add(nomeOriginal);
    // Retorna o nome original modificado com um sufixo numérico caso já exista na tabela
    return contador > 0 ? "$nomeOriginal$contador" : nomeOriginal;
  }

  // Itera sobre os campos da classe representada pelo objeto campos
  for (var fieldName in classMirror.instanceMembers.keys) {
    var field = classMirror.declarations[fieldName];
    if (field is VariableMirror) {
      String name = MirrorSystem.getName(field.simpleName);
      var fieldType = field.type.reflectedType;

      // Cria um nome modificado para o campo original
      String nomeModificado = criarNomeModificado(name);

      // Adiciona o tipo de dado na string da tabela de acordo com o tipo do campo
      if (fieldType == Texto) {
        instanceMirror.getField(field.simpleName).reflectee as Texto;
        tabela += '$nomeModificado TEXT,';
      } else if (fieldType == Data) {
        instanceMirror.getField(field.simpleName).reflectee as Data;
        tabela += '$nomeModificado DATE,';
      } else if (fieldType == Frase) {
        instanceMirror.getField(field.simpleName).reflectee as Frase;
        tabela += '$nomeModificado TEXT,';
      }
    }
  }

  // Remove a última vírgula da string da tabela gerada
  tabela = tabela.substring(0, tabela.length - 1);

  // Deleta a tabela "formulario" caso já exista no banco de dados e cria uma nova tabela com a string da tabela gerada
  db.execute('DROP TABLE IF EXISTS formulario ');
  db.execute('CREATE TABLE IF NOT EXISTS formulario ($tabela)');

  // Retorna a string da tabela gerada
  return tabela;
}
