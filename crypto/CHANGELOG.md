# Changelog

All notable changes to the Crypto Auth API project.

## [1.0.0] - 2025-10-29

### Added
- Complete JWT-based authentication system
- User registration with email/password
- Secure login with bcrypt password hashing
- Access token and refresh token mechanism
- Protected route middleware
- Input validation for email and password
- Custom error handling with appropriate HTTP status codes
- PostgreSQL database with Prisma ORM
- User model with activity tracking (lastLoginAt)
- Comprehensive API documentation
- TypeScript configuration with strict mode
- Express.js server with security middleware (helmet, cors)
- Health check endpoint
- Environment variable configuration
- Database connection with logging

### Security
- Password hashing with bcrypt (10 salt rounds)
- JWT tokens with configurable expiration
- Email format validation
- Password strength requirements (minimum 6 characters)
- Protected endpoints with Bearer token authentication
- CORS and Helmet security headers

### Documentation
- Complete README with API endpoints
- cURL examples for all endpoints
- Setup and installation instructions
- Environment variable documentation
- Project structure overview
- Development and deployment guides
