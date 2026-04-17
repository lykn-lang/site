(() => {
  const LYKN_KW = new Set([
    'bind', 'func', 'fn', 'lambda', 'if', 'if-let', 'when-let',
    'match', 'type', 'cell', 'swap!', 'reset!', 'express', 'set!',
    'import', 'export', 'async', 'await', 'try', 'catch', 'finally',
    'for-of', 'for-in', 'for', 'while', 'do-while', 'class',
    '->', '->>', 'some->', 'some->>', 'defmacro', 'template',
    'obj', 'new', 'return', 'throw', 'delete', 'typeof',
    'assoc', 'dissoc', 'conj', 'cond', 'and', 'or', 'not',
    'assign', 'import-macros'
  ]);

  const JS_KW = new Set([
    'const', 'let', 'var', 'function', 'return', 'if', 'else',
    'throw', 'new', 'class', 'extends', 'import', 'export',
    'from', 'async', 'await', 'try', 'catch', 'finally',
    'for', 'while', 'do', 'switch', 'case', 'break', 'continue',
    'typeof', 'instanceof', 'delete', 'void', 'in', 'of'
  ]);

  function span(cls, text) {
    return '<span class="' + cls + '">' + esc(text) + '</span>';
  }

  function esc(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  function highlightLykn(src) {
    let out = '';
    let i = 0;
    while (i < src.length) {
      // comments
      if (src[i] === ';' && src[i + 1] === ';') {
        let end = src.indexOf('\n', i);
        if (end === -1) end = src.length;
        out += span('sc', src.slice(i, end));
        i = end;
        continue;
      }
      // strings
      if (src[i] === '"') {
        let j = i + 1;
        while (j < src.length && src[j] !== '"') {
          if (src[j] === '\\') j++;
          j++;
        }
        j++;
        out += span('ss', src.slice(i, j));
        i = j;
        continue;
      }
      // keywords (:name)
      if (src[i] === ':' && i + 1 < src.length && /[a-zA-Z]/.test(src[i + 1])) {
        let j = i + 1;
        while (j < src.length && /[a-zA-Z0-9_-]/.test(src[j])) j++;
        out += span('st', src.slice(i, j));
        i = j;
        continue;
      }
      // numbers (standalone)
      if (/[0-9]/.test(src[i]) && (i === 0 || /[\s(,]/.test(src[i - 1]))) {
        let j = i;
        while (j < src.length && /[0-9.]/.test(src[j])) j++;
        if (j >= src.length || /[\s),;\]]/.test(src[j])) {
          out += span('sn', src.slice(i, j));
          i = j;
          continue;
        }
      }
      // atoms (identifiers, keywords, operators)
      if (/[a-zA-Z_!?<>=+\-*/%&|^~]/.test(src[i])) {
        let j = i;
        while (j < src.length && /[a-zA-Z0-9_!?<>=+\-*/%&|^~:.]/.test(src[j])) j++;
        const word = src.slice(i, j);
        if (LYKN_KW.has(word)) {
          out += span('sk', word);
        } else if (word.includes(':') || word.includes('.')) {
          out += span('sf', word);
        } else {
          out += span('sf', word);
        }
        i = j;
        continue;
      }
      // hash dispatch (#a, #t, #f)
      if (src[i] === '#') {
        let j = i + 1;
        while (j < src.length && /[a-zA-Z]/.test(src[j])) j++;
        out += span('sk', src.slice(i, j));
        i = j;
        continue;
      }
      out += esc(src[i]);
      i++;
    }
    return out;
  }

  function highlightJS(src) {
    let out = '';
    let i = 0;
    while (i < src.length) {
      // line comments
      if (src[i] === '/' && src[i + 1] === '/') {
        let end = src.indexOf('\n', i);
        if (end === -1) end = src.length;
        out += span('sc', src.slice(i, end));
        i = end;
        continue;
      }
      // block comments
      if (src[i] === '/' && src[i + 1] === '*') {
        let end = src.indexOf('*/', i + 2);
        if (end === -1) end = src.length; else end += 2;
        out += span('sc', src.slice(i, end));
        i = end;
        continue;
      }
      // strings
      if (src[i] === '"' || src[i] === "'" || src[i] === '`') {
        const q = src[i];
        let j = i + 1;
        while (j < src.length && src[j] !== q) {
          if (src[j] === '\\') j++;
          j++;
        }
        j++;
        out += span('ss', src.slice(i, j));
        i = j;
        continue;
      }
      // numbers
      if (/[0-9]/.test(src[i]) && (i === 0 || /[\s(,;=:+\-*/<>!&|^~?[\]{]/.test(src[i - 1]))) {
        let j = i;
        while (j < src.length && /[0-9.eE_xXa-fA-F]/.test(src[j])) j++;
        out += span('sn', src.slice(i, j));
        i = j;
        continue;
      }
      // identifiers & keywords
      if (/[a-zA-Z_$]/.test(src[i])) {
        let j = i;
        while (j < src.length && /[a-zA-Z0-9_$]/.test(src[j])) j++;
        const word = src.slice(i, j);
        if (JS_KW.has(word)) {
          out += span('sk', word);
        } else if (j < src.length && src[j] === '(') {
          out += span('sf', word);
        } else {
          out += span('sf', word);
        }
        i = j;
        continue;
      }
      // arrow
      if (src[i] === '=' && src[i + 1] === '>') {
        out += span('sk', '=>');
        i += 2;
        continue;
      }
      out += esc(src[i]);
      i++;
    }
    return out;
  }

  function isLykn(text) {
    const trimmed = text.trimStart();
    return trimmed.startsWith('(') || trimmed.startsWith(';');
  }

  document.querySelectorAll('.prose pre code').forEach(el => {
    const raw = el.textContent;
    el.innerHTML = isLykn(raw) ? highlightLykn(raw) : highlightJS(raw);
  });
})();
