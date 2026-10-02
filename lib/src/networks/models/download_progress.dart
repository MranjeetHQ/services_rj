class DownloadProgress {
  const DownloadProgress({required this.received, required this.total});

  final int received;

  final int total;

  double get percentage {
    if (total == 0) return 0;

    return (received / total) * 100;
  }
}
