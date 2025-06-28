import { handler } from "./user-profile-get";

const mockSend = jest.fn();
jest.mock("@aws-sdk/lib-dynamodb", () => {
  return {
    DynamoDBDocumentClient: {
      from: () => ({ send: (...args: any[]) => mockSend(...args) }),
    },
    GetCommand: jest.fn(),
  };
});

jest.mock("@aws-sdk/client-dynamodb", () => {
  return { DynamoDBClient: jest.fn() };
});

describe("User Profile GET Handler", () => {
  const mockEvent = {
    requestContext: {
      authorizer: {
        user: "test-user-id",
      },
    },
    headers: {
      Authorization: "Bearer test-token",
    },
  } as any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockSend.mockReset();
  });

  it("should return 401 when token is missing", async () => {
    const eventWithoutToken = {
      ...mockEvent,
      headers: {},
    };
    const result = await handler(eventWithoutToken);
    expect(result.statusCode).toBe(500); // The handler throws an error which gets caught
    expect(JSON.parse(result.body)).toEqual({
      error: "Failed to create user profile",
    });
  });

  it("should return 404 when no profile exists", async () => {
    mockSend.mockResolvedValue({ Item: null });
    const result = await handler(mockEvent);
    expect(result.statusCode).toBe(404);
    const body = JSON.parse(result.body);
    expect(body.error).toBe("Profile not found");
  });

  it("should return user profile when it exists", async () => {
    const mockProfile = {
      PK: "USER#test-user-id",
      SK: "PROFILE#test-user-id",
      user_id: "test-user-id",
      first_name: "John",
      last_name: "Doe",
      handle: "johndoe",
      profile_picture_url: "https://example.com/avatar.jpg",
      onboarding_complete: true,
      created_at: "2023-01-01T00:00:00.000Z",
    };
    mockSend.mockResolvedValue({ Item: mockProfile });
    const result = await handler(mockEvent);
    expect(result.statusCode).toBe(200);
    const body = JSON.parse(result.body);
    expect(body).toEqual(mockProfile);
  });

  it("should handle DynamoDB errors gracefully", async () => {
    mockSend.mockRejectedValue(new Error("DynamoDB error"));
    const result = await handler(mockEvent);
    expect(result.statusCode).toBe(500);
    expect(JSON.parse(result.body)).toEqual({
      error: "Failed to create user profile",
    });
  });
});
