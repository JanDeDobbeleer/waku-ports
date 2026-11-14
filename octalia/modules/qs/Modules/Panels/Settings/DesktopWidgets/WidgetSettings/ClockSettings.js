.pragma library

function watchInput(input, root, formatInput) {
  if (input) {
    input.activeFocusChanged.connect(function () {
      if (input.activeFocus) {
        root.focusedInput = formatInput;
      }
    });
  }
}

function insertToken(root, formatInput, token) {
  let focusedInput = root.focusedInput;
  if (!focusedInput || !focusedInput.inputItem) {
    if (formatInput.inputItem) {
      formatInput.inputItem.focus = true;
      focusedInput = formatInput;
      root.focusedInput = focusedInput;
    }
  }
  if (focusedInput && focusedInput.inputItem) {
    const input = focusedInput.inputItem;
    const cursorPos = input.cursorPosition;
    const currentText = input.text;
    const newText = currentText.substring(0, cursorPos) + token + currentText.substring(cursorPos);
    input.text = newText + " ";
    input.cursorPosition = cursorPos + token.length + 1;
    input.focus = true;
    root.saveSettings();
  }
}
