import 'package:flutter/material.dart';

//CONSTRUIÇÃO DA TELA DO CELULAR
bool temadispositivo = false;

class configDispositivo extends StatefulWidget {
  @override
  State<configDispositivo> createState() => configDispositivoState();
}

class configDispositivoState extends State<configDispositivo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white, // Define a cor do ícone de volta (seta)
          ),
          title: Text(
            "Configurações do Dispositivo",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color.fromARGB(255, 30, 82, 144)
              : const Color.fromARGB(255, 10, 21, 50),
        ),
        body: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ALTERAR TEMA CLARO E ESCURO

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
                              groupValue: temadispositivo,
                              fillColor: MaterialStateProperty.all<Color>(
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              onChanged: (bool? value) {
                                if (value != null) {
                                  setState(() {
                                    temadispositivo =
                                        value; // Altera o valor de temadispositivo diretamente
                                  });
                                }
                              },
                            ),
                            Radio<bool>(
                              value: true,
                              groupValue: temadispositivo,
                              fillColor: MaterialStateProperty.all<Color>(
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                              onChanged: (bool? value) {
                                if (value != null) {
                                  setState(() {
                                    temadispositivo = value;
                                  });
                                }
                              },
                            ),
                          ],
                        )
                      ]),
                ),
              ),

              //ESPAÇAMENTO
              Container(
                height: 50,
              ),

              //ATIVAR OU DESATIVAR O DISPLAY COM SWITCH

              Padding(
                padding: const EdgeInsets.only(left: 50.0, bottom: 8.0),
                child: Text(
                  "Ativar ou Desativar o Display",
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
              ),

              Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      width: 400,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: CustomSwitch(),
                      ),
                    ),
                  )),

              //ESPAÇAMENTO
              Container(
                height: 50,
              ),

              //BOTÃO DESCONECTAR DISPOSITIVO DO APP

              Align(
                child: SizedBox(
                  height: 50.0,
                  width: 300.0,
                  child: ElevatedButton(
                    onPressed: () {
                      _showConfirmationDialog(context);
                    },
                    child: Text(
                      "Desconectar Dispositivo",
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
        ));
  }
}

//SWITCH ATIVAR OU DESATIVAR

class CustomSwitch extends StatefulWidget {
  const CustomSwitch({super.key});

  @override
  State<CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch> {
  bool light = false;

  @override
  Widget build(BuildContext context) {
    return Switch(
      // This bool value toggles the switch.
      value: light,
      activeColor: Colors.white,
      inactiveTrackColor: Colors.grey[700],
      inactiveThumbColor: Colors.white,
      activeTrackColor: Theme.of(context).brightness == Brightness.dark
          ? Color.fromARGB(255, 137, 191, 255)
          : Color.fromARGB(255, 30, 82, 144),
      onChanged: (bool value) {
        // This is called when the user toggles the switch.
        setState(() {
          light = value;
        });
      },
    );
  }
}

//SLIDER CONTROLE DE LUMINOSIDADE

class BrightnessSlider extends StatefulWidget {
  @override
  _BrightnessSliderState createState() => _BrightnessSliderState();
}

class _BrightnessSliderState extends State<BrightnessSlider> {
  double _currentBrightness = 0.5;

  Widget build(BuildContext context) {
    return Slider(
      value: _currentBrightness,
      onChanged: (double value) {
        setState(() {
          _currentBrightness = value;
        });
      },
      activeColor: Theme.of(context).brightness == Brightness.dark
          ? Color.fromARGB(255, 137, 191, 255)
          : Color.fromARGB(255, 30, 82, 144),
      inactiveColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : Colors.black,
    );
  }
}

//DESCONECTAR DISPOSITIVO

void _showConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirmação'),
        content: Text('Deseja desconectar o dispositivo?'),
        actions: <Widget>[
          TextButton(
            child: Text('Não'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Sim'),
            onPressed: () {
              // TODO: Adicionar lógica para desconectar o dispositivo
              // Navigator.of(context).pushAndRemoveUntil(
              //  MaterialPageRoute(builder: (context) => TelaLogin()),
              // (Route<dynamic> route) => false,
              //);
            },
          ),
        ],
      );
    },
  );
}

/* PALETA DE CORES APP

Azul claro #89BFFF = Color.fromARGB(255, 137, 191, 255)
Azul #1E5290 = Color.fromARGB(255, 30, 82, 144)
Azul escuro #0A1532 = Color.fromARGB(255, 10, 21, 50)
Roxo claro #74329D = Color.fromARGB(255, 116, 50, 157)
Roxo escuro #420E54 = Color.fromARGB(255, 66, 14, 84)

*/