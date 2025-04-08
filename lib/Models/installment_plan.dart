
class InstallmentPlan {
  final double downPayment;
  final double totalPrice;
  final List<double> monthlyPayments;
  final bool isCustom;
  final String type;
  final double remainingAmount;
  final double monthlyPayment;

  InstallmentPlan({
    required this.downPayment,
    required this.totalPrice,
    required this.monthlyPayments,
    required this.type,
    this.isCustom = false,
    required this.remainingAmount,
    required this.monthlyPayment,
  });

  factory InstallmentPlan.calculateCustomPlan(double productPrice, double downPayment) {
    double totalPrice = productPrice * 5;
    double remainingAmount = totalPrice - downPayment;
    double monthlyPayment = (remainingAmount / 4).roundToDouble();
    
    return InstallmentPlan(
      type: 'custom',
      downPayment: downPayment.roundToDouble(),
      totalPrice: totalPrice.roundToDouble(),
      monthlyPayments: List.generate(4, (_) => monthlyPayment),
      remainingAmount: remainingAmount.roundToDouble(),
      monthlyPayment: monthlyPayment,
      isCustom: true,
    );
  }
}
