String generatedatefieldClass(
 ) {
   StringBuffer buffer = StringBuffer();

buffer.writeln(r"	import 'package:flutter/material.dart';	");
buffer.writeln(r"	import 'package:flutter/services.dart';	");
buffer.writeln(r"		");
buffer.writeln(r"	class DateInputFormatter extends TextInputFormatter {	");
buffer.writeln(r"	  final String separator;	");
buffer.writeln(r"		");
buffer.writeln(r"	  DateInputFormatter({this.separator = '/'});	");
buffer.writeln(r"		");
buffer.writeln(r"	  @override	");
buffer.writeln(r"	  TextEditingValue formatEditUpdate(	");
buffer.writeln(r"	    TextEditingValue oldValue,	");
buffer.writeln(r"	    TextEditingValue newValue,	");
buffer.writeln(r"	  ) {	");
buffer.writeln(r"	    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');	");
buffer.writeln(r"		");
buffer.writeln(r"	    if (digitsOnly.length > 8) {	");
buffer.writeln(r"	      digitsOnly = digitsOnly.substring(0, 8);	");
buffer.writeln(r"	    }	");
buffer.writeln(r"		");
buffer.writeln(r"	    final buffer = StringBuffer();	");
buffer.writeln(r"	    for (int i = 0; i < digitsOnly.length; i++) {	");
buffer.writeln(r"	      buffer.write(digitsOnly[i]);	");
buffer.writeln(r"	      if ((i == 1 || i == 3) && i != digitsOnly.length - 1) {	");
buffer.writeln(r"	        buffer.write(separator);	");
buffer.writeln(r"	      }	");
buffer.writeln(r"	    }	");
buffer.writeln(r"		");
buffer.writeln(r"	    final String formatted = buffer.toString();	");
buffer.writeln(r"	    return TextEditingValue(	");
buffer.writeln(r"	      text: formatted,	");
buffer.writeln(r"	      selection: TextSelection.collapsed(offset: formatted.length),	");
buffer.writeln(r"	    );	");
buffer.writeln(r"	  }	");
buffer.writeln(r"	}	");
  return buffer.toString().replaceAll('\u00A0', ' ');
}
