CREATE DATABASE Loja_Fotos
GO
USE Loja_Fotos
GO
-- **Tabelas** --


-- PRODUTO
CREATE TABLE Produto (
    id UNIQUEIDENTIFIER,
    descricao TEXT NOT NULL,
    tipo VARCHAR(20) NOT NULL,
    preco_custo FLOAT NOT NULL,
    preco_venda FLOAT NOT NULL,

    CONSTRAINT PK_Produto PRIMARY KEY (id)
)
GO

CREATE TABLE Estoque (
    id UNIQUEIDENTIFIER,
    qtd_minima INT NOT NULL,
    qtd_estoque INT NOT NULL,

    CONSTRAINT PK_Estoque PRIMARY KEY (id),
    CONSTRAINT FK_Estoque_Produto FOREIGN KEY (id) REFERENCES Produto(id)
)
GO

-- Funcionario
CREATE TABLE Funcionario (
    codigo UNIQUEIDENTIFIER,
    nome VARCHAR(50) NOT NULL,

    CONSTRAINT PK_Funcionario PRIMARY KEY (codigo)
)
GO

CREATE TABLE Endereco_Funcionario (
    codigo_funcionario UNIQUEIDENTIFIER,
    logradouro VARCHAR(80) NOT NULL,
    CEP CHAR(8) NOT NULL,
    bairro VARCHAR(80) NOT NULL,
    complemento VARCHAR(80) NOT NULL,
    cidade VARCHAR(50) NOT NULL,
    UF CHAR(2) NOT NULL,

    CONSTRAINT PK_Endereco_Funcionario PRIMARY KEY (codigo_funcionario),
    CONSTRAINT FK_Endereco_Funcionario_Funcionario FOREIGN KEY (codigo_funcionario) REFERENCES Funcionario (codigo)
)
GO

CREATE TABLE Telefone_Funcionario (
    codigo_funcionario UNIQUEIDENTIFIER,
    telefone VARCHAR(11) NOT NULL,

    CONSTRAINT PK_Telefone_Funcionario PRIMARY KEY (codigo_funcionario, telefone),
    CONSTRAINT FK_Telefone_Funcionario_Funcionario FOREIGN KEY (codigo_funcionario) REFERENCES Funcionario (codigo)
)
GO

-- Cliente
CREATE TABLE Pessoa (
    codigo UNIQUEIDENTIFIER,
    nome VARCHAR(50) NOT NULL,

    CONSTRAINT PK_Pessoa PRIMARY KEY (codigo)
)
GO

CREATE TABLE Telefone_Pessoa (
    codigo_pessoa UNIQUEIDENTIFIER,
    telefone VARCHAR(11) NOT NULL,

    CONSTRAINT PK_Telefone_Pessoa PRIMARY KEY (codigo_pessoa, telefone),
    CONSTRAINT FK_Telefone_Pessoa_Pessoa FOREIGN KEY (codigo_pessoa) REFERENCES Pessoa (codigo)
)
GO

CREATE TABLE Endereco_Pessoa (
    codigo_pessoa UNIQUEIDENTIFIER,
    logradouro VARCHAR(80) NOT NULL,
    CEP CHAR(8) NOT NULL,
    bairro VARCHAR(80) NOT NULL,
    complemento VARCHAR(80) NOT NULL,
    cidade VARCHAR(50) NOT NULL,
    UF CHAR(2) NOT NULL,

    CONSTRAINT PK_Endereco_Pessoa PRIMARY KEY (codigo_pessoa),
    CONSTRAINT FK_Endereco_Pessoa_Pessoa FOREIGN KEY (codigo_pessoa) REFERENCES Pessoa (codigo)
)
GO

CREATE TABLE Cliente_Fisico (
    codigo UNIQUEIDENTIFIER,
    CPF CHAR(11) NOT NULL,
    RG VARCHAR(14) NOT NULL,
    sexo CHAR NOT NULL,
    data_nascimento DATETIME NOT NULL,

    CONSTRAINT PK_Cliente_Fisico PRIMARY KEY (codigo, CPF),
    CONSTRAINT FK_Cliente_Fisico_Pessoa FOREIGN KEY (codigo) REFERENCES Pessoa(codigo)
)
GO

CREATE TABLE Cliente_Juridico (
    codigo UNIQUEIDENTIFIER,
    CNPJ CHAR(14) NOT NULL,
    IE VARCHAR(14) NOT NULL,
    nome_responsavel CHAR(11) NOT NULL

    CONSTRAINT PK_Cliente_Juridico PRIMARY KEY (CNPJ),
    CONSTRAINT FK_Cliente_Juridico_Pessoa FOREIGN KEY (codigo) REFERENCES Pessoa(codigo)
)
GO

-- Venda
CREATE TABLE Venda (
    numero UNIQUEIDENTIFIER,
    codigo_pessoa UNIQUEIDENTIFIER,
    codigo_funcionario UNIQUEIDENTIFIER,
    data_venda DATETIME NOT NULL,
    cond_pagamento VARCHAR(20) NOT NULL,
    valor_venda FLOAT NOT NULL DEFAULT (0),

    CONSTRAINT PK_Venda PRIMARY KEY (numero),
    CONSTRAINT FK_Venda_Pessoa FOREIGN KEY (codigo_pessoa)  REFERENCES Pessoa (codigo),
    CONSTRAINT FK_Venda_Funcionario FOREIGN KEY (codigo_funcionario)  REFERENCES Funcionario (codigo)
)
GO

CREATE TABLE Venda_Produto (
    id_produto UNIQUEIDENTIFIER, 
    numero_venda UNIQUEIDENTIFIER,
    preco_venda FLOAT NOT NULL,
    quantidade INT NOT NULL,
    valor_total_item FLOAT NULL,

    CONSTRAINT PK_Venda_Produto PRIMARY KEY (id_produto, numero_venda),
    CONSTRAINT FK_Venda_Produto_Produto FOREIGN KEY (id_produto) REFERENCES Produto (id),
    CONSTRAINT FK_Venda_Produto_Venda FOREIGN KEY (numero_venda) REFERENCES Venda (numero)
)
GO

-- Triggers

-- Venda_Produto
CREATE OR ALTER TRIGGER TGR_Valor_Venda ON Venda_Produto AFTER INSERT AS
    BEGIN
    DECLARE
        @IdProduto UNIQUEIDENTIFIER,
        @IdVenda UNIQUEIDENTIFIER,
        @Preco FLOAT,
        @Quantidade INT

        SELECT @IdProduto = id_produto, @IdVenda = numero_venda, @Preco = preco_venda, @Quantidade = quantidade FROM INSERTED

        UPDATE Venda_Produto SET valor_total_item = @Preco * @Quantidade WHERE id_produto = @IdProduto AND numero_venda = @IdVenda
    END
GO

-- Adicao Venda
CREATE OR ALTER TRIGGER TGR_Venda_Add ON Venda_Produto AFTER UPDATE AS
    BEGIN
    DECLARE
        @Id UNIQUEIDENTIFIER,
        @Total FLOAT

        SELECT @id = numero_venda, @Total = valor_total_item FROM INSERTED

        UPDATE Venda SET valor_venda = valor_venda + @Total WHERE numero = @id
    END
GO

-- Remocao Venda
CREATE OR ALTER TRIGGER TGR_Venda_Rem ON Venda_Produto AFTER DELETE AS
    BEGIN
    DECLARE
        @Id UNIQUEIDENTIFIER,
        @Total FLOAT

        SELECT @id = numero_venda, @Total = valor_total_item FROM DELETED

        UPDATE Venda SET valor_venda = valor_venda - @Total WHERE numero = @id
    END
GO

-- Procedures

CREATE OR ALTER PROC InserirPessoa @Nome VARCHAR(50) AS
    BEGIN
        INSERT INTO Pessoa (codigo, nome) VALUES (NEWID(), @Nome)
    END
GO

CREATE OR ALTER PROC InserCF @Id UNIQUEIDENTIFIER, @CPF CHAR(11), @RG VARCHAR(11), @Sexo CHAR, @Data DATETIME AS
    BEGIN
        INSERT INTO Cliente_Fisico (codigo, CPF, RG, sexo, data_nascimento) VALUES (@Id, @CPF, @RG, @Sexo, CONVERT(DATETIME, @Data, 103))
    END
GO

CREATE OR ALTER PROC InserirFuncionario @Nome VARCHAR(50) AS 
    BEGIN
        INSERT INTO Funcionario (codigo, nome) VALUES (NEWID(), @Nome)
    END
GO

CREATE OR ALTER PROC InserirProduto @Desc TEXT, @Tipo VARCHAR(50), @PCusto FLOAT, @PVenda FLOAT AS
    BEGIN
        INSERT INTO Produto (id, descricao, tipo, preco_custo, preco_venda) VALUES (NEWID(), @Desc, @Tipo, @PCusto, @PVenda)
    END
GO

CREATE OR ALTER PROC InserirEstoque @Id UNIQUEIDENTIFIER, @Min INT, @Estoque INT AS
    BEGIN
        INSERT INTO Estoque (id, qtd_minima, qtd_estoque) VALUES (@Id, @Min, @Estoque)
    END
GO

CREATE OR ALTER PROC CriarVenda @CodPessoa UNIQUEIDENTIFIER, @CodFunc UNIQUEIDENTIFIER, @Pagamento VARCHAR(20) AS
    BEGIN
        INSERT INTO Venda (numero, codigo_pessoa, codigo_funcionario, data_venda, cond_pagamento) VALUES (NEWID(), @CodPessoa, @CodFunc, GETDATE(), @Pagamento)
    END
GO

CREATE OR ALTER PROC InserirProdutoVenda @IdProduto UNIQUEIDENTIFIER, @IdVenda UNIQUEIDENTIFIER, @Preco FLOAT, @Quantidade INT AS
    BEGIN
        INSERT INTO Venda_Produto (id_produto, numero_venda, preco_venda, quantidade) VALUES (@IdProduto, @IdVenda, @Preco, @Quantidade)
    END
GO

/*
-- Inserções
EXEC.InserirPessoa 'Marcos'
EXEC.InserirPessoa 'Tatiana'
SELECT * FROM Pessoa

EXEC.InserCF '37a8ddfa-ee63-4da9-9022-0767dca5801b', '12345678900', '123', 'M', '10/02/1990'
EXEC.InserCF '11af1dac-feef-4e9e-960f-59e1ed1d9c79', '12345678910', '123', 'F', '03/04/2000'
SELECT * FROM Cliente_Fisico

EXEC.InserirFuncionario 'Jubileu'
SELECT * FROM Funcionario

EXEC.InserirProduto 'Produto legal', 'CoolItems', 10.0, 20.0
EXEC.InserirProduto 'Produto muito bom', 'CoolItems', 3.0, 50.0
SELECT * FROM Produto

EXEC.InserirEstoque 'e50a3638-9fdb-4f0c-886c-7c99c3165b14', 2, 3
EXEC.InserirEstoque '6c3f5f70-5851-4be3-86d9-ef19a8ba5486', 1, 7
SELECT * FROM Estoque

EXEC.CriarVenda '37a8ddfa-ee63-4da9-9022-0767dca5801b', '387edbe9-5f9e-4296-9074-d5d8485a536e', 'Fiado'
EXEC.CriarVenda '11af1dac-feef-4e9e-960f-59e1ed1d9c79', '387edbe9-5f9e-4296-9074-d5d8485a536e', 'Kwanza'
SELECT * FROM Venda

EXEC.InserirProdutoVenda 'e50a3638-9fdb-4f0c-886c-7c99c3165b14', '2ea6ed06-7159-4313-8a24-6afd473c3f46', 30, 2
EXEC.InserirProdutoVenda '6c3f5f70-5851-4be3-86d9-ef19a8ba5486', '2ea6ed06-7159-4313-8a24-6afd473c3f46' , 50, 3
EXEC.InserirProdutoVenda 'e50a3638-9fdb-4f0c-886c-7c99c3165b14', 'a0a5c239-4b4b-472a-b787-9acae0fd4fcb', 20, 7
SELECT * FROM Venda_Produto

DELETE FROM Venda 
DELETE FROM Venda_Produto
*/

-- Visualizar
SELECT Pessoa.nome, Cliente_Fisico.CPF, (SELECT valor_venda FROM Venda JOIN Pessoa ON Pessoa.codigo = Venda.codigo_pessoa) AS 'Total Compra' FROM Pessoa JOIN Cliente_Fisico ON Pessoa.codigo = Cliente_Fisico.codigo
