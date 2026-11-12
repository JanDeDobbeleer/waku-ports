.pragma library

function isMathExpression(expression) {
  if (!/^[\d\s\+\-\*\/\(\)\.\%\^a-zA-Z,]+$/.test(expression))
    return false;
  if (!/[+\-*/%\^]/.test(expression) && !/[a-zA-Z]\s*\(/.test(expression))
    return false;
  if (/[+\-*/%\^]\s*$/.test(expression))
    return false;
  return !/^[a-zA-Z\s]+$/.test(expression);
}

function getResults(query, advancedMath, i18n, iconMode, provider, os, toastService, launcher) {
  if (!query)
    return [];
  const trimmed = query.trim();
  if (!trimmed || !isMathExpression(trimmed))
    return [];
  try {
    const result = advancedMath.evaluate(trimmed);
    const formattedResult = advancedMath.formatResult(result);
    return [{
      "name": formattedResult,
      "description": i18n.tr("launcher.providers.calculator-press-enter-to-copy"),
      "icon": iconMode === "tabler" ? "calculator" : "accessories-calculator",
      "isTablerIcon": true,
      "isImage": false,
      "provider": provider,
      "onActivate": function () {
        os.copy(formattedResult);
        toastService.showNotice(i18n.tr("common.copied-to-clipboard"), formattedResult, undefined);
        if (launcher)
          launcher.close();
      }
    }];
  } catch (error) {
    return [];
  }
}
