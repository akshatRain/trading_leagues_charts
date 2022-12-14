import 'dart:async' show StreamSink;

import 'package:flutter/material.dart';
import 'package:trading_leagues_chart/entity/executed_trades_entity.dart';
import 'package:trading_leagues_chart/tl_chart_widget.dart';

import '../entity/info_window_entity.dart';
import '../entity/k_line_entity.dart';
import '../utils/date_format_util.dart';
import 'base_chart_painter.dart';
import 'base_chart_renderer.dart';
import 'main_renderer.dart';
import 'secondary_renderer.dart';
import 'vol_renderer.dart';

class ChartPainter extends BaseChartPainter {
  static get maxScrollX => BaseChartPainter.maxScrollX;
  late BaseChartRenderer mMainRenderer;
  BaseChartRenderer? mVolRenderer, mSecondaryRenderer;
  StreamSink<InfoWindowEntity?>? sink;
  AnimationController? controller;
  double opacity;

  ChartPainter({
    required datas,
    required scaleX,
    required scrollX,
    required isLongPass,
    required selectX,
    mainState,
    volState,
    secondaryState,
    this.sink,
    bool isLine = false,
    this.controller,
    this.opacity = 0.0,
    buySellPriceData,
    buySellTransactionType,
    ltp,
  }) : super(
            datas: datas,
            scaleX: scaleX,
            scrollX: scrollX,
            isLongPress: isLongPass,
            selectX: selectX,
            mainState: mainState,
            volState: volState,
            secondaryState: secondaryState,
            isLine: isLine,
            buySellPriceData: buySellPriceData,
            buySellTransactionType: buySellTransactionType,
            ltp: ltp);

  @override
  void initChartRenderer() {
    mMainRenderer = MainRenderer(
      mMainRect,
      mMainMaxValue,
      mMainMinValue,
      ChartStyle.topPadding,
      mainState,
      isLine,
      scaleX,
    );
    if (mVolRect != null) {
      mVolRenderer ??= VolRenderer(mVolRect!, mVolMaxValue, mVolMinValue,
          ChartStyle.childPadding, scaleX);
    }
    if (mSecondaryRect != null) {
      mSecondaryRenderer ??= SecondaryRenderer(
          mSecondaryRect!,
          mSecondaryMaxValue,
          mSecondaryMinValue,
          ChartStyle.childPadding,
          secondaryState,
          scaleX);
    }
  }

  final Paint mBgPaint = Paint()..color = ChartColors.bgColor;

  @override
  void drawBg(Canvas canvas, Size size) {
    Rect mainRect = Rect.fromLTRB(
        0, 0, mMainRect.width, mMainRect.height + ChartStyle.topPadding);
    canvas.drawRect(mainRect, mBgPaint);

    if (mVolRect != null) {
      Rect volRect = Rect.fromLTRB(0, mVolRect!.top - ChartStyle.childPadding,
          mVolRect!.width, mVolRect!.bottom);
      canvas.drawRect(volRect, mBgPaint);
    }

    if (mSecondaryRect != null) {
      Rect secondaryRect = Rect.fromLTRB(
          0,
          mSecondaryRect!.top - ChartStyle.childPadding,
          mSecondaryRect!.width,
          mSecondaryRect!.bottom);
      canvas.drawRect(secondaryRect, mBgPaint);
    }
    Rect dateRect = Rect.fromLTRB(
        0, size.height - ChartStyle.bottomDateHigh, size.width, size.height);
    canvas.drawRect(dateRect, mBgPaint);
  }

  @override
  void drawGrid(canvas) {
    mMainRenderer.drawGrid(
        canvas, ChartStyle.gridRowSpace, ChartStyle.gridColumns);
    mVolRenderer?.drawGrid(
        canvas, ChartStyle.gridRowSpace, ChartStyle.gridColumns);
    mSecondaryRenderer?.drawGrid(
        canvas, ChartStyle.gridRowSpace, ChartStyle.gridColumns);
  }

  @override
  void drawChart(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(mTranslateX * scaleX, 0.0);
    canvas.scale(scaleX, 1.0);
    for (int i = mStartIndex; i <= mStopIndex; i++) {
      KLineEntity curPoint = datas[i];
      KLineEntity lastPoint = i == 0 ? curPoint : datas[i - 1];
      double curX = getX(i);
      double lastX = i == 0 ? curX : getX(i - 1);

      mMainRenderer.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      mVolRenderer?.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      mSecondaryRenderer?.drawChart(
          lastPoint, curPoint, lastX, curX, size, canvas);
    }

    if (isLongPress == true) drawCrossLine(canvas, size);
    canvas.restore();
  }

  @override
  void drawRightText(canvas) {
    var textStyle = getTextStyle(ChartColors.yAxisTextColor);
    mMainRenderer.drawRightText(canvas, textStyle, ChartStyle.gridRowSpace);
    mVolRenderer?.drawRightText(canvas, textStyle, ChartStyle.gridRowSpace);
    mSecondaryRenderer?.drawRightText(
        canvas, textStyle, ChartStyle.gridRowSpace);
  }

  @override
  void drawDate(Canvas canvas, Size size) {
    double columnSpace = size.width / ChartStyle.gridColumns;
    double startX = getX(mStartIndex) - mPointWidth / 2;
    double stopX = getX(mStopIndex) + mPointWidth / 2;
    double y = 0.0;
    for (var i = 0; i <= ChartStyle.gridColumns; ++i) {
      double translateX = xToTranslateX(columnSpace * i);
      if (translateX >= startX && translateX <= stopX) {
        int index = indexOfTranslateX(translateX);
        TextPainter tp = getTextPainter(getDate(datas[index].id!),
            color: ChartColors.xAxisTextColor);
        y = size.height -
            (ChartStyle.bottomDateHigh - tp.height) / 2 -
            tp.height;
        tp.paint(canvas, Offset(columnSpace * i - tp.width / 2, y));
      }
    }
  }

  Paint selectPointPaint = Paint()
    ..isAntiAlias = true
    ..strokeWidth = 0.5
    ..color = ChartColors.markerBgColor;
  Paint selectorBorderPaint = Paint()
    ..isAntiAlias = true
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke
    ..color = ChartColors.markerBorderColor;

  @override
  void drawCrossLineText(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);

    TextPainter tp = getTextPainter(format(point.close), color: Colors.white);
    double textHeight = tp.height;
    double textWidth = tp.width;

    double w1 = 5;
    double w2 = 3;
    double r = textHeight / 2 + w2;
    double y = getMainY(point.close);
    double x;
    bool isLeft = false;
    if (translateXtoX(getX(index)) < mWidth / 2) {
      isLeft = false;
      x = 1;
      Path path = Path();
      path.moveTo(x, y - r);
      path.lineTo(x, y + r);
      path.lineTo(textWidth + 2 * w1, y + r);
      path.lineTo(textWidth + 2 * w1 + w2, y);
      path.lineTo(textWidth + 2 * w1, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1, y - textHeight / 2));
    } else {
      isLeft = true;
      x = mWidth - textWidth - 1 - 2 * w1 - w2;
      Path path = Path();
      path.moveTo(x, y);
      path.lineTo(x + w2, y + r);
      path.lineTo(mWidth - 2, y + r);
      path.lineTo(mWidth - 2, y - r);
      path.lineTo(x + w2, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1 + w2, y - textHeight / 2));
    }

    TextPainter dateTp =
        getTextPainter(getDate(point.id!), color: Colors.white);
    textWidth = dateTp.width;
    r = textHeight / 2;
    x = translateXtoX(getX(index));
    y = size.height - ChartStyle.bottomDateHigh;

    if (x < textWidth + 2 * w1) {
      x = 1 + textWidth / 2 + w1;
    } else if (mWidth - x < textWidth + 2 * w1) {
      x = mWidth - 1 - textWidth / 2 - w1;
    }
    double baseLine = textHeight / 2;
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectPointPaint);
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectorBorderPaint);

    dateTp.paint(canvas, Offset(x - textWidth / 2, y));

    sink?.add(InfoWindowEntity(point, isLeft));
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    if (isLongPress) {
      var index = calculateSelectedX(selectX);
      data = getItem(index);
    }

    mMainRenderer.drawText(canvas, data, x);
    mVolRenderer?.drawText(canvas, data, x);
    mSecondaryRenderer?.drawText(canvas, data, x);
  }

  @override
  void drawMaxAndMin(Canvas canvas) {
    if (isLine == true) return;

    double x = translateXtoX(getX(mMainMinIndex));
    double y = getMainY(mMainLowMinValue);
    if (x < mWidth / 2) {
      TextPainter tp = getTextPainter("?????? L: ${format(mMainLowMinValue)}",
          color: ChartColors.dnColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter("${format(mMainLowMinValue)} :L ??????",
          color: ChartColors.dnColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
    x = translateXtoX(getX(mMainMaxIndex));
    y = getMainY(mMainHighMaxValue);
    if (x < mWidth / 2) {
      TextPainter tp = getTextPainter("?????? H: ${format(mMainHighMaxValue)}",
          color: ChartColors.upColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter("${format(mMainHighMaxValue)} :H ??????",
          color: ChartColors.upColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
  }

  void drawCrossLine(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);
    Paint paintY = Paint()
      ..color = Colors.white12
      ..strokeWidth = ChartStyle.vCrossWidth
      ..isAntiAlias = true;
    double x = getX(index);
    double y = getMainY(point.close);

    canvas.drawLine(Offset(x, ChartStyle.topPadding),
        Offset(x, size.height - ChartStyle.bottomDateHigh), paintY);

    Paint paintX = Paint()
      ..color = Colors.white
      ..strokeWidth = ChartStyle.hCrossWidth
      ..isAntiAlias = true;

    canvas.drawLine(Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintX);
//    canvas.drawCircle(Offset(x, y), 2.0, paintX);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), height: 2.0 * scaleX, width: 2.0),
        paintX);
  }

  final Paint realTimePaint = Paint()
        ..strokeWidth = 1.0
        ..isAntiAlias = true,
      pointPaint = Paint();

  @override
  void drawRealTimePrice(Canvas canvas, Size size) {
    if (mMarginRight == 0 || datas.isEmpty == true) return;
    KLineEntity point = datas.last;
    TextPainter tp = getTextPainter(format(point.close),
        color: ChartColors.rightRealTimeTextColor);
    double y = getMainY(point.close);

    var max = (mTranslateX.abs() +
            mMarginRight -
            getMinTranslateX().abs() +
            mPointWidth) *
        scaleX;
    double x = mWidth - max;
    if (!isLine) x += mPointWidth / 2;
    var dashWidth = 10;
    var dashSpace = 5;
    double startX = 0;
    final space = (dashSpace + dashWidth);
    if (tp.width < max) {
      while (startX < max) {
        canvas.drawLine(
            Offset(x + startX, y),
            Offset(x + startX + dashWidth, y),
            realTimePaint..color = ChartColors.realTimeLineColor);
        startX += space;
      }

      if (isLine) {
        startAnimation();
        Gradient pointGradient = RadialGradient(
            colors: [Colors.white.withOpacity(opacity), Colors.transparent]);
        pointPaint.shader = pointGradient
            .createShader(Rect.fromCircle(center: Offset(x, y), radius: 14.0));
        canvas.drawCircle(Offset(x, y), 14.0, pointPaint);
        canvas.drawCircle(
            Offset(x, y), 2.0, realTimePaint..color = Colors.white);
      } else {
        stopAnimation();
      }
      double left = mWidth - tp.width;
      double top = y - tp.height / 2;
      canvas.drawRRect(
          RRect.fromLTRBAndCorners(
            left - 10,
            top - 5,
            left + tp.width + 3,
            top + tp.height + 5,
            bottomLeft: const Radius.circular(5),
            topLeft: const Radius.circular(5),
          ),
          realTimePaint..color = ChartColors.realTimeBgColor);
      tp.paint(canvas, Offset(left - 5, top));
    } else {
      stopAnimation();
      startX = 0;
      if (point.close > mMainMaxValue) {
        y = getMainY(mMainMaxValue);
      } else if (point.close < mMainMinValue) {
        y = getMainY(mMainMinValue);
      }
      while (startX < mWidth) {
        canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y),
            realTimePaint..color = ChartColors.realTimeLongLineColor);
        startX += space;
      }

      const padding = 3.0;
      const triangleHeight = 8.0;
      const triangleWidth = 5.0;

      double left =
          mWidth - mWidth / ChartStyle.gridColumns - tp.width / 2 - padding * 2;
      double top = y - tp.height / 2 - padding;
      //padding
      double right = left + tp.width + padding * 2 + triangleWidth + padding;
      double bottom = top + tp.height + padding * 2;
      double radius = (bottom - top) / 2;

      RRect rectBg1 =
          RRect.fromLTRBR(left, top, right, bottom, Radius.circular(radius));
      RRect rectBg2 = RRect.fromLTRBR(left - 1, top - 1, right + 1, bottom + 1,
          Radius.circular(radius + 2));
      canvas.drawRRect(
          rectBg2, realTimePaint..color = ChartColors.realTimeTextBorderColor);
      canvas.drawRRect(
          rectBg1, realTimePaint..color = ChartColors.realTimeBgColor);
      tp = getTextPainter(format(point.close),
          color: ChartColors.realTimeTextColor);
      Offset textOffset = Offset(left + padding, y - tp.height / 2);
      tp.paint(canvas, textOffset);

      Path path = Path();
      double dx = tp.width + textOffset.dx + padding;
      double dy = top + (bottom - top - triangleHeight) / 2;
      path.moveTo(dx, dy);
      path.lineTo(dx + triangleWidth, dy + triangleHeight / 2);
      path.lineTo(dx, dy + triangleHeight);
      path.close();
      canvas.drawPath(
          path,
          realTimePaint
            ..color = ChartColors.realTimeTextColor
            ..shader = null);
    }
  }

  @override
  void drawBuySellPriceIndicator(Canvas canvas, Size size) {
    for (var i = 0; i < buySellPriceData.length; i++) {
      if (mMarginRight == 0 || datas.isEmpty == true) return;
      ExecutedTradesEntity point = buySellPriceData[i];

      // Adds the suffix K, M, B for the pnl
      num pnl = (ltp - point.tradePrice) * point.quantity;
      if (buySellTransactionType[i] == TransactionType.SOLD &&
          (pnl > 0 || pnl < 0)) {
        pnl *= -1;
      }
      String suffix1;
      if (pnl < 1000) {
        suffix1 = "";
      } else if (pnl >= 1000 && pnl < 1000000) {
        pnl /= 1000;
        suffix1 = "K";
      } else if (pnl >= 1000000 && pnl < 1000000000) {
        pnl /= 1000000;
        suffix1 = "M";
      } else {
        pnl /= 1000000000;
        suffix1 = "B";
      }
      // Creates a text painter for the pnl transacted at
      TextPainter tp1 = getTextPainter(format(pnl as double) + suffix1,
          color: ChartColors.rightRealTimeTextColor);

      // Adds the suffix K, M, B for the pnl
      // num quantity = point.quantity;
      String suffix2;
      if (point.quantity < 1000) {
        suffix2 = "";
      } else if (point.quantity >= 1000 && point.quantity < 1000000) {
        point.quantity /= 1000;
        suffix2 = "K";
      } else if (point.quantity >= 1000000 && point.quantity < 1000000000) {
        point.quantity /= 1000000;
        suffix2 = "M";
      } else {
        point.quantity /= 1000000000;
        suffix2 = "B";
      }
      // Creates a text painter for the quantity transacted with
      TextPainter tp2 =
          getTextPainter("${point.quantity}$suffix2", color: Colors.white);

      // PILL LOGIC
      double y = getMainY(point.tradePrice as double);
      double top = y - tp1.height / 2;
      // DRAWS THE YELLOW / WHITE PILL
      canvas.drawRRect(
          RRect.fromLTRBAndCorners(
            0,
            top - 5,
            (tp1.width + 10) + (tp2.width + 10) + 1,
            top + tp1.height + 5,
            bottomRight: const Radius.circular(5),
            topRight: const Radius.circular(5),
          ),
          realTimePaint
            ..color = buySellTransactionType[i] == TransactionType.BOUGHT
                ? Colors.white
                : Colors.yellow);
      tp1.paint(canvas, Offset(5, top));

      // DRAWS THE TRANSPARENT BG PILL
      canvas.drawRRect(
          RRect.fromLTRBAndCorners(
            tp1.width + 10,
            top - 4,
            (tp1.width + 10) + (tp2.width + 10),
            top + tp1.height + 4,
            bottomRight: const Radius.circular(5),
            topRight: const Radius.circular(5),
          ),
          realTimePaint..color = ChartColors.bgColorPNL);
      tp2.paint(canvas, Offset(tp1.width + 15, top));

      // DRAWING THE LINE
      int dashWidth = 10;
      int dashSpace = 5;
      double startX = (tp1.width + 10) + (tp2.width + 10) + 1;
      final int space = (dashSpace + dashWidth);

      while (startX < mWidth - tp1.width) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(
              (startX + dashWidth) > (mWidth - tp1.width)
                  ? (mWidth - tp1.width)
                  : (startX + dashWidth),
              y),
          realTimePaint
            ..color = buySellTransactionType[i] == TransactionType.BOUGHT
                ? Colors.white
                : Colors.yellow,
        );
        startX += space;
      }
    }
  }

  TextPainter getTextPainter(text, {color = Colors.white}) {
    TextSpan span = TextSpan(text: "$text", style: getTextStyle(color));
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    return tp;
  }

  String getDate(int date) =>
      dateFormat(DateTime.fromMillisecondsSinceEpoch(date * 1000), mFormats);

  double getMainY(double y) => mMainRenderer.getY(y);

  startAnimation() {
    if (controller?.isAnimating != true) controller?.repeat(reverse: true);
  }

  stopAnimation() {
    if (controller?.isAnimating == true) controller?.stop();
  }
}
