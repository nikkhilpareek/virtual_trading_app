import jwt from 'jsonwebtoken';
import config from '../config';

export interface TokenPayload {
    userId: string;
    email: string;
}

export interface TokenPair {
    accessToken: string;
    refreshToken: string;
}

/**
 * Generate access and refresh tokens for a user
 */
export const generateTokens = (payload: TokenPayload): TokenPair => {
    const accessToken = jwt.sign(payload, config.jwt.secret, {
        expiresIn: config.jwt.expiresIn,
    });

    const refreshToken = jwt.sign(payload, config.jwt.refreshSecret, {
        expiresIn: config.jwt.refreshExpiresIn,
    });

    return { accessToken, refreshToken };
};

/**
 * Verify and decode an access token
 */
export const verifyAccessToken = (token: string): TokenPayload => {
    return jwt.verify(token, config.jwt.secret) as TokenPayload;
};

/**
 * Verify and decode a refresh token
 */
export const verifyRefreshToken = (token: string): TokenPayload => {
    return jwt.verify(token, config.jwt.refreshSecret) as TokenPayload;
};
