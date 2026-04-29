const express = require('express');
const { sql, connect } = require('./database/connection');

const app = express();
const PORT = 3000;
const contaRoutes = require('./routes/contaRoutes');
const usuarioRoutes = require('./routes/usuarioRoutes');


app.use(express.json());
app.use('/api',contaRoutes);
app.use('/api',usuarioRoutes);


app.use((req, res) => {
    res.status(404).json({ 
        error: 'Rota não encontrada',
        message: `A URL ${req.method} ${req.originalUrl} não existe neste servidor`
    });
});

// Inicia o servidor
app.listen(PORT, async () => {
    await connect();
    console.log(`Servidor rodando em http://localhost:${PORT}`);
});