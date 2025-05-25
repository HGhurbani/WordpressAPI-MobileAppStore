import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../Models/installment_plan.dart';

class CartProvider extends ChangeNotifier {
  final List<_CartItem> _items = [];

  List<_CartItem> get items => _items;

  double get totalAmount {
    double total = 0.0;
    for (var item in _items) {
      final isCustom = item.installmentPlan?.type == 'custom';
      final unitPrice = isCustom
          ? item.installmentPlan!.downPayment
          : item.product.price;

      total += unitPrice * item.quantity;
    }
    return total;
  }


  void addToCart(Product product, {InstallmentPlan? plan}) {
    final index = _items.indexWhere((element) => element.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(
        _CartItem(product: product, quantity: 1, installmentPlan: plan),
      );
    }
    notifyListeners();
  }


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
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id.toString() == productId);
    notifyListeners();
  }


}



class _CartItem {
  final Product product;
  int quantity;
  InstallmentPlan? installmentPlan;

  _CartItem({
    required this.product, 
    this.quantity = 1,
    this.installmentPlan,
  });
}
