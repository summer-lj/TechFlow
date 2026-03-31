import { Injectable, type NestMiddleware } from '@nestjs/common';
import { randomUUID } from 'crypto';
import type { NextFunction, Response } from 'express';

import type { RequestWithUser } from '../types/request-with-user.type';

@Injectable()
export class RequestContextMiddleware implements NestMiddleware {
  use(request: RequestWithUser, response: Response, next: NextFunction) {
    const incomingRequestId = request.header('x-request-id');
    const requestId = incomingRequestId || randomUUID();

    request.requestId = requestId;
    response.setHeader('x-request-id', requestId);

    next();
  }
}
