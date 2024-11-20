import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'medidor.dart';

bool animation =
    true; // isso aqui se colocar false desliga todas as animações dos medidores, tem que fazer para o gráfico tbm
double currentValue = 0; //isso vem do main
double voltageValue = 0; //isso tbm
double powerValue = 0; //isso dá para fazer aqui
double frequencyValue = 0; //tbm vem
bool isOn = false; //vem
bool wire1 = false; //vem
bool wire2 = false; //vem
Timer? _timer;

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const TelaHome();
  }
}

class TelaHome extends StatefulWidget {
  const TelaHome({super.key});

  @override
  State<TelaHome> createState() => _TelaHomeState();
}

class _TelaHomeState extends State<TelaHome> {
  List<Map<String, dynamic>> dataList = [];
  double totalConsumption = 0.0; // Para armazenar o consumo total
  String texto1 = "";
  String texto2 = "";
  bool determinante = false;
  TextStyle textStyle1 = const TextStyle(color: Colors.black, fontSize: 14);
  TextStyle textStyle2 = const TextStyle(color: Colors.black, fontSize: 14);

  void typeOfWire() {
    determinante = !wire1 && !wire2;
    if (determinante) {
      texto1 = 'Nenhuma rede identificada.';
      texto2 = '';
      textStyle1 = const TextStyle(
          color: /*Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : */
              Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold);
      textStyle2 = const TextStyle(
          color: /*Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : */
              Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold);
    } else {
      if (wire1) {
        texto1 = "Fase";
        textStyle1 = const TextStyle(
            color: /*Theme.of(context).brightness == Brightness.dark
                ? Color.fromARGB(255, 255, 137, 137)
                : */
                Color.fromARGB(255, 129, 11, 11),
            fontSize: 16,
            fontWeight: FontWeight.bold);
      }
      if (!wire1) {
        texto1 = 'Neutro';
        textStyle1 = const TextStyle(
            color: /*Theme.of(context).brightness == Brightness.dark
                ? Color.fromARGB(255, 137, 191, 255)
                : */
                Color.fromARGB(255, 30, 82, 144),
            fontSize: 16,
            fontWeight: FontWeight.bold);
      }
      if (wire2) {
        texto2 = ' Fase';
        textStyle2 = const TextStyle(
            color: /*Theme.of(context).brightness == Brightness.dark
                ? Color.fromARGB(255, 255, 137, 137)
                : */
                Color.fromARGB(255, 129, 11, 11),
            fontSize: 16,
            fontWeight: FontWeight.bold);
      }
      if (!wire2) {
        texto2 = ' Neutro';
        textStyle2 = const TextStyle(
            color: /*Theme.of(context).brightness == Brightness.dark
                ? Color.fromARGB(255, 137, 191, 255)
                : */
                Color.fromARGB(255, 30, 82, 144),
            fontSize: 16,
            fontWeight: FontWeight.bold);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDataList(); // Buscar dados do banco assim que a tela for carregada
    startTimer();
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      fetchDataList().then((_) async {
        if (!mounted) return;
        setState(() {
          powerValue = (currentValue * voltageValue);
          typeOfWire();
        });
      });
    });
  }

  Future<Database> openDatabaseConnection() async {
    return openDatabase(
      join(await getDatabasesPath(), 'medidas.db'),
      version: 1,
    );
  }

  double totalGastoReais = 0.0;
  Future<void> fetchDataList() async {
    final Database db =
        await openDatabaseConnection(); // Abre a conexão com o banco

    // Nome da tabela e colunas a serem usadas para os últimos 30 dias
    String table = 'last_30_days';
    String typeColumn = 'lst_day_ampers'; // Corrente em amperes
    String voltColumn = 'lst_day_volts'; // Tensão em volts
    String valueColumn =
        'lst_day_value_kw'; // aqui é melhor, puxa diretamente da tabela, ignora aquele debaixo

    // Definir o valor do kWh em reais (exemplo: 0.60 reais por kWh)
    double precoKWh =
        0.85; //isso aqui vem da config, que deve ser inserida no banco tbm, mas isso faz dps

    // Obter registros dos últimos 30 dias
    final List<Map<String, dynamic>> records = await db.query(
      table,
      orderBy: 'lst_day_date DESC',
      limit: 30, // Considera os últimos 30 registros
    );

    double totalGastoReais = 0.0;
    double sum = 0;
    int count = 0;

    // Agrupando e calculando o valor total em reais (similar ao agrupamento feito no histórico)
    for (int i = 0; i < records.length; i++) {
      final record = records[i];

      // Cálculo da potência (kWh) - considerando amperes e voltagem
      double amperes = record[typeColumn] ?? 0.0;
      double volts = record[voltColumn] ?? 0.0;
      double horas =
          1; // Ajuste o tempo conforme necessário (aqui foi assumido 1 hora)

      double consumoKWh = (amperes * volts * horas) / 1000; // Consumo em kWh

      // Se estiver calculando o valor, multiplica pelo preço do kWh
      double valorGasto = consumoKWh * precoKWh;

      sum += valorGasto;
      count++;

      // Se for necessário agrupar (como no histórico, por exemplo, a cada 5 registros)
      if (count == 5 || i == records.length - 1) {
        // Aqui você pode usar o sum e gerar uma média ou fazer outra lógica de agrupamento
        totalGastoReais += sum;
        sum = 0;
        count = 0;
      }
    }

    // Aqui, em vez de retornar diretamente o valor formatado, deixamos o cálculo pronto
    // A formatação será feita ao usá-lo.

    // Exemplo de uso direto da formatação
  }

  @override
  Widget build(BuildContext context) {
    // Calcula a largura do padding lateral
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = screenWidth * 0.05;

    // Determina a cor baseada no tema
    final Color backgroundColor =
        Theme.of(context).brightness == Brightness.dark
            ? const Color.fromARGB(255, 30, 82, 144)
            : const Color.fromARGB(255, 10, 21, 50);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WattSync',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
      ),
      body: Column(
        mainAxisSize:
            MainAxisSize.min, // Adicionado para evitar altura infinita
        children: [
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
            ),
            height: 150,
            child: Stack(
              children: [
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25.0),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Color.fromARGB(255, 10, 21, 50)
                          : Color.fromARGB(255, 30, 82, 144),
                    ),
                    width: 360,
                    height: 120,
                    padding: const EdgeInsets.only(top: 12.0, left: 25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Seu consumo nos últimos 30 dias foi:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'R\$ ${totalGastoReais.toStringAsFixed(2)}', // Consumindo valor calculado
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            height: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.0),
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color.fromARGB(255, 30, 31, 28)
                  : const Color.fromARGB(255, 235, 235, 235),
            ),
            width: 360,
            height: 60,
            padding: EdgeInsets.only(left: 20.0, right: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Tipo de rede:',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8.0), // Espaçamento entre os textos
                // Abaixo, uma listagem dos dados recebidos do banco
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        texto1,
                        style: textStyle1,
                      ),
                      if (texto1.isNotEmpty && texto2.isNotEmpty)
                        Text(
                          ' - ',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      Text(
                        texto2,
                        style: textStyle2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25.0),
              child: Column(
                mainAxisSize: MainAxisSize
                    .min, // Garantir que o Column não use altura infinita
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 2.0,
                    mainAxisSpacing: 2.0,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: MediaQuery.of(context).size.width /
                        (MediaQuery.of(context).size.height * 0.52),
                    children: [
                      Container(
                        alignment: Alignment.center,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color.fromARGB(255, 30, 31, 28)
                            : const Color.fromARGB(255, 235, 235, 235),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ('Tensão'),
                                style: TextStyle(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              medidor(
                                  Colors.blue,
                                  Colors.purple,
                                  0,
                                  240,
                                  voltageValue, // Atualiza para usar a tensão recebida
                                  animation,
                                  "V"),
                            ]),
                      ),
                      Container(
                        alignment: Alignment.center,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color.fromARGB(255, 30, 31, 28)
                            : const Color.fromARGB(255, 235, 235, 235),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ('Corrente'),
                                style: TextStyle(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              medidor(
                                  Colors.red,
                                  Colors.orange,
                                  0,
                                  16,
                                  currentValue, // Atualiza para usar a corrente recebida
                                  animation,
                                  "A"),
                            ]),
                      ),
                      Container(
                        alignment: Alignment.center,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color.fromARGB(255, 30, 31, 28)
                            : const Color.fromARGB(255, 235, 235, 235),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ('Potência'),
                                style: TextStyle(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              medidor(Colors.green, Colors.yellow, 0, 4000,
                                  powerValue, animation, "W"),
                            ]),
                      ),
                      Container(
                        alignment: Alignment.center,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color.fromARGB(255, 30, 31, 28)
                            : const Color.fromARGB(255, 235, 235, 235),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ('Frequência'),
                                style: TextStyle(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              medidor(Colors.purple, Colors.pink, 0, 80,
                                  frequencyValue, animation, "Hz"),
                            ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
