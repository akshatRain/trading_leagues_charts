import 'package:flutter/material.dart' show Color;

class ChartColors {
  ChartColors._();

  // static const Color bgColor = Color(0xff0D141E);
  static const Color bgColor = Color(0x00000000);
  static const Color kLineColor = Color(0xff4C86CD);
  // static const Color gridColor = Color(0xff4c5c74);
  static const Color gridColor = Color(0xff9EA0AA);
  static const List<Color> kLineShadowColor = [
    Color(0x554C86CD),
    Color(0x00000000)
  ];
  static const Color ma5Color = Color(0xffC9B885);
  static const Color ma10Color = Color(0xff6CB0A6);
  static const Color ma30Color = Color(0xff9979C6);
  static const Color upColor = Color(0xff00DF8D);
  static const Color dnColor = Color(0xffFF3030);
  static const Color volColor = Color(0xff4729AE);

  static const Color macdColor = Color(0xff4729AE);
  static const Color difColor = Color(0xffC9B885);
  static const Color deaColor = Color(0xff6CB0A6);

  static const Color kColor = Color(0xffC9B885);
  static const Color dColor = Color(0xff6CB0A6);
  static const Color jColor = Color(0xff9979C6);
  static const Color rsiColor = Color(0xffC9B885);

  static const Color yAxisTextColor = Color(0xff60738E);
  static const Color xAxisTextColor = Color(0xff60738E);

  static const Color maxMinTextColor = Color(0xffffffff);

  static const Color depthBuyColor = Color(0xff60A893);
  static const Color depthSellColor = Color(0xffC15866);

  static const Color markerBorderColor = Color(0xff6C7A86);

  static const Color markerBgColor = Color(0xff0D1722);

  static const Color realTimeBgColor = Color(0xffFFC0D5);
  static const Color rightRealTimeTextColor = Color(0xff171728);
  static const Color realTimeTextBorderColor = Color(0xffFFC0D5);
  static const Color realTimeTextColor = Color(0xff171728);

  static const Color realTimeLineColor = Color(0xffFFC0D5);
  static const Color realTimeLongLineColor = Color(0xffFFC0D5);

  static const Color simpleLineUpColor = Color(0xff6CB0A6);
  static const Color simpleLineDnColor = Color(0xffC15466);
}

class ChartStyle {
  ChartStyle._();

  static const double pointWidth = 11.0;

  static const double candleWidth = 8.5;

  static const double candleLineWidth = 1.5;

  static const double volWidth = 8.5;

  static const double macdWidth = 3.0;

  static const double vCrossWidth = 8.5;

  static const double hCrossWidth = 0.5;

  // static const int gridRows = 3,
  static const int gridRowSpace = 50;
  static const int gridColumns = 4;

  static const double topPadding = 30.0,
      bottomDateHigh = 20.0,
      childPadding = 25.0;

  static const double defaultTextSize = 10.0;
}
