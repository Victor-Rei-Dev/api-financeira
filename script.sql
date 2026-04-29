USE MASTER
GO

IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = 'node_user')
	CREATE LOGIN node_user WITH PASSWORD = 'senha123', CHECK_POLICY = OFF;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'Financeiro')
BEGIN
    ALTER DATABASE Financeiro SET SINGLE_USER WITH ROLLBACK IMMEDIATE
    DROP DATABASE Financeiro
END
GO

CREATE DATABASE Financeiro
GO

USE Financeiro
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'node_user')
BEGIN
    CREATE USER node_user FOR LOGIN node_user;
    ALTER ROLE db_owner ADD MEMBER node_user;
END
GO


CREATE TABLE usuario (
id_usu INT PRIMARY KEY IDENTITY,
nome VARCHAR(255),
email VARCHAR(255) UNIQUE NOT NULL,
senha VARBINARY(255) NOT NULL,
data_cad DATE DEFAULT GETDATE(),
tel VARCHAR(11),
cpf VARCHAR(14) UNIQUE NOT NULL,
ativo BIT DEFAULT 1
)

CREATE TABLE conta (
id_conta INT PRIMARY KEY IDENTITY,
id_usu INT FOREIGN KEY REFERENCES usuario(id_usu),
saldo DECIMAL(18,2) DEFAULT 0.00 CHECK(saldo>=0.00),
tipo VARCHAR(100) NOT NULL,
limite_diario_vigente DECIMAL(18,2) DEFAULT NULL,
ativo BIT DEFAULT 1
)

CREATE TABLE transacao (
id_transacao INT PRIMARY KEY IDENTITY,
valor DECIMAL(18,2) NOT NULL CHECK(valor > 0),
id_enviador INT FOREIGN KEY REFERENCES conta(id_conta) NOT NULL,
id_enviado INT FOREIGN KEY REFERENCES conta(id_conta) NOT NULL,
descricao VARCHAR(255),
data_hora DATETIME DEFAULT GETDATE(),
saldo_antes_enviador DECIMAL(18,2),
saldo_depois_enviador DECIMAL(18,2),
saldo_antes_enviado DECIMAL(18,2),
saldo_depois_enviado DECIMAL(18,2),
CONSTRAINT proibidor CHECK(id_enviador != id_enviado)
)

CREATE TABLE limite_diario (
id_limite INT PRIMARY KEY IDENTITY,
valor_hoje DECIMAL(18,2) DEFAULT 0.00,
id_conta INT FOREIGN KEY REFERENCES conta(id_conta),
limite DECIMAL(18,2) DEFAULT 5000.00,
data DATE DEFAULT CAST(GETDATE() AS DATE),
UNIQUE(data,id_conta)
)



GO
CREATE INDEX idx_usu_cpf ON usuario(cpf)
CREATE INDEX idx_conta_id_usu ON conta(id_usu)
CREATE INDEX idx_limite_diario_id_conta_data ON limite_diario(id_conta,data)
CREATE INDEX idx_transacao_enviador ON transacao(id_enviador,data_hora DESC)
CREATE INDEX idx_transacao_enviado ON transacao (id_enviado,data_hora DESC)
CREATE INDEX idx_email_usu ON usuario(email)



GO
CREATE PROC sp_transacao @id_enviador INT,@id_enviado INT,@valor DECIMAL(18,2),@descricao VARCHAR(255) = NULL
AS
BEGIN
SET NOCOUNT ON
BEGIN TRY
	BEGIN TRANSACTION
			DECLARE @saldo_antes_enviador DECIMAL(18,2)
			SELECT @saldo_antes_enviador = saldo FROM conta WITH (UPDLOCK) WHERE id_conta = @id_enviador

			IF @saldo_antes_enviador IS NULL
				THROW 50001,'Conta de origem não existente',1

			IF @saldo_antes_enviador < @valor
				THROW 50002,'Saldo insuficiente',1

			
			DECLARE @data_atual DATE
			DECLARE @valor_hoje DECIMAL(18,2)
			DECLARE @limite_pedido DECIMAL(18,2)
			SELECT @data_atual = data,@valor_hoje = valor_hoje FROM limite_diario WHERE data = CAST(GETDATE() AS DATE) AND id_conta = @id_enviador
			SELECT  @limite_pedido = COALESCE(limite_diario_vigente,5000.00) FROM conta WHERE id_conta = @id_enviador

			IF @data_atual IS NULL
				BEGIN
				INSERT INTO limite_diario(valor_hoje,id_conta,data,limite)
				VALUES (0.00,@id_enviador,CAST(GETDATE() AS DATE),@limite_pedido)
				SET @valor_hoje = 0.00
				SET @data_atual = CAST(GETDATE() AS DATE)
				END

				IF @limite_pedido < @valor+@valor_hoje
					THROW 50007,'Limite diário excedido',1

				UPDATE limite_diario
				SET valor_hoje = @valor + @valor_hoje WHERE data = @data_atual AND id_conta = @id_enviador
	
			DECLARE @conta_enviado INT
			SELECT @conta_enviado = id_conta FROM conta WITH (UPDLOCK) WHERE id_conta = @id_enviado
			
			IF @conta_enviado IS NULL
				THROW 50003,'Conta de destino não existente',1

			DECLARE @saldo_antes_enviado DECIMAL(18,2)
			SELECT @saldo_antes_enviado = saldo FROM conta WHERE id_conta = @id_enviado


			UPDATE conta SET saldo = saldo - @valor WHERE id_conta = @id_enviador
			UPDATE conta SET saldo = saldo + @valor WHERE id_conta = @id_enviado

			

			DECLARE @saldo_depois_enviado DECIMAL(18,2)
			SELECT @saldo_depois_enviado = saldo FROM conta WHERE id_conta = @id_enviado
			
			DECLARE @saldo_posterior DECIMAL(18,2)
			SELECT @saldo_posterior = saldo FROM conta WHERE id_conta = @id_enviador

			INSERT INTO transacao (valor,id_enviador,id_enviado,saldo_antes_enviador,saldo_depois_enviador,saldo_antes_enviado,saldo_depois_enviado,descricao)
			VALUES (@valor,@id_enviador,@id_enviado,@saldo_antes_enviador,@saldo_posterior,@saldo_antes_enviado,@saldo_depois_enviado,@descricao)
			COMMIT
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK
		
		;THROW
	END CATCH
	
END

GO

CREATE PROC sp_cadastro @nome VARCHAR(255),@email VARCHAR(255),@senha VARCHAR(255),@tel VARCHAR(11),@cpf VARCHAR(14),@tipo VARCHAR(100) = 'corrente'
AS
BEGIN
SET NOCOUNT ON	
	BEGIN TRY
	BEGIN TRANSACTION

	IF EXISTS (SELECT 1 FROM usuario WHERE email = @email OR cpf = @cpf)
		THROW 50004,'Usuário já cadastrado',1

	INSERT INTO usuario(nome,email,senha,tel,cpf) VALUES
	(@nome,@email,HASHBYTES('SHA2_256', @senha),@tel,@cpf)

	DECLARE @novo_usuario INT
	SET @novo_usuario = SCOPE_IDENTITY()

	INSERT INTO conta(id_usu,saldo,tipo)
	VALUES (@novo_usuario,0.00,@tipo)
	COMMIT

	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK
		;THROW
	END CATCH
END

GO
CREATE  PROC sp_depositar_saldo @valor DECIMAL(18,2),@cpf VARCHAR(14)
AS
BEGIN
SET NOCOUNT ON
BEGIN TRY
BEGIN TRANSACTION
	UPDATE c
	SET c.saldo = c.saldo + @valor
	FROM conta c
	INNER JOIN usuario u ON c.id_usu = u.id_usu
	 WHERE u.cpf = @cpf
	
	IF @@ROWCOUNT = 0
		THROW 50005,'CPF não encontrado',1
	COMMIT
	END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK

	;THROW
END CATCH
END


GO
CREATE PROC sp_depositar_saldo_id @valor DECIMAL(18,2), @id_conta INT
AS
BEGIN
SET NOCOUNT ON
BEGIN TRY
BEGIN TRANSACTION
	UPDATE c
	SET c.saldo = c.saldo + @valor
	FROM conta c
	 WHERE c.id_conta = @id_conta
	
	IF @@ROWCOUNT = 0
		THROW 50005,'Conta não encontrada',1
	COMMIT
	END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK
	;THROW
END CATCH
END

GO
CREATE PROC sp_extrato @id_conta INT
AS
BEGIN
SET NOCOUNT ON
BEGIN TRY
	IF NOT EXISTS (SELECT 1 FROM conta WHERE id_conta = @id_conta)
			THROW 50005,'Conta não encontrada',1
	IF NOT EXISTS (SELECT 1 FROM transacao WHERE id_enviador = @id_conta OR id_enviado = @id_conta)
		THROW 50006,'Nenhuma transação realizada.',1
	SELECT 
            t.data_hora,
            t.valor,
            CASE 
                WHEN t.id_enviador = @id_conta THEN 'ENVIO'
                ELSE 'RECEBIMENTO'
            END AS tipo,
            CASE 
                WHEN t.id_enviador = @id_conta THEN u_destino.nome  -- quem recebeu
                ELSE u_origem.nome                                 -- quem enviou
            END AS outra_parte,
			CASE 
				WHEN t.id_enviador = @id_conta THEN t.saldo_antes_enviador
				ELSE saldo_antes_enviado
				END AS saldo_anterior,
			CASE 
				WHEN t.id_enviador = @id_conta THEN t.saldo_depois_enviador
				ELSE t.saldo_depois_enviado
			END AS saldo_posterior
        FROM transacao t
        LEFT JOIN conta c_origem ON t.id_enviador = c_origem.id_conta -- O LEFT JOIN preserva a parte da esquerda, mesmo se for NULL a parte direita.
        LEFT JOIN usuario u_origem ON c_origem.id_usu = u_origem.id_usu
        LEFT JOIN conta c_destino ON t.id_enviado = c_destino.id_conta
        LEFT JOIN usuario u_destino ON c_destino.id_usu = u_destino.id_usu
        WHERE t.id_enviador = @id_conta OR t.id_enviado = @id_conta
        ORDER BY t.data_hora DESC
	
END TRY
BEGIN CATCH
	;THROW
END CATCH
END

GO
CREATE PROC sp_atualizar_limite @id_conta INT, @limite DECIMAL(18,2)
AS
BEGIN
SET NOCOUNT ON
BEGIN TRY
BEGIN TRANSACTION
	IF NOT EXISTS (SELECT 1 FROM conta WHERE id_conta = @id_conta)
		THROW 50005, 'Conta não encontrada.',1

		UPDATE conta
		SET limite_diario_vigente = @limite WHERE id_conta = @id_conta
		COMMIT
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK

	;THROW
END CATCH
END

GO 
CREATE PROC sp_deletar_conta @id_conta INT AS
BEGIN
SET NOCOUNT ON
BEGIN TRY
BEGIN TRANSACTION
	DECLARE @saldo DECIMAL(18,2)
	SELECT @saldo = saldo FROM conta WHERE id_conta = @id_conta

	IF @saldo IS NULL
		THROW 50005,'Conta não encontrada',1
	
	IF @saldo > 0
		THROW 50008, 'Não é possível fechar conta com saldo positivo', 1
		
	UPDATE conta SET ativo = 0 WHERE id_conta = @id_conta
	COMMIT
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK

		;THROW

END CATCH
END
GO 
CREATE PROC sp_deletar_usuario @id_usu INT AS
BEGIN
BEGIN TRY
SET NOCOUNT ON
BEGIN TRANSACTION

	IF EXISTS (SELECT 1 FROM conta WHERE id_usu = @id_usu AND ativo = 1)
		THROW 50009,'Feche a conta antes de apagar o usuário',1

	UPDATE usuario SET ativo = 0 WHERE id_usu = @id_usu
	COMMIT
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
		ROLLBACK

		;THROW

END CATCH
END


GO
CREATE PROC sp_buscar_usu @id_usu INT AS
BEGIN
SELECT id_usu,nome,email,tel,cpf,data_cad,ativo FROM usuario WHERE id_usu = @id_usu
END


GO
CREATE PROC sp_buscar_conta @id_conta INT AS
BEGIN 
SET NOCOUNT ON
SELECT u.nome,c.*
FROM conta c
JOIN usuario u ON u.id_usu = c.id_usu
WHERE c.id_conta = @id_conta
END

GO
CREATE PROC sp_login @email VARCHAR(255),@senha VARCHAR(255)
AS
BEGIN
	SET NOCOUNT ON
		BEGIN TRY
			IF @email IS NULL OR @senha IS NULL
				THROW 500010,'Dados inválidos',1

			SELECT id_usu, nome, email, ativo
			FROM usuario 
			WHERE email = @email 
			AND senha = HASHBYTES('SHA2_256', @senha)
			AND ativo = 1

		END TRY
		BEGIN CATCH
			;THROW

		END CATCH
END