.pragma library

function setTelemetryOnlyMode(panel, enabled) { panel.telemetryOnlyMode = enabled; }
function disconnectTelemetryCompleted(panel, callback) { panel.telemetryWizardCompleted.disconnect(callback); }
function connectTelemetryCompleted(panel, callback) { panel.telemetryWizardCompleted.connect(callback); }
