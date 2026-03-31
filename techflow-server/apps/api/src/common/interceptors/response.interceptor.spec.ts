import { ExecutionContextHost } from '@nestjs/core/helpers/execution-context-host';
import { firstValueFrom, of } from 'rxjs';

import { ResponseInterceptor } from './response.interceptor';

describe('ResponseInterceptor', () => {
  it('wraps successful payloads in the standard envelope', async () => {
    const interceptor = new ResponseInterceptor<{ hello: string }>();
    const request = {
      requestId: 'req-123',
      originalUrl: '/api/v1/example',
    };

    const context = new ExecutionContextHost([request]);
    context.setType('http');

    const result = await firstValueFrom(
      interceptor.intercept(context as never, {
        handle: () =>
          of({
            message: 'Fetched',
            data: { hello: 'world' },
          }),
      }),
    );

    expect(result).toMatchObject({
      success: true,
      message: 'Fetched',
      requestId: 'req-123',
      path: '/api/v1/example',
      data: { hello: 'world' },
    });
  });
});
