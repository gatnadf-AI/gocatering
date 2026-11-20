class Owner {
  final String key;
  final String gelar;
  final String nama;
  final String nik;
  final String email;
  final String phone;
  final String? photo;
  final String password;
  final bool mustReset;
  final String createdAt;
  final List<String> shops;

  Owner({
    required this.key,
    required this.gelar,
    required this.nama,
    required this.nik,
    required this.email,
    required this.phone,
    this.photo,
    required this.password,
    this.mustReset = false,
    required this.createdAt,
    this.shops = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'gelar': gelar,
      'nama': nama,
      'nik': nik,
      'email': email,
      'phone': phone,
      'photo': photo,
      'password': password,
      'mustReset': mustReset ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory Owner.fromMap(Map<String, dynamic> map) {
    return Owner(
      key: map['key'],
      gelar: map['gelar'],
      nama: map['nama'],
      nik: map['nik'],
      email: map['email'],
      phone: map['phone'],
      photo: map['photo'],
      password: map['password'],
      mustReset: map['mustReset'] == 1,
      createdAt: map['createdAt'],
    );
  }
}

class Shop {
  final String id;
  final String code;
  final String name;
  final String? tagline;
  final String? logo;
  final double rating;
  final int sold;
  final String ownerKey;
  final String? addr;
  final String? mapUrl;
  final String? csWa;
  final String? photo;
  final bool builtin;

  Shop({
    required this.id,
    required this.code,
    required this.name,
    this.tagline,
    this.logo,
    this.rating = 0,
    this.sold = 0,
    required this.ownerKey,
    this.addr,
    this.mapUrl,
    this.csWa,
    this.photo,
    this.builtin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'tagline': tagline,
      'logo': logo,
      'rating': rating,
      'sold': sold,
      'ownerKey': ownerKey,
      'addr': addr,
      'mapUrl': mapUrl,
      'csWa': csWa,
      'photo': photo,
      'builtin': builtin ? 1 : 0,
    };
  }

  factory Shop.fromMap(Map<String, dynamic> map) {
    return Shop(
      id: map['id'],
      code: map['code'],
      name: map['name'],
      tagline: map['tagline'],
      logo: map['logo'],
      rating: map['rating'] ?? 0,
      sold: map['sold'] ?? 0,
      ownerKey: map['ownerKey'],
      addr: map['addr'],
      mapUrl: map['mapUrl'],
      csWa: map['csWa'],
      photo: map['photo'],
      builtin: map['builtin'] == 1,
    );
  }
}

class Package {
  final String id;
  final String shopId;
  final String name;
  final int price;
  final String? img;
  final String? desc;

  Package({
    required this.id,
    required this.shopId,
    required this.name,
    required this.price,
    this.img,
    this.desc,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopId': shopId,
      'name': name,
      'price': price,
      'img': img,
      'descr': desc,
    };
  }

  factory Package.fromMap(Map<String, dynamic> map) {
    return Package(
      id: map['id'],
      shopId: map['shopId'],
      name: map['name'],
      price: map['price'],
      img: map['img'],
      desc: map['descr'],
    );
  }
}

class Order {
  final String id;
  final String shopId;
  final String items; // JSON string
  final int subtotal;
  final int fee;
  final int deliveryFee;
  final int total;
  final String method;
  final String payStatus;
  final String status;
  final String fulfillment;
  final String? pickup; // JSON string
  final String? delivery; // JSON string
  final String buyer; // JSON string
  final String createdAt;

  Order({
    required this.id,
    required this.shopId,
    required this.items,
    required this.subtotal,
    required this.fee,
    this.deliveryFee = 0,
    required this.total,
    required this.method,
    required this.payStatus,
    required this.status,
    required this.fulfillment,
    this.pickup,
    this.delivery,
    required this.buyer,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopId': shopId,
      'items': items,
      'subtotal': subtotal,
      'fee': fee,
      'deliveryFee': deliveryFee,
      'total': total,
      'method': method,
      'payStatus': payStatus,
      'status': status,
      'fulfillment': fulfillment,
      'pickup': pickup,
      'delivery': delivery,
      'buyer': buyer,
      'createdAt': createdAt,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      shopId: map['shopId'],
      items: map['items'],
      subtotal: map['subtotal'],
      fee: map['fee'],
      deliveryFee: map['deliveryFee'] ?? 0,
      total: map['total'],
      method: map['method'],
      payStatus: map['payStatus'],
      status: map['status'],
      fulfillment: map['fulfillment'],
      pickup: map['pickup'],
      delivery: map['delivery'],
      buyer: map['buyer'],
      createdAt: map['createdAt'],
    );
  }
}

class Customer {
  final int? id;
  final String shopId;
  final String name;
  final String phone;
  final int orderCount;
  final String firstOrder;
  final String lastOrder;

  Customer({
    this.id,
    required this.shopId,
    required this.name,
    required this.phone,
    this.orderCount = 1,
    required this.firstOrder,
    required this.lastOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopId': shopId,
      'name': name,
      'phone': phone,
      'orderCount': orderCount,
      'firstOrder': firstOrder,
      'lastOrder': lastOrder,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      shopId: map['shopId'],
      name: map['name'],
      phone: map['phone'],
      orderCount: map['orderCount'] ?? 1,
      firstOrder: map['firstOrder'],
      lastOrder: map['lastOrder'],
    );
  }
}

class UserSession {
  final String? email;
  final String? name;
  final String? role;
  final String? ownerKey;
  final String? phone;
  final String? sellerShop;

  UserSession({
    this.email,
    this.name,
    this.role,
    this.ownerKey,
    this.phone,
    this.sellerShop,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': 1,
      'email': email,
      'name': name,
      'role': role,
      'ownerKey': ownerKey,
      'phone': phone,
      'sellerShop': sellerShop,
    };
  }

  factory UserSession.fromMap(Map<String, dynamic> map) {
    return UserSession(
      email: map['email'],
      name: map['name'],
      role: map['role'],
      ownerKey: map['ownerKey'],
      phone: map['phone'],
      sellerShop: map['sellerShop'],
    );
  }
}
