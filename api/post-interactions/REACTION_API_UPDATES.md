# Reaction API Updates

## Overview

This document outlines the implementation of the new reaction API endpoints as specified in the requirements. The implementation includes new Lambda functions, updated API Gateway configuration, and modifications to the posts API to support the new reaction system.

## New API Endpoints

### 1. POST /interactions/{post_id}/reactions (Add New Reaction)

- **File**: `api/post-interactions/src/post-reactions.ts`
- **Purpose**: Add a new reaction when user doesn't have an existing reaction
- **Response**: 201 Created with reaction details
- **Validation**: Checks for existing reaction and returns 409 Conflict if found

### 2. PUT /interactions/{post_id}/reactions (Update Existing Reaction)

- **File**: `api/post-interactions/src/put-reactions.ts`
- **Purpose**: Update an existing reaction
- **Response**: 200 OK with updated reaction details
- **Validation**: Requires existing reaction, returns 404 if not found

### 3. DELETE /interactions/{post_id}/reactions (Remove Reaction)

- **File**: `api/post-interactions/src/delete-reactions.ts`
- **Purpose**: Remove user's reaction from a post
- **Response**: 204 No Content
- **Validation**: Requires existing reaction, returns 404 if not found

### 4. GET /interactions/{post_id}/reactions (Get Reactions for Post)

- **File**: `api/post-interactions/src/get-reactions.ts`
- **Purpose**: Get all reactions for a post with pagination
- **Response**: 200 OK with reactions array and counts
- **Features**: Pagination support with limit and lastEvaluatedKey

## Valid Reaction Types

The API now supports these reaction types:

- `like`
- `love`
- `laugh`
- `wow`
- `sad`
- `angry`

## Database Schema

The existing `post_reactions` table structure is used:

- **Hash Key**: `post_id` (String)
- **Range Key**: `user_id` (String)
- **Attributes**: `reaction` (String), `timestamp` (String)

## Posts API Integration

### User Reaction Field

Both `posts-get-item.ts` and `posts-get-items.ts` have been updated to include:

- `user_reaction`: The current user's reaction for the post (null if no reaction)

### Reaction Count Mapping

The interaction counts now properly map the new reaction types:

- `like` and `love` reactions are counted as "likes"
- Legacy emoji reactions (👍, ❤️) are still supported for backward compatibility

## Terraform Configuration

### New Lambda Functions

Added to `api/post-interactions/terraform/lambda.tf`:

- `PostReactionsFunction` (post-reactions.handler)
- `PutReactionsFunction` (put-reactions.handler)
- `DeleteReactionsFunction` (delete-reactions.handler)
- `GetReactionsFunction` (get-reactions.handler)

### API Gateway Methods

Added to `api/post-interactions/terraform/api-gateway.tf`:

- POST method for `/interactions/{post_id}/reactions`
- PUT method for `/interactions/{post_id}/reactions`
- DELETE method for `/interactions/{post_id}/reactions`
- GET method for `/interactions/{post_id}/reactions`

## Error Handling

### Standard Error Responses

All endpoints return consistent error responses:

- **400 Bad Request**: Missing required fields or invalid reaction type
- **401 Unauthorized**: Missing or invalid authentication
- **404 Not Found**: Post doesn't exist or reaction not found
- **409 Conflict**: User already has a reaction (POST only)
- **500 Internal Server Error**: Server-side errors

### Error Response Format

```json
{
  "error": "Error Type",
  "message": "Detailed error message"
}
```

## Authentication

All endpoints require Firebase authentication and extract the user ID from:

```typescript
const userId = event.requestContext.authorizer?.user;
```

## CORS Support

All endpoints include proper CORS headers:

```typescript
headers: {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
}
```

## Event Logging

All reaction operations are logged to the `post_events` table with appropriate event types:

- `reaction`: New reaction added
- `reaction_update`: Existing reaction updated
- `reaction_removed`: Reaction removed

## Deployment

### Build Process

The existing build script automatically includes the new Lambda functions:

```bash
./build.sh
```

### Terraform Deployment

Deploy the updated infrastructure:

```bash
cd terraform
terraform plan
terraform apply
```

## Testing

### Manual Testing

Test each endpoint with:

1. **POST**: Add new reaction (should return 201)
2. **PUT**: Update existing reaction (should return 200)
3. **DELETE**: Remove reaction (should return 204)
4. **GET**: Retrieve reactions (should return 200 with pagination)

### Validation Testing

- Test with invalid reaction types (should return 400)
- Test without authentication (should return 401)
- Test with non-existent posts (should return 404)
- Test POST with existing reaction (should return 409)

## Backward Compatibility

The implementation maintains backward compatibility with:

- Existing emoji-based reactions (👍, ❤️, 🔄, 💬)
- Current posts API response format
- Existing DynamoDB table structure

## Future Enhancements

Potential improvements for future iterations:

1. **Reaction Analytics**: Track reaction trends and patterns
2. **Reaction Notifications**: Notify users when their posts receive reactions
3. **Custom Reactions**: Allow custom reaction types per community
4. **Reaction History**: Track reaction changes over time
5. **Bulk Operations**: Support bulk reaction operations for multiple posts
