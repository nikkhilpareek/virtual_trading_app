import { Request, Response, NextFunction } from 'express';
import { ApiError } from '../utils/errors';

/**
 * Global error handler middleware
 */
export const errorHandler = (
    error: Error,
    req: Request,
    res: Response,
    next: NextFunction
): void => {
    if (error instanceof ApiError) {
        res.status(error.statusCode).json({
            success: false,
            message: error.message,
        });
        return;
    }

    // Log unexpected errors
    console.error('Unexpected error:', error);

    res.status(500).json({
        success: false,
        message: 'Internal server error',
    });
};
