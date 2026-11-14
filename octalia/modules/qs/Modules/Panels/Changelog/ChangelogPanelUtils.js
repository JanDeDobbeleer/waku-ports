.pragma library

function colorizeHeaders(text, color) {
  if (!text)
    return "";
  return text.replace(/^# (.*)$/gm, `<br/><h1 style="color:${color}">$1</h1><br/>`).replace(/^## (.*)$/gm, `<br/><h2 style="color:${color}">$1</h2><br/>`);
}
