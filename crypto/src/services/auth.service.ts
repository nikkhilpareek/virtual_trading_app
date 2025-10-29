import prisma from '../config/database';
import { hashPassword, comparePassword } from '../utils/password';
import { generateTokens, verifyRefreshToken, TokenPair } from './token.service';

export interface SignupData {
    email: string;
    password: string;
    name?: string;
}

export interface LoginData {
    email: string;
    password: string;
}

export interface AuthResponse {
    user: {
        id: string;
        email: string;
        name: string | null;
    };
    tokens: TokenPair;
}

/**
 * Register a new user
 */
export const signup = async (data: SignupData): Promise<AuthResponse> => {
    const { email, password, name } = data;

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
        where: { email },
    });

    if (existingUser) {
        throw new Error('User with this email already exists');
    }

    // Hash password
    const hashedPassword = await hashPassword(password);

    // Create user
    const user = await prisma.user.create({
        data: {
            email,
            password: hashedPassword,
            name,
        },
    });

    // Generate tokens
    const tokens = generateTokens({
        userId: user.id,
        email: user.email,
    });

    return {
        user: {
            id: user.id,
            email: user.email,
            name: user.name,
        },
        tokens,
    };
};

/**
 * Login an existing user
 */
export const login = async (data: LoginData): Promise<AuthResponse> => {
    const { email, password } = data;

    // Find user
    const user = await prisma.user.findUnique({
        where: { email },
    });

    if (!user) {
        throw new Error('Invalid credentials');
    }

    // Verify password
    const isPasswordValid = await comparePassword(password, user.password);

    if (!isPasswordValid) {
        throw new Error('Invalid credentials');
    }

    // Update last login timestamp
    await prisma.user.update({
        where: { id: user.id },
        data: { lastLoginAt: new Date() },
    });

    // Generate tokens
    const tokens = generateTokens({
        userId: user.id,
        email: user.email,
    });

    return {
        user: {
            id: user.id,
            email: user.email,
            name: user.name,
        },
        tokens,
    };
};/**
 * Refresh access token using refresh token
 */
export const refreshAccessToken = async (refreshToken: string): Promise<TokenPair> => {
    try {
        const decoded = verifyRefreshToken(refreshToken);

        // Verify user still exists
        const user = await prisma.user.findUnique({
            where: { id: decoded.userId },
        });

        if (!user) {
            throw new Error('User not found');
        }

        // Generate new token pair
        return generateTokens({
            userId: user.id,
            email: user.email,
        });
    } catch (error) {
        throw new Error('Invalid refresh token');
    }
};
