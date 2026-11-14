class PlanRejected implements Exception {
  const PlanRejected(this.reason);

  final String reason;

  @override
  String toString() => 'stream plan rejected: $reason';
}

String registrableDomain(String host) {
  final labels = host.toLowerCase().split('.');
  if (labels.length <= 2) return labels.join('.');
  return labels.sublist(labels.length - 2).join('.');
}

Uri checkedPlanUrl({required String url, required String allowedHost}) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    throw const PlanRejected('the page address is not a secure web address');
  }
  if (uri.host.toLowerCase() != allowedHost.toLowerCase()) {
    throw const PlanRejected('the page is not on the allowed host');
  }
  return uri;
}

bool navigationAllowed({required Uri target, required String allowedHost}) {
  if (target.scheme == 'about') return true;
  if (target.scheme != 'https') return false;
  return registrableDomain(target.host) == registrableDomain(allowedHost);
}
