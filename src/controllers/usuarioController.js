const { sql } = require('../database/connection');

async function  cadastro(req,res) {
    const { nome,email,senha,tel,cpf,tipo } = req.body;

    if (!nome || !email || !senha || !tel || !cpf) {
        return res.status(400).json({error:'Campos obrigatórios faltando'});
    }

    if (!email.includes('@') || !email.includes('.')) {
        return res.status(400).json({error:'Email inválido'});
    }

    if (tel.length !== 11) {
        return res.status(400).json({error:'Telefone inválido'});
    }

    if (cpf.length !== 14) {
        return res.status(400).json({error:'CPF inválido'});
    }


    try {
        const request = new sql.Request();
        request.input('nome',sql.VarChar(255),nome);
        request.input('email',sql.VarChar(255),email);
        request.input('senha',sql.VarChar(255),senha);
        request.input('tel',sql.VarChar(11),tel);
        request.input('cpf',sql.VarChar(14),cpf);
        request.input('tipo', sql.VarChar(100), tipo || 'corrente'); 

        const result = await request.execute('sp_cadastro');

        res.status(201).json(
            {
                success:true
            }
        );


    }

    catch(err) {
        console.log('Erro no banco',err);
        res.status(500).json({error:'Erro interno do servidor'});
    }
}


async function buscarUsuario(req,res) {
    const { id_usu } = req.params;

    if (!id_usu || id_usu <= 0 ) {
      return  res.status(400).json({error:'ID do usuário é obrigatório'});
    }

    try{
        const request = new sql.Request();
        request.input('id_usu',sql.Int,id_usu);

        const result = await request.execute('sp_buscar_usu');

        if(result.recordset.length == 0) {
          return res.status(404).json({error:'Usuário não encontrado'});
        }
        res.status(200).json({
          success:true,
          usuario: result.recordset[0]  
        });

    }
    catch(err) {
        console.log('Erro',err);
        res.status(500).json({error:'Erro interno do servidor'});
    }
}

async function deletarUsuario(req,res) {
const {id_usu} = req.params;

if(!id_usu || id_usu <=0) {
    return res.status(400).json({error:'ID do usuário é obrigatório'})
}
try{
    const request = new sql.Request();
    request.input('id_usu',sql.Int,id_usu);

    await request.execute('sp_deletar_usuario');

    res.status(204).send();
}
catch(err) {
    console.log('Erro',err);
    res.status(500).json({error:'Erro interno do servidor'});
}
}

async function login(req,res) {
const { email,senha } = req.body;

if(!email || !senha) {
    return res.status(400).json({error:'Email e senha são obrigatórios'});
}

try{
    const request = new sql.Request();
    request.input('email',sql.VarChar(255),email);
    request.input('senha',sql.VarChar(255),senha);

    const result = await request.execute('sp_login');

    if (result.recordset.length == 0) {
        return res.status(401).json({error:'Email ou senha inválidos'});
    }

    const usuario = result.recordset[0];

   

    res.status(200).json({
        success:true,
        usuario : {
            id: usuario.id_usu,
            nome: usuario.nome,
            email: usuario.email

        }

    });

}
catch(err) {
    console.log('Erro:',err);
    res.status(500).json({error:'Erro interno do servidor'});
}
}

module.exports = {cadastro,buscarUsuario,deletarUsuario,login};