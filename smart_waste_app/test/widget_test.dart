import 'package:flutter_test/flutter_test.dart';
import 'package:smart_waste_app/services/tflite_service.dart';

void main() {
  group('TFLiteService Mapping Tests', () {
    test('getWasteCategory maps categories correctly', () {
      final service = TFLiteService();
      expect(service.getWasteCategory('vegetation'), 'Organik');
      expect(service.getWasteCategory('food organics'), 'Organik');
      expect(service.getWasteCategory('plastic'), 'Anorganik');
      expect(service.getWasteCategory('paper'), 'Anorganik');
      expect(service.getWasteCategory('unknown'), 'Anorganik'); // Default fallback
    });

    test('getTranslatedLabel translates labels correctly', () {
      final service = TFLiteService();
      expect(service.getTranslatedLabel('vegetation'), 'Vegetasi');
      expect(service.getTranslatedLabel('plastic'), 'Plastik');
      expect(service.getTranslatedLabel('food organics'), 'Sisa Makanan');
      expect(service.getTranslatedLabel('unknown'), 'unknown'); // Fallback to input
    });
  });
}

