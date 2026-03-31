import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus } from '@nestjs/common';
import type { Response } from 'express';

import type { RequestWithUser } from '../types/request-with-user.type';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: unknown, host: ArgumentsHost) {
    const context = host.switchToHttp();
    const response = context.getResponse<Response>();
    const request = context.getRequest<RequestWithUser>();

    const status =
      exception instanceof HttpException ? exception.getStatus() : HttpStatus.INTERNAL_SERVER_ERROR;

    const exceptionResponse =
      exception instanceof HttpException ? exception.getResponse() : 'Internal server error';

    const rawMessage =
      typeof exceptionResponse === 'string'
        ? exceptionResponse
        : ((exceptionResponse as { message?: string | string[] }).message ?? 'Request failed');

    const message = Array.isArray(rawMessage) ? 'Validation failed' : rawMessage;
    const details = Array.isArray(rawMessage) ? rawMessage : undefined;

    response.status(status).json({
      success: false,
      requestId: request.requestId ?? 'unknown',
      timestamp: new Date().toISOString(),
      path: request.originalUrl,
      error: {
        code: HttpStatus[status] ?? 'INTERNAL_SERVER_ERROR',
        message,
        details,
      },
    });
  }
}
