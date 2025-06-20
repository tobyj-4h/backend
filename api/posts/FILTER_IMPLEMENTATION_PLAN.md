# Posts Filter Implementation Plan

## Overview

This document outlines the implementation details for the four main filter types in the posts API:

1. **Discover**
2. **Following**
3. **What's Hot**
4. **Popular in my Groups**

## Current Status

- ✅ **What's Hot**: Implemented with engagement scoring
- ✅ **Discover**: Implemented with user associations integration
- ✅ **Following**: Implemented with user associations integration
- ✅ **Popular in my Groups**: Implemented with user associations integration
- ✅ **Phase 1 Complete**: User Associations Integration

## Filter Type Details

### 1. Discover

**Purpose**: Show posts from users the current user doesn't follow to help discover new content.

**Implementation Status**: ✅ Complete

- Queries user associations table to get list of users the current user follows
- Filters posts to exclude posts from followed users
- Sorts by engagement score
- Handles cases where user is not authenticated (falls back to latest posts)

**Database Queries**:

```typescript
// Get user's following list
const following = await getUserFollowing(userId);

// Get posts excluding followed users
const posts = await getPostsExcludingUsers(following, offset, pageSize);
```

### 2. Following

**Purpose**: Show posts only from users the current user follows.

**Implementation Status**: ✅ Complete

- Queries user associations table to get list of users the current user follows
- Filters posts to only include posts from followed users
- Sorts by timestamp (newest first)
- Handles empty following lists gracefully

**Database Queries**:

```typescript
// Get user's following list
const following = await getUserFollowing(userId);

// Get posts from followed users only
const posts = await getPostsFromUsers(following, offset, pageSize);
```

### 3. What's Hot

**Purpose**: Show the most engaging content across the platform.

**Implementation Status**: ✅ Complete

- Calculates engagement score based on views, reactions, comments, and favorites
- Sorts by engagement score
- Weights: views (0.1), reactions (2), comments (3), favorites (2)

### 4. Popular in my Groups

**Purpose**: Show posts from groups the user is a member of, sorted by engagement within those groups.

**Implementation Status**: ✅ Complete

- Queries user associations table to get list of groups the user is a member of
- Filters posts to only include posts from those groups
- Sorts by engagement score within the groups
- Handles empty group memberships gracefully

**Database Queries**:

```typescript
// Get user's group memberships
const groups = await getUserGroups(userId);

// Get posts from user's groups
const posts = await getPostsFromGroups(groups, offset, pageSize);
```

## Phase 1: User Associations Integration ✅ COMPLETE

### Completed Tasks:

1. ✅ Implemented `getUserFollowing()` function
2. ✅ Implemented `getUserGroups()` function
3. ✅ Updated filter logic to use these functions
4. ✅ Added proper error handling
5. ✅ Updated IAM permissions for user associations table access
6. ✅ Implemented user associations API endpoints (GET and PUT)

### User Associations API Endpoints:

- `GET /user/associations` - Get user's following list and group memberships
- `POST /user/associations` - Create following relationship or group membership

### Database Schema:

```typescript
interface UserAssociation {
  PK: string; // "USER#${userId}"
  SK: string; // "FOLLOWING#${followedUserId}" or "GROUP#${groupId}"
  association_type: string; // "following" or "group_member"
  created_at: string;
  role?: string; // "member", "admin", "moderator"
  joined_at?: string;
  target_user_id?: string;
  group_id?: string;
}
```

## Phase 2: Database Optimization 🔄 NEXT

### Planned Tasks:

1. 🔄 Add GSIs for efficient filtering
2. 🔄 Implement engagement score pre-calculation
3. 🔄 Add caching layer for frequently accessed data
4. 🔄 Optimize queries for large following lists

### GSI Recommendations:

```typescript
// GSI for user_id + timestamp (for following filter)
{
  name: "UserTimestampIndex",
  hashKey: "user_id",
  rangeKey: "timestamp",
  projectionType: "ALL"
}

// GSI for group_id + engagement_score (for groups filter)
{
  name: "GroupEngagementIndex",
  hashKey: "group_id",
  rangeKey: "engagement_score",
  projectionType: "ALL"
}

// GSI for engagement_score + timestamp (for what's hot)
{
  name: "EngagementTimestampIndex",
  hashKey: "engagement_score",
  rangeKey: "timestamp",
  projectionType: "ALL"
}
```

## Phase 3: Advanced Features 📋 FUTURE

### Planned Tasks:

1. 📋 Implement time decay for engagement scores
2. 📋 Add group-specific engagement metrics
3. 📋 Implement search functionality
4. 📋 Add personalized recommendations
5. 📋 Add analytics and monitoring

## Testing Strategy

### Unit Tests Needed:

- Test each filter type with mock data
- Test pagination logic
- Test engagement score calculation
- Test error handling
- Test user associations integration

### Integration Tests Needed:

- Test with real DynamoDB data
- Test user associations integration
- Test performance with large datasets

## Performance Considerations

### Current Implementation:

- Uses `ScanCommand` with client-side filtering and sorting
- Suitable for small to medium datasets
- Direct DynamoDB queries for user associations

### Optimization Opportunities:

- Use GSIs to replace scans with queries
- Pre-calculate engagement scores
- Implement caching for user associations
- Use batch operations for large following lists
- Add time-based filtering to avoid old posts

## Security Considerations

### Access Control:

- ✅ Users can only see posts they have permission to view
- ✅ User associations are private to each user
- ✅ Proper authentication and authorization

### Data Privacy:

- ✅ Following lists are private
- ✅ Group memberships are validated
- ✅ No exposure of sensitive user data

## Next Steps

1. **Deploy Phase 1**: Deploy the current implementation to test with real data
2. **Performance Testing**: Test with realistic data volumes
3. **Phase 2 Planning**: Design and implement GSIs based on usage patterns
4. **Monitoring**: Add CloudWatch metrics for filter usage and performance

## API Endpoints Needed

### User Associations API

- `GET /user/associations` - Get user's following list and group memberships
- `POST /user/associations` - Create following relationship or group membership

### Groups API (if not exists)

- `GET /groups` - List groups
- `GET /groups/{groupId}` - Get group details
- `POST /groups` - Create group
- `PUT /groups/{groupId}` - Update group

## Monitoring and Analytics

### Metrics to Track

- Filter usage distribution
- Response times for each filter type
- Cache hit rates
- User engagement with different filter types

### Alerts

- High response times
- Cache miss rates
- Database query performance
- Error rates
