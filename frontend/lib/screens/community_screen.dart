import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/community.dart';
import '../providers/community_provider.dart';
import '../widgets/glossy_widgets.dart';
import 'package:intl/intl.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<CommunityProvider>().fetchFeed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Community Feed',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F3D2B),
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          // Gradient Background to match HomeScreen
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1F3D2B).withValues(alpha: 0.04),
                  const Color(0xFF8FBC8F).withValues(alpha: 0.20),
                  const Color(0xFFF8FAF5),
                ],
              ),
            ),
          ),
          
          Consumer<CommunityProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.posts.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1F3D2B)),
                );
              }

              if (provider.error != null && provider.posts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Oops! ${provider.error}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: const Color(0xFF1F3D2B)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      GlossyButton(
                        onPressed: () => provider.fetchFeed(),
                        label: const Text('Retry'),
                        color: const Color(0xFF1F3D2B),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.fetchFeed(),
                color: const Color(0xFF1F3D2B),
                backgroundColor: Colors.white,
                child: CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    // Padding for AppBar
                    const SliverToBoxAdapter(child: SizedBox(height: 110)),
                    
                    // Welcome Message
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plant Talk 🌿',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F3D2B),
                                  ),
                            ),
                            Text(
                              'Share your garden and ask for advice',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),

                    // Posts List
                    if (provider.posts.isEmpty)
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              children: [
                                Icon(Icons.forum_outlined, size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'Be the first to share something!',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.grey.shade500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final post = provider.posts[index];
                              return _PostCard(post: post);
                            },
                            childCount: provider.posts.length,
                          ),
                        ),
                      ),

                    // Bottom Padding
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      
      // Floating Action Button to create post
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostScreen(context),
        backgroundColor: const Color(0xFF1F3D2B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Share Post'),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showCreatePostScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
  }
}

class _PostCard extends StatelessWidget {
  final CommunityPost post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return GlossyCard(
      fillOpacity: 0.08,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1F3D2B).withValues(alpha: 0.1),
                  child: Text(
                    post.username[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF1F3D2B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.username,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F3D2B),
                          ),
                    ),
                    Text(
                      DateFormat('MMM d, h:mm a').format(post.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            Text(
              post.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1F3D2B),
                    height: 1.5,
                  ),
            ),
            
            // Image (if any)
            if (post.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Actions (Like & Comment)
            Row(
              children: [
                _ActionButton(
                  icon: post.isLikedByMe ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  label: '${post.likesCount}',
                  color: post.isLikedByMe ? Colors.red : Colors.grey.shade600,
                  onTap: () => context.read<CommunityProvider>().toggleLike(post.id),
                ),
                const SizedBox(width: 24),
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${post.comments.length}',
                  color: Colors.grey.shade600,
                  onTap: () => _showCommentsModal(context, post),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsModal(BuildContext context, CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsBottomSheet(post: post),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsBottomSheet extends StatefulWidget {
  final CommunityPost post;

  const _CommentsBottomSheet({required this.post});

  @override
  State<_CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<_CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Comments',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F3D2B),
                ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          
          Expanded(
            child: widget.post.comments.isEmpty
                ? Center(
                    child: Text(
                      'No comments yet',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.post.comments.length,
                    itemBuilder: (context, index) {
                      final comment = widget.post.comments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF1F3D2B).withValues(alpha: 0.1),
                              child: Text(
                                comment.username[0].toUpperCase(),
                                style: const TextStyle(fontSize: 12, color: Color(0xFF1F3D2B)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        comment.username,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat('MMM d').format(comment.createdAt),
                                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment.content,
                                    style: const TextStyle(fontSize: 13, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    if (_commentController.text.isNotEmpty) {
                      context.read<CommunityProvider>().addComment(widget.post.id, _commentController.text);
                      _commentController.clear();
                    }
                  },
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF1F3D2B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1F3D2B).withValues(alpha: 0.04),
                  const Color(0xFF8FBC8F).withValues(alpha: 0.20),
                  const Color(0xFFF8FAF5),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GlossyCard(
                    fillOpacity: 0.08,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _contentController,
                        maxLines: 10,
                        decoration: const InputDecoration(
                          hintText: 'What\'s on your mind? Share garden tips, ask questions...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_contentController.text.isNotEmpty) {
                          final communityProvider = context.read<CommunityProvider>();
                          final success = await communityProvider.createPost(
                            CommunityPostCreate(content: _contentController.text),
                          );
                          if (success && mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F3D2B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Post to Community 🌿', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
