String parseHttpLocation(final String rawUri, final String location) {
  final uri = Uri.parse(rawUri);
  // If location starts with "://", the protocol is missing, add a protocol to it
  if (location.startsWith('://')) {
    return '${uri.scheme}$location';
  }

  // If the location contains "://", it means that it is an absolute URL (with a protocol) and is returned directly
  if (location.contains("://")) {
    return location;
  }

  // If the location doesn't have a protocol part (i.e. no "://") and it's a relative path, we splice it with rawUri

  // If location starts with a slash, it means that it is a relative path from the root path
  if (location.startsWith('/')) {
    return uri.resolve(location).toString();
  } else {
    // If the location doesn't start with a slash, it's a relative path based on the current path
    return uri.resolveUri(Uri.parse(location)).toString();
  }
}