String generatefieldvalidatorClass(
 ) {
  StringBuffer buffer = StringBuffer();

  buffer.writeln(r"	import 'package:intl/intl.dart';  // Add this import	");
  buffer.writeln(r"		");
  buffer.writeln(r"	class FieldValidators {	");
  buffer.writeln(r"	  // 🔒 Required field	");
  buffer.writeln(
    r"	  static String? required(String? value, {String fieldName = 'Field'}) {	",
  );
  buffer.writeln(r"	    if (value == null || value.trim().isEmpty) {	");
  buffer.writeln(r"	      return '$fieldName is required';	");
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) requiredValidator({String fieldName = 'Field'}) {	",
  );
  buffer.writeln(
    r"	    return (value) => required(value, fieldName: fieldName);	",
  );
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(r"	  // 🔡 Min length	");
  buffer.writeln(
    r"	  static String? minLength(String? value, int min, {String fieldName = 'Field'}) {	",
  );
  buffer.writeln(r"	    if (value != null && value.trim().length < min) {	");
  buffer.writeln(
    r"	      return '$fieldName must be at least $min characters';	",
  );
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) minLengthValidator(int min, {String fieldName = 'Field'}) {	",
  );
  buffer.writeln(
    r"	    return (value) => minLength(value, min, fieldName: fieldName);	",
  );
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(r"	  // 🔠 Max length	");
  buffer.writeln(
    r"	  static String? maxLength(String? value, int max, {String fieldName = 'Field'}) {	",
  );
  buffer.writeln(r"	    if (value != null && value.trim().length > max) {	");
  buffer.writeln(
    r"	      return '$fieldName must be maximum $max characters';	",
  );
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) maxLengthValidator(int max, {String fieldName = 'Field'}) {	",
  );
  buffer.writeln(
    r"	    return (value) => maxLength(value, max, fieldName: fieldName);	",
  );
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(r"	  // 📧 Email validation	");
  buffer.writeln(
    r"	  static String? email(String? value, {String fieldName = 'Email'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(
    r"	    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');	",
  );
  buffer.writeln(r"	    if (!regex.hasMatch(value.trim())) {	");
  buffer.writeln(r"	      return 'Please enter valid $fieldName';	");
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) emailValidator({String fieldName = 'Email'}) {	",
  );
  buffer.writeln(
    r"	    return (value) => email(value, fieldName: fieldName);	",
  );
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(r"	  // 📱 Mobile number (10 digits)	");
  buffer.writeln(
    r"	  static String? mobile(String? value, {String fieldName = 'Mobile'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(r"	    final regex = RegExp(r'^[0-9]{10}$');	");
  buffer.writeln(r"	    if (!regex.hasMatch(value.trim())) {	");
  buffer.writeln(r"	      return 'Please enter valid $fieldName';	");
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) mobileValidator({String fieldName = 'Mobile'}) {	",
  );
  buffer.writeln(
    r"	    return (value) => mobile(value, fieldName: fieldName);	",
  );
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(r"	  // 🔍 Regex	");
  buffer.writeln(
    r"	  static String? regex(String? value, String pattern, {String fieldName = 'Field'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(r"	    final regex = RegExp(pattern);	");
  buffer.writeln(r"	    if (!regex.hasMatch(value.trim())) {	");
  buffer.writeln(r"	      return '$fieldName format invalid';	");
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) regexValidator(String pattern, {String fieldName = 'Field'}) {	",
  );
  buffer.writeln(
    r"	    return (value) => regex(value, pattern, fieldName: fieldName);	",
  );
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? numberOnly(String? value, {String fieldName = 'Field'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(r"	    final regex = RegExp(r'^\d+$');	");
  buffer.writeln(r"	    if (!regex.hasMatch(value.trim())) {	");
  buffer.writeln(r"	      return '$fieldName must be a number';	");
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) numberOnlyValidator({String fieldName = 'Field'}) {	",
  );
  buffer.writeln(
    r"	    return (value) => numberOnly(value, fieldName: fieldName);	",
  );
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(r"	  // 🧾 PAN number (India)	");
  buffer.writeln(
    r"	  static String? pan(String? value, {String fieldName = 'PAN'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(r"	    final regex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');	");
  buffer.writeln(r"	    if (!regex.hasMatch(value.trim().toUpperCase())) {	");
  buffer.writeln(r"	      return 'Invalid $fieldName format';	");
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) panValidator({String fieldName = 'PAN'}) =>	",
  );
  buffer.writeln(r"	      (value) => pan(value, fieldName: fieldName);	");
  buffer.writeln(r"		");
  buffer.writeln(r"	  // 🆔 Aadhaar number (12-digit)	");
  buffer.writeln(
    r"	  static String? aadhaar(String? value, {String fieldName = 'Aadhaar'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(r"	    final regex = RegExp(r'^\d{12}$');	");
  buffer.writeln(r"	    if (!regex.hasMatch(value.trim())) {	");
  buffer.writeln(r"	      return 'Invalid $fieldName number';	");
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) aadhaarValidator({String fieldName = 'Aadhaar'}) =>	",
  );
  buffer.writeln(r"	      (value) => aadhaar(value, fieldName: fieldName);	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? alphabetsOnly(String? value, {String fieldName = 'Field'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(r"	    final regex = RegExp(r'^[a-zA-Z ]+$');	");
  buffer.writeln(r"	    if (!regex.hasMatch(value.trim())) {	");
  buffer.writeln(r"	      return '$fieldName must contain only letters';	");
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) alphabetsOnlyValidator({String fieldName = 'Field'}) =>	",
  );
  buffer.writeln(
    r"	      (value) => alphabetsOnly(value, fieldName: fieldName);	",
  );
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? alphaNumeric(String? value, {String fieldName = 'Field'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(r"	    final regex = RegExp(r'^[a-zA-Z0-9]+$');	");
  buffer.writeln(r"	    if (!regex.hasMatch(value.trim())) {	");
  buffer.writeln(r"	      return '$fieldName must be alphanumeric';	");
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) alphaNumericValidator({String fieldName = 'Field'}) =>	",
  );
  buffer.writeln(
    r"	      (value) => alphaNumeric(value, fieldName: fieldName);	",
  );
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? ifsc(String? value, {String fieldName = 'IFSC'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(r"	    final regex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');	");
  buffer.writeln(r"	    if (!regex.hasMatch(value.trim().toUpperCase())) {	");
  buffer.writeln(r"	      return 'Invalid $fieldName code';	");
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) ifscValidator({String fieldName = 'IFSC'}) =>	",
  );
  buffer.writeln(r"	      (value) => ifsc(value, fieldName: fieldName);	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? gst(String? value, {String fieldName = 'GST'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(
    r"	    final regex = RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$');	",
  );
  buffer.writeln(r"	    if (!regex.hasMatch(value.trim().toUpperCase())) {	");
  buffer.writeln(r"	      return 'Invalid $fieldName number';	");
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) gstValidator({String fieldName = 'GST'}) =>	",
  );
  buffer.writeln(r"	      (value) => gst(value, fieldName: fieldName);	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? vehicleNumber(String? value, {String fieldName = 'Vehicle Number'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(
    r"	    final regex = RegExp(r'^[A-Z]{2}[0-9]{1,2}[A-Z]{1,2}[0-9]{4}$'); 	",
  );
  buffer.writeln(r"	    if (!regex.hasMatch(value.trim().toUpperCase())) {	");
  buffer.writeln(r"	      return 'Invalid $fieldName format';	");
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) vehicleNumberValidator({String fieldName = 'Vehicle Number'}) =>	",
  );
  buffer.writeln(
    r"	      (value) => vehicleNumber(value, fieldName: fieldName);	",
  );
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? noSpecialCharacters(String? value, {String fieldName = 'Field'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(r"	    final regex = RegExp(r'^[a-zA-Z0-9\s]+$');	");
  buffer.writeln(r"	    if (!regex.hasMatch(value.trim())) {	");
  buffer.writeln(
    r"	      return '$fieldName must not contain special characters';	",
  );
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) noSpecialCharactersValidator({String fieldName = 'Field'}) =>	",
  );
  buffer.writeln(
    r"	      (value) => noSpecialCharacters(value, fieldName: fieldName);	",
  );
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? numberRange(String? value, num min, num max, {String fieldName = 'Number'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(r"	    final parsed = num.tryParse(value);	");
  buffer.writeln(
    r"	    if (parsed == null || parsed < min || parsed > max) {	",
  );
  buffer.writeln(r"	      return '$fieldName must be between $min and $max';	");
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) numberRangeValidator(num min, num max, {String fieldName = 'Number'}) =>	",
  );
  buffer.writeln(
    r"	      (value) => numberRange(value, min, max, fieldName: fieldName);	",
  );
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? lowerCaseOnly(String? value, {String fieldName = 'Field'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(r"	    final regex = RegExp(r'^[a-z]+$');	");
  buffer.writeln(r"	    if (!regex.hasMatch(value.trim())) {	");
  buffer.writeln(r"	      return '$fieldName must be all lowercase';	");
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) lowerCaseOnlyValidator({String fieldName = 'Field'}) =>	",
  );
  buffer.writeln(
    r"	      (value) => lowerCaseOnly(value, fieldName: fieldName);	",
  );
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? upperCaseOnly(String? value, {String fieldName = 'Field'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(r"	    final regex = RegExp(r'^[A-Z]+$');	");
  buffer.writeln(r"	    if (!regex.hasMatch(value.trim())) {	");
  buffer.writeln(r"	      return '$fieldName must be all uppercase';	");
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) upperCaseOnlyValidator({String fieldName = 'Field'}) =>	",
  );
  buffer.writeln(
    r"	      (value) => upperCaseOnly(value, fieldName: fieldName);	",
  );
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? pastDate(String? value, String format, {String fieldName = 'Date'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(r"	    try {	");
  buffer.writeln(
    r"	      final inputDate = DateFormat(format).parseStrict(value.trim());	",
  );
  buffer.writeln(
    r"	      if (!inputDate.isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {	",
  );
  buffer.writeln(r"	        return '$fieldName must be a past date';	");
  buffer.writeln(r"	      }	");
  buffer.writeln(r"	      return null;	");
  buffer.writeln(r"	    } catch (_) {	");
  buffer.writeln(
    r"	      return 'Invalid $fieldName format (Expected: $format)';	",
  );
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) pastDateValidator(String format, {String fieldName = 'Date'}) =>	",
  );
  buffer.writeln(
    r"	      (value) => pastDate(value, format, fieldName: fieldName);	",
  );
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? futureDate(String? value, String format, {String fieldName = 'Date'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(r"	    try {	");
  buffer.writeln(
    r"	      final inputDate = DateFormat(format).parseStrict(value.trim());	",
  );
  buffer.writeln(
    r"	      if (!inputDate.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {	",
  );
  buffer.writeln(r"	        return '$fieldName must be a future date';	");
  buffer.writeln(r"	      }	");
  buffer.writeln(r"	      return null;	");
  buffer.writeln(r"	    } catch (_) {	");
  buffer.writeln(
    r"	      return 'Invalid $fieldName format (Expected: $format)';	",
  );
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) futureDateValidator(String format, {String fieldName = 'Date'}) =>	",
  );
  buffer.writeln(
    r"	      (value) => futureDate(value, format, fieldName: fieldName);	",
  );
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? decimal(String? value, {int decimalPlaces = 2, String fieldName = 'Amount'}) {	",
  );
  buffer.writeln(
    r"	    if (value == null || value.trim().isEmpty) return null;	",
  );
  buffer.writeln(
    r"	    final regex = RegExp(r'^\d+(\.\d{0,' + decimalPlaces.toString() + r'})?$'); 	",
  );
  buffer.writeln(r"	    if (!regex.hasMatch(value.trim())) {	");
  buffer.writeln(
    r"	      return '$fieldName must be a valid number with up to $decimalPlaces decimal places';	",
  );
  buffer.writeln(r"	    }	");
  buffer.writeln(r"	    return null;	");
  buffer.writeln(r"	  }	");
  buffer.writeln(r"		");
  buffer.writeln(
    r"	  static String? Function(String?) decimalValidator({int decimalPlaces = 2, String fieldName = 'Amount'}) =>	",
  );
  buffer.writeln(
    r"	      (value) => decimal(value, decimalPlaces: decimalPlaces, fieldName: fieldName);	",
  );
  buffer.writeln(r"	}	");
  buffer.writeln(r"		");
  return buffer.toString().replaceAll('\u00A0', ' ');
}
