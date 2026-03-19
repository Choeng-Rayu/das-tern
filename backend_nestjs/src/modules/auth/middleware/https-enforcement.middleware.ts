import { Injectable, NestMiddleware } from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';

@Injectable()
export class HttpsEnforcementMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    if (process.env.NODE_ENV !== 'production') {
      return next();
    }

    const forwardedProtoHeader = req.headers['x-forwarded-proto'];
    const forwardedProto = Array.isArray(forwardedProtoHeader)
      ? forwardedProtoHeader[0]
      : forwardedProtoHeader;

    const isForwardedHttps =
      typeof forwardedProto === 'string' &&
      forwardedProto.split(',')[0].trim().toLowerCase() === 'https';

    if (req.secure || isForwardedHttps) {
      return next();
    }

    return res
      .status(403)
      .json({ message: 'HTTPS is required for authentication endpoints' });
  }
}
