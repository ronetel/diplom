class ClothingCategory {
  final String id;
  final String name;
  final String type; 
  final String groupName;

  const ClothingCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.groupName,
  });
}

class ClothingCategories {
  static const List<ClothingCategory> all = [
    
    ClothingCategory(id: 'tshirt',      name: 'Футболка',          type: 'top', groupName: 'Верх'),
    ClothingCategory(id: 'polo',        name: 'Поло',              type: 'top', groupName: 'Верх'),
    ClothingCategory(id: 'tank',        name: 'Майка',             type: 'top', groupName: 'Верх'),
    ClothingCategory(id: 'shirt',       name: 'Рубашка',           type: 'top', groupName: 'Верх'),
    ClothingCategory(id: 'blouse',      name: 'Блузка',            type: 'top', groupName: 'Верх'),
    ClothingCategory(id: 'sweater',     name: 'Свитер',            type: 'top', groupName: 'Верх'),
    ClothingCategory(id: 'jumper',      name: 'Джемпер',           type: 'top', groupName: 'Верх'),
    ClothingCategory(id: 'pullover',    name: 'Пуловер',           type: 'top', groupName: 'Верх'),
    ClothingCategory(id: 'hoodie',      name: 'Худи',              type: 'top', groupName: 'Верх'),
    ClothingCategory(id: 'sweatshirt',  name: 'Толстовка',         type: 'top', groupName: 'Верх'),
    ClothingCategory(id: 'cardigan',    name: 'Кардиган',          type: 'top', groupName: 'Верх'),
    ClothingCategory(id: 'turtleneck',  name: 'Водолазка',         type: 'top', groupName: 'Верх'),
    ClothingCategory(id: 'top',         name: 'Топ',               type: 'top', groupName: 'Верх'),
    ClothingCategory(id: 'bodysuit',    name: 'Боди',              type: 'top', groupName: 'Верх'),
    ClothingCategory(id: 'longsleeve',  name: 'Лонгслив',          type: 'top', groupName: 'Верх'),
    ClothingCategory(id: 'crop_top',    name: 'Кроп-топ',          type: 'top', groupName: 'Верх'),
    ClothingCategory(id: 'vest_top',    name: 'Безрукавка',        type: 'top', groupName: 'Верх'),
    ClothingCategory(id: 'flannel',     name: 'Фланелевая рубашка',type: 'top', groupName: 'Верх'),

    
    ClothingCategory(id: 'jeans',       name: 'Джинсы',            type: 'bottom', groupName: 'Низ'),
    ClothingCategory(id: 'trousers',    name: 'Брюки',             type: 'bottom', groupName: 'Низ'),
    ClothingCategory(id: 'shorts',      name: 'Шорты',             type: 'bottom', groupName: 'Низ'),
    ClothingCategory(id: 'skirt',       name: 'Юбка',              type: 'bottom', groupName: 'Низ'),
    ClothingCategory(id: 'leggings',    name: 'Леггинсы',          type: 'bottom', groupName: 'Низ'),
    ClothingCategory(id: 'joggers',     name: 'Джоггеры',          type: 'bottom', groupName: 'Низ'),
    ClothingCategory(id: 'sweatpants',  name: 'Спортивные штаны',  type: 'bottom', groupName: 'Низ'),
    ClothingCategory(id: 'chinos',      name: 'Чинос',             type: 'bottom', groupName: 'Низ'),
    ClothingCategory(id: 'capri',       name: 'Капри',             type: 'bottom', groupName: 'Низ'),
    ClothingCategory(id: 'bermuda',     name: 'Бермуды',           type: 'bottom', groupName: 'Низ'),
    ClothingCategory(id: 'mini_skirt',  name: 'Мини-юбка',         type: 'bottom', groupName: 'Низ'),
    ClothingCategory(id: 'midi_skirt',  name: 'Миди-юбка',         type: 'bottom', groupName: 'Низ'),
    ClothingCategory(id: 'maxi_skirt',  name: 'Макси-юбка',        type: 'bottom', groupName: 'Низ'),
    ClothingCategory(id: 'denim_skirt', name: 'Джинсовая юбка',    type: 'bottom', groupName: 'Низ'),
    ClothingCategory(id: 'culottes',    name: 'Кюлоты',            type: 'bottom', groupName: 'Низ'),
    ClothingCategory(id: 'wide_pants',  name: 'Широкие брюки',     type: 'bottom', groupName: 'Низ'),

    
    ClothingCategory(id: 'jacket',      name: 'Куртка',            type: 'outerwear', groupName: 'Верхняя одежда'),
    ClothingCategory(id: 'coat',        name: 'Пальто',            type: 'outerwear', groupName: 'Верхняя одежда'),
    ClothingCategory(id: 'down_jacket', name: 'Пуховик',           type: 'outerwear', groupName: 'Верхняя одежда'),
    ClothingCategory(id: 'fur_coat',    name: 'Шуба',              type: 'outerwear', groupName: 'Верхняя одежда'),
    ClothingCategory(id: 'sheepskin',   name: 'Дублёнка',          type: 'outerwear', groupName: 'Верхняя одежда'),
    ClothingCategory(id: 'raincoat',    name: 'Плащ',              type: 'outerwear', groupName: 'Верхняя одежда'),
    ClothingCategory(id: 'windbreaker', name: 'Ветровка',          type: 'outerwear', groupName: 'Верхняя одежда'),
    ClothingCategory(id: 'anorak',      name: 'Анорак',            type: 'outerwear', groupName: 'Верхняя одежда'),
    ClothingCategory(id: 'bomber',      name: 'Бомбер',            type: 'outerwear', groupName: 'Верхняя одежда'),
    ClothingCategory(id: 'parka',       name: 'Парка',             type: 'outerwear', groupName: 'Верхняя одежда'),
    ClothingCategory(id: 'trench',      name: 'Тренч',             type: 'outerwear', groupName: 'Верхняя одежда'),
    ClothingCategory(id: 'vest',        name: 'Жилет',             type: 'outerwear', groupName: 'Верхняя одежда'),
    ClothingCategory(id: 'leather_jkt', name: 'Кожаная куртка',    type: 'outerwear', groupName: 'Верхняя одежда'),
    ClothingCategory(id: 'denim_jkt',   name: 'Джинсовая куртка',  type: 'outerwear', groupName: 'Верхняя одежда'),
    ClothingCategory(id: 'moto_jkt',    name: 'Косуха',            type: 'outerwear', groupName: 'Верхняя одежда'),
    ClothingCategory(id: 'blazer',      name: 'Блейзер',           type: 'outerwear', groupName: 'Верхняя одежда'),
    ClothingCategory(id: 'fleece',      name: 'Флиска',            type: 'outerwear', groupName: 'Верхняя одежда'),

    
    ClothingCategory(id: 'dress',       name: 'Платье',            type: 'full-body', groupName: 'Платья и комбинезоны'),
    ClothingCategory(id: 'sundress',    name: 'Сарафан',           type: 'full-body', groupName: 'Платья и комбинезоны'),
    ClothingCategory(id: 'jumpsuit',    name: 'Комбинезон',        type: 'full-body', groupName: 'Платья и комбинезоны'),
    ClothingCategory(id: 'romper',      name: 'Ромпер',            type: 'full-body', groupName: 'Платья и комбинезоны'),
    ClothingCategory(id: 'overalls',    name: 'Комбез-брюки',      type: 'full-body', groupName: 'Платья и комбинезоны'),

    
    ClothingCategory(id: 'sneakers',    name: 'Кроссовки',         type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'canvas',      name: 'Кеды',              type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'heels',       name: 'Туфли на каблуке',  type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'flats',       name: 'Туфли на плоской',  type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'boots',       name: 'Ботинки',           type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'high_boots',  name: 'Сапоги',            type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'uggs',        name: 'Угги',              type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'loafers',     name: 'Лоферы',            type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'moccasins',   name: 'Мокасины',          type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'ballerinas',  name: 'Балетки',           type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'sandals',     name: 'Сандалии',          type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'flipflops',   name: 'Шлёпанцы',          type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'open_shoes',  name: 'Босоножки',         type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'slip_ons',    name: 'Слипоны',           type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'ankle_boots', name: 'Ботильоны',         type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'clogs',       name: 'Сабо',              type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'platforms',   name: 'Платформа',         type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'derby',       name: 'Дерби',             type: 'shoes', groupName: 'Обувь'),
    ClothingCategory(id: 'oxfords',     name: 'Оксфорды',          type: 'shoes', groupName: 'Обувь'),

    
    ClothingCategory(id: 'belt',        name: 'Ремень',            type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'bag',         name: 'Сумка',             type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'backpack',    name: 'Рюкзак',            type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'clutch',      name: 'Клатч',             type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'hat',         name: 'Шапка',             type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'cap',         name: 'Бейсболка',         type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'beret',       name: 'Берет',             type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'fedora',      name: 'Федора',            type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'scarf',       name: 'Шарф',              type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'bandana',     name: 'Платок/Бандана',    type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'gloves',      name: 'Перчатки',          type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'sunglasses',  name: 'Очки',              type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'watch',       name: 'Часы',              type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'necklace',    name: 'Ожерелье/Цепочка',  type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'earrings',    name: 'Серьги',            type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'bracelet',    name: 'Браслет',           type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'ring',        name: 'Кольцо',            type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'tie',         name: 'Галстук',           type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'bowtie',      name: 'Бабочка',           type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'socks',       name: 'Носки',             type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'tights',      name: 'Колготки',          type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'swimsuit',    name: 'Купальник',         type: 'accessory', groupName: 'Аксессуары'),
    ClothingCategory(id: 'swim_trunks', name: 'Плавки',            type: 'accessory', groupName: 'Аксессуары'),
  ];

  
  static ClothingCategory? findById(String id) {
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  
  static ClothingCategory? findByName(String name) {
    try {
      return all.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  
  static String typeForCategory(String categoryId) {
    return findById(categoryId)?.type ?? 'top';
  }

  
  static List<ClothingCategory> search(String query) {
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  
  static List<String> get groups {
    final seen = <String>{};
    return all.map((c) => c.groupName).where(seen.add).toList();
  }

  
  static List<ClothingCategory> byGroup(String group) =>
      all.where((c) => c.groupName == group).toList();
}
