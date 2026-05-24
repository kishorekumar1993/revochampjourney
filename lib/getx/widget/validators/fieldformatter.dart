String generatefieldformatterClass(
 ) {
   StringBuffer buffer = StringBuffer();
buffer.writeln(r"	import 'package:flutter/services.dart';	");
buffer.writeln(r"		");
buffer.writeln(r"	class FieldFormatters {	");
buffer.writeln(r"	  static TextInputFormatter date({String separator = '/'}) =>	");
buffer.writeln(r"	      FilteringTextInputFormatter.allow(RegExp('[0-9$separator]'));	");
buffer.writeln(r"		");
buffer.writeln(r"	  static TextInputFormatter name() =>	");
buffer.writeln(r"	      FilteringTextInputFormatter.allow(RegExp('[a-zA-Z ]'));	");
buffer.writeln(r"		");
buffer.writeln(r"	  static TextInputFormatter mobile() =>	");
buffer.writeln(r"	      FilteringTextInputFormatter.allow(RegExp('[0-9]'));	");
buffer.writeln(r"		");
buffer.writeln(r"	  static TextInputFormatter amount({bool allowDecimal = true}) =>	");
buffer.writeln(r"	      FilteringTextInputFormatter.allow(	");
buffer.writeln(r"	        allowDecimal ? RegExp(r'[0-9.]') : RegExp('[0-9]'),	");
buffer.writeln(r"	      );	");
buffer.writeln(r"		");
buffer.writeln(r"	  static TextInputFormatter email() =>	");
buffer.writeln(r"	      FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9@._-]'));	");
buffer.writeln(r"		");
buffer.writeln(r"	  static TextInputFormatter alphabetsOnly() =>	");
buffer.writeln(r"	      FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]'));	");
buffer.writeln(r"		");
buffer.writeln(r"	  static TextInputFormatter alphaNumeric() =>	");
buffer.writeln(r"	      FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]'));	");
buffer.writeln(r"		");
buffer.writeln(r"	  static TextInputFormatter noSpecialCharacters() =>	");
buffer.writeln(r"	      FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9 ]'));	");
buffer.writeln(r"	}	");
  return buffer.toString().replaceAll('\u00A0', ' ');
}
