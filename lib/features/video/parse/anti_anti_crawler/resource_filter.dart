class ResourceFilter {
  const ResourceFilter();

  bool allow(String lowerUrl) {
    if (lowerUrl.endsWith('.png')) return false;
    if (lowerUrl.endsWith('.jpg')) return false;
    if (lowerUrl.endsWith('.jpeg')) return false;
    if (lowerUrl.endsWith('.gif')) return false;
    if (lowerUrl.endsWith('.svg')) return false;
    if (lowerUrl.endsWith('.woff')) return false;
    if (lowerUrl.endsWith('.woff2')) return false;
    return true;
  }
}
