<?php
// Documentação: Este ficheiro é responsável por estabelecer a conexão com o banco de dados.
// Utiliza a classe PDO (PHP Data Objects) para uma conexão mais segura e compatível com vários bancos.

class Database {
    // Parâmetros de conexão com o banco de dados.
    // Altera estes valores para os teus próprios.
    private $host = "143.106.241.4"; // O endereço do teu servidor MySQL (geralmente localhost).
    private $db_name = "cl202149"; // O nome do teu banco de dados.
    private $username = "cl202149"; // O teu nome de utilizador do MySQL.
    private $password = "cl*22082006"; // A tua senha do MySQL.
    public $conn; // Variável pública para guardar o objeto de conexão.

    // Método para obter a conexão com o banco de dados.
    public function getConnection() {
        // Inicializa a conexão como nula.
        $this->conn = null;

        try {
            // Tenta criar uma nova instância de PDO (a conexão).
            // A string de conexão (DSN) especifica o tipo de banco, o host e o nome do banco.
            $this->conn = new PDO("mysql:host=" . $this->host . ";dbname=" . $this->db_name, $this->username, $this->password);
            
            // Define o modo de erro do PDO para exceções, o que ajuda a depurar erros.
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            
            // Define o conjunto de caracteres para utf8mb4 para suportar uma vasta gama de caracteres.
            $this->conn->exec("set names utf8mb4");

        } catch(PDOException $exception) {
            // Se a conexão falhar, mostra uma mensagem de erro.
            echo "Erro de conexão: " . $exception->getMessage();
        }

        // Retorna o objeto de conexão.
        return $this->conn;
    }
}
?>