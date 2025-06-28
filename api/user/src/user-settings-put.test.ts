import { handler } from "./user-settings-put";

// Mock DynamoDB client
const mockSend = jest.fn();
jest.mock("@aws-sdk/lib-dynamodb", () => {
  return {
    DynamoDBDocumentClient: {
      from: () => ({ send: (...args: any[]) => mockSend(...args) }),
    },
    PutCommand: jest.fn(),
    GetCommand: jest.fn(),
  };
});

jest.mock("@aws-sdk/client-dynamodb", () => {
  return { DynamoDBClient: jest.fn() };
});

describe("User Settings PUT Handler", () => {
  const mockEvent = {
    requestContext: {
      authorizer: {
        user: "test-user-id",
      },
    },
    headers: {},
    body: JSON.stringify({
      isDarkMode: true,
      themeColor: "blue",
      fontSize: 16,
      biometricEnabled: true,
    }),
  } as any;

  beforeEach(() => {
    jest.clearAllMocks();
    mockSend.mockReset();
  });

  it("should return 401 when user ID is missing", async () => {
    const eventWithoutUser = {
      ...mockEvent,
      requestContext: { authorizer: {} },
    };

    const result = await handler(eventWithoutUser);

    expect(result.statusCode).toBe(401);
    expect(JSON.parse(result.body)).toEqual({
      error: "Unauthorized",
      message: "User ID not found in request context",
    });
  });

  it("should return 400 for invalid JSON body", async () => {
    const eventWithInvalidBody = {
      ...mockEvent,
      body: "invalid json",
    };

    const result = await handler(eventWithInvalidBody);

    expect(result.statusCode).toBe(400);
    expect(JSON.parse(result.body)).toEqual({
      error: "Bad Request",
      message: "Invalid JSON in request body",
    });
  });

  it("should return 400 for invalid settings data", async () => {
    const eventWithInvalidSettings = {
      ...mockEvent,
      body: JSON.stringify({
        isDarkMode: "not a boolean",
        fontSize: 50, // out of range
        themeColor: 123,
      }),
    };

    const result = await handler(eventWithInvalidSettings);

    expect(result.statusCode).toBe(400);
    const body = JSON.parse(result.body);
    expect(body.error).toBe("Invalid data");
    expect(body.details).toContain("isDarkMode must be a boolean");
    expect(body.details).toContain(
      "fontSize must be an integer between 10 and 30"
    );
    expect(body.details).toContain("themeColor must be a string");
  });

  it("should create new settings", async () => {
    mockSend.mockResolvedValue({}); // PutCommand succeeds
    const now = Date.now;
    Date.now = () => 1234567890000;
    const result = await handler(mockEvent);
    Date.now = now;
    expect(result.statusCode).toBe(201);
    const body = JSON.parse(result.body);
    expect(body.PK).toBe("USER#test-user-id");
    expect(body.SK).toBe("SETTINGS");
    expect(body.isDarkMode).toBe(true);
    expect(body.themeColor).toBe("blue");
    expect(body.fontSize).toBe(16);
    expect(body.biometricEnabled).toBe(true);
    expect(body.user_id).toBe("test-user-id");
    expect(body.updated_at).toBeDefined();
  });

  it("should handle DynamoDB errors gracefully", async () => {
    mockSend.mockRejectedValue(new Error("DynamoDB error"));
    const result = await handler(mockEvent);
    expect(result.statusCode).toBe(500);
    expect(JSON.parse(result.body)).toEqual({
      error: "Failed to save user settings",
    });
  });
});
