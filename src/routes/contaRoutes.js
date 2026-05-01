const express = require('express');
const router = express.Router();


const { transferir, extrato, depositarSaldo, buscarConta, deletarConta, atualizarLimite } = require('../controllers/contaController');
const { route } = require('./usuarioRoutes');
const { verificarToken } = require('../middlewares/auth');

router.post('/transferir/:id_enviador', verificarToken, transferir);
router.get('/extrato/:id_conta', verificarToken, extrato);
router.get('/buscarConta/:id_conta', verificarToken, buscarConta);
router.delete('/deletarConta/:id_conta', verificarToken, deletarConta);
router.patch('/atualizarLimite/:id_conta', verificarToken, atualizarLimite);
router.patch('/depositarSaldo/:id_conta', verificarToken, depositarSaldo);


module.exports = router;