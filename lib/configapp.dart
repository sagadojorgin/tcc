import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wattsync/configdispositivo.dart';
import 'package:flutter/services.dart';
import 'database_helper_config.dart';
import 'main.dart';

/*void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appController = AppController();
  await appController.loadPreferences(); // Carrega as preferências

  runApp(
    ChangeNotifierProvider(
      create: (context) => appController,
      child: TelaConfigApp(),
    ),
  );
}*/

class TelaConfigApp extends StatelessWidget {
  const TelaConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppController>(
      builder: (context, appController, child) {
        return MaterialApp(
          theme: ThemeData(
            brightness:
                appController.isDartTheme ? Brightness.dark : Brightness.light,
          ),
          home: ConfigPage(),
        );
      },
    );
  }
}

class ConfigPage extends StatelessWidget {
  ConfigPage();

  @override
  Widget build(BuildContext context) {
    int consumptionLimit = Provider.of<AppController>(context).consumptionLimit;
    double costPerKwh = Provider.of<AppController>(context).costPerKwh ?? 0.0;

    // Controlador para o TextField
    TextEditingController _costController =
        TextEditingController(text: costPerKwh.toString());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Configurações",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color.fromARGB(255, 30, 82, 144)
            : const Color.fromARGB(255, 10, 21, 50),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              //ALTERAR TEMA CLARO OU ESCURO

              Padding(
                padding: const EdgeInsets.only(left: 50.0, bottom: 8.0),
                child: Text(
                  "Tema",
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
              ),

              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  height: 250,
                  width: 400,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[850]
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[300]
                                    : Colors.grey[600],
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15.0)),
                              ),
                            ),
                            Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[300]
                                    : Colors.grey[600],
                                borderRadius:
                                    BorderRadius.all(Radius.circular(15.0)),
                              ),
                            )
                          ],
                        ),
                        Container(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              "Claro",
                              style: TextStyle(
                                  fontSize: 20.0, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Escuro",
                              style: TextStyle(
                                  fontSize: 20.0, fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Radio<bool>(
                                value: false,
                                groupValue: Provider.of<AppController>(context)
                                    .isDartTheme,
                                onChanged: (bool? value) {
                                  Provider.of<AppController>(context,
                                          listen: false)
                                      .changeTheme(false);
                                },
                              ),
                              Radio<bool>(
                                value: true,
                                groupValue: Provider.of<AppController>(context)
                                    .isDartTheme,
                                onChanged: (bool? value) {
                                  Provider.of<AppController>(context,
                                          listen: false)
                                      .changeTheme(true);
                                },
                              ),
                            ]),
                      ]),
                ),
              ),

              //ESPAÇAMENTO
              Container(
                height: 50,
              ),

              //CUSTO DO KILOWATT/H
              Padding(
                padding: const EdgeInsets.only(left: 50.0, bottom: 8.0),
                child: Text(
                  "Custo do Kilowatt (Kw/h)",
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
              ),

              Center(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    width: 400,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[850]
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white // Cor do texto para tema escuro
                            : Colors.black, // Cor do texto
                        fontSize: 18, // Tamanho da fonte
                        fontWeight: FontWeight.bold, // Peso da fonte
                      ),
                      controller: _costController,
                      decoration: InputDecoration(
                        hintText: 'Digite o valor',
                        // Retira a barrinha roxa (outline) no foco
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none, // Remove a borda roxa
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide
                              .none, // Remove a borda quando o campo não está em foco
                        ),
                      ),
                      onChanged: (value) {
                        double? enteredValue = double.tryParse(value);
                        if (enteredValue != null) {
                          costPerKwh = enteredValue;
                        }
                      },
                    ),
                  ),
                ),
              ),

              //ESPAÇAMENTO
              SizedBox(
                height: 10,
              ),

              //BOTÃO SALVAR AS ALTERAÇÕES DO KILOWATT/H
              Align(
                child: SizedBox(
                  height: 50.0,
                  width: 200.0,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Salva o custo do kilowatt/h no banco de dados
                      await DatabaseHelper().saveCostPerKwh(costPerKwh);

                      // Atualiza o estado do AppController para refletir a mudança
                      Provider.of<AppController>(context, listen: false)
                          .saveCostPerKwh(costPerKwh);

                      // Atualize a interface com o novo valor
                      print("Custo do Kilowatt por hora salvo: $costPerKwh");
                    },
                    child: Text('Salvar', style: TextStyle(fontSize: 20.0)),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850] ??
                                Colors
                                    .grey // Adicionando ?? Colors.grey para garantir que não seja nulo
                            : Colors.grey[350] ??
                                Colors
                                    .grey, // Adicionando ?? Colors.grey para garantir que não seja nulo
                      ),
                      foregroundColor: MaterialStateProperty.all<Color>(
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white // Cor do texto para tema escuro
                            : Colors.black, // Cor do texto para tema claro
                      ),
                    ),
                  ),
                ),
              ),

              //ESPAÇAMENTO
              Container(
                height: 50,
              ),

              //BOTÃO DEFINIR LIMITE DE CONSUMO
              Align(
                child: SizedBox(
                  height: 50.0,
                  width: 300.0,
                  child: ElevatedButton(
                    onPressed: () {
                      _showLimitAdjustmentDialog(context, consumptionLimit);
                    },
                    child: Text(
                      "Definir limite de consumo",
                      style: TextStyle(fontSize: 20.0),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Theme.of(context).brightness == Brightness.dark
                            ? Color.fromARGB(255, 66, 14, 84)
                            : Color.fromARGB(255, 116, 50, 157),
                      ),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                    ),
                  ),
                ),
              ),

              //ESPAÇAMENTO
              SizedBox(height: 16),

              //BOTÃO CONFIGURAÇÕES DO DISPOSITIVO
              Align(
                child: SizedBox(
                  height: 50.0,
                  width: 350.0,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => configDispositivo()),
                      );
                    },
                    child: Text(
                      "Configurações do Dispositivo",
                      style: TextStyle(fontSize: 20.0),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Theme.of(context).brightness == Brightness.dark
                            ? Color.fromARGB(255, 66, 14, 84)
                            : Color.fromARGB(255, 116, 50, 157),
                      ),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showLimitAdjustmentDialog(BuildContext context, int currentLimit) {
  int selectedLimit = currentLimit; // Inicia com o valor atual
  TextEditingController limitController =
      TextEditingController(text: '$currentLimit');

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Definir Limite de Consumo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Limite de consumo atual: $currentLimit',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Text(
                  'Ajuste o valor entre 0 e 3600',
                  style: TextStyle(
                    fontSize: 15,
                  ),
                ),
                Slider(
                  value: selectedLimit.toDouble(),
                  min: 0,
                  max: 3600,
                  divisions: 3600,
                  label: '$selectedLimit',
                  onChanged: (value) {
                    setState(() {
                      selectedLimit = value.toInt();
                      limitController.text = selectedLimit.toString();
                    });
                  },
                ),
                TextField(
                  controller: limitController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Digite o valor do limite',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    int? enteredValue = int.tryParse(value);
                    if (enteredValue != null &&
                        enteredValue >= 0 &&
                        enteredValue <= 3600) {
                      setState(() {
                        selectedLimit = enteredValue;
                      });
                    } else if (enteredValue != null && enteredValue > 3600) {
                      limitController.text = '3600'; // Limita o valor ao máximo
                      limitController.selection = TextSelection.fromPosition(
                          TextPosition(offset: limitController.text.length));
                    }
                  },
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Cancelar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Confirmar'),
                onPressed: () async {
                  // Salva o limite usando o método `setConsumptionLimit` no controlador
                  await Provider.of<AppController>(context, listen: false)
                      .setConsumptionLimit(selectedLimit);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    },
  );
}
