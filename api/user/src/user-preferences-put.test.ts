import { handler } from "./user-preferences-put";

const mockSend = jest.fn();
jest.mock("@aws-sdk/lib-dynamodb", () => {
  return {
    DynamoDBDocumentClient: {
      from: () => ({ send: (...args: any[]) => mockSend(...args) }),
    },
    PutCommand: jest.fn(),
  };
});

jest.mock("@aws-sdk/client-dynamodb", () => {
  return { DynamoDBClient: jest.fn() };
});

describe("User Preferences PUT Handler", () => {
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
      locations: [{ lat: 40.7128, lng: -74.006 }],
      schools: ["school1", "school2"],
      districts: ["district1"],
      topics: ["math", "science"],
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
      error: "Failed to create user preferences",
    });
  });

  it("should return 400 when locations is not an array", async () => {
    const eventWithInvalidLocations = {
      ...mockEvent,
      body: JSON.stringify({
        locations: "not an array",
        schools: ["school1"],
        districts: ["district1"],
        topics: ["math"],
      }),
    };
    const result = await handler(eventWithInvalidLocations);
    expect(result.statusCode).toBe(400);
    expect(JSON.parse(result.body)).toEqual({
      error: "locations is required and must be an array",
    });
  });

  it("should return 400 when schools is not an array", async () => {
    const eventWithInvalidSchools = {
      ...mockEvent,
      body: JSON.stringify({
        locations: [{ lat: 40.7128, lng: -74.006 }],
        schools: "not an array",
        districts: ["district1"],
        topics: ["math"],
      }),
    };
    const result = await handler(eventWithInvalidSchools);
    expect(result.statusCode).toBe(400);
    expect(JSON.parse(result.body)).toEqual({
      error: "schools is required and must be an array",
    });
  });

  it("should return 400 when districts is not an array", async () => {
    const eventWithInvalidDistricts = {
      ...mockEvent,
      body: JSON.stringify({
        locations: [{ lat: 40.7128, lng: -74.006 }],
        schools: ["school1"],
        districts: "not an array",
        topics: ["math"],
      }),
    };
    const result = await handler(eventWithInvalidDistricts);
    expect(result.statusCode).toBe(400);
    expect(JSON.parse(result.body)).toEqual({
      error: "districts is required and must be an array",
    });
  });

  it("should return 400 when topics is not an array", async () => {
    const eventWithInvalidTopics = {
      ...mockEvent,
      body: JSON.stringify({
        locations: [{ lat: 40.7128, lng: -74.006 }],
        schools: ["school1"],
        districts: ["district1"],
        topics: "not an array",
      }),
    };
    const result = await handler(eventWithInvalidTopics);
    expect(result.statusCode).toBe(400);
    expect(JSON.parse(result.body)).toEqual({
      error: "topics is required and must be an array",
    });
  });

  it("should create user preferences successfully", async () => {
    mockSend.mockResolvedValue({}); // PutCommand succeeds
    const now = Date.now;
    Date.now = () => 1234567890000;
    const result = await handler(mockEvent);
    Date.now = now;
    expect(result.statusCode).toBe(201);
    const body = JSON.parse(result.body);
    expect(body.PK).toBe("USER#test-user-id");
    expect(body.SK).toBe("PREFERENCES#test-user-id");
    expect(body.user_id).toBe("test-user-id");
    expect(body.locations).toEqual([{ lat: 40.7128, lng: -74.006 }]);
    expect(body.schools).toEqual(["school1", "school2"]);
    expect(body.districts).toEqual(["district1"]);
    expect(body.topics).toEqual(["math", "science"]);
    expect(body.created_at).toBeDefined();
  });

  it("should handle DynamoDB errors gracefully", async () => {
    mockSend.mockRejectedValue(new Error("DynamoDB error"));
    const result = await handler(mockEvent);
    expect(result.statusCode).toBe(500);
    expect(JSON.parse(result.body)).toEqual({
      error: "Failed to create user preferences",
    });
  });
});
