const express = require('express');
const router = express.Router();


const { transferir, extrato, depositarSaldo, buscarConta,deletarConta,atualizarLimite} = require('../controllers/contaController');
const { route } = require('./usuarioRoutes');

router.post('/transferir/:id_enviador', transferir);
router.get('/extrato/:id_conta', extrato);
router.get('/buscarConta/:id_conta',buscarConta);
router.delete('/deletarConta/:id_conta',deletarConta);
router.patch('/atualizarLimite/:id_conta',atualizarLimite);
router.patch('/depositarSaldo/:id_conta',depositarSaldo);


module.exports = router;