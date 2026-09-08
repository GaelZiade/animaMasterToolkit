/// Un sumando dentro del cálculo de un resultado.
///
/// Permite mostrar la operación como una lista de términos alineados en vez de
/// una única línea de texto corrido, que es difícil de leer de un vistazo.
class ExplainedTerm {
  const ExplainedTerm(this.label, this.value, {this.isTotal = false});

  /// Nombre del sumando, tal como aparece en las reglas.
  final String label;

  final int value;

  /// Marca la fila del total, que se muestra separada del resto.
  final bool isTotal;
}

class ExplainedText {
  ExplainedText({
    required this.title,
    this.text = '',
    this.explanation = '',
    this.result,
    this.specialRule,
    BookReference? reference,
  }) {
    explanations = [];
    references = [];
    terms = [];

    if (reference != null) {
      references.add(reference);
    }
  }
  String title;
  String text;
  String explanation;
  SpecialRule? specialRule;

  int? result;
  late List<ExplainedText> explanations;
  late List<BookReference> references;

  /// Desglose de la operación, si el cálculo se puede expresar como una suma.
  late List<ExplainedTerm> terms;

  /// Carga el desglose y deja el total como última fila.
  void setTerms(List<ExplainedTerm> newTerms, {required String totalLabel, required int total}) {
    terms = [
      ...newTerms.where((term) => term.value != 0),
      ExplainedTerm(totalLabel, total, isTotal: true),
    ];
  }

  void addExplanation(String newExplanation) {
    explanation = '$explanation\n$newExplanation';
  }

  void addText(String newText) {
    text = '$text\n$newText';
  }

  void add({
    String? text,
    String? explanation,
    BookReference? reference,
    int? result,
    SpecialRule? specialRule,
  }) {
    if (text != null) this.text = this.text.isEmpty ? text : '${this.text}\n$text';
    if (explanation != null) this.explanation = this.explanation.isEmpty ? explanation : '${this.explanation}\n$explanation';
    if (reference != null) references.add(reference);
    if (result != null) this.result = result;
    if (specialRule != null) this.specialRule = specialRule;
  }
}

class BookReference {
  BookReference({
    required this.page,
    required this.book,
  });
  int page;
  Books book;
}

enum Books {
  coreExxet,
  directorsScreen,
  prometheus;

  String get name {
    switch (this) {
      case Books.coreExxet:
        return 'Core Exxet';
      case Books.directorsScreen:
        return 'Pantalla del director';
      case Books.prometheus:
        return 'Prometheus Exxet';
    }
  }
}

enum SpecialRule {
  damageAccumulation,
  uruboros;

  String get name {
    switch (this) {
      case SpecialRule.damageAccumulation:
        return '[DA]';
      case SpecialRule.uruboros:
        return '[UB]';
    }
  }
}
