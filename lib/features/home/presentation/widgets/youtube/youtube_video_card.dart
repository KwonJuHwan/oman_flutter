import 'package:flutter/material.dart';
import '../../../domain/models/video_recommendation_model.dart';

class YoutubeBestMatchCard extends StatelessWidget {
  final VideoResponseDto video;
  final Color themeColor;

  const YoutubeBestMatchCard({
    super.key,
    required this.video,
    this.themeColor = const Color(0xFFFF4E45),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Container(
          height: 200, 
          width: double.infinity, 
          decoration: BoxDecoration(
            color: Colors.grey[800], 
            borderRadius: BorderRadius.circular(20), 
            image: DecorationImage(image: NetworkImage(video.thumbnail), fit: BoxFit.cover)
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: 12, left: 12, 
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7), // ✨ withOpacity 대체
                    borderRadius: BorderRadius.circular(20)
                  ), 
                  child: Text("#Best Pick", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12))
                )
              )
            ]
          ),
        ), 
        const SizedBox(height: 12), 
        Text(video.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.2, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis), 
        const SizedBox(height: 4), 
        Text("${video.channel} • 조회수 ${video.count}회", style: TextStyle(fontSize: 14, color: Colors.grey[400])),
      ]
    );
  }
}

class YoutubePopularItem extends StatelessWidget {
  final VideoResponseDto video;
  final Color themeColor;

  const YoutubePopularItem({
    super.key,
    required this.video,
    this.themeColor = const Color(0xFFFF4E45),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 100, height: 70, 
          decoration: BoxDecoration(
            color: Colors.grey[800], 
            borderRadius: BorderRadius.circular(12), 
            image: DecorationImage(image: NetworkImage(video.thumbnail), fit: BoxFit.cover)
          )
        ), 
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text(video.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis), 
              const SizedBox(height: 4), 
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.2), 
                      borderRadius: BorderRadius.circular(4)
                    ), 
                    child: Text("#Yummy", style: TextStyle(fontSize: 10, color: themeColor, fontWeight: FontWeight.bold))
                  ), 
                  const SizedBox(width: 6), 
                  Expanded(
                    child: Text(video.channel, style: TextStyle(fontSize: 12, color: Colors.grey[400]), overflow: TextOverflow.ellipsis)
                  )
                ]
              )
            ]
          )
        ),
      ]
    );
  }
}