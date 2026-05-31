void main() {
  var val = 'a';
  var indent = '  ';
  var key = 'test';
  var valStr = "'${val.replaceAll("'", "\\'")}'";
  print("$indent  $key: $valStr,");
}