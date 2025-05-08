import 'package:flutter/material.dart';

class ModeSwitch extends StatefulWidget {
  const ModeSwitch({super.key});

  @override
  State<ModeSwitch> createState() => _ModeSwitchState();
}

class _ModeSwitchState extends State<ModeSwitch> {
  final List<bool> _isSelected = [
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
  }

  @override
  Widget build(BuildContext context) {
    TextStyle ts = TextStyle(
      color: Theme.of(context).colorScheme.inverseSurface,
      fontSize: 16,
    );

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
