class CommunityComment {
  final String username;
  final String content;
  final DateTime createdAt;

  CommunityComment({
    required this.username,
    required this.content,
    required this.createdAt,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      username: json['username'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class CommunityPost {
  final String id;
  final String username;
  final String content;
  final String? imageUrl;
  final List<String> likes;
  final List<CommunityComment> comments;
  final DateTime createdAt;
  final int likesCount;
  final bool isLikedByMe;

  CommunityPost({
    required this.id,
    required this.username,
    required this.content,
    this.imageUrl,
    required this.likes,
    required this.comments,
    required this.createdAt,
    required this.likesCount,
    required this.isLikedByMe,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'],
      username: json['username'],
      content: json['content'],
      imageUrl: json['image_url'],
      likes: List<String>.from(json['likes'] ?? []),
      comments: (json['comments'] as List<dynamic>?)
              ?.map((c) => CommunityComment.fromJson(c))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at']),
      likesCount: json['likes_count'] ?? 0,
      isLikedByMe: json['is_liked_by_me'] ?? false,
    );
  }
}

class CommunityFeedResponse {
  final List<CommunityPost> posts;
  final int total;

  CommunityFeedResponse({
    required this.posts,
    required this.total,
  });

  factory CommunityFeedResponse.fromJson(Map<String, dynamic> json) {
    return CommunityFeedResponse(
      posts: (json['posts'] as List<dynamic>?)
              ?.map((p) => CommunityPost.fromJson(p))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }
}

class CommunityPostCreate {
  final String content;
  final String? imageBase64;

  CommunityPostCreate({
    required this.content,
    this.imageBase64,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      if (imageBase64 != null) 'image_base64': imageBase64,
    };
  }
}

class CommunityCommentCreate {
  final String content;

  CommunityCommentCreate({required this.content});

  Map<String, dynamic> toJson() {
    return {'content': content};
  }
}
