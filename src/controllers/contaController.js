const { sql } = require('../database/connection');


async function transferir(req,res) {
    const { id_enviador } = req.params;
    const {id_enviado,valor,descricao} = req.body;

    if (!id_enviador || id_enviador <= 0) {
        return res.status(400).json({error:'ID do enviador é obrigatório'});
    }
    if (!id_enviado || id_enviado <= 0) {
        return res.status(400).json({error:'ID de destino é obrigatório'});
    }

    if (!valor || isNaN(valor) || valor <=0) {
        return res.status(400).json({error:'Valor transferido é obrigatório'});
    }

    try {
        const request = new sql.Request();
        request.input('id_enviador',sql.Int,id_enviador);
        request.input('id_enviado',sql.Int,id_enviado);
        request.input('valor',sql.Decimal(18,2),valor);
        request.input('descricao',sql.VarChar,descricao || null);

        await request.execute('sp_transacao');

        res.status(201).json({
            success:true
        });

    }
    catch (err) {
        console.log('Erro:',err);
        res.status(500).json({error:'Erro interno do servidor'});
    }
}

async function extrato(req,res) {
const {id_conta} = req.params

if (!id_conta || id_conta <= 0){
    return res.status(400).json({error:'ID da conta é obrigatório'});
}

try{
    const request = new sql.Request();
    request.input('id_conta',sql.Int,id_conta);

    const result = await request.execute('sp_extrato');

    if(result.recordset.length == 0){
        return res.status(404).json({error:'Conta não encontrada'});
    }

    res.status(200).json({
        success:true,
        extrato: result.recordset
    });
}
catch(err) {
    console.log('Erro:',err);
    res.status(500).json({error:'Erro interno do servidor'})
}

}


async function depositarSaldo(req,res) {

    const {id_conta} = req.params;
    const { valor } = req.body;

    if(!id_conta || id_conta <= 0 ) {
        return res.status(400).json({error:'ID da conta é obrigatório'});
    }

    if(!valor || isNaN(valor) || valor <= 0) {
        return res.status(400).json({error:'Valor do saldo deve ser positivo'});
    }
    try {
        const request = new sql.Request();
        request.input('id_conta',sql.Int,id_conta);
        request.input('valor',sql.Decimal(18,2),valor)

       await request.execute('sp_depositar_saldo_id');

       

       res.status(200).json({
        success:true
       });
    }
    catch(err){
        console.log('Erro',err);
        res.status(500).json({error:'Erro interno do servidor'});
    }
}

async function buscarConta(req,res) {
    const { id_conta } = req.params;

    if(!id_conta || id_conta <= 0) {
        return res.status(400).json({error:'ID da conta é obrigatório'});
    }

    try{
        const request = new sql.Request();
        request.input('id_conta',sql.Int,id_conta);

        const result =  await request.execute('sp_buscar_conta');

        if (result.recordset.length == 0){
            return res.status(404).json({error:'Conta não encontrada'});
        }

        res.status(200).json(
            {
                success:true,
                conta:result.recordset[0]
            }
        );
    }
    catch(err) {
        console.log('Erro',err);
        res.status(500).json({error:'Erro interno do servidor'});
    }
}


async function deletarConta(req,res) {
    const { id_conta } = req.params;

    if (!id_conta || id_conta <= 0) {
        return res.status(400).json({error:'ID da conta é obrigatório'});
    }

    try{
        const request = new sql.Request();
        request.input('id_conta',sql.Int,id_conta);

        await request.execute('sp_deletar_conta');
        
        res.status(204).send();
    }
    catch(err) {
        console.log('Erro',err);
        res.status(500).json({error:'Erro interno do servidor'})
    }
}

async function atualizarLimite(req,res) {
    const { id_conta } = req.params;
    const { limite }  = req.body;

    if (!id_conta || id_conta <= 0) {
        return res.status(400).json({error:'ID da conta é obrigatório'});
    }
    if (!limite || limite <= 0) {
        return res.status(400).json({error:'Limite deve ser maior que zero'});
    }

    try{
        const request = new sql.Request();
        request.input('id_conta',sql.Int,id_conta);
        request.input('limite',sql.Decimal(18,2),limite);

        await request.execute('sp_atualizar_limite');

        res.status(200).json({
            success:true
        });

    }
    catch(err) {
        console.log('Erro:',err);
        res.status(500).json({error:'Erro interno do servidor'});
    }


}

module.exports = {transferir,extrato,depositarSaldo,buscarConta,deletarConta,atualizarLimite};

