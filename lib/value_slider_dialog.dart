import 'package:flutter/material.dart';

class ValueSliderDialog extends StatefulWidget {
  const ValueSliderDialog({
    Key? key,
    required this.title,
    required this.minValue,
    required this.startValue,
    required this.maxValue,
    required this.cancelText,
    required this.acceptText,
  }) : super(key: key);

  final String title;
  final int minValue;
  final int startValue;
  final int maxValue;
  final String cancelText;
  final String acceptText;

  @override
  State<ValueSliderDialog> createState() => _ValueSliderDialogState();
}

class _ValueSliderDialogState extends State<ValueSliderDialog> {
  late double _min;
  late double _value;
  late double _max;

  @override
  void initState() {
    _min = widget.minValue.toDouble();
    _value = widget.startValue.toDouble();
    _max = widget.maxValue.toDouble();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Slider(
            min: _min,
            value: _value,
            max: _max,
            divisions: 10,
            label: '${_value.toInt()} x ${_value.toInt()}',
            onChanged: (val) => setState(() => _value = val),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${_min.toInt()}'),
                Text('${_max.toInt()}'),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton(
                child: Text(widget.cancelText),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: Text(widget.acceptText),
                onPressed: () => Navigator.of(context).pop(_value.toInt()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
