import type { NextFunction, Request, Response } from 'express';

type AsyncRouteHandler = (req: Request, res: Response) => Promise<void>;

/// Express doesn't forward a rejected promise to error middleware on its
/// own — every async controller must be wrapped in this so thrown
/// HttpError/ZodError instances reach errorHandler instead of hanging the
/// request or crashing the process.
export function asyncHandler(handler: AsyncRouteHandler) {
  return (req: Request, res: Response, next: NextFunction) => {
    handler(req, res).catch(next);
  };
}
