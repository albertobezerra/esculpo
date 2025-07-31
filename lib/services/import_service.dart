// lib/services/import_service.dart
abstract class ImportService {
  Future<void> importFromPdf(String filePath);
  Future<void> importFromSpreadsheet(String filePath);
}
