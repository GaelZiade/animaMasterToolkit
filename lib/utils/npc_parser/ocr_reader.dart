import 'dart:js_interop';
import 'dart:typed_data';

/// Puente con `web/ocr.js`, que lee capturas con Tesseract.js en el navegador.
@JS('amtOcr')
external _AmtOcr? get _amtOcr;

extension type _AmtOcr(JSObject _) implements JSObject {
  external JSPromise<JSString> recognize(JSAny image, JSFunction onProgress);
  external void listenPaste(JSFunction onImage);
  external void stopPaste();
}

abstract class OcrReader {
  static bool get available => _amtOcr != null;

  /// Texto de una imagen: bytes de un archivo o un Blob pegado.
  static Future<String> read(Object image, {void Function(String status, double progress)? onProgress}) async {
    final ocr = _amtOcr;

    if (ocr == null) throw StateError('El lector de imágenes no está disponible en este navegador.');

    final source = image is Uint8List ? image.toJS : image as JSAny;
    final text = await ocr
        .recognize(
          source,
          ((JSString status, JSNumber progress) => onProgress?.call(status.toDart, progress.toDartDouble)).toJS,
        )
        .toDart;

    return text.toDart;
  }

  /// Llama a [onImage] con cada imagen que se pegue con Ctrl+V.
  static void listenPaste(void Function(JSAny image) onImage) {
    _amtOcr?.listenPaste(((JSAny image) => onImage(image)).toJS);
  }

  static void stopPaste() => _amtOcr?.stopPaste();
}
