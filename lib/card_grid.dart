import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:bingogame/theme_color.dart';
import 'package:bingogame/card_cell.dart';
import 'package:bingogame/model.dart';
import 'package:bingogame/card_grid_cell.dart';

class CardGrid extends StatefulWidget {
  final int cardNumber;
  final int cardGridUpdateSign;

  const CardGrid({
    super.key,
    required this.cardNumber,
    required this.cardGridUpdateSign,
  });

  @override
  State<CardGrid> createState() => _CardGridState();
}

class _CardGridState extends State<CardGrid> {
  static const int _gridSize = 5;
  static final Random _random = Random();
  late List<List<CardCell>> _grid;
  final Set<int> _highlighted = <int>{};
  late int _cardNumber;
  late ThemeColor _themeColor;
  late String _subject;
  late String _cardState;

  @override
  void initState() {
    super.initState();
    _initState();
  }

  void _initState() async {
    _themeColor = ThemeColor(context: context);
    _cardNumber = widget.cardNumber;
    _updateSubject();
    await _restoreCardState();
    _loadBallHistory();
    _updateBingoHighlight();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant CardGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _didUpdateWidget(oldWidget);
  }

  void _didUpdateWidget(covariant CardGrid oldWidget) async {
    if (widget.cardGridUpdateSign == -1) {
    } else if (widget.cardGridUpdateSign == 0) {
      _updateSubject();
      await _restoreCardState();
      _loadBallHistory();
      _updateBingoHighlight();
      if (mounted) {
        setState(() {});
      }
    } else {
      if (oldWidget.cardGridUpdateSign != widget.cardGridUpdateSign) {
        _loadBallHistory();
        _updateBingoHighlight();
        if (mounted) {
          setState(() {});
        }
      }
    }
  }

  int _indexOf(int row, int col) => col * _gridSize + row;

  void _updateSubject() {
    if (_cardNumber == 1) {
      _subject = Model.cardSubject1;
    } else if (_cardNumber == 2) {
      _subject = Model.cardSubject2;
    } else if (_cardNumber == 3) {
      _subject = Model.cardSubject3;
    } else if (_cardNumber == 4) {
      _subject = Model.cardSubject4;
    } else if (_cardNumber == 5) {
      _subject = Model.cardSubject5;
    } else if (_cardNumber == 6) {
      _subject = Model.cardSubject6;
    }
  }

  Future<void> _restoreCardState() async {
    if (_cardNumber == 1) {
      _cardState = Model.cardState1;
    } else if (_cardNumber == 2) {
      _cardState = Model.cardState2;
    } else if (_cardNumber == 3) {
      _cardState = Model.cardState3;
    } else if (_cardNumber == 4) {
      _cardState = Model.cardState4;
    } else if (_cardNumber == 5) {
      _cardState = Model.cardState5;
    } else if (_cardNumber == 6) {
      _cardState = Model.cardState6;
    }
    _grid = List.generate(
      _gridSize,
          (_) => List.generate(_gridSize, (_) => CardCell(number: 0)),
    );
    final bool restored = _loadStoredCardState(_cardState);
    if (!restored) {
      _generateNewCard();
      await _saveCardState();
    }
  }
  
  bool _loadStoredCardState(String stored) {
    if (stored.isEmpty) {
      return false;
    }
    final List<int> entries = stored
      .split(',')
      .where((element) => element.isNotEmpty)
      .map((e) => int.tryParse(e))
      .where((e) => e != null)
      .map((e) => e!)
      .toList();
    if (entries.length != _gridSize * _gridSize) {
      return false;
    }
    for (int i = 0; i < _gridSize * _gridSize; i++) {
      if (entries[i] == 0) {
        return false;
      }
    }
    int index = 0;
    for (int col = 0; col < _gridSize; col++) {
      for (int row = 0; row < _gridSize; row++) {
        _grid[row][col]
          ..number = entries[index]
          ..open = false;
        index++;
      }
    }
    _grid[2][2].open = true;
    return true;
  }

  void _generateNewCard() {
    for (int col = 0; col < _gridSize; col++) {
      final int base = col * 15;
      final numbers = List<int>.generate(15, (index) => base + index + 1);
      numbers.shuffle(_random);
      for (int row = 0; row < _gridSize; row++) {
        _grid[row][col]
          ..number = numbers[row]
          ..open = false;
      }
    }
    _grid[2][2].open = true;
  }

  Future<void> _saveCardState() async {
    final buffer = StringBuffer();
    for (int col = 0; col < _gridSize; col++) {
      for (int row = 0; row < _gridSize; row++) {
        final cellNumber = _grid[row][col].number;
        buffer..write(cellNumber.toString())..write(',');
      }
    }
    await Model.setCardState(_cardNumber, buffer.toString());
  }

  void _loadBallHistory() {
    final String ballHistory = Model.ballHistory;
    if (ballHistory.isEmpty) {
      return;
    }
    final List<int> ballHistoryNumbers = ballHistory
        .split(',')
        .map((e) => int.tryParse(e))
        .where((e) => e != null)
        .map((e) => e!)
        .where((e) => e >= 0 && e < 75)
        .toList();
    if (ballHistoryNumbers.isEmpty) {
      return;
    }
    for (int col = 0; col < _gridSize; col++) {
      for (int row = 0; row < _gridSize; row++) {
        if (ballHistoryNumbers.contains(_grid[row][col].number - 1)) {
          _grid[row][col].open = true;
        }
      }
    }
  }

  void _updateBingoHighlight() {
    _highlighted.clear();
    for (int row = 0; row < _gridSize; row++) {
      bool allOpen = true;
      for (int col = 0; col < _gridSize; col++) {
        if (!_grid[row][col].open && !(row == 2 && col == 2)) {
          allOpen = false;
          break;
        }
      }
      if (allOpen) {
        for (int col = 0; col < _gridSize; col++) {
          _highlighted.add(_indexOf(row, col));
        }
      }
    }
    for (int col = 0; col < _gridSize; col++) {
      bool allOpen = true;
      for (int row = 0; row < _gridSize; row++) {
        if (!_grid[row][col].open && !(row == 2 && col == 2)) {
          allOpen = false;
          break;
        }
      }
      if (allOpen) {
        for (int row = 0; row < _gridSize; row++) {
          _highlighted.add(_indexOf(row, col));
        }
      }
    }
    bool diagonal1 = true;
    for (int i = 0; i < _gridSize; i++) {
      if (!_grid[i][i].open && !(i == 2 && i == 2)) {
        diagonal1 = false;
        break;
      }
    }
    if (diagonal1) {
      for (int i = 0; i < _gridSize; i++) {
        _highlighted.add(_indexOf(i, i));
      }
    }
    bool diagonal2 = true;
    for (int i = 0; i < _gridSize; i++) {
      final int row = i;
      final int col = _gridSize - 1 - i;
      if (!_grid[row][col].open && !(row == 2 && col == 2)) {
        diagonal2 = false;
        break;
      }
    }
    if (diagonal2) {
      for (int i = 0; i < _gridSize; i++) {
        _highlighted.add(_indexOf(i, _gridSize - 1 - i));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _themeColor.mainCardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(left: 5, right: 5, top: 0, bottom: 5),
        child: Column(children:[
          Text(_subject),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _gridSize * _gridSize,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridSize,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final row = index ~/ _gridSize;
              final col = index % _gridSize;
              return _buildCardCell(row, col);
            },
          )
        ]),
      )
    );
  }

  Widget _buildCardCell(int row, int col) {
    final cell = _grid[row][col];
    final bool isCenter = row == 2 && col == 2;
    final bool isOpen = cell.open || isCenter;
    final int index = _indexOf(row, col);
    final bool highlighted = _highlighted.contains(index);
    final Color background = isOpen ? _themeColor.cardTableOpenBackColor : _themeColor.cardTableCloseBackColor;
    final Color baseTextColor = isOpen ? _themeColor.cardTableOpenForeColor : _themeColor.cardTableCloseForeColor;
    final Color textColor = highlighted ? _themeColor.cardTableBingoForeColor : baseTextColor;
    final String label = isCenter ? 'F' : cell.number.toString();
    return CardGridCell(
      isOpen: isOpen,
      label: label,
      background: background,
      textColor: textColor,
    );
  }

}
