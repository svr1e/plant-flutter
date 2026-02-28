import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/community.dart';
import '../services/api_service.dart';

class CommunityProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<CommunityPost> _posts = [];
  bool _isLoading = false;
  String? _error;

  List<CommunityPost> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch all community posts
  Future<void> fetchFeed() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/community/posts');
      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        final feedResponse = CommunityFeedResponse.fromJson(data);
        _posts = feedResponse.posts;
        _error = null;
      } else {
        _error = data['detail'] ?? 'Failed to fetch community feed';
      }
    } catch (e) {
      _error = 'Failed to fetch community feed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new post
  Future<bool> createPost(CommunityPostCreate post) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        '/community/posts',
        body: json.encode(post.toJson()),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newPost = CommunityPost.fromJson(data);
        _posts.insert(0, newPost); // Add to the top of the feed
        _error = null;
        notifyListeners();
        return true;
      } else {
        final data = json.decode(response.body);
        _error = data['detail'] ?? 'Failed to create post';
        return false;
      }
    } catch (e) {
      _error = 'Failed to create post: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle like on a post
  Future<void> toggleLike(String postId) async {
    try {
      final response = await _apiService.post('/community/posts/$postId/like');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final isLiked = data['liked'] as bool;
        
        // Update the local state for immediate feedback
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final post = _posts[index];
          _posts[index] = CommunityPost(
            id: post.id,
            username: post.username,
            content: post.content,
            imageUrl: post.imageUrl,
            likes: post.likes, // We don't update the full list locally
            comments: post.comments,
            createdAt: post.createdAt,
            likesCount: isLiked ? post.likesCount + 1 : post.likesCount - 1,
            isLikedByMe: isLiked,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
    }
  }

  // Add a comment to a post
  Future<bool> addComment(String postId, String content) async {
    try {
      final commentCreate = CommunityCommentCreate(content: content);
      final response = await _apiService.post(
        '/community/posts/$postId/comments',
        body: json.encode(commentCreate.toJson()),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newComment = CommunityComment.fromJson(data);
        
        // Update the local state
        final index = _posts.indexWhere((p) => p.id == postId);
        if (index != -1) {
          final post = _posts[index];
          final updatedComments = List<CommunityComment>.from(post.comments)..add(newComment);
          _posts[index] = CommunityPost(
            id: post.id,
            username: post.username,
            content: post.content,
            imageUrl: post.imageUrl,
            likes: post.likes,
            comments: updatedComments,
            createdAt: post.createdAt,
            likesCount: post.likesCount,
            isLikedByMe: post.isLikedByMe,
          );
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
    return false;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
