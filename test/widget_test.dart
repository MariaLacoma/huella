import 'package:flutter_test/flutter_test.dart';
import 'package:huella/main.dart';

void main() {
  testWidgets('La aplicación HUELLA inicia correctamente', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HuellaApp());

    expect(find.text('HUELLA'), findsOneWidget);
    expect(find.text('Encontrá. Ayudá. Reuní.'), findsOneWidget);
    expect(find.text('Buscar mascotas'), findsOneWidget);
    expect(find.text('Registrarme'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}