import 'package:flutter/services.dart';

/// Formatador de texto que aplica a máscara MM:SS ou HH:MM:SS em tempo real.
class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 1. Remove tudo que não for número (evita letras e caracteres especiais)
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // 2. Limita a 6 dígitos numéricos (HHMMSS)
    if (newText.length > 6) {
      newText = newText.substring(0, 6);
    }

    // 3. Reconstrói a string inserindo os ':' nas posições corretas
    String formatted = '';
    for (int i = 0; i < newText.length; i++) {
      if (i == 2 || i == 4) {
        formatted += ':';
      }
      formatted += newText[i];
    }

    // 4. Retorna o valor atualizado mantendo o cursor na posição correta
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
