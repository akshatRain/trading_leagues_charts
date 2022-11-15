import 'package:flutter/material.dart';
import '../entity/candle_entity.dart';
import 'package:trading_leagues_chart/tl_chart_widget.dart' show MainState;
import 'base_chart_renderer.dart';

class MainRenderer extends BaseChartRenderer<CandleEntity> {
  double mCandleWidth = ChartStyle.candleWidth;
  double mCandleLineWidth = ChartStyle.candleLineWidth;
  MainState state;
  bool isLine;

  final double _contentPadding = 12.0;

  MainRenderer(
    Rect mainRect,
    double maxValue,
    double minValue,
    double topPadding,
    this.state,
    this.isLine,
    double scaleX,
  ) : super(
            chartRect: mainRect,
            maxValue: maxValue,
            minValue: minValue,
            topPadding: topPadding,
            scaleX: scaleX) {
    var diff = maxValue - minValue;
    var newScaleY = (chartRect.height - _contentPadding) / diff;
    var newDiff = chartRect.height / newScaleY;
    var value = (newDiff - diff) / 2;
    if (newDiff > diff) {
      scaleY = newScaleY;
      this.maxValue += value;
      this.minValue -= value;
    }
  }

  @override
  void drawText(Canvas canvas, CandleEntity data, double x) {
    if (isLine == true) return;
    TextSpan? span;
    if (state == MainState.MA) {
      span = TextSpan(
        children: [
          if (data.MA5Price != 0)
            TextSpan(
                text: "MA5:${format(data.MA5Price!)}    ",
                style: getTextStyle(ChartColors.ma5Color)),
          if (data.MA10Price != 0)
            TextSpan(
                text: "MA10:${format(data.MA10Price!)}    ",
                style: getTextStyle(ChartColors.ma10Color)),
          if (data.MA30Price != 0)
            TextSpan(
                text: "MA30:${format(data.MA30Price!)}    ",
                style: getTextStyle(ChartColors.ma30Color)),
        ],
      );
    } else if (state == MainState.BOLL) {
      span = TextSpan(
        children: [
          if (data.mb != 0)
            TextSpan(
                text: "BOLL:${format(data.mb!)}    ",
                style: getTextStyle(ChartColors.ma5Color)),
          if (data.up != 0)
            TextSpan(
                text: "UP:${format(data.up!)}    ",
                style: getTextStyle(ChartColors.ma10Color)),
          if (data.dn != 0)
            TextSpan(
                text: "LB:${format(data.dn!)}    ",
                style: getTextStyle(ChartColors.ma30Color)),
        ],
      );
    }
    if (span == null) return;
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x, chartRect.top - topPadding));
  }

  @override
  void drawChart(CandleEntity lastPoint, CandleEntity curPoint, double lastX,
      double curX, Size size, Canvas canvas) {
    if (isLine != true) drawCandle(curPoint, canvas, curX);
    if (isLine == true) {
      draLine(lastPoint.close, curPoint.close, canvas, lastX, curX);
    } else if (state == MainState.MA) {
      drawMaLine(lastPoint, curPoint, canvas, lastX, curX);
    } else if (state == MainState.BOLL) {
      drawBollLine(lastPoint, curPoint, canvas, lastX, curX);
    }
  }

  Shader? mLineFillShader;
  Path? mLinePath, mLineFillPath;
  final double mLineStrokeWidth = 1.0;
  final Paint mLinePaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..color = ChartColors.kLineColor;
  final Paint mLineFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  draLine(double lastPrice, double curPrice, Canvas canvas, double lastX,
      double curX) {
    mLinePath ??= Path();

    if (lastX == curX) lastX = 0;
    mLinePath!.moveTo(lastX, getY(lastPrice));
    mLinePath!.cubicTo((lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2,
        getY(curPrice), curX, getY(curPrice));

    mLineFillShader ??= const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      tileMode: TileMode.clamp,
      colors: ChartColors.kLineShadowColor,
    ).createShader(Rect.fromLTRB(
        chartRect.left, chartRect.top, chartRect.right, chartRect.bottom));
    mLineFillPaint.shader = mLineFillShader;

    mLineFillPath ??= Path();

    mLineFillPath?.moveTo(lastX, chartRect.height + chartRect.top);
    mLineFillPath?.lineTo(lastX, getY(lastPrice));
    mLineFillPath?.cubicTo((lastX + curX) / 2, getY(lastPrice),
        (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
    mLineFillPath?.lineTo(curX, chartRect.height + chartRect.top);
    mLineFillPath?.close();

    canvas.drawPath(mLineFillPath!, mLineFillPaint);
    mLineFillPath?.reset();

    canvas.drawPath(mLinePath!,
        mLinePaint..strokeWidth = (mLineStrokeWidth / scaleX).clamp(0.3, 1.0));
    mLinePath?.reset();
  }

  void drawMaLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    if (lastPoint.MA5Price != 0) {
      drawLine(lastPoint.MA5Price!, curPoint.MA5Price!, canvas, lastX, curX,
          ChartColors.ma5Color);
    }
    if (lastPoint.MA10Price != 0) {
      drawLine(lastPoint.MA10Price!, curPoint.MA10Price!, canvas, lastX, curX,
          ChartColors.ma10Color);
    }
    if (lastPoint.MA30Price != 0) {
      drawLine(lastPoint.MA30Price!, curPoint.MA30Price!, canvas, lastX, curX,
          ChartColors.ma30Color);
    }
  }

  void drawBollLine(CandleEntity lastPoint, CandleEntity curPoint,
      Canvas canvas, double lastX, double curX) {
    if (lastPoint.up != 0) {
      drawLine(lastPoint.up!, curPoint.up!, canvas, lastX, curX,
          ChartColors.ma10Color);
    }
    if (lastPoint.mb != 0) {
      drawLine(lastPoint.mb!, curPoint.mb!, canvas, lastX, curX,
          ChartColors.ma5Color);
    }
    if (lastPoint.dn != 0) {
      drawLine(lastPoint.dn!, curPoint.dn!, canvas, lastX, curX,
          ChartColors.ma30Color);
    }
  }

  void drawCandle(CandleEntity curPoint, Canvas canvas, double curX) {
    var high = getY(curPoint.high);
    var low = getY(curPoint.low);
    var open = getY(curPoint.open);
    var close = getY(curPoint.close);
    double r = mCandleWidth / 2;
    double lineR = mCandleLineWidth / 2;

    //1px
    if ((open - close).abs() < 1) {
      if (open > close) {
        open += 0.5;
        close -= 0.5;
      } else {
        open -= 0.5;
        close += 0.5;
      }
    }
    if (open > close) {
      chartPaint.color = ChartColors.upColor;
      canvas.drawRect(
          Rect.fromLTRB(curX - r, close, curX + r, open), chartPaint);
      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    } else {
      chartPaint.color = ChartColors.dnColor;
      canvas.drawRect(
          Rect.fromLTRB(curX - r, open, curX + r, close), chartPaint);
      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    }
  }

  @override
  void drawRightText(canvas, textStyle, int gridRowSpace) {
    int newGridRows = chartRect.height ~/ gridRowSpace;
    for (var i = 0; i <= newGridRows; ++i) {
      double position = 0;
      if (i == 0) {
        position = (newGridRows - i) * gridRowSpace - _contentPadding / 2;
      } else if (i == newGridRows) {
        position = (newGridRows - i) * gridRowSpace + _contentPadding / 2;
      } else {
        position = (newGridRows - i) * gridRowSpace.toDouble();
      }
      var value = position / scaleY + minValue;
      TextSpan span = TextSpan(text: format(value), style: textStyle);
      TextPainter tp =
          TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      double y;
      if (i == 0 || i == newGridRows) {
        y = getY(value) - tp.height / 2;
      } else {
        y = getY(value) - tp.height;
      }
      tp.paint(canvas, Offset(chartRect.width - tp.width, y));
    }
  }

  @override
  void drawGrid(Canvas canvas, int gridRowSpace, int gridColumns) {
    canvas.drawLine(Offset(0, chartRect.bottom),
        Offset(chartRect.width, chartRect.bottom), gridPaint);
    final int gridRowsNew = chartRect.height ~/ gridRowSpace;
    for (int i = 0; i <= gridRowsNew; i++) {
      double dashWidth = 3, dashSpace = 7, startX = 0;
      while (startX <= chartRect.width) {
        canvas.drawLine(Offset(startX, chartRect.bottom - i * 50),
            Offset(startX + dashWidth, chartRect.bottom - i * 50), gridPaint);
        startX += dashWidth + dashSpace;
      }
    }
  }
}
