.pragma library

function connectSaved(popup, onSaveCommand, onSaveResume) {
  try { popup.saved.disconnect(popup._savedSlot); } catch (e) {}
  popup._savedSlot = function (timeout, command, resumeCommand, name) {
    onSaveCommand(command);
    onSaveResume(resumeCommand);
  };
  popup.saved.connect(popup._savedSlot);
}
