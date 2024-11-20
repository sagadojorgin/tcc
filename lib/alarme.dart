import 'package:flutter/material.dart';
import 'database_helper.dart';

class AlarmScreen extends StatefulWidget {
  @override
  _AlarmScreenState createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _alarms = [];

  @override
  void initState() {
    super.initState();
    _fetchAlarms();
  }

  String _getSelectedDays(Map<String, dynamic> alarm) {
    List<String> selectedDays = [];
    if (alarm['seg'] == 1) selectedDays.add('Segunda');
    if (alarm['ter'] == 1) selectedDays.add('Terça');
    if (alarm['qua'] == 1) selectedDays.add('Quarta');
    if (alarm['qui'] == 1) selectedDays.add('Quinta');
    if (alarm['sex'] == 1) selectedDays.add('Sexta');
    if (alarm['sab'] == 1) selectedDays.add('Sábado');
    if (alarm['dom'] == 1) selectedDays.add('Domingo');
    return selectedDays.join(', ');
  }

  Future<void> _fetchAlarms() async {
    final List<Map<String, dynamic>> alarms = await _dbHelper.getAllAlarms();
    print('Alarmes recuperados do banco de dados: $alarms');
    setState(() {
      _alarms = alarms;
    });
  }

  Future<void> _updateAlarmStatus(int id, int isActive) async {
    Map<String, dynamic> updatedAlarm = {'is_active': isActive};
    await _dbHelper.updateAlarm(id, updatedAlarm);
    _fetchAlarms();
  }

  Future<void> _addAlarm() async {
    Map<String, dynamic> newAlarm = {
      'start_time': '00:00',
      'end_time': '00:00',
      'seg': 1,
      'ter': 1,
      'qua': 1,
      'qui': 1,
      'sex': 1,
      'sab': 0,
      'dom': 0,
      'is_active': 1,
    };
    await _dbHelper.insertAlarm(newAlarm);
    _fetchAlarms();
  }

  Future<void> _updateAlarmTime(int id, String field, TimeOfDay time) async {
    final formattedTime = time.format(context);
    Map<String, dynamic> updatedAlarm = {field: formattedTime};
    await _dbHelper.updateAlarm(id, updatedAlarm);
    _fetchAlarms();
  }

  Future<void> _updateAlarmDay(int id, String day, int isSelected) async {
    Map<String, dynamic> updatedAlarm = {day: isSelected};
    await _dbHelper.updateAlarm(id, updatedAlarm);
    _fetchAlarms();
  }

  Future<void> _selectTime(
      BuildContext context, int id, String field, String currentTime) async {
    final timeParts = currentTime.split(":");
    TimeOfDay initialTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime != null) {
      await _updateAlarmTime(id, field, pickedTime);
    }
  }

  Future<void> _deleteAlarm(int id) async {
    // Fazer uma cópia da lista de alarmes
    List<Map<String, dynamic>> alarmsCopy = List.from(_alarms);

    // Remover da lista copiada
    alarmsCopy.removeWhere((alarm) => alarm['id'] == id);

    // Atualizar o estado com a nova lista
    setState(() {
      _alarms = alarmsCopy;
    });

    final db = await _dbHelper.database;

    // Excluir o alarme do banco de dados
    int result = await db.delete(
      'alarms',
      where: 'id = ?',
      whereArgs: [id],
    );

    print('Alarme excluído: ID $id, Resultado $result');

    // Resetar o contador do ID após a exclusão
    await db.rawUpdate(
        '''UPDATE sqlite_sequence SET seq = 0 WHERE name = 'alarms';''');

    // Reordenar os IDs dos alarmes restantes para garantir sequência contínua
    List<Map<String, dynamic>> remainingAlarms =
        await db.query('alarms', orderBy: 'id ASC');

    for (int i = 0; i < remainingAlarms.length; i++) {
      int newId = i + 1;
      int currentId = remainingAlarms[i]['id'];

      if (currentId != newId) {
        await db.update(
          'alarms',
          {'id': newId},
          where: 'id = ?',
          whereArgs: [currentId],
        );
      }
    }

    // Recarregar a lista de alarmes após a exclusão
    _fetchAlarms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gerenciador de Ativação',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color.fromARGB(255, 30, 82, 144)
            : const Color.fromARGB(255, 10, 21, 50),
      ),
      body: ListView.builder(
        itemCount: _alarms.length,
        itemBuilder: (context, index) {
          final alarm = _alarms[index];
          return Dismissible(
            key: Key(alarm['id'].toString()),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) async {
              await _deleteAlarm(alarm['id']);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Alarme excluído')),
              );
            },
            background: Container(
              color: Colors.red,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
              ),
            ),
            child: Card(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Color.fromARGB(255, 66, 14, 84)
                  : Color.fromARGB(255, 116, 50, 157),
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Alarme Programado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        Switch(
                          value: alarm['is_active'] == 1,
                          onChanged: (value) {
                            int isActive = value ? 1 : 0;
                            _updateAlarmStatus(alarm['id'], isActive);
                          },
                          activeColor: Colors.white,
                          inactiveTrackColor: Colors.grey[300],
                          inactiveThumbColor: Colors.white,
                          activeTrackColor:
                              Theme.of(context).brightness == Brightness.dark
                                  ? const Color.fromARGB(255, 30, 82, 144)
                                  : const Color.fromARGB(255, 137, 191, 255),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0, right: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => _selectTime(context, alarm['id'],
                                'start_time', alarm['start_time']),
                            child: Row(
                              children: [
                                Text('DE:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                    )),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  alarm['start_time'],
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _selectTime(context, alarm['id'],
                                'end_time', alarm['end_time']),
                            child: Row(
                              children: [
                                Text('ATÉ:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                    )),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  alarm['end_time'],
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 22,
                      children: [
                        _buildEditableDayChip(
                            alarm['id'], 'D', 'dom', alarm['dom'] == 1),
                        _buildEditableDayChip(
                            alarm['id'], 'S', 'seg', alarm['seg'] == 1),
                        _buildEditableDayChip(
                            alarm['id'], 'T', 'ter', alarm['ter'] == 1),
                        _buildEditableDayChip(
                            alarm['id'], 'Q', 'qua', alarm['qua'] == 1),
                        _buildEditableDayChip(
                            alarm['id'], 'Q', 'qui', alarm['qui'] == 1),
                        _buildEditableDayChip(
                            alarm['id'], 'S', 'sex', alarm['sex'] == 1),
                        _buildEditableDayChip(
                            alarm['id'], 'S', 'sab', alarm['sab'] == 1),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAlarm,
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Color.fromARGB(255, 66, 14, 84)
            : Color.fromARGB(255, 116, 50, 157),
        foregroundColor:
            Colors.white, // Cor do ícone (ajuste conforme desejado)
      ),
    );
  }

  Widget _buildEditableDayChip(
      int id, String label, String day, bool isSelected) {
    return GestureDetector(
      onTap: () {
        int newSelectedState = isSelected ? 0 : 1;
        _updateAlarmDay(id, day, newSelectedState);
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (Theme.of(context).brightness == Brightness.dark
                  ? const Color.fromARGB(255, 30, 82, 144)
                  : const Color.fromARGB(255, 137, 191, 255))
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black)
                : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}
