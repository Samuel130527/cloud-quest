
import 'package:cloud_functions/cloud_functions.dart';

class CompletionService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<Map<String, dynamic>> completeToday() async {
    try {
      final callable = _functions.httpsCallable('completeToday');
      final result = await callable.call();

      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      print('FUNCTION ERROR CODE: ${e.code}');
      print('FUNCTION ERROR MESSAGE: ${e.message}');
      print('FUNCTION ERROR DETAILS: ${e.details}');

      throw Exception('Function error: ${e.code} - ${e.message}');
    } catch (e) {
      print('UNKNOWN COMPLETION ERROR: $e');
      rethrow;
    }
  }
}
