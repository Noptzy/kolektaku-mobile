import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/accent_palette.dart';

const hueTrackHeight = 10.0;
const _transparent = Color(0x00000000);
const _gradientStopCount = 13;

final hueTrackGradientColors = [
  for (var step = 0; step < _gradientStopCount; step++)
    accentColorFromHue(step * 360 / (_gradientStopCount - 1)),
];

class HueSlider extends StatefulWidget {
  const HueSlider({
    super.key,
    required this.hue,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double hue;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  State<HueSlider> createState() => _HueSliderState();
}

class _HueSliderState extends State<HueSlider> {
  late final ShadSliderController _controller = ShadSliderController(
    initialValue: widget.hue,
  );

  @override
  void didUpdateWidget(HueSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hue != oldWidget.hue && widget.hue != _controller.value) {
      _controller.value = widget.hue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _controller,
      builder: (context, hue, _) {
        return SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: hueTrackHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(hueTrackHeight / 2),
                  gradient: LinearGradient(colors: hueTrackGradientColors),
                ),
              ),
              ShadSlider(
                key: const Key('accent-hue-slider'),
                controller: _controller,
                min: 0,
                max: 360,
                thumbColor: accentColorFromHue(hue),
                activeTrackColor: _transparent,
                inactiveTrackColor: _transparent,
                disabledActiveTrackColor: _transparent,
                disabledInactiveTrackColor: _transparent,
                onChanged: widget.onChanged,
                onChangeEnd: widget.onChangeEnd,
              ),
            ],
          ),
        );
      },
    );
  }
}
