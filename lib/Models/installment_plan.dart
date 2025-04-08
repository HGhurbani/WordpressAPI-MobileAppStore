
class InstallmentPlan {
  final double downPayment;
  final double totalPrice;
  final List<double> monthlyPayments;
  final bool isCustom;

  InstallmentPlan({
    required this.downPayment,
    required this.totalPrice,
    required this.monthlyPayments,
    this.isCustom = false,
  });

  factory InstallmentPlan.calculateCustomPlan(double productPrice, double downPayment) {
    double totalPrice = productPrice * 5;
    double remainingAmount = totalPrice - downPayment;
    double monthlyPayment = (remainingAmount / 4).roundToDouble();
    
    return InstallmentPlan(
      downPayment: downPayment.roundToDouble(),
      totalPrice: totalPrice.roundToDouble(),
      monthlyPayments: List.generate(4, (_) => monthlyPayment),
      isCustom: true,
    );
  }
}
