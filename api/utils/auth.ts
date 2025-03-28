// import { JwtPayload } from "jsonwebtoken";
// import jwt from "jsonwebtoken";
// import { getAllowedOrigin } from "./origin";

// /**
//  * Validates the request origin against allowed origins.
//  * @param origin - The request origin
//  * @returns The allowed origin if valid, throws an error otherwise.
//  */
// export const validateOrigin = (origin: string): string => {
//   const allowedOrigin = getAllowedOrigin(origin);
//   if (!allowedOrigin) {
//     throw {
//       statusCode: 403,
//       message: "Origin not allowed.",
//     };
//   }
//   return allowedOrigin;
// };

// /**
//  * Decodes a JWT token.
//  * @param token - The JWT token
//  * @returns Decoded JWT payload
//  * @throws Error if the token is invalid or cannot be decoded
//  */
// export const decodeToken = (token: string): JwtPayload => {
//   const decoded = jwt.decode(token);

//   if (!decoded || typeof decoded === "string") {
//     throw new Error("Invalid token: Unable to decode payload");
//   }

//   return decoded as JwtPayload;
// };
