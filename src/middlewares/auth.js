const jwt = require('jsonwebtoken');

const SECRET = process.env.JWT_SECRET || 'meu_segredo_super_secreto';

function gerarToken(usuario) {
    return jwt.sign(
        { id: usuario.id_usu, email: usuario.email },
        SECRET,
        { expiresIn: '24h' }
    );
}

function verificarToken(req, res, next) {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
        return res.status(401).json({ error: 'Token não fornecido' });
    }

    const token = authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: 'Token mal formatado' });
    }

    try {
        const decoded = jwt.verify(token, SECRET);
        req.usuario = decoded; 
        next();
    } catch (err) {
        if (err.name === 'TokenExpiredError') {
            return res.status(401).json({ error: 'Token expirado' });
        }
        return res.status(403).json({ error: 'Token inválido' });
    }
}

module.exports = { gerarToken, verificarToken };