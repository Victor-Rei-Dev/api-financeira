const sql = require('mssql');
require('dotenv').config();

const config = {
    server: process.env.DB_SERVER,
    port: 1433,
    database: process.env.DB_DATABASE,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    options: {
        encrypt: false,
        trustServerCertificate: true
    }
};

async function connect() {
    try {
        await sql.connect(config);
        console.log('Conectado ao SQL Server');
        return true;
    } catch (err) {
        console.error('Erro ao conectar:', err.message);
        return false;
    }
}

module.exports = { sql, connect };