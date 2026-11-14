.pragma library

function title(toplevel) {
  return toplevel ? String(toplevel.title || toplevel.appId || "") : ""
}
