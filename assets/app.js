const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const bodyParser = require('body-parser');
const app = express();
const port = 3000;


// Middleware para processar JSON no corpo das requisições
app.use(bodyParser.json());

// Exemplo de rota GET para obter alarmes
app.get('/alarms', (req, res) => {
    const alarms = [
      { id: 1, start_time: '05:30', end_time: '14:30', weekdays: 'Mon,Wed,Fri', is_active: true },
      { id: 2, start_time: '06:00', end_time: '15:00', weekdays: 'Tue,Thu', is_active: false }
    ];
    res.json(alarms);
  });
  
// Conexão com o banco de dados SQLite
const db = new sqlite3.Database('G:/ETEC Raposo Tavares/3ºDS/DTCC/WattSyncDBSQLite.sqbpro');

// Endpoint para adicionar um novo alarme
app.post('/alarmes', (req, res) => {
    const { start_time, end_time, weekdays, is_active } = req.body;
  
    // Verificar se todos os campos obrigatórios estão presentes
    if (!start_time || !end_time || !weekdays) {
      return res.status(400).json({ error: 'Dados incompletos' });
    }
  
    // Inserir os dados do alarme no banco de dados
    const weekdaysString = weekdays.join(','); // Armazenar os dias da semana como string separada por vírgulas
    const isActiveInt = is_active ? 1 : 0; // Converter booleano para inteiro (0 ou 1)
  
    db.run(
      `INSERT INTO alarmes (start_time, end_time, weekdays, is_active) VALUES (?, ?, ?, ?)`,
      [start_time, end_time, weekdaysString, isActiveInt],
      function (err) {
        if (err) {
          return res.status(500).json({ error: err.message });
        }
        // Retornar sucesso com o ID do novo alarme
        res.status(201).json({ id: this.lastID });
      }
    );
  });
  
  // Iniciar o servidor
  app.listen(PORT, () => {
    console.log(`Servidor rodando em http://localhost:${PORT}`);
  });