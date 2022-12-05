import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'package:example/models/trade_book_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trading_leagues_chart/entity/executed_trades_entity.dart';
import 'package:trading_leagues_chart/trading_leagues_chart.dart';
import 'package:trading_leagues_chart/generated/l10n.dart' as k_chart;
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // supportedLocales: [const Locale('zh', 'CN')],
      localizationsDelegates: const [
        k_chart.S.delegate //国际话
      ],
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<KLineEntity> datas = [];
  bool showLoading1 = true, showLoading2 = true;
  bool isLine = true;
  List<ExecutedTradesEntity> buySellPriceData = [
    // ExecutedTradesEntity.toExecutedTradesEntity(
    //   ltp: 17000.1,
    //   tradePrice: 17000.1,
    //   quantity: 1,
    //   oid: 21,
    // ),
  ];
  // Map<String, ExecutedTradesEntity> buySellPriceDataMap = {};
  List<int> buySellPriceIndex = [];
  List<TransactionType> buySellTransactionType = [];

  void getData(String period) async {
    late String result;
    try {
      result = await getIPAddress(period);
    } catch (e) {
      result = await rootBundle.loadString('assets/kline.json');
    } finally {
      Map parseJson = json.decode(result);
      List list = parseJson['data'];
      datas = list
          .map((item) => KLineEntity.fromJson(item))
          .toList()
          .reversed
          .toList()
          .cast<KLineEntity>();
      DataUtil.calculate(datas);
      showLoading1 = false;
      setState(() {});
    }
  }

  Future<String> getIPAddress(String? period) async {
    var url =
        'https://api.huobi.br.com/market/history/kline?period=${period ?? '1min'}&size=300&symbol=btcusdt';
    String result;
    var response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 7));
    if (response.statusCode == 200) {
      result = response.body;
    } else {
      return Future.error("获取失败");
    }
    return result;
  }

  void callTradeBookApi() async {
    try {
      TradeBookModel response = await getTradeBook(43881);
      for (TradeBookData element in response.data!) {
        if (element.closed == 0) {
          buySellPriceData.add(
            ExecutedTradesEntity.toExecutedTradesEntity(
              // ltp: 17050.5,
              tradePrice: 17050.5,
              quantity: 1,
              oid: element.oid as int,
            ),
          );
          if (element.transaction as int == 1) {
            buySellTransactionType.add(TransactionType.BOUGHT);
          } else {
            buySellTransactionType.add(TransactionType.SOLD);
          }
        }
      }
    } finally {
      showLoading2 = false;
      setState(() {});
    }
  }

  Future<TradeBookModel> getTradeBook(int leagueId) async {
    TradeBookModel data;
    String? jwt =
            "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOiJVR1I4UFJFS0FYIiwiaWF0IjoxNjcwMTYwNDM3LCJleHAiOjE2NzI3NTI0Mzd9.SQ-7qZowTpBAcYbMBslejNsqhkYSLJu1M-9n0iJ1oJs",
        uid = "UGR8PREKAX";
    try {
      var header = <String, String>{
        "Authorization": "Bearer $jwt",
        "Content-Type": "application/json"
      };
      var body = jsonEncode({"uid": uid, "leagueid": leagueId});

      var url =
          Uri.encodeFull("https://tl.raintech.ai/classicleague/getTradebook");
      final response =
          await http.post(Uri.parse(url), body: body, headers: header);

      if (response.statusCode == 200) {
        data = TradeBookModel.fromJson(json.decode(response.body.toString()));
        return data;
      } else {
        throw response.statusCode.toString();
      }
    } catch (error) {
      throw error.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    getData('1min');
    callTradeBookApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF171728),
      body: ListView(
        children: [
          Center(
            child: Stack(children: <Widget>[
              Container(
                height: 450,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: double.infinity,
                child: KChartWidget(
                  datas,
                  isLine: false,
                  mainState: MainState.NONE,
                  secondaryState: SecondaryState.NONE,
                  volState: VolState.NONE,
                  fractionDigits: 2,
                  buySellPriceData: buySellPriceData,
                  ltp: 0,
                  buySellTransactionType: buySellTransactionType,
                ),
              ),
              if (showLoading1 || showLoading2)
                Container(
                    width: double.infinity,
                    height: 450,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator()),
            ]),
          ),
          buildButtons(),
        ],
      ),
    );
  }

  Widget buildButtons() {
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 5,
      children: <Widget>[
        button("BUY", onPressed: () {
          setState(() {
            // buySellPriceData.add(KLineEntity.fromJson(datas.last.toJson()));
            // buySellPriceIndex.add(datas.length.toInt());
            // buySellTransactionType.add(TransactionType.BOUGHT);
          });
        }),
        button("SELL", onPressed: () {
          setState(() {
            // buySellPriceData.add(KLineEntity.fromJson(datas.last.toJson()));
            // buySellPriceIndex.add(datas.length.toInt());
            // buySellTransactionType.add(TransactionType.SOLD);
          });
        }),
        // button("kLine", onPressed: () => isLine = !isLine),
        // button("MA", onPressed: () => _mainState = MainState.MA),
        // button("BOLL", onPressed: () => _mainState = MainState.BOLL),
        // button("隐藏",
        //     onPressed: () => _mainState =
        //         _mainState == MainState.NONE ? MainState.MA : MainState.NONE),
        // button("MACD", onPressed: () => _secondaryState = SecondaryState.MACD),
        // button("KDJ", onPressed: () => _secondaryState = SecondaryState.KDJ),
        // button("RSI", onPressed: () => _secondaryState = SecondaryState.RSI),
        // button("WR", onPressed: () => _secondaryState = SecondaryState.WR),
        // button("隐藏副视图",
        //     onPressed: () => _secondaryState =
        //         _secondaryState == SecondaryState.NONE
        //             ? SecondaryState.MACD
        //             : SecondaryState.NONE),
        button("update", onPressed: () {
          datas.last.close += (Random().nextInt(100) - 50).toDouble();
          datas.last.high = max(datas.last.high, datas.last.close);
          datas.last.low = min(datas.last.low, datas.last.close);
          DataUtil.updateLastData(datas);
        }),
        button("addData", onPressed: () {
          var kLineEntity = KLineEntity.fromJson(datas.last.toJson());
          kLineEntity.id = kLineEntity.id! + 60 * 60 * 24;
          kLineEntity.open = kLineEntity.close;
          kLineEntity.close += (Random().nextInt(100) - 50).toDouble();
          datas.last.high = max(datas.last.high, datas.last.close);
          datas.last.low = min(datas.last.low, datas.last.close);
          DataUtil.addLastData(datas, kLineEntity);
        }),
        // button("1month", onPressed: () async {
        //   //getData('1mon');
        //   String result = await rootBundle.loadString('assets/kmon.json');
        //   Map parseJson = json.decode(result);
        //   List list = parseJson['data'];
        //   datas = list
        //       .map((item) => KLineEntity.fromJson(item))
        //       .toList()
        //       .reversed
        //       .toList()
        //       .cast<KLineEntity>();
        //   DataUtil.calculate(datas);
        // }),
        // TextButton(
        //     onPressed: () {
        //       showLoading = true;
        //       setState(() {});
        //       getData('1day');
        //     },
        //     style: TextButton.styleFrom(backgroundColor: Colors.blue),
        //     child: const Text("1day", style: TextStyle(color: Colors.black))),
      ],
    );
  }

  Widget button(String text, {VoidCallback? onPressed}) {
    return TextButton(
        onPressed: () {
          if (onPressed != null) {
            onPressed();
            setState(() {});
          }
        },
        style: TextButton.styleFrom(backgroundColor: Colors.blue),
        child: Text(text, style: const TextStyle(color: Colors.black)));
  }
}
