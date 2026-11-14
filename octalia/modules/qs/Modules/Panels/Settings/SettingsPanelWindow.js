.pragma library

function keybindModel(keys, content) {
  return keys.map(function (key) { return { key: key, content: content }; });
}

function navigateTo(content, owner, tab, subTab) {
  const tabId = tab !== undefined ? tab : 0;
  const subTabId = (subTab !== undefined && subTab !== null && subTab >= 0) ? subTab : -1;
  if (owner.isInitialized) {
    content.navigateToTab(tabId, subTabId);
  } else {
    content.requestedTab = tabId;
    if (subTabId >= 0) content._pendingSubTab = subTabId;
    content.initialize();
    owner.isInitialized = true;
    if (subTabId < 0 && content.activeTabContent) content.setSubTabIndex(0);
  }
}

function navigateToEntry(content, entry, owner) {
  if (owner.isInitialized) {
    Qt.callLater(function () { content.navigateToResult(entry); });
  } else {
    content.requestedTab = entry.tab;
    content.initialize();
    Qt.callLater(function () { content.navigateToResult(entry); });
    owner.isInitialized = true;
  }
}

function selectNextTab(content) { content.selectNextTab(); }
function selectPreviousTab(content) { content.selectPreviousTab(); }
function moveSearchSelection(content, upward) {
  if (content.searchText.trim() !== "") {
    if (upward) content.searchSelectPrevious();
    else content.searchSelectNext();
  } else if (upward) {
    content.scrollUp();
  } else {
    content.scrollDown();
  }
}
