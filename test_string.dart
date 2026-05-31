void main() {
  var val = 'a';
  var indent = '  ';
  var key = 'test';
  var valStr = val is String ? "'${val.replaceAll("'", "\\'")}'" : val;
  print("$indent  $key: $valStr,");
}