from datetime import datetime
from typing import List, Optional
from community_models import CommunityPost, CommunityPostResponse, Comment, CommunityPostCreate
from bson import ObjectId

class CommunityService:
    """Service for community post logic"""

    @staticmethod
    def create_response(post_doc: dict, current_username: str) -> CommunityPostResponse:
        """Create a response model from a post document"""
        # Ensure 'id' is extracted from '_id'
        post_id = str(post_doc['_id'])
        
        # Determine if current user liked the post
        likes = post_doc.get('likes', [])
        is_liked_by_me = current_username in likes
        
        # Extract comments
        comments_docs = post_doc.get('comments', [])
        comments = [Comment(**c) for c in comments_docs]
        
        return CommunityPostResponse(
            id=post_id,
            username=post_doc['username'],
            content=post_doc['content'],
            image_url=post_doc.get('image_url'),
            likes=likes,
            comments=comments,
            created_at=post_doc['created_at'],
            updated_at=post_doc.get('updated_at', post_doc['created_at']),
            likes_count=len(likes),
            is_liked_by_me=is_liked_by_me
        )

    @staticmethod
    async def create_post(db, username: str, post_data: CommunityPostCreate, image_url: Optional[str] = None) -> dict:
        """Create a new community post"""
        post_doc = {
            "username": username,
            "content": post_data.content,
            "image_url": image_url,
            "likes": [],
            "comments": [],
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow()
        }
        
        result = await db.community_posts.insert_one(post_doc)
        post_doc["_id"] = result.inserted_id
        return post_doc

    @staticmethod
    async def toggle_like(db, post_id: str, username: str) -> bool:
        """Toggle a like for a post. Returns True if liked, False if unliked."""
        post = await db.community_posts.find_one({"_id": ObjectId(post_id)})
        if not post:
            return False
            
        likes = post.get('likes', [])
        if username in likes:
            # Unlike
            await db.community_posts.update_one(
                {"_id": ObjectId(post_id)},
                {"$pull": {"likes": username}, "$set": {"updated_at": datetime.utcnow()}}
            )
            return False
        else:
            # Like
            await db.community_posts.update_one(
                {"_id": ObjectId(post_id)},
                {"$addToSet": {"likes": username}, "$set": {"updated_at": datetime.utcnow()}}
            )
            return True

    @staticmethod
    async def add_comment(db, post_id: str, username: str, content: str) -> Optional[Comment]:
        """Add a comment to a post"""
        comment = {
            "username": username,
            "content": content,
            "created_at": datetime.utcnow()
        }
        
        result = await db.community_posts.update_one(
            {"_id": ObjectId(post_id)},
            {"$push": {"comments": comment}, "$set": {"updated_at": datetime.utcnow()}}
        )
        
        if result.modified_count > 0:
            return Comment(**comment)
        return None
