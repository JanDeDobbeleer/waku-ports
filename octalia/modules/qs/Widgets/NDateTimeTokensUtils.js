.pragma library

function getCategoryColor(category, Color) {
    switch (category) {
    case "Year":
      return [Color.mPrimary, Color.mOnPrimary];
    case "Month":
      return [Color.mSecondary, Color.mOnSecondary];
    case "Day":
      return [Color.mTertiary, Color.mOnTertiary];
    case "Hour":
      return [Color.mPrimary, Color.mOnPrimary];
    case "Minute":
      return [Color.mSecondary, Color.mOnSecondary];
    case "Second":
      return [Color.mTertiary, Color.mOnTertiary];
    case "AM/PM":
      return [Color.mError, Color.mOnError];
    case "Timezone":
      return [Color.mOnSurface, Color.mSurface];
    case "Common":
      return [Color.mError, Color.mOnError];
    default:
      return [Color.mOnSurfaceVariant, Color.mSurfaceVariant];
    }
}

function field(item, name) {
  return item[name];
}
