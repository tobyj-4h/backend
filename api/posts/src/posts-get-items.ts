import { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  ScanCommand,
  BatchGetCommand,
  QueryCommand,
  GetCommand,
} from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const dynamoDb = DynamoDBDocumentClient.from(client);
const POSTS_TABLE = process.env.POSTS_TABLE || "posts";
const USER_PROFILE_TABLE = process.env.USER_PROFILE_TABLE || "user_profile";
const REQUIRED_SCOPE = process.env.REQUIRED_SCOPE;

interface UserProfile {
  id: string;
  handle: string;
  profile_picture_url?: string;
  first_name: string;
  last_name: string;
}

interface PostWithUserInfo {
  [key: string]: any;
  user?: UserProfile;
}

interface QueryParams {
  filter?: string;
  page?: string;
  pageSize?: string;
  userId?: string;
  search?: string;
}

interface PaginationInfo {
  currentPage: number;
  pageSize: number;
  totalItems: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
}

interface PostsResponse {
  posts: PostWithUserInfo[];
  pagination: PaginationInfo;
}

// Helper function to calculate engagement score for "What's Hot" filtering
const calculateEngagementScore = (post: any): number => {
  const views = post.views || 0;
  const likes = post.likes || 0;
  const comments = post.comments || 0;
  const reposts = post.reposts || 0;
  const quotes = post.quotes || 0;

  // Weight different engagement types
  return views * 0.1 + (likes + reposts + quotes) * 2 + comments * 3;
};

// Helper function to get posts based on filter type
const getPostsByFilter = async (
  filter: string,
  page: number,
  pageSize: number,
  userId?: string
): Promise<any[]> => {
  const offset = page * pageSize;

  switch (filter.toLowerCase()) {
    case "discover":
      // Discover: Show posts from users the current user doesn't follow
      // This helps users find new content and users to follow
      if (!userId) {
        // If no user ID, fall back to latest posts
        return await getLatestPosts(offset, pageSize);
      }

      // Get list of users the current user follows
      const following = await getUserFollowing(userId);

      // Get posts excluding followed users
      return await getPostsExcludingUsers(following, offset, pageSize);

    case "following":
      // Following: Show posts only from users the current user follows
      if (!userId) {
        return [];
      }

      // Get list of users the current user follows
      const followingUsers = await getUserFollowing(userId);

      // Get posts from followed users only
      return await getPostsFromUsers(followingUsers, offset, pageSize);

    case "what's hot":
    case "whats hot":
    case "trending":
      // What's Hot: Sort posts by engagement score (views, reactions, comments, favorites)
      // This shows the most engaging content across the platform
      const hotParams = new ScanCommand({
        TableName: POSTS_TABLE,
        FilterExpression: "is_deleted = :isDeleted",
        ExpressionAttributeValues: {
          ":isDeleted": false,
        },
      });

      const hotResult = await dynamoDb.send(hotParams);
      const hotPosts = hotResult.Items || [];

      // Sort by engagement score (calculated on the fly)
      const postsWithScore = hotPosts.map((post) => ({
        ...post,
        engagementScore: calculateEngagementScore(post),
      }));

      postsWithScore.sort((a, b) => b.engagementScore - a.engagementScore);

      // Apply pagination
      return postsWithScore.slice(offset, offset + pageSize);

    case "popular in my groups":
    case "groups":
      // Popular in my Groups: Show posts from groups the user is a member of
      // Sort by engagement within those groups
      if (!userId) {
        return [];
      }

      // Get list of groups the user is a member of
      const groups = await getUserGroups(userId);

      // Get posts from user's groups
      return await getPostsFromGroups(groups, offset, pageSize);

    case "latest":
    case "recent":
    default:
      // Latest: Sort posts by timestamp (newest first)
      // This is the default fallback
      return await getLatestPosts(offset, pageSize);
  }
};

// Helper function to get latest posts (extracted for reuse)
const getLatestPosts = async (
  offset: number,
  pageSize: number
): Promise<any[]> => {
  const latestParams = new ScanCommand({
    TableName: POSTS_TABLE,
    FilterExpression: "is_deleted = :isDeleted",
    ExpressionAttributeValues: {
      ":isDeleted": false,
    },
  });

  const latestResult = await dynamoDb.send(latestParams);
  const latestPosts = latestResult.Items || [];

  // Sort by timestamp (newest first)
  latestPosts.sort(
    (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
  );

  // Apply pagination
  return latestPosts.slice(offset, offset + pageSize);
};

// Helper function to get user's following list
const getUserFollowing = async (userId: string): Promise<string[]> => {
  try {
    // For now, we'll make a direct DynamoDB query to get following list
    // In the future, this could be a call to the user associations API
    const queryParams = new QueryCommand({
      TableName: "user_associations",
      KeyConditionExpression: "PK = :pk AND begins_with(SK, :sk)",
      ExpressionAttributeValues: {
        ":pk": `USER#${userId}`,
        ":sk": "FOLLOWING#",
      },
    });

    const result = await dynamoDb.send(queryParams);
    const associations = result.Items || [];

    // Extract user IDs from the SK
    const following = associations.map((association: any) => {
      return association.SK.replace("FOLLOWING#", "");
    });

    console.log("User following list:", following);
    return following;
  } catch (error) {
    console.error("Error getting user following list:", error);
    return [];
  }
};

// Helper function to get user's group memberships
const getUserGroups = async (userId: string): Promise<string[]> => {
  try {
    // For now, we'll make a direct DynamoDB query to get group memberships
    // In the future, this could be a call to the user associations API
    const queryParams = new QueryCommand({
      TableName: "user_associations",
      KeyConditionExpression: "PK = :pk AND begins_with(SK, :sk)",
      ExpressionAttributeValues: {
        ":pk": `USER#${userId}`,
        ":sk": "GROUP#",
      },
    });

    const result = await dynamoDb.send(queryParams);
    const associations = result.Items || [];

    // Extract group IDs from the SK
    const groups = associations.map((association: any) => {
      return association.SK.replace("GROUP#", "");
    });

    console.log("User group memberships:", groups);
    return groups;
  } catch (error) {
    console.error("Error getting user group memberships:", error);
    return [];
  }
};

// Helper function to get posts excluding specific users
const getPostsExcludingUsers = async (
  excludeUserIds: string[],
  offset: number,
  pageSize: number
): Promise<any[]> => {
  const scanParams = new ScanCommand({
    TableName: POSTS_TABLE,
    FilterExpression:
      "is_deleted = :isDeleted AND (NOT user_id IN (:excludeUsers))",
    ExpressionAttributeValues: {
      ":isDeleted": false,
      ":excludeUsers": excludeUserIds,
    },
  });

  const result = await dynamoDb.send(scanParams);
  const posts = result.Items || [];

  // Sort by engagement score for discover
  const postsWithScore = posts.map((post) => ({
    ...post,
    engagementScore: calculateEngagementScore(post),
  }));

  postsWithScore.sort((a, b) => b.engagementScore - a.engagementScore);

  // Apply pagination
  return postsWithScore.slice(offset, offset + pageSize);
};

// Helper function to get posts from specific users
const getPostsFromUsers = async (
  userIds: string[],
  offset: number,
  pageSize: number
): Promise<any[]> => {
  if (userIds.length === 0) {
    return [];
  }

  // For small lists, we can use IN clause
  if (userIds.length <= 100) {
    const scanParams = new ScanCommand({
      TableName: POSTS_TABLE,
      FilterExpression: "is_deleted = :isDeleted AND user_id IN (:userIds)",
      ExpressionAttributeValues: {
        ":isDeleted": false,
        ":userIds": userIds,
      },
    });

    const result = await dynamoDb.send(scanParams);
    const posts = result.Items || [];

    // Sort by timestamp (newest first)
    posts.sort(
      (a, b) =>
        new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
    );

    // Apply pagination
    return posts.slice(offset, offset + pageSize);
  } else {
    // For large lists, we need to batch the queries
    // This is a simplified implementation - in production you'd want to optimize this
    const allPosts: any[] = [];

    for (let i = 0; i < userIds.length; i += 100) {
      const batch = userIds.slice(i, i + 100);
      const scanParams = new ScanCommand({
        TableName: POSTS_TABLE,
        FilterExpression: "is_deleted = :isDeleted AND user_id IN (:userIds)",
        ExpressionAttributeValues: {
          ":isDeleted": false,
          ":userIds": batch,
        },
      });

      const result = await dynamoDb.send(scanParams);
      if (result.Items) {
        allPosts.push(...result.Items);
      }
    }

    // Sort by timestamp (newest first)
    allPosts.sort(
      (a, b) =>
        new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
    );

    // Apply pagination
    return allPosts.slice(offset, offset + pageSize);
  }
};

// Helper function to get posts from specific groups
const getPostsFromGroups = async (
  groupIds: string[],
  offset: number,
  pageSize: number
): Promise<any[]> => {
  if (groupIds.length === 0) {
    return [];
  }

  // For now, we'll scan and filter by group_id
  // In the future, you might want to add a GSI for group_id
  const scanParams = new ScanCommand({
    TableName: POSTS_TABLE,
    FilterExpression: "is_deleted = :isDeleted AND group_id IN (:groupIds)",
    ExpressionAttributeValues: {
      ":isDeleted": false,
      ":groupIds": groupIds,
    },
  });

  const result = await dynamoDb.send(scanParams);
  const posts = result.Items || [];

  // Sort by engagement score within groups
  const postsWithScore = posts.map((post) => ({
    ...post,
    engagementScore: calculateEngagementScore(post),
  }));

  postsWithScore.sort((a, b) => b.engagementScore - a.engagementScore);

  // Apply pagination
  return postsWithScore.slice(offset, offset + pageSize);
};

// Helper function to get total count for pagination
const getTotalCount = async (
  filter: string,
  userId?: string
): Promise<number> => {
  // For now, we'll get the total count of non-deleted posts
  // In the future, this should be filtered based on the filter type
  const scanParams = new ScanCommand({
    TableName: POSTS_TABLE,
    FilterExpression: "is_deleted = :isDeleted",
    ExpressionAttributeValues: {
      ":isDeleted": false,
    },
    Select: "COUNT",
  });

  const result = await dynamoDb.send(scanParams);
  return result.Count || 0;
};

// Helper function to get interaction counts for posts
const getInteractionCounts = async (
  postIds: string[]
): Promise<{ [postId: string]: any }> => {
  const counts: { [postId: string]: any } = {};

  // Initialize counts for all posts
  postIds.forEach((postId) => {
    counts[postId] = {
      comments: 0,
      likes: 0,
      reposts: 0,
      quotes: 0,
      views: 0,
      reactions: {
        like: 0,
        love: 0,
        laugh: 0,
        wow: 0,
        sad: 0,
        angry: 0,
      },
    };
  });

  try {
    // Get view counts using BatchGetItem
    const viewKeys = postIds.map((postId) => ({ post_id: postId }));
    const viewBatchParams = new BatchGetCommand({
      RequestItems: {
        post_view_counters: {
          Keys: viewKeys,
        },
      },
    });

    const viewResult = await dynamoDb.send(viewBatchParams);
    if (viewResult.Responses?.["post_view_counters"]) {
      viewResult.Responses["post_view_counters"].forEach((item: any) => {
        const postId = item.post_id;
        if (postId && item.view_count) {
          counts[postId].views = parseInt(item.view_count.N || "0", 10);
        }
      });
    }

    // Get all reactions for all posts - scan entire table and filter in memory
    const reactionsParams = new ScanCommand({
      TableName: "post_reactions",
    });

    const reactionsResult = await dynamoDb.send(reactionsParams);
    if (reactionsResult.Items) {
      console.log("Reactions found:", reactionsResult.Items.length);
      console.log("Sample reactions:", reactionsResult.Items.slice(0, 3));
      console.log("Querying for post IDs:", postIds);

      // Create a set of lowercase post IDs for efficient lookup
      const targetPostIds = new Set(postIds.map((id) => id.toLowerCase()));

      // Group reactions by post_id and reaction type (case-insensitive)
      const reactionCounts: {
        [postId: string]: { [reaction: string]: number };
      } = {};

      reactionsResult.Items.forEach((item) => {
        const postId = item.post_id;
        const reaction = item.reaction;
        // Use lowercase for consistent matching
        const normalizedPostId = postId.toLowerCase();

        // Only process if this post is in our target list
        if (targetPostIds.has(normalizedPostId)) {
          if (!reactionCounts[normalizedPostId]) {
            reactionCounts[normalizedPostId] = {};
          }
          reactionCounts[normalizedPostId][reaction] =
            (reactionCounts[normalizedPostId][reaction] || 0) + 1;
        }
      });

      console.log("Reaction counts by post (normalized):", reactionCounts);

      // Map reactions to expected fields (case-insensitive matching)
      postIds.forEach((postId) => {
        const normalizedPostId = postId.toLowerCase();
        const postReactions = reactionCounts[normalizedPostId] || {};

        // Set detailed reaction counts
        counts[postId].reactions.like = postReactions["like"] || 0;
        counts[postId].reactions.love = postReactions["love"] || 0;
        counts[postId].reactions.laugh = postReactions["laugh"] || 0;
        counts[postId].reactions.wow = postReactions["wow"] || 0;
        counts[postId].reactions.sad = postReactions["sad"] || 0;
        counts[postId].reactions.angry = postReactions["angry"] || 0;

        // Map specific reactions to expected fields (legacy support)
        // New reaction types: like, love, laugh, wow, sad, angry
        counts[postId].likes =
          postReactions["like"] ||
          postReactions["love"] ||
          postReactions["👍"] ||
          postReactions["❤️"] ||
          0;
        counts[postId].reposts =
          postReactions["🔄"] || postReactions["repost"] || 0;
        counts[postId].quotes =
          postReactions["💬"] || postReactions["quote"] || 0;
      });
    }

    // Get comment counts - scan entire table and filter in memory
    const commentsParams = new ScanCommand({
      TableName: "post_comments",
    });

    const commentsResult = await dynamoDb.send(commentsParams);
    if (commentsResult.Items) {
      console.log("Comments found:", commentsResult.Items.length);
      console.log("Sample comments:", commentsResult.Items.slice(0, 3));

      // Create a set of lowercase post IDs for efficient lookup
      const targetPostIds = new Set(postIds.map((id) => id.toLowerCase()));

      // Group comments by post_id (case-insensitive)
      const commentCounts: { [postId: string]: number } = {};
      commentsResult.Items.forEach((item) => {
        const postId = item.post_id;
        // Use lowercase for consistent matching
        const normalizedPostId = postId.toLowerCase();

        // Only process if this post is in our target list
        if (targetPostIds.has(normalizedPostId)) {
          commentCounts[normalizedPostId] =
            (commentCounts[normalizedPostId] || 0) + 1;
        }
      });

      console.log("Comment counts by post (normalized):", commentCounts);

      // Assign comment counts (case-insensitive matching)
      postIds.forEach((postId) => {
        const normalizedPostId = postId.toLowerCase();
        counts[postId].comments = commentCounts[normalizedPostId] || 0;
      });
    }

    // Get favorite counts and add them to likes - scan entire table and filter in memory
    const favoritesParams = new ScanCommand({
      TableName: "post_user_favorites",
    });

    const favoritesResult = await dynamoDb.send(favoritesParams);
    if (favoritesResult.Items) {
      console.log("Favorites found:", favoritesResult.Items.length);
      console.log("Sample favorites:", favoritesResult.Items.slice(0, 3));

      // Create a set of lowercase post IDs for efficient lookup
      const targetPostIds = new Set(postIds.map((id) => id.toLowerCase()));

      // Group favorites by post_id (case-insensitive)
      const favoriteCounts: { [postId: string]: number } = {};
      favoritesResult.Items.forEach((item) => {
        const postId = item.post_id;
        // Use lowercase for consistent matching
        const normalizedPostId = postId.toLowerCase();

        // Only process if this post is in our target list
        if (targetPostIds.has(normalizedPostId)) {
          favoriteCounts[normalizedPostId] =
            (favoriteCounts[normalizedPostId] || 0) + 1;
        }
      });

      console.log("Favorite counts by post:", favoriteCounts);

      // Add favorite counts to likes (case-insensitive matching)
      postIds.forEach((postId) => {
        const normalizedPostId = postId.toLowerCase();
        const favoriteCount = favoriteCounts[normalizedPostId] || 0;
        counts[postId].likes += favoriteCount;
        if (favoriteCount > 0) {
          console.log(`Post ${postId} has ${favoriteCount} favorites`);
        }
      });
    }
  } catch (error) {
    console.error("Error getting interaction counts:", error);
  }

  console.log("Final interaction counts:", counts);
  return counts;
};

// Helper function to get user interaction states for posts
const getUserInteractionStates = async (
  postIds: string[],
  userId: string
): Promise<{
  [postId: string]: { is_favorite: boolean; user_reaction: string | null };
}> => {
  const states: {
    [postId: string]: { is_favorite: boolean; user_reaction: string | null };
  } = {};

  // Initialize states for all posts
  postIds.forEach((postId) => {
    states[postId] = {
      is_favorite: false,
      user_reaction: null,
    };
  });

  if (!userId) {
    return states;
  }

  try {
    // Get user favorites for all posts using BatchGetItem
    const favoriteKeys = postIds.map((postId) => ({
      user_id: userId,
      post_id: postId,
    }));

    const batchParams = new BatchGetCommand({
      RequestItems: {
        post_user_favorites: {
          Keys: favoriteKeys,
        },
        post_reactions: {
          Keys: postIds.map((postId) => ({
            post_id: postId,
            user_id: userId,
          })),
        },
      },
    });

    const result = await dynamoDb.send(batchParams);

    if (result.Responses?.["post_user_favorites"]) {
      result.Responses["post_user_favorites"].forEach((item: any) => {
        const postId = item.post_id;
        if (postId) {
          states[postId].is_favorite = true;
        }
      });
    }

    if (result.Responses?.["post_reactions"]) {
      result.Responses["post_reactions"].forEach((item: any) => {
        const postId = item.post_id;
        const reaction = item.reaction?.S;
        if (postId && reaction) {
          states[postId].user_reaction = reaction;
        }
      });
    }
  } catch (error) {
    console.error("Error getting user interaction states:", error);
  }

  return states;
};

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    console.log("Received event:", JSON.stringify(event));

    const token = event.headers["Authorization"]?.split(" ")[1];

    if (!token) {
      console.error("Unauthorized: Missing token");
      throw new Error("Unauthorized");
    }

    // Extract scopes and user info from authorizer context
    const scopes = (event.requestContext.authorizer?.scope || "").split(" ");
    const userId = event.requestContext.authorizer?.user;

    console.log("scopes", scopes);
    console.log("userId", userId);

    // Parse query parameters
    const queryParams: QueryParams = event.queryStringParameters || {};
    const filter = queryParams.filter || "latest";
    const page = parseInt(queryParams.page || "0", 10);
    const pageSize = parseInt(queryParams.pageSize || "20", 10);
    const searchQuery = queryParams.search;

    console.log("Received query parameters:", {
      filter,
      page,
      pageSize,
      search: searchQuery,
    });

    // Validate pagination parameters
    if (page < 0) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({ error: "Page must be 0 or greater" }),
      };
    }

    if (pageSize < 1 || pageSize > 100) {
      return {
        statusCode: 400,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Access-Control-Allow-Origin": "*",
        },
        body: JSON.stringify({ error: "Page size must be between 1 and 100" }),
      };
    }

    // Get posts based on filter
    const posts = await getPostsByFilter(filter, page, pageSize, userId);

    // Get total count for pagination info
    const totalCount = await getTotalCount(filter, userId);

    // Get unique user IDs from posts
    const userIds = [
      ...new Set(posts.map((post) => post.user_id).filter(Boolean)),
    ];

    // Batch fetch user profiles
    let userProfiles: { [userId: string]: UserProfile } = {};

    if (userIds.length > 0) {
      // DynamoDB BatchGet can handle up to 100 items at once
      const batchSize = 100;
      for (let i = 0; i < userIds.length; i += batchSize) {
        const batch = userIds.slice(i, i + batchSize);

        const batchParams = new BatchGetCommand({
          RequestItems: {
            [USER_PROFILE_TABLE]: {
              Keys: batch.map((userId) => ({
                PK: `USER#${userId}`,
                SK: `PROFILE#${userId}`,
              })),
              ProjectionExpression:
                "user_id, handle, profile_picture_url, first_name, last_name",
            },
          },
        });

        const batchResult = await dynamoDb.send(batchParams);

        if (batchResult.Responses?.[USER_PROFILE_TABLE]) {
          batchResult.Responses[USER_PROFILE_TABLE].forEach((profile: any) => {
            userProfiles[profile.user_id] = {
              id: profile.user_id,
              handle: profile.handle,
              profile_picture_url: profile.profile_picture_url,
              first_name: profile.first_name,
              last_name: profile.last_name,
            };
          });
        }
      }
    }

    // Enhance posts with user information
    const postsWithUserInfo: PostWithUserInfo[] = posts.map((post) => ({
      ...post,
      user: post.user_id ? userProfiles[post.user_id] : undefined,
    }));

    // Get interaction counts for all posts
    const postIds = posts.map((post) => post.id);

    // Limit the number of posts we process for interaction data to prevent timeouts
    const maxPostsForInteractions = 50;
    const limitedPostIds = postIds.slice(0, maxPostsForInteractions);

    console.log(
      `Processing interaction data for ${limitedPostIds.length} posts out of ${postIds.length} total posts`
    );

    let interactionCounts: { [postId: string]: any } = {};
    let userInteractionStates: {
      [postId: string]: { is_favorite: boolean; user_reaction: string | null };
    } = {};

    try {
      [interactionCounts, userInteractionStates] = await Promise.all([
        getInteractionCounts(limitedPostIds),
        userId
          ? getUserInteractionStates(limitedPostIds, userId)
          : Promise.resolve(
              {} as {
                [postId: string]: {
                  is_favorite: boolean;
                  user_reaction: string | null;
                };
              }
            ),
      ]);
      console.log("Successfully fetched interaction data");
    } catch (error) {
      console.error("Error fetching interaction data, using defaults:", error);
      // Use default values if interaction data fails to load
      interactionCounts = {};
      userInteractionStates = {};
    }

    // Add interaction counts and user interaction states to posts
    const postsWithInteractions = postsWithUserInfo.map((post) => ({
      ...post,
      ...interactionCounts[post.id],
      ...userInteractionStates[post.id],
    }));

    // Calculate pagination info
    const totalPages = Math.ceil(totalCount / pageSize);
    const pagination: PaginationInfo = {
      currentPage: page,
      pageSize: pageSize,
      totalItems: totalCount,
      totalPages: totalPages,
      hasNextPage: page < totalPages - 1,
      hasPreviousPage: page > 0,
    };

    console.log("postsWithInteractions", postsWithInteractions);
    console.log("pagination", pagination);

    const response: PostsResponse = {
      posts: postsWithInteractions,
      pagination: pagination,
    };

    console.log("response", JSON.stringify(response, null, 2));

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify(response),
    };
  } catch (error) {
    console.error("Error retrieving posts:", error);

    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
      },
      body: JSON.stringify({ error: "Failed to retrieve posts" }),
    };
  }
};
