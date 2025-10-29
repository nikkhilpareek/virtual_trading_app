import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken } from '../services/token.service';

export interface AuthRequest extends Request {
    user?: {
        userId: string;
        email: string;
    };
}

/**
 * Middleware to authenticate requests using JWT
 */
export const authenticate = (
    req: AuthRequest,
    res: Response,
    next: NextFunction
): void => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            res.status(401).json({
                success: false,
                message: 'No token provided',
            });
            return;
        }

        const token = authHeader.substring(7);
        const decoded = verifyAccessToken(token);

        req.user = {
            userId: decoded.userId,
            email: decoded.email,
        };

        next();
    } catch (error) {
        res.status(401).json({
            success: false,
            message: 'Invalid or expired token',
        });
    }
};
