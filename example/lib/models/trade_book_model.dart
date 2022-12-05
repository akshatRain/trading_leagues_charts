class TradeBookModel {
  String? status;
  List<TradeBookData>? data;
  String? msg;

  TradeBookModel({this.status, this.data, this.msg});

  TradeBookModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['data'] != null) {
      data = <TradeBookData>[];
      json['data'].forEach((v) {
        // print(v.toString());
        data!.add(TradeBookData.fromJson(v));
      });
    }
    msg = json['msg'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['msg'] = this.msg;
    return data;
  }
}

class TradeBookData {
  dynamic oid;
  String? leagueid;
  String? uid;
  dynamic quantity;
  dynamic transaction;
  String? exchange;
  String? symbol;
  String? entrytime;
  String? exittime;
  dynamic entryprice;
  dynamic exitprice;
  dynamic pnl;
  dynamic closed;

  TradeBookData(
      {this.oid,
      this.leagueid,
      this.uid,
      this.quantity,
      this.transaction,
      this.exchange,
      this.symbol,
      this.entrytime,
      this.exittime,
      this.entryprice,
      this.exitprice,
      this.pnl,
      this.closed});

  TradeBookData.fromJson(Map<String, dynamic> json) {
    oid = json['oid'];
    leagueid = json['leagueid'];
    uid = json['uid'];
    quantity = json['quantity'];
    transaction = json['transaction'];
    exchange = json['exchange'];
    symbol = json['symbol'];
    entrytime = json['entrytime'];
    exittime = json['exittime'];
    entryprice = json['entryprice'];
    exitprice = json['exitprice'];
    pnl = json['pnl'];
    closed = json['closed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['oid'] = this.oid;
    data['leagueid'] = this.leagueid;
    data['uid'] = this.uid;
    data['quantity'] = this.quantity;
    data['transaction'] = this.transaction;
    data['exchange'] = this.exchange;
    data['symbol'] = this.symbol;
    data['entrytime'] = this.entrytime;
    data['exittime'] = this.exittime;
    data['entryprice'] = this.entryprice;
    data['exitprice'] = this.exitprice;
    data['pnl'] = this.pnl;
    data['closed'] = this.closed;
    return data;
  }
}
