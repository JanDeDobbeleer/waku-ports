.pragma library

function load(root, rulesFile) {
  try {
    const parsed = JSON.parse(rulesFile.text());
    const raw = Array.isArray(parsed.rules) ? parsed.rules : [];
    root.rules = filterRules(raw);
  } catch (e) {
    root.rules = [];
  }
}

function filterRules(rules) {
  return rules.filter(r => (r.pattern || "").trim() !== "");
}

function evaluate(appName, summary, body, rules, Logger) {
    const haystack = [appName || "", summary || "", body || ""].join(" ");
    for (let i = 0; i < rules.length; i++) {
      const r = rules[i];
      const pattern = (r.pattern || "").trim();
      if (pattern === "")
        continue;
      let matched = false;
      if (pattern.length >= 3 && pattern.startsWith("/") && pattern.endsWith("/")) {
        try {
          matched = new RegExp(pattern.slice(1, -1)).test(haystack);
        } catch (e) {
          Logger.w("NotificationRulesService", "Invalid regex:", pattern, e);
        }
      } else if (pattern.includes("*")) {
        try {
          const reStr = pattern.replace(/[.+?^${}()|[\]\\]/g, "\\$&").replace(/\*/g, ".*");
          matched = new RegExp(reStr, "i").test(haystack);
        } catch (e) {
          matched = haystack.toLowerCase().includes(pattern.toLowerCase());
        }
      } else {
        matched = haystack.toLowerCase().includes(pattern.toLowerCase());
      }
      if (matched) {
        const a = (r.action || "block").toLowerCase();
        if (a === "mute" || a === "hide")
          return a;
        if (a === "silence")
          return "hide";
        return "block";
      }
    }
    return null;
}
