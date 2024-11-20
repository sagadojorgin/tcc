import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'home.dart';
import 'historico.dart';
import 'configapp.dart';
import 'alarme.dart';
import 'database_helper_config.dart';

double valor = 0;
void main() async {
  // Certifique-se de inicializar os bindings do Flutter antes de qualquer outra coisa
  WidgetsFlutterBinding.ensureInitialized();

  final appController = AppController();
  await appController.loadPreferences();

  // Aguarda a criação do banco de dados antes de rodar o app
  bool isDatabaseReady = await initializeDatabase();

  // Se o banco não estiver pronto, a execução do app é interrompida
  if (isDatabaseReady) {
    runApp(
      ChangeNotifierProvider(
        create: (context) => appController,
        child: MyApp(),
      ),
    );
  } else {
    print(
        'Erro ao criar ou verificar o banco de dados. O app não pode ser iniciado.');
  }
}

Future<bool> initializeDatabase() async {
  final String path = join(await getDatabasesPath(), 'medidas.db');
  try {
    // Tenta abrir o banco de dados e criar as tabelas se necessário
    await openDatabase(
      path,
      version: 1, // Versão inicial do banco de dados
      onCreate: (db, version) async {
        // Criação das tabelas conforme as definições enviadas
        await db.execute('''
          CREATE TABLE IF NOT EXISTS seconds (
            sec_id INTEGER PRIMARY KEY AUTOINCREMENT,
            sec_time INTEGER,
            sec_miliampers REAL,
            sec_volts REAL,
            sec_value_kw REAL
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS minutes (
            min_id INTEGER PRIMARY KEY AUTOINCREMENT,
            min_time INTEGER,
            min_miliampers REAL,
            min_volts REAL,
            min_value_kw REAL
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS hours (
            hour_id INTEGER PRIMARY KEY AUTOINCREMENT,
            hour_datetime INTEGER,
            hour_miliampers REAL,
            hour_volts REAL,
            hour_value_kw REAL
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS last_24_hours (
            lst_hour_id INTEGER PRIMARY KEY AUTOINCREMENT,
            lst_hour_datetime INTEGER,
            lst_hour_miliampers REAL,
            lst_hour_volts REAL,
            lst_hour_value_kw REAL
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS days (
            day_id INTEGER PRIMARY KEY AUTOINCREMENT,
            day_date INTEGER,
            day_ampers REAL,
            day_volts REAL,
            day_value_kw REAL
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS last_30_days (
            lst_day_id INTEGER PRIMARY KEY AUTOINCREMENT,
            lst_day_date INTEGER,
            lst_day_ampers REAL,
            lst_day_volts REAL,
            lst_day_value_kw REAL
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS last_12_months (
            lst_mnt_id INTEGER PRIMARY KEY AUTOINCREMENT,
            lst_mnt_date INTEGER,
            lst_mnt_ampers REAL,
            lst_mnt_volts REAL,
            lst_mnt_value_kw REAL
          );
        ''');
        print("Tabelas criadas com sucesso.");
      },
    );

    print("Banco de dados 'medidas.db' criado com sucesso.");
    return true;
  } catch (e) {
    print("Erro ao tentar abrir ou criar o banco de dados: $e");
    return false;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, appController, child) {
        return MaterialApp(
          theme: ThemeData(
            brightness:
                appController.isDartTheme ? Brightness.dark : Brightness.light,
          ),
          home: HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int myIndex = 0;
  late Timer _timer;

  List<Widget> widgetList = [
    const TelaHome(), // Tela principal
    TelaHistorico(),
    TelaAlarme(), //Text('News', style: TextStyle(fontSize: 40)),
    ConfigPage(), // Tela de histórico
  ];

  @override
  void initState() {
    super.initState();
    startTimer(); // Iniciar o Timer para buscar dados
  }

  // Função para iniciar o Timer e buscar os dados
  void startTimer() {
    const oneSec = Duration(seconds: 1); // A cada 1 segundo
    _timer = Timer.periodic(oneSec, (Timer timer) {
      fetchData(); // Buscar os dados a cada 1 segundo
    });
  }

  // Função que faz a requisição HTTP e insere os dados no banco
  Future<void> fetchData() async {
    // const url = 'http://192.168.0.16/enviar-dados'; // IP do ESP32
    const url = 'http://WattSync.local/enviar-dados'; // LOCAL

    try {
      // Exibe uma mensagem de log indicando que a requisição está sendo feita
      print('Tentando obter dados do servidor...');

      final response =
          await http.get(Uri.parse(url)).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        // Verificando o conteúdo da resposta no terminal
        print('Resposta recebida do servidor: $jsonResponse');

        voltageValue = (jsonResponse['tensao'] as num).toDouble();
        currentValue = (jsonResponse['corrente'] as num).toDouble();
        frequencyValue = (jsonResponse['frequencia'] as num).toDouble();
        isOn = jsonResponse['ligado'];
        wire1 = jsonResponse['Fio1'];
        wire2 = jsonResponse['Fio2'];
        // Exibe os valores recebidos no terminal
        print(
            'Dados recebidos: Tensão: $voltageValue, Corrente: $currentValue, Custo: $valor, Frequência: $frequencyValue');

        // Inserir dados no banco
        await insertData(voltageValue, currentValue, valor, frequencyValue);
      } else {
        // Exibe o erro caso o código de status HTTP não seja 200
        print(
            'Erro ao receber dados. Código de status HTTP: ${response.statusCode}');
      }
    } catch (error) {
      // Exibe a mensagem de erro caso a requisição falhe
      print('Erro ao tentar obter dados do servidor: $error');
    }
  }

  // Função que abre a conexão com o banco de dados
  Future<Database> openDatabaseConnection() async {
    return openDatabase(
      join(await getDatabasesPath(), 'medidas.db'),
      version: 1,
    );
  }

  // Função que insere dados no banco de dados e processa as médias
  Future<void> insertData(
      double tensao, double corrente, double custo, double frequencia) async {
    final Database db = await openDatabaseConnection();

    // Inserir os dados na tabela 'seconds'
    await db.insert(
      'seconds',
      {
        'sec_time': DateTime.now().millisecondsSinceEpoch,
        'sec_miliampers': corrente,
        'sec_volts': tensao,
        'sec_value_kw': custo,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print("Dados inseridos na tabela 'seconds'.");

    // Verificar se há 60 registros na tabela 'seconds'
    final countQuery = await db.rawQuery('SELECT COUNT(*) FROM seconds');
    int count = Sqflite.firstIntValue(countQuery)!;

    // Se houver 60 registros, calcular a média e enviar para a tabela 'minutes'
    if (count >= 60) {
      print("Atingiu 60 registros na tabela 'seconds'. Calculando a média...");

      // Calcular a média dos valores
      final averagesQuery = await db.rawQuery('''
      SELECT AVG(sec_miliampers) AS avg_miliampers,
             AVG(sec_volts) AS avg_volts,
             AVG(sec_value_kw) AS avg_value_kw
      FROM seconds
    ''');

      var averages = averagesQuery.first;
      double avgCurrent =
          (averages['avg_miliampers'] as num?)?.toDouble() ?? 0.0;
      double avgVoltage = (averages['avg_volts'] as num?)?.toDouble() ?? 0.0;
      double avgPower = (averages['avg_value_kw'] as num?)?.toDouble() ?? 0.0;

      print(
          'Média calculada na tabela "seconds": Corrente: $avgCurrent, Tensão: $avgVoltage, Potência: $avgPower');

      // Inserir os dados calculados na tabela 'minutes'
      await db.insert(
        'minutes',
        {
          'min_time': DateTime.now().millisecondsSinceEpoch,
          'min_miliampers': avgCurrent,
          'min_volts': avgVoltage,
          'min_value_kw': avgPower,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print("Média inserida na tabela 'minutes'.");

      // Apagar os 60 registros da tabela 'seconds'
      await db.rawDelete(
          'DELETE FROM seconds WHERE sec_id IN (SELECT sec_id FROM seconds LIMIT 60)');
      print("Registros apagados da tabela 'seconds'.");
    }

    // Verificar se há 60 registros na tabela 'minutes'
    final countMinutesQuery = await db.rawQuery('SELECT COUNT(*) FROM minutes');
    int countMinutes = Sqflite.firstIntValue(countMinutesQuery)!;

    // Se houver 60 registros, calcular a média e enviar para a tabela 'hours'
    if (countMinutes >= 60) {
      print("Atingiu 60 registros na tabela 'minutes'. Calculando a média...");

      // Calcular a média dos valores na tabela 'minutes'
      final minutesAveragesQuery = await db.rawQuery('''
      SELECT AVG(min_miliampers) AS avg_miliampers,
             AVG(min_volts) AS avg_volts,
             AVG(min_value_kw) AS avg_value_kw
      FROM minutes
    ''');

      var minutesAverages = minutesAveragesQuery.first;
      double avgCurrentMinutes =
          (minutesAverages['avg_miliampers'] as num?)?.toDouble() ?? 0.0;
      double avgVoltageMinutes =
          (minutesAverages['avg_volts'] as num?)?.toDouble() ?? 0.0;
      double avgPowerMinutes =
          (minutesAverages['avg_value_kw'] as num?)?.toDouble() ?? 0.0;

      print(
          'Média calculada na tabela "minutes": Corrente: $avgCurrentMinutes, Tensão: $avgVoltageMinutes, Potência: $avgPowerMinutes');

      // Inserir os dados calculados na tabela 'hours'
      await db.insert(
        'hours',
        {
          'hour_datetime': DateTime.now().millisecondsSinceEpoch,
          'hour_miliampers': avgCurrentMinutes,
          'hour_volts': avgVoltageMinutes,
          'hour_value_kw': avgPowerMinutes,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print("Média inserida na tabela 'hours'.");
      // Inserir os dados calculados na tabela 'last_24_hours'
      await db.insert(
        'last_24_hours',
        {
          'lst_hour_datetime': DateTime.now().millisecondsSinceEpoch,
          'lst_hour_volts': avgVoltageMinutes,
          'lst_hour_value_kw': avgPowerMinutes,
          'lst_hour_miliampers': avgCurrentMinutes,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print("Dados inseridos na tabela 'last_24_hours'.");
      // Gerenciar a rotação na tabela 'last_24_hours': excluir o primeiro registro se houver mais de 24
      final countLast24Query =
          await db.rawQuery('SELECT COUNT(*) FROM last_24_hours');
      int countLast24 = Sqflite.firstIntValue(countLast24Query)!;

      if (countLast24 > 24) {
        await db.rawDelete(
            'DELETE FROM last_24_hours WHERE lst_hour_id IN (SELECT lst_hour_id FROM last_24_hours LIMIT 1)');
        print("Registro mais antigo apagado da tabela 'last_24_hours'.");
      }
      // Apagar os 60 registros da tabela 'minutes'
      await db.rawDelete(
          'DELETE FROM minutes WHERE min_id IN (SELECT min_id FROM minutes LIMIT 60)');
      print("Registros apagados da tabela 'minutes'.");
    }

    // Verificar se há 24 registros na tabela 'hours'
    final countHoursQuery = await db.rawQuery('SELECT COUNT(*) FROM hours');
    int countHours = Sqflite.firstIntValue(countHoursQuery)!;

    // Se houver 24 registros, calcular a média e somar os valores de 'hour_miliampers'
    if (countHours >= 24) {
      print("Atingiu 24 registros na tabela 'hours'. Calculando a média...");

      // Calcular a média de todos os valores, exceto 'hour_miliampers'
      final hoursAveragesQuery = await db.rawQuery('''
      SELECT AVG(hour_volts) AS avg_volts,
             AVG(hour_value_kw) AS avg_value_kw,
             SUM(hour_miliampers) AS sum_miliampers
      FROM hours
    ''');

      var hoursAverages = hoursAveragesQuery.first;
      double avgVoltageHours =
          (hoursAverages['avg_volts'] as num?)?.toDouble() ?? 0.0;
      double avgPowerHours =
          (hoursAverages['avg_value_kw'] as num?)?.toDouble() ?? 0.0;
      double sumCurrentHours =
          (hoursAverages['sum_miliampers'] as num?)?.toDouble() ?? 0.0;

      print(
          'Média calculada na tabela "hours": Tensão: $avgVoltageHours, Potência: $avgPowerHours, Soma Corrente: $sumCurrentHours');

      // Inserir os dados calculados na tabela 'days'
      await db.insert(
        'days',
        {
          'day_date': DateTime.now().millisecondsSinceEpoch,
          'day_volts': avgVoltageHours,
          'day_value_kw': avgPowerHours,
          'day_ampers': sumCurrentHours,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print("Média inserida na tabela 'days'.");
      // Inserir os dados calculados na tabela 'last_30_days'
      await db.insert(
        'last_30_days',
        {
          'lst_day_date': DateTime.now().millisecondsSinceEpoch,
          'lst_day_volts': avgVoltageHours,
          'lst_day_value_kw': avgPowerHours,
          'lst_day_ampers': sumCurrentHours,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print("Dados inseridos na tabela 'last_30_days'.");
      // Gerenciar a rotação na tabela 'last_30_days': excluir o primeiro registro se houver mais de 30
      final countLast30Query =
          await db.rawQuery('SELECT COUNT(*) FROM last_30_days');
      int countLast30 = Sqflite.firstIntValue(countLast30Query)!;

      if (countLast30 > 30) {
        await db.rawDelete(
            'DELETE FROM last_30_days WHERE lst_day_id IN (SELECT lst_day_id FROM last_30_days LIMIT 1)');
        print("Registro mais antigo apagado da tabela 'last_30_days'.");
      }
      // Apagar os 24 registros da tabela 'hours'
      await db.rawDelete(
          'DELETE FROM hours WHERE hour_id IN (SELECT hour_id FROM hours LIMIT 24)');
      print("Registros apagados da tabela 'hours'.");
    }

    // Verificar se há 30 registros na tabela 'days'
    final countDaysQuery = await db.rawQuery('SELECT COUNT(*) FROM days');
    int countDays = Sqflite.firstIntValue(countDaysQuery)!;

    // Se houver 30 registros, calcular a média e enviar para a tabela 'last_12_months'
    if (countDays >= 30) {
      print("Atingiu 30 registros na tabela 'days'. Calculando a média...");

      // Calcular a média dos valores na tabela 'days'
      final daysAveragesQuery = await db.rawQuery('''
      SELECT AVG(day_volts) AS avg_volts,
             AVG(day_value_kw) AS avg_value_kw,
             SUM(day_ampers) AS sum_ampers
      FROM days
    ''');

      var daysAverages = daysAveragesQuery.first;
      double avgVoltageDays =
          (daysAverages['avg_volts'] as num?)?.toDouble() ?? 0.0;
      double avgPowerDays =
          (daysAverages['avg_value_kw'] as num?)?.toDouble() ?? 0.0;
      double sumCurrentDays =
          (daysAverages['sum_ampers'] as num?)?.toDouble() ?? 0.0;

      print(
          'Média calculada na tabela "days": Tensão: $avgVoltageDays, Potência: $avgPowerDays, Soma Corrente: $sumCurrentDays');

      // Inserir os dados calculados na tabela 'last_12_months'
      await db.insert(
        'last_12_months',
        {
          'lst_mnt_date': DateTime.now().millisecondsSinceEpoch,
          'lst_mnt_volts': avgVoltageDays,
          'lst_mnt_value_kw': avgPowerDays,
          'lst_mnt_ampers': sumCurrentDays,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print("Média inserida na tabela 'last_12_months'.");

      // Gerenciar a rotação na tabela 'last_12_months': excluir o primeiro registro se houver mais de 12
      final countLast12Query =
          await db.rawQuery('SELECT COUNT(*) FROM last_12_months');
      int countLast12 = Sqflite.firstIntValue(countLast12Query)!;

      if (countLast12 > 12) {
        await db.rawDelete(
            'DELETE FROM last_12_months WHERE lst_mnt_id IN (SELECT lst_mnt_id FROM last_12_months LIMIT 1)');
        print("Registro mais antigo apagado da tabela 'last_12_months'.");
      }

      // Apagar os 30 registros da tabela 'days'
      await db.rawDelete(
          'DELETE FROM days WHERE day_id IN (SELECT day_id FROM days LIMIT 30)');
      print("Registros apagados da tabela 'days'.");
    }
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancelar o timer quando a tela for fechada
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: widgetList[myIndex], // Exibir a tela de acordo com a navegação
      ),
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: false,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color.fromARGB(255, 30, 82, 144)
            : const Color.fromARGB(255, 10, 21, 50),
        selectedItemColor: Color.fromARGB(255, 137, 191, 255),
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            myIndex = index; // Mudar a tela conforme o índice
          });
        },
        currentIndex: myIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_sharp),
            label: 'Histórico',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_sharp),
            label: 'Ativação',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_sharp),
            label: 'Configurações',
          ),
        ],
      ),
    );
  }
}

//Tela Home
class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const TelaHome();
  }
}

// Tela de Histórico
class TelaHistorico extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return HistoricPage(); // Tela de histórico
  }
}

class TelaAlarme extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlarmScreen();
  }
}

class TelaConfig extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ConfigPage();
  }
}

class AppController extends ChangeNotifier {
  bool _isDartTheme = false;
  bool get isDartTheme => _isDartTheme;

  int _consumptionLimit = 0;
  int get consumptionLimit => _consumptionLimit;

  double? _costPerKwh;
  double? get costPerKwh => _costPerKwh;

  Future<void> loadPreferences() async {
    await loadConsumptionLimit();
    await loadThemePreference();
    await loadCostPerKwh(); // Carregar custo do Kw/h
  }

  Future<void> loadConsumptionLimit() async {
    _consumptionLimit = await DatabaseHelper().getConsumptionLimit() ?? 0;
    print("Limite definido: $_consumptionLimit");
    notifyListeners();
  }

  Future<void> setConsumptionLimit(int limit) async {
    _consumptionLimit = limit; // Atualiza o valor localmente

    await DatabaseHelper()
        .saveConsumptionLimit(limit); // Salva no banco de dados
    print("Limite definido: $_consumptionLimit"); // Print do Limite de Consumo
    notifyListeners(); // Notifica para atualizar a interface
  }

  Future<void> loadThemePreference() async {
    _isDartTheme = await DatabaseHelper().getThemePreference();
    print("Preferência de tema carregada: $_isDartTheme"); // Print do valor
    notifyListeners();
  }

  void changeTheme(bool isDart) async {
    _isDartTheme = isDart;
    // Salva a escolha de tema no banco de dados
    await DatabaseHelper().saveThemePreference(isDart);
    print(
        "Preferência de tema carregada: $_isDartTheme"); // Print do valor, false = claro; true = escuro.
    notifyListeners();
  }

  Future<void> loadCostPerKwh() async {
    _costPerKwh = await DatabaseHelper().getCostPerKwh();
    print("Custo do Kilowatt/h: $_costPerKwh");
    notifyListeners();
  }

  Future<void> saveCostPerKwh(double cost) async {
    _costPerKwh = cost;
    valor = cost;
    await DatabaseHelper().saveCostPerKwh(cost);
    print("Custo do Kilowatt/h salvo: $_costPerKwh");
    notifyListeners(); // Atualiza a interface com o novo valor
  }
}
