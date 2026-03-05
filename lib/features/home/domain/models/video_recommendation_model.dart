// lib/features/home/domain/models/video_recommendation_model.dart

class VideoResponseDto {
  final int id;
  final String thumbnail;
  final String title;
  final String channel;
  final String url;
  final int count;

  VideoResponseDto({
    required this.id,
    required this.thumbnail,
    required this.title,
    required this.channel,
    required this.url,
    required this.count,
  });

  factory VideoResponseDto.fromJson(Map<String, dynamic> json) {
    return VideoResponseDto(
      id: json['id'] ?? 0,
      thumbnail: json['thumbnail'] ?? '',
      title: json['title'] ?? '',
      channel: json['channel'] ?? '',
      url: json['url'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class VideoRecommendationResponseDto {
  final List<VideoResponseDto> matchVideos;
  final List<VideoResponseDto> popularVideos;

  VideoRecommendationResponseDto({
    required this.matchVideos,
    required this.popularVideos,
  });

  factory VideoRecommendationResponseDto.fromJson(Map<String, dynamic> json) {
    return VideoRecommendationResponseDto(
      // 백엔드의 @JsonProperty("match_videos") 매핑
      matchVideos: (json['match_videos'] as List<dynamic>?)
              ?.map((e) => VideoResponseDto.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
      popularVideos: (json['popular_videos'] as List<dynamic>?)
              ?.map((e) => VideoResponseDto.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
    );
  }
}