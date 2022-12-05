class ExecutedTradesEntity {
  // num ltp;
  num tradePrice;
  num quantity;
  int oid;

  ExecutedTradesEntity({
    // required this.ltp,
    required this.tradePrice,
    required this.quantity,
    required this.oid,
  });

  factory ExecutedTradesEntity.toExecutedTradesEntity({
    // required num ltp,
    required num tradePrice,
    required num quantity,
    required int oid,
  }) {
    return ExecutedTradesEntity(
      // ltp: ltp,
      tradePrice: tradePrice,
      quantity: quantity,
      oid: oid,
    );
  }
}
