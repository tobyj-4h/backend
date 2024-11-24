const ALLOWED_ORIGINS = [
  "http://localhost:5173",
  "https://dev.fourhorizonsed.com",
  "https://staging.fourhorizonsed.com",
  "https://app.fourhorizonsed.com",
];

/**
 * Gets the allowed origin if the request origin is valid.
 * @param origin - The request origin
 * @returns The matched origin or null if not allowed.
 */
export const getAllowedOrigin = (origin: string): string | null => {
  return ALLOWED_ORIGINS.includes(origin) ? origin : null;
};

export default getAllowedOrigin;
