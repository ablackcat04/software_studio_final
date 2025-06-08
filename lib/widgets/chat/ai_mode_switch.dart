import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:software_studio_final/state/chat_history_notifier.dart';

class AIModeSwitch extends StatefulWidget {
  const AIModeSwitch({super.key});

  @override
  State<AIModeSwitch> createState() => _AIModeSwitchState();
}

class _AIModeSwitchState extends State<AIModeSwitch> {
  List<bool> _isSelected = [
    true,
    false,
    false,
    false,
  ]; // Initial state: first selected

  void _onToggle(int index) {
    setState(() {
      for (int i = 0; i < _isSelected.length; i++) {
        _isSelected[i] = i == index;
      }
    });
    final guideNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );
    if (index == 0) {
      guideNotifier.setMode('一般');
    } else if (index == 1) {
      guideNotifier.setMode('已讀亂回 (回一些好像有關係但有好像沒關係的，莫名其妙的)');
    } else if (index == 2) {
      guideNotifier.setMode('假正經 (一本正經的講幹話)');
    } else if (index == 3) {
      guideNotifier.setMode('關鍵字 (像是"春"for"春日影")');
    }
  }

  @override
  Widget build(BuildContext context) {
    TextStyle ts = TextStyle(
      color: Theme.of(context).colorScheme.inverseSurface,
      fontSize: 16,
    );

    final guideNotifier = Provider.of<ChatHistoryNotifier>(
      context,
      listen: false,
    );
    if (guideNotifier.mode == '一般') {
      _isSelected = [true, false, false, false];
    } else if (guideNotifier.mode == '已讀亂回 (回一些好像有關係但有好像沒關係的，莫名其妙的)') {
      _isSelected = [false, true, false, false];
    } else if (guideNotifier.mode == '假正經 (一本正經的講幹話)') {
      _isSelected = [false, false, true, false];
    } else if (guideNotifier.mode == '關鍵字 (像是"春"for"春日影")') {
      _isSelected = [false, false, false, true];
    }

    return Padding(
      padding: EdgeInsets.all(8.0),
      child: SizedBox(
        height: 40,
        child: ToggleButtons(
          isSelected: _isSelected,
          onPressed: _onToggle,
          borderRadius: BorderRadius.circular(8),
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          fillColor: Theme.of(context).colorScheme.primaryContainer,
          color: Colors.black,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('一般', style: ts),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('已讀亂回', style: ts),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('正經', style: ts),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('關鍵字', style: ts),
            ),
          ],
        ),
      ),
    );
  }
}
