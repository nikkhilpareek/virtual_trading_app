/**
 * Email validation regex
 */
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * Validate email format
 */
export const isValidEmail = (email: string): boolean => {
    return EMAIL_REGEX.test(email);
};

/**
 * Validate password strength
 * - At least 6 characters
 */
export const isValidPassword = (password: string): boolean => {
    return password.length >= 6;
};

/**
 * Sanitize user input
 */
export const sanitizeInput = (input: string): string => {
    return input.trim();
};
