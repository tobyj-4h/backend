# Post Interactions Implementation

## Overview

This document outlines the implementation of post interactions functionality, including views, reactions, comments, and favorites. All interactions are stored in DynamoDB tables and integrated with the posts API.

## Implementation Status

- ✅ **Views**: Implemented with counter tracking
- ✅ **Reactions**: Implemented with user tracking
- ✅ **Comments**: Implemented with full CRUD
- ✅ **Favorites**: Implemented with user tracking
- ✅ **Firebase Auth Integration**: All functions updated to use Firebase authorizer
- ✅ **CORS Headers**: Added proper CORS support
- ✅ **Database Schema**: Updated with proper keys and indexes
- ✅ **Posts Integration**: Interaction counts included in posts API response

## API Endpoints

### Views

- `POST /interactions/{post_id}/view` - Record a post view

### Reactions

- `POST /interactions/{post_id}/react` - Add a reaction to a post
- `DELETE /interactions/{post_id}/react` - Remove a reaction from a post

### Comments

- `POST /interactions/{post_id}/comment` - Add a comment to a post

### Favorites

- `POST /interactions/{post_id}/favorite` - Favorite a post
- `DELETE /interactions/{post_id}/favorite` - Unfavorite a post

## Database Schema

### Post Events Table (`post_events`)

```typescript
interface PostEvent {
  post_id: string; // Hash key
  event_id: string; // Range key
  user_id: string;
  event_type: string; // "view", "reaction", "comment", "favorite", "unfavorite", "unreaction"
  event_value: any; // Reaction type, comment ID, boolean, etc.
  timestamp: string;
}
```

### Post Views Table (`post_views`)

```typescript
interface PostView {
  post_id: string; // Hash key
  timestamp: number; // Range key
  user_id: string;
}
```

### Post View Counters Table (`post_view_counters`)

```typescript
interface PostViewCounter {
  post_id: string; // Hash key
  view_count: number;
}
```

### Post Reactions Table (`post_reactions`)

```typescript
interface PostReaction {
  post_id: string; // Hash key
  user_id: string; // Range key
  reaction: string; // Reaction type (emoji, etc.)
  timestamp: string;
}
```

### Post Comments Table (`post_comments`)

```typescript
interface PostComment {
  post_id: string; // Hash key
  comment_id: string; // Range key
  user_id: string;
  comment_text: string;
  timestamp: string;
}
```

### Post User Favorites Table (`post_user_favorites`)

```typescript
interface PostUserFavorite {
  user_id: string; // Hash key
  post_id: string; // Range key
  timestamp: string;
}
```

## Global Secondary Indexes

### Post Reactions

- **User Reaction Index**: `user_id` (hash) + `reaction` (range)
  - Allows querying reactions by user

### Post Comments

- **User Comments Index**: `user_id` (hash) + `comment_id` (range)
  - Allows querying comments by user

### Post Views

- **User Views Index**: `user_id` (hash) + `timestamp` (range)
  - Allows querying views by user

## Key Features

### 1. View Tracking

- Records individual view events with user and timestamp
- Maintains atomic counters for quick access
- Uses DynamoDB's `UpdateItem` with `if_not_exists` for thread-safe increments

### 2. Reaction System

- Supports multiple reaction types per post
- Tracks which user made which reaction
- Allows removing specific reactions
- Uses composite key (post_id + user_id) for efficient queries

### 3. Comment System

- Full comment CRUD operations
- Unique comment IDs using ULID
- Links comments to posts and users
- Includes comment text and metadata

### 4. Favorite System

- Simple favorite/unfavorite toggle
- Tracks user favorites with timestamps
- Efficient queries by user or post

### 5. Event Logging

- All interactions logged to `post_events` table
- Enables analytics and audit trails
- Supports future features like notifications

## Integration with Posts API

### Interaction Counts

The posts API now includes interaction counts in the response:

```typescript
interface PostWithInteractions {
  // ... existing post fields
  view_count: number;
  reaction_count: number;
  comment_count: number;
  favorite_count: number;
}
```

### Engagement Scoring

Interaction counts are used for engagement scoring in the "What's Hot" filter:

```typescript
const calculateEngagementScore = (post: any): number => {
  const views = post.view_count || 0;
  const reactions = post.reaction_count || 0;
  const comments = post.comment_count || 0;
  const favorites = post.favorite_count || 0;

  // Weight different engagement types
  return views * 0.1 + reactions * 2 + comments * 3 + favorites * 2;
};
```

## Security & Authentication

### Firebase Integration

- All endpoints use Firebase authorizer
- User ID extracted from `event.requestContext.authorizer?.user`
- Proper error handling for unauthorized requests

### CORS Support

- All endpoints include proper CORS headers
- Supports cross-origin requests from frontend applications

### Data Validation

- Input validation for required fields
- Proper error responses with meaningful messages
- Type safety with TypeScript interfaces

## Performance Considerations

### Current Implementation

- Uses DynamoDB's atomic operations for counters
- Parallel queries for interaction counts
- Efficient key structures for common queries

### Optimization Opportunities

- **Caching**: Cache interaction counts for frequently accessed posts
- **Batch Operations**: Use BatchGetItem for multiple count queries
- **GSI Optimization**: Add more GSIs based on query patterns
- **Counter Aggregation**: Pre-calculate and store aggregated counts

## Error Handling

### Common Error Scenarios

- **Missing post_id**: 400 Bad Request
- **Unauthorized user**: 401 Unauthorized
- **Invalid input**: 400 Bad Request with validation message
- **Database errors**: 500 Internal Server Error

### Error Response Format

```typescript
{
  error: string;
  message: string;
}
```

## Testing Strategy

### Unit Tests Needed

- Test each interaction type with mock data
- Test error handling scenarios
- Test authentication and authorization
- Test input validation

### Integration Tests Needed

- Test with real DynamoDB data
- Test concurrent interactions
- Test performance with large datasets
- Test CORS functionality

## Monitoring & Analytics

### CloudWatch Metrics

- Lambda invocation counts and durations
- DynamoDB read/write capacity
- Error rates by endpoint
- Response times

### Custom Metrics

- Interaction counts by type
- Most popular posts
- User engagement patterns
- Peak usage times

## Future Enhancements

### Planned Features

1. **Real-time Updates**: WebSocket support for live interaction updates
2. **Notification System**: Notify users of interactions on their posts
3. **Advanced Analytics**: Detailed engagement analytics and insights
4. **Rate Limiting**: Prevent spam and abuse
5. **Moderation**: Content moderation for comments and reactions

### Technical Improvements

1. **Caching Layer**: Redis or DynamoDB DAX for frequently accessed data
2. **Event Streaming**: Use DynamoDB Streams for real-time processing
3. **Microservices**: Split into separate services for different interaction types
4. **GraphQL**: Add GraphQL API for more flexible queries

## Deployment Notes

### Environment Variables

```bash
# Required for all interaction functions
AWS_REGION=us-east-1

# Table names (with defaults)
EVENTS_TABLE=post_events
VIEWS_TABLE=post_views
VIEW_COUNTERS_TABLE=post_view_counters
REACTIONS_TABLE=post_reactions
COMMENTS_TABLE=post_comments
FAVORITES_TABLE=post_user_favorites
```

### IAM Permissions

All Lambda functions require DynamoDB permissions for:

- `GetItem`, `PutItem`, `UpdateItem`, `DeleteItem`
- `Query`, `Scan` (for counting operations)
- Access to all interaction tables

### Dependencies

- `@aws-sdk/client-dynamodb`
- `@aws-sdk/lib-dynamodb`
- `ulid` (for generating unique IDs)
