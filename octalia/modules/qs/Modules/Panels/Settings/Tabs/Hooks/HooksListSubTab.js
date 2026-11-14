.pragma library

function setPopupCallbacks(popup, onSave, onTest) {
  try { popup.saved.disconnect(popup._savedSlot); } catch (e) {}
  try { popup.test.disconnect(popup._testSlot); } catch (e) {}
  popup._savedSlot = onSave;
  popup._testSlot = onTest;
  popup.saved.connect(popup._savedSlot);
  popup.test.connect(popup._testSlot);
}
