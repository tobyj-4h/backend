import { handler } from "./user-settings-get";

// Mock DynamoDB client
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

describe("User Settings GET Handler", () => {
  const mockEvent = {
    requestContext: {
      authorizer: {
        user: "test-user-id",
      },
    },
    headers: {},
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

  it("should return 404 when no settings exist", async () => {
    mockSend.mockResolvedValue({ Item: null });
    const result = await handler(mockEvent);
    expect(result.statusCode).toBe(404);
    const body = JSON.parse(result.body);
    expect(body.error).toBe("Settings not found");
  });

  it("should return user settings when they exist", async () => {
    const mockSettings = {
      PK: "USER#test-user-id",
      SK: "SETTINGS",
      isDarkMode: true,
      themeColor: "blue",
      fontSize: 16,
      biometricEnabled: true,
    };
    mockSend.mockResolvedValue({ Item: mockSettings });
    const result = await handler(mockEvent);
    expect(result.statusCode).toBe(200);
    const body = JSON.parse(result.body);
    expect(body).toEqual(mockSettings);
  });

  it("should handle DynamoDB errors gracefully", async () => {
    mockSend.mockRejectedValue(new Error("DynamoDB error"));
    const result = await handler(mockEvent);
    expect(result.statusCode).toBe(500);
    expect(JSON.parse(result.body)).toEqual({
      error: "Failed to get user settings",
    });
  });
});
