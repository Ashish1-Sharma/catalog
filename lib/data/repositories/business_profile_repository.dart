import '../database/app_database.dart';

class BusinessProfileRepository {
  final AppDatabase _db;

  BusinessProfileRepository(this._db);

  Future<BusinessProfile?> getProfile() => _db.getBusinessProfile();

  Future<int> saveProfile(BusinessProfilesCompanion companion) => _db.saveBusinessProfile(companion);
}
