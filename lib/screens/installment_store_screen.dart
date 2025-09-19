import 'package:flutter/material.dart';

import 'product_list_screen.dart';

class InstallmentStoreScreen extends StatelessWidget {
  const InstallmentStoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ProductListScreen(
      showInstallmentOnly: true,
      titleAr: 'متجر التقسيط',
      titleEn: 'Installment Store',
      searchHintAr: 'ابحث عن عروض التقسيط...',
      searchHintEn: 'Search for installment deals...',
      noResultsTextAr: 'لا توجد عروض تقسيط متاحة حالياً',
      noResultsTextEn: 'No installment offers available right now',
    );
  }
}
