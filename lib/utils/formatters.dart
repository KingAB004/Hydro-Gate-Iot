String formatGateId(String text) {
  return text.replaceAllMapped(RegExp(r'gate_hydrogate-([a-zA-Z0-9_\-]+)'), (match) {
    String suffix = match.group(1) ?? '';
    if (suffix.isNotEmpty) {
      // Split by dashes if any, capitalize each part, then join.
      List<String> parts = suffix.split('-');
      for (int i = 0; i < parts.length; i++) {
        if (parts[i].isNotEmpty) {
          parts[i] = parts[i][0].toUpperCase() + parts[i].substring(1);
        }
      }
      suffix = parts.join('-');
    }
    return 'HydroGate-$suffix';
  });
}
