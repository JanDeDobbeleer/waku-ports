.pragma library

function length(values) {
  return (values && values.length !== undefined) ? values.length : 0;
}
