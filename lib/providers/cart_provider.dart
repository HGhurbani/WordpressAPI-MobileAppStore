import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  // هيكل المنتج في السلة: {product: Product, quantity: int}
  final List<_CartItem> _items = [];

  List<_CartItem> get items => _items;

  double get totalAmount {
    double total = 0;
    for (var item in _items) {
      total += (item.product.price * item.quantity);
    }
    return total;
  }

  void addToCart(Product product) {
    // تحقق إن كان المنتج موجودًا مسبقًا
    final index = _items.indexWhere((element) => element.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(_CartItem(product: product, quantity: 1));
    }
    notifyListeners();
  }

  // دالة لإرجاع كمية المنتج الموجودة في السلة
  int getQuantity(Product product) {
    final index = _items.indexWhere((element) => element.product.id == product.id);
    return index >= 0 ? _items[index].quantity : 0;
  }

  void removeFromCart(Product product) {
    _items.removeWhere((element) => element.product.id == product.id);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
  void decreaseQuantity(Product product) {
    final index = _items.indexWhere((element) => element.product.id == product.id);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }
  void increaseQuantity(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _items[index].quantity += 1;
      notifyListeners();
    }
  }
}


class _CartItem {
  final Product product;
  int quantity;

  _CartItem({required this.product, this.quantity = 1});
}
