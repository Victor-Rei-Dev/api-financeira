const express = require('express');
const router = express.Router();

const { cadastro, buscarUsuario, deletarUsuario, login } = require('../controllers/usuarioController');
const { verificarToken } = require('../middlewares/auth');
router.post('/cadastrar',cadastro);
router.get('/buscarUsuario/:id_usu', verificarToken, buscarUsuario);
router.delete('/deletarUsuario/:id_usu', verificarToken, deletarUsuario);
router.post('/login',login);
module.exports = router;