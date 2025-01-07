import 'package:shared_preferences/shared_preferences.dart';

class ProfileManager {
  static const String _nameKey = 'user_name';
  static const String _lastNameKey = 'user_last_name';
  static const String _emailKey = 'user_email';
  static const String _phoneKey = 'user_phone';

  // Haalt het profiel op uit SharedPreferences
  static Future<Map<String, String>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    String name = prefs.getString(_nameKey) ?? '';
    String lastName = prefs.getString(_lastNameKey) ?? '';
    String email = prefs.getString(_emailKey) ?? '';
    String phone = prefs.getString(_phoneKey) ?? '';

    // Debugging: print de geladen gegevens om te controleren of ze correct worden geladen
    print('Profiel geladen: $name, $lastName, $email, $phone');

    return {
      'name': name,
      'lastName': lastName,
      'email': email,
      'phone': phone,
    };
  }

  // Slaat het profiel op in SharedPreferences
  static Future<void> saveProfile(String name, String lastName, String email, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_lastNameKey, lastName);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_phoneKey, phone);

    // Debugging: print de opgeslagen gegevens om te controleren of ze correct worden opgeslagen
    print('Profiel opgeslagen: $name, $lastName, $email, $phone');

    // Direct controleren of de gegevens zijn opgeslagen
    print('Saved Name: ${prefs.getString(_nameKey)}');
    print('Saved LastName: ${prefs.getString(_lastNameKey)}');
    print('Saved Email: ${prefs.getString(_emailKey)}');
    print('Saved Phone: ${prefs.getString(_phoneKey)}');
  }
}
