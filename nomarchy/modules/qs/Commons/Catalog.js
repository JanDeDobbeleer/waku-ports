.pragma library

function parse(raw) {
  try {
    let parsed = JSON.parse(raw || "{}")
    return (parsed && typeof parsed === "object" && !Array.isArray(parsed)) ? parsed : ({})
  } catch (e) {
    return ({})
  }
}
