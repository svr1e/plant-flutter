from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List
from bson import ObjectId

class Comment(BaseModel):
    """Comment model"""
    username: str
    content: str
    created_at: datetime = Field(default_factory=datetime.utcnow)

class CommunityPost(BaseModel):
    """Community post model"""
    username: str
    content: str
    image_url: Optional[str] = None
    likes: List[str] = Field(default_factory=list) # List of usernames who liked
    comments: List[Comment] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class CommunityPostResponse(CommunityPost):
    """Response model for a community post"""
    id: str
    likes_count: int = 0
    is_liked_by_me: bool = False

class CommunityPostCreate(BaseModel):
    """Schema for creating a new post"""
    content: str
    image_base64: Optional[str] = None

class CommunityCommentCreate(BaseModel):
    """Schema for adding a comment"""
    content: str

class CommunityFeedResponse(BaseModel):
    """Response for the community feed"""
    posts: List[CommunityPostResponse]
    total: int
