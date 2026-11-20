import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'gocatering.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabel owners (penjual)
    await db.execute('''
      CREATE TABLE owners (
        key TEXT PRIMARY KEY,
        gelar TEXT,
        nama TEXT,
        nik TEXT,
        email TEXT,
        phone TEXT,
        photo TEXT,
        password TEXT,
        mustReset INTEGER DEFAULT 0,
        createdAt TEXT
      )
    ''');

    // Tabel shops (toko/restoran)
    await db.execute('''
      CREATE TABLE shops (
        id TEXT PRIMARY KEY,
        code TEXT,
        name TEXT,
        tagline TEXT,
        logo TEXT,
        rating REAL DEFAULT 0,
        sold INTEGER DEFAULT 0,
        ownerKey TEXT,
        addr TEXT,
        mapUrl TEXT,
        csWa TEXT,
        photo TEXT,
        builtin INTEGER DEFAULT 0,
        FOREIGN KEY (ownerKey) REFERENCES owners(key)
      )
    ''');

    // Tabel packages (paket menu)
    await db.execute('''
      CREATE TABLE packages (
        id TEXT PRIMARY KEY,
        shopId TEXT,
        name TEXT,
        price INTEGER,
        img TEXT,
        desc TEXT,
        FOREIGN KEY (shopId) REFERENCES shops(id)
      )
    ''');

    // Tabel orders (pesanan)
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        shopId TEXT,
        items TEXT,
        subtotal INTEGER,
        fee INTEGER,
        deliveryFee INTEGER DEFAULT 0,
        total INTEGER,
        method TEXT,
        payStatus TEXT,
        status TEXT,
        fulfillment TEXT,
        pickup TEXT,
        delivery TEXT,
        buyer TEXT,
        createdAt TEXT,
        FOREIGN KEY (shopId) REFERENCES shops(id)
      )
    ''');

    // Tabel customers (pelanggan per toko)
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shopId TEXT,
        name TEXT,
        phone TEXT,
        orderCount INTEGER DEFAULT 1,
        firstOrder TEXT,
        lastOrder TEXT,
        FOREIGN KEY (shopId) REFERENCES shops(id)
      )
    ''');

    // Tabel menu_off (paket yang di-off-kan penjual)
    await db.execute('''
      CREATE TABLE menu_off (
        packageId TEXT PRIMARY KEY,
        shopId TEXT,
        FOREIGN KEY (packageId) REFERENCES packages(id),
        FOREIGN KEY (shopId) REFERENCES shops(id)
      )
    ''');

    // Tabel user_session (sesi login)
    await db.execute('''
      CREATE TABLE user_session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        email TEXT,
        name TEXT,
        role TEXT,
        ownerKey TEXT,
        phone TEXT,
        sellerShop TEXT
      )
    ''');
  }

  // ============ OWNER OPERATIONS ============
  
  Future<int> insertOwner(Map<String, dynamic> owner) async {
    Database db = await database;
    return await db.insert('owners', owner);
  }

  Future<List<Map<String, dynamic>>> getOwners() async {
    Database db = await database;
    return await db.query('owners');
  }

  Future<Map<String, dynamic>?> getOwnerByKey(String key) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'owners',
      where: 'key = ?',
      whereArgs: [key],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getOwnerByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'owners',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getOwnerByNik(String nik) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'owners',
      where: 'nik = ?',
      whereArgs: [nik],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateOwner(Map<String, dynamic> owner) async {
    Database db = await database;
    return await db.update(
      'owners',
      owner,
      where: 'key = ?',
      whereArgs: [owner['key']],
    );
  }

  // ============ SHOP OPERATIONS ============
  
  Future<int> insertShop(Map<String, dynamic> shop) async {
    Database db = await database;
    return await db.insert('shops', shop);
  }

  Future<List<Map<String, dynamic>>> getShops() async {
    Database db = await database;
    return await db.query('shops');
  }

  Future<List<Map<String, dynamic>>> getShopsByOwner(String ownerKey) async {
    Database db = await database;
    return await db.query(
      'shops',
      where: 'ownerKey = ?',
      whereArgs: [ownerKey],
    );
  }

  Future<Map<String, dynamic>?> getShopById(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'shops',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> updateShop(Map<String, dynamic> shop) async {
    Database db = await database;
    return await db.update(
      'shops',
      shop,
      where: 'id = ?',
      whereArgs: [shop['id']],
    );
  }

  // ============ PACKAGE OPERATIONS ============
  
  Future<int> insertPackage(Map<String, dynamic> package) async {
    Database db = await database;
    return await db.insert('packages', package);
  }

  Future<List<Map<String, dynamic>>> getPackagesByShop(String shopId) async {
    Database db = await database;
    return await db.query(
      'packages',
      where: 'shopId = ?',
      whereArgs: [shopId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllPackages() async {
    Database db = await database;
    return await db.query('packages');
  }

  // ============ ORDER OPERATIONS ============
  
  Future<int> insertOrder(Map<String, dynamic> order) async {
    Database db = await database;
    return await db.insert('orders', order);
  }

  Future<List<Map<String, dynamic>>> getOrdersByShop(String shopId) async {
    Database db = await database;
    return await db.query(
      'orders',
      where: 'shopId = ?',
      whereArgs: [shopId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getOrdersByStatus(String shopId, String status) async {
    Database db = await database;
    return await db.query(
      'orders',
      where: 'shopId = ? AND status = ?',
      whereArgs: [shopId, status],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> updateOrder(Map<String, dynamic> order) async {
    Database db = await database;
    return await db.update(
      'orders',
      order,
      where: 'id = ?',
      whereArgs: [order['id']],
    );
  }

  // ============ CUSTOMER OPERATIONS ============
  
  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    Database db = await database;
    return await db.insert('customers', customer);
  }

  Future<List<Map<String, dynamic>>> getCustomersByShop(String shopId) async {
    Database db = await database;
    return await db.query(
      'customers',
      where: 'shopId = ?',
      whereArgs: [shopId],
      orderBy: 'orderCount DESC',
    );
  }

  Future<int> updateCustomerOrderCount(String shopId, String phone, String name) async {
    Database db = await database;
    String now = DateTime.now().toIso8601String();
    
    List<Map<String, dynamic>> existing = await db.query(
      'customers',
      where: 'shopId = ? AND phone = ?',
      whereArgs: [shopId, phone],
    );
    
    if (existing.isNotEmpty) {
      return await db.rawUpdate(
        'UPDATE customers SET orderCount = orderCount + 1, lastOrder = ?, name = ? WHERE shopId = ? AND phone = ?',
        [now, name, shopId, phone],
      );
    } else {
      return await db.insert('customers', {
        'shopId': shopId,
        'name': name,
        'phone': phone,
        'orderCount': 1,
        'firstOrder': now,
        'lastOrder': now,
      });
    }
  }

  // ============ MENU OFF OPERATIONS ============
  
  Future<int> toggleMenuOff(String packageId, String shopId, bool isOff) async {
    Database db = await database;
    if (isOff) {
      return await db.insert('menu_off', {'packageId': packageId, 'shopId': shopId});
    } else {
      return await db.delete(
        'menu_off',
        where: 'packageId = ? AND shopId = ?',
        whereArgs: [packageId, shopId],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getMenuOffByShop(String shopId) async {
    Database db = await database;
    return await db.query(
      'menu_off',
      where: 'shopId = ?',
      whereArgs: [shopId],
    );
  }

  // ============ USER SESSION OPERATIONS ============
  
  Future<int> saveSession(Map<String, dynamic> session) async {
    Database db = await database;
    return await db.insert(
      'user_session',
      session,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getSession() async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query('user_session');
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> clearSession() async {
    Database db = await database;
    return await db.delete('user_session');
  }

  // ============ UTILITY ============
  
  Future<void> clearAllData() async {
    Database db = await database;
    await db.delete('user_session');
    await db.delete('menu_off');
    await db.delete('customers');
    await db.delete('orders');
    await db.delete('packages');
    await db.delete('shops');
    await db.delete('owners');
  }
}
