import 'dart:math';
export 'package:flutter/material.dart'
    show Color, required, TextStyle, Rect, Canvas, Size, CustomPainter;
import 'package:flutter/material.dart'
    show Color, TextStyle, Rect, Canvas, Size, CustomPainter;
import 'package:trading_leagues_chart/entity/executed_trades_entity.dart';
import 'package:trading_leagues_chart/utils/date_format_util.dart';
import 'package:trading_leagues_chart/utils/number_util.dart';
import 'package:trading_leagues_chart/entity/k_line_entity.dart';
import 'package:trading_leagues_chart/tl_chart_widget.dart';
import 'package:trading_leagues_chart/chart_style.dart' show ChartStyle;

abstract class BaseChartPainter extends CustomPainter {
  static double maxScrollX = 0.0;
  List<KLineEntity> datas;
  MainState mainState;
  List<ExecutedTradesEntity> buySellPriceData;
  List<TransactionType> buySellTransactionType;
  final num ltp;
  VolState volState;
  SecondaryState secondaryState;

  double scaleX = 1.0, scrollX = 0.0, selectX;
  bool isLongPress = false;
  bool isLine;

  late Rect mMainRect;
  Rect? mVolRect, mSecondaryRect;
  late double mDisplayHeight, mWidth;

  int mStartIndex = 0, mStopIndex = 0;
  double mMainMaxValue = -double.maxFinite, mMainMinValue = double.maxFinite;
  double mVolMaxValue = -double.maxFinite, mVolMinValue = double.maxFinite;
  double mSecondaryMaxValue = -double.maxFinite,
      mSecondaryMinValue = double.maxFinite;
  double mTranslateX = -double.maxFinite;
  int mMainMaxIndex = 0, mMainMinIndex = 0;
  double mMainHighMaxValue = -double.maxFinite,
      mMainLowMinValue = double.maxFinite;
  int mItemCount = 0;
  double mDataLen = 0.0;
  double mPointWidth = ChartStyle.pointWidth;
  List<String> mFormats = [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn];
  double mMarginRight = 0.0;

  BaseChartPainter({
    required this.datas,
    required this.scaleX,
    required this.scrollX,
    required this.isLongPress,
    required this.selectX,
    this.mainState = MainState.MA,
    this.volState = VolState.VOL,
    this.secondaryState = SecondaryState.MACD,
    this.isLine = false,
    required this.buySellPriceData,
    required this.buySellTransactionType,
    required this.ltp,
  }) {
    mItemCount = datas.length;
    mDataLen = mItemCount * mPointWidth;
    initFormats();
  }

  void initFormats() {
//    [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn]
    if (mItemCount < 2) return;
    int firstTime = datas.first.id ?? 0;
    int secondTime = datas[1].id ?? 0;
    int time = secondTime - firstTime;

    if (time >= 24 * 60 * 60 * 28) {
      mFormats = [yy, '-', mm];
    } else if (time >= 24 * 60 * 60) {
      mFormats = [yy, '-', mm, '-', dd];
    } else {
      mFormats = [mm, '-', dd, ' ', HH, ':', nn];
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, size.height));
    mDisplayHeight =
        size.height - ChartStyle.topPadding - ChartStyle.bottomDateHigh;
    mWidth = size.width;
    mMarginRight = (mWidth / ChartStyle.gridColumns - mPointWidth) / scaleX;
    initRect(size);
    calculateValue();
    initChartRenderer();

    canvas.save();
    canvas.scale(1, 1);
    drawBg(canvas, size);
    drawGrid(canvas);
    if (datas.isNotEmpty) {
      drawChart(canvas, size);
      drawRightText(canvas);
      drawRealTimePrice(canvas, size);
      drawDate(canvas, size);
      if (isLongPress == true) drawCrossLineText(canvas, size);
      drawText(canvas, datas.last, 5);
      drawMaxAndMin(canvas);
      // if (buySellPriceIndicator) {
      drawBuySellPriceIndicator(canvas, size);
      // }
    }
    canvas.restore();
  }

  void initChartRenderer();

  void drawBg(Canvas canvas, Size size);

  void drawGrid(canvas);

  void drawChart(Canvas canvas, Size size);

  void drawRightText(canvas);

  void drawDate(Canvas canvas, Size size);

  void drawText(Canvas canvas, KLineEntity data, double x);

  void drawMaxAndMin(Canvas canvas);

  void drawCrossLineText(Canvas canvas, Size size);

  void initRect(Size size) {
    double mainHeight = mDisplayHeight * 0.6;
    double volHeight = mDisplayHeight * 0.2;
    double secondaryHeight = mDisplayHeight * 0.2;
    if (volState == VolState.NONE && secondaryState == SecondaryState.NONE) {
      mainHeight = mDisplayHeight;
    } else if (volState == VolState.NONE ||
        secondaryState == SecondaryState.NONE) {
      mainHeight = mDisplayHeight * 0.8;
    }
    mMainRect = Rect.fromLTRB(
        0, ChartStyle.topPadding, mWidth, ChartStyle.topPadding + mainHeight);
    if (volState != VolState.NONE) {
      mVolRect = Rect.fromLTRB(0, mMainRect.bottom + ChartStyle.childPadding,
          mWidth, mMainRect.bottom + volHeight);
    }
    if (secondaryState != SecondaryState.NONE) {
      mSecondaryRect = Rect.fromLTRB(
          0,
          (mVolRect?.bottom ?? mMainRect.bottom) + ChartStyle.childPadding,
          mWidth,
          (mVolRect?.bottom ?? mMainRect.bottom) + secondaryHeight);
    }
  }

  calculateValue() {
    if (datas.isEmpty) return;
    maxScrollX = getMinTranslateX().abs();
    setTranslateXFromScrollX(scrollX);
    mStartIndex = indexOfTranslateX(xToTranslateX(0));
    mStopIndex = indexOfTranslateX(xToTranslateX(mWidth));
    for (int i = mStartIndex; i <= mStopIndex; i++) {
      var item = datas[i];
      getMainMaxMinValue(item, i);
      getVolMaxMinValue(item);
      getSecondaryMaxMinValue(item);
    }
  }

  void getMainMaxMinValue(KLineEntity item, int i) {
    if (isLine == true) {
      mMainMaxValue = max(mMainMaxValue, item.close);
      mMainMinValue = min(mMainMinValue, item.close);
    } else {
      double maxPrice = item.high, minPrice = item.low;
      if (mainState == MainState.MA) {
        if (item.MA5Price != 0) {
          maxPrice = max(maxPrice, item.MA5Price!);
          minPrice = min(minPrice, item.MA5Price!);
        }
        if (item.MA10Price != 0) {
          maxPrice = max(maxPrice, item.MA10Price!);
          minPrice = min(minPrice, item.MA10Price!);
        }
        if (item.MA20Price != 0) {
          maxPrice = max(maxPrice, item.MA20Price!);
          minPrice = min(minPrice, item.MA20Price!);
        }
        if (item.MA30Price != 0) {
          maxPrice = max(maxPrice, item.MA30Price!);
          minPrice = min(minPrice, item.MA30Price!);
        }
      } else if (mainState == MainState.BOLL) {
        if (item.up != 0) {
          maxPrice = max(item.up!, item.high);
        }
        if (item.dn != 0) {
          minPrice = min(item.dn!, item.low);
        }
      }
      mMainMaxValue = max(mMainMaxValue, maxPrice);
      mMainMinValue = min(mMainMinValue, minPrice);

      if (mMainHighMaxValue < item.high) {
        mMainHighMaxValue = item.high;
        mMainMaxIndex = i;
      }
      if (mMainLowMinValue > item.low) {
        mMainLowMinValue = item.low;
        mMainMinIndex = i;
      }
    }
  }

  void getVolMaxMinValue(KLineEntity item) {
    mVolMaxValue = max(
        mVolMaxValue, max(item.vol, max(item.MA5Volume!, item.MA10Volume!)));
    mVolMinValue = min(
        mVolMinValue, min(item.vol, min(item.MA5Volume!, item.MA10Volume!)));
  }

  void getSecondaryMaxMinValue(KLineEntity item) {
    if (secondaryState == SecondaryState.MACD) {
      mSecondaryMaxValue =
          max(mSecondaryMaxValue, max(item.macd!, max(item.dif!, item.dea!)));
      mSecondaryMinValue =
          min(mSecondaryMinValue, min(item.macd!, min(item.dif!, item.dea!)));
    } else if (secondaryState == SecondaryState.KDJ) {
      mSecondaryMaxValue =
          max(mSecondaryMaxValue, max(item.k!, max(item.d!, item.j!)));
      mSecondaryMinValue =
          min(mSecondaryMinValue, min(item.k!, min(item.d!, item.j!)));
    } else if (secondaryState == SecondaryState.RSI) {
      mSecondaryMaxValue = max(mSecondaryMaxValue, item.rsi!);
      mSecondaryMinValue = min(mSecondaryMinValue, item.rsi!);
    } else {
      mSecondaryMaxValue = max(mSecondaryMaxValue, item.r!);
      mSecondaryMinValue = min(mSecondaryMinValue, item.r!);
    }
  }

  double xToTranslateX(double x) => -mTranslateX + x / scaleX;

  int indexOfTranslateX(double translateX) =>
      _indexOfTranslateX(translateX, 0, mItemCount - 1);

  ///index
  int _indexOfTranslateX(double translateX, int start, int end) {
    if (end == start || end == -1) {
      return start;
    }
    if (end - start == 1) {
      double startValue = getX(start);
      double endValue = getX(end);
      return (translateX - startValue).abs() < (translateX - endValue).abs()
          ? start
          : end;
    }
    int mid = start + (end - start) ~/ 2;
    double midValue = getX(mid);
    if (translateX < midValue) {
      return _indexOfTranslateX(translateX, start, mid);
    } else if (translateX > midValue) {
      return _indexOfTranslateX(translateX, mid, end);
    } else {
      return mid;
    }
  }

  ///+ mPointWidth / 2
  ///@param position
  double getX(int position) => position * mPointWidth + mPointWidth / 2;

  KLineEntity getItem(int position) {
    return datas[position];
  }

  ///scrollX TranslateX
  void setTranslateXFromScrollX(double scrollX) =>
      mTranslateX = scrollX + getMinTranslateX();

  double getMinTranslateX() {
//    var x = -mDataLen + mWidth / scaleX - mPointWidth / 2;
    var x = -mDataLen + mWidth / scaleX - mPointWidth / 2;
    x = x >= 0 ? 0.0 : x;
    if (x >= 0) {
      if (mWidth / scaleX - getX(datas.length) < mMarginRight) {
        x -= mMarginRight - mWidth / scaleX + getX(datas.length);
      } else {
        //Right
        mMarginRight = mWidth / scaleX - getX(datas.length);
      }
    } else if (x < 0) {
      x -= mMarginRight;
    }
    return x >= 0 ? 0.0 : x;
  }

  ///index
  int calculateSelectedX(double selectX) {
    int mSelectedIndex = indexOfTranslateX(xToTranslateX(selectX));
    if (mSelectedIndex < mStartIndex) {
      mSelectedIndex = mStartIndex;
    }
    if (mSelectedIndex > mStopIndex) {
      mSelectedIndex = mStopIndex;
    }
    return mSelectedIndex;
  }

  ///translateX view
  double translateXtoX(double translateX) =>
      (translateX + mTranslateX) * scaleX;

  TextStyle getTextStyle(Color color) {
    return TextStyle(fontSize: ChartStyle.defaultTextSize, color: color);
  }

  void drawRealTimePrice(Canvas canvas, Size size);

  void drawBuySellPriceIndicator(Canvas canvas, Size size);

  String format(double n) {
    return NumberUtil.format(n);
  }

  @override
  bool shouldRepaint(BaseChartPainter oldDelegate) {
    return true;
//    return oldDelegate.datas != datas ||
//        oldDelegate.datas?.length != datas?.length ||
//        oldDelegate.scaleX != scaleX ||
//        oldDelegate.scrollX != scrollX ||
//        oldDelegate.isLongPress != isLongPress ||
//        oldDelegate.selectX != selectX ||
//        oldDelegate.isLine != isLine ||
//        oldDelegate.mainState != mainState ||
//        oldDelegate.secondaryState != secondaryState;
  }
}
