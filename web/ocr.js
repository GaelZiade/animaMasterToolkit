// Lectura de capturas de perfiles (OCR) para "Pegar PNJ".
//
// Tesseract.js corre en el navegador: no hace falta servidor. El motor y el
// idioma español se descargan de jsDelivr la primera vez que se usa, así que la
// aplicación no carga nada extra hasta entonces.
(function () {
  const TESSERACT_URL = 'https://cdn.jsdelivr.net/npm/tesseract.js@5.1.1/dist/tesseract.min.js';

  let enginePromise = null;
  let workerPromise = null;
  let progressListener = null;
  let pasteListener = null;

  function loadEngine() {
    if (window.Tesseract) return Promise.resolve();
    if (enginePromise) return enginePromise;

    enginePromise = new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.src = TESSERACT_URL;
      script.onload = () => resolve();
      script.onerror = () => {
        enginePromise = null;
        reject(new Error('No se pudo descargar el lector de imágenes. Revisá la conexión.'));
      };
      document.head.appendChild(script);
    });

    return enginePromise;
  }

  function getWorker() {
    if (workerPromise) return workerPromise;

    workerPromise = loadEngine()
      .then(() =>
        window.Tesseract.createWorker('spa', 1, {
          logger: (message) => {
            if (!progressListener) return;
            const loading = message.status !== 'recognizing text';
            progressListener(loading ? 'Preparando el lector' : 'Leyendo la imagen', message.progress || 0);
          },
        }),
      )
      .catch((error) => {
        workerPromise = null;
        throw error;
      });

    return workerPromise;
  }

  // Gris y, si la captura es chica, más grande: Tesseract lee mucho mejor el
  // texto chico de los manuales así. Con capturas reales, ×3 confunde menos
  // dígitos que ×2 o que binarizar.
  function prepare(blob) {
    return createImageBitmap(blob).then((bitmap) => {
      const scale = bitmap.width < 900 ? 3 : bitmap.width < 1600 ? 2 : 1;
      const canvas = document.createElement('canvas');
      canvas.width = bitmap.width * scale;
      canvas.height = bitmap.height * scale;

      const context = canvas.getContext('2d');
      context.imageSmoothingQuality = 'high';
      context.filter = 'grayscale(1) contrast(1.3)';
      context.drawImage(bitmap, 0, 0, canvas.width, canvas.height);

      return canvas;
    });
  }

  // Busca el espacio entre dos columnas: una franja vertical casi sin tinta en
  // el tercio central. Tesseract mezcla las columnas renglón por renglón si se
  // le pasa la página entera. Tolera líneas finas que la crucen, como el
  // subrayado de un título.
  function findGutter(canvas) {
    const { width, height } = canvas;
    const pixels = canvas.getContext('2d').getImageData(0, 0, width, height).data;

    let total = 0;
    for (let i = 0; i < pixels.length; i += 4) total += pixels[i];
    const threshold = total / (pixels.length / 4) - 60;

    const ink = new Array(width).fill(0);
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        if (pixels[(y * width + x) * 4] < threshold) ink[x]++;
      }
    }

    const tolerance = Math.max(3, height * 0.02);
    const minimum = Math.max(8, width * 0.015);
    let best = null;
    let start = -1;

    for (let x = Math.floor(width * 0.3); x <= Math.ceil(width * 0.7); x++) {
      const empty = x < width && ink[x] <= tolerance;

      if (empty && start < 0) start = x;
      if (!empty && start >= 0) {
        if (x - start >= minimum && (!best || x - start > best.end - best.start)) best = { start, end: x };
        start = -1;
      }
    }

    if (!best) return null;

    // Dos columnas de verdad tienen texto a los dos lados en casi todos los
    // renglones. Un perfil de una columna con algún dato a la derecha
    // («Clase: Natural 10») no.
    let rowsWithInk = 0;
    let rowsLeft = 0;
    let rowsRight = 0;

    for (let y = 0; y < height; y++) {
      let left = false;
      let right = false;

      for (let x = 0; x < width; x++) {
        if (pixels[(y * width + x) * 4] >= threshold) continue;
        if (x < best.start) left = true;
        if (x >= best.end) right = true;
      }

      if (left || right) rowsWithInk++;
      if (left) rowsLeft++;
      if (right) rowsRight++;
    }

    const balanced = rowsWithInk > 0 && rowsLeft / rowsWithInk > 0.6 && rowsRight / rowsWithInk > 0.6;

    return balanced ? Math.round((best.start + best.end) / 2) : null;
  }

  function crop(canvas, from, to) {
    const part = document.createElement('canvas');
    part.width = to - from;
    part.height = canvas.height;
    part.getContext('2d').drawImage(canvas, from, 0, part.width, part.height, 0, 0, part.width, part.height);

    return part;
  }

  function toBlob(image) {
    if (image instanceof Blob) return image;
    return new Blob([image]);
  }

  window.amtOcr = {
    // Devuelve el texto de la imagen (Blob o bytes).
    recognize(image, onProgress) {
      progressListener = onProgress || null;

      return Promise.all([getWorker(), prepare(toBlob(image))])
        .then(async ([worker, canvas]) => {
          const gutter = findGutter(canvas);
          const parts = gutter ? [crop(canvas, 0, gutter), crop(canvas, gutter, canvas.width)] : [canvas];
          const texts = [];

          // Una columna después de la otra, en orden de lectura.
          for (const part of parts) texts.push((await worker.recognize(part)).data.text);

          return texts.join('\n\n');
        })
        .finally(() => {
          progressListener = null;
        });
    },

    // Avisa cuando se pega una imagen con Ctrl+V mientras está abierto el
    // diálogo.
    listenPaste(onImage) {
      window.amtOcr.stopPaste();

      pasteListener = (event) => {
        const items = (event.clipboardData && event.clipboardData.items) || [];

        for (const item of items) {
          if (item.kind === 'file' && item.type.startsWith('image/')) {
            event.preventDefault();
            onImage(item.getAsFile());
            return;
          }
        }
      };

      document.addEventListener('paste', pasteListener, true);
    },

    stopPaste() {
      if (pasteListener) document.removeEventListener('paste', pasteListener, true);
      pasteListener = null;
    },
  };
})();
