import { Request, Response } from 'express';
import * as authService from '../services/auth.service';

/**
 * Handle user signup
 */
export const signup = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password, name } = req.body;

    // Validate input
    if (!email || !password) {
      res.status(400).json({
        success: false,
        message: 'Email and password are required',
      });
      return;
    }

    if (password.length < 6) {
      res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters',
      });
      return;
    }

    const result = await authService.signup({ email, password, name });

    res.status(201).json({
      success: true,
      data: result,
      message: 'User registered successfully',
    });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    
    if (errorMessage.includes('already exists')) {
      res.status(409).json({
        success: false,
        message: errorMessage,
      });
      return;
    }

    res.status(500).json({
      success: false,
      message: 'Internal server error',
    });
  }
};

/**
 * Handle user login
 */
export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      res.status(400).json({
        success: false,
        message: 'Email and password are required',
      });
      return;
    }

    const result = await authService.login({ email, password });

    res.status(200).json({
      success: true,
      data: result,
      message: 'Login successful',
    });
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    
    if (errorMessage.includes('Invalid credentials')) {
      res.status(401).json({
        success: false,
        message: 'Invalid email or password',
      });
      return;
    }

    res.status(500).json({
      success: false,
      message: 'Internal server error',
    });
  }
};

/**
 * Handle token refresh
 */
export const refreshToken = async (req: Request, res: Response): Promise<void> => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      res.status(400).json({
        success: false,
        message: 'Refresh token is required',
      });
      return;
    }

    const tokens = await authService.refreshAccessToken(refreshToken);

    res.status(200).json({
      success: true,
      data: { tokens },
      message: 'Token refreshed successfully',
    });
  } catch (error) {
    res.status(401).json({
      success: false,
      message: 'Invalid or expired refresh token',
    });
  }
};

/**
 * Handle user logout (client-side token removal)
 */
export const logout = async (req: Request, res: Response): Promise<void> => {
  res.status(200).json({
    success: true,
    message: 'Logout successful',
  });
};
