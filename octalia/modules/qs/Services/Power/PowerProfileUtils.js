.pragma library

function available(profiles) {
  return profiles && profiles.hasPerformanceProfile;
}

function profile(profiles, fallback) {
  return profiles ? profiles.profile : fallback;
}

function setProfile(root, p, Logger) {
  if (!root.available)
    return;
  try {
    root.powerProfiles.profile = p;
  } catch (e) {
    Logger.e("PowerProfileService", "Failed to set profile:", e);
  }
}
