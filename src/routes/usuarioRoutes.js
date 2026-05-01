const express = require('express');
const router = express.Router();

const {cadastro,buscarUsuario,deletarUsuario,login} = require('../controllers/usuarioController')
router.post('/cadastrar',cadastro);
router.get('/buscarUsuario/:id_usu',buscarUsuario);
router.delete('/deletarUsuario/:id_usu',deletarUsuario);
router.post('/login',login);
module.exports = router;