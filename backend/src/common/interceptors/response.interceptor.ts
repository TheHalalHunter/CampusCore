import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from "@nestjs/common";
import { Observable } from "rxjs";
import { map } from "rxjs/operators";

export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message?: string;
}

/** Wraps all successful responses in a standard { success, data } envelope.
 *  If a controller already returns a shaped { success, data } object the
 *  interceptor passes it through untouched to prevent double-wrapping.
 */
@Injectable()
export class ResponseInterceptor<T> implements NestInterceptor<
  T,
  ApiResponse<T>
> {
  intercept(
    _context: ExecutionContext,
    next: CallHandler,
  ): Observable<ApiResponse<T>> {
    return next.handle().pipe(
      map((data) => {
        // Already wrapped — pass through as-is
        if (data !== null && typeof data === 'object' && 'success' in data) {
          return data;
        }
        return {
          success: true,
          data,
          message: undefined,
        };
      }),
    );
  }
}
