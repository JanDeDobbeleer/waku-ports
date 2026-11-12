.pragma library
function acquire(service) { if (service && service.ref) service.ref(); }
function release(service) { if (service && service.unref) service.unref(); }
