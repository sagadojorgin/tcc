import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class TelaHistorico extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HistoricPage();
  }
}

class HistoricPage extends StatefulWidget {
  HistoricPage({Key? key}) : super(key: key);

  @override
  HistoricPageState createState() => HistoricPageState();
}

class HistoricPageState extends State<HistoricPage> {
  String dropDownTime = 'Últimas 24h';
  String dropDownType = 'Potência';
  List<_SalesData> data = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startDataRefreshTimer();
  }

  // Função para iniciar o timer e atualizar os dados
  void _startDataRefreshTimer() {
    const duration = Duration(seconds: 10);
    _timer = Timer.periodic(duration, (timer) {
      _fetchData(); // Atualiza os dados periodicamente
    });
  }

  // Função para buscar dados com base no dropdown de tempo e tipo
  Future<void> _fetchData() async {
    final Database db = await openDatabase(
      join(await getDatabasesPath(), 'medidas.db'),
    );

    String table = 'last_24_hours'; // Tabela padrão
    String timeColumn = 'lst_hour_datetime';
    String typeColumn = 'lst_hour_miliampers';
    String voltColumn = 'lst_hour_volts';
    String valueColumn = 'lst_hour_value_kw';

    // Definir a tabela e a consulta baseada no dropdown de tempo
    switch (dropDownTime) {
      case 'Últimas 24h':
        table = 'last_24_hours';
        timeColumn = 'lst_hour_datetime';
        typeColumn = 'lst_hour_miliampers';
        voltColumn = 'lst_hour_volts';
        valueColumn = 'lst_hour_value_kw';
        break;
      case 'Últimos 7 dias':
        table = 'last_30_days';
        timeColumn = 'lst_day_date';
        typeColumn = 'lst_day_ampers';
        voltColumn = 'lst_day_volts';
        valueColumn = 'lst_day_value_kw';
        break;
      case 'Últimos 30 dias':
        table = 'last_30_days';
        timeColumn = 'lst_day_date';
        typeColumn = 'lst_day_ampers';
        voltColumn = 'lst_day_volts';
        valueColumn = 'lst_day_value_kw';
        break;
      case 'Últimos 15 dias':
        table = 'last_30_days';
        timeColumn = 'lst_day_date';
        typeColumn = 'lst_day_ampers';
        voltColumn = 'lst_day_volts';
        valueColumn = 'lst_day_value_kw';
        break;
      case 'Últimos 6 meses':
        table = 'last_12_months';
        timeColumn = 'lst_mnt_date';
        typeColumn = 'lst_mnt_ampers';
        voltColumn = 'lst_mnt_volts';
        valueColumn = 'lst_mnt_value_kw';
        break;
      case 'Últimos 12 meses':
        table = 'last_12_months';
        timeColumn = 'lst_mnt_date';
        typeColumn = 'lst_mnt_ampers';
        voltColumn = 'lst_mnt_volts';
        valueColumn = 'lst_mnt_value_kw';
        break;
      default:
        break;
    }

    // Definir o limite de registros com base no dropdown de tempo
    int limit = getRecordLimit(dropDownTime);

    // Obter registros com base na consulta anterior
    final List<Map<String, dynamic>> records = await db.query(
      table,
      orderBy: '$timeColumn DESC',
      limit: limit,
    );
    // Função para arredondar valores para 2 casas decimais
    double _roundToTwoDecimals(double value) {
      return (value * 100).roundToDouble() / 100;
    }

    setState(() {
      List<_SalesData> groupedData = [];
      double sum = 0;
      int count = 0;

      // Aqui estamos aplicando o agrupamento de dados conforme o intervalo de tempo selecionado
      for (int i = 0; i < records.length; i++) {
        final record = records[i];
        final double value = dropDownType == 'Valor'
            ? _roundToTwoDecimals(
                ((record[voltColumn] ?? 0) * (record[typeColumn] ?? 0) / 1000) *
                    (record[valueColumn] ?? 0))
            : _roundToTwoDecimals(
                ((record[voltColumn] ?? 0) * (record[typeColumn] ?? 0) / 1000));

        sum += value;
        count++;

        // Lógica de agrupamento de dados conforme o tempo selecionado
        if (dropDownTime == 'Últimas 24h') {
          // Para "Últimas 24h", fazemos o agrupamento de 4 em 4 registros
          if (count == 4 || i == records.length - 1) {
            double avgValue = sum / count; // Calcula a média
            String label =
                '${groupedData.length * 4 + 1}h - ${groupedData.length * 4 + 4}h'; // Exibe o intervalo de 4 horas

            groupedData.add(_SalesData(label, avgValue));

            sum = 0;
            count = 0;
          }
        } else if (dropDownTime == 'Últimos 7 dias') {
          // Para "Últimos 7 dias", agrupamos em intervalos de 1 dia
          if (i % 1 == 0 || i == records.length - 1) {
            double avgValue = sum / count;
            String label = '${groupedData.length + 1} dia';

            groupedData.add(_SalesData(label, avgValue));

            sum = 0;
            count = 0;
          }
        } else if (dropDownTime == 'Últimos 15 dias') {
          // Para "Últimos 15 dias", agrupamos em intervalos de 3 dias
          if (i % 3 == 0 || i == records.length - 1) {
            double avgValue = sum / count;
            String label = '${groupedData.length + 1} dia(s)';

            groupedData.add(_SalesData(label, avgValue));

            sum = 0;
            count = 0;
          }
        } else if (dropDownTime == 'Últimos 30 dias') {
          // Para "Últimos 30 dias", agrupamos em intervalos de 5 dias
          if (i % 5 == 0 || i == records.length - 1) {
            double avgValue = sum / count;
            String label = '${groupedData.length + 1} dia(s)';

            groupedData.add(_SalesData(label, avgValue));

            sum = 0;
            count = 0;
          }
        } else if (dropDownTime == 'Últimos 6 meses') {
          // Para "Últimos 6 meses", agrupamos em intervalos de 1 mês
          if (i % 1 == 0 || i == records.length - 1) {
            double avgValue = sum / count;
            String label = '${groupedData.length + 1} mês';

            groupedData.add(_SalesData(label, avgValue));

            sum = 0;
            count = 0;
          }
        } else if (dropDownTime == 'Últimos 12 meses') {
          // Para "Últimos 12 meses", agrupamos em intervalos de 2 meses
          if (i % 2 == 0 || i == records.length - 1) {
            double avgValue = sum / count;
            String label = '${groupedData.length + 1} mês(s)';

            groupedData.add(_SalesData(label, avgValue));

            sum = 0;
            count = 0;
          }
        }
      }

      data = groupedData;

      // Verifica se os dados são suficientes para o limite, senão não preenche com "N/A"
      if (data.length < limit) {
        int missingDataCount = limit - data.length;
        // Não preenche com dados "N/A" se não houver dados suficientes
        // Nesse caso, você pode apenas limitar os dados ou ajustar o comportamento de exibição
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelar o timer ao descartar o widget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico de consumo',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color.fromARGB(255, 30, 82, 144)
            : const Color.fromARGB(255, 10, 21, 50),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  DropdownMenuTime(
                    onChanged: (value) {
                      setState(() {
                        dropDownTime = value;
                        _fetchData(); // Recarrega os dados ao mudar a opção
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  DropdownMenuType(
                    onChanged: (value) {
                      setState(() {
                        dropDownType = value;
                        _fetchData(); // Recarrega os dados ao mudar a opção
                      });
                    },
                  ),
                ],
              ),
            ),
            data.isEmpty
                ? const Center(child: Text("Nenhum dado disponível"))
                : SfCartesianChart(
                    primaryXAxis: CategoryAxis(
                      labelStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[500]
                            : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      labelStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[500]
                            : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    title: ChartTitle(
                      text: 'Histórico de Consumo',
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    legend: Legend(
                      isVisible: true,
                      textStyle: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    tooltipBehavior: TooltipBehavior(enable: true),
                    series: <CartesianSeries<_SalesData, String>>[
                      LineSeries<_SalesData, String>(
                        dataSource: data,
                        xValueMapper: (_SalesData sales, _) => sales.label,
                        yValueMapper: (_SalesData sales, _) => sales.value,
                        name: 'Consumo',
                        color: const Color.fromARGB(255, 116, 50, 157),
                        dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            textStyle: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        markerSettings: const MarkerSettings(
                          isVisible: true,
                          shape: DataMarkerType.circle,
                          color: Color.fromARGB(255, 116, 50, 157),
                        ),
                      )
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // Função para obter o número de registros com base no tempo selecionado
  int getRecordLimit(String dropDownTime) {
    switch (dropDownTime) {
      case 'Últimas 24h':
        return 24; // Últimas 24 horas
      case 'Últimos 7 dias':
        return 7; // Últimos 7 dias
      case 'Últimos 15 dias':
        return 15; // Últimos 15 dias
      case 'Últimos 30 dias':
        return 30; // Últimos 30 dias
      case 'Últimos 6 meses':
        return 6; // Últimos 6 meses
      case 'Últimos 12 meses':
        return 12; // Últimos 12 meses
      default:
        return 24; // Valor padrão (quando o tempo não é especificado)
    }
  }
}

// Model para armazenar as informações de gráfico
class _SalesData {
  _SalesData(this.label, this.value);

  final String label;
  final double value;
}

// Dropdown de tempo
class DropdownMenuTime extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const DropdownMenuTime({super.key, required this.onChanged});

  @override
  State<DropdownMenuTime> createState() => _DropdownMenuTimeState();
}

const List<String> timeOptions = <String>[
  'Últimas 24h',
  'Últimos 7 dias',
  'Últimos 15 dias',
  'Últimos 30 dias',
  'Últimos 6 meses',
  'Últimos 12 meses'
];

class _DropdownMenuTimeState extends State<DropdownMenuTime> {
  String selectedValue = timeOptions.first;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedValue,
      onChanged: (String? newValue) {
        setState(() {
          selectedValue = newValue!;
        });
        widget.onChanged(selectedValue);
      },
      items: timeOptions.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontSize: 20,
              )),
        );
      }).toList(),
      icon: Icon(
        Icons.arrow_downward,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
      ),
      iconSize: 24,
    );
  }
}

// Dropdown de tipo de dados (Potência ou Corrente)
class DropdownMenuType extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const DropdownMenuType({super.key, required this.onChanged});

  @override
  State<DropdownMenuType> createState() => _DropdownMenuTypeState();
}

const List<String> typeOptions = <String>['Potência', 'Valor'];

class _DropdownMenuTypeState extends State<DropdownMenuType> {
  String selectedType = typeOptions.first;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedType,
      onChanged: (String? newValue) {
        setState(() {
          selectedType = newValue!;
        });
        widget.onChanged(selectedType);
      },
      items: typeOptions.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontSize: 20,
              )),
        );
      }).toList(),
      icon: Icon(
        Icons.arrow_downward,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
      ),
      iconSize: 24,
    );
  }
}
