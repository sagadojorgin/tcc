import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

Widget medidor(Color colorFirst, Color colorSecond, double min, double max,
    double value, bool animation, String symbol) {
  return SizedBox(
    width: 184, // Define a largura do gauge
    height: 164, // Define a altura do gauge
    child: SfRadialGauge(
      // widget do gauge inteiro
      enableLoadingAnimation: animation, // habilita a animação inicial
      animationDuration:
          1000, // duração da animação, em milisegundos provavelmente
      axes: <RadialAxis>[
        RadialAxis(
          minimum: min,
          maximum: max,
          interval: (max / 8).roundToDouble(),
          showLabels: true, // para aparecer os números
          showLastLabel: true, // para aparecer o último número
          showTicks:
              false, // para não aparecer umas barrinhas verticais antes dos números
          axisLabelStyle: const GaugeTextStyle(
            fontSize: 10, // Define o tamanho das labels internas
            fontWeight: FontWeight.bold,
          ),
          axisLineStyle: AxisLineStyle(
            thickness: 0.1,
            thicknessUnit: GaugeSizeUnit.factor,
            cornerStyle: CornerStyle.bothFlat,
            color: Colors.grey.withOpacity(0.3), //cor de fundo do gauge
          ),
          pointers: <GaugePointer>[
            RangePointer(
              value:
                  value, // aqui é onde aquela variável manda o valor para o gauge
              width: 0.1,
              sizeUnit: GaugeSizeUnit.factor,
              gradient: SweepGradient(
                // para fazer o gradiente do progresso
                colors: [colorFirst, colorSecond],
                stops: const [
                  0.0,
                  0.75
                ], // porcentagem de cada cor do gradiente, o $colorFirst começa no 0% e o $colorSecond no 75%
              ),
              enableAnimation: animation, // habilita a animação do progresso
              animationDuration: 1000, // duração da animação do progresso
              animationType:
                  AnimationType.ease, // tipo da animação do progresso
            ),
            NeedlePointer(
              value:
                  value, // aqui é onde a variável manda o valor para o ponteiro
              needleLength: 1.3, // comprimento do ponteiro
              lengthUnit: GaugeSizeUnit.factor,
              needleStartWidth: 1, // largula inicial do ponteiro
              needleEndWidth: 7, // largura final do ponteiro
              gradient: LinearGradient(
                // para fazer o gradiente do ponteiro
                colors: [
                  const Color(0xfffcfcfc),
                  colorSecond,
                  Colors.transparent
                ],
                stops: const [
                  0.10,
                  0.75,
                  0.76
                ], // porcentagem de cada cor do gradiente, nem eu sei como isso tá funcionando, na dúvida, não mexe
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                transform: const GradientRotation(180 *
                    3.14 /
                    180), // aqui para dar um flip no gradiente, nesse momento ele é redundante, mas não tira
              ),
              enableAnimation: animation, // habilita a animação do ponteiro
              animationDuration: 1000, // duração da animação do ponteiro
              animationType: AnimationType.ease, // tipo da animação do ponteiro
              knobStyle: const KnobStyle(
                knobRadius: 0, // Remove a bola no meio
              ),
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Text(
                '$value '
                '$symbol', // o valor que aparece no meio do gauge
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
              angle: 90,
              positionFactor: 0.5,
            ),
          ],
        ),
      ],
    ),
  );
}
