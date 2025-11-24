# Flutter App HTTPS Update

## Changes Made

Updated the Flutter app to use HTTPS with the production domain `homescrapy.xyz`.

### File Modified

**`cinema_scraper/app/lib/services/api_service.dart`**

### Changes

**Before:**
```dart
class ApiService {
  static const String _remoteHost = '93.55.231.209';
  
  String get baseUrl {
    return 'http://$_remoteHost:80';
  }
}
```

**After:**
```dart
class ApiService {
  // Production domain with HTTPS
  static const String _productionDomain = 'homescrapy.xyz';
  
  // For local development, uncomment one of these:
  // static const String _localHost = '10.0.2.2:8000'; // Android Emulator
  // static const String _localHost = '192.168.1.x:8000'; // Physical device
  
  String get baseUrl {
    // Production: HTTPS with domain
    return 'https://$_productionDomain';
    
    // For local development, uncomment this instead:
    // return 'http://$_localHost';
  }
}
```

## Benefits

1. ✅ **Secure Communication** - All API requests now use HTTPS encryption
2. ✅ **Domain-based** - Uses `homescrapy.xyz` instead of IP address
3. ✅ **Easy Switching** - Simple comments to switch between production and development
4. ✅ **No Port Needed** - HTTPS uses standard port 443 (implicit)

## Testing the App

After this change, rebuild and run the Flutter app:

```bash
cd /home/ale/Documenti/Agents/cinema_scraper/app

# Clean build
flutter clean
flutter pub get

# Run on your device
flutter run
```

The app will now connect to:
- **Production API**: `https://homescrapy.xyz/movies`
- **Swagger Docs**: `https://homescrapy.xyz/docs`

## Local Development

To switch back to local development, edit `lib/services/api_service.dart`:

```dart
String get baseUrl {
  // Comment out production
  // return 'https://$_productionDomain';
  
  // Uncomment for local development
  return 'http://10.0.2.2:8000'; // For Android Emulator
  // OR
  // return 'http://192.168.1.x:8000'; // For physical device
}
```

## Verification

Test the app to ensure:
1. ✅ Movies load from HTTPS endpoint
2. ✅ Movie details load correctly
3. ✅ No SSL certificate errors
4. ✅ All features work as expected

## Network Security

The app now benefits from:
- **Encrypted traffic** - All data encrypted in transit
- **Certificate validation** - Flutter validates SSL certificate
- **Man-in-the-middle protection** - HTTPS prevents MITM attacks
- **Data integrity** - Ensures data isn't tampered with

## Troubleshooting

### SSL Certificate Errors

If you see SSL certificate errors, ensure:
1. Backend SSL is properly configured
2. Domain DNS is correct
3. Certificate is valid (not expired)

### Connection Refused

If connection fails:
1. Check backend is running: `https://homescrapy.xyz/`
2. Verify firewall allows HTTPS (port 443)
3. Check app has internet permission (should already be configured)

### Testing with curl

Test the API endpoint:
```bash
# Test from command line
curl https://homescrapy.xyz/movies

# Should return JSON with movie data
```

## Next Steps

1. **Rebuild the app** with the new configuration
2. **Test thoroughly** on both emulator and physical device
3. **Deploy to app stores** if ready for production
4. **Monitor** API usage and performance

---

**Status**: ✅ App updated to use HTTPS with homescrapy.xyz
**Security**: ✅ All traffic now encrypted
**Ready for**: Production deployment
