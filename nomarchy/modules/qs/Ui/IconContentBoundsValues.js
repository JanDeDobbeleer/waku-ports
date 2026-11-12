.pragma library

function mappedBounds(item) { return item.mappedBounds }
function configure(item, sourceBinding, parentBinding) {
  item.sourceItem = sourceBinding
  item.boundsParent = parentBinding
}
