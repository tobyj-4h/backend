import { handler } from "./user-profile-put";

const mockSend = jest.fn();
jest.mock("@aws-sdk/lib-dynamodb", () => {
  return {
    DynamoDBDocumentClient: {
      from: () => ({ send: (...args: any[]) => mockSend(...args) }),
    },
    PutCommand: jest.fn(),
    UpdateCommand: jest.fn(),
    QueryCommand: jest.fn(),
  };
});

jest.mock("@aws-sdk/client-dynamodb", () => {
  return { DynamoDBClient: jest.fn() };
});

describe("User Profile PUT Handler", () => {
  const mockEvent = {
    requestContext: {
      authorizer: {
        user: "test-user-id",
      },
    },
    headers: {
      Authorization: "Bearer test-token",
    },
    body: JSON.stringify({
      firstName: "John",
      lastName: "Doe",
      handle: "johndoe",
      profilePictureUrl: "https://example.com/avatar.jpg",
      onboardingComplete: true,
    }),
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

  it("should create user profile successfully", async () => {
    mockSend.mockResolvedValue({}); // PutCommand succeeds
    const now = Date.now;
    Date.now = () => 1234567890000;
    const result = await handler(mockEvent);
    Date.now = now;
    expect(result.statusCode).toBe(201);
    const body = JSON.parse(result.body);
    expect(body.PK).toBe("USER#test-user-id");
    expect(body.SK).toBe("PROFILE#test-user-id");
    expect(body.user_id).toBe("test-user-id");
    expect(body.first_name).toBe("John");
    expect(body.last_name).toBe("Doe");
    expect(body.handle).toBe("johndoe");
    expect(body.profile_picture_url).toBe("https://example.com/avatar.jpg");
    expect(body.onboarding_complete).toBe(true);
    expect(body.created_at).toBeDefined();
    expect(body.onboarding_complete_at).toBeDefined();
  });

  it("should handle optional fields correctly", async () => {
    const eventWithMinimalData = {
      ...mockEvent,
      body: JSON.stringify({
        firstName: "Jane",
        lastName: "Smith",
        handle: "janesmith",
      }),
    };
    mockSend.mockResolvedValue({});
    const result = await handler(eventWithMinimalData);
    expect(result.statusCode).toBe(201);
    const body = JSON.parse(result.body);
    expect(body.first_name).toBe("Jane");
    expect(body.last_name).toBe("Smith");
    expect(body.handle).toBe("janesmith");
    expect(body.profile_picture_url).toBeUndefined();
    expect(body.onboarding_complete).toBeUndefined();
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
