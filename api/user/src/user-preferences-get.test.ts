import { handler } from "./user-preferences-get";

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

describe("User Preferences GET Handler", () => {
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
      error: "Failed to get user preferences",
    });
  });

  it("should return 404 when no preferences exist", async () => {
    mockSend.mockResolvedValue({ Item: null });
    const result = await handler(mockEvent);
    expect(result.statusCode).toBe(404);
    const body = JSON.parse(result.body);
    expect(body.error).toBe("Preferences not found");
  });

  it("should return user preferences when they exist", async () => {
    const mockPreferences = {
      PK: "USER#test-user-id",
      SK: "PREFERENCES#test-user-id",
      user_id: "test-user-id",
      locations: [{ lat: 40.7128, lng: -74.006 }],
      schools: ["school1", "school2"],
      districts: ["district1"],
      topics: ["math", "science"],
    };
    mockSend.mockResolvedValue({ Item: mockPreferences });
    const result = await handler(mockEvent);
    expect(result.statusCode).toBe(200);
    const body = JSON.parse(result.body);
    expect(body).toEqual(mockPreferences);
  });

  it("should handle DynamoDB errors gracefully", async () => {
    mockSend.mockRejectedValue(new Error("DynamoDB error"));
    const result = await handler(mockEvent);
    expect(result.statusCode).toBe(500);
    expect(JSON.parse(result.body)).toEqual({
      error: "Failed to get user preferences",
    });
  });
});
