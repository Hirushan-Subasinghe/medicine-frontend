# Production Deployment Checklist

## Backend (Node.js Server)

### Configuration
- [ ] Update `.env` file with production settings
- [ ] Configure environment variables in Oracle Cloud
- [ ] Set `NODE_ENV=production` in the environment
- [ ] Configure proper CORS settings for production
- [ ] Set up proper logging mechanisms
- [ ] Disable any development-only routes or debugging tools

### Security
- [ ] Ensure all API endpoints are properly authenticated
- [ ] Set up HTTPS with SSL/TLS certificate
- [ ] Configure proper firewall rules
- [ ] Remove any test accounts or credentials
- [ ] Ensure sensitive data is encrypted
- [ ] Set up appropriate rate limiting

### Database
- [ ] Verify database connection with production credentials
- [ ] Set up database backups
- [ ] Configure connection pooling appropriately
- [ ] Ensure indexes are properly set up for performance
- [ ] Verify Prisma ORM is using production configuration

### Performance
- [ ] Implement caching where appropriate
- [ ] Optimize database queries
- [ ] Enable compression for responses
- [ ] Configure proper timeout values
- [ ] Test with expected production load

## Mobile App (Flutter)

### Configuration
- [ ] Update constants_prod.dart with production API endpoint
- [ ] Ensure correct Firebase project is used in production
- [ ] Verify all API calls use the production URL
- [ ] Disable any debug features or logs
- [ ] Ensure app ID, version name and version code are correct

### Testing
- [ ] Test app on physical devices (both Android and iOS)
- [ ] Verify backend connectivity on mobile networks
- [ ] Test application functionality with production backend
- [ ] Verify push notifications are working in production
- [ ] Test authentication flow with production Firebase
- [ ] Test offline functionality

### Publishing
- [ ] Generate signed release APK/App Bundle for Android
- [ ] Prepare screenshots and descriptions for app stores
- [ ] Complete app store listing information
- [ ] Set up privacy policy and terms of service
- [ ] Configure app signing in Google Play Console / App Store Connect

## Connection Validation Steps

### Server-Side Validation
1. Run `Test-BackendConnection.ps1` script to verify server accessibility
2. Check server logs for any errors during startup
3. Verify database connection is successful
4. Ensure API endpoints return expected responses
5. Monitor server performance during usage

### Client-Side Validation
1. Use the Diagnostic Page in the app to verify connection
2. Check Firebase Authentication is working correctly
3. Test all main app functionality with the production backend
4. Verify data persistence and syncing works correctly
5. Test background processes and notifications

## Common Issues

### Connection Problems
- Incorrect API endpoint URL in constants_prod.dart
- Firewall blocking connections to server
- Missing or incorrectly configured CORS headers
- Network connectivity issues on mobile device
- SSL/TLS certificate issues

### Authentication Issues
- Firebase configuration mismatch between app and server
- Token validation failures
- Expired credentials or tokens
- Incorrect authentication flow

### Database Issues
- Connection string errors
- Permission problems with database user
- Schema mismatches
- Connection pool exhaustion
