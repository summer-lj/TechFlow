import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { map, type Observable } from 'rxjs';

import type { ApiEnvelope, ApiPayload } from '../interfaces/api-response.interface';
import type { RequestWithUser } from '../types/request-with-user.type';

@Injectable()
export class ResponseInterceptor<T> implements NestInterceptor<ApiPayload<T>, ApiEnvelope<T>> {
  intercept(
    context: ExecutionContext,
    next: CallHandler<ApiPayload<T>>,
  ): Observable<ApiEnvelope<T>> {
    const request = context.switchToHttp().getRequest<RequestWithUser>();

    return next.handle().pipe(
      map((payload) => ({
        success: true,
        message: payload.message ?? 'Request completed successfully',
        requestId: request.requestId ?? 'unknown',
        timestamp: new Date().toISOString(),
        path: request.originalUrl,
        data: payload.data,
        ...(payload.meta ? { meta: payload.meta } : {}),
      })),
    );
  }
}
