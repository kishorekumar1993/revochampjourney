import 'package:flutter/material.dart';


/// A read‑only widget that evaluates formulas like:
///   CONCAT('Documents will be generated for case: ', case_title, ' upon submission.')
///   (base_price + tax) * quantity
class FormulaFieldWidget extends StatelessWidget {
  final String label;
  final String formula;
  final Map<String, dynamic> formValues;

  const FormulaFieldWidget({
    super.key,
    required this.label,
    required this.formula,
    required this.formValues,
  });

  @override
  Widget build(BuildContext context) {
    final result = FormulaEvaluator.evaluate(formula, formValues);
    final displayText = result.isValid ? result.value : 'Error: ${result.error}';

    return TextField(
      readOnly: true,
      controller: TextEditingController(text: displayText),
      decoration: InputDecoration(
        labelText: label,
        helperText: formula,
        errorText: result.isValid ? null : result.error,
      ),
    );
  }
}

/// Evaluation result containing a string value and optional error.
class EvalResult {
  final bool isValid;
  final String value;
  final String? error;

  EvalResult.success(this.value) : isValid = true, error = null;
  EvalResult.failure(this.error) : isValid = false, value = '';
}

/// Evaluates formulas with CONCAT(), arithmetic, and field references.
class FormulaEvaluator {
  static EvalResult evaluate(String formula, Map<String, dynamic> values) {
    try {
      final tokens = _tokenize(formula);
      final ast = _parse(tokens);
      final result = _evaluateNode(ast, values);
      return EvalResult.success(result);
    } catch (e) {
      return EvalResult.failure(e.toString());
    }
  }

  // ---- Tokenization ----
  static List<Token> _tokenize(String input) {
    final regex = RegExp(
      r"\bCONCAT\b|\d+(?:\.\d+)?|\w+(?:\.\w+)?|[()+\-*/]|'[^']*'|,",
      caseSensitive: false,
    );
    final matches = regex.allMatches(input);
    final tokens = <Token>[];
    for (final m in matches) {
      final text = m.group(0)!;
      if (text.toUpperCase() == 'CONCAT') {
        tokens.add(Token.function('CONCAT'));
      } else if (text == '(') {
        tokens.add(Token.lParen());
      } else if (text == ')') {
        tokens.add(Token.rParen());
      } else if (text == '+') {
        tokens.add(Token.plus());
      } else if (text == '-') {
        tokens.add(Token.minus());
      } else if (text == '*') {
        tokens.add(Token.multiply());
      } else if (text == '/') {
        tokens.add(Token.divide());
      } else if (text == ',') {
        tokens.add(Token.comma());
      } else if (double.tryParse(text) != null) {
        tokens.add(Token.number(double.parse(text)));
      } else if (text.startsWith("'") && text.endsWith("'")) {
        tokens.add(Token.string(text.substring(1, text.length - 1)));
      } else {
        tokens.add(Token.identifier(text));
      }
    }
    return tokens;
  }

  // ---- Parser (recursive descent) ----
  static dynamic _parse(List<Token> tokens, [int index = 0]) {
    return _parseExpression(tokens, index);
  }

  static dynamic _parseExpression(List<Token> tokens, int index) {
    return _parseAddSub(tokens, index);
  }

  static dynamic _parseAddSub(List<Token> tokens, int index) {
    var left = _parseMulDiv(tokens, index);
    if (left is ParseError) return left;
    var pos = left.pos;
    while (pos < tokens.length && (tokens[pos].type == TokenType.plus || tokens[pos].type == TokenType.minus)) {
      final op = tokens[pos];
      pos++;
      final right = _parseMulDiv(tokens, pos);
      if (right is ParseError) return right;
      pos = right.pos;
      left = ParseResult(AstNode.binary(op, left.node, right.node), pos);
    }
    return left;
  }

  static dynamic _parseMulDiv(List<Token> tokens, int index) {
    var left = _parsePrimary(tokens, index);
    if (left is ParseError) return left;
    var pos = left.pos;
    while (pos < tokens.length && (tokens[pos].type == TokenType.multiply || tokens[pos].type == TokenType.divide)) {
      final op = tokens[pos];
      pos++;
      final right = _parsePrimary(tokens, pos);
      if (right is ParseError) return right;
      pos = right.pos;
      left = ParseResult(AstNode.binary(op, left.node, right.node), pos);
    }
    return left;
  }

  static dynamic _parsePrimary(List<Token> tokens, int index) {
    if (index >= tokens.length) return ParseError('Unexpected end');
    final token = tokens[index];
    switch (token.type) {
      case TokenType.number:
        return ParseResult(AstNode.number(token.value!), index + 1);
      case TokenType.identifier:
        return ParseResult(AstNode.identifier(token.lexeme!), index + 1);
      case TokenType.string:
        return ParseResult(AstNode.stringValue(token.lexeme!), index + 1);
      case TokenType.function:
        if (token.lexeme!.toUpperCase() == 'CONCAT') {
          // CONCAT( ... )
          final next = index + 1;
          if (next >= tokens.length || tokens[next].type != TokenType.lParen) {
            return ParseError('Expected ( after CONCAT');
          }
          // parse arguments until closing )
          final argsResult = _parseFunctionArgs(tokens, next + 1);
          if (argsResult is ParseError) return argsResult;
          final (args, endPos) = argsResult;
          if (endPos >= tokens.length || tokens[endPos].type != TokenType.rParen) {
            return ParseError('Expected ) after CONCAT arguments');
          }
          return ParseResult(AstNode.functionCall('CONCAT', args), endPos + 1);
        } else {
          return ParseError('Unsupported function: ${token.lexeme}');
        }
      case TokenType.lParen:
        final inner = _parseExpression(tokens, index + 1);
        if (inner is ParseError) return inner;
        if (inner.pos >= tokens.length || tokens[inner.pos].type != TokenType.rParen) {
          return ParseError('Missing )');
        }
        return ParseResult(inner.node, inner.pos + 1);
      default:
        return ParseError('Unexpected token ${token.lexeme}');
    }
  }

  static dynamic _parseFunctionArgs(List<Token> tokens, int start) {
    final args = <AstNode>[];
    int pos = start;
    while (pos < tokens.length && tokens[pos].type != TokenType.rParen) {
      if (tokens[pos].type == TokenType.comma) {
        pos++;
        continue;
      }
      final arg = _parseExpression(tokens, pos);
      if (arg is ParseError) return arg;
      args.add(arg.node);
      pos = arg.pos;
      if (pos < tokens.length && tokens[pos].type == TokenType.comma) {
        pos++;
      }
    }
    return (args, pos);
  }

  static String _evaluateNode(AstNode node, Map<String, dynamic> values) {
    switch (node.type) {
      case NodeType.number:
        return node.value!.toString();
      case NodeType.identifier:
        final val = values[node.name];
        if (val == null) throw Exception('Field "${node.name}" not found');
        return val.toString();
      case NodeType.stringValue:
        return node.stringValue!;
      case NodeType.binary:
        final left = _evaluateNode(node.left!, values);
        final right = _evaluateNode(node.right!, values);
        final leftNum = double.tryParse(left);
        final rightNum = double.tryParse(right);
        if (leftNum == null || rightNum == null) {
          throw Exception('Cannot perform arithmetic on non-numeric values: "$left" or "$right"');
        }
        double result;
        switch (node.op?.type) {
          case TokenType.plus:
            result = leftNum + rightNum;
            break;
          case TokenType.minus:
            result = leftNum - rightNum;
            break;
          case TokenType.multiply:
            result = leftNum * rightNum;
            break;
          case TokenType.divide:
            if (rightNum == 0) throw Exception('Division by zero');
            result = leftNum / rightNum;
            break;
          default:
            throw Exception('Unknown operator');
        }
        // Format without trailing .0 if integer
        if (result == result.roundToDouble()) {
          return result.round().toString();
        }
        return result.toStringAsFixed(2);
      case NodeType.functionCall:
        if (node.funcName == 'CONCAT') {
          final args = node.funcArgs!;
          final parts = <String>[];
          for (final arg in args) {
            parts.add(_evaluateNode(arg, values));
          }
          return parts.join('');
        } else {
          throw Exception('Unknown function: ${node.funcName}');
        }
    }
  }
}

// ---- Token and AST Definitions ----
enum TokenType {
  lParen,
  rParen,
  plus,
  minus,
  multiply,
  divide,
  number,
  identifier,
  string,
  comma,
  function,
}

class Token {
  final TokenType type;
  final String? lexeme;
  final double? value;
  Token(this.type, {this.lexeme, this.value});
  Token.number(double v) : type = TokenType.number, value = v, lexeme = v.toString();
  Token.string(String s) : type = TokenType.string, lexeme = s, value = null;
  Token.identifier(String s) : type = TokenType.identifier, lexeme = s, value = null;
  Token.function(String s) : type = TokenType.function, lexeme = s, value = null;
  static Token lParen() => Token(TokenType.lParen, lexeme: '(');
  static Token rParen() => Token(TokenType.rParen, lexeme: ')');
  static Token plus() => Token(TokenType.plus, lexeme: '+');
  static Token minus() => Token(TokenType.minus, lexeme: '-');
  static Token multiply() => Token(TokenType.multiply, lexeme: '*');
  static Token divide() => Token(TokenType.divide, lexeme: '/');
  static Token comma() => Token(TokenType.comma, lexeme: ',');
}

enum NodeType { number, identifier, stringValue, binary, functionCall }

class AstNode {
  final NodeType type;
  final double? value;
  final String? name;
  final String? stringValue;
  final Token? op;
  final AstNode? left;
  final AstNode? right;
  final String? funcName;
  final List<AstNode>? funcArgs;

  AstNode.number(this.value)
      : type = NodeType.number,
        name = null,
        stringValue = null,
        op = null,
        left = null,
        right = null,
        funcName = null,
        funcArgs = null;

  AstNode.identifier(this.name)
      : type = NodeType.identifier,
        value = null,
        stringValue = null,
        op = null,
        left = null,
        right = null,
        funcName = null,
        funcArgs = null;

  AstNode.stringValue(this.stringValue)
      : type = NodeType.stringValue,
        value = null,
        name = null,
        op = null,
        left = null,
        right = null,
        funcName = null,
        funcArgs = null;

  AstNode.binary(this.op, this.left, this.right)
      : type = NodeType.binary,
        value = null,
        name = null,
        stringValue = null,
        funcName = null,
        funcArgs = null;

  AstNode.functionCall(this.funcName, this.funcArgs)
      : type = NodeType.functionCall,
        value = null,
        name = null,
        stringValue = null,
        op = null,
        left = null,
        right = null;
}

class ParseResult {
  final AstNode node;
  final int pos;
  ParseResult(this.node, this.pos);
}

class ParseError {
  final String message;
  ParseError(this.message);
}