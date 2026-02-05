class YoutubeVideo {
  final String title;
  final String channelName;
  final String thumbnailUrl; // 실제로는 네트워크 이미지 URL
  final String views;
  final String publishedAt;

  YoutubeVideo({
    required this.title,
    required this.channelName,
    required this.thumbnailUrl,
    required this.views,
    required this.publishedAt,
  });
}